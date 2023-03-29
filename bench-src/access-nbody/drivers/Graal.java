import java.nio.file.Files;
import java.nio.file.Paths;
import java.io.FileReader;
import java.nio.charset.StandardCharsets;
import javax.script.*;
import org.graalvm.polyglot.*;

public class Graal {
	public static class Body {
		public double x;
		public double y;
		public double z;
		public double vx;
		public double vy;
		public double vz;
		public double mass;

		private static double PI = 3.141592653589793;
		private static double SOLAR_MASS = 4 * PI * PI;
		private static double DAYS_PER_YEAR = 365.24;

		public Body(double x, double y, double z, double vx, double vy, double vz, double mass) {
			this.x = x;
			this.y = y;
			this.z = z;
			this.vx = vx;
			this.vy = vy;
			this.vz = vz;
			this.mass = mass;
		}
		public Body offsetMomentum(double px, double py, double pz) {
			this.vx = -px / SOLAR_MASS;
			this.vy = -py / SOLAR_MASS;
			this.vz = -pz / SOLAR_MASS;
			return this;
		}
	}
	public static void main(String[] args) throws Exception {
		Context context = Context.newBuilder("js")
			.allowAllAccess(true)
			.build();

		context.eval("js", new String(Files.readAllBytes(Paths.get("../graal.interop.js")), StandardCharsets.UTF_8));
		Value glb = context.eval("js", "this");
		//Invocable fun = (Invocable)glb.getMember("run");
		glb.invokeMember("run");
	}
}
