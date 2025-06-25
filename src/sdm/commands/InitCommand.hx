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
		final path = Path.join([app.workingDirectory, 'sdm.xml']);

		if (FileSystem.exists(path) && !FileSystem.isDirectory(path)) {
			IO.ask('Overwrite file `sdm.xml`?', r -> if (r) {
				File.saveContent(path, '<!DOCTYPE sdm-config>\n<config/>');
				IO.showInfo('File `sdm.xml` overwritten');
			});
		} else {
			File.saveContent(path, '<!DOCTYPE sdm-config>\n<config/>');
			IO.showInfo('File `sdm.xml` created');
		}
	}
}
