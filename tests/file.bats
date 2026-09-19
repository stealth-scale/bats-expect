#!/usr/bin/env bats

# shellcheck disable=SC2034,SC2154,SC2030,SC2031
# Variables here are read by name through the library or set by `capture`, and
# every @test is its own process, not a subshell of the file.

# ==============================================================================
# bats-expect: file - Test Suite
# ==============================================================================
#   01. assert_exists, refute_exists
#   02. assert_file_exists, refute_file_exists, assert_dir_exists, refute_dir_exists
#   03. assert_link_exists, refute_link_exists
#   04. assert_file_empty, refute_file_empty, assert_dir_empty, refute_dir_empty
#   05. assert_file_contains, refute_file_contains
#   06. assert_file_permission, refute_file_permission
#   07. assert_file_executable, readable, writable and their refutes
#   08. assert_files_equal, refute_files_equal
#   09. assert_symlink_to, refute_symlink_to
#   10. The bats-file names
# ==============================================================================

load helper
setup() {
    common_setup
    d="$BATS_TEST_TMPDIR"
    printf 'hello\nworld\n' > "$d/f"
    : > "$d/e"
    mkdir "$d/dir" "$d/full"
    : > "$d/full/.hidden"
    ln -s "$d/f" "$d/l"
    ln -s "$d/missing" "$d/dangling"
    chmod 640 "$d/f"
}

# ==============================================================================
# GROUP 01: assert_exists, refute_exists
# ==============================================================================

@test "assert_exists: file, directory and dangling link -> pass" {
    assert_passes assert_exists "$d/f"
    assert_passes assert_exists "$d/dir"
    assert_passes assert_exists "$d/dangling"
}

@test "assert_exists: nothing there -> file or directory does not exist" {
    assert_fails -p '-- file or directory does not exist --' assert_exists "$d/nope"
    assert_fails -p "path : $d/nope" assert_exists "$d/nope"
}

@test "refute_exists: nothing there -> passes" {
    assert_passes refute_exists "$d/nope"
}

@test "refute_exists: something there -> exists, but it was expected to be absent" {
    assert_fails -p 'file or directory exists, but it was expected to be absent' refute_exists "$d/f"
    assert_fails -p 'expected to be absent' refute_exists "$d/dangling"
}

# ==============================================================================
# GROUP 02: files and directories
# ==============================================================================

@test "assert_file_exists: regular file -> passes" {
    assert_passes assert_file_exists "$d/f"
}

@test "assert_file_exists: directory or missing -> file does not exist" {
    assert_fails -p '-- file does not exist --' assert_file_exists "$d/dir"
    assert_fails -p '-- file does not exist --' assert_file_exists "$d/nope"
}

@test "refute_file_exists: missing or directory -> passes" {
    assert_passes refute_file_exists "$d/nope"
    assert_passes refute_file_exists "$d/dir"
}

@test "refute_file_exists: regular file -> file exists, but it was expected to be absent" {
    assert_fails -p 'file exists, but it was expected to be absent' refute_file_exists "$d/f"
}

@test "assert_dir_exists: directory -> passes" {
    assert_passes assert_dir_exists "$d/dir"
}

@test "assert_dir_exists: file or missing -> directory does not exist" {
    assert_fails -p '-- directory does not exist --' assert_dir_exists "$d/f"
}

@test "refute_dir_exists: file or missing -> passes" {
    assert_passes refute_dir_exists "$d/f"
}

@test "refute_dir_exists: directory -> directory exists, but it was expected to be absent" {
    assert_fails -p 'directory exists, but it was expected to be absent' refute_dir_exists "$d/dir"
}

# ==============================================================================
# GROUP 03: assert_link_exists, refute_link_exists
# ==============================================================================

@test "assert_link_exists: link, dangling included -> passes" {
    assert_passes assert_link_exists "$d/l"
    assert_passes assert_link_exists "$d/dangling"
}

@test "assert_link_exists: regular file -> symbolic link does not exist" {
    assert_fails -p '-- symbolic link does not exist --' assert_link_exists "$d/f"
}

@test "refute_link_exists: regular file -> passes" {
    assert_passes refute_link_exists "$d/f"
}

@test "refute_link_exists: link -> symbolic link exists, but it was expected to be absent" {
    assert_fails -p 'symbolic link exists, but it was expected to be absent' refute_link_exists "$d/l"
}

# ==============================================================================
# GROUP 04: emptiness
# ==============================================================================

@test "assert_file_empty: empty file -> passes" {
    assert_passes assert_file_empty "$d/e"
}

@test "assert_file_empty: file with content -> file is not empty, shows the content" {
    assert_fails -p '-- file is not empty --' assert_file_empty "$d/f"
    assert_fails -p 'content (2 lines):' assert_file_empty "$d/f"
}

@test "assert_file_empty: missing file -> file does not exist" {
    assert_fails -p 'file does not exist' assert_file_empty "$d/nope"
}

