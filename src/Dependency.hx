import sys.thread.Thread;
import tink.cli.Prompt;
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

	public function install(prompt:Prompt):Promise<Noise> {
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
			final code:Int = Sys.command('haxelib', args);
			code == 0 ? Success(Noise) : Failure(new Error(Std.string(code)));
		});
	}

	public function buildElement(prompt:Prompt):Xml {
		final el:Xml = Xml.createElement('dependency');
		el.set('name', name);
		if (blind) el.set('blind', 'true');
		switch kind {
			case DHaxelib(version):
				el.nodeName = 'haxelib';
				if (version != null) el.set('version', version);
			case DGit(url, ref, dir):
				el.nodeName = 'git';
				el.set('url', url);
				if (ref != null) el.set('ref', ref);
				if (dir != null) {
					if (ref == null) prompt.printeln('No git ref provided');
					else el.set('dir', dir);
				}
		}

		return el;
	}
}