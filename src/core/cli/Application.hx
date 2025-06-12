package core.cli;

import core.cli.commands.HelpCommand;
import core.cli.commands.Command;

using StringTools;

class Application {
	public var callDirectory(default, null):String;

	private var _commands:Array<Command>;

	public function new() {
		_commands = [];
		_setupCommands();
	}

	private function _setupCommands() {
		registerCommand(new HelpCommand());
	}

	public function registerCommand(newCmd:Command):Bool {
		if (Lambda.exists(_commands, cmd -> cmd.name == newCmd.name))
			return false;

		_commands.push(newCmd);
		return true;
	}

	public function run(args:Array<String>) {
		callDirectory = args.pop();

		final cmd = _resolveCommand(args) ?? Lambda.find(_commands, cmd -> cmd.name == 'help');
		args.remove(cmd.name);

		cmd.execute(args, this);
	}

	private function _resolveCommand(args:Array<String>):Null<Command> {
		for (arg in args) {
			if (arg.startsWith('-'))
				continue;

			return Lambda.find(_commands, cmd -> cmd.name == arg);
		}
		return null;
	}
}