@test "refute_file_empty: file with content -> passes" {
    assert_passes refute_file_empty "$d/f"
}

@test "refute_file_empty: empty file -> file is empty" {
    assert_fails -p '-- file is empty --' refute_file_empty "$d/e"
}

@test "assert_dir_empty: empty directory -> passes" {
    assert_passes assert_dir_empty "$d/dir"
}

@test "assert_dir_empty: directory with a dotfile -> directory is not empty, lists it" {
    assert_fails -p '-- directory is not empty --' assert_dir_empty "$d/full"
    assert_fails -p '.hidden' assert_dir_empty "$d/full"
}

@test "refute_dir_empty: directory with entries -> passes" {
    assert_passes refute_dir_empty "$d/full"
}

@test "refute_dir_empty: empty directory -> directory is empty" {
    assert_fails -p '-- directory is empty --' refute_dir_empty "$d/dir"
}

# ==============================================================================
# GROUP 05: assert_file_contains, refute_file_contains
# ==============================================================================

@test "assert_file_contains: text present -> passes" {
    assert_passes assert_file_contains "$d/f" ell
    assert_passes assert_file_contains "$d/f" world
}

@test "assert_file_contains: text is literal -> a regex metacharacter is a character" {
    assert_fails -p 'file does not contain text' assert_file_contains "$d/f" 'h.llo'
}

@test "assert_file_contains: text absent -> file does not contain text" {
    assert_fails -p '-- file does not contain text --' assert_file_contains "$d/f" bye
    assert_fails -p 'text : bye' assert_file_contains "$d/f" bye
}

@test "assert_file_contains: --regexp -> extended regular expression per line" {
    assert_passes assert_file_contains --regexp "$d/f" '^h.llo$'
    assert_passes assert_file_contains -e "$d/f" 'wor?ld'
    assert_fails -p 'file does not contain regular expression' assert_file_contains -e "$d/f" '^world hello$'
}

@test "assert_file_contains: invalid regexp -> usage error" {
    assert_fails -p '-- ERROR: assert_file_contains --' assert_file_contains -e "$d/f" '('
}

@test "assert_file_contains: missing arguments -> usage error" {
    assert_fails -p '-- ERROR: assert_file_contains --' assert_file_contains "$d/f"
}

@test "assert_file_contains: missing file -> file does not exist" {
    assert_fails -p 'file does not exist' assert_file_contains "$d/nope" x
}

@test "refute_file_contains: text absent -> passes" {
    assert_passes refute_file_contains "$d/f" bye
}

@test "refute_file_contains: text present -> file contains text, with the matching line" {
    assert_fails -p '-- file contains text --' refute_file_contains "$d/f" world
    assert_fails -p 'match : 2:world' refute_file_contains "$d/f" world
}

@test "refute_file_contains: --regexp matched -> file contains regular expression" {
    assert_fails -p '-- file contains regular expression --' refute_file_contains -e "$d/f" '^w'
}

# ==============================================================================
# GROUP 06: assert_file_permission, refute_file_permission
# ==============================================================================

@test "assert_file_permission: matching mode -> passes with or without a leading zero" {
    assert_passes assert_file_permission 640 "$d/f"
    assert_passes assert_file_permission 0640 "$d/f"
}

@test "assert_file_permission: other mode -> file does not have the permission, expected and actual" {
    assert_fails -p '-- file does not have the permission --' assert_file_permission 600 "$d/f"
    assert_fails -p 'expected : 600' assert_file_permission 600 "$d/f"
    assert_fails -p 'actual   : 640' assert_file_permission 600 "$d/f"
}

@test "assert_file_permission: missing path -> file or directory does not exist" {
    assert_fails -p 'file or directory does not exist' assert_file_permission 644 "$d/nope"
}

@test "refute_file_permission: other mode -> passes" {
    assert_passes refute_file_permission 600 "$d/f"
}

@test "refute_file_permission: matching mode -> file has the permission, but it was expected not to" {
    assert_fails -p 'file has the permission, but it was expected not to' refute_file_permission 640 "$d/f"
}

# ==============================================================================
# GROUP 07: executable, readable, writable
# ==============================================================================

@test "assert_file_executable: executable -> passes; not -> file is not executable" {
    chmod 750 "$d/f"
    assert_passes assert_file_executable "$d/f"
    assert_fails -p '-- file is not executable --' assert_file_executable "$d/e"
    assert_fails -p 'permission : 644' assert_file_executable "$d/e"
}

@test "refute_file_executable: not executable -> passes; executable -> file is executable" {
    assert_passes refute_file_executable "$d/e"
    chmod 750 "$d/f"
    assert_fails -p '-- file is executable --' refute_file_executable "$d/f"
}

@test "assert_file_readable: readable -> passes" {
    assert_passes assert_file_readable "$d/f"
}

@test "assert_file_readable: unreadable -> file is not readable" {
    (( EUID == 0 )) && skip 'root reads everything'
    chmod 000 "$d/e"
    assert_fails -p '-- file is not readable --' assert_file_readable "$d/e"
}

