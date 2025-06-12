package sdm.commands;

import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import core.cli.Application;
import core.cli.commands.Command;

class InitCommand extends Command {
	public function new() {
		super('init', 'Creates `sdm.xml` that stores information about all dependencies');
	}

	public function execute(args:Array<String>, app:Application) {
		final path = Path.join([app.callDirectory, 'sdm.xml']);

		if (FileSystem.exists(path) && !FileSystem.isDirectory(path)) {
			Sys.print('Overwrite `sdm.xml`? [y/n]: ');
			if (Sys.stdin().readLine().toLowerCase().charAt(0) != 'y')
				return;
		}

		File.saveContent(path, '<!DOCTYPE sdm-config>\n<config/>');
		Sys.println('Created `sdm.xml`');
	}
}
