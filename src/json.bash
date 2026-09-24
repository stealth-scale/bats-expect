#
# bats-expect: json
#
# Assertions on JSON through jq. The JSON is a string; `--file` takes a path
# instead. A missing jq, invalid JSON or a bad jq path is a usage error, not a
# failed expectation.
#
#   assert_json_valid "$output"
#   assert_json_equal "$output" .status ok
#   assert_json_equal --file config.json .port 8080
#   assert_json_has_key "$output" .items[0].id
#   assert_json_length "$output" .items 3

#######################################
# Fails when the input is not valid JSON. `null`, `false` and numbers are
# valid documents.
#
# Usage: assert_json_valid [--file] JSON
#
# Arguments:
#   --file        JSON is a path to read instead of the document itself
#   JSON (String) - The document, or the path
# Returns:
#   0 - Valid
#   1 - Otherwise, after the report, or after a usage error
#######################################
assert_json_valid() {
    local json; local -a rest
    expect::json::input assert_json_valid "$@" || return 1
    local error
    if ! error="$(printf '%s' "$json" | jq . 2>&1 >/dev/null)"; then
        expect::report::fail 'value is not valid JSON' 'error' "${error:-jq rejected the input}" 'value' "$json"
    fi
}

#######################################
# Fails when the input is valid JSON.
#
# Usage: refute_json_valid [--file] JSON
#
# Arguments:
#   --file        JSON is a path to read instead of the document itself
#   JSON (String) - The document, or the path
# Returns:
#   0 - Invalid
#   1 - Otherwise, after the report, or after a usage error
#######################################
refute_json_valid() {
    local json; local -a rest
    expect::json::input refute_json_valid "$@" || return 1
    if printf '%s' "$json" | jq . >/dev/null 2>&1; then
        expect::report::fail 'value is valid JSON, but it was expected not to be' 'value' "$json"
    fi
}

#######################################
# Fails when the value at the jq path differs from the expectation. The value
# is compared as text, as `jq -r` prints it: numbers, booleans and strings
# without quotes, objects and arrays as compact JSON, a missing path as null.
#
# Usage: assert_json_equal [--file] JSON PATH EXPECTED
#
# Arguments:
#   --file            JSON is a path to read instead of the document itself
#   JSON (String)     - The document, or the path
#   PATH (String)     - A jq filter, such as .items[0].name
#   EXPECTED (String) - The expected text
# Returns:
#   0 - Equal
#   1 - Otherwise, after the report, or after a usage error
#######################################
assert_json_equal() {
    local json; local -a rest
    expect::json::input assert_json_equal "$@" || return 1
    local path="${rest[0]-}" expected="${rest[1]-}" actual
    actual="$(expect::json::get assert_json_equal "$json" "$path")" || return 1
    if [[ "$actual" != "$expected" ]]; then
        expect::report::fail 'JSON value differs' 'path' "$path" 'expected' "$expected" 'actual' "$actual"
    fi
}

#######################################
# Fails when the value at the jq path equals the given text.
#
# Usage: refute_json_equal [--file] JSON PATH UNEXPECTED
#
# Arguments:
#   --file              JSON is a path to read instead of the document itself
#   JSON (String)       - The document, or the path
#   PATH (String)       - A jq filter
#   UNEXPECTED (String) - The text the value must not equal
# Returns:
#   0 - Different
#   1 - Otherwise, after the report, or after a usage error
#######################################
refute_json_equal() {
    local json; local -a rest
    expect::json::input refute_json_equal "$@" || return 1
    local path="${rest[0]-}" unexpected="${rest[1]-}" actual
    actual="$(expect::json::get refute_json_equal "$json" "$path")" || return 1
    if [[ "$actual" == "$unexpected" ]]; then
        expect::report::fail 'JSON value equals, but it was expected to differ' 'path' "$path" 'value' "$actual"
    fi
}

#######################################
# Fails when the jq path is absent or null.
#
# Usage: assert_json_has_key [--file] JSON PATH
#
# Arguments:
#   --file        JSON is a path to read instead of the document itself
#   JSON (String) - The document, or the path
#   PATH (String) - A jq filter
# Returns:
#   0 - Present and not null
#   1 - Otherwise, after the report, or after a usage error
#######################################
assert_json_has_key() {
    local json; local -a rest
    expect::json::input assert_json_has_key "$@" || return 1
    local path="${rest[0]-}"
    local -i result=0
    expect::json::has_value assert_json_has_key "$json" "$path" || result=$?
    case "$result" in
        1) expect::report::fail 'JSON has no value at path' 'path' "$path" 'json' "$json" ;;
        2) return 1 ;;
    esac
}

