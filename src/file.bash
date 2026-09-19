#
# bats-expect: file
#
# Assertions on paths: existence by type, emptiness, content, mode, symlink
# targets and equality. Every `assert_*` has a `refute_*`. The bats-file names
# for the same checks (`assert_file_not_exists`, `assert_not_symlink_to`, ...)
# are kept as aliases, so a test written against bats-file passes unchanged;
# one difference: `assert_file_contains` matches text, and takes `--regexp` for
# a pattern, where bats-file always takes a pattern.
#
#   assert_file_exists "$conf"
#   assert_file_contains "$conf" 'port = 8080'
#   assert_file_permission 0600 "$key"
#   assert_symlink_to "$target" "$link"
#   refute_exists "$tmp/leftover"

#######################################
# Fails when nothing exists at the path. A dangling symbolic link exists.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - Something is there
#   1 - Otherwise, after the report
#######################################
assert_exists() {
    [[ -e "${1-}" || -L "${1-}" ]] || expect::report::fail 'file or directory does not exist' 'path' "${1-}"
}

#######################################
# Fails when anything exists at the path.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - Nothing there
#   1 - Otherwise, after the report
#######################################
refute_exists() {
    if [[ -e "${1-}" || -L "${1-}" ]]; then
        expect::report::fail 'file or directory exists, but it was expected to be absent' 'path' "${1-}"
    fi
}

#######################################
# Fails when the path is not a regular file.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - A regular file
#   1 - Otherwise, after the report
#######################################
assert_file_exists() {
    [[ -f "${1-}" ]] || expect::report::fail 'file does not exist' 'path' "${1-}"
}

#######################################
# Fails when the path is a regular file.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - Not a regular file
#   1 - Otherwise, after the report
#######################################
refute_file_exists() {
    [[ ! -f "${1-}" ]] || expect::report::fail 'file exists, but it was expected to be absent' 'path' "${1-}"
}

#######################################
# Fails when the path is not a directory.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - A directory
#   1 - Otherwise, after the report
#######################################
assert_dir_exists() {
    [[ -d "${1-}" ]] || expect::report::fail 'directory does not exist' 'path' "${1-}"
}

#######################################
# Fails when the path is a directory.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - Not a directory
#   1 - Otherwise, after the report
#######################################
refute_dir_exists() {
    [[ ! -d "${1-}" ]] || expect::report::fail 'directory exists, but it was expected to be absent' 'path' "${1-}"
}

#######################################
# Fails when the path is not a symbolic link.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - A symbolic link
#   1 - Otherwise, after the report
#######################################
assert_link_exists() {
    [[ -L "${1-}" ]] || expect::report::fail 'symbolic link does not exist' 'path' "${1-}"
}

#######################################
# Fails when the path is a symbolic link.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - Not a symbolic link
#   1 - Otherwise, after the report
#######################################
refute_link_exists() {
    [[ ! -L "${1-}" ]] || expect::report::fail 'symbolic link exists, but it was expected to be absent' 'path' "${1-}"
}

#######################################
# Fails when the file is missing or has content. The report shows the content.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - An empty file
#   1 - Otherwise, after the report
#######################################
assert_file_empty() {
    assert_file_exists "${1-}" || return 1
    if [[ -s "$1" ]]; then
        expect::report::fail 'file is not empty' 'path' "$1" 'content' "$(cat -- "$1")"
    fi
}

#######################################
# Fails when the file is missing or empty.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - A file with content
#   1 - Otherwise, after the report
#######################################
refute_file_empty() {
    assert_file_exists "${1-}" || return 1
    [[ -s "$1" ]] || expect::report::fail 'file is empty' 'path' "$1"
}

#######################################
# Fails when the directory is missing or has entries. The report lists them,
# dotfiles included.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - An empty directory
#   1 - Otherwise, after the report
#######################################
assert_dir_empty() {
    assert_dir_exists "${1-}" || return 1
    local entries; entries="$(expect::file::entries "$1")"
    if [[ -n "$entries" ]]; then
        expect::report::fail 'directory is not empty' 'path' "$1" 'entries' "$entries"
    fi
}

#######################################
# Fails when the directory is missing or has no entries.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - A directory with entries
#   1 - Otherwise, after the report
#######################################
refute_dir_empty() {
    assert_dir_exists "${1-}" || return 1
    [[ -n "$(expect::file::entries "$1")" ]] || expect::report::fail 'directory is empty' 'path' "$1"
}

