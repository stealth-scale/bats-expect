#
# bats-expect: number
#
# Comparisons between numbers. Integers and decimals are accepted; awk does
# the comparison, so decimals work and a value that is not a number is a usage
# error rather than a silent zero.
#
#   assert_gt "$count" 0
#   assert_le "$elapsed" 2.5
#   assert_between "$port" 1024 65535
#   assert_within_delta "$measured" 1.0 0.05

#######################################
# Fails when the value is not greater than the bound.
#
# Arguments:
#   $1 (Number) - The value
#   $2 (Number) - The bound
# Returns:
#   0 - Greater
#   1 - Otherwise, after the report, or after a usage error for a non-number
#######################################
assert_gt() {
    expect::number::compare assert_gt '>' 'greater than' "${1-}" "${2-}"
}

#######################################
# Fails when the value is not greater than or equal to the bound.
#
# Arguments:
#   $1 (Number) - The value
#   $2 (Number) - The bound
# Returns:
#   0 - Greater or equal
#   1 - Otherwise, after the report, or after a usage error for a non-number
#######################################
assert_ge() {
    expect::number::compare assert_ge '>=' 'greater than or equal to' "${1-}" "${2-}"
}

#######################################
# Fails when the value is not less than the bound.
#
# Arguments:
#   $1 (Number) - The value
#   $2 (Number) - The bound
# Returns:
#   0 - Less
#   1 - Otherwise, after the report, or after a usage error for a non-number
#######################################
assert_lt() {
    expect::number::compare assert_lt '<' 'less than' "${1-}" "${2-}"
}

#######################################
# Fails when the value is not less than or equal to the bound.
#
# Arguments:
#   $1 (Number) - The value
#   $2 (Number) - The bound
# Returns:
#   0 - Less or equal
#   1 - Otherwise, after the report, or after a usage error for a non-number
#######################################
assert_le() {
    expect::number::compare assert_le '<=' 'less than or equal to' "${1-}" "${2-}"
}

#######################################
# Fails when the value is outside the inclusive range.
#
# Arguments:
#   $1 (Number) - The value
#   $2 (Number) - The lower bound
#   $3 (Number) - The upper bound
# Returns:
#   0 - Inside the range
#   1 - Otherwise, after the report, or after a usage error for a non-number
#######################################
assert_between() {
    expect::number::require assert_between "${1-}" "${2-}" "${3-}" || return 1
    if ! expect::number::test "$1" '>=' "$2" || ! expect::number::test "$1" '<=' "$3"; then
        expect::report::fail 'value is outside the range' 'value' "$1" 'range' "$2 to $3"
    fi
}

#######################################
# Fails when the value is inside the inclusive range.
#
# Arguments:
#   $1 (Number) - The value
#   $2 (Number) - The lower bound
#   $3 (Number) - The upper bound
# Returns:
#   0 - Outside the range
#   1 - Otherwise, after the report, or after a usage error for a non-number
#######################################
refute_between() {
    expect::number::require refute_between "${1-}" "${2-}" "${3-}" || return 1
    if expect::number::test "$1" '>=' "$2" && expect::number::test "$1" '<=' "$3"; then
        expect::report::fail 'value is inside the range' 'value' "$1" 'range' "$2 to $3"
    fi
}

#######################################
# Fails when the actual value is further than delta from the expected one.
#
# Arguments:
#   $1 (Number) - The actual value
#   $2 (Number) - The expected value
#   $3 (Number) - The allowed difference, inclusive
# Returns:
#   0 - Within delta
#   1 - Otherwise, after the report, or after a usage error for a non-number
#######################################
assert_within_delta() {
    expect::number::require assert_within_delta "${1-}" "${2-}" "${3-}" || return 1
    local difference
    difference="$(awk -v a="$1" -v b="$2" 'BEGIN { d = a - b; if (d < 0) d = -d; printf "%g", d }')"
    if ! expect::number::test "$difference" '<=' "$3"; then
        expect::report::fail 'value is not within delta' 'expected' "$2" 'actual' "$1" 'delta' "$3" 'difference' "$difference"
    fi
}

# ------------------------------------------------------------------------------
# Internal
# ------------------------------------------------------------------------------

#######################################
# Fails with a usage error when an argument is not a number.
#
# Arguments:
#   $1 (String)  - The calling assertion
#   $@ (Strings) - The values to check
# Returns:
#   0 - All numbers
#   1 - After the error report
#######################################
expect::number::require() {
    local caller="$1" value
    shift
    for value in "$@"; do
        if [[ ! "$value" =~ ^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]]; then
            expect::report::error "$caller" "not a number: \`$value'"
            return 1
        fi
    done
}

#######################################
# Compares two numbers with awk.
#
# Arguments:
#   $1 (Number) - The left operand
#   $2 (String) - The operator: >, >=, < or <=
#   $3 (Number) - The right operand
# Returns:
#   0 - The comparison holds
#   1 - It does not
#######################################
expect::number::test() {
    awk -v a="$1" -v b="$3" -v op="$2" 'BEGIN {
        if (op == ">")  exit !(a > b)
        if (op == ">=") exit !(a >= b)
        if (op == "<")  exit !(a < b)
        if (op == "<=") exit !(a <= b)
        exit 1
    }'
}

#######################################
# The shared body of assert_gt, assert_ge, assert_lt and assert_le.
#
# Arguments:
#   $1 (String) - The calling assertion
#   $2 (String) - The operator
#   $3 (String) - The operator in words, for the report title
#   $4 (Number) - The value
#   $5 (Number) - The bound
# Returns:
#   0 - The comparison holds
#   1 - Otherwise, after the report, or after a usage error for a non-number
#######################################
expect::number::compare() {
    local caller="$1" op="$2" words="$3" actual="$4" bound="$5"
    expect::number::require "$caller" "$actual" "$bound" || return 1
    if ! expect::number::test "$actual" "$op" "$bound"; then
        expect::report::fail "value is not $words the bound" 'value' "$actual" 'bound' "$bound"
    fi
}
