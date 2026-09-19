#
# bats-expect: variable
#
# Assertions on a variable by name: whether it is set, empty, equal to a value,
# and how it is declared. Passing the name instead of the value lets an
# assertion tell "unset" from "empty" and check attributes. Local variables of
# the test are visible to these functions through bash's dynamic scoping.
#
#   assert_var_set HOME
#   refute_var_empty PATH
#   assert_var_equal SHELL /bin/bash
#   assert_declared -a items
#   assert_declared -x TERM

#######################################
# Fails when the variable is not set. An empty value counts as set; a
# variable declared without a value, as `local x` does, counts as unset.
#
# Arguments:
#   $1 (String) - The variable name
# Returns:
#   0 - Set
#   1 - Otherwise, after the report, or after a usage error for a bad name
#######################################
assert_var_set() {
    expect::variable::require_name assert_var_set "${1-}" || return 1
    if ! expect::variable::is_set "$1"; then
        expect::report::fail 'variable is not set' 'variable' "$1"
    fi
}

#######################################
# Fails when the variable is set.
#
# Arguments:
#   $1 (String) - The variable name
# Returns:
#   0 - Unset
#   1 - Otherwise, after the report, or after a usage error for a bad name
#######################################
refute_var_set() {
    expect::variable::require_name refute_var_set "${1-}" || return 1
    if expect::variable::is_set "$1"; then
        expect::report::fail 'variable is set' 'variable' "$1" 'value' "$(expect::variable::value "$1")"
    fi
}

#######################################
# Fails when the variable is unset or has a value.
#
# Arguments:
#   $1 (String) - The variable name
# Returns:
#   0 - Set and empty
#   1 - Otherwise, after the report, or after a usage error for a bad name
#######################################
assert_var_empty() {
    expect::variable::require_name assert_var_empty "${1-}" || return 1
    if ! expect::variable::is_set "$1"; then
        expect::report::fail 'variable is not set' 'variable' "$1"
    elif [[ -n "$(expect::variable::value "$1")" ]]; then
        expect::report::fail 'variable is not empty' 'variable' "$1" 'value' "$(expect::variable::value "$1")"
    fi
}

#######################################
# Fails when the variable is unset or empty.
#
# Arguments:
#   $1 (String) - The variable name
# Returns:
#   0 - Set and not empty
#   1 - Otherwise, after the report, or after a usage error for a bad name
#######################################
refute_var_empty() {
    expect::variable::require_name refute_var_empty "${1-}" || return 1
    if ! expect::variable::is_set "$1"; then
        expect::report::fail 'variable is not set' 'variable' "$1"
    elif [[ -z "$(expect::variable::value "$1")" ]]; then
        expect::report::fail 'variable is empty' 'variable' "$1"
    fi
}

#######################################
# Fails when the variable is unset or its value differs from the expectation.
# For an array, the value is the elements joined by spaces.
#
# Arguments:
#   $1 (String) - The variable name
#   $2 (String) - The expected value
# Returns:
#   0 - Set and equal
#   1 - Otherwise, after the report, or after a usage error for a bad name
#######################################
assert_var_equal() {
    expect::variable::require_name assert_var_equal "${1-}" || return 1
    if ! expect::variable::is_set "$1"; then
        expect::report::fail 'variable is not set' 'variable' "$1" 'expected' "${2-}"
        return 1
    fi
    local actual; actual="$(expect::variable::value "$1")"
    if [[ "$actual" != "${2-}" ]]; then
        expect::report::fail 'variable value differs' 'variable' "$1" 'expected' "${2-}" 'actual' "$actual"
    fi
}

#######################################
# Fails when the variable is set to the given value. An unset variable passes.
#
# Arguments:
#   $1 (String) - The variable name
#   $2 (String) - The value it must not have
# Returns:
#   0 - Unset or different
#   1 - Otherwise, after the report, or after a usage error for a bad name
#######################################
refute_var_equal() {
    expect::variable::require_name refute_var_equal "${1-}" || return 1
    expect::variable::is_set "$1" || return 0
    local actual; actual="$(expect::variable::value "$1")"
    if [[ "$actual" == "${2-}" ]]; then
        expect::report::fail 'variable has the unexpected value' 'variable' "$1" 'unexpected' "${2-}"
    fi
}

#######################################
# Fails when the name is not declared with the given attribute. Without an
# attribute, the name only has to be declared.
#
# Usage: assert_declared [-a|-A|-f|-i|-n|-r|-x] NAME
#
# Options:
#   -a  indexed array      -A  associative array   -f  function
#   -i  integer            -n  nameref             -r  readonly
#   -x  exported
# Arguments:
#   NAME (String) - The variable or, with -f, function name
# Returns:
#   0 - Declared as asked
#   1 - Otherwise, after the report, or after a usage error for a bad name
#######################################
assert_declared() {
    local attribute='' name
    expect::variable::parse_declared assert_declared "$@" || return 1
    local title='variable is not declared'
    [[ -n "$attribute" ]] && title="variable is not declared as $(expect::variable::kind_name "$attribute")"
    if ! expect::variable::has_attribute "$name" "$attribute"; then
        local declared; declared="$(expect::variable::declaration "$name")"
        expect::report::fail "$title" 'variable' "$name" 'declaration' "${declared:-none}"
    fi
}

