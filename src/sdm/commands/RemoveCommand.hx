package sdm.commands;

import sdm.Config.ConfigPrinter;
import sys.io.File;
import sdm.Config.ConfigParser;
import sys.FileSystem;
import core.cli.Application;
import core.cli.commands.Command;

using StringTools;

class RemoveCommand extends Command {
	public function new() {
		super('remove', ['name'], 'Removes dependency');
	}

	public function execute(args:Array<String>, app:Application) {
		Sys.setCwd(app.workingDirectory);

		if (FileSystem.exists('sdm.xml') && !FileSystem.isDirectory('sdm.xml'))
			ConfigParser.parse(File.getContent('sdm.xml'));
		else
			return;

		var profile:Null<String> = null;
		var name:Null<String> = null;
		while (args.length > 0) {
			switch args.shift() {
				case '--profile' | '-p':
					profile = args.shift();
				case arg:
					name = arg;
			}
		}

		if (name == null)
			throw 'No name provided';

		final deps = profile != null ? Config.profiles.get(profile) : Config.dependencies;

		if (deps?.length < 1)
			return;

		final dep = Lambda.find(deps, dep -> dep.name == name);
		if (dep != null)
			deps.remove(dep);

		File.saveContent('sdm.xml', ConfigPrinter.print());

		IO.showInfo('Removed dependency $name');
	}
}
