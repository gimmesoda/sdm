package sdm.commands;

import sys.io.File;
import sdm.Config.ConfigParser;
import sys.FileSystem;
import core.cli.Application;
import core.cli.commands.Command;

class InstallCommand extends Command {
	public function new() {
		super('install', 'Install dependencies');
	}

	public function execute(args:Array<String>, app:Application) {
		var global:Bool = false;
		var profile:Null<String> = null;

		while (args.length > 0) {
			switch args.shift() {
				case '--global' | '-g':
					global = true;
				case '--profile' | '-p':
					profile = args.shift();
			}
		}

		Sys.setCwd(app.callDirectory);

		if (FileSystem.exists('sdm.xml') && !FileSystem.isDirectory('sdm.xml'))
			ConfigParser.parse(File.getContent('sdm.xml'));
		else
			throw '`sdm.xml` not found';

		var deps = Config.dependencies;
		if (profile != null && Config.profiles.exists(profile))
			deps = deps.concat(Config.profiles[profile]);

		if (deps.length == 0)
			return;

		Sys.setCwd(app.callDirectory);
		if (!global)
			Sys.command('haxelib', ['newrepo']);

		for (dep in deps) {
			var cmdArgs:Array<String> = global ? ['--global'] : [];
			if (dep.skipSubDeps)
				cmdArgs.push('--skip-dependencies');
			switch dep.type {
				case DHaxelib(version):
					cmdArgs = cmdArgs.concat(['install', dep.name]);
					if (version != null)
						cmdArgs.push(version);
				case DGit(url, ref):
					cmdArgs = cmdArgs.concat(['git', dep.name, url]);
					if (ref != null)
						cmdArgs.push(ref);
				case DDev(path):
					cmdArgs = cmdArgs.concat(['dev', dep.name, path]);
			}
			Sys.command('haxelib', cmdArgs);
		}

		for (dep in deps) {
			switch dep.type {
				case DHaxelib(version) if (version != null):
					Sys.command('haxelib', ['set', dep.name, version]);
				case DGit(_, _):
					Sys.command('haxelib', ['set', dep.name, 'git']);
				case _:
			}
		}
	}
}
