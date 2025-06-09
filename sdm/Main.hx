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
		var recievedCommand = false;

		var job:Null<() -> Void> = null;

		Sys.setCwd(args.pop());

		while (args.length > 0) {
			switch args.shift().toLowerCase() {
				case 'setup' if (!recievedCommand):
					job = _setup;
					recievedCommand = true;

				case 'init' if (!recievedCommand):
					job = _init;
					recievedCommand = true;

				case 'install' if (!recievedCommand):
					job = _install;
					recievedCommand = true;

				case 'haxelib' if (!recievedCommand):
					job = _haxelib.bind(args.shift(), (args.length > 0 && !args[0].startsWith('-')) ? args.shift() : null);
					recievedCommand = true;

				case 'git' if (!recievedCommand):
					job = _git.bind(args.shift(), args.shift(), (args.length > 0 && !args[0].startsWith('-')) ? args.shift() : null);
					recievedCommand = true;

				case 'dev' if (!recievedCommand):
					job = _dev.bind(args.shift(), args.shift());
					recievedCommand = true;

				case 'remove' if (!recievedCommand):
					job = _remove.bind(args.shift());
					recievedCommand = true;

				case 'add' if (!recievedCommand):
					Sys.print('`add ${args[0]}` is deprecated and will be removed, ');
					switch args.shift() {
						case 'haxelib':
							job = _haxelib.bind(args.shift(), (args.length > 0 && !args[0].startsWith('-')) ? args.shift() : null);
							recievedCommand = true;
							Sys.println('use `haxelib` instead');

						case 'git':
							job = _git.bind(args.shift(), args.shift(), (args.length > 0 && !args[0].startsWith('-')) ? args.shift() : null);
							recievedCommand = true;
							Sys.println('use `git` instead');

						case 'dev':
							job = _dev.bind(args.shift(), args.shift());
							recievedCommand = true;
							Sys.println('use `dev` instead');
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
		else {
			_printHelp();
		}
	}

	private static function _printHelp() {
		Sys.println('Soda\'s Dependency Manager (SDM)');
		Sys.println('Usage: sdm [command] [options]\n');
		Sys.println('Commands:');
		Sys.println('  setup                      Creates global shortcut');
		Sys.println('  init                       Creates basic config (sdm.xml)');
		Sys.println('  install                    Installs dependencies');
		Sys.println('  haxelib [name] [version?]  Adds Haxelib dependency');
		Sys.println('  git [name] [url] [ref?]    Adds Git dependency');
		Sys.println('  dev [name] [path]          Adds local development dependency');
		Sys.println('  remove [name]              Removes dependency\n');
		Sys.println('Options:');
		Sys.println('  -p, --profile [name]       Target specific profile');
		Sys.println('  -g, --global               Install dependencies globally');
		Sys.println('  --skip-dependencies        Skip installing sub-dependencies\n');
		Sys.println('Examples:');
		Sys.println('  sdm haxelib hscript 2.6.0 -p dev');
		Sys.println('  sdm git heaps https://github.com/HeapsIO/heaps.git');
		Sys.println('  sdm install -p dev --global');
	}

	private static function _setup() {
		File.saveContent(Path.join([Sys.getEnv('HAXEPATH'), 'sdm.cmd']), '@haxelib --global run sdm %*');
	}

	private static function _init() {
		File.saveContent('sdm.xml', '<!DOCTYPE sdm-config>\n<config></config>');
	}

	private static function _install() {
		if (!FileSystem.exists('sdm.xml') || FileSystem.isDirectory('sdm.xml')) {
			Sys.println('sdm.xml not initialized!');
			return;
		}

		if (!isGlobal)
			FileSystem.createDirectory('.haxelib');

		final document = Xml.parse(File.getContent('sdm.xml'));

		final config = Config.fromXmlElement(document.firstElement());
		config.installDependenciesWithProfile(profile);
		Sys.println('Current libraries:');
		Sys.command('haxelib', ['list']);
	}

	private static function _haxelib(name:String, version:String) {
		var document = (!FileSystem.exists('sdm.xml') || FileSystem.isDirectory('sdm.xml')) ? Xml.createDocument() : Xml.parse(File.getContent('sdm.xml'));

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

		if (profile != null)
			Sys.println('Added haxelib dependency $name to $profile');
		else
			Sys.println('Added haxelib dependency $name');
	}

	private static function _git(name:String, url:String, ?ref:String) {
		var document = (!FileSystem.exists('sdm.xml') || FileSystem.isDirectory('sdm.xml')) ? Xml.createDocument() : Xml.parse(File.getContent('sdm.xml'));

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

		if (profile != null)
			Sys.println('Added git dependency $name to $profile');
		else
			Sys.println('Added git dependency $name');
	}

	private static function _dev(name:String, path:String) {
		var document = (!FileSystem.exists('sdm.xml') || FileSystem.isDirectory('sdm.xml')) ? Xml.createDocument() : Xml.parse(File.getContent('sdm.xml'));

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

		if (profile != null)
			Sys.println('Added dev dependency $name to $profile');
		else
			Sys.println('Added dev dependency $name');
	}

	private static function _remove(name:String) {
		if (!FileSystem.exists('sdm.xml') || FileSystem.isDirectory('sdm.xml')) {
			Sys.println('sdm.xml not initialized!');
			return;
		}

		var document = Xml.parse(File.getContent('sdm.xml'));
		final configElement = document.firstElement();
		final config = Config.fromXmlElement(configElement);

		if (profile != null)
			config.getProfile(profile).removeDependency(name);
		else
			config.removeDependency(name);

		config.removeEmptyProfiles();

		document = Xml.createDocument();
		document.addChild(Xml.createDocType('sdm-config'));
		document.addChild(config.toXmlElement());
		File.saveContent('sdm.xml', Printer.print(document, true));

		if (profile != null)
			Sys.println('Removed dependency $name from $profile');
		else
			Sys.println('Removed dependency $name');
	}
}
