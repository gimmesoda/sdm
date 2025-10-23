import tink.cli.prompt.SysPrompt;
import tink.Cli;

function main() {
	final args:Array<String> = Sys.args();
	// Sys.setCwd(args.pop());

	final prompt:SysPrompt = new SysPrompt();
	Cli.process(args, new App(prompt)).handle(Cli.exit);
}