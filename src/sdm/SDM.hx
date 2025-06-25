package sdm;

import sys.io.File;
import sys.FileSystem;
import core.cli.Application;

class SDM extends Application {
	override function _setupCommands() {
		#if !building_extension
		registerCommand(new sdm.commands.HelpCommand());
		registerCommand(new sdm.commands.SetupCommand());
		#end

		registerCommand(new sdm.commands.InitCommand());
		registerCommand(new sdm.commands.InstallCommand());

		registerCommand(new sdm.commands.HaxelibCommand());
		registerCommand(new sdm.commands.GitCommand());
		registerCommand(new sdm.commands.DevCommand());
		registerCommand(new sdm.commands.RemoveCommand());
	}
}
