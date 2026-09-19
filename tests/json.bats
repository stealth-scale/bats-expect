#!/usr/bin/env bats

# shellcheck disable=SC2034,SC2154,SC2030,SC2031
# Variables here are read by name through the library or set by `capture`, and
# every @test is its own process, not a subshell of the file.

# ==============================================================================
# bats-expect: json - Test Suite
# ==============================================================================
#   01. assert_json_valid, refute_json_valid
#   02. assert_json_equal, refute_json_equal
#   03. assert_json_has_key, refute_json_has_key
#   04. assert_json_length
#   05. --file and the jq requirement
# ==============================================================================

load helper
setup() {
    common_setup
    command -v jq >/dev/null || skip 'jq is not installed'
    j='{"a":{"b":[1,2,3]},"s":"x y","n":null,"t":true}'
}

# ==============================================================================
# GROUP 01: assert_json_valid, refute_json_valid
# ==============================================================================

@test "assert_json_valid: object, array, scalar and null -> pass" {
    assert_passes assert_json_valid "$j"
    assert_passes assert_json_valid '[1, 2]'
    assert_passes assert_json_valid '"text"'
    assert_passes assert_json_valid null
    assert_passes assert_json_valid false
}

@test "assert_json_valid: broken document -> value is not valid JSON, with jq's error" {
    assert_fails -p '-- value is not valid JSON --' assert_json_valid '{'
    assert_fails -p 'error' assert_json_valid '{'
}

@test "refute_json_valid: broken document -> passes" {
    assert_passes refute_json_valid '{'
    assert_passes refute_json_valid 'not json'
}

@test "refute_json_valid: valid document -> value is valid JSON, but it was expected not to be" {
    assert_fails -p 'value is valid JSON, but it was expected not to be' refute_json_valid "$j"
}

# ==============================================================================
# GROUP 02: assert_json_equal, refute_json_equal
# ==============================================================================

@test "assert_json_equal: string, number, boolean -> compared as jq -r prints them" {
    assert_passes assert_json_equal "$j" .s 'x y'
    assert_passes assert_json_equal "$j" '.a.b[0]' 1
    assert_passes assert_json_equal "$j" .t true
}

@test "assert_json_equal: object or array -> compact JSON" {
    assert_passes assert_json_equal "$j" .a.b '[1,2,3]'
    assert_passes assert_json_equal "$j" .a '{"b":[1,2,3]}'
}

@test "assert_json_equal: missing path -> null" {
    assert_passes assert_json_equal "$j" .missing null
}

@test "assert_json_equal: other value -> JSON value differs, path, expected and actual" {
    assert_fails -p '-- JSON value differs --' assert_json_equal "$j" .s other
    assert_fails -p 'path     : .s' assert_json_equal "$j" .s other
    assert_fails -p 'expected : other' assert_json_equal "$j" .s other
    assert_fails -p 'actual   : x y' assert_json_equal "$j" .s other
}

@test "assert_json_equal: invalid document -> usage error" {
    assert_fails -p '-- ERROR: assert_json_equal --' assert_json_equal '{' .s x
}

@test "assert_json_equal: invalid path -> usage error with jq's message" {
    assert_fails -p 'jq rejected the path' assert_json_equal "$j" '.[' x
}

@test "refute_json_equal: other value -> passes" {
    assert_passes refute_json_equal "$j" .s other
}

@test "refute_json_equal: same value -> JSON value equals, but it was expected to differ" {
    assert_fails -p 'JSON value equals, but it was expected to differ' refute_json_equal "$j" .s 'x y'
}

# ==============================================================================
# GROUP 03: assert_json_has_key, refute_json_has_key
# ==============================================================================

@test "assert_json_has_key: present path -> passes, false counts as present" {
    assert_passes assert_json_has_key "$j" .a.b
    assert_passes assert_json_has_key "$j" '.a.b[2]'
    assert_passes assert_json_has_key '{"f":false}' .f
}

@test "assert_json_has_key: absent or null path -> JSON has no value at path" {
    assert_fails -p '-- JSON has no value at path --' assert_json_has_key "$j" .zz
    assert_fails -p 'JSON has no value at path' assert_json_has_key "$j" .n
    assert_fails -p 'path : .zz' assert_json_has_key "$j" .zz
}

@test "refute_json_has_key: absent or null path -> passes" {
    assert_passes refute_json_has_key "$j" .zz
    assert_passes refute_json_has_key "$j" .n
}

@test "refute_json_has_key: present path -> JSON has a value at path, with the value" {
    assert_fails -p 'JSON has a value at path, but it was expected not to' refute_json_has_key "$j" .s
    assert_fails -p 'value : x y' refute_json_has_key "$j" .s
}

# ==============================================================================
# GROUP 04: assert_json_length
# ==============================================================================

@test "assert_json_length: array, object and string -> their lengths" {
    assert_passes assert_json_length "$j" .a.b 3
    assert_passes assert_json_length "$j" .a 1
    assert_passes assert_json_length "$j" .s 3
}

@test "assert_json_length: other length -> JSON length differs" {
    assert_fails -p '-- JSON length differs --' assert_json_length "$j" .a.b 2
    assert_fails -p 'actual   : 3' assert_json_length "$j" .a.b 2
}

@test "assert_json_length: non-integer -> usage error" {
    assert_fails -p '-- ERROR: assert_json_length --' assert_json_length "$j" .a.b x
}

# ==============================================================================
# GROUP 05: --file and the jq requirement
# ==============================================================================

@test "assert_json_equal: --file -> reads the document from a path" {
    printf '%s' "$j" > "$BATS_TEST_TMPDIR/doc.json"
    assert_passes assert_json_equal --file "$BATS_TEST_TMPDIR/doc.json" .s 'x y'
    assert_passes assert_json_valid --file "$BATS_TEST_TMPDIR/doc.json"
}

@test "assert_json_valid: --file with a missing path -> usage error" {
    assert_fails -p '-- ERROR: assert_json_valid --' assert_json_valid --file "$BATS_TEST_TMPDIR/nope.json"
    assert_fails -p 'file does not exist' assert_json_valid --file "$BATS_TEST_TMPDIR/nope.json"
}

@test "assert_json_valid: jq missing -> usage error names the requirement" {
    without_jq() { PATH=/nonexistent assert_json_valid "$j"; }
    assert_fails -p 'jq is required for the JSON assertions' without_jq
}
