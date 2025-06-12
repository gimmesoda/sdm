package sdm;

import haxe.xml.Printer;
import sdm.Dependency;

class Config {
	public static var dependencies:Array<Dependency> = [];
	public static var profiles:Map<String, Array<Dependency>> = [];
}

class ConfigParser {
	public static function parse(string:String) {
		final xml = Xml.parse(string).firstElement();

		for (element in xml.elements()) {
			switch element.nodeName {
				case 'dependency':
					parseDependency(element);
				case 'profile':
					parseProfile(element);
			}
		}
	}

	public static function parseDependency(xml:Xml, ?profile:String) {
		final name = xml.get('name');
		final type = xml.get('type');
		final skipSubDeps = xml.get('skip-sub-deps') == 'true' || xml.get('skip-dependencies') == 'true';

		final deps = profile != null ? Config.profiles[profile] : Config.dependencies;

		if (Lambda.exists(deps, dep -> dep.name == name))
			throw 'Duplicate dependency $name';

		switch type {
			case 'haxelib':
				deps.push({name: name, type: DHaxelib(xml.get('version')), skipSubDeps: skipSubDeps});
			case 'git':
				deps.push({name: name, type: DGit(xml.get('url'), xml.get('ref')), skipSubDeps: skipSubDeps});
			case 'dev':
				deps.push({name: name, type: DDev(xml.get('path')), skipSubDeps: skipSubDeps});
		}
	}

	public static function parseProfile(xml:Xml) {
		final name = xml.get('name');

		Config.profiles[name] = [];

		for (element in xml.elements()) {
			if (element.nodeName == 'dependency')
				parseDependency(element, name);
		}
	}
}

class ConfigPrinter {
	public static function print():String {
		final xml = Xml.createDocument();
		xml.addChild(Xml.createDocType('sdm-config'));

		final body = Xml.createElement('config');
		xml.addChild(body);

		for (dep in Config.dependencies)
			body.addChild(printDependency(dep));

		for (name => deps in Config.profiles) {
			if (deps.length > 0)
				body.addChild(printProfile(name, deps));
		}

		return Printer.print(xml, true);
	}

	public static function printDependency(dep:Dependency):Xml {
		final xml = Xml.createElement('dependency');
		xml.set('name', dep.name);

		switch dep.type {
			case DHaxelib(version):
				xml.set('type', 'haxelib');
				if (version != null)
					xml.set('version', version);
			case DGit(url, ref):
				xml.set('type', 'git');
				xml.set('url', url);
				if (ref != null)
					xml.set('ref', ref);
			case DDev(path):
				xml.set('type', 'dev');
				xml.set('path', path);
		}

		if (dep.skipSubDeps)
			xml.set('skip-sub-deps', 'true');

		return xml;
	}

	public static function printProfile(name:String, deps:Array<Dependency>):Xml {
		final xml = Xml.createElement('profile');
		xml.set('name', name);

		for (dep in deps)
			xml.addChild(printDependency(dep));

		return xml;
	}
}
