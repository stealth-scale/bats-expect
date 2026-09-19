#!/usr/bin/env bats

# shellcheck disable=SC2034,SC2154,SC2030,SC2031
# Variables here are read by name through the library or set by `capture`, and
# every @test is its own process, not a subshell of the file.

# ==============================================================================
# bats-expect: report - Test Suite
# ==============================================================================
#   01. Measuring: count_lines, is_single_line, width, single_width
#   02. Printing: rows, blocks, pairs, mark_line, decorate
#   03. Failing: fail, fail_body, error, require_regex
#   04. The fail polyfill
# ==============================================================================

load helper
setup() { common_setup; }

# ==============================================================================
# GROUP 01: Measuring
# ==============================================================================

@test "expect::report::count_lines: -> a trailing newline does not add a line" {
    [ "$(expect::report::count_lines '')" = 0 ]
    [ "$(expect::report::count_lines 'a')" = 1 ]
    [ "$(expect::report::count_lines $'a\nb')" = 2 ]
    [ "$(expect::report::count_lines $'a\nb\n')" = 2 ]
}

@test "expect::report::is_single_line: -> true only when every value is one line" {
    expect::report::is_single_line a b ''
    run ! expect::report::is_single_line a $'b\nc'
}

@test "expect::report::width: -> the longest key" {
    [ "$(expect::report::width a 1 abcd 2 ab 3)" = 4 ]
}

@test "expect::report::single_width: -> ignores keys whose value spans lines" {
    [ "$(expect::report::single_width abcd $'1\n2' ab 3)" = 2 ]
}

# ==============================================================================
# GROUP 02: Printing
# ==============================================================================

@test "expect::report::rows: -> aligned rows at the given width" {
    run expect::report::rows 8 expected b actual a
    [ "${lines[0]}" = "expected : b" ]
    [ "${lines[1]}" = "actual   : a" ]
}

@test "expect::report::blocks: -> key with line count, value indented" {
    run expect::report::blocks actual $'x\ny'
    [ "${lines[0]}" = "actual (2 lines):" ]
    [ "${lines[1]}" = "  x" ]
    [ "${lines[2]}" = "  y" ]
}

@test "expect::report::pairs: single-line values -> rows" {
    run expect::report::pairs 8 expected b actual a
    [ "${lines[0]}" = "expected : b" ]
    [ "${lines[1]}" = "actual   : a" ]
}

@test "expect::report::pairs: one multi-line value -> every pair becomes a block" {
    run expect::report::pairs 8 expected b actual $'x\ny'
    [ "${lines[0]}" = "expected (1 lines):" ]
    [ "${lines[1]}" = "  b" ]
    [ "${lines[2]}" = "actual (2 lines):" ]
}

@test "expect::report::mark_line: -> the chosen line starts with >, the others with spaces" {
    run expect::report::mark_line $'one\ntwo\nthree' 1
    [ "${lines[0]}" = "  one" ]
    [ "${lines[1]}" = "> two" ]
    [ "${lines[2]}" = "  three" ]
}

@test "expect::report::decorate: -> blank line, title, body, rule, blank line" {
    local framed
    framed="$(printf 'body\n' | expect::report::decorate 'the title'; printf x)"
    [ "${framed%x}" = $'\n-- the title --\nbody\n--\n\n' ]
}

# ==============================================================================
# GROUP 03: Failing
# ==============================================================================

@test "expect::report::fail: -> framed pairs and status 1" {
    capture expect::report::fail 'values do not equal' expected b actual a
    [ "$rc" -eq 1 ]
    # capture strips the trailing newline of the report
    [ "$report" = $'\n-- values do not equal --\nexpected : b\nactual   : a\n--' ]
}

@test "expect::report::fail_body: -> frames a body from stdin and fails" {
    local rc=0 report
    report="$(printf 'custom body\n' | expect::report::fail_body 'a title' 2>&1)" || rc=$?
    [ "$rc" -eq 1 ]
    [ "$report" = $'\n-- a title --\ncustom body\n--' ]
}

@test "expect::report::error: -> ERROR title with the assertion name" {
    capture expect::report::error assert_thing 'what went wrong'
    [ "$rc" -eq 1 ]
    [ "$report" = $'\n-- ERROR: assert_thing --\nwhat went wrong\n--' ]
}

@test "expect::report::require_regex: valid -> 0 and silent" {
    capture expect::report::require_regex assert_x '^a+$'
    [ "$rc" -eq 0 ]
    [ -z "$report" ]
}

@test "expect::report::require_regex: invalid -> usage error naming the caller" {
    capture expect::report::require_regex assert_x '('
    [ "$rc" -eq 1 ]
    [[ "$report" == *"-- ERROR: assert_x --"* ]]
    [[ "$report" == *"regular expression"* ]]
}

# ==============================================================================
# GROUP 04: The fail polyfill
# ==============================================================================

@test "fail: arguments -> printed to stderr, returns 1" {
    run --separate-stderr fail one two
    [ "$status" -eq 1 ]
    [ "$output" = "" ]
    [ "$stderr" = "one two" ]
}

@test "fail: no arguments -> reads stdin" {
    run --separate-stderr fail <<< "from stdin"
    [ "$status" -eq 1 ]
    [ "$stderr" = "from stdin" ]
}

@test "fail: defined before the library loads -> kept" {
    fail() { printf 'custom\n' >&2; return 1; }
    load "$BATS_TEST_DIRNAME/../load"
    run --separate-stderr fail x
    [ "$stderr" = "custom" ]
}
