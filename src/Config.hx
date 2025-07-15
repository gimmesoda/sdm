import haxe.xml.Printer;
import Dependency.DependencyType;
import haxe.xml.Access;
import sys.io.File;
import sys.FileSystem;

class Config {
	public static var dependencies:Array<Dependency> = [];
	public static var profiles:Map<String, Array<Dependency>> = [];

	public static function parseOrThrow() {
		final path = '${Main.workingDirectory}/sdm.xml';
		if (!FileSystem.exists(path)) throw 'SDM not initialized';

		final xml = Xml.parse(File.getContent(path));
		final fast = new Access(xml.firstElement());

		_parseDependencies(fast, dependencies);

		for (profile in fast.nodes.profile) {
			final list = profiles[profile.att.name] ??= [];
			_parseDependencies(profile, list);
		}
	}

	static function _parseDependencies(fast:Access, list:Array<Dependency>) {
		for (dep in fast.elements) {
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

			addOrOverwrite(list, name, type, blind);
		}
	}

	public static function write() {
		final doc = Xml.createDocument();
		doc.addChild(Xml.createDocType('sdm-config'));

		final conf = Xml.createElement('config');

		for (dep in dependencies)
			conf.addChild(_writeDependency(dep));

		for (prf => list in profiles) {
			final xml = Xml.createElement('profile');
			xml.set('name', prf);
			for (dep in list) xml.addChild(_writeDependency(dep));
			conf.addChild(xml);
		}

		doc.addChild(conf);

		File.saveContent('${Main.workingDirectory}/sdm.xml', Printer.print(doc, true));
	}

	static function _writeDependency(dep:Dependency):Xml {
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

	public static function addOrOverwrite(list:Array<Dependency>, name:String, type:DependencyType, blind:Bool) {
		final found = Lambda.find(list, d -> d.name == name);
		if (found != null) {
			found.type = type;
			found.blind = blind;
		} else {
			list.push({
				name: name,
				type: type,
				blind: blind
			});
		}
	}

	static inline function _isBlindDependency(fast:Access):Bool {
		return (fast.has.blind && fast.att.blind == 'true')
			|| (fast.has.resolve('skip-sub-deps') && fast.att.resolve('skip-sub-deps') == 'true')
			|| (fast.has.resolve('skip-dependencies') && fast.att.resolve('skip-dependencies') == 'true');
	}
}
