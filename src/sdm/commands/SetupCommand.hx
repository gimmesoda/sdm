package sdm.commands;

import haxe.io.Path;
import sys.io.File;
import core.cli.Application;
import core.cli.commands.Command;

using StringTools;

class SetupCommand extends Command {
	public function new() {
		super('setup', 'Creates shortcuts so you can type `sdm` instead of `haxelib run sdm`');
	}

	public function execute(args:Array<String>, app:Application) {
		final haxepath = Path.removeTrailingSlashes(Sys.getEnv('HAXEPATH'));

		if (Sys.systemName().toLowerCase().startsWith('windows')) {
			File.saveContent('$haxepath/sdm.cmd', '@haxelib --global run sdm %*');
			IO.showInfo('Created Windows shortcut');
		}

		File.saveContent('$haxepath/sdm', '#!/bin/sh\nhaxelib --global run sdm "$@"');
		IO.showInfo('Created Unix shortcut');
	}
}
