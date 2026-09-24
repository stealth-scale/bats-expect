# Entry point for `load` and `bats_load_library`. Sources the library from src/,
# the report layer first because every other file prints through it.
#
#   load 'helpers/bats-expect/load'
#
# The library is self-contained. When bats-support is loaded as well, its `fail`
# is used; otherwise a polyfill with the same contract is defined.
expect_dir="$(dirname "${BASH_SOURCE[0]}")/src"
for expect_file in report run value variable type number array file nameref json meta; do
    # shellcheck source=/dev/null
    source "${expect_dir}/${expect_file}.bash"
done
unset expect_dir expect_file
