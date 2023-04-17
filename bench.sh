#!/bin/bash

source ./common.sh

mkdir -p artifacts

function repr {
	echo "$@" >> "$REPROUT"
	echo "$@"
}

function setRepr {
	REPROUT="$(readlink -f -- "$CUR_DIR/artifacts/$1")"
	: > "$REPROUT"
}

echo "=== cpu ==="
setRepr "cpu.info"
cat /proc/cpuinfo | grep -i 'model name' | uniq | tee "$REPROUT"

echo "=== repo info ==="

cd "$PANDA_ROOT"

setRepr "repo.info"

for i in $(find . -name '.git' -and -not -path '*third?party*' | sort)
do
	cd "$i"
	repr "repo $i"
	repr "  branch $(git branch --show-current) at $(git rev-parse HEAD)"
	repr "  remotes:"
	for i in $(git remote)
	do
		repr "    $i $(git remote get-url $i)"
	done
	cd "$PANDA_ROOT"
done

cd "$CUR_DIR"

echo "=== ark version ==="

setRepr "ark.version"

"$PANDA_BUILD/bin/ark" --version 2>&1 | tee "$REPROUT" || true

mkdir -p "$CUR_DIR/artifacts/benchs/"

for bench in hidden/benchs/*
do
	BENCHOUT="$CUR_DIR/artifacts/benchs/$(basename -- "$bench").json"
	echo "{" > "$BENCHOUT"

	echo "=== node ==="
	
	echo '"node": ' >> "$BENCHOUT"
	node "$bench/node.js" >> "$BENCHOUT"

	echo "=== ark ==="
	echo ', "ark": ' >> "$BENCHOUT"
	"$PANDA_BUILD/bin/ark" --interpreter-type=cpp --gc-type=g1-gc --load-runtimes=ecmascript "$bench/ark.abc" _GLOBAL::func_main_0 >> "$BENCHOUT"

	echo "=== ark-interop ==="
	pushd "$bench" 2>&1 > /dev/null
	echo ', "ark-i": ' >> "$BENCHOUT"
	"$PANDA_BUILD/bin/ark" \
		--interpreter-type=cpp \
		--runtime-type=ets \
		--gc-type=g1-gc \
		--load-runtimes=ets:ecmascript \
		"--boot-panda-files=$PANDA_BUILD/plugins/ets/etsstdlib.abc:$PANDA_BUILD/plugins/ets/etsinterop.abc:$PANDA_BUILD/plugins/ets/etsinterop1.abc:$PANDA_BUILD/plugins/ets/etsinterop_stub.abc" \
		"drivers/ets.abc" ETSGLOBAL::main \
			| sed -e 's/deoptimziations count\s*[0-9]*//g' \
			>> "$BENCHOUT"
	popd 2>&1 > /dev/null

	#echo "=== nashorn ==="
	#echo ', "nashorn": ' >> "$BENCHOUT"
	#jjs --language=es6 "$bench/nashorn.js" >> "$BENCHOUT"

	echo "=== nashorn ==="
	echo ', "nashorn": ' >> "$BENCHOUT"
	jjs --language=es6 -ot=false "$bench/nashorn.js" >> "$BENCHOUT"

	echo "=== nashorn-interop ==="
	echo ', "nashorn-i": ' >> "$BENCHOUT"
	pushd "$bench/drivers" 2>&1 > /dev/null
	java -Dnashorn.args="--language=es6 -ot=false" Nashorn >> "$BENCHOUT"
	popd 2>&1 > /dev/null

	echo "=== graal ==="
	echo ', "graal": ' >> "$BENCHOUT"
	"$GRAAL/js" --jvm "$bench/graal.js" >> "$BENCHOUT"

	echo "=== graal-interop ==="
	pushd "$bench/drivers" 2>&1 > /dev/null
	echo ', "graal-i": ' >> "$BENCHOUT"
	"$GRAAL/java" Graal >> "$BENCHOUT"
	popd 2>&1 > /dev/null

	echo "}" >> "$BENCHOUT"
done
