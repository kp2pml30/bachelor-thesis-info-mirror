#!/bin/bash

source ./common.sh

mkdir -p "hidden/example"
"$PANDA_BUILD/bin/es2panda" --opt-level=2 --extension=js --output "hidden/example/1.js.abc" "example/1.js"
"$PANDA_BUILD/bin/es2panda" --opt-level=2 --extension=ets --output "hidden/example/1.ets.abc" --arktsconfig=hidden/arktsconfig.json "example/1.ets"


"$PANDA_BUILD/bin/ark" \
	--compiler-disasm-dump \
	--compiler-hotness-threshold=10 \
	--no-async-jit=true \
	--interpreter-type=cpp \
	--runtime-type=ets \
	--load-runtimes=ets:ecmascript \
	"--boot-panda-files=$PANDA_BUILD/plugins/ets/etsstdlib.abc:$PANDA_BUILD/plugins/ets/etsinterop.abc:$PANDA_BUILD/plugins/ets/etsinterop1.abc:$PANDA_BUILD/plugins/ets/etsinterop_stub.abc" \
	"hidden/example/1.ets.abc" ETSGLOBAL::main