@test "refute_file_readable: readable -> file is readable" {
    assert_fails -p '-- file is readable --' refute_file_readable "$d/f"
}

@test "assert_file_writable: writable -> passes" {
    assert_passes assert_file_writable "$d/f"
}

@test "assert_file_writable: read-only -> file is not writable" {
    (( EUID == 0 )) && skip 'root writes everything'
    chmod 400 "$d/e"
    assert_fails -p '-- file is not writable --' assert_file_writable "$d/e"
}

@test "refute_file_writable: writable -> file is writable" {
    assert_fails -p '-- file is writable --' refute_file_writable "$d/f"
}

# ==============================================================================
# GROUP 08: assert_files_equal, refute_files_equal
# ==============================================================================

@test "assert_files_equal: same content -> passes" {
    cp "$d/f" "$d/g"
    assert_passes assert_files_equal "$d/f" "$d/g"
}

@test "assert_files_equal: different content -> files are not the same, with cmp's difference" {
    assert_fails -p '-- files are not the same --' assert_files_equal "$d/f" "$d/e"
    assert_fails -p 'difference' assert_files_equal "$d/f" "$d/e"
}

@test "assert_files_equal: missing file -> file does not exist" {
    assert_fails -p 'file does not exist' assert_files_equal "$d/f" "$d/nope"
}

@test "refute_files_equal: different content -> passes" {
    assert_passes refute_files_equal "$d/f" "$d/e"
}

@test "refute_files_equal: same content -> files are the same, but they were expected to differ" {
    cp "$d/f" "$d/g"
    assert_fails -p 'files are the same, but they were expected to differ' refute_files_equal "$d/f" "$d/g"
}

# ==============================================================================
# GROUP 09: assert_symlink_to, refute_symlink_to
# ==============================================================================

@test "assert_symlink_to: link to the target -> passes" {
    assert_passes assert_symlink_to "$d/f" "$d/l"
}

@test "assert_symlink_to: relative link target -> resolved and passes" {
    ln -s f "$d/rel"
    assert_passes assert_symlink_to "$d/f" "$d/rel"
}

@test "assert_symlink_to: other target -> symbolic link does not have the correct target, with the actual" {
    assert_fails -p 'symbolic link does not have the correct target' assert_symlink_to "$d/e" "$d/l"
    assert_fails -p "actual   : $d/f" assert_symlink_to "$d/e" "$d/l"
}

@test "assert_symlink_to: not a link -> symbolic link does not exist" {
    assert_fails -p 'symbolic link does not exist' assert_symlink_to "$d/f" "$d/e"
}

@test "refute_symlink_to: other target -> passes" {
    assert_passes refute_symlink_to "$d/e" "$d/l"
}

@test "refute_symlink_to: the target -> symbolic link has the target, but it was expected not to" {
    assert_fails -p 'symbolic link has the target, but it was expected not to' refute_symlink_to "$d/f" "$d/l"
}

# ==============================================================================
# GROUP 10: The bats-file names
# ==============================================================================

@test "assert_not_exists: -> refute_exists" {
    assert_passes assert_not_exists "$d/nope"
    assert_fails -p 'expected to be absent' assert_not_exists "$d/f"
}

@test "assert_file_not_exists: -> refute_file_exists" {
    assert_passes assert_file_not_exists "$d/nope"
    assert_fails -p 'file exists' assert_file_not_exists "$d/f"
}

@test "assert_dir_not_exists: -> refute_dir_exists" {
    assert_passes assert_dir_not_exists "$d/f"
    assert_fails -p 'directory exists' assert_dir_not_exists "$d/dir"
}

@test "assert_link_not_exists: -> refute_link_exists" {
    assert_passes assert_link_not_exists "$d/f"
    assert_fails -p 'symbolic link exists' assert_link_not_exists "$d/l"
}

@test "assert_file_not_empty: -> refute_file_empty" {
    assert_passes assert_file_not_empty "$d/f"
    assert_fails -p 'file is empty' assert_file_not_empty "$d/e"
}

@test "assert_file_not_contains: -> refute_file_contains" {
    assert_passes assert_file_not_contains "$d/f" bye
    assert_fails -p 'file contains text' assert_file_not_contains "$d/f" hello
}

@test "assert_not_file_permission: -> refute_file_permission" {
    assert_passes assert_not_file_permission 600 "$d/f"
    assert_fails -p 'file has the permission' assert_not_file_permission 640 "$d/f"
}

@test "assert_file_not_executable: -> refute_file_executable" {
    assert_passes assert_file_not_executable "$d/e"
}

@test "assert_files_not_equal: -> refute_files_equal" {
    assert_passes assert_files_not_equal "$d/f" "$d/e"
}

@test "assert_not_symlink_to: -> refute_symlink_to" {
    assert_passes assert_not_symlink_to "$d/e" "$d/l"
    assert_fails -p 'symbolic link has the target' assert_not_symlink_to "$d/f" "$d/l"
}
