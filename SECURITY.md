# Security policy

## Supported versions

The latest tagged version is supported.

## Reporting a vulnerability

Report a vulnerability through GitHub's private vulnerability reporting on this repository,
under its Security tab. Do not open a public issue. We acknowledge a report within three
working days and publish a fix before any disclosure.

## Evaluation of arguments

No assertion evaluates its arguments. Values are compared as strings, names are validated
as identifiers before `declare -p` or a nameref reads them, `assert` and `refute` execute
their arguments as a command without `eval`, and jq filters are passed to jq as arguments.
The tests in `tests/run.bats` and `tests/variable.bats` check these properties.
