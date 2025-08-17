import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

using StringTools;
using Tools;

typedef Flags = {
	global:Bool,
	blind:Bool,
	?profile:String
}

class Main {
	public static var workingDirectory:String;

	private static function main() {
		// it's like a pointer, got it?
		final args = Sys.args();

		workingDirectory = Path.normalize(args.pop());

		while (workingDirectory.fastCodeAt(workingDirectory.length - 1) == '/'.code)
			workingDirectory = workingDirectory.substr(0, workingDirectory.length - 1);

		final flags = _readFlags(args);

		switch args.shift() {
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
				final profile = (flags.profile != null)
					? (Config.profiles[flags.profile] ??= { dependencies: [], tasks: [] })
					: Config.global;
				Config.addOrOverwriteDependency(profile, args.shift(), DHaxelib(args.shift().getStringOrNull()), flags.blind);
				Config.write();

			case 'git':
				Config.parseOrThrow();
				final profile = (flags.profile != null)
					? (Config.profiles[flags.profile] ??= { dependencies: [], tasks: [] })
					: Config.global;
				Config.addOrOverwriteDependency(profile, args.shift(), DGit(args.shift(), args.shift().getStringOrNull(), args.shift().getStringOrNull()), flags.blind);
				Config.write();

			case 'dev':
				Config.parseOrThrow();
				final profile = (flags.profile != null)
					? (Config.profiles[flags.profile] ??= { dependencies: [], tasks: [] })
					: Config.global;
				Config.addOrOverwriteDependency(profile, args.shift(), DDev(args.shift()), flags.blind);
				Config.write();

			case 'remove':
				Config.parseOrThrow();
				if (flags.profile == null || Config.profiles.exists(flags.profile)) {
					final profile = flags.profile != null ? Config.profiles[flags.profile] : Config.global;
					if (profile.dependencies.length > 0) profile.dependencies.remove(Lambda.find(profile.dependencies, d -> d.name == args.shift()));
				}
				Config.write();

			case 'task':
				Config.parseOrThrow();
				final profile = (flags.profile != null)
					? (Config.profiles[flags.profile] ??= { dependencies: [], tasks: [] })
					: Config.global;
				Config.addTask(profile, args.shift(), args.shift());
				Config.write();

			case 'install':
				Config.parseOrThrow();
				Attributes.parse();
				Sys.println('Current profile: ${flags.profile ?? Attributes.installProfile}');
				if (flags.profile == null || Config.profiles.exists(flags.profile)) {
					final customProfile = flags.profile != null;
					final profile = customProfile ? Config.profiles[flags.profile] : Config.global;

					if (!flags.global && profile.dependencies.length > 0 && !FileSystem.exists('$workingDirectory/.haxelib/'))
					Sys.command('haxelib', ['-cwd', workingDirectory, 'newrepo']);

					for (dep in (customProfile ? profile.dependencies.concat(Config.global.dependencies) : profile.dependencies)) {
						switch dep.type {
							case DHaxelib(version):
								var args = getHaxelibStartArgs(flags, dep, true).concat([ 'install', dep.name ]);
								if (version != null) args.push(version);
								Sys.command('haxelib', args);
							case DGit(url, ref, dir):
								var args = getHaxelibStartArgs(flags, dep, true).concat([ 'git', dep.name, url ]);
								if (ref != null) args.push(ref);
								if (dir != null) args.push(dir);
								Sys.command('haxelib', args);
							case DDev(path):
								var args = getHaxelibStartArgs(flags, dep, false).concat([ 'dev', dep.name, path ]);
								Sys.command('haxelib', args);
						}
					}

					for (tsk in (customProfile ? profile.tasks.concat(Config.global.tasks) : profile.tasks))
						runTask(tsk);
				}
		}
	}

	private static function runTask(task:Task) {
		if (task.dir.getStringOrNull() != null && Path.isAbsolute(task.dir)) {
			Sys.println('SYSTEM VIOLATION: `${task.cmd}` in `${task.dir}` blocked');
			return;
		}
		final dir = task.dir == null ? workingDirectory : Path.join([ workingDirectory, task.dir ]);
		if (!dir.startsWith(workingDirectory)) {
			Sys.println('SYSTEM VIOLATION: `${task.cmd}` in `$dir` blocked');
			return;
		}

		final cwd = Sys.getCwd();
		Sys.setCwd(dir);
		Sys.command(task.cmd);
		Sys.setCwd(cwd);
	}

	private static function getHaxelibStartArgs(flags:Flags, dep:Dependency, never:Bool):Array<String> {
		var args = [ '-cwd', workingDirectory ];
		if (never)
			args.push('--never');
		if (flags.global) args.push('--global');
		if (flags.blind || dep.blind) args.push('--skip-dependencies');
		return args;
	}

	private static function _readFlags(args:Array<String>):Flags {
		final flags:Flags = {
			global: false,
			blind: false
		}

		var i = 0;
		while (i < args.length) {
			switch args[i]?.toLowerCase() {
				case '-g' | '--global':
					flags.global = true;
					args.splice(i, 1);
				case '-b' | '--blind':
					flags.blind = true;
					args.splice(i, 1);
				case '-p' | '--profile':
					flags.profile = args[i + 1];
					args.splice(i, 2);
				case '--skip-sub-deps' | '--skip-dependencies':
					Sys.println('${args[i]} is deprecated, use -b/--blind instead');
					flags.blind = true;
					args.splice(i, 1);
				default:
					i++;
			}
		}

		return flags;
	}
}
