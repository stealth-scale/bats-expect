# Shared setup of the bats-expect test files: strict mode and the library.
common_setup() {
    set -Euo pipefail
    bats_require_minimum_version 1.5.0
    load "$BATS_TEST_DIRNAME/../load"
}

# Runs an assertion in a subshell and captures its report and status without
# touching the test's `output`, `status` or `lines`.
capture() {
    report=''
    rc=0
    report="$("$@" 2>&1)" || rc=$?
}
