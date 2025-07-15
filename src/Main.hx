import sys.FileSystem;
import sys.io.File;
import Dependency.DependencyType;
import haxe.ds.Vector;
import haxe.io.Path;

using StringTools;

typedef Flags = {
	global:Bool,
	blind:Bool,
	?profile:String
}

class Main {
	public static var workingDirectory:String;

	static function main() {
		// it's like a pointer, got it?
		final args = new Vector<Array<String>>(1, Sys.args());

		workingDirectory = Path.normalize(args[0].pop());

		while (workingDirectory.fastCodeAt(workingDirectory.length - 1) == '/'.code)
			workingDirectory = workingDirectory.substr(0, workingDirectory.length - 1);

		final flags = _readFlags(args);

		switch args[0].shift() {
			case 'help':
				Sys.println('TODO: new help message');

			case 'setup':
				final haxepath = Path.removeTrailingSlashes(Sys.getEnv('HAXEPATH'));
				if (Sys.systemName().toLowerCase().startsWith('windows')) {
					File.saveContent('$haxepath/sdm.cmd', '@haxelib --global run sdm %*');
					Sys.println('Created Windows shortcut');
				}
				File.saveContent('$haxepath/sdm', '#!/bin/sh\nhaxelib --global run sdm "$@"');
				Sys.println('Created Unix shortcut');

			case 'init':
				if (!FileSystem.exists('$workingDirectory/sdm.xml'))
					File.saveContent('$workingDirectory/sdm.xml', '<!DOCTYPE sdm-config>\n<config/>');

			case 'haxelib':
				Config.parseOrThrow();
				final list = (flags.profile != null)
					? (Config.profiles[flags.profile] ??= [])
					: Config.dependencies;
				Config.addOrOverwrite(list, args[0].shift(), DHaxelib(args[0].shift().getStringOrNull()), flags.blind);
				Config.write();

			case 'git':
				Config.parseOrThrow();
				final list = (flags.profile != null)
					? (Config.profiles[flags.profile] ??= [])
					: Config.dependencies;
				Config.addOrOverwrite(list, args[0].shift(), DGit(args[0].shift(), args[0].shift().getStringOrNull()), flags.blind);
				Config.write();

			case 'dev':
				Config.parseOrThrow();
				final list = (flags.profile != null)
					? (Config.profiles[flags.profile] ??= [])
					: Config.dependencies;
				Config.addOrOverwrite(list, args[0].shift(), DDev(args[0].shift()), flags.blind);
				Config.write();

			case 'remove':
				Config.parseOrThrow();
				final list = (flags.profile != null)
					? (Config.profiles[flags.profile] ??= [])
					: Config.dependencies;
				if (list.length > 0) list.remove(Lambda.find(list, d -> d.name == args[0].shift()));
				Config.write();

			case 'install':
				Config.parseOrThrow();
				Attributes.parse();
				Sys.println('Current profile: ${flags.profile ?? Attributes.installProfile}');
				final list = (flags.profile != null || Attributes.installProfile != null)
					? Config.dependencies.concat(Config.profiles[flags.profile ?? Attributes.installProfile] ??= [])
					: Config.dependencies;

				if (!flags.global && list.length > 0 && !FileSystem.exists('$workingDirectory/.haxelib/'))
					Sys.command('haxelib', ['newrepo', '--cwd', workingDirectory]);

				for (dep in list) {
					switch dep.type {
						case DHaxelib(version):
							Sys.command('haxelib', ['--never', 'install', dep.name, '--cwd', workingDirectory]
								.concat(version != null ? [version] : [])
								.concat(flags.global ? ['--global'] : [])
								.concat(flags.blind ? ['--skip-dependencies'] : []));
						case DGit(url, ref):
							Sys.command('haxelib', ['--never', 'git', dep.name, url, '--cwd', workingDirectory]
								.concat(ref != null ? [ref] : [])
								.concat(flags.global ? ['--global'] : [])
								.concat(flags.blind ? ['--skip-dependencies'] : []));
						case DDev(path):
							Sys.command('haxelib', ['--never', 'dev', dep.name, path, '--cwd', workingDirectory]
								.concat(flags.global ? ['--global'] : [])
								.concat(flags.blind ? ['--skip-dependencies'] : []));
					}
				}
		}
	}

	static function _readFlags(args:Vector<Array<String>>):Flags {
		final flags:Flags = {
			global: false,
			blind: false
		}

		var i = 0;
		while (i < args[0].length) {
			switch args[0][i]?.toLowerCase() {
				case '-g' | '--global':
					flags.global = true;
					args[0].splice(i, 1);
				case '-b' | '--blind':
					flags.blind = true;
					args[0].splice(i, 1);
				case '-p' | '--profile':
					flags.profile = args[0][i + 1];
					args[0].slice(i, 2);
				case '--skip-sub-deps' | '--skip-dependencies':
					Sys.println('${args[0][i]} is deprecated, use -b/--blind instead');
					flags.blind = true;
					args[0].splice(i, 1);
				case _:
					i++;
			}
		}

		return flags;
	}
}
