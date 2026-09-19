#!/usr/bin/env bats

# shellcheck disable=SC2034,SC2154,SC2030,SC2031
# Variables here are read by name through the library or set by `capture`, and
# every @test is its own process, not a subshell of the file.

# ==============================================================================
# bats-expect: meta - Test Suite
# ==============================================================================
# assert_passes and assert_fails are checked with plain shell tests, because
# every other test file relies on them.
#   01. assert_passes
#   02. assert_fails
# ==============================================================================

load helper
setup() { common_setup; }

# ==============================================================================
# GROUP 01: assert_passes
# ==============================================================================

@test "assert_passes: passing assertion -> returns 0 and prints nothing" {
    capture assert_passes assert_equal a a
    [ "$rc" -eq 0 ]
    [ -z "$report" ]
}

@test "assert_passes: failing assertion -> fails and includes the inner report" {
    capture assert_passes assert_equal a b
    [ "$rc" -eq 1 ]
    [[ "$report" == *"-- assertion failed, but it was expected to pass --"* ]]
    [[ "$report" == *"assertion : assert_equal a b"* ]]
    [[ "$report" == *"status    : 1"* ]]
    [[ "$report" == *"values do not equal"* ]]
}

@test "assert_passes: subshell -> the assertion cannot change the test's variables" {
    local marker=before
    set_marker() { marker=after; }
    assert_passes set_marker
    [ "$marker" = before ]
}

# ==============================================================================
# GROUP 02: assert_fails
# ==============================================================================

@test "assert_fails: failing assertion -> returns 0" {
    capture assert_fails assert_equal a b
    [ "$rc" -eq 0 ]
    [ -z "$report" ]
}

@test "assert_fails: passing assertion -> fails" {
    capture assert_fails assert_equal a a
    [ "$rc" -eq 1 ]
    [[ "$report" == *"-- assertion passed, but it was expected to fail --"* ]]
    [[ "$report" == *"assertion : assert_equal a a"* ]]
}

@test "assert_fails: --partial -> passes when the report contains the text" {
    assert_fails --partial 'values do not equal' assert_equal a b
    assert_fails -p 'expected : b' assert_equal a b
}

@test "assert_fails: --partial -> fails when the report lacks the text" {
    capture assert_fails --partial 'no such text' assert_equal a b
    [ "$rc" -eq 1 ]
    [[ "$report" == *"report does not contain the text"* ]]
    [[ "$report" == *"text      : no such text"* ]]
}

@test "assert_fails: --regexp -> the report must match" {
    assert_fails --regexp 'expected +: b' assert_equal a b
    capture assert_fails -e '^zzz' assert_equal a b
    [ "$rc" -eq 1 ]
    [[ "$report" == *"does not match the regular expression"* ]]
}

@test "assert_fails: -- -> ends the options" {
    assert_fails -- assert_equal a b
}

@test "assert_fails: no assertion -> usage error" {
    capture assert_fails
    [ "$rc" -eq 1 ]
    [[ "$report" == *"-- ERROR: assert_fails --"* ]]
}

@test "assert_fails: --partial without a value -> usage error" {
    capture assert_fails --partial
    [ "$rc" -eq 1 ]
    [[ "$report" == *"requires an argument"* ]]
}

@test "assert_fails: invalid --regexp -> usage error names assert_fails" {
    capture assert_fails --regexp '(' assert_equal a b
    [ "$rc" -eq 1 ]
    [[ "$report" == *"-- ERROR: assert_fails --"* ]]
}
