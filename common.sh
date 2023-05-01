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
echo "panda build: $PANDA_BUILD"
echo "graal root: $GRAAL"

PANDA_ROOT="$(readlink -f -- "$PANDA_ROOT")"
PANDA_BUILD="$(readlink -f -- "$PANDA_BUILD")"

verifyFile "$PANDA_ROOT" "libpandabase/interop/common.h"
verifyFile "$PANDA_ROOT" "plugins/ecmascript/compiler/optimizer/interop/ecmascript_foreign_objects_type_resolving.cpp"
verifyFile "$GRAAL" "js"

function verifyRoots {
	verifyFile "$PANDA_BUILD" "bin/ark" "bin/es2panda"
}

