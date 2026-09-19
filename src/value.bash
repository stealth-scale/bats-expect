#
# bats-expect: value
#
# Assertions on a string value. The value is the first argument and the
# expectation the second, so a test reads "assert VALUE equals/contains X".
# A missing argument is an empty string; nothing here trips `set -u`.
#
#   assert_equal "$version" 1.2.0
#   assert_contains "$path" /usr
#   assert_starts_with "$url" https://
#   refute_empty "$name"

#######################################
# Fails when the two values differ.
#
# Arguments:
#   $1 (String) - The actual value
#   $2 (String) - The expected value
# Returns:
#   0 - Equal
#   1 - Otherwise, after the report
#######################################
assert_equal() {
    if [[ "${1-}" != "${2-}" ]]; then
        expect::report::fail 'values do not equal' 'expected' "${2-}" 'actual' "${1-}"
    fi
}

#######################################
# Fails when the two values are equal.
#
# Arguments:
#   $1 (String) - The actual value
#   $2 (String) - The value it must differ from
# Returns:
#   0 - Different
#   1 - Otherwise, after the report
#######################################
refute_equal() {
    if [[ "${1-}" == "${2-}" ]]; then
        expect::report::fail 'values should not be equal' 'unexpected' "${2-}" 'actual' "${1-}"
    fi
}

#######################################
# bats-assert's name for refute_equal.
#
# Arguments:
#   $1 (String) - The actual value
#   $2 (String) - The value it must differ from
# Returns:
#   0 - Different
#   1 - Otherwise, after the report
#######################################
assert_not_equal() {
    refute_equal "$@"
}

#######################################
# Fails when the value does not match the extended regular expression.
#
# Arguments:
#   $1 (String) - The value
#   $2 (String) - The regular expression
# Returns:
#   0 - Matches
#   1 - Otherwise, after the report, or after a usage error for an invalid regex
#######################################
assert_regex() {
    local value="${1-}" pattern="${2-}"
    expect::report::require_regex assert_regex "$pattern" || return 1
    if [[ ! "$value" =~ $pattern ]]; then
        expect::report::pairs 8 'value' "$value" 'pattern' "$pattern" 'case' "$(expect::value::case_mode)" \
            | expect::report::fail_body 'value does not match regular expression'
    fi
}

#######################################
# Fails when the value matches the extended regular expression. The report
# shows the matched text.
#
# Arguments:
#   $1 (String) - The value
#   $2 (String) - The regular expression
# Returns:
#   0 - Does not match
#   1 - Otherwise, after the report, or after a usage error for an invalid regex
#######################################
refute_regex() {
    local value="${1-}" pattern="${2-}"
    expect::report::require_regex refute_regex "$pattern" || return 1
    if [[ "$value" =~ $pattern ]]; then
        expect::report::pairs 8 'value' "$value" 'pattern' "$pattern" 'match' "${BASH_REMATCH[0]}" \
            'case' "$(expect::value::case_mode)" | expect::report::fail_body 'value matches regular expression'
    fi
}

#######################################
# Fails when the value is not empty.
#
# Arguments:
#   $1 (String) - The value
# Returns:
#   0 - Empty
#   1 - Otherwise, after the report
#######################################
assert_empty() {
    if [[ -n "${1-}" ]]; then
        expect::report::fail 'value is not empty' 'value' "$1"
    fi
}

#######################################
# Fails when the value is empty.
#
# Arguments:
#   $1 (String) - The value
# Returns:
#   0 - Not empty
#   1 - Otherwise, after the report
#######################################
refute_empty() {
    if [[ -z "${1-}" ]]; then
        expect::report::fail 'value is empty' 'value' ''
    fi
}

#######################################
# Fails when the value does not contain the substring. The substring is
# literal: `*`, `?` and `[` are characters, not patterns.
#
# Arguments:
#   $1 (String) - The value
#   $2 (String) - The substring
# Returns:
#   0 - Contains it
#   1 - Otherwise, after the report
#######################################
assert_contains() {
    if [[ "${1-}" != *"${2-}"* ]]; then
        expect::report::fail 'value does not contain substring' 'value' "${1-}" 'substring' "${2-}"
    fi
}

#######################################
# Fails when the value contains the substring.
#
# Arguments:
#   $1 (String) - The value
#   $2 (String) - The substring
# Returns:
#   0 - Does not contain it
#   1 - Otherwise, after the report
#######################################
refute_contains() {
    if [[ "${1-}" == *"${2-}"* ]]; then
        expect::report::fail 'value contains substring' 'value' "${1-}" 'substring' "${2-}"
    fi
}

