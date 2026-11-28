# Mirrors upstream ci.yml "Test" (just test-rust --locked --no-fail-fast) and, on Linux, "Lint".
export RUSTC_WRAPPER= CARGO_BUILD_RUSTC_WRAPPER= MESH_LLM_SKIP_UI=1
case "$RUNNER_OS" in
  Linux) sudo apt-get update -qq && sudo apt-get install -y -qq build-essential cmake ninja-build pkg-config libssl-dev libdbus-1-dev mold lld jq lsof shellcheck >/dev/null
         rustup component add rustfmt clippy ;;
  macOS) brew install lld >/dev/null ;;
esac
rustc --version
if [ "$RUNNER_OS" = Linux ]; then
  echo "::group::lint"; cargo fmt --all -- --check && cargo clippy --workspace --all-targets --locked -- -D warnings; echo "::endgroup::"
fi
cargo test --workspace --locked --no-fail-fast 2>&1 | tee "$RUNNER_TEMP/test.log" | grep -E '^(test result|error|failures:|    [a-z_:]+$)|FAILED|panicked' || true
! grep -qE 'test result: FAILED|^error' "$RUNNER_TEMP/test.log"
