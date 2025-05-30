package sdm;

enum DependencyType {
	HAXELIB(version:Null<String>);
	GIT(url:String, ref:Null<String>);
	DEV(path:String);
}

class Dependency {
	public var name(default, null):String;
	public var type(default, null):DependencyType;
	public var skipDependencies(default, null):Bool;

	public inline function new(name:String, type:DependencyType, skipDependencies:Bool) {
		set(name, type, skipDependencies);
	}

	public inline function set(name:String, type:DependencyType, skipDependencies:Bool) {
		this.name = name;
		this.type = type;
		this.skipDependencies = skipDependencies;
	}

	public function install() {
		var args = ['--never'];
		if (skipDependencies)
			args.push('--skip-dependencies');
		if (Main.isGlobal)
			args.push('--global');

		switch type {
			case HAXELIB(version):
				args = args.concat(['install', name]);
				if (version != null)
					args.push(version);

			case GIT(url, ref):
				args = args.concat(['git', name, url]);
				if (ref != null)
					args.push(ref);

			case DEV(path):
				args = args.concat(['dev', name, path]);
		}

		Sys.command('haxelib', args);
	}
}
