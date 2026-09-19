#
# bats-expect: meta
#
# Assertions about assertions. They run an assertion in a subshell, capture
# its report, and let a test state that an assertion passes or fails, and what
# it says when it fails. The library tests itself this way, and a project can
# test assertions of its own the same way.
#
#   assert_passes assert_equal a a
#   assert_fails assert_equal a b
#   assert_fails --partial 'values do not equal' assert_equal a b

#######################################
# Fails when the assertion given as arguments fails. The assertion runs in a
# subshell, so it cannot change the test's variables. Its report is included.
#
# Arguments:
#   $@ - The assertion and its arguments
# Returns:
#   0 - The assertion passed
#   1 - Otherwise, after the report
#######################################
assert_passes() {
    local report
    local -i result=0
    report="$("$@" 2>&1)" || result=$?
    if (( result != 0 )); then
        expect::meta::fail 'assertion failed, but it was expected to pass' "$report" \
            'assertion' "$*" 'status' "$result"
    fi
}

#######################################
# Fails when the assertion given as arguments passes, or when its report does
# not contain the expected text or match the expected regular expression.
#
# Usage: assert_fails [-p TEXT | --partial TEXT] [-e REGEXP | --regexp REGEXP] [--] ASSERTION ARGS...
#
# Options:
#   -p, --partial TEXT   The report must contain TEXT
#   -e, --regexp REGEXP  The report must match the extended regular expression
# Arguments:
#   ASSERTION - The assertion and its arguments
# Returns:
#   0 - The assertion failed, and its report matched when asked
#   1 - Otherwise, after the report, or after a usage error
#######################################
assert_fails() {
    local partial='' regexp=''
    while (( $# > 0 )); do
        case "$1" in
            -p|--partial)
                if (( $# < 2 )); then expect::report::error assert_fails "\`--partial' requires an argument"; return 1; fi
                partial="$2"; shift 2 ;;
            -e|--regexp)
                if (( $# < 2 )); then expect::report::error assert_fails "\`--regexp' requires an argument"; return 1; fi
                regexp="$2"; shift 2 ;;
            --) shift; break ;;
            *) break ;;
        esac
    done
    if (( $# == 0 )); then
        expect::report::error assert_fails 'expects an assertion to run'
        return 1
    fi
    [[ -n "$regexp" ]] && { expect::report::require_regex assert_fails "$regexp" || return 1; }

    local report
    local -i result=0
    report="$("$@" 2>&1)" || result=$?
    if (( result == 0 )); then
        expect::report::fail 'assertion passed, but it was expected to fail' 'assertion' "$*"
    elif [[ -n "$partial" && "$report" != *"$partial"* ]]; then
        expect::meta::fail 'assertion failed, but its report does not contain the text' "$report" \
            'assertion' "$*" 'text' "$partial"
    elif [[ -n "$regexp" ]] && [[ ! "$report" =~ $regexp ]]; then
        expect::meta::fail 'assertion failed, but its report does not match the regular expression' "$report" \
            'assertion' "$*" 'regexp' "$regexp"
    fi
}

# ------------------------------------------------------------------------------
# Internal
# ------------------------------------------------------------------------------

#######################################
# Prints a report with rows for the pairs and the inner assertion's report as
# a block underneath, and fails.
#
# Arguments:
#   $1 (String)  - The title
#   $2 (String)  - The inner report
#   $@ (Strings) - key value [key value ...]
# Returns:
#   1 - Always
#######################################
expect::meta::fail() {
    local title="$1" inner="$2"
    shift 2
    {
        expect::report::rows "$(expect::report::width "$@")" "$@"
        expect::report::blocks 'report' "$inner"
    } | expect::report::fail_body "$title"
}
