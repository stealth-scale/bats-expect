# bats-expect

One assertion library for [bats-core](https://github.com/bats-core/bats-core). It contains
bats-assert, name for name and report for report, the file assertions of bats-file, and
assertions on values, variables, types, numbers, arrays, namerefs and JSON that neither
has. One `load`, and no other library is needed.

```bash
load 'helpers/bats-expect/load'

@test "release notes are generated" {
    run make notes VERSION=1.2.0
    assert_success
    assert_line --index 0 'notes: 1.2.0'
    assert_file_exists build/notes.md
    assert_file_contains build/notes.md '## 1.2.0'
    assert_json_equal --file build/meta.json .version 1.2.0
}
```

## Install

```sh
git submodule add https://github.com/stealth-scale/bats-expect tests/helpers/bats-expect
```

```bash
load 'helpers/bats-expect/load'
```

`load.bash` is the entry point, so `bats_load_library bats-expect` works as well when the
repository is on `BATS_LIB_PATH`. `make install` copies the library to
`/usr/local/lib/bats-expect`.

Requirements: Bash 4.4 or later and bats-core 1.5.0 or later. jq is needed for the JSON
assertions only. The test suite runs on bash 4.4 to 5.3 with bats-core 1.7.0 and 1.14.0.

## Coming from bats-assert or bats-file

Replace the `load` lines. Every bats-assert function is here with the same name, options
and failure report, byte for byte: `assert`, `refute`, `assert_success`, `assert_failure`,
`assert_output`, `refute_output`, `assert_line`, `refute_line`, `assert_stderr`,
`refute_stderr`, `assert_stderr_line`, `refute_stderr_line`, `assert_equal`,
`assert_not_equal`, `assert_regex`, `refute_regex`. One difference in behaviour: on an
empty output, `assert_line` reports a failure and `refute_line` passes, where bats-assert
stops both with `lines: parameter not set`.

The common bats-file assertions are here under their bats-file names, arguments in the same
order. The differences:

- `assert_file_contains PATH TEXT` and `assert_file_not_contains` match text. bats-file
  matches a basic regular expression. Pass `--regexp` for an extended one.
- `assert_file_owner`, `assert_not_file_owner`, `assert_file_size_equals`,
  `assert_size_zero`, `assert_size_not_zero`, the setuid, setgid and sticky-bit checks, and
  the block, character, socket and fifo checks are not included.

When bats-support is loaded, its `fail` is used. Otherwise a polyfill with the same contract
is defined, so nothing else has to be loaded first.

## Conventions

- `assert_X` fails when X does not hold. `refute_X` fails when it does. Every assertion has
  its twin, except `assert_success`, `assert_failure` and the comparisons, whose opposite is
  another assertion.
- The subject comes first, the expectation after it: `assert_contains "$value" needle`.
- A missing argument is read as an empty string, so `set -u` never trips.
- `--partial` and `--regexp` mean the same wherever they appear. `--` ends the options.
- A wrong call, such as an invalid regular expression or a name that is not an array, is
  reported under `-- ERROR: <assertion> --` and is never a passed assertion.
- No argument is evaluated. Every argument is a value.

A failure prints the report bats-assert users know:

```
-- values do not equal --
expected : 1.2.0
actual   : 1.2.0-rc1
--
```

A value that spans lines is printed as a block with its line count. `refute_line` marks the
offending line with `>`.

## Reference

### run

Assertions on the last `run`. `run --separate-stderr` fills `$stderr` for the stderr forms.

| Assertion | Fails when |
| --- | --- |
| `assert_success` | `$status` is not 0 |
| `assert_failure [STATUS]` | `$status` is 0, or differs from `STATUS` |
| `assert_output [-p\|-e] [-\|EXPECTED]` | `$output` does not equal, contain, or match `EXPECTED`; with no argument, is empty |
| `refute_output [-p\|-e] [-\|UNEXPECTED]` | `$output` equals, contains, or matches; with no argument, is not empty |
| `assert_line [-n I] [-p\|-e] EXPECTED` | no line, or line `I`, equals, contains or matches |
| `refute_line [-n I] [-p\|-e] UNEXPECTED` | a line, or line `I`, equals, contains or matches |
| `assert_stderr`, `refute_stderr`, `assert_stderr_line`, `refute_stderr_line` | the same, on `$stderr` and `$stderr_lines` |
| `assert COMMAND...` | the command fails |
| `refute COMMAND...` | the command succeeds |

### value

| Assertion | Fails when |
| --- | --- |
| `assert_equal ACTUAL EXPECTED` | the values differ |
| `refute_equal ACTUAL UNEXPECTED`, `assert_not_equal` | the values are equal |
| `assert_regex VALUE REGEX`, `refute_regex` | the value does not match, or matches |
| `assert_empty VALUE`, `refute_empty` | the value is not empty, or is |
| `assert_contains VALUE TEXT`, `refute_contains` | the literal text is absent, or present |
| `assert_starts_with VALUE PREFIX`, `refute_starts_with` | the prefix is absent, or present |
| `assert_ends_with VALUE SUFFIX`, `refute_ends_with` | the suffix is absent, or present |
| `assert_one_of VALUE ITEM...`, `refute_one_of` | the value is none of the items, or one of them |
| `assert_line_count VALUE N` | the value does not have `N` lines |

### variable

By name, so unset and empty are told apart and attributes can be checked. A `local` of the
test is visible.

| Assertion | Fails when |
| --- | --- |
| `assert_var_set NAME`, `refute_var_set` | the variable is unset, or set. Declared without a value counts as unset |
| `assert_var_empty NAME`, `refute_var_empty` | the variable is unset or has a value, or is unset or empty |
| `assert_var_equal NAME VALUE`, `refute_var_equal` | the variable is unset or differs, or equals |
| `assert_declared [-a\|-A\|-f\|-i\|-n\|-r\|-x] NAME`, `refute_declared` | the name lacks the attribute, or has it. Without an option: is not declared, or is |

### type

| Assertion | Fails when |
| --- | --- |
| `assert_is_int VALUE`, `refute_is_int` | not, or is, an optional sign and digits |
| `assert_is_number VALUE`, `refute_is_number` | not, or is, a decimal number |
| `assert_is_bool VALUE`, `refute_is_bool` | not, or is, `true` or `false` |
| `assert_is_regex VALUE`, `refute_is_regex` | does not, or does, compile as an extended regular expression |
| `assert_is_identifier VALUE`, `refute_is_identifier` | not, or is, a shell identifier |

### number

Integers and decimals. awk compares, so `0.1` and `1.25` compare as numbers. A value that is
not a decimal number is a usage error.

| Assertion | Fails when |
| --- | --- |
| `assert_gt A B`, `assert_ge`, `assert_lt`, `assert_le` | the comparison does not hold |
| `assert_between VALUE MIN MAX`, `refute_between` | the value is outside, or inside, the inclusive range |
| `assert_within_delta ACTUAL EXPECTED DELTA` | the difference exceeds `DELTA` |

### array

By name. Indexed and associative arrays.

| Assertion | Fails when |
| --- | --- |
| `assert_array_contains NAME VALUE`, `refute_array_contains` | no element, or an element, equals the value |
| `assert_array_equal NAME VALUE...`, `refute_array_equal` | the elements, in order, differ from, or equal, the values |
| `assert_array_length NAME N` | the array does not have `N` elements |
| `assert_array_empty NAME`, `refute_array_empty` | the array has elements, or none |
| `assert_array_has_key NAME KEY`, `refute_array_has_key` | the key is absent, or present. The key is compared as text, never evaluated: an index in decimal for an indexed array |

### file

| Assertion | Fails when |
| --- | --- |
| `assert_exists PATH`, `refute_exists` | nothing, or something, is at the path. A dangling link exists |
| `assert_file_exists PATH`, `refute_file_exists` | not, or is, a regular file |
| `assert_dir_exists PATH`, `refute_dir_exists` | not, or is, a directory |
| `assert_link_exists PATH`, `refute_link_exists` | not, or is, a symbolic link |
| `assert_file_empty PATH`, `refute_file_empty` | the file has content, or none |
| `assert_dir_empty PATH`, `refute_dir_empty` | the directory has entries, or none. Dotfiles count |
| `assert_file_contains [-e] PATH TEXT`, `refute_file_contains` | the text, or with `-e` the regular expression, is absent, or present |
| `assert_file_permission MODE PATH`, `refute_file_permission` | the mode differs, or matches. `644` and `0644` are the same |
| `assert_file_executable PATH`, `_readable`, `_writable`, and their refutes | the caller lacks, or has, the permission |
| `assert_files_equal A B`, `refute_files_equal` | the files differ, or are the same |
| `assert_symlink_to TARGET LINK`, `refute_symlink_to` | the link does not resolve to the target, or does |

bats-file names kept: `assert_not_exists`, `assert_file_not_exists`, `assert_dir_not_exists`,
`assert_link_not_exists`, `assert_file_not_empty`, `assert_file_not_contains`,
`assert_not_file_permission`, `assert_file_not_executable`, `assert_files_not_equal`,
`assert_not_symlink_to`.

### nameref

For functions that return through a nameref, `f out_var args...`, the common shape in a
bash library.

| Function | What it does |
| --- | --- |
| `run_nameref FUNC ARGS...` | Calls `FUNC` with a fresh output variable first. Fills `$status`, `$output` and `$lines` as `run` does, in the current shell. An array joins with newlines |
| `assert_nameref EXPECTED FUNC ARGS...` | Fails when the function returns non-zero or another value |
| `refute_nameref UNEXPECTED FUNC ARGS...` | Fails when the function returns 0 and that value |

### json

Through jq. `JSON` is the document as a string. `--file PATH` reads it from a file. Values are
compared as `jq -r` prints them: strings and numbers bare, objects and arrays compact.

| Assertion | Fails when |
| --- | --- |
| `assert_json_valid [--file] JSON`, `refute_json_valid` | the document is invalid, or valid |
| `assert_json_equal [--file] JSON PATH EXPECTED`, `refute_json_equal` | the value at the jq path differs, or equals |
| `assert_json_has_key [--file] JSON PATH`, `refute_json_has_key` | the path is null or absent, or present |
| `assert_json_length [--file] JSON PATH N` | the array, object or string at the path does not have length `N` |

### meta

For testing assertions, this library's or your own.

| Assertion | Fails when |
| --- | --- |
| `assert_passes ASSERTION ARGS...` | the assertion fails. Its report is included |
| `assert_fails [-p TEXT] [-e REGEX] ASSERTION ARGS...` | the assertion passes, or its report lacks the text or does not match |

## Working here

```sh
make test                                   # the suite in the bats-test image: bash 5.2, bats 1.14.0
make test BASH_VERSION=4.4 BATS_VERSION=1.7.0
make test-host                              # the suite with the bash and bats of this machine
make coverage                               # the suite under kcov: a table per file, report in coverage/; fails under 100%
make lint                                   # shellcheck over the loader, the sources and the tests
make check                                  # what CI runs: lint, then test
```

`RUNTIME=docker` selects Docker. The default is Podman. `TARGET` selects one test file.

[CONTRIBUTING.md](CONTRIBUTING.md) has the rest.

## License

[MIT](LICENSE). Copyright Stealth Scale B.V.
