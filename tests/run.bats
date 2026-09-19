#!/usr/bin/env bats

# shellcheck disable=SC2034,SC2154,SC2030,SC2031
# Variables here are read by name through the library or set by `capture`, and
# every @test is its own process, not a subshell of the file.

# ==============================================================================
# bats-expect: run - Test Suite
# ==============================================================================
# The bats-assert compatible assertions on `run`.
#   01. assert_success
#   02. assert_failure
#   03. assert_output
#   04. refute_output
#   05. assert_line
#   06. refute_line
#   07. assert_stderr, refute_stderr, assert_stderr_line, refute_stderr_line
#   08. assert and refute
# ==============================================================================

load helper
setup() { common_setup; }

three_lines() { printf 'one\ntwo\nthree\n'; }
noisy() { echo out; echo err >&2; return "${1:-0}"; }

# ==============================================================================
# GROUP 01: assert_success
# ==============================================================================

@test "assert_success: status 0 -> passes" {
    run true
    assert_passes assert_success
}

@test "assert_success: non-zero status -> fails as command failed" {
    run noisy 3
    assert_fails -p '-- command failed --' assert_success
}

@test "assert_success: non-zero status -> reports the status as a row" {
    run noisy 3
    assert_fails -p 'status : 3' assert_success
}

@test "assert_success: merged output of two lines -> reported as a block" {
    run noisy 3
    assert_fails -p 'output (2 lines):' assert_success
}

@test "assert_success: --separate-stderr -> the report shows stderr" {
    run --separate-stderr noisy 1
    assert_fails -p 'stderr : err' assert_success
}

# ==============================================================================
# GROUP 02: assert_failure
# ==============================================================================

@test "assert_failure: non-zero status -> passes" {
    run false
    assert_passes assert_failure
}

@test "assert_failure: expected status matches -> passes" {
    run false
    assert_passes assert_failure 1
}

@test "assert_failure: status 0 -> fails" {
    run noisy
    assert_fails -p 'command succeeded, but it was expected to fail' assert_failure
}

@test "assert_failure: other status -> fails with expected and actual" {
    run noisy 2
    assert_fails -p 'command failed as expected, but status differs' assert_failure 3
    assert_fails -p 'expected : 3' assert_failure 3
    assert_fails -p 'actual   : 2' assert_failure 3
}

# ==============================================================================
# GROUP 03: assert_output
# ==============================================================================

@test "assert_output: literal -> the whole output must match" {
    run three_lines
    assert_passes assert_output $'one\ntwo\nthree'
}

@test "assert_output: literal mismatch -> output differs with expected and actual" {
    run three_lines
    assert_fails -p '-- output differs --' assert_output one
    assert_fails -p 'expected (1 lines):' assert_output one
}

@test "assert_output: --partial -> a substring passes" {
    run three_lines
    assert_passes assert_output --partial tw
    assert_passes assert_output -p $'one\ntwo'
}

@test "assert_output: --partial mismatch -> output does not contain substring" {
    run three_lines
    assert_fails -p 'output does not contain substring' assert_output --partial zzz
}

@test "assert_output: --regexp -> matches the whole output" {
    run three_lines
    assert_passes assert_output --regexp '^one.*three$'
    assert_passes assert_output -e 'tw.'
}

@test "assert_output: --regexp mismatch -> regular expression does not match output" {
    run three_lines
    assert_fails -p 'regular expression does not match output' assert_output --regexp '^two'
}

@test "assert_output: --stdin -> the expectation is read from stdin" {
    run three_lines
    assert_output - <<< $'one\ntwo\nthree'
    assert_output --stdin <<< $'one\ntwo\nthree'
}

@test "assert_output: no argument -> the output must be non-empty" {
    run three_lines
    assert_passes assert_output
}

@test "assert_output: no argument on empty output -> no output" {
    run true
    assert_fails -p '-- no output --' assert_output
}

@test "assert_output: -- -> a value that starts with a dash" {
    run echo -- -p
    assert_passes assert_output -- '-- -p'
}

@test "assert_output: --partial with --regexp -> usage error" {
    run three_lines
    assert_fails -p '-- ERROR: assert_output --' assert_output --partial --regexp x
    assert_fails -p 'mutually exclusive' assert_output --partial --regexp x
}

@test "assert_output: invalid regexp -> usage error" {
    run three_lines
    assert_fails -p '-- ERROR: assert_output --' assert_output --regexp '('
}

# ==============================================================================
# GROUP 04: refute_output
# ==============================================================================

@test "refute_output: different output -> passes" {
    run three_lines
    assert_passes refute_output one
}

@test "refute_output: same output -> output equals, but it was expected to differ" {
    run three_lines
    assert_fails -p 'output equals, but it was expected to differ' refute_output $'one\ntwo\nthree'
}

@test "refute_output: --partial found -> output should not contain substring" {
    run three_lines
    assert_fails -p 'output should not contain substring' refute_output --partial two
}

@test "refute_output: --regexp matched -> regular expression should not match output" {
    run three_lines
    assert_fails -p 'regular expression should not match output' refute_output --regexp 'tw.'
}

@test "refute_output: no argument -> the output must be empty" {
    run true
    assert_passes refute_output
    run three_lines
    assert_fails -p 'output non-empty, but expected no output' refute_output
}

# ==============================================================================
# GROUP 05: assert_line
# ==============================================================================

@test "assert_line: a line equals -> passes" {
    run three_lines
    assert_passes assert_line two
}

@test "assert_line: no line equals -> output does not contain line" {
    run three_lines
    assert_fails -p 'output does not contain line' assert_line tw
    assert_fails -p 'line : tw' assert_line tw
}

@test "assert_line: --index -> the line at the index" {
    run three_lines
    assert_passes assert_line --index 1 two
    assert_passes assert_line -n 2 three
}

@test "assert_line: --index mismatch -> line differs with the index" {
    run three_lines
    assert_fails -p '-- line differs --' assert_line --index 0 two
    assert_fails -p 'index    : 0' assert_line --index 0 two
}

@test "assert_line: --partial -> a line containing the text" {
    run three_lines
    assert_passes assert_line --partial hre
    assert_fails -p 'no output line contains substring' assert_line --partial zzz
}

@test "assert_line: --regexp -> a line matching" {
    run three_lines
    assert_passes assert_line --regexp '^t.*e$'
    assert_fails -p 'no output line matches regular expression' assert_line --regexp '^z'
}

@test "assert_line: --index with --partial and --regexp" {
    run three_lines
    assert_passes assert_line --index 1 --partial w
    assert_passes assert_line --index 1 --regexp '^tw'
    assert_fails -p 'line does not contain substring' assert_line --index 1 --partial zzz
    assert_fails -p 'regular expression does not match line' assert_line --index 1 --regexp '^z'
}

@test "assert_line: empty output -> a search fails without a bash error" {
    run true
    assert_fails -p 'output does not contain line' assert_line one
}

@test "assert_line: --index without an integer -> usage error" {
    run three_lines
    assert_fails -p "\`--index' requires an integer argument" assert_line --index x two
}

@test "assert_line: invalid regexp -> usage error" {
    run three_lines
    assert_fails -p '-- ERROR: assert_line --' assert_line --regexp '('
}

@test "assert_line: no run before -> usage error, not a bash error" {
    unset lines
    assert_fails -p "\`lines' is not set. Call \`run' first." assert_line x
}

# ==============================================================================
# GROUP 06: refute_line
# ==============================================================================

@test "refute_line: no line equals -> passes" {
    run three_lines
    assert_passes refute_line four
}

@test "refute_line: a line equals -> line should not be in output" {
    run three_lines
    assert_fails -p 'line should not be in output' refute_line two
}

@test "refute_line: a line equals -> the report marks the line" {
    run three_lines
    assert_fails -p 'line  : two' refute_line two
    assert_fails -p 'index : 1' refute_line two
    assert_fails -p '> two' refute_line two
    assert_fails -p '  one' refute_line two
}

@test "refute_line: --index -> only that line is checked" {
    run three_lines
    assert_passes refute_line --index 1 one
    assert_fails -p '-- line should differ --' refute_line --index 1 two
}

@test "refute_line: --index with --partial and --regexp" {
    run three_lines
    assert_fails -p 'line should not contain substring' refute_line --index 1 --partial w
    assert_fails -p 'regular expression should not match line' refute_line --index 1 --regexp '^tw'
}

@test "refute_line: --partial and --regexp anywhere" {
    run three_lines
    assert_fails -p 'no line should contain substring' refute_line --partial hre
    assert_fails -p 'no line should match the regular expression' refute_line --regexp '^t'
}

@test "refute_line: empty output -> passes" {
    run true
    assert_passes refute_line one
}

@test "refute_line: --partial with --regexp -> usage error" {
    run three_lines
    assert_fails -p 'mutually exclusive' refute_line --partial --regexp x
}

@test "refute_line: --index without a value -> usage error" {
    run three_lines
    assert_fails -p '-- ERROR: refute_line --' refute_line --index
}

# ==============================================================================
# GROUP 07: stderr variants
# ==============================================================================

@test "assert_stderr: --separate-stderr -> literal and partial" {
    run --separate-stderr noisy
    assert_passes assert_stderr err
    assert_passes assert_stderr --partial er
    assert_fails -p '-- stderr differs --' assert_stderr out
}

@test "refute_stderr: -> inverted" {
    run --separate-stderr noisy
    assert_passes refute_stderr out
    assert_fails -p 'stderr equals, but it was expected to differ' refute_stderr err
}

@test "assert_stderr_line: -> lines of stderr" {
    run --separate-stderr noisy
    assert_passes assert_stderr_line --index 0 err
    assert_fails -p 'stderr does not contain line' assert_stderr_line out
}

@test "refute_stderr_line: -> lines of stderr, inverted" {
    run --separate-stderr noisy
    assert_passes refute_stderr_line out
    assert_fails -p 'line should not be in stderr' refute_stderr_line err
}

# ==============================================================================
# GROUP 08: assert and refute
# ==============================================================================

@test "assert: command succeeds -> passes" {
    assert_passes assert true
    assert_passes assert test 1 -lt 2
}

@test "assert: command fails -> assertion failed with the expression" {
    assert_fails -p '-- assertion failed --' assert false
    assert_fails -p 'expression : test 2 -lt 1' assert test 2 -lt 1
}

@test "assert: arguments -> passed as they are, never evaluated" {
    local file="$BATS_TEST_TMPDIR/pwned"
    # shellcheck disable=SC2016  # the point is that this is never expanded
    assert_passes assert test -n '$(touch '"$file"')'
    [ ! -e "$file" ]
}

@test "refute: command fails -> passes" {
    assert_passes refute false
}

@test "refute: command succeeds -> assertion succeeded, but it was expected to fail" {
    assert_fails -p 'assertion succeeded, but it was expected to fail' refute true
}
