#!/usr/bin/env bats

# shellcheck disable=SC2034,SC2154,SC2030,SC2031
# Variables here are read by name through the library or set by `capture`, and
# every @test is its own process, not a subshell of the file.

# ==============================================================================
# bats-expect: array - Test Suite
# ==============================================================================
#   01. assert_array_contains, refute_array_contains
#   02. assert_array_equal, refute_array_equal
#   03. assert_array_length
#   04. assert_array_empty, refute_array_empty
#   05. assert_array_has_key, refute_array_has_key
#   06. Usage errors shared by the array assertions
# ==============================================================================

load helper
setup() { common_setup; }

# ==============================================================================
# GROUP 01: assert_array_contains, refute_array_contains
# ==============================================================================

@test "assert_array_contains: element present -> passes" {
    local -a items=(x y z)
    assert_passes assert_array_contains items y
}

@test "assert_array_contains: element absent -> array does not contain value, with the elements" {
    local -a items=(x y)
    assert_fails -p '-- array does not contain value --' assert_array_contains items q
    assert_fails -p 'value : q' assert_array_contains items q
    assert_fails -p 'elements (2 lines):' assert_array_contains items q
}

@test "assert_array_contains: associative array -> looks at the values" {
    local -A map=([k]=v)
    assert_passes assert_array_contains map v
    assert_fails -p 'array does not contain value' assert_array_contains map k
}

@test "assert_array_contains: empty element -> found" {
    local -a items=('' a)
    assert_passes assert_array_contains items ''
}

@test "refute_array_contains: element absent -> passes" {
    local -a items=(x y)
    assert_passes refute_array_contains items q
}

@test "refute_array_contains: element present -> array contains value" {
    local -a items=(x y)
    assert_fails -p '-- array contains value --' refute_array_contains items x
}

# ==============================================================================
# GROUP 02: assert_array_equal, refute_array_equal
# ==============================================================================

@test "assert_array_equal: same elements in order -> passes" {
    local -a items=(a b c)
    assert_passes assert_array_equal items a b c
    local -a none=()
    assert_passes assert_array_equal none
}

@test "assert_array_equal: different order -> array elements differ" {
    local -a items=(a b)
    assert_fails -p '-- array elements differ --' assert_array_equal items b a
}

@test "assert_array_equal: different length -> array elements differ, expected and actual blocks" {
    local -a items=(a b)
    assert_fails -p 'expected (3 lines):' assert_array_equal items a b c
    assert_fails -p 'actual (2 lines):' assert_array_equal items a b c
}

@test "assert_array_equal: newline inside an element -> compared element by element" {
    local -a items=($'a\nb' c)
    assert_fails -p 'array elements differ' assert_array_equal items a $'b\nc'
}

@test "refute_array_equal: different elements -> passes" {
    local -a items=(a b)
    assert_passes refute_array_equal items b a
    assert_passes refute_array_equal items a
}

@test "refute_array_equal: same elements -> array elements should differ" {
    local -a items=(a b)
    assert_fails -p '-- array elements should differ --' refute_array_equal items a b
}

# ==============================================================================
# GROUP 03: assert_array_length
# ==============================================================================

@test "assert_array_length: matching length -> passes" {
    local -a items=(a b)
    assert_passes assert_array_length items 2
    local -a none=()
    assert_passes assert_array_length none 0
}

@test "assert_array_length: other length -> array length differs" {
    local -a items=(a b)
    assert_fails -p '-- array length differs --' assert_array_length items 3
    assert_fails -p 'expected : 3' assert_array_length items 3
    assert_fails -p 'actual   : 2' assert_array_length items 3
}

@test "assert_array_length: non-integer -> usage error" {
    local -a items=(a)
    assert_fails -p '-- ERROR: assert_array_length --' assert_array_length items x
}

# ==============================================================================
# GROUP 04: assert_array_empty, refute_array_empty
# ==============================================================================

@test "assert_array_empty: no elements -> passes" {
    local -a none=()
    assert_passes assert_array_empty none
}

@test "assert_array_empty: elements -> array is not empty, with length" {
    local -a items=(a b)
    assert_fails -p '-- array is not empty --' assert_array_empty items
    assert_fails -p 'length : 2' assert_array_empty items
}

@test "refute_array_empty: elements -> passes" {
    local -a items=(a)
    assert_passes refute_array_empty items
}

@test "refute_array_empty: no elements -> array is empty" {
    local -a none=()
    assert_fails -p '-- array is empty --' refute_array_empty none
}

# ==============================================================================
# GROUP 05: assert_array_has_key, refute_array_has_key
# ==============================================================================

@test "assert_array_has_key: associative key present -> passes" {
    local -A map=([k]=v [other]=w)
    assert_passes assert_array_has_key map k
}

@test "assert_array_has_key: associative key absent -> array has no such key, lists the keys" {
    local -A map=([k]=v)
    assert_fails -p '-- array has no such key --' assert_array_has_key map q
    assert_fails -p 'key   : q' assert_array_has_key map q
    assert_fails -p 'keys (1 lines):' assert_array_has_key map q
}

@test "assert_array_has_key: indexed array -> the key is an index" {
    local -a items=(a b)
    assert_passes assert_array_has_key items 1
    assert_fails -p 'array has no such key' assert_array_has_key items 5
}

@test "refute_array_has_key: key absent -> passes" {
    local -A map=([k]=v)
    assert_passes refute_array_has_key map q
}

@test "refute_array_has_key: key present -> array has the key, with its value" {
    local -A map=([k]=v)
    assert_fails -p '-- array has the key --' refute_array_has_key map k
    assert_fails -p 'value : v' refute_array_has_key map k
}

@test "assert_array_has_key: key -> compared as text, never evaluated" {
    local -A map=([k]=v)
    local -a items=(a b c)
    local marker="$BATS_TEST_TMPDIR/evaluated"
    assert_fails -p 'array has no such key' assert_array_has_key map "\$(touch $marker)"
    assert_fails -p 'array has no such key' assert_array_has_key items '1+1'
    assert_fails -p 'array has no such key' assert_array_has_key items "x[\$(touch $marker)]"
    assert_passes refute_array_has_key items '1+1'
    assert_passes refute_array_has_key map "\$(touch $marker)"
    [ ! -e "$marker" ]
}

# ==============================================================================
# GROUP 06: Usage errors
# ==============================================================================

@test "assert_array_contains: undeclared name -> usage error" {
    unset nope_zz
    assert_fails -p '-- ERROR: assert_array_contains --' assert_array_contains nope_zz x
    assert_fails -p "\`nope_zz' is not declared" assert_array_contains nope_zz x
}

@test "assert_array_contains: scalar -> usage error naming the declaration" {
    local scalar=1
    assert_fails -p "\`scalar' is not an array" assert_array_contains scalar 1
}

@test "assert_array_contains: invalid name -> usage error" {
    assert_fails -p 'not a variable name' assert_array_contains 'a b' x
}

@test "refute_array_empty: undeclared name -> usage error names refute_array_empty" {
    unset nope_zz
    assert_fails -p '-- ERROR: refute_array_empty --' refute_array_empty nope_zz
}
