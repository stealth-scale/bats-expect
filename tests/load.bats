#!/usr/bin/env bats

# shellcheck disable=SC2034,SC2154,SC2030,SC2031
# Variables here are read by name through the library or set by `capture`, and
# every @test is its own process, not a subshell of the file.

# ==============================================================================
# bats-expect: load - Test Suite
# ==============================================================================
#   01. load.bash
# ==============================================================================

load helper
setup() { common_setup; }

@test "load.bash: -> defines every public assertion" {
    local name
    for name in assert_success assert_output assert_line assert_equal assert_regex assert_contains \
                assert_var_set assert_declared assert_is_int assert_gt assert_array_contains \
                assert_file_exists assert_symlink_to run_nameref assert_nameref assert_json_equal \
                assert_passes assert_fails; do
        declare -F "$name" >/dev/null || { echo "missing: $name" >&2; return 1; }
    done
}

@test "load.bash: -> every assert has a refute, except the ones bats-assert and bats-file define without one" {
    local name twin
    local -a without_twin=(assert_success assert_failure assert assert_not_equal assert_line_count
        assert_array_length assert_json_length assert_within_delta assert_gt assert_ge assert_lt assert_le
        assert_nameref assert_passes assert_fails
        assert_not_exists assert_file_not_exists assert_dir_not_exists assert_link_not_exists
        assert_file_not_empty assert_file_not_contains assert_not_file_permission
        assert_file_not_executable assert_files_not_equal assert_not_symlink_to)
    for name in $(declare -F | awk '$3 ~ /^assert_/ { print $3 }'); do
        twin="refute_${name#assert_}"
        if ! declare -F "$twin" >/dev/null; then
            [[ " ${without_twin[*]} " == *" $name "* ]] || { echo "no refute for $name" >&2; return 1; }
        fi
    done
}

@test "load.bash: -> leaves no loader variables behind" {
    [ -z "${expect_dir-}" ]
    [ -z "${expect_file-}" ]
}

@test "load.bash: loaded twice -> harmless" {
    load "$BATS_TEST_DIRNAME/../load"
    assert_passes assert_equal a a
}

@test "load.bash: sourced outside bats -> works with the fail polyfill" {
    # shellcheck disable=SC2016  # the script runs in the child bash
    run env -i PATH="$PATH" bash -c 'set -u; source "$1" && assert_equal a a && ! assert_equal a b 2>/dev/null && echo ok' _ "$BATS_TEST_DIRNAME/../load.bash"
    [ "$status" -eq 0 ]
    [ "$output" = ok ]
}

@test "load.bash: bats-support present -> its fail is used" {
    fail() { printf 'support-fail: %s\n' "$(cat)" >&2; return 1; }
    load "$BATS_TEST_DIRNAME/../load"
    run --separate-stderr assert_equal a b
    [ "$status" -eq 1 ]
    [[ "$stderr" == "support-fail: "* ]]
}