#######################################
# Fails when the jq path is present and not null.
#
# Usage: refute_json_has_key [--file] JSON PATH
#
# Arguments:
#   --file        JSON is a path to read instead of the document itself
#   JSON (String) - The document, or the path
#   PATH (String) - A jq filter
# Returns:
#   0 - Absent or null
#   1 - Otherwise, after the report, or after a usage error
#######################################
refute_json_has_key() {
    local json; local -a rest
    expect::json::input refute_json_has_key "$@" || return 1
    local path="${rest[0]-}"
    local -i result=0
    expect::json::has_value refute_json_has_key "$json" "$path" || result=$?
    case "$result" in
        0) expect::report::fail 'JSON has a value at path, but it was expected not to' 'path' "$path" \
               'value' "$(printf '%s' "$json" | jq -rc "$path")" ;;
        2) return 1 ;;
    esac
}

#######################################
# Fails when the array, object or string at the jq path does not have the
# length.
#
# Usage: assert_json_length [--file] JSON PATH LENGTH
#
# Arguments:
#   --file           JSON is a path to read instead of the document itself
#   JSON (String)    - The document, or the path
#   PATH (String)    - A jq filter
#   LENGTH (Integer) - The expected length
# Returns:
#   0 - The lengths match
#   1 - Otherwise, after the report, or after a usage error
#######################################
assert_json_length() {
    local json; local -a rest
    expect::json::input assert_json_length "$@" || return 1
    local path="${rest[0]-}" expected="${rest[1]-}" actual
    if [[ ! "$expected" =~ ^[0-9]+$ ]]; then
        expect::report::error assert_json_length "expected length must be an integer: \`$expected'"
        return 1
    fi
    actual="$(expect::json::get assert_json_length "$json" "$path | length")" || return 1
    if [[ "$actual" != "$expected" ]]; then
        expect::report::fail 'JSON length differs' 'path' "$path" 'expected' "$expected" 'actual' "$actual"
    fi
}

# ------------------------------------------------------------------------------
# Internal
# ------------------------------------------------------------------------------

#######################################
# Reads `[--file] JSON` into the caller's `json`, and the arguments after it
# into `rest`. Requires jq.
#
# Arguments:
#   $1 (String) - The calling assertion
#   $@          - The assertion's arguments
# Returns:
#   0 - Read
#   1 - After a usage error report: no jq, or a missing file
#######################################
expect::json::input() {
    local caller="$1"
    shift
    if ! command -v jq >/dev/null 2>&1; then
        expect::report::error "$caller" 'jq is required for the JSON assertions'
        return 1
    fi
    rest=()
    if [[ "${1-}" == --file ]]; then
        shift
        if [[ ! -f "${1-}" ]]; then
            expect::report::error "$caller" "file does not exist: \`${1-}'"
            return 1
        fi
        json="$(cat -- "$1")"
    else
        json="${1-}"
    fi
    (( $# > 0 )) && shift
    rest=("$@")
}

#######################################
# Fails with a usage error when the document is not valid JSON.
#
# Arguments:
#   $1 (String) - The calling assertion
#   $2 (String) - The document
# Returns:
#   0 - Valid
#   1 - After the error report
#######################################
expect::json::require_valid() {
    local caller="$1" json="$2" error
    if ! error="$(printf '%s' "$json" | jq . 2>&1 >/dev/null)"; then
        expect::report::error "$caller" "input is not valid JSON: ${error:-jq rejected the input}"
        return 1
    fi
}

#######################################
# Tells whether the jq path has a value other than null. jq -e exits 1 for a
# last output of null or false, 4 for no output, and 2 or more for an error,
# which is a usage error here rather than an absent value.
#
# Arguments:
#   $1 (String) - The calling assertion
#   $2 (String) - The document
#   $3 (String) - The jq filter
# Returns:
#   0 - A value other than null
#   1 - Absent or null
#   2 - After a usage error report: invalid document or filter
#######################################
expect::json::has_value() {
    local caller="$1" json="$2" path="$3" error
    expect::json::require_valid "$caller" "$json" || return 2
    local -i result=0
    error="$(printf '%s' "$json" | jq -e "$path != null" 2>&1 >/dev/null)" || result=$?
    case "$result" in
        0) return 0 ;;
        1|4) return 1 ;;
    esac
    expect::report::error "$caller" "jq rejected the path \`$path': $error"
    return 2
}

#######################################
# Prints the value at a jq path as text, as `jq -rc` does.
#
# Arguments:
#   $1 (String) - The calling assertion
#   $2 (String) - The document
#   $3 (String) - The jq filter
# Outputs:
#   The value
# Returns:
#   0 - Printed
#   1 - After a usage error report: invalid document or filter
#######################################
expect::json::get() {
    local caller="$1" json="$2" path="$3" value
    expect::json::require_valid "$caller" "$json" || return 1
    if ! value="$(printf '%s' "$json" | jq -rc "$path" 2>&1)"; then
        expect::report::error "$caller" "jq rejected the path \`$path': $value"
        return 1
    fi
    printf '%s\n' "$value"
}
