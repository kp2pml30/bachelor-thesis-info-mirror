const C1 = Interop.findClass('C1')
const C2 = Interop.findClass('C2')

function test(x, y) {
	x.fld *= y
}

for (let i = 0; i < 50; i++) {
	test(C1, 10)
	test(C2, 13)
}
