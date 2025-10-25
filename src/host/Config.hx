package host;

import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;

using StringTools;

class Config {
	public static inline var XML_PATH:String = 'sdm.xml';

	private var main:Dependencies;
	private var profiles:Map<String, Dependencies> = [];

	public function new() {
		main = new Dependencies();
	}

	public function addDependency(name:String, kind:Dependency.Kind, blind:Bool, ?profile:String) {
		if (profile == null) {
			main.add(name, kind, blind);
			return;
		}

		profiles[profile] ??= new Dependencies();
		profiles[profile].add(name, kind, blind);
	}

	public function removeDependency(name:String, ?profile:String) {
		if (profile == null) {
			main.remove(name);
			return;
		}
		
		if (profiles.exists(profile)) {
			profiles[profile].remove(name);
			if (profiles[profile].isEmpty()) profiles.remove(profile);
		}
	}

	public function loadXml(cwd:String) {
		final xmlPath:String = Path.join([cwd, XML_PATH]);

		if (!FileSystem.exists(xmlPath)) {
			Sys.println('\033[31mNo sdm.xml found\033[39m');
			return;
		}

		final e:Xml = Xml.parse(File.getContent(xmlPath)).firstElement();
		if (e.nodeName != 'config') {
			Sys.println('\033[31m${e.nodeName} expected to be a config\033[39m');
			return;
		}

		for (se in e.elements()) {
			switch se.nodeName {
				case 'haxelib' | 'git':
					final d:Null<Dependency> = Dependency.fromXml(se);
					if (d != null) (main : Array<Dependency>).push(d);

				case 'profile': loadProfileXml(se);

				case n: Sys.println('\033[33mUnknown node name $n\033[39m');
			}
		}
	}

	private function loadProfileXml(e:Xml) {
		if (!e.exists('name')) {
			Sys.println('\033[33mProfile should have name attribute\033[39m');
			return;
		}

		final name:String = e.get('name');
		profiles[name] ??= new Dependencies();

		for (se in e.elements()) switch se.nodeName {
			case 'haxelib' | 'git':
				final d:Null<Dependency> = Dependency.fromXml(se);
				if (d != null) (profiles[name] : Array<Dependency>).push(d);

			case 'profile':
				Sys.println('\033[33mCannot add profile to profile\033[39m');
				continue;
			
			case n: Sys.println('\033[33mUnknown node name $n\033[39m');
		}
	}

	public function saveXml(cwd:String, force:Bool) {
		final xmlPath:String = Path.join([cwd, XML_PATH]);

		if (!force && FileSystem.exists(xmlPath)) {
			Sys.println('sdm.xml already exists');
			Sys.print('overwrite? [y/N] ');

			final answer:Int = Sys.stdin().readLine().toLowerCase().trim().fastCodeAt(0);
			if (answer != 'y'.code) return;
		}

		final doc:Xml = Xml.createDocument();
		doc.addChild(Xml.createDocType('sdm-config'));

		final e:Xml = Xml.createElement('config');
		for (d in main) e.addChild(d.toXml());
		for (p => deps in profiles) {
			final se:Xml = Xml.createElement('profile');
			se.set('name', p);
			for (d in deps) se.addChild(d.toXml());
			e.addChild(se);
		}
		doc.addChild(e);

		File.saveContent(xmlPath, haxe.xml.Printer.print(doc, true));
	}
}