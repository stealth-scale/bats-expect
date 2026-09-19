#!/usr/bin/env bats

# shellcheck disable=SC2034,SC2154,SC2030,SC2031
# Variables here are read by name through the library or set by `capture`, and
# every @test is its own process, not a subshell of the file.

# ==============================================================================
# bats-expect: type - Test Suite
# ==============================================================================
#   01. assert_is_int, refute_is_int
#   02. assert_is_number, refute_is_number
#   03. assert_is_bool, refute_is_bool
#   04. assert_is_regex, refute_is_regex
#   05. assert_is_identifier, refute_is_identifier
# ==============================================================================

load helper
setup() { common_setup; }

# ==============================================================================
# GROUP 01: assert_is_int, refute_is_int
# ==============================================================================

@test "assert_is_int: digits with an optional sign -> passes" {
    assert_passes assert_is_int 0
    assert_passes assert_is_int 42
    assert_passes assert_is_int -3
    assert_passes assert_is_int +7
}

@test "assert_is_int: decimals, text and empty -> value is not an integer" {
    assert_fails -p '-- value is not an integer --' assert_is_int 1.5
    assert_fails -p 'value : abc' assert_is_int abc
    assert_fails -p 'value is not an integer' assert_is_int ''
    assert_fails -p 'value is not an integer' assert_is_int
}

@test "refute_is_int: non-integer -> passes" {
    assert_passes refute_is_int 1.5
    assert_passes refute_is_int abc
}

@test "refute_is_int: integer -> value is an integer" {
    assert_fails -p '-- value is an integer --' refute_is_int 42
}

# ==============================================================================
# GROUP 02: assert_is_number, refute_is_number
# ==============================================================================

@test "assert_is_number: integers and decimals -> passes" {
    assert_passes assert_is_number 42
    assert_passes assert_is_number -1.5
    assert_passes assert_is_number .5
    assert_passes assert_is_number 3.
}

@test "assert_is_number: text, empty and exponents -> value is not a number" {
    assert_fails -p '-- value is not a number --' assert_is_number abc
    assert_fails -p 'value is not a number' assert_is_number ''
    assert_fails -p 'value is not a number' assert_is_number 1e5
}

@test "refute_is_number: text -> passes" {
    assert_passes refute_is_number abc
}

@test "refute_is_number: number -> value is a number" {
    assert_fails -p '-- value is a number --' refute_is_number 1.5
}

# ==============================================================================
# GROUP 03: assert_is_bool, refute_is_bool
# ==============================================================================

@test "assert_is_bool: true and false -> passes" {
    assert_passes assert_is_bool true
    assert_passes assert_is_bool false
}

@test "assert_is_bool: anything else -> value is not a boolean" {
    assert_fails -p '-- value is not a boolean --' assert_is_bool yes
    assert_fails -p 'expected : true or false' assert_is_bool 1
    assert_fails -p 'value is not a boolean' assert_is_bool TRUE
}

@test "refute_is_bool: other values -> passes" {
    assert_passes refute_is_bool yes
}

@test "refute_is_bool: true or false -> value is a boolean" {
    assert_fails -p '-- value is a boolean --' refute_is_bool false
}

# ==============================================================================
# GROUP 04: assert_is_regex, refute_is_regex
# ==============================================================================

# The empty pattern is not a case: glibc compiles it and the regcomp of macOS rejects
# it with REG_EMPTY, and the assertion reports what the platform says.
@test "assert_is_regex: valid extended regular expression -> passes" {
    assert_passes assert_is_regex 'a+'
    assert_passes assert_is_regex '^[0-9]{2}$'
    assert_passes assert_is_regex '.*'
}

@test "assert_is_regex: invalid expression -> value is not a valid extended regular expression" {
    assert_fails -p '-- value is not a valid extended regular expression --' assert_is_regex 'a('
    assert_fails -p 'value : [' assert_is_regex '['
}

@test "refute_is_regex: invalid expression -> passes" {
    assert_passes refute_is_regex 'a('
}

@test "refute_is_regex: valid expression -> value is a valid extended regular expression" {
    assert_fails -p '-- value is a valid extended regular expression --' refute_is_regex 'a+'
}

# ==============================================================================
# GROUP 05: assert_is_identifier, refute_is_identifier
# ==============================================================================

@test "assert_is_identifier: letters, digits and underscores -> passes" {
    assert_passes assert_is_identifier foo
    assert_passes assert_is_identifier _x1
}

@test "assert_is_identifier: leading digit, dash or colon -> value is not an identifier" {
    assert_fails -p '-- value is not an identifier --' assert_is_identifier 1x
    assert_fails -p 'value is not an identifier' assert_is_identifier a-b
    assert_fails -p 'value is not an identifier' assert_is_identifier a::b
    assert_fails -p 'value is not an identifier' assert_is_identifier ''
}

@test "refute_is_identifier: non-identifier -> passes" {
    assert_passes refute_is_identifier a-b
}

@test "refute_is_identifier: identifier -> value is an identifier" {
    assert_fails -p '-- value is an identifier --' refute_is_identifier foo
}
