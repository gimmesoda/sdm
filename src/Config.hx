import haxe.xml.Printer;
import Dependency.DependencyType;
import haxe.xml.Access;
import sys.io.File;
import sys.FileSystem;

typedef Profile = {
	dependencies:Array<Dependency>,
	tasks:Array<Task>,
}

class Config {
	public static var global:Profile = { dependencies: [], tasks: [] };
	public static var profiles:Map<String, Profile> = [];

	public static function parseOrThrow() {
		final path = '${Main.workingDirectory}/sdm.xml';
		if (!FileSystem.exists(path)) throw 'SDM not initialized';

		final xml = Xml.parse(File.getContent(path));
		final fast = new Access(xml.firstElement());

		_parseProfile(fast, global);

		for (profile in fast.nodes.profile) {
			final list = profiles[profile.att.name] ??= { dependencies: [], tasks: [] };
			_parseProfile(profile, list);
		}
	}

	private static function _parseProfile(fast:Access, profile:Profile) {
		for (dep in fast.elements) {
			// tasks
			if (dep.name == 'task') {
				var cmd = dep.att.cmd;
				var dir = dep.has.dir ? dep.att.dir : null;

				addTask(profile, cmd, dir);

				continue;
			}

			// dependencies
			var type:Null<DependencyType>;
			if (dep.name == 'haxelib' || (dep.name == 'dependency' && dep.att.type == 'haxelib'))
				type = DHaxelib(dep.has.version ? dep.att.version : null);
			else if (dep.name == 'git' || (dep.name == 'dependency' && dep.att.type == 'git'))
				type = DGit(dep.att.url, dep.has.ref ? dep.att.ref : null);
			else if (dep.name == 'dev' || (dep.name == 'dependency' && dep.att.type == 'dev'))
				type = DDev(dep.att.path);
			else continue;

			final name = dep.att.name;
			final blind = _isBlindDependency(dep);

			addOrOverwriteDependency(profile, name, type, blind);
		}
	}

	public static function write() {
		final doc = Xml.createDocument();
		doc.addChild(Xml.createDocType('sdm-config'));

		final conf = Xml.createElement('config');

		for (dep in global.dependencies)
			conf.addChild(_writeDependency(dep));
		for (tsk in global.tasks)
			conf.addChild(_writeTask(tsk));

		for (name => profile in profiles) {
			final xml = Xml.createElement('profile');
			xml.set('name', name);
			for (dep in profile.dependencies) xml.addChild(_writeDependency(dep));
			for (tsk in profile.tasks) xml.addChild(_writeTask(tsk));
			conf.addChild(xml);
		}

		doc.addChild(conf);

		File.saveContent('${Main.workingDirectory}/sdm.xml', Printer.print(doc, true));
	}

	private static function _writeDependency(dep:Dependency):Xml {
		final xml = Xml.createElement(switch dep.type {
			case DHaxelib(_): 'haxelib';
			case DGit(_, _): 'git';
			case DDev(_): 'dev';
		});

		xml.set('name', dep.name);
		if (dep.blind) xml.set('blind', 'true');

		switch dep.type {
			case DHaxelib(version):
				if (version != null) xml.set('version', version);
			case DGit(url, ref):
				xml.set('url', url);
				if (ref != null) xml.set('ref', ref);
			case DDev(path):
				xml.set('path', path);
		}

		return xml;
	}

	private static function _writeTask(tsk:Task):Xml {
		final xml = Xml.createElement('task');
		xml.set('cmd', tsk.cmd);
		if (tsk.dir != null) xml.set('dir', tsk.dir);
		return xml;
	}

	public static function addOrOverwriteDependency(profile:Profile, name:String, type:DependencyType, blind:Bool) {
		final found = Lambda.find(profile.dependencies, d -> d.name == name);
		if (found != null) {
			found.type = type;
			found.blind = blind;
		} else {
			profile.dependencies.push({
				name: name,
				type: type,
				blind: blind
			});
		}
	}

	public static function addTask(profile:Profile, cmd:String, ?dir:String) {
		profile.tasks.push({ cmd: cmd, dir: dir });
	}

	private static inline function _isBlindDependency(fast:Access):Bool {
		return (fast.has.blind && fast.att.blind == 'true')
			|| (fast.has.resolve('skip-sub-deps') && fast.att.resolve('skip-sub-deps') == 'true')
			|| (fast.has.resolve('skip-dependencies') && fast.att.resolve('skip-dependencies') == 'true');
	}
}
