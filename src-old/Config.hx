import haxe.xml.Access;
import sys.io.File;
import tink.cli.Prompt;
import sys.FileSystem;

typedef Dependency = {
	kind:DependencyKind,
	blind:Bool
}

enum DependencyKind {
	DHaxelib(name:String, ?version:String);
	DGit(name:String, url:String, ?ref:String, ?dir:String);
}

class Config {
	public var global:Array<Dependency> = [];
	public var profiles:Map<String, Array<Dependency>> = [];

	public function new() {}

	public function parse(prompt:Prompt):Config {
		if (!FileSystem.exists('sdm.xml')) {
			prompt.println('sdm.xml does not exist');
			return this;
		}

		final xmlContent:String = File.getContent('sdm.xml');
		final xml:Xml = Xml.parse(xmlContent);
		final node:Access = new Access(xml.firstElement());
	
		parseProfile(node, true);
		return this;
	}

	private function parseProfile(node:Access, isGlobal:Bool = false) {
		final list:Array<Dependency> = isGlobal ? global : (profiles[node.att.name] ??= []);

		for (n in node.elements) switch n.name {
			case 'haxelib':
				list.push({
					kind: DHaxelib(n.att.name, n.has.version ? n.att.version : null),
					blind: n.has.blind && n.att.blind == 'true'
				});
			case 'git':
				list.push({
					kind: DGit(n.att.name, n.att.url, n.has.ref ? n.att.ref : null, n.has.dir ? n.att.dir : null),
					blind: n.has.blind && n.att.blind == 'true'
				});
			case 'profile' if (isGlobal): parseProfile(n);
		}
	}

	public function write(prompt:Prompt) {
		final document:Xml = Xml.createDocument();
		document.addChild(Xml.createDocType('sdm-config'));
		document.addChild(writeProfile(global, true));
		
		if (!FileSystem.exists('sdm.xml')) prompt.println('sdm.xml successfully created!');
		File.saveContent('sdm.xml', haxe.xml.Printer.print(document, true));
	}

	private function writeProfile(list:Array<Dependency>, isGlobal:Bool = false):Xml {
		final profile:Xml = Xml.createElement(isGlobal ? 'config' : 'profile');
		for (d in list) switch d.kind {
			case DHaxelib(name, version):
				final haxelib:Xml = Xml.createElement('haxelib');
				haxelib.set('name', name);
				if (version != null) haxelib.set('version', version);
				profile.addChild(haxelib);
			case DGit(name, url, ref, dir):
				final git:Xml = Xml.createElement('git');
				git.set('name', name);
				git.set('url', url);
				if (ref != null) git.set('ref', ref);
				if (dir != null) git.set('dir', dir);
				profile.addChild(git);
		}
		for (n => l in profiles) {
			final subprofile:Xml = writeProfile(l);
			subprofile.nodeName = n;
			profile.addChild(subprofile);
		}
		return profile;
	}
}