#!/bin/sh
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/goldenfleece-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM
xcrun --sdk macosx clang -fobjc-arc -framework Foundation \
    -I "$repo_dir/GoldenFleece" \
    "$repo_dir/GoldenFleece/NSObject+GFJson.m" \
    "$repo_dir/GoldenFleece/GFDateFormatter.m" \
    "$repo_dir/Tests/SerializationTests.m" \
    -o "$test_dir/serialization-tests"
"$test_dir/serialization-tests"
