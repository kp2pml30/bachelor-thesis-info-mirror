#!/bin/bash

set -e

D="$(mktemp -d)"

mv "./artifacts" "$D"

CB="$(git branch --show-current)"
git checkout artifacts
rm -rf "./artifacts"
cp -r "$D/artifacts" "./artifacts"
git add artifacts
git commit --amend --no-edit
git checkout "$CB"

mv "$D" "./artifacts"

rm -rf "$D"
