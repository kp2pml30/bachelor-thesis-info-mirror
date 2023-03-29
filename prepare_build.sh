#!/bin/bash

source ./common.sh

if [ ! -d "$PANDA_BUILD" ]
then
	cmake \
		-DCMAKE_C_COMPILER=clang-14 \
		-DCMAKE_CXX_COMPILER=clang++-14 \
		-GNinja \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
		-DPANDA_WITH_TESTS=false \
		-DPANDA_WITH_ECMASCRIPT=true \
		-DPANDA_WITH_BENCHMARKS=false \
		-DPANDA_CROSS_COMPILER=false \
		-DPANDA_ENABLE_CLANG_TIDY=true \
		-DPANDA_QEMU_BUILD=false \
		-DPANDA_WITH_STATIC_LINKER=false \
		-DPANDA_WITH_ETS=true \
		-DPANDA_WITH_BYTECODE_OPTIMIZER=true \
		-DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE \
		-DCMAKE_BUILD_TYPE:STRING=Release \
		-S "$PANDA_ROOT" \
		-B "$PANDA_BUILD" \
		-G Ninja
fi

cmake --build "$PANDA_BUILD" --target ark --target es2panda --target etsstdlib

mkdir -p hidden/benchs

cat <<EOF > hidden/arktsconfig.json
{
	"baseUrl": "$PANDA_ROOT",
	"paths": {
		"std": "$PANDA_ROOT/plugins/ets/stdlib/std",
		"panda": "$PANDA_ROOT/plugins/ets/stdlib/panda"
  }
}
EOF

for i in bench-src/*
do
	base="$(basename "$i")"
	echo "building benchmark $base"
	mkdir -p "hidden/benchs/$base"
	modes=(nashorn graal ark node)
	rm -rf "hidden/benchs/$base/drivers" 2> /dev/null || true
	outp="hidden/benchs/$base/"
	cp -r "$i/drivers" "$outp"
	for name in ${modes[*]}
	do
		erb "mode=$name" 'interop=false' "$i/src.js.erb" > "$outp/$name.js"
		erb "mode=$name" 'interop=true' "$i/src.js.erb" > "$outp/$name.interop.js"
	done

	"$PANDA_BUILD/bin/es2panda" --extension=js --output "$outp/ark.abc" "$outp/ark.js"
	"$PANDA_BUILD/bin/es2panda" --extension=js --output "$outp/ark.interop.abc" "$outp/ark.interop.js"
	"$PANDA_BUILD/bin/es2panda" "--arktsconfig=hidden/arktsconfig.json" --extension=ets --output "$outp/drivers/ets.abc" "$outp/drivers/ets.ets"
	javac "$outp/drivers/Nashorn.java"
	"$GRAAL/javac" "$outp/drivers/Graal.java"
done
