package sdm;

import haxe.xml.Printer;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class Main {
	public static var profile:Null<String> = null;
	public static var isGlobal:Bool = false;
	public static var skipDependencies:Bool = false;

	private static function main() {
		final args = Sys.args();
		var waiting = true;

		var job:Null<() -> Void> = null;

		Sys.setCwd(args.pop());

		while (args.length > 0) {
			switch args.shift().toLowerCase() {
				case 'setup' if (waiting):
					job = _setup;
					waiting = false;

				case 'init' if (waiting):
					job = _init;
					waiting = false;

				case 'install' if (waiting):
					job = _install;
					waiting = false;

				case 'add' if (waiting):
					switch args.shift() {
						case 'profile':
							job = _addProfile.bind(args.shift());
							waiting = false;

						case 'haxelib':
							job = _addHaxelib.bind(args.shift(), (args.length > 0 && !args[0].startsWith('-')) ? args.shift() : null);
							waiting = false;

						case 'git':
							job = _addGit.bind(args.shift(), args.shift(), (args.length > 0 && !args[0].startsWith('-')) ? args.shift() : null);
							waiting = false;

						case 'dev':
							job = _addDev.bind(args.shift(), args.shift());
							waiting = false;
					}

				case '--profile' | '-p':
					profile = args.shift();

				case '--global' | '-g':
					isGlobal = true;

				case '--skip-dependencies':
					skipDependencies = true;
			}
		}

		if (job != null)
			job();
	}

	private static function _setup() {
		File.saveContent(Path.join([Sys.getEnv('HAXEPATH'), 'sdm.cmd']), '@haxelib --global run sdm %*');
	}

	private static function _init() {
		File.saveContent('sdm.xml', '<!DOCTYPE sdm-config>\n<config></config>');
	}

	private static function _install() {
		if (!FileSystem.exists('sdm.xml') || FileSystem.isDirectory('sdm.xml'))
			return;

		if (!isGlobal)
			FileSystem.createDirectory('.haxelib');

		final document = Xml.parse(File.getContent('sdm.xml'));
		final config = Config.fromXmlElement(document.firstElement());
		config.installDependenciesWithProfile(profile);
	}

	private static function _addProfile(name:String) {
		if (!FileSystem.exists('sdm.xml') || FileSystem.isDirectory('sdm.xml'))
			_init();

		var document = Xml.parse(File.getContent('sdm.xml'));
		final configElement = document.firstElement();
		final config = Config.fromXmlElement(configElement);

		config.addProfile(name);

		document = Xml.createDocument();
		document.addChild(Xml.createDocType('sdm-config'));
		document.addChild(config.toXmlElement());
		File.saveContent('sdm.xml', Printer.print(document, true));
	}

	private static function _addHaxelib(name:String, version:String) {
		if (!FileSystem.exists('sdm.xml') || FileSystem.isDirectory('sdm.xml'))
			_init();

		var document = Xml.parse(File.getContent('sdm.xml'));
		final configElement = document.firstElement();
		final config = Config.fromXmlElement(configElement);

		if (profile != null) {
			config.addProfile(profile);
			config.getProfile(profile).addDependency(name, HAXELIB(version), skipDependencies);
		} else
			config.addDependency(name, HAXELIB(version), skipDependencies);

		document = Xml.createDocument();
		document.addChild(Xml.createDocType('sdm-config'));
		document.addChild(config.toXmlElement());
		File.saveContent('sdm.xml', Printer.print(document, true));
	}

	private static function _addGit(name:String, url:String, ?ref:String) {
		if (!FileSystem.exists('sdm.xml') || FileSystem.isDirectory('sdm.xml'))
			_init();

		var document = Xml.parse(File.getContent('sdm.xml'));
		final configElement = document.firstElement();
		final config = Config.fromXmlElement(configElement);

		if (profile != null) {
			config.addProfile(profile);
			config.getProfile(profile).addDependency(name, GIT(url, ref), skipDependencies);
		} else
			config.addDependency(name, GIT(url, ref), skipDependencies);

		document = Xml.createDocument();
		document.addChild(Xml.createDocType('sdm-config'));
		document.addChild(config.toXmlElement());
		File.saveContent('sdm.xml', Printer.print(document, true));
	}

	private static function _addDev(name:String, path:String) {
		if (!FileSystem.exists('sdm.xml') || FileSystem.isDirectory('sdm.xml'))
			_init();

		var document = Xml.parse(File.getContent('sdm.xml'));
		final configElement = document.firstElement();
		final config = Config.fromXmlElement(configElement);

		if (profile != null) {
			config.addProfile(profile);
			config.getProfile(profile).addDependency(name, DEV(path), skipDependencies);
		} else
			config.addDependency(name, DEV(path), skipDependencies);

		document = Xml.createDocument();
		document.addChild(Xml.createDocType('sdm-config'));
		document.addChild(config.toXmlElement());
		File.saveContent('sdm.xml', Printer.print(document, true));
	}
}
