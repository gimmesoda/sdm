package host;

enum Kind {
	DHaxelib(?version:String);
	DGit(url:String, ?ref:String, ?dir:String);
}

class Dependency {
	public var name(default, null):String;

	private var kind:Kind;
	private var blind:Bool;

	public static function fromXml(e:Xml):Null<Dependency> {
		if (!e.exists('name')) {
			Sys.println('\033[33mDependency should have name attribute\033[39m');
			return null;
		}

		final name:String = e.get('name');
		final blind:Bool = e.exists('blind') && e.get('blind') == 'true';

		switch e.nodeName {
			case 'haxelib':
				final version:Null<String> = e.exists('version') ? e.get('version') : null;
				return new Dependency(name, DHaxelib(version), blind);

			case 'git':
				if (!e.exists('url')) {
					Sys.println('\033[33mDependency $name should have url attribute\033[39m');
					return null;
				}
				final url:String = e.get('url');
				var ref:Null<String> = e.exists('ref') ? e.get('ref') : null;
				final dir:Null<String> = e.exists('dir') ? e.get('dir') : null;

				if (dir != null && ref == null) {
					Sys.println('\033[33mDependency $name does not have ref attributes, trying main...');
					ref = 'main';
				}

				return new Dependency(name, DGit(url, ref, dir), blind);

			case t:
				Sys.println('Unknown dependency type $t');
				return null;
		}
	}

	public function new(name:String, kind:Kind, blind:Bool) {
		this.name = name;
		set(kind, blind);
	}

	public function set(kind:Kind, blind:Bool) {
		this.kind = kind;
		this.blind = blind;
	}

	public inline function install(cwd:String, global:Bool) {
		Sys.command('haxelib', buildArgs(cwd, global));
	}

	private function buildArgs(cwd:String, global:Bool):Array<String> {
		var args:Array<String> = ['-cwd', cwd, '--never'];
		if (global) args.push('--global');

		if (blind) args.push('--skip-dependencies');

		switch kind {
			case DHaxelib(version):
				args = args.concat(['install', name]);
				if (version != null) args.push(version);

			case DGit(url, ref, dir):
				args = args.concat(['git', name, url]);
				if (ref != null) args.push(ref);
				if (dir != null) args.push(dir);
		}

		return args;
	}

	public function getKindString():String {
		return switch kind {
			case DHaxelib(_): 'haxelib';
			case DGit(_, _, _): 'git';
		}
	}

	public function toXml():Xml {
		final e:Xml = Xml.createElement(getKindString());

		e.set('name', name);
		if (blind) e.set('blind', 'true');

		switch kind {
			case DHaxelib(version):
				if (version != null) e.set('version', version);

			case DGit(url, ref, dir):
				e.set('url', url);
				if (ref != null) e.set('ref', ref);
				if (dir != null) e.set('dir', dir);
		}

		return e;
	}

	public function toString():String {
		final b:StringBuf = new StringBuf();
		b.add(name);
		b.add(' - ');
		b.add(getKindString());
		b.addChar('('.code);

		switch kind {
			case DHaxelib(version):
				b.add(version ?? 'latest');

			case DGit(url, ref, dir):
				b.add(url);
				if (ref != null) b.add('#$ref');
				if (dir != null) {
					if (ref == null) b.add('#main');
					b.add('#$dir');
				}
		}

		b.addChar(')'.code);
		return b.toString();
	}
}