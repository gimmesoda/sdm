package host;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class App {
	public final cwd:String;

	public function new(cwd:String) {
		this.cwd = cwd;
	}

	public function run(callArgs:Array<String>) {
		var command:Null<String> = null;
		var args:Array<String> = [];

		var blind:Bool = false;
		var profile:Null<String> = null;
		// Only for install
		var global:Bool = false;

		while (callArgs.length > 0) switch callArgs.shift() {
			case flag if (flag.startsWith('-')):
				switch flag {
					case '--blind' | '-b': blind = true;
					case '--profile' | '-p': profile = callArgs.shift();
					case '--global' | '-g': global = true;
				}

			case cmd if (command == null): command = cmd;

			case arg: args.push(arg);
		}

		switch command {
			case 'setup':
				if (!checkArgs(command, args, 0, 0)) return;
				setupShortcuts();

			case 'init':
				if (!checkArgs(command, args, 0, 0)) return;
				initConfig();

			case 'haxelib':
				if (!checkArgs(command, args, 1, 2)) return;
				addHaxelibDependency(args.shift(), args.shift(), blind, profile);

			case 'git':
				if (!checkArgs(command, args, 2, 4)) return;
				addGitDependency(args.shift(), args.shift(), args.shift(), args.shift(), blind, profile);

			case 'github':
				if (!checkArgs(command, args, 2, 4)) return;
				addGitDependency(args.shift(), 'https://github.com/${args.shift()}.git', args.shift(), args.shift(), blind, profile);

			case 'remove':
				if (!checkArgs(command, args, 1, 1)) return;
				removeDependency(args.shift(), profile);

			case 'list':
				if (!checkArgs(command, args, 0, 0)) return;
				listDependencies(profile);

			case 'install':
				if (!checkArgs(command, args, 0, 0)) return;
				installDependencies(global, profile);

			case 'help':
				if (!checkArgs(command, args, 0, 1)) return;
				showHelp(args.shift());

			default:
				showHelp(args.shift());
		}
	}

	public function setupShortcuts() {
		var haxePath:Null<String> = Sys.getEnv('HAXEPATH');
		if (haxePath != null) haxePath = Path.normalize(haxePath);
		else {
			Sys.println('\033[31mCould not resolve Haxe path\033[39m');
			return;
		}

		if (isWin()) {
			File.copy('res/shortcuts/sdm.cmd', '$haxePath/sdm.cmd');
			Sys.println('\033[32m$haxePath/sdm.cmd created successfully!\033[39m');
		}

		File.copy('res/shortcuts/sdm', '$haxePath/sdm');
		Sys.println('\033[32m$haxePath/sdm created successfully!\033[39m');
	}

	public function initConfig() {
		new Config().saveXml(cwd, false);
	}

	public function addHaxelibDependency(name:String, ?version:String, blind:Bool, ?profile:String) {
		final config:Config = new Config();
		config.loadXml(cwd);
		config.addDependency(name, DHaxelib(version), blind, profile);
		config.saveXml(cwd, true);
	}

	public function addGitDependency(name:String, url:String, ?ref:String, ?dir:String, blind:Bool, ?profile:String) {
		final config:Config = new Config();
		config.loadXml(cwd);
		config.addDependency(name, DGit(url, ref, dir), blind, profile);
		config.saveXml(cwd, true);
	}

	public function removeDependency(name:String, ?profile:String) {
		final config:Config = new Config();
		config.loadXml(cwd);
		config.removeDependency(name, profile);
		config.saveXml(cwd, true);
	}

	public function listDependencies(?profile:String) {
		for (d in getDependencies(profile)) Sys.println(' > $d');
	}

	public function installDependencies(global:Bool, ?profile:String) {
		final inst:Installation = new Installation();
		for (d in getDependencies(profile)) inst.add(d);
		inst.run(cwd, global);
	}

	private function getDependencies(?profile:String):Dependencies {
		final config:Config = new Config();
		config.loadXml(cwd);

		final deps:Dependencies = @:privateAccess config.main.copy();
		if (profile != null && @:privateAccess config.profiles.exists(profile)) {
			for (d in @:privateAccess config.profiles[profile])
				deps.add(d.name, @:privateAccess d.kind, @:privateAccess d.blind);
		}
		return deps;
	}

	public function showHelp(?cmd:String) {
		var helpPath:String = 'res/help';
		var commandHelp:String = '$helpPath/commands/$cmd.ansi';
		if (!FileSystem.exists(commandHelp))
			commandHelp = '$helpPath/general.ansi';

		final message:String = File.getContent(commandHelp).trim();
		Sys.println('$message\n');
	}

	private function checkArgs(cmd:String, args:Array<String>, min:Int, max:Int):Bool {
		if (args.length < min || args.length > max) {
			showHelp(cmd);
			return false;
		}
		return true;
	}

	private static var systemName:String;
	private static inline function isWin():Bool {
		systemName ??= Sys.systemName();
		return systemName == 'Windows';
	}
}