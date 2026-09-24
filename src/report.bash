#
# bats-expect: report
#
# The failure report every assertion prints, in the format bats-assert users know:
#
#     -- values do not equal --
#     expected : foo
#     actual   : bar
#     --
#
# A value that spans lines is printed as a block instead of a row. `fail` comes
# from bats-support when it is loaded; a polyfill with the same contract is
# defined otherwise, so the library loads on its own.

if ! declare -F fail >/dev/null; then
    #######################################
    # Prints a failure message to stderr and returns 1. Same contract as
    # bats-support's fail, so either one can be loaded first.
    #
    # Arguments:
    #   $@ (Strings) - (Optional) The message. Read from stdin when absent
    # Outputs:
    #   The message, on stderr
    # Returns:
    #   1 - Always
    #######################################
    # shellcheck disable=SC2120  # the arguments are for callers outside this file
    fail() {
        if (( $# > 0 )); then
            printf '%s\n' "$*" >&2
        else
            expect::report::copy_stdin >&2
        fi
        return 1
    }
fi

#######################################
# Copies stdin to stdout in pure bash, so a report still prints when a test
# has emptied PATH or mocked cat.
#
# Inputs:
#   The text, on stdin
# Outputs:
#   The same text
#######################################
expect::report::copy_stdin() {
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        printf '%s\n' "$line"
    done
}

#######################################
# Counts the lines of a value. A trailing newline does not add a line, so
# "a\nb" and "a\nb\n" both count 2, and the empty string counts 0.
#
# Arguments:
#   $1 (String) - The value
# Outputs:
#   The number of lines
#######################################
expect::report::count_lines() {
    local -i n=0
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        (( ++n ))
    done < <(printf '%s' "$1")
    printf '%d\n' "$n"
}

#######################################
# Tells whether every value fits on one line.
#
# Arguments:
#   $@ (Strings) - The values
# Returns:
#   0 - None of the values spans more than one line
#   1 - At least one does
#######################################
expect::report::is_single_line() {
    local value
    for value in "$@"; do
        (( $(expect::report::count_lines "$value") > 1 )) && return 1
    done
    return 0
}

#######################################
# Prints key/value pairs as aligned rows, one per pair: `key   : value`.
#
# Arguments:
#   $1 (Integer) - The key column width
#   $@ (Strings) - key value [key value ...]
# Outputs:
#   One row per pair
#######################################
expect::report::rows() {
    local -i width="$1"
    shift
    while (( $# > 1 )); do
        printf '%-*s : %s\n' "$width" "$1" "$2"
        shift 2
    done
}

#######################################
# Prints key/value pairs as blocks: `key (N lines):` followed by the value,
# each line indented by two spaces. An empty value prints as one empty line,
# as bats-support prints it.
#
# Arguments:
#   $@ (Strings) - key value [key value ...]
# Outputs:
#   One block per pair
#######################################
expect::report::blocks() {
    local line
    while (( $# > 1 )); do
        printf '%s (%d lines):\n' "$1" "$(expect::report::count_lines "$2")"
        [[ -n "$2" ]] || printf '\n'
        while IFS= read -r line || [[ -n "$line" ]]; do
            printf '  %s\n' "$line"
        done < <(printf '%s' "$2")
        shift 2
    done
}

#######################################
# Prints key/value pairs as rows when every value is one line, and as blocks
# when any value spans lines. This is bats-support's rule, so the reports of
# the bats-assert compatible assertions match bats-assert's byte for byte.
#
# Arguments:
#   $1 (Integer) - The key column width, used for rows
#   $@ (Strings) - key value [key value ...]
# Outputs:
#   The rows or the blocks
#######################################
expect::report::pairs() {
    local -i width="$1"
    shift
    local -a pairs=("$@") values=()
    local -i i
    for (( i = 1; i < ${#pairs[@]}; i += 2 )); do
        values+=("${pairs[i]}")
    done
    if expect::report::is_single_line "${values[@]}"; then
        expect::report::rows "$width" "$@"
    else
        expect::report::blocks "$@"
    fi
}

#######################################
# Measures the longest key among the pairs, for aligning rows.
#
# Arguments:
#   $@ (Strings) - key value [key value ...]
# Outputs:
#   The width
#######################################
expect::report::width() {
    local -i width=0
    while (( $# > 1 )); do
        (( ${#1} > width )) && width=${#1}
        shift 2
    done
    printf '%d\n' "$width"
}

#######################################
# Measures the longest key among the pairs whose value is one line. Reports
# that print some pairs as rows and one stream as a block align the rows on
# this width, as bats-support does.
#
# Arguments:
#   $@ (Strings) - key value [key value ...]
# Outputs:
#   The width
#######################################
expect::report::single_width() {
    local -i width=0
    while (( $# > 1 )); do
        expect::report::is_single_line "$2" && (( ${#1} > width )) && width=${#1}
        shift 2
    done
    printf '%d\n' "$width"
}

#######################################
# Wraps a body in the `-- title --` frame: a blank line, the title line, the
# body, a closing `--` and a blank line.
#
# Arguments:
#   $1 (String) - The title
# Inputs:
#   The body, on stdin
# Outputs:
#   The framed body
#######################################
expect::report::decorate() {
    printf '\n-- %s --\n' "$1"
    expect::report::copy_stdin
    printf -- '--\n\n'
}

#######################################
# Prints a failure report and fails. The pairs are printed as rows or blocks
# by the all-or-nothing rule, aligned on the longest key. This is what most
# assertions call.
#
# Arguments:
#   $1 (String)  - The title
#   $@ (Strings) - key value [key value ...]
# Outputs:
#   The report, on stderr through fail
# Returns:
#   1 - Always
#######################################
expect::report::fail() {
    local title="$1"
    shift
    expect::report::pairs "$(expect::report::width "$@")" "$@" | expect::report::fail_body "$title"
}

#######################################
# Frames a body read from stdin under a title and fails. For reports that mix
# rows and blocks, which build their body from rows, pairs and blocks.
#
# Arguments:
#   $1 (String) - The title
# Inputs:
#   The body, on stdin
# Outputs:
#   The report, on stderr through fail
# Returns:
#   1 - Always
#######################################
expect::report::fail_body() {
    # shellcheck disable=SC2119  # fail reads the report from stdin
    expect::report::decorate "$1" | fail
}

#######################################
# Prints a usage error for an assertion and fails. A usage error is a wrong
# call, such as an invalid option, as opposed to a failed expectation.
#
# Arguments:
#   $1 (String) - The calling assertion
#   $2 (String) - The message
# Outputs:
#   The report under `-- ERROR: <assertion> --`, on stderr through fail
# Returns:
#   1 - Always
#######################################
expect::report::error() {
    # shellcheck disable=SC2119  # fail reads the report from stdin
    printf '%s\n' "$2" | expect::report::decorate "ERROR: $1" | fail
}

#######################################
# Checks that a value compiles as an extended regular expression, and reports
# a usage error for the calling assertion when it does not. Bash 5.3 says why
# on stderr; that text is used when it is there.
#
# Arguments:
#   $1 (String) - The calling assertion
#   $2 (String) - The regular expression
# Returns:
#   0 - Valid
#   1 - Invalid, after the error report
#######################################
expect::report::require_regex() {
    local caller="$1" regex="$2" error
    # [[ =~ ]] returns 2 for a regex it cannot compile, 1 for a plain non-match.
    # The || keeps the non-match from tripping errexit in the caller.
    local -i result=0
    error="$([[ '' =~ $regex ]] 2>&1)" || result=$?
    if (( result == 2 )); then
        local message="Invalid extended regular expression: \`$regex'"
        [[ "$error" =~ (invalid regular expression .*) ]] && message="${BASH_REMATCH[1]}"
        expect::report::error "$caller" "$message"
        return 1
    fi
    return 0
}

#######################################
# Prints the lines of a value with one of them marked, for a report that points
# at an offending line: the marked line starts with `> `, the others with two
# spaces.
#
# Arguments:
#   $1 (String)  - The value
#   $2 (Integer) - The index of the line to mark, from 0
# Outputs:
#   The lines
#######################################
expect::report::mark_line() {
    local value="$1"
    local -i target="$2" idx=0
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        if (( idx == target )); then
            printf '> %s\n' "$line"
        else
            printf '  %s\n' "$line"
        fi
        (( ++idx ))
    done < <(printf '%s' "$value")
}
