#!/usr/bin/env bats

# shellcheck disable=SC2034,SC2154,SC2030,SC2031
# Variables here are read by name through the library or set by `capture`, and
# every @test is its own process, not a subshell of the file.

# ==============================================================================
# bats-expect: value - Test Suite
# ==============================================================================
#   01. assert_equal, refute_equal, assert_not_equal
#   02. assert_regex, refute_regex
#   03. assert_empty, refute_empty
#   04. assert_contains, refute_contains
#   05. assert_starts_with, refute_starts_with, assert_ends_with, refute_ends_with
#   06. assert_one_of, refute_one_of
#   07. assert_line_count
# ==============================================================================

load helper
setup() { common_setup; }

# ==============================================================================
# GROUP 01: assert_equal, refute_equal, assert_not_equal
# ==============================================================================

@test "assert_equal: same values -> passes" {
    assert_passes assert_equal a a
    assert_passes assert_equal '' ''
}

@test "assert_equal: different values -> values do not equal, expected and actual" {
    assert_fails -p '-- values do not equal --' assert_equal a b
    assert_fails -p 'expected : b' assert_equal a b
    assert_fails -p 'actual   : a' assert_equal a b
}

@test "assert_equal: multi-line values -> blocks with line counts" {
    assert_fails -p 'expected (2 lines):' assert_equal a $'b\nc'
    assert_fails -p 'actual (1 lines):' assert_equal a $'b\nc'
}

@test "assert_equal: values that look like options -> compared as values" {
    assert_passes assert_equal -n -n
    assert_passes assert_equal -- --
}

@test "assert_equal: missing arguments -> empty strings, no unbound variable error" {
    set -u
    assert_passes assert_equal
    assert_fails -p 'values do not equal' assert_equal a
}

@test "assert_equal: unicode -> byte-exact" {
    assert_passes assert_equal café café
    assert_fails -p 'values do not equal' assert_equal café cafe
}

@test "refute_equal: different values -> passes" {
    assert_passes refute_equal a b
}

@test "refute_equal: same values -> values should not be equal, with unexpected" {
    assert_fails -p '-- values should not be equal --' refute_equal a a
    assert_fails -p 'unexpected : a' refute_equal a a
}

@test "assert_not_equal: -> the bats-assert name for refute_equal" {
    assert_passes assert_not_equal a b
    assert_fails -p 'values should not be equal' assert_not_equal a a
}

# ==============================================================================
# GROUP 02: assert_regex, refute_regex
# ==============================================================================

@test "assert_regex: match -> passes" {
    assert_passes assert_regex abc '^a.c$'
    assert_passes assert_regex 2026-01-08 '[0-9]{4}-[0-9]{2}-[0-9]{2}'
}

@test "assert_regex: mismatch -> value, pattern and case at width 8" {
    assert_fails -p '-- value does not match regular expression --' assert_regex abc '^z'
    assert_fails -p 'value    : abc' assert_regex abc '^z'
    assert_fails -p 'pattern  : ^z' assert_regex abc '^z'
    assert_fails -p 'case     : sensitive' assert_regex abc '^z'
}

@test "assert_regex: nocasematch on -> matches and reports insensitive" {
    shopt -s nocasematch
    assert_passes assert_regex ABC '^abc$'
    assert_fails -p 'case     : insensitive' assert_regex ABC '^z'
    shopt -u nocasematch
}

@test "assert_regex: invalid pattern -> usage error" {
    assert_fails -p '-- ERROR: assert_regex --' assert_regex abc '('
}

@test "refute_regex: no match -> passes" {
    assert_passes refute_regex abc '^z'
}

@test "refute_regex: match -> value matches regular expression, with the match" {
    assert_fails -p '-- value matches regular expression --' refute_regex abc 'b+'
    assert_fails -p 'match    : b' refute_regex abc 'b+'
}

@test "refute_regex: invalid pattern -> usage error" {
    assert_fails -p '-- ERROR: refute_regex --' refute_regex abc '('
}

# ==============================================================================
# GROUP 03: assert_empty, refute_empty
# ==============================================================================

@test "assert_empty: empty or missing value -> passes" {
    assert_passes assert_empty ''
    assert_passes assert_empty
}

@test "assert_empty: a value -> value is not empty, with the value" {
    assert_fails -p '-- value is not empty --' assert_empty x
    assert_fails -p 'value : x' assert_empty x
}

