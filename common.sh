#!/bin/bash

set -e

CUR_DIR="$(pwd)"

function verifyFile {
	pref="$1"
	shift
	for i in "$@"
	do
		[[ -f "$pref/$i" ]] || (echo "  absent file $pref/$i" && exit 1)
	done
}

echo "panda root: $PANDA_ROOT"

verifyFile "$PANDA_ROOT" "plugins/ecmascript/compiler/ecmascript_foreign_objects_type_resolving.cpp"

echo "panda build: $PANDA_BUILD"

verifyFile "$PANDA_BUILD" "bin/ark" "bin/es2panda"

echo "graal root: $GRAAL"

verifyFile "$GRAAL" "js"

PANDA_ROOT="$(readlink -f -- "$PANDA_ROOT")"
PANDA_BUILD="$(readlink -f -- "$PANDA_BUILD")"
