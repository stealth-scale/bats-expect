#!/usr/bin/env bats

# shellcheck disable=SC2034,SC2154,SC2030,SC2031
# Variables here are read by name through the library or set by `capture`, and
# every @test is its own process, not a subshell of the file.

# ==============================================================================
# bats-expect: number - Test Suite
# ==============================================================================
#   01. assert_gt, assert_ge, assert_lt, assert_le
#   02. assert_between, refute_between
#   03. assert_within_delta
# ==============================================================================

load helper
setup() { common_setup; }

# ==============================================================================
# GROUP 01: assert_gt, assert_ge, assert_lt, assert_le
# ==============================================================================

@test "assert_gt: greater -> passes, integers and decimals" {
    assert_passes assert_gt 2 1
    assert_passes assert_gt 1.5 1.25
    assert_passes assert_gt 0 -1
}

@test "assert_gt: equal or less -> value is not greater than the bound" {
    assert_fails -p '-- value is not greater than the bound --' assert_gt 1 1
    assert_fails -p 'value : 1' assert_gt 1 2
    assert_fails -p 'bound : 2' assert_gt 1 2
}

@test "assert_gt: non-number -> usage error, not a silent zero" {
    assert_fails -p '-- ERROR: assert_gt --' assert_gt abc 1
    assert_fails -p "not a number: \`abc'" assert_gt 1 abc
    assert_fails -p 'not a number' assert_gt
}

@test "assert_ge: greater or equal -> passes" {
    assert_passes assert_ge 2 1
    assert_passes assert_ge 1 1
}

@test "assert_ge: less -> value is not greater than or equal to the bound" {
    assert_fails -p '-- value is not greater than or equal to the bound --' assert_ge 1 2
}

@test "assert_lt: less -> passes" {
    assert_passes assert_lt 1 2
    assert_passes assert_lt -1.5 -1
}

@test "assert_lt: equal or greater -> value is not less than the bound" {
    assert_fails -p '-- value is not less than the bound --' assert_lt 2 2
}

@test "assert_le: less or equal -> passes" {
    assert_passes assert_le 1 2
    assert_passes assert_le 1.5 1.5
}

@test "assert_le: greater -> value is not less than or equal to the bound" {
    assert_fails -p '-- value is not less than or equal to the bound --' assert_le 3 2
}

# ==============================================================================
# GROUP 02: assert_between, refute_between
# ==============================================================================

@test "assert_between: inside the range -> passes, bounds included" {
    assert_passes assert_between 5 1 10
    assert_passes assert_between 1 1 10
    assert_passes assert_between 10 1 10
    assert_passes assert_between 0.5 0 1
}

@test "assert_between: outside the range -> value is outside the range" {
    assert_fails -p '-- value is outside the range --' assert_between 11 1 10
    assert_fails -p 'range : 1 to 10' assert_between 0 1 10
}

@test "assert_between: non-number -> usage error" {
    assert_fails -p '-- ERROR: assert_between --' assert_between x 1 10
}

@test "refute_between: outside the range -> passes" {
    assert_passes refute_between 11 1 10
}

@test "refute_between: inside the range -> value is inside the range" {
    assert_fails -p '-- value is inside the range --' refute_between 5 1 10
}

# ==============================================================================
# GROUP 03: assert_within_delta
# ==============================================================================

@test "assert_within_delta: difference within delta -> passes, delta included" {
    assert_passes assert_within_delta 1.05 1 0.1
    assert_passes assert_within_delta 0.9 1 0.1
    assert_passes assert_within_delta 10 10 0
}

@test "assert_within_delta: difference beyond delta -> value is not within delta, with the difference" {
    assert_fails -p '-- value is not within delta --' assert_within_delta 1.5 1 0.1
    assert_fails -p 'difference : 0.5' assert_within_delta 1.5 1 0.1
}

@test "assert_within_delta: seven significant digits -> compared without rounding to six" {
    assert_passes assert_within_delta 1234567 0 1234567
    assert_passes assert_within_delta 1.1 1 0.1
    assert_fails -p 'difference : 1234568' assert_within_delta 1234568 0 1234567
}

@test "assert_within_delta: non-number -> usage error" {
    assert_fails -p '-- ERROR: assert_within_delta --' assert_within_delta 1 x 0.1
}