@test "refute_empty: a value -> passes, a space is a value" {
    assert_passes refute_empty x
    assert_passes refute_empty ' '
}

@test "refute_empty: empty or missing value -> value is empty" {
    assert_fails -p '-- value is empty --' refute_empty ''
    assert_fails -p '-- value is empty --' refute_empty
}

# ==============================================================================
# GROUP 04: assert_contains, refute_contains
# ==============================================================================

@test "assert_contains: substring present -> passes" {
    assert_passes assert_contains abc b
    assert_passes assert_contains abc abc
}

@test "assert_contains: substring absent -> value does not contain substring" {
    assert_fails -p '-- value does not contain substring --' assert_contains abc z
    assert_fails -p 'substring : z' assert_contains abc z
}

@test "assert_contains: glob characters -> literal" {
    assert_passes assert_contains 'a[b]c' '[b]'
    assert_fails -p 'value does not contain substring' assert_contains abc '*'
}

@test "assert_contains: missing substring argument -> empty string, passes" {
    set -u
    assert_passes assert_contains abc
}

@test "assert_contains: value starting with a dash -> compared as a value" {
    assert_passes assert_contains -- -
}

@test "refute_contains: substring absent -> passes" {
    assert_passes refute_contains abc z
}

@test "refute_contains: substring present -> value contains substring" {
    assert_fails -p '-- value contains substring --' refute_contains abc b
}

# ==============================================================================
# GROUP 05: prefixes and suffixes
# ==============================================================================

@test "assert_starts_with: prefix present -> passes" {
    assert_passes assert_starts_with https://x https://
    assert_passes assert_starts_with --flag --
}

@test "assert_starts_with: prefix absent -> value does not start with prefix" {
    assert_fails -p '-- value does not start with prefix --' assert_starts_with abc b
    assert_fails -p 'prefix : b' assert_starts_with abc b
}

@test "assert_starts_with: glob characters -> literal" {
    assert_fails -p 'value does not start with prefix' assert_starts_with abc '*'
}

@test "refute_starts_with: prefix absent -> passes" {
    assert_passes refute_starts_with abc b
}

@test "refute_starts_with: prefix present -> value starts with prefix" {
    assert_fails -p '-- value starts with prefix --' refute_starts_with abc a
}

@test "assert_ends_with: suffix present -> passes" {
    assert_passes assert_ends_with file.tar.gz .gz
}

@test "assert_ends_with: suffix absent -> value does not end with suffix" {
    assert_fails -p '-- value does not end with suffix --' assert_ends_with abc a
    assert_fails -p 'suffix : a' assert_ends_with abc a
}

@test "refute_ends_with: suffix absent -> passes" {
    assert_passes refute_ends_with abc a
}

@test "refute_ends_with: suffix present -> value ends with suffix" {
    assert_fails -p '-- value ends with suffix --' refute_ends_with abc c
}

# ==============================================================================
# GROUP 06: assert_one_of, refute_one_of
# ==============================================================================

@test "assert_one_of: value among the items -> passes" {
    assert_passes assert_one_of b a b c
}

@test "assert_one_of: value not among the items -> lists the items" {
    assert_fails -p '-- value is not one of the items --' assert_one_of z a b c
    assert_fails -p 'items : a, b, c' assert_one_of z a b c
}

@test "assert_one_of: no items -> fails" {
    assert_fails -p 'value is not one of the items' assert_one_of z
}

@test "refute_one_of: value not among the items -> passes" {
    assert_passes refute_one_of z a b c
}

@test "refute_one_of: value among the items -> value is one of the items" {
    assert_fails -p '-- value is one of the items --' refute_one_of b a b c
}

# ==============================================================================
# GROUP 07: assert_line_count
# ==============================================================================

@test "assert_line_count: matching count -> passes" {
    assert_passes assert_line_count $'a\nb' 2
    assert_passes assert_line_count '' 0
}

@test "assert_line_count: trailing newline -> does not add a line" {
    assert_passes assert_line_count $'a\nb\n' 2
}

@test "assert_line_count: other count -> line count differs, expected and actual as rows" {
    assert_fails -p '-- line count differs --' assert_line_count $'a\nb' 3
    assert_fails -p 'expected : 3' assert_line_count $'a\nb' 3
    assert_fails -p 'actual   : 2' assert_line_count $'a\nb' 3
}

@test "assert_line_count: non-integer count -> usage error" {
    assert_fails -p '-- ERROR: assert_line_count --' assert_line_count a x
}
