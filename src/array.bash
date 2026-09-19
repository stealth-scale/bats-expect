#
# bats-expect: array
#
# Assertions on an array by name, since an array cannot be passed as one
# argument. Indexed and associative arrays are both accepted; `contains`,
# `equal` and `length` look at the values, `has_key` at the keys.
#
#   items=(a b c)
#   assert_array_contains items b
#   assert_array_equal items a b c
#   assert_array_length items 3
#   declare -A map=([k]=v)
#   assert_array_has_key map k

#######################################
# Fails when no element of the array equals the value.
#
# Arguments:
#   $1 (String) - The array name
#   $2 (String) - The value
# Returns:
#   0 - An element equals the value
#   1 - Otherwise, after the report, or after a usage error for a non-array
#######################################
assert_array_contains() {
    expect::array::require assert_array_contains "${1-}" || return 1
    local -n expect_array_ref="$1"
    local element
    for element in "${expect_array_ref[@]}"; do
        [[ "$element" == "${2-}" ]] && return 0
    done
    expect::array::fail 'array does not contain value' 'elements' "$(expect::array::join "${expect_array_ref[@]}")" \
        'array' "$1" 'value' "${2-}"
}

#######################################
# Fails when an element of the array equals the value.
#
# Arguments:
#   $1 (String) - The array name
#   $2 (String) - The value
# Returns:
#   0 - No element equals the value
#   1 - Otherwise, after the report, or after a usage error for a non-array
#######################################
refute_array_contains() {
    expect::array::require refute_array_contains "${1-}" || return 1
    local -n expect_array_ref="$1"
    local element
    for element in "${expect_array_ref[@]}"; do
        if [[ "$element" == "${2-}" ]]; then
            expect::array::fail 'array contains value' 'elements' "$(expect::array::join "${expect_array_ref[@]}")" \
                'array' "$1" 'value' "${2-}"
            return 1
        fi
    done
    return 0
}

#######################################
# Fails when the array's elements, in order, are not the values given.
#
# Arguments:
#   $1 (String)  - The array name
#   $@ (Strings) - The expected elements
# Returns:
#   0 - Same elements in the same order
#   1 - Otherwise, after the report, or after a usage error for a non-array
#######################################
assert_array_equal() {
    expect::array::require assert_array_equal "${1-}" || return 1
    local -n expect_array_ref="$1"
    shift
    if ! expect::array::same "$@"; then
        expect::report::fail 'array elements differ' \
            'expected' "$(expect::array::join "$@")" 'actual' "$(expect::array::join "${expect_array_ref[@]}")"
    fi
}

#######################################
# Fails when the array's elements, in order, are exactly the values given.
#
# Arguments:
#   $1 (String)  - The array name
#   $@ (Strings) - The elements it must not equal
# Returns:
#   0 - The elements differ
#   1 - Otherwise, after the report, or after a usage error for a non-array
#######################################
refute_array_equal() {
    expect::array::require refute_array_equal "${1-}" || return 1
    local -n expect_array_ref="$1"
    shift
    if expect::array::same "$@"; then
        expect::report::fail 'array elements should differ' 'elements' "$(expect::array::join "${expect_array_ref[@]}")"
    fi
}

