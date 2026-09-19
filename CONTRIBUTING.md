# Contributing

## Getting set up

You need GNU make, [ShellCheck](https://www.shellcheck.net) and Podman or Docker.
`make test` pulls `ghcr.io/stealth-scale/bats-test`, the image of the
[bats-test](https://github.com/stealth-scale/bats-test) repository, at the bash and bats-core
versions it is given. For `make test-host`, install Bash 4.4 or later,
[bats-core](https://github.com/bats-core/bats-core) 1.7.0 or later, and jq.

```sh
git clone git@github.com:stealth-scale/bats-expect.git
cd bats-expect
make check
```

## Before you open a pull request

```sh
make lint       # shellcheck over the loader, the sources and the tests
make test       # the suite in the bats-test image; BASH_VERSION and BATS_VERSION pick the cell
make test-host  # the suite with the bash and bats of this machine
make coverage   # the suite under kcov: a table per file, report in coverage/
make check      # what CI runs: lint, then test
```

`RUNTIME=docker` selects Docker. The default is Podman. `TARGET` selects one test file.

CI runs `make lint`, `make test` for bash 4.4, 5.1, 5.2 and 5.3 against bats-core 1.7.0 and
1.14.0, and `make test-host` on Ubuntu and macOS with both bats-core versions.

## Adding an assertion

- Put it in the `src/` file of its domain, or start a new file and add it to `load.bash`.
- Name it `assert_<subject>_<predicate>` and give it a `refute_` twin unless its opposite is
  another assertion.
- Take the subject first and the expectation after it. Read missing arguments as `${1-}`, so
  `set -u` never trips.
- Report through `expect::report::fail`, or through `expect::report::rows`,
  `expect::report::pairs` and `expect::report::blocks` under `expect::report::fail_body` when
  the report mixes rows and a block. Report a wrong call through `expect::report::error`.
- Write the docblock every function here has: summary, `Arguments`, `Returns`, and
  `Globals` or `Outputs` when they apply. Internal functions too.
- Test it in `tests/<domain>.bats` with `assert_passes` and `assert_fails`, one case per
  test, each named `<function>: <case> -> <expectation>`, so a failing test names the
  function it is about. Cover the pass, every failure title, the report rows, and the usage
  errors.
- Add the assertion to the README reference and a line under `## [Unreleased]` in
  [CHANGELOG.md](CHANGELOG.md).

A change to a bats-assert compatible assertion has one more check: its report must stay
byte-identical to bats-assert's. `tests/run.bats` asserts the titles and rows. When in doubt,
run the same failing call through both libraries and diff the output.

## Releasing

A release is a tag on `main`.

1. Move the `Unreleased` entries in `CHANGELOG.md` under a new `## [X.Y.Z] - YYYY-MM-DD`
   heading and add the compare link at the foot of the file.
2. Commit as `chore: release vX.Y.Z`.
3. `git tag -s vX.Y.Z -m vX.Y.Z && git push --follow-tags`.

The release workflow runs the ci workflow on the tag and publishes a GitHub release with
the changelog entry as its notes. A tag without a matching changelog entry fails the
workflow.

## Conventions

Commit messages take the form `type(scope): summary`, as the standards for every stealth
repository set out at https://docs.stealthscale.io. The scope is the domain file when a
change stays in one: `feat(json): add assert_json_length`.

## Review

A pull request is reviewed by a maintainer of the stealth-scale organisation.
