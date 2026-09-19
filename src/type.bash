#
# bats-expect: type
#
# Assertions on the shape of a value: integer, number, boolean, regular
# expression, identifier. Each has a refute twin.
#
#   assert_is_int "$count"
#   assert_is_number "$ratio"
#   assert_is_bool "$flag"
#   assert_is_regex "$pattern"

#######################################
# Fails when the value is not an integer: an optional sign and digits.
#
# Arguments:
#   $1 (String) - The value
# Returns:
#   0 - An integer
#   1 - Otherwise, after the report
#######################################
assert_is_int() {
    if [[ ! "${1-}" =~ ^[+-]?[0-9]+$ ]]; then
        expect::report::fail 'value is not an integer' 'value' "${1-}"
    fi
}

#######################################
# Fails when the value is an integer.
#
# Arguments:
#   $1 (String) - The value
# Returns:
#   0 - Not an integer
#   1 - Otherwise, after the report
#######################################
refute_is_int() {
    if [[ "${1-}" =~ ^[+-]?[0-9]+$ ]]; then
        expect::report::fail 'value is an integer' 'value' "${1-}"
    fi
}

#######################################
# Fails when the value is not a decimal number: an optional sign, digits and
# an optional fraction. Integers are numbers.
#
# Arguments:
#   $1 (String) - The value
# Returns:
#   0 - A number
#   1 - Otherwise, after the report
#######################################
assert_is_number() {
    if ! expect::type::is_number "${1-}"; then
        expect::report::fail 'value is not a number' 'value' "${1-}"
    fi
}

#######################################
# Fails when the value is a decimal number.
#
# Arguments:
#   $1 (String) - The value
# Returns:
#   0 - Not a number
#   1 - Otherwise, after the report
#######################################
refute_is_number() {
    if expect::type::is_number "${1-}"; then
        expect::report::fail 'value is a number' 'value' "${1-}"
    fi
}

#######################################
# Fails when the value is not `true` or `false`.
#
# Arguments:
#   $1 (String) - The value
# Returns:
#   0 - A boolean
#   1 - Otherwise, after the report
#######################################
assert_is_bool() {
    if [[ "${1-}" != true && "${1-}" != false ]]; then
        expect::report::fail 'value is not a boolean' 'value' "${1-}" 'expected' 'true or false'
    fi
}

#######################################
# Fails when the value is `true` or `false`.
#
# Arguments:
#   $1 (String) - The value
# Returns:
#   0 - Not a boolean
#   1 - Otherwise, after the report
#######################################
refute_is_bool() {
    if [[ "${1-}" == true || "${1-}" == false ]]; then
        expect::report::fail 'value is a boolean' 'value' "${1-}"
    fi
}

#######################################
# Fails when the value does not compile as an extended regular expression.
#
# Arguments:
#   $1 (String) - The value
# Returns:
#   0 - A valid regular expression
#   1 - Otherwise, after the report
#######################################
assert_is_regex() {
    if ! expect::type::is_regex "${1-}"; then
        expect::report::fail 'value is not a valid extended regular expression' 'value' "${1-}"
    fi
}

#######################################
# Fails when the value compiles as an extended regular expression.
#
# Arguments:
#   $1 (String) - The value
# Returns:
#   0 - Not a valid regular expression
#   1 - Otherwise, after the report
#######################################
refute_is_regex() {
    if expect::type::is_regex "${1-}"; then
        expect::report::fail 'value is a valid extended regular expression' 'value' "${1-}"
    fi
}

#######################################
# Fails when the value is not a shell identifier: letters, digits and
# underscores, not starting with a digit.
#
# Arguments:
#   $1 (String) - The value
# Returns:
#   0 - An identifier
#   1 - Otherwise, after the report
#######################################
assert_is_identifier() {
    if [[ ! "${1-}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        expect::report::fail 'value is not an identifier' 'value' "${1-}"
    fi
}

#######################################
# Fails when the value is a shell identifier.
#
# Arguments:
#   $1 (String) - The value
# Returns:
#   0 - Not an identifier
#   1 - Otherwise, after the report
#######################################
refute_is_identifier() {
    if [[ "${1-}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        expect::report::fail 'value is an identifier' 'value' "${1-}"
    fi
}

# ------------------------------------------------------------------------------
# Internal
# ------------------------------------------------------------------------------

#######################################
# Tells whether a value is a decimal number.
#
# Arguments:
#   $1 (String) - The value
# Returns:
#   0 - A number
#   1 - Not a number
#######################################
expect::type::is_number() {
    [[ "$1" =~ ^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]]
}

#######################################
# Tells whether a value compiles as an extended regular expression. A regex
# that does not compile makes `[[ =~ ]]` return 2; a plain non-match returns 1.
#
# Arguments:
#   $1 (String) - The value
# Returns:
#   0 - Valid
#   1 - Invalid
#######################################
expect::type::is_regex() {
    local -i result=0
    # shellcheck disable=SC2319  # the status of the test is what is being read
    [[ '' =~ $1 ]] 2>/dev/null || result=$?
    (( result != 2 ))
}
