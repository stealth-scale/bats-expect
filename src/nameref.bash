#
# bats-expect: nameref
#
# Support for functions that return their result through a nameref instead of
# stdout: `f out_var args...`. `run_nameref` calls one and fills `$status`,
# `$output` and `$lines` as bats' `run` does, without a subshell, so a test
# asserts on the returned value with the same assertions as on any output.
# `assert_nameref` is the one-line form.
#
#   run_nameref stealth::util::text::trim '  foo  '
#   assert_success
#   assert_output foo
#
#   assert_nameref foo stealth::util::text::trim '  foo  '

#######################################
# Calls a function with a fresh output variable as its first argument and the
# remaining arguments after it. Sets `$status` to the function's return code,
# `$output` to the value of the output variable, and `$lines` to its lines.
# For an array, `$output` joins the elements with newlines. The function runs
# in the current shell, so its side effects stay visible.
#
# Arguments:
#   $1 (String) - The function
#   $@          - Its arguments, after the output variable
# Globals:
#   status (Write), output (Write), lines (Write)
# Returns:
#   0 - The function ran; its own status is in $status
#   1 - After a usage error for a name that is not a function
#######################################
run_nameref() {
    local expect_nameref_function="${1-}"
    shift
    if ! declare -F "$expect_nameref_function" >/dev/null 2>&1; then
        expect::report::error run_nameref "not a function: \`$expect_nameref_function'"
        return 1
    fi
    local expect_nameref_out=''
    # shellcheck disable=SC2034  # read through the reference
    status=0
    "$expect_nameref_function" expect_nameref_out "$@" || status=$?
    local declaration
    declaration="$(declare -p expect_nameref_out 2>/dev/null)"
    if [[ "$declaration" == "declare -a"* ]]; then
        # shellcheck disable=SC2178  # the function redeclared the reference as an array
        local -n expect_nameref_ref=expect_nameref_out
        output="$(printf '%s\n' "${expect_nameref_ref[@]}")"
    else
        output="$expect_nameref_out"
    fi
    # shellcheck disable=SC2034  # read by the line assertions
    IFS=$'\n' read -r -d '' -a lines <<< "$output" || true
    return 0
}

#######################################
# Fails when the function does not return the expected value through its
# nameref, or returns a non-zero status.
#
# Arguments:
#   $1 (String) - The expected value
#   $2 (String) - The function
#   $@          - Its arguments, after the output variable
# Returns:
#   0 - The function returned 0 and the value
#   1 - Otherwise, after the report, or after a usage error
#######################################
assert_nameref() {
    local expected="${1-}"
    shift
    local status output
    # shellcheck disable=SC2034  # keeps run_nameref's lines out of the test's globals
    local -a lines
    run_nameref "$@" || return 1
    if (( status != 0 )); then
        expect::report::fail 'function failed' 'function' "$*" 'status' "$status" 'output' "$output"
    elif [[ "$output" != "$expected" ]]; then
        expect::report::fail 'nameref value differs' 'function' "$*" 'expected' "$expected" 'actual' "$output"
    fi
}

#######################################
# Fails when the function returns the value through its nameref with status 0.
#
# Arguments:
#   $1 (String) - The value it must not return
#   $2 (String) - The function
#   $@          - Its arguments, after the output variable
# Returns:
#   0 - The function failed or returned another value
#   1 - Otherwise, after the report, or after a usage error
#######################################
refute_nameref() {
    local unexpected="${1-}"
    shift
    local status output
    # shellcheck disable=SC2034  # keeps run_nameref's lines out of the test's globals
    local -a lines
    run_nameref "$@" || return 1
    if (( status == 0 )) && [[ "$output" == "$unexpected" ]]; then
        expect::report::fail 'nameref value equals, but it was expected to differ' 'function' "$*" 'value' "$output"
    fi
}