#######################################
# Fails when the value does not start with the prefix. The prefix is literal.
#
# Arguments:
#   $1 (String) - The value
#   $2 (String) - The prefix
# Returns:
#   0 - Starts with it
#   1 - Otherwise, after the report
#######################################
assert_starts_with() {
    if [[ "${1-}" != "${2-}"* ]]; then
        expect::report::fail 'value does not start with prefix' 'value' "${1-}" 'prefix' "${2-}"
    fi
}

#######################################
# Fails when the value starts with the prefix.
#
# Arguments:
#   $1 (String) - The value
#   $2 (String) - The prefix
# Returns:
#   0 - Does not start with it
#   1 - Otherwise, after the report
#######################################
refute_starts_with() {
    if [[ "${1-}" == "${2-}"* ]]; then
        expect::report::fail 'value starts with prefix' 'value' "${1-}" 'prefix' "${2-}"
    fi
}

#######################################
# Fails when the value does not end with the suffix. The suffix is literal.
#
# Arguments:
#   $1 (String) - The value
#   $2 (String) - The suffix
# Returns:
#   0 - Ends with it
#   1 - Otherwise, after the report
#######################################
assert_ends_with() {
    if [[ "${1-}" != *"${2-}" ]]; then
        expect::report::fail 'value does not end with suffix' 'value' "${1-}" 'suffix' "${2-}"
    fi
}

#######################################
# Fails when the value ends with the suffix.
#
# Arguments:
#   $1 (String) - The value
#   $2 (String) - The suffix
# Returns:
#   0 - Does not end with it
#   1 - Otherwise, after the report
#######################################
refute_ends_with() {
    if [[ "${1-}" == *"${2-}" ]]; then
        expect::report::fail 'value ends with suffix' 'value' "${1-}" 'suffix' "${2-}"
    fi
}

#######################################
# Fails when the value is not one of the items given after it.
#
# Arguments:
#   $1 (String)  - The value
#   $@ (Strings) - The allowed items
# Returns:
#   0 - The value equals one of the items
#   1 - Otherwise, after the report
#######################################
assert_one_of() {
    local value="${1-}" item
    shift
    for item in "$@"; do
        [[ "$value" == "$item" ]] && return 0
    done
    expect::report::fail 'value is not one of the items' 'value' "$value" 'items' "$(expect::value::join "$@")"
}

#######################################
# Fails when the value is one of the items given after it.
#
# Arguments:
#   $1 (String)  - The value
#   $@ (Strings) - The refused items
# Returns:
#   0 - The value equals none of the items
#   1 - Otherwise, after the report
#######################################
refute_one_of() {
    local value="${1-}" item
    shift
    for item in "$@"; do
        if [[ "$value" == "$item" ]]; then
            expect::report::fail 'value is one of the items' 'value' "$value" 'items' "$(expect::value::join "$@")"
            return 1
        fi
    done
    return 0
}

#######################################
# Fails when the value does not have exactly the given number of lines. A
# trailing newline does not count as a line.
#
# Arguments:
#   $1 (String)  - The value
#   $2 (Integer) - The expected line count
# Returns:
#   0 - The counts match
#   1 - Otherwise, after the report, or after a usage error for a non-integer
#######################################
assert_line_count() {
    if [[ ! "${2-}" =~ ^[0-9]+$ ]]; then
        expect::report::error assert_line_count "expected line count must be an integer: \`${2-}'"
        return 1
    fi
    local -i actual
    actual="$(expect::report::count_lines "${1-}")"
    if (( actual != $2 )); then
        {
            expect::report::rows 8 'expected' "$2" 'actual' "$actual"
            expect::report::pairs 8 'value' "${1-}"
        } | expect::report::fail_body 'line count differs'
    fi
}

# ------------------------------------------------------------------------------
# Internal
# ------------------------------------------------------------------------------

#######################################
# Names the case mode of pattern matching for a regex report.
#
# Outputs:
#   insensitive when shopt nocasematch is on, sensitive otherwise
#######################################
expect::value::case_mode() {
    if shopt -q nocasematch; then printf 'insensitive\n'; else printf 'sensitive\n'; fi
}

#######################################
# Joins the arguments with ", " for a report row.
#
# Arguments:
#   $@ (Strings) - The items
# Outputs:
#   The joined items
#######################################
expect::value::join() {
    (( $# == 0 )) && { printf '\n'; return 0; }
    printf '%s' "$1"
    shift
    local item
    for item in "$@"; do printf ', %s' "$item"; done
    printf '\n'
}