#######################################
# Fails when the file does not contain the text. The text is literal; with
# --regexp it is an extended regular expression matched against each line.
#
# Usage: assert_file_contains [-e | --regexp] PATH EXPECTED
#
# Options:
#   -e, --regexp  EXPECTED is an extended regular expression
# Arguments:
#   PATH (String)     - The file
#   EXPECTED (String) - The text or regular expression
# Returns:
#   0 - Contains it
#   1 - Otherwise, after the report, or after a usage error
#######################################
assert_file_contains() {
    local mode; local -a rest
    expect::file::parse_contains assert_file_contains "$@" || return 1
    assert_file_exists "${rest[0]-}" || return 1
    if [[ "$mode" == regexp ]]; then
        expect::report::require_regex assert_file_contains "${rest[1]-}" || return 1
        if ! grep -qE -- "${rest[1]-}" "${rest[0]}"; then
            expect::report::fail 'file does not contain regular expression' 'path' "${rest[0]}" 'regexp' "${rest[1]-}"
        fi
    elif ! grep -qF -- "${rest[1]-}" "${rest[0]}"; then
        expect::report::fail 'file does not contain text' 'path' "${rest[0]}" 'text' "${rest[1]-}"
    fi
}

#######################################
# Fails when the file contains the text. Same options as assert_file_contains.
# The report shows the first matching line with its number.
#
# Usage: refute_file_contains [-e | --regexp] PATH EXPECTED
#
# Arguments:
#   PATH (String)     - The file
#   EXPECTED (String) - The text or regular expression
# Returns:
#   0 - Does not contain it
#   1 - Otherwise, after the report, or after a usage error
#######################################
refute_file_contains() {
    local mode; local -a rest
    expect::file::parse_contains refute_file_contains "$@" || return 1
    assert_file_exists "${rest[0]-}" || return 1
    if [[ "$mode" == regexp ]]; then
        expect::report::require_regex refute_file_contains "${rest[1]-}" || return 1
        if grep -qE -- "${rest[1]-}" "${rest[0]}"; then
            expect::report::fail 'file contains regular expression' 'path' "${rest[0]}" 'regexp' "${rest[1]-}" \
                'match' "$(grep -nE -- "${rest[1]-}" "${rest[0]}" | head -n 1)"
        fi
    elif grep -qF -- "${rest[1]-}" "${rest[0]}"; then
        expect::report::fail 'file contains text' 'path' "${rest[0]}" 'text' "${rest[1]-}" \
            'match' "$(grep -nF -- "${rest[1]-}" "${rest[0]}" | head -n 1)"
    fi
}

#######################################
# Fails when the path does not have the mode. Mode first, as in bats-file.
#
# Arguments:
#   $1 (String) - The octal mode, 644 or 0644
#   $2 (String) - The path
# Returns:
#   0 - The mode matches
#   1 - Otherwise, after the report
#######################################
assert_file_permission() {
    assert_exists "${2-}" || return 1
    local expected actual
    expected="$(expect::file::normalize_mode "${1-}")"
    actual="$(expect::file::mode "$2")"
    if [[ "$actual" != "$expected" ]]; then
        expect::report::fail 'file does not have the permission' 'path' "$2" 'expected' "$expected" 'actual' "$actual"
    fi
}

#######################################
# Fails when the path has the mode. Mode first, as in bats-file.
#
# Arguments:
#   $1 (String) - The octal mode, 644 or 0644
#   $2 (String) - The path
# Returns:
#   0 - Another mode
#   1 - Otherwise, after the report
#######################################
refute_file_permission() {
    assert_exists "${2-}" || return 1
    local expected actual
    expected="$(expect::file::normalize_mode "${1-}")"
    actual="$(expect::file::mode "$2")"
    if [[ "$actual" == "$expected" ]]; then
        expect::report::fail 'file has the permission, but it was expected not to' 'path' "$2" 'permission' "$actual"
    fi
}

#######################################
# Fails when the path is not executable by the caller.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - Executable
#   1 - Otherwise, after the report
#######################################
assert_file_executable() {
    assert_exists "${1-}" || return 1
    [[ -x "$1" ]] || expect::report::fail 'file is not executable' 'path' "$1" 'permission' "$(expect::file::mode "$1")"
}

#######################################
# Fails when the path is executable by the caller.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - Not executable
#   1 - Otherwise, after the report
#######################################
refute_file_executable() {
    assert_exists "${1-}" || return 1
    [[ ! -x "$1" ]] || expect::report::fail 'file is executable' 'path' "$1" 'permission' "$(expect::file::mode "$1")"
}

#######################################
# Fails when the path is not readable by the caller.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - Readable
#   1 - Otherwise, after the report
#######################################
assert_file_readable() {
    assert_exists "${1-}" || return 1
    [[ -r "$1" ]] || expect::report::fail 'file is not readable' 'path' "$1" 'permission' "$(expect::file::mode "$1")"
}

