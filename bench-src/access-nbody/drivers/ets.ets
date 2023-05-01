import * from "panda/interop"

const PI = 3.141592653589793;
const SOLAR_MASS = 4 * PI * PI;
const DAYS_PER_YEAR = 365.24;

class Body {
	public x: double
	public y: double
	public z: double
	public vx: double
	public vy: double
	public vz: double
	public mass: double

	public constructor(x: double, y: double, z: double, vx: double, vy: double, vz: double, mass: double) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.vx = vx;
		this.vy = vy;
		this.vz = vz;
		this.mass = mass;
	}
	public offsetMomentum(px: double, py: double, pz: double): Body {
		this.vx = -px / SOLAR_MASS;
		this.vy = -py / SOLAR_MASS;
		this.vz = -pz / SOLAR_MASS;
		return this;
	}
}


function main(args: String[]): void {
	const eng = ScriptVM.create("ecmascript")
	const obj = eng.load(args[0])
	const fn = asScriptObject(eng.getObjectProperty(obj, "run"))
	eng.invoke(fn)
	eng.destroy()
}

