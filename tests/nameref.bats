#!/usr/bin/env bats

# shellcheck disable=SC2034,SC2154,SC2030,SC2031,SC2178
# Variables here are read by name through the library or set by `capture`, and
# every @test is its own process, not a subshell of the file.

# ==============================================================================
# bats-expect: nameref - Test Suite
# ==============================================================================
#   01. run_nameref
#   02. assert_nameref
#   03. refute_nameref
# ==============================================================================

load helper
setup() { common_setup; }

# Fixtures: functions that return through a nameref. One of them returns an array
# through the same reference name, which is what SC2178 objects to above.
trim() { local -n out="$1"; local s="$2"; s="${s#"${s%%[![:space:]]*}"}"; out="${s%"${s##*[![:space:]]}"}"; }
split() { local -n out="$1"; IFS=, read -r -a out <<< "$2"; }
failing() { local -n out="$1"; out=partial; return 3; }
side_effect() { local -n out="$1"; out='done'; touched=yes; }

# ==============================================================================
# GROUP 01: run_nameref
# ==============================================================================

@test "run_nameref: scalar result -> output holds it and status is 0" {
    run_nameref trim '  foo  '
    [ "$status" -eq 0 ]
    [ "$output" = foo ]
}

@test "run_nameref: result -> the run assertions apply to it" {
    run_nameref trim '  foo  '
    assert_success
    assert_output foo
    assert_line --index 0 foo
}

@test "run_nameref: array result -> output joins the elements, lines holds them" {
    run_nameref split a,b,c
    [ "$output" = $'a\nb\nc' ]
    [ "${lines[1]}" = b ]
    [ "${#lines[@]}" -eq 3 ]
}

@test "run_nameref: non-zero return -> status holds it and output the partial value" {
    run_nameref failing
    [ "$status" -eq 3 ]
    [ "$output" = partial ]
}

@test "run_nameref: current shell -> side effects of the function stay visible" {
    touched=no
    run_nameref side_effect
    [ "$touched" = yes ]
}

@test "run_nameref: not a function -> usage error" {
    capture run_nameref no_such_function
    [ "$rc" -eq 1 ]
    [[ "$report" == *"-- ERROR: run_nameref --"* ]]
    [[ "$report" == *"not a function"* ]]
}

# ==============================================================================
# GROUP 02: assert_nameref
# ==============================================================================

@test "assert_nameref: expected value returned -> passes" {
    assert_passes assert_nameref foo trim ' foo'
}

@test "assert_nameref: other value -> nameref value differs, expected and actual" {
    assert_fails -p '-- nameref value differs --' assert_nameref bar trim foo
    assert_fails -p 'expected : bar' assert_nameref bar trim foo
    assert_fails -p 'actual   : foo' assert_nameref bar trim foo
}

@test "assert_nameref: function fails -> function failed, with the status" {
    assert_fails -p '-- function failed --' assert_nameref partial failing
    assert_fails -p 'status   : 3' assert_nameref partial failing
}

@test "assert_nameref: leaves the test's status and output alone" {
    status=7 output=kept
    assert_passes assert_nameref foo trim foo
    assert_nameref foo trim foo
    [ "$status" = 7 ]
    [ "$output" = kept ]
}

# ==============================================================================
# GROUP 03: refute_nameref
# ==============================================================================

@test "refute_nameref: other value -> passes" {
    assert_passes refute_nameref bar trim foo
}

@test "refute_nameref: function fails -> passes, a failed call returns nothing" {
    assert_passes refute_nameref partial failing
}

@test "refute_nameref: the value -> nameref value equals, but it was expected to differ" {
    assert_fails -p 'nameref value equals, but it was expected to differ' refute_nameref foo trim foo
}