#######################################
# Fails when the path is readable by the caller.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - Not readable
#   1 - Otherwise, after the report
#######################################
refute_file_readable() {
    assert_exists "${1-}" || return 1
    [[ ! -r "$1" ]] || expect::report::fail 'file is readable' 'path' "$1" 'permission' "$(expect::file::mode "$1")"
}

#######################################
# Fails when the path is not writable by the caller.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - Writable
#   1 - Otherwise, after the report
#######################################
assert_file_writable() {
    assert_exists "${1-}" || return 1
    [[ -w "$1" ]] || expect::report::fail 'file is not writable' 'path' "$1" 'permission' "$(expect::file::mode "$1")"
}

#######################################
# Fails when the path is writable by the caller.
#
# Arguments:
#   $1 (String) - The path
# Returns:
#   0 - Not writable
#   1 - Otherwise, after the report
#######################################
refute_file_writable() {
    assert_exists "${1-}" || return 1
    [[ ! -w "$1" ]] || expect::report::fail 'file is writable' 'path' "$1" 'permission' "$(expect::file::mode "$1")"
}

#######################################
# Fails when the two files differ byte for byte. The report shows cmp's
# first difference.
#
# Arguments:
#   $1 (String) - A path
#   $2 (String) - Another path
# Returns:
#   0 - Same content
#   1 - Otherwise, after the report
#######################################
assert_files_equal() {
    assert_file_exists "${1-}" || return 1
    assert_file_exists "${2-}" || return 1
    if ! cmp -s -- "$1" "$2"; then
        expect::report::fail 'files are not the same' 'path' "$1" 'path' "$2" \
            'difference' "$(cmp -- "$1" "$2" 2>&1 || true)"
    fi
}

#######################################
# Fails when the two files are the same byte for byte.
#
# Arguments:
#   $1 (String) - A path
#   $2 (String) - Another path
# Returns:
#   0 - Different
#   1 - Otherwise, after the report
#######################################
refute_files_equal() {
    assert_file_exists "${1-}" || return 1
    assert_file_exists "${2-}" || return 1
    if cmp -s -- "$1" "$2"; then
        expect::report::fail 'files are the same, but they were expected to differ' 'path' "$1" 'path' "$2"
    fi
}

#######################################
# Fails when the link does not resolve to the target. Target first, as in
# bats-file. Both sides are resolved, so a relative link target passes.
#
# Arguments:
#   $1 (String) - The expected target
#   $2 (String) - The link
# Returns:
#   0 - The link resolves to the target
#   1 - Otherwise, after the report
#######################################
assert_symlink_to() {
    assert_link_exists "${2-}" || return 1
    local actual expected
    actual="$(expect::file::resolve "$2")"
    expected="$(expect::file::resolve "${1-}")"
    if [[ "$actual" != "$expected" ]]; then
        expect::report::fail 'symbolic link does not have the correct target' \
            'link' "$2" 'expected' "${1-}" 'actual' "$(readlink -- "$2")"
    fi
}

#######################################
# Fails when the link resolves to the target. Target first, as in bats-file.
#
# Arguments:
#   $1 (String) - The target it must not have
#   $2 (String) - The link
# Returns:
#   0 - Another target
#   1 - Otherwise, after the report
#######################################
refute_symlink_to() {
    assert_link_exists "${2-}" || return 1
    if [[ "$(expect::file::resolve "$2")" == "$(expect::file::resolve "${1-}")" ]]; then
        expect::report::fail 'symbolic link has the target, but it was expected not to' 'link' "$2" 'target' "${1-}"
    fi
}

#######################################
# bats-file's name for refute_exists. Same arguments, report and return value.
#
# Returns:
#   0 - As refute_exists
#   1 - As refute_exists, after its report
#######################################
assert_not_exists() {
    refute_exists "$@"
}

#######################################
# bats-file's name for refute_file_exists. Same arguments, report and return value.
#
# Returns:
#   0 - As refute_file_exists
#   1 - As refute_file_exists, after its report
#######################################
assert_file_not_exists() {
    refute_file_exists "$@"
}

#######################################
# bats-file's name for refute_dir_exists. Same arguments, report and return value.
#
# Returns:
#   0 - As refute_dir_exists
#   1 - As refute_dir_exists, after its report
#######################################
assert_dir_not_exists() {
    refute_dir_exists "$@"
}

#######################################
# bats-file's name for refute_link_exists. Same arguments, report and return value.
#
# Returns:
#   0 - As refute_link_exists
#   1 - As refute_link_exists, after its report
#######################################
assert_link_not_exists() {
    refute_link_exists "$@"
}

