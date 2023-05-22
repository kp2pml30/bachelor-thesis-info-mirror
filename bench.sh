#!/bin/bash

source ./common.sh

#set -x

verifyRoots

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
	echo "### benchmarking $(basename -- "$bench")"

	BENCHOUT="$CUR_DIR/artifacts/benchs/$(basename -- "$bench").json"
	echo "{" > "$BENCHOUT"

	source bench.env
	COM="bench-src/$(basename -- "$bench")/bench.env"
	if [ -f "$COM"  ]
	then
		source "$COM"
	fi

mapOpts () {
	echo "$2" | sed 's/ /\n/g' | sed "s/^/$1/g" | tr '\n' ' '
}

	if [ "$JIT" = true ]
	then
		ARK_OPTS=""
		JVM_OPTS=""
		JJS_OPTS=""
		NODE_OPTS=""
		GRAAL_OPTS=""
		GRAAL_JVM_OPTS=""
	else
		NODE_OPTS="--jitless --no-opt"
		ARK_OPTS="--compiler-enable-jit=false"
		JVM_OPTS="-Djava.compiler=NONE -Xint"
		JJS_OPTS="$(mapOpts "-J" "$JVM_OPTS")"
		GRAAL_OPTS=""
		GRAAL_JVM_OPTS=""
	fi

	echo "=== node ==="
	
	echo '"node": ' >> "$BENCHOUT"
	# --print-opt-code 
	node $NODE_OPTS "$bench/node.js" >> "$BENCHOUT"

	echo "=== ark ==="
	echo ', "ark": ' >> "$BENCHOUT"
	"$PANDA_BUILD/bin/ark" $ARK_OPTS --interpreter-type=cpp --gc-type=g1-gc --load-runtimes=ecmascript "$bench/ark.abc" _GLOBAL::func_main_0 >> "$BENCHOUT"

	pushd "$bench" 2>&1 > /dev/null
	echo "=== ark-int ==="
	echo ', "ark-int": ' >> "$BENCHOUT"
	"$PANDA_BUILD/bin/ark" \
		$ARK_OPTS \
		--interpreter-type=cpp \
		--runtime-type=ets \
		--load-runtimes=ets:ecmascript \
		"--boot-panda-files=$PANDA_BUILD/plugins/ets/etsstdlib.abc:$PANDA_BUILD/plugins/ets/etsinterop.abc:$PANDA_BUILD/plugins/ets/etsinterop1.abc:$PANDA_BUILD/plugins/ets/etsinterop_stub.abc" \
		"drivers/ets.abc" ETSGLOBAL::main -- "ark.interop.abc" \
			>> "$BENCHOUT"
	echo "=== ark-int-arr ==="
	echo ', "ark-int-arr": ' >> "$BENCHOUT"
	"$PANDA_BUILD/bin/ark" \
		$ARK_OPTS \
		--interpreter-type=cpp \
		--runtime-type=ets \
		--load-runtimes=ets:ecmascript \
		"--boot-panda-files=$PANDA_BUILD/plugins/ets/etsstdlib.abc:$PANDA_BUILD/plugins/ets/etsinterop.abc:$PANDA_BUILD/plugins/ets/etsinterop1.abc:$PANDA_BUILD/plugins/ets/etsinterop_stub.abc" \
		"drivers/ets.abc" ETSGLOBAL::main -- "ark.interop.array.abc" \
			>> "$BENCHOUT"
	popd 2>&1 > /dev/null

	echo "=== nashorn ==="
	echo ', "nashorn": ' >> "$BENCHOUT"
	jjs $JJS_OPTS --language=es6 -ot=false "$bench/nashorn.js" >> "$BENCHOUT"

	pushd "$bench/drivers" 2>&1 > /dev/null
	echo "=== nashorn-int ==="
	echo ', "nashorn-int": ' >> "$BENCHOUT"
	java $JVM_OPTS -Dnashorn.args="--language=es6 -ot=false" Nashorn "nashorn.interop.js" >> "$BENCHOUT"
	echo "=== nashorn-int-arr ==="
	echo ', "nashorn-int-arr": ' >> "$BENCHOUT"
	java $JVM_OPTS -Dnashorn.args="--language=es6 -ot=false" Nashorn "nashorn.interop.array.js" >> "$BENCHOUT"
	popd 2>&1 > /dev/null

	echo "=== graal ==="
	echo ', "graal": ' >> "$BENCHOUT"
	"$GRAAL/js" --jvm $GRAAL_OPTS "$bench/graal.js" >> "$BENCHOUT"

	pushd "$bench/drivers" 2>&1 > /dev/null
	echo "=== graal-int ==="
	echo ', "graal-int": ' >> "$BENCHOUT"
	"$GRAAL/java" $GRAAL_JVM_OPTS Graal "graal.interop.js" >> "$BENCHOUT"
	echo "=== graal-int-arr ==="
	echo ', "graal-int-arr": ' >> "$BENCHOUT"
	"$GRAAL/java" $GRAAL_JVM_OPTS Graal "graal.interop.array.js" >> "$BENCHOUT"
	popd 2>&1 > /dev/null

	echo "}" >> "$BENCHOUT"
done
