package core.cli.commands;

class HelpCommand extends Command {
	public function new() {
		super('help', 'Prints this message');
	}

	@:access(core.cli.Application._commands)
	public function execute(args:Array<String>, app:Application) {
		var nameLength = 10;
		for (cmd in app._commands) {
			final cmdName = cmd.buildNameString();
			nameLength = nameLength > cmdName.length ? nameLength : cmdName.length;
		}

		var buf = new StringBuf();
		buf.add('\nCommands:');
		for (cmd in app._commands) {
			buf.addChar('\n'.code);
			buf.add(cmd.buildHelpString(nameLength));
		}

		IO.showInfo(buf.toString());
	}
}