#######################################
# bats-file's name for refute_file_empty. Same arguments, report and return value.
#
# Returns:
#   0 - As refute_file_empty
#   1 - As refute_file_empty, after its report
#######################################
assert_file_not_empty() {
    refute_file_empty "$@"
}

#######################################
# bats-file's name for refute_file_contains. Same arguments, report and return value.
#
# Returns:
#   0 - As refute_file_contains
#   1 - As refute_file_contains, after its report
#######################################
assert_file_not_contains() {
    refute_file_contains "$@"
}

#######################################
# bats-file's name for refute_file_permission. Same arguments, report and return value.
#
# Returns:
#   0 - As refute_file_permission
#   1 - As refute_file_permission, after its report
#######################################
assert_not_file_permission() {
    refute_file_permission "$@"
}

#######################################
# bats-file's name for refute_file_executable. Same arguments, report and return value.
#
# Returns:
#   0 - As refute_file_executable
#   1 - As refute_file_executable, after its report
#######################################
assert_file_not_executable() {
    refute_file_executable "$@"
}

#######################################
# bats-file's name for refute_files_equal. Same arguments, report and return value.
#
# Returns:
#   0 - As refute_files_equal
#   1 - As refute_files_equal, after its report
#######################################
assert_files_not_equal() {
    refute_files_equal "$@"
}

#######################################
# bats-file's name for refute_symlink_to. Same arguments, report and return value.
#
# Returns:
#   0 - As refute_symlink_to
#   1 - As refute_symlink_to, after its report
#######################################
assert_not_symlink_to() {
    refute_symlink_to "$@"
}

# ------------------------------------------------------------------------------
# Internal
# ------------------------------------------------------------------------------

#######################################
# Parses `[-e|--regexp] PATH EXPECTED` into the caller's `mode` (text or
# regexp) and `rest`.
#
# Arguments:
#   $1 (String) - The calling assertion
#   $@          - The assertion's arguments
# Returns:
#   0 - Parsed
#   1 - After a usage error report
#######################################
expect::file::parse_contains() {
    local caller="$1"
    shift
    mode=text rest=()
    while (( $# > 0 )); do
        case "$1" in
            -e|--regexp) mode=regexp; shift ;;
            --) shift; break ;;
            *) break ;;
        esac
    done
    if (( $# < 2 )); then
        expect::report::error "$caller" 'expects a path and the expected content'
        return 1
    fi
    rest=("$@")
}

#######################################
# Lists the entries of a directory, dotfiles included.
#
# Arguments:
#   $1 (String) - The directory
# Outputs:
#   One entry name per line, or nothing for an empty directory
#######################################
expect::file::entries() {
    local entry
    for entry in "$1"/* "$1"/.[!.]* "$1"/..?*; do
        [[ -e "$entry" || -L "$entry" ]] && printf '%s\n' "${entry##*/}"
    done
    return 0
}

#######################################
# Prints the octal mode of a path as the platform's stat reports it.
#
# Arguments:
#   $1 (String) - The path
# Outputs:
#   The mode, such as 644 or 4755
#######################################
expect::file::mode() {
    if [[ "$OSTYPE" == darwin* ]]; then
        stat -f '%OLp' -- "$1" # LCOV_EXCL_LINE: coverage runs on Linux
    else
        stat -c '%a' -- "$1"
    fi
}

#######################################
# Strips leading zeros from a mode, so 0644 and 644 compare equal.
#
# Arguments:
#   $1 (String) - The mode
# Outputs:
#   The mode without leading zeros
#######################################
expect::file::normalize_mode() {
    local mode="$1"
    while [[ "$mode" == 0?* ]]; do mode="${mode#0}"; done
    printf '%s\n' "$mode"
}

#######################################
# Follows a chain of symbolic links to its end and makes the directory part
# physical. Pure bash and readlink, so it works where `readlink -f` does not
# exist, macOS among them.
#
# Arguments:
#   $1 (String) - The path
# Outputs:
#   The resolved path
#######################################
expect::file::resolve() {
    local path="$1" target dir
    local -i hops=0
    while [[ -L "$path" ]] && (( hops++ < 40 )); do
        target="$(readlink -- "$path")"
        if [[ "$target" == /* ]]; then
            path="$target"
        else
            path="$(dirname -- "$path")/$target"
        fi
    done
    dir="$(cd -- "$(dirname -- "$path")" 2>/dev/null && pwd -P)" || { printf '%s\n' "$path"; return 0; }
    printf '%s/%s\n' "$dir" "$(basename -- "$path")"
}
