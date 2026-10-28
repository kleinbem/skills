---
name: agent-ops
description: >-
  How an agent runs long work in the kleinbem fleet: watching builds and CI so
  failures are reported unasked, polling without rate limits or YubiKey
  popups, local build priority on nixos-nvme, waiting productively, shell
  traps, and verifying with real builds. Load before starting builds, CI runs,
  background jobs or waits.
---
# Running long work in the kleinbem fleet

## Watch every job, report failures unasked

- Every running job (GitHub run, local build, Orin build, a subagent's run too) has one
  background watcher in the main session. It exits at the first failed job or when the job is
  done; then report right away and restart it for whatever still runs. Martin should never have
  to ask to learn that something broke.
- Watch per job (a failed matrix job), not only a run's overall status.
- Only say "the watcher reports it" while one is actually running.
- A watcher is a plain loop and costs no tokens while it waits:
  `while true; do <check>; [ done ] && { echo EVENT …; break; }; sleep 300; done` as a background
  Bash call. Don't `disown` it: the notification comes from the shell ending.
- After a green run that goes into a PR, triage the log's warnings too (see
  `nixpkgs-contributing`); watchers stop on errors only.

## Polling without side effects

- One slow loop for all GitHub runs (`gh run view <id> --json status,conclusion,jobs` every
  2–5 min). Parallel `gh run watch` loops trip GitHub's secondary rate limit (403 with core quota
  left); on a 403, stop all gh calls for 2 minutes.
- Never poll a host with repeated ssh: every attempt raises a YubiKey PIN popup. Wait with
  `ping -c1 -W2 <host>` or `timeout 3 bash -c '</dev/tcp/<host>/22'`, then one ssh call. A single
  long-running ssh that waits on the host side (`while systemctl --user is-active -q <unit>`) is
  fine. `just access::grant-notouch <host>` (run by Martin) gives 24 h of touch-free ssh.
- Run long remote builds as `systemd-run --user --unit=<name> --collect` so they survive the ssh
  session.

## Local builds on nixos-nvme

- 8 cores, 62 GB RAM, zram plus 10 GB disk swap, swappiness 150; the nix-daemon runs at idle CPU
  priority with max-jobs 3, cores 6. Don't raise those.
- Run cargo and other local builds the same way: `chrt --idle 0 ionice -c3 cargo … -j 4`.
- Before a heavy build check `free -h`, `swapon --show` and `/proc/pressure/memory`. If swap is
  nearly full, find what holds it (per-process `VmSwap`), tell Martin, and start only when there
  is room; a full swap at a build peak freezes his desktop.
- Checks and full builds go to GitHub runners; the workstation is for builds that need its store,
  hardware or a built binary. Use every machine that's free, but never two heavy local builds at
  once.
- Build with `--no-link`, or put the out-link in the session scratchpad. Never leave `result*`
  links in `~/.cache` or `$HOME`: each one is a GC root, and 47 of them once kept 50+ GiB of old
  test builds alive (one was a whole older nixos-nvme system). Keep a root only when something
  must outlive the session, name it after what it's for, and tell Martin so he can drop it.
- Never put store paths into PATH by hand (`~/.local/bin/x -> /nix/store/…`): the link has no root,
  shadows the system's version and breaks after the next GC. Install through nix-config.

## Waiting productively

- While something builds, pick the next open task that doesn't depend on it and doesn't compete
  for memory.
- Estimate durations from the last comparable run. GitHub times are UTC; give Martin times in
  Irish time.
- Keep multi-day work out of the scratchpad (`/tmp` is tmpfs, wiped on reboot): worktrees next to
  the clone, logs in `~/.cache`, drafts in Obsidian.

## Shell traps

- `pgrep -f`/`pkill -f` with a pattern written in the same command line matches the calling
  shell (`bash -c '<command>'`): a wait never ends, `pkill` kills the shell (exit 144). Wait on a
  PID (`while kill -0 $pid`) or a log marker, or use a character class (`"[n]ix-build"`). The
  same over SSH: `ssh host 'pkill -f …'` kills the remote shell (exit 255). Kill by PID.
- Under `set -euo pipefail`, `VAR=$(cmd_expected_to_fail | grep …)` aborts the script; wrap it:
  `(cmd 2>&1 || true) | grep …`. A script that `git add`s internally needs `git diff HEAD --quiet`
  to detect changes.
- `! cmd` never fails a script under `set -e` (also in nixpkgs `runCommand` tests); write
  `if cmd; then echo "unexpected success" >&2; exit 1; fi`.

## Find the cause before the PR

- Every kleinbem PR auto-merges once green, so opening one is merging it. Know why something
  fails before changing how it works.
- One host's symptom isn't a fleet finding. Check the same thing on the other hosts first (one
  `ssh` loop; no-touch grants make it free). If they're fine, the cause is in that host's config
  or hardware, and so is the fix.
- Try the one-off manual fix first: how it behaves points at the cause. On nixos-nvme, chrony had
  0 RTC samples and the clock sat at 2021. Swapping chrony to `rtcsync` fleet-wide (nix-config
  #355) was wrong: `acpi_tad` held rtc0, `hwclock --rtc /dev/rtc1` worked, the other five hosts
  trimmed fine, and the fix was blacklisting one module on one host (#356).

## Verify with real builds

- GPU tests on orin-nano (JetPack 6, driver for CUDA 12): nixpkgs master defaults to CUDA 13
  (seen 2026-10-27), which that driver can't run. Build with `cudaPackages_12` and
  `config.cudaCapabilities = [ "8.7" ]`.
- Eval isn't verification: build the narrowest derivation that runs the check (for sops-nix,
  `config.system.build.sops-nix-manifest`; for module docs, the NixOS manual; for packages, their
  tests).
- `builtins.getFlake` inside `--expr` ignores `--override-input` and reads the committed lock. Test
  uncommitted cross-repo changes with `.#` refs; `path:` on a git worktree ignores uncommitted files.
- When CI says "1 dependency failed" and the log buffer hides which: instantiate the package at
  the toplevel's nixpkgs rev, walk its inputs and check `https://cache.nixos.org/<hash>.narinfo`
  (404 = Hydra never built it), confirm on Hydra (`/jobset/nixos/unstable/evals`, then
  `/eval/<id>/job/nixpkgs.<attr>.<system>`). Or rebuild on the device:
  `nix copy --derivation --to ssh-ng://<host> <drv>`, `nix build --dry-run '<drv>^*'`, then
  `nix build --keep-going -L --max-jobs 1`.
