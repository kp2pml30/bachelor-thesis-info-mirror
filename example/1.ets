import * from "panda/interop"

class C1 {
	static fld: double = 2
}

class C2 {
	static fld: int = 1
}

function main(): void {
	const eng = ScriptVM.create("ecmascript")
	eng.load("hidden/example/1.js.abc")
	eng.destroy()

	console.println(C1.fld)
	console.println(C2.fld)
}
