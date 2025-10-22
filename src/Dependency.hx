import tink.io.Worker;
import sys.io.Process;

using StringTools;

enum DependencyKind {
	DHaxelib(?version:String);
	DGit(url:String, ?ref:String, ?dir:String);
}

class Dependency {
	public var name:String;
	public var kind:DependencyKind;
	public var blind:Bool;

	public function new(name:String, kind:DependencyKind, blind:Bool = false) {
		this.name = name;
		this.kind = kind;
		this.blind = blind;
	}

	public function install():Promise<Noise> {
		var args:Array<String> = ['--never'];
		if (blind) args.push('--skip-dependencies');

		switch kind {
			case DHaxelib(version):
				args = args.concat(['install', name]);
				if (version != null) args.push(version);
			case DGit(url, ref, dir):
				args = args.concat(['git', name, url]);
				if (ref != null) args.push(ref);
				if (dir != null) {
					if (ref == null) return Worker.get().work(() -> Failure(new Error(BadRequest, 'Missing git ref')));
					args.push(dir);
				}
		}

		return Worker.get().work(() -> {
			final proc:Process = new Process('haxelib', args);
			switch proc.exitCode() {
				case 0: Success(Noise);
				default:
					var message:String = proc.stderr.readAll().toString().trim();
					message = message.substring(message.lastIndexOf('\n' + 1));
					Failure(new Error(message.length == 0 ? 'null message' : message));
			}
		});
	}
}