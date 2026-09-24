# Changelog

Every change a user would notice is recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] - 2026-09-24

### Fixed

- A report that prints an empty value as a block prints the empty line bats-support prints
  under `name (0 lines):`, so `assert_output ''` against a multi-line output matches
  bats-assert's report byte for byte.
- `assert_array_has_key` and `refute_array_has_key` compare the key as text with the keys of
  the array. The key was a subscript: an index such as `1+1` was evaluated as arithmetic,
  and on bash 4.4 a command substitution in the key ran.
- `assert_json_has_key` and `refute_json_has_key` report a jq path jq rejects as a usage
  error. `refute_json_has_key` passed on such a path, and `assert_json_has_key` reported it
  as an absent value.
- `assert_within_delta` takes the difference to 15 significant digits. It rounded to six, so
  `assert_within_delta 1234567 0 1234567` failed.
- `assert_var_equal` joins the elements of an array with spaces under any `IFS`.

## [1.0.0] - 2026-09-19

First tagged release.

### Added

- The bats-assert assertions, with the same names, options and byte-identical reports:
  `assert`, `refute`, `assert_success`, `assert_failure`, `assert_output`, `refute_output`,
  `assert_line`, `refute_line`, `assert_stderr`, `refute_stderr`, `assert_stderr_line`,
  `refute_stderr_line`, `assert_equal`, `assert_not_equal`, `assert_regex`, `refute_regex`.
- Value assertions: `refute_equal`, `assert_empty`, `refute_empty`, `assert_contains`,
  `refute_contains`, `assert_starts_with`, `refute_starts_with`, `assert_ends_with`,
  `refute_ends_with`, `assert_one_of`, `refute_one_of`, `assert_line_count`.
- Variable assertions by name: `assert_var_set`, `refute_var_set`, `assert_var_empty`,
  `refute_var_empty`, `assert_var_equal`, `refute_var_equal`, `assert_declared`,
  `refute_declared`.
- Type assertions: `assert_is_int`, `assert_is_number`, `assert_is_bool`, `assert_is_regex`,
  `assert_is_identifier`, and their refutes.
- Number assertions: `assert_gt`, `assert_ge`, `assert_lt`, `assert_le`, `assert_between`,
  `refute_between`, `assert_within_delta`.
- Array assertions by name: `assert_array_contains`, `refute_array_contains`,
  `assert_array_equal`, `refute_array_equal`, `assert_array_length`, `assert_array_empty`,
  `refute_array_empty`, `assert_array_has_key`, `refute_array_has_key`.
- File assertions with bats-file's names and argument order, each with a `refute_` twin:
  existence by type, emptiness, `assert_file_contains` with literal text or `--regexp`,
  permission, executable, readable, writable, `assert_files_equal`, `assert_symlink_to`.
- Nameref support: `run_nameref`, `assert_nameref`, `refute_nameref`.
- JSON assertions through jq: `assert_json_valid`, `assert_json_equal`,
  `assert_json_has_key`, `assert_json_length`, and their refutes, with `--file`.
- Meta assertions: `assert_passes` and `assert_fails`.
- A `fail` polyfill, so the library loads without bats-support.
- Reports that survive a broken `PATH`: the report layer uses no external command.
- A test suite of 340 cases.

[Unreleased]: https://github.com/stealth-scale/bats-expect/compare/v1.0.1...main
[1.0.1]: https://github.com/stealth-scale/bats-expect/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/stealth-scale/bats-expect/releases/tag/v1.0.0