#######################################
# Fails when the array does not have exactly the given number of elements.
#
# Arguments:
#   $1 (String)  - The array name
#   $2 (Integer) - The expected length
# Returns:
#   0 - The lengths match
#   1 - Otherwise, after the report, or after a usage error
#######################################
assert_array_length() {
    expect::array::require assert_array_length "${1-}" || return 1
    if [[ ! "${2-}" =~ ^[0-9]+$ ]]; then
        expect::report::error assert_array_length "expected length must be an integer: \`${2-}'"
        return 1
    fi
    local -n expect_array_ref="$1"
    if (( ${#expect_array_ref[@]} != $2 )); then
        expect::report::fail 'array length differs' 'array' "$1" 'expected' "$2" 'actual' "${#expect_array_ref[@]}"
    fi
}

#######################################
# Fails when the array has elements.
#
# Arguments:
#   $1 (String) - The array name
# Returns:
#   0 - Empty
#   1 - Otherwise, after the report, or after a usage error for a non-array
#######################################
assert_array_empty() {
    expect::array::require assert_array_empty "${1-}" || return 1
    local -n expect_array_ref="$1"
    if (( ${#expect_array_ref[@]} > 0 )); then
        expect::array::fail 'array is not empty' 'elements' "$(expect::array::join "${expect_array_ref[@]}")" \
            'array' "$1" 'length' "${#expect_array_ref[@]}"
    fi
}

#######################################
# Fails when the array has no elements.
#
# Arguments:
#   $1 (String) - The array name
# Returns:
#   0 - Not empty
#   1 - Otherwise, after the report, or after a usage error for a non-array
#######################################
refute_array_empty() {
    expect::array::require refute_array_empty "${1-}" || return 1
    local -n expect_array_ref="$1"
    if (( ${#expect_array_ref[@]} == 0 )); then
        expect::report::fail 'array is empty' 'array' "$1"
    fi
}

#######################################
# Fails when the array has no element under the key. For an indexed array the
# key is an index.
#
# Arguments:
#   $1 (String) - The array name
#   $2 (String) - The key
# Returns:
#   0 - The key exists
#   1 - Otherwise, after the report, or after a usage error for a non-array
#######################################
assert_array_has_key() {
    expect::array::require assert_array_has_key "${1-}" || return 1
    local -n expect_array_ref="$1"
    if [[ ! -v "expect_array_ref[${2-}]" ]]; then
        expect::array::fail 'array has no such key' 'keys' "$(expect::array::join "${!expect_array_ref[@]}")" \
            'array' "$1" 'key' "${2-}"
    fi
}

#######################################
# Fails when the array has an element under the key.
#
# Arguments:
#   $1 (String) - The array name
#   $2 (String) - The key
# Returns:
#   0 - The key does not exist
#   1 - Otherwise, after the report, or after a usage error for a non-array
#######################################
refute_array_has_key() {
    expect::array::require refute_array_has_key "${1-}" || return 1
    local -n expect_array_ref="$1"
    if [[ -v "expect_array_ref[${2-}]" ]]; then
        expect::report::fail 'array has the key' 'array' "$1" 'key' "${2-}" 'value' "${expect_array_ref[${2-}]}"
    fi
}

# ------------------------------------------------------------------------------
# Internal
# ------------------------------------------------------------------------------

#######################################
# Fails with a usage error unless the name is a declared indexed or
# associative array.
#
# Arguments:
#   $1 (String) - The calling assertion
#   $2 (String) - The name
# Returns:
#   0 - An array
#   1 - After the error report
#######################################
expect::array::require() {
    local caller="$1" name="$2" declaration
    if [[ ! "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        expect::report::error "$caller" "not a variable name: \`$name'"
        return 1
    fi
    if ! declaration="$(declare -p "$name" 2>/dev/null)"; then
        expect::report::error "$caller" "\`$name' is not declared"
        return 1
    fi
    if [[ "$declaration" != "declare -"[aA]* ]]; then
        expect::report::error "$caller" "\`$name' is not an array: $declaration"
        return 1
    fi
}

#######################################
# Tells whether the caller's expect_array_ref holds exactly the arguments, in
# order. Elements are compared one by one, so a newline inside an element
# cannot make two different arrays look the same.
#
# Arguments:
#   $@ (Strings) - The expected elements
# Returns:
#   0 - Same
#   1 - Different
#######################################
expect::array::same() {
    (( ${#expect_array_ref[@]} == $# )) || return 1
    local -a values=("${expect_array_ref[@]}")
    local -i i=0
    local expected
    for expected in "$@"; do
        [[ "${values[i]}" == "$expected" ]] || return 1
        (( ++i ))
    done
    return 0
}

#######################################
# Prints a report with rows for the pairs and the elements or keys as a block
# underneath, and fails.
#
# Arguments:
#   $1 (String)  - The title
#   $2 (String)  - The block's key: elements or keys
#   $3 (String)  - The block's value, one item per line
#   $@ (Strings) - key value [key value ...] for the rows
# Returns:
#   1 - Always
#######################################
expect::array::fail() {
    local title="$1" block_key="$2" block="$3"
    shift 3
    {
        expect::report::rows "$(expect::report::width "$@")" "$@"
        expect::report::blocks "$block_key" "$block"
    } | expect::report::fail_body "$title"
}

#######################################
# Prints elements one per line, so a report shows them apart and an empty
# element is visible.
#
# Arguments:
#   $@ (Strings) - The elements
# Outputs:
#   The elements, or nothing for none
#######################################
expect::array::join() {
    (( $# == 0 )) && return 0
    printf '%s\n' "$@"
}
