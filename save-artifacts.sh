#!/bin/bash

set -e
set -x

D="$(mktemp -d)"

mv "./artifacts" "$D"

function undo {
	mv "$D/artifacts" "."
	rm -rf "$D"
}

CB="$(git branch --show-current)"
git checkout artifacts || (undo && exit 1)
rm -rf "./artifacts"
cp -r "$D/artifacts" "./artifacts"
git add artifacts
git commit --amend --no-edit
git checkout "$CB"

undo