#######################################
# Fails when the name is declared with the given attribute. Without an
# attribute, the name must not be declared at all. Same options as
# assert_declared.
#
# Arguments:
#   NAME (String) - The variable or, with -f, function name
# Returns:
#   0 - Not declared as asked
#   1 - Otherwise, after the report, or after a usage error for a bad name
#######################################
refute_declared() {
    local attribute='' name
    expect::variable::parse_declared refute_declared "$@" || return 1
    local title='variable is declared'
    [[ -n "$attribute" ]] && title="variable is declared as $(expect::variable::kind_name "$attribute")"
    if expect::variable::has_attribute "$name" "$attribute"; then
        expect::report::fail "$title" 'variable' "$name" 'declaration' "$(expect::variable::declaration "$name")"
    fi
}

# ------------------------------------------------------------------------------
# Internal
# ------------------------------------------------------------------------------

#######################################
# Tells whether a variable has a value. `local x` without a value is declared
# but not set, and `declare -p` prints that as a line without `=`.
#
# Arguments:
#   $1 (String) - The variable name
# Returns:
#   0 - Set
#   1 - Unset or not declared
#######################################
expect::variable::is_set() {
    local declaration
    declaration="$(declare -p "$1" 2>/dev/null)" || return 1
    [[ "$declaration" == *=* ]]
}

#######################################
# Fails with a usage error when the name is not a shell identifier.
#
# Arguments:
#   $1 (String) - The calling assertion
#   $2 (String) - The name
# Returns:
#   0 - Valid
#   1 - After the error report
#######################################
expect::variable::require_name() {
    if [[ ! "$2" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        expect::report::error "$1" "not a variable name: \`$2'"
        return 1
    fi
}

#######################################
# Prints the value of a variable: the scalar, or the elements of an array
# joined by spaces.
#
# Arguments:
#   $1 (String) - The variable name
# Outputs:
#   The value, or nothing when the variable is not declared
#######################################
expect::variable::value() {
    local declaration
    declaration="$(declare -p "$1" 2>/dev/null)" || return 0
    if [[ "$declaration" == "declare -"[aA]* ]]; then
        local -n expect_variable_ref="$1"
        printf '%s\n' "${expect_variable_ref[*]}"
    else
        printf '%s\n' "${!1}"
    fi
}

#######################################
# Prints the `declare -p` line of a variable, or `declare -f` of a function.
#
# Arguments:
#   $1 (String) - The name
# Outputs:
#   The declaration, or nothing when the name is not declared
#######################################
expect::variable::declaration() {
    declare -p "$1" 2>/dev/null || declare -F "$1" 2>/dev/null || true
}

#######################################
# Parses `[-attribute] NAME` into the caller's `attribute` and `name`, and
# validates the name: an identifier, or a function name that may contain
# `:`, `.` and `-` after the first character.
#
# Arguments:
#   $1 (String) - The calling assertion
#   $@          - The assertion's arguments
# Returns:
#   0 - Parsed
#   1 - After a usage error report
#######################################
expect::variable::parse_declared() {
    local caller="$1"
    shift
    if [[ "${1-}" =~ ^-[aAfinrx]$ ]]; then
        attribute="${1#-}"
        shift
    fi
    name="${1-}"
    if [[ "$attribute" == f ]]; then
        [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_:.-]*$ ]] && return 0
        expect::report::error "$caller" "not a function name: \`$name'"
        return 1
    fi
    expect::variable::require_name "$caller" "$name"
}

#######################################
# Tells whether a name carries an attribute. With no attribute, whether it is
# declared at all.
#
# Arguments:
#   $1 (String) - The name
#   $2 (String) - The attribute letter, or empty
# Returns:
#   0 - Yes
#   1 - No
#######################################
expect::variable::has_attribute() {
    local name="$1" attribute="$2" declaration
    if [[ "$attribute" == f ]]; then
        declare -F "$name" >/dev/null 2>&1
        return
    fi
    declaration="$(declare -p "$name" 2>/dev/null)" || return 1
    [[ -z "$attribute" ]] && return 0
    # `declare -p` prints the attributes as one flag group after "declare -".
    local flags="${declaration#declare -}"
    flags="${flags%% *}"
    [[ "$flags" == *"$attribute"* ]]
}

#######################################
# Names an attribute for a report title.
#
# Arguments:
#   $1 (String) - The attribute letter
# Outputs:
#   The words, such as "an indexed array"
#######################################
expect::variable::kind_name() {
    case "$1" in
        a) printf 'an indexed array\n' ;;
        A) printf 'an associative array\n' ;;
        f) printf 'a function\n' ;;
        i) printf 'an integer\n' ;;
        n) printf 'a nameref\n' ;;
        r) printf 'readonly\n' ;;
        x) printf 'exported\n' ;;
    esac
}
