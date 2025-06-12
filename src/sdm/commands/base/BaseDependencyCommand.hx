package sdm.commands.base;

import sdm.Dependency.DependencyType;
import sys.io.File;
import sdm.Config.ConfigParser;
import sys.FileSystem;
import core.cli.Application;
import core.cli.commands.Command;

class BaseDependencyCommand extends Command {
	public function execute(args:Array<String>, app:Application) {
		Sys.setCwd(app.callDirectory);

		if (FileSystem.exists('sdm.xml') && !FileSystem.isDirectory('sdm.xml'))
			ConfigParser.parse(File.getContent('sdm.xml'));
	}

	private function _resolveParams(args:Array<String>):{
		skipSubDeps:Bool,
		profile:Null<String>,
		name:String,
		others:Array<String>
	} {
		var skipSubDeps = false;
		var profile:Null<String> = null;
		var name:Null<String> = null;
		var others:Array<String> = [];

		while (args.length > 0) {
			switch args.shift() {
				case '--profile' | '-p':
					profile = args.shift();
				case '--skip-sub-deps':
					skipSubDeps = true;
				case arg:
					if (name == null)
						name = arg;
					else
						others.push(arg);
			}
		}

		if (name == null)
			throw 'No name provided';

		return {
			skipSubDeps: skipSubDeps,
			profile: profile,
			name: name,
			others: others
		}
	}

	private function _resolveTargetProfile(profile:Null<String>):Array<Dependency> {
		return profile != null ? (Config.profiles.get(profile) ?? (Config.profiles[profile] = [])) : Config.dependencies;
	}

	private function _addDependency(profile:Array<Dependency>, name:String, type:DependencyType, skipSubDeps:Bool) {
		final dep = Lambda.find(profile, dep -> dep.name == name);
		if (dep != null) {
			dep.type = type;
			dep.skipSubDeps = skipSubDeps;
		} else
			profile.push({name: name, type: type, skipSubDeps: skipSubDeps});
	}
}
