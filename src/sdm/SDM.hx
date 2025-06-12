package sdm;

import sdm.commands.*;
import core.cli.Application;

class SDM extends Application {
	override function _setupCommands() {
		registerCommand(new HelpCommand());

		registerCommand(new SetupCommand());

		registerCommand(new InitCommand());
		registerCommand(new InstallCommand());

		registerCommand(new HaxelibCommand());
		registerCommand(new GitCommand());
		registerCommand(new DevCommand());
		registerCommand(new RemoveCommand());
	}
}
