import tink.Cli;
import tink.cli.Prompt;

class App {
	public function new() {}

	@:defaultCommand
	public inline function help(prompt:Prompt) {
		prompt.println(Cli.getDoc(this));
	}

	@:command
	public function setup(prompt:Prompt) {
		var haxePath:Null<String> = Sys.getEnv('HAXEPATH');
		if (haxePath == null) {
			prompt.println('\x1b[31mThe HAXEPATH variable is not set\x1b[39m');
			return;
		}
	}
}