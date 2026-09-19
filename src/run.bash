#
# bats-expect: run
#
# Assertions on the result of bats' `run`: `$status`, `$output`, `$lines`,
# `$stderr` and `$stderr_lines`. Names, options and reports are those of
# bats-assert, so a test written against bats-assert passes unchanged.
#
#   run my_command --flag
#   assert_success
#   assert_output --partial 'done'
#   assert_line --index 0 'first line'
#   refute_stderr

#######################################
# Fails when the last `run` did not exit 0.
#
# Globals:
#   status (Read) - The exit status of the last run
#   output (Read) - Its output
#   stderr (Read) - Its stderr, when run had --separate-stderr
# Returns:
#   0 - The status is 0
#   1 - Otherwise, after the report
#######################################
assert_success() {
    : "${output?}" "${status?}"
    if (( status != 0 )); then
        {
            expect::report::rows 6 'status' "$status"
            expect::report::pairs 6 'output' "$output"
            [[ -n "${stderr-}" ]] && expect::report::pairs 6 'stderr' "$stderr"
        } | expect::report::fail_body 'command failed'
    fi
}

#######################################
# Fails when the last `run` exited 0, or with a status other than the one
# given.
#
# Arguments:
#   $1 (Integer) - (Optional) The expected exit status
# Globals:
#   status (Read) - The exit status of the last run
#   output (Read) - Its output
#   stderr (Read) - Its stderr, when run had --separate-stderr
# Returns:
#   0 - The status is non-zero, and equals $1 when given
#   1 - Otherwise, after the report
#######################################
assert_failure() {
    : "${output?}" "${status?}"
    if (( status == 0 )); then
        {
            expect::report::pairs 6 'output' "$output"
            [[ -n "${stderr-}" ]] && expect::report::pairs 6 'stderr' "$stderr"
        } | expect::report::fail_body 'command succeeded, but it was expected to fail'
    elif (( $# > 0 )) && (( status != $1 )); then
        {
            expect::report::rows 8 'expected' "$1" 'actual' "$status"
            expect::report::pairs 8 'output' "$output"
            [[ -n "${stderr-}" ]] && expect::report::pairs 8 'stderr' "$stderr"
        } | expect::report::fail_body 'command failed as expected, but status differs'
    fi
}

#######################################
# Fails when `$output` does not match the expectation. With no argument, the
# output must be non-empty.
#
# Usage: assert_output [-p | -e] [- | [--] EXPECTED]
#
# Options:
#   -p, --partial  EXPECTED is a substring of the output
#   -e, --regexp   EXPECTED is an extended regular expression
#   -, --stdin     Read EXPECTED from stdin
# Arguments:
#   EXPECTED (String) - The expected output, substring or regular expression
# Globals:
#   output (Read)
# Returns:
#   0 - The output matches
#   1 - Otherwise, after the report, or after a usage error
#######################################
assert_output() {
    expect::run::assert_stream assert_output output "$@"
}

#######################################
# Fails when `$stderr` does not match the expectation. Same options as
# assert_output. Needs `run --separate-stderr`.
#
# Globals:
#   stderr (Read)
# Returns:
#   0 - The stderr matches
#   1 - Otherwise, after the report, or after a usage error
#######################################
assert_stderr() {
    expect::run::assert_stream assert_stderr stderr "$@"
}

#######################################
# Fails when `$output` matches the expectation. Same options as assert_output.
# With no argument, the output must be empty.
#
# Globals:
#   output (Read)
# Returns:
#   0 - The output does not match
#   1 - Otherwise, after the report, or after a usage error
#######################################
refute_output() {
    expect::run::refute_stream refute_output output "$@"
}

#######################################
# Fails when `$stderr` matches the expectation. Same options as assert_output.
#
# Globals:
#   stderr (Read)
# Returns:
#   0 - The stderr does not match
#   1 - Otherwise, after the report, or after a usage error
#######################################
refute_stderr() {
    expect::run::refute_stream refute_stderr stderr "$@"
}

#######################################
# Fails when no line of `$output` matches the expectation, or the line at an
# index does not.
#
# Usage: assert_line [-n INDEX] [-p | -e] [--] EXPECTED
#
# Options:
#   -n, --index INDEX  Match the line at INDEX, counted from 0
#   -p, --partial      EXPECTED is a substring of the line
#   -e, --regexp       EXPECTED is an extended regular expression
# Arguments:
#   EXPECTED (String) - The expected line, substring or regular expression
# Globals:
#   lines (Read), output (Read)
# Returns:
#   0 - A line matches
#   1 - Otherwise, after the report, or after a usage error
#######################################
assert_line() {
    expect::run::assert_line assert_line output "$@"
}

#######################################
# Fails when no line of `$stderr` matches the expectation, or the line at an
# index does not. Same options as assert_line.
#
# Globals:
#   stderr_lines (Read), stderr (Read)
# Returns:
#   0 - A line matches
#   1 - Otherwise, after the report, or after a usage error
#######################################
assert_stderr_line() {
    expect::run::assert_line assert_stderr_line stderr "$@"
}

#######################################
# Fails when a line of `$output` matches the expectation, or the line at an
# index does. Same options as assert_line.
#
# Globals:
#   lines (Read), output (Read)
# Returns:
#   0 - No line matches
#   1 - Otherwise, after the report, or after a usage error
#######################################
refute_line() {
    expect::run::refute_line refute_line output "$@"
}

#######################################
# Fails when a line of `$stderr` matches the expectation, or the line at an
# index does. Same options as assert_line.
#
# Globals:
#   stderr_lines (Read), stderr (Read)
# Returns:
#   0 - No line matches
#   1 - Otherwise, after the report, or after a usage error
#######################################
refute_stderr_line() {
    expect::run::refute_line refute_stderr_line stderr "$@"
}

#######################################
# Fails when the command given as arguments fails. The arguments are the
# command; nothing is passed through eval.
#
# Arguments:
#   $@ - The command and its arguments
# Returns:
#   0 - The command exited 0
#   1 - Otherwise, after the report
#######################################
assert() {
    if ! "$@"; then
        expect::report::fail 'assertion failed' 'expression' "$*"
    fi
}

#######################################
# Fails when the command given as arguments succeeds.
#
# Arguments:
#   $@ - The command and its arguments
# Returns:
#   0 - The command exited non-zero
#   1 - Otherwise, after the report
#######################################
refute() {
    if "$@"; then
        expect::report::fail 'assertion succeeded, but it was expected to fail' 'expression' "$*"
    fi
}

# ------------------------------------------------------------------------------
# Internal
# ------------------------------------------------------------------------------

#######################################
# Parses the options shared by the stream and line assertions into variables
# of the caller: `mode` (literal, partial or regexp), `use_stdin`, `has_index`,
# `index`, and the remaining arguments in `rest`.
#
# Arguments:
#   $1 (String) - The calling assertion, for error reports
#   $@          - The arguments to parse
# Returns:
#   0 - Parsed
#   1 - After a usage error report
#######################################
expect::run::parse_options() {
    local caller="$1"
    shift
    mode=literal use_stdin=0 has_index=0 index=0 rest=()
    local -i partial=0 regexp=0
    while (( $# > 0 )); do
        case "$1" in
            -p|--partial) partial=1; shift ;;
            -e|--regexp) regexp=1; shift ;;
            -|--stdin) use_stdin=1; shift ;;
            -n|--index)
                if (( $# < 2 )) || [[ ! "$2" =~ ^-?([0-9]|[1-9][0-9]+)$ ]]; then
                    expect::report::error "$caller" "\`--index' requires an integer argument: \`${2-}'"
                    return 1
                fi
                has_index=1; index=$2; shift 2 ;;
            --) shift; break ;;
            *) break ;;
        esac
    done
    if (( partial && regexp )); then
        expect::report::error "$caller" "\`--partial' and \`--regexp' are mutually exclusive"
        return 1
    fi
    (( partial )) && mode=partial
    (( regexp )) && mode=regexp
    rest=("$@")
    return 0
}

#######################################
# The body of assert_output and assert_stderr.
#
# Arguments:
#   $1 (String) - The calling assertion
#   $2 (String) - The stream variable: output or stderr
#   $@          - The assertion's arguments
# Returns:
#   0 - The stream matches
#   1 - Otherwise, after the report, or after a usage error
#######################################
expect::run::assert_stream() {
    local caller="$1" stream_type="$2"
    shift 2
    : "${!stream_type?}"
    local stream="${!stream_type}"
    local mode use_stdin has_index index
    local -a rest
    expect::run::parse_options "$caller" "$@" || return 1

    if (( $# == 0 )); then
        if [[ -z "$stream" ]]; then
            printf 'expected non-empty %s, but %s was empty\n' "$stream_type" "$stream_type" \
                | expect::report::fail_body "no $stream_type"
            return 1
        fi
        return 0
    fi

    local expected
    if (( use_stdin )); then expected="$(cat -)"; else expected="${rest[0]-}"; fi

    case "$mode" in
        regexp)
            expect::report::require_regex "$caller" "$expected" || return 1
            if [[ ! "$stream" =~ $expected ]]; then
                expect::report::fail "regular expression does not match $stream_type" \
                    'regexp' "$expected" "$stream_type" "$stream"
            fi ;;
        partial)
            if [[ "$stream" != *"$expected"* ]]; then
                expect::report::fail "$stream_type does not contain substring" \
                    'substring' "$expected" "$stream_type" "$stream"
            fi ;;
        *)
            if [[ "$stream" != "$expected" ]]; then
                expect::report::fail "$stream_type differs" 'expected' "$expected" 'actual' "$stream"
            fi ;;
    esac
}

#######################################
# The body of refute_output and refute_stderr.
#
# Arguments:
#   $1 (String) - The calling assertion
#   $2 (String) - The stream variable: output or stderr
#   $@          - The assertion's arguments
# Returns:
#   0 - The stream does not match
#   1 - Otherwise, after the report, or after a usage error
#######################################
expect::run::refute_stream() {
    local caller="$1" stream_type="$2"
    shift 2
    : "${!stream_type?}"
    local stream="${!stream_type}"
    local mode use_stdin has_index index
    local -a rest
    expect::run::parse_options "$caller" "$@" || return 1

    if (( $# == 0 )); then
        if [[ -n "$stream" ]]; then
            expect::report::fail "$stream_type non-empty, but expected no $stream_type" "$stream_type" "$stream"
            return 1
        fi
        return 0
    fi

    local unexpected
    if (( use_stdin )); then unexpected="$(cat -)"; else unexpected="${rest[0]-}"; fi

    case "$mode" in
        regexp)
            expect::report::require_regex "$caller" "$unexpected" || return 1
            if [[ "$stream" =~ $unexpected ]]; then
                expect::report::fail "regular expression should not match $stream_type" \
                    'regexp' "$unexpected" "$stream_type" "$stream"
            fi ;;
        partial)
            if [[ "$stream" == *"$unexpected"* ]]; then
                expect::report::fail "$stream_type should not contain substring" \
                    'substring' "$unexpected" "$stream_type" "$stream"
            fi ;;
        *)
            if [[ "$stream" == "$unexpected" ]]; then
                expect::report::fail "$stream_type equals, but it was expected to differ" "$stream_type" "$stream"
            fi ;;
    esac
}

#######################################
# Names the lines array of a stream.
#
# Arguments:
#   $1 (String) - The stream: output or stderr
# Outputs:
#   lines or stderr_lines
#######################################
expect::run::lines_var() {
    if [[ "$1" == output ]]; then printf 'lines\n'; else printf 'stderr_lines\n'; fi
}

#######################################
# Fails with a usage error when the lines array of a stream is not declared,
# which means `run` did not run. An empty array passes: bats-assert's
# `${lines?}` check rejects an empty output, this one does not.
#
# Arguments:
#   $1 (String) - The calling assertion
#   $2 (String) - The array name
# Returns:
#   0 - Declared
#   1 - After the error report
#######################################
expect::run::require_lines() {
    if ! declare -p "$2" >/dev/null 2>&1; then
        expect::report::error "$1" "\`$2' is not set. Call \`run' first."
        return 1
    fi
}

#######################################
# The body of assert_line and assert_stderr_line.
#
# Arguments:
#   $1 (String) - The calling assertion
#   $2 (String) - The stream: output or stderr
#   $@          - The assertion's arguments
# Returns:
#   0 - A line matches
#   1 - Otherwise, after the report, or after a usage error
#######################################
expect::run::assert_line() {
    local caller="$1" stream_type="$2"
    shift 2
    local lines_var; lines_var="$(expect::run::lines_var "$stream_type")"
    expect::run::require_lines "$caller" "$lines_var" || return 1
    local -n stream_lines="$lines_var"
    local stream="${!stream_type-}"
    local mode use_stdin has_index index
    local -a rest
    expect::run::parse_options "$caller" "$@" || return 1
    local expected="${rest[0]-}"
    [[ "$mode" == regexp ]] && { expect::report::require_regex "$caller" "$expected" || return 1; }

    local -i i
    if (( has_index )); then
        local line="${stream_lines[index]-}"
        case "$mode" in
            regexp)
                [[ "$line" =~ $expected ]] && return 0
                expect::report::fail 'regular expression does not match line' \
                    'index' "$index" 'regexp' "$expected" 'line' "$line" ;;
            partial)
                [[ "$line" == *"$expected"* ]] && return 0
                expect::report::fail 'line does not contain substring' \
                    'index' "$index" 'substring' "$expected" 'line' "$line" ;;
            *)
                [[ "$line" == "$expected" ]] && return 0
                expect::report::fail 'line differs' 'index' "$index" 'expected' "$expected" 'actual' "$line" ;;
        esac
        return 1
    fi

    local title key
    case "$mode" in
        regexp)
            for (( i = 0; i < ${#stream_lines[@]}; ++i )); do
                [[ "${stream_lines[i]}" =~ $expected ]] && return 0
            done
            title="no $stream_type line matches regular expression"; key=regexp ;;
        partial)
            for (( i = 0; i < ${#stream_lines[@]}; ++i )); do
                [[ "${stream_lines[i]}" == *"$expected"* ]] && return 0
            done
            title="no $stream_type line contains substring"; key=substring ;;
        *)
            for (( i = 0; i < ${#stream_lines[@]}; ++i )); do
                [[ "${stream_lines[i]}" == "$expected" ]] && return 0
            done
            title="$stream_type does not contain line"; key=line ;;
    esac
    local -i width
    width="$(expect::report::single_width "$key" "$expected" "$stream_type" "$stream")"
    {
        expect::report::rows "$width" "$key" "$expected"
        expect::report::pairs "$width" "$stream_type" "$stream"
    } | expect::report::fail_body "$title"
}

#######################################
# The body of refute_line and refute_stderr_line. When a line matches in a
# stream of several lines, the report marks that line with `>`.
#
# Arguments:
#   $1 (String) - The calling assertion
#   $2 (String) - The stream: output or stderr
#   $@          - The assertion's arguments
# Returns:
#   0 - No line matches
#   1 - Otherwise, after the report, or after a usage error
#######################################
expect::run::refute_line() {
    local caller="$1" stream_type="$2"
    shift 2
    local lines_var; lines_var="$(expect::run::lines_var "$stream_type")"
    expect::run::require_lines "$caller" "$lines_var" || return 1
    local -n stream_lines="$lines_var"
    local stream="${!stream_type-}"
    local mode use_stdin has_index index
    local -a rest
    expect::run::parse_options "$caller" "$@" || return 1
    local unexpected="${rest[0]-}"
    [[ "$mode" == regexp ]] && { expect::report::require_regex "$caller" "$unexpected" || return 1; }

    local -i i
    if (( has_index )); then
        local line="${stream_lines[index]-}"
        case "$mode" in
            regexp)
                if [[ "$line" =~ $unexpected ]]; then
                    expect::report::fail 'regular expression should not match line' \
                        'index' "$index" 'regexp' "$unexpected" 'line' "$line"
                    return 1
                fi ;;
            partial)
                if [[ "$line" == *"$unexpected"* ]]; then
                    expect::report::fail 'line should not contain substring' \
                        'index' "$index" 'substring' "$unexpected" 'line' "$line"
                    return 1
                fi ;;
            *)
                if [[ "$line" == "$unexpected" ]]; then
                    expect::report::fail 'line should differ' 'index' "$index" 'line' "$line"
                    return 1
                fi ;;
        esac
        return 0
    fi

    local title key
    for (( i = 0; i < ${#stream_lines[@]}; ++i )); do
        case "$mode" in
            regexp)  [[ "${stream_lines[i]}" =~ $unexpected ]] || continue
                     title='no line should match the regular expression'; key=regexp ;;
            partial) [[ "${stream_lines[i]}" == *"$unexpected"* ]] || continue
                     title='no line should contain substring'; key=substring ;;
            *)       [[ "${stream_lines[i]}" == "$unexpected" ]] || continue
                     title="line should not be in $stream_type"; key=line ;;
        esac
        local -i width
        width="$(expect::report::single_width "$key" "$unexpected" 'index' "$i" "$stream_type" "$stream")"
        {
            expect::report::rows "$width" "$key" "$unexpected" 'index' "$i"
            if expect::report::is_single_line "$stream"; then
                expect::report::rows "$width" "$stream_type" "$stream"
            else
                printf '%s (%d lines):\n' "$stream_type" "$(expect::report::count_lines "$stream")"
                expect::report::mark_line "$stream" "$i"
            fi
        } | expect::report::fail_body "$title"
        return 1
    done
    return 0
}
