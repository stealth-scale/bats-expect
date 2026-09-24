#!/usr/bin/env bats

# shellcheck disable=SC2034,SC2154,SC2030,SC2031
# Variables here are read by name through the library or set by `capture`, and
# every @test is its own process, not a subshell of the file.

# ==============================================================================
# bats-expect: variable - Test Suite
# ==============================================================================
#   01. assert_var_set, refute_var_set
#   02. assert_var_empty, refute_var_empty
#   03. assert_var_equal, refute_var_equal
#   04. assert_declared, refute_declared
# ==============================================================================

load helper
setup() { common_setup; }

# ==============================================================================
# GROUP 01: assert_var_set, refute_var_set
# ==============================================================================

@test "assert_var_set: variable with a value -> passes" {
    local x=1
    assert_passes assert_var_set x
}

@test "assert_var_set: variable with an empty value -> passes" {
    local e=''
    assert_passes assert_var_set e
}

@test "assert_var_set: unset variable -> variable is not set" {
    unset nope_zz
    assert_fails -p '-- variable is not set --' assert_var_set nope_zz
    assert_fails -p 'variable : nope_zz' assert_var_set nope_zz
}

@test "assert_var_set: declared without a value -> counts as unset" {
    local declared_only
    assert_fails -p 'variable is not set' assert_var_set declared_only
}

@test "assert_var_set: array -> passes" {
    local -a arr=(1)
    assert_passes assert_var_set arr
}

@test "assert_var_set: invalid name -> usage error" {
    assert_fails -p '-- ERROR: assert_var_set --' assert_var_set 'not a name'
    assert_fails -p 'not a variable name' assert_var_set '1x'
}

@test "refute_var_set: unset variable -> passes" {
    unset nope_zz
    assert_passes refute_var_set nope_zz
}

@test "refute_var_set: set variable -> variable is set, with its value" {
    local x=1
    assert_fails -p '-- variable is set --' refute_var_set x
    assert_fails -p 'value    : 1' refute_var_set x
}

# ==============================================================================
# GROUP 02: assert_var_empty, refute_var_empty
# ==============================================================================

@test "assert_var_empty: empty value -> passes" {
    local e=''
    assert_passes assert_var_empty e
}

@test "assert_var_empty: a value -> variable is not empty" {
    local x=1
    assert_fails -p '-- variable is not empty --' assert_var_empty x
    assert_fails -p 'value    : 1' assert_var_empty x
}

@test "assert_var_empty: unset -> variable is not set" {
    unset nope_zz
    assert_fails -p 'variable is not set' assert_var_empty nope_zz
}

@test "refute_var_empty: a value -> passes" {
    local x=1
    assert_passes refute_var_empty x
}

@test "refute_var_empty: empty value -> variable is empty" {
    local e=''
    assert_fails -p '-- variable is empty --' refute_var_empty e
}

@test "refute_var_empty: unset -> variable is not set" {
    unset nope_zz
    assert_fails -p 'variable is not set' refute_var_empty nope_zz
}

# ==============================================================================
# GROUP 03: assert_var_equal, refute_var_equal
# ==============================================================================

@test "assert_var_equal: same value -> passes" {
    local x=1
    assert_passes assert_var_equal x 1
}

@test "assert_var_equal: other value -> variable value differs, expected and actual" {
    local x=1
    assert_fails -p '-- variable value differs --' assert_var_equal x 2
    assert_fails -p 'expected : 2' assert_var_equal x 2
    assert_fails -p 'actual   : 1' assert_var_equal x 2
}

@test "assert_var_equal: unset -> variable is not set" {
    unset nope_zz
    assert_fails -p 'variable is not set' assert_var_equal nope_zz 1
}

@test "assert_var_equal: array -> elements joined by spaces" {
    local -a arr=(a b)
    assert_passes assert_var_equal arr 'a b'
}

@test "assert_var_equal: array under another IFS -> elements still joined by spaces" {
    local -a arr=(a b)
    local IFS=,
    assert_passes assert_var_equal arr 'a b'
}

@test "refute_var_equal: other value -> passes" {
    local x=1
    assert_passes refute_var_equal x 2
}

@test "refute_var_equal: unset -> passes" {
    unset nope_zz
    assert_passes refute_var_equal nope_zz 1
}

@test "refute_var_equal: same value -> variable has the unexpected value" {
    local x=1
    assert_fails -p '-- variable has the unexpected value --' refute_var_equal x 1
}

# ==============================================================================
# GROUP 04: assert_declared, refute_declared
# ==============================================================================

@test "assert_declared: no option -> any declared variable passes" {
    local x=1
    assert_passes assert_declared x
}

@test "assert_declared: no option on an undeclared name -> variable is not declared" {
    unset nope_zz
    assert_fails -p '-- variable is not declared --' assert_declared nope_zz
    assert_fails -p 'declaration : none' assert_declared nope_zz
}

@test "assert_declared: -a -> indexed array" {
    local -a arr=()
    assert_passes assert_declared -a arr
}

@test "assert_declared: -a on a scalar -> not declared as an indexed array, shows the declaration" {
    local x=1
    assert_fails -p '-- variable is not declared as an indexed array --' assert_declared -a x
    assert_fails -p 'declaration : declare -- x="1"' assert_declared -a x
}

@test "assert_declared: -A -> associative array" {
    local -A map=([k]=v)
    assert_passes assert_declared -A map
    assert_fails -p 'not declared as an associative array' assert_declared -A nope_zz
}

@test "assert_declared: -f -> function" {
    assert_passes assert_declared -f assert_equal
    assert_passes assert_declared -f expect::report::fail
    assert_fails -p '-- variable is not declared as a function --' assert_declared -f no_such_function
}

@test "assert_declared: -i, -r and -x -> integer, readonly and exported" {
    local -i n=1
    local -r ro=1
    local -x ex=1
    assert_passes assert_declared -i n
    assert_passes assert_declared -r ro
    assert_passes assert_declared -x ex
    assert_fails -p 'not declared as readonly' assert_declared -r n
    assert_fails -p 'not declared as exported' assert_declared -x n
}

@test "assert_declared: -n -> nameref" {
    local target=1
    local -n ref=target
    assert_passes assert_declared -n ref
}

@test "assert_declared: invalid name -> usage error" {
    assert_fails -p '-- ERROR: assert_declared --' assert_declared -a 'a b'
    assert_fails -p 'not a function name' assert_declared -f 'a b'
}

@test "refute_declared: undeclared name -> passes" {
    unset nope_zz
    assert_passes refute_declared nope_zz
}

@test "refute_declared: declared name -> variable is declared" {
    local x=1
    assert_fails -p '-- variable is declared --' refute_declared x
}

@test "refute_declared: attribute absent -> passes" {
    local -a arr=()
    assert_passes refute_declared -A arr
    assert_passes refute_declared -f arr
}

@test "refute_declared: attribute present -> variable is declared as ..." {
    local -a arr=()
    assert_fails -p '-- variable is declared as an indexed array --' refute_declared -a arr
}
