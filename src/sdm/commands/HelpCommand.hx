package sdm.commands;

import sys.io.File;
import haxe.Json;
import core.cli.Application;
import core.cli.commands.HelpCommand as CoreHelpCommand;

using StringTools;

class HelpCommand extends CoreHelpCommand {
	@:access(core.cli.Application._commands)
	override function execute(args:Array<String>, app:Application) {
		var buf = new StringBuf();

		buf.add('\n░░      ░░░       ░░░  ░░░░  ░');
		buf.add('\n▒  ▒▒▒▒▒▒▒▒  ▒▒▒▒  ▒▒   ▒▒   ▒');
		buf.add('\n▓▓      ▓▓▓  ▓▓▓▓  ▓▓        ▓');
		buf.add('\n███████  ██  ████  ██  █  █  █');
		buf.add('\n██      ███       ███  ████  █');

		final haxelib = Json.parse(File.getContent('haxelib.json'));
		buf.add('\n\nSoda\'s Dependency Manager cheat sheet (${haxelib.version})');

		var nameLength = 10;
		for (cmd in app._commands) {
			final cmdName = cmd.buildNameString();
			nameLength = nameLength > cmdName.length ? nameLength : cmdName.length;
		}

		buf.add('\n\nCommands:');
		for (cmd in app._commands) {
			buf.addChar('\n'.code);
			buf.add(cmd.buildHelpString(nameLength));
		}

		final flagDocs = [
			['--global/-g', 'Installs dependencies globally'],
			['--profile/-p', 'Selects a profile'],
			['--skip-sub-deps', 'Skips sub-dependencies']
		];

		for (flagDoc in flagDocs)
			nameLength = nameLength > flagDoc[0].length ? nameLength : flagDoc[0].length;

		buf.add('\n\nFlags:');
		for (flagDoc in flagDocs) {
			buf.addChar('\n'.code);
			buf.add(flagDoc[0].rpad(' ', nameLength));
			buf.add('  ');
			buf.add(flagDoc[1]);
		}
		Sys.println(buf.toString());
	}
}
