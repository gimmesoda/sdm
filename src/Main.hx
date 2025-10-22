import tink.cli.prompt.SysPrompt;
import tink.Cli;

function main() {
	// final args:Array<String> = Sys.args();
	// // Sys.setCwd(args.pop());
	// Cli.process(args, new App()).handle(Cli.exit);

	final inst:Installation = new Installation();
	inst.add(new Dependency('hscript', DHaxelib()));
	inst.add(new Dependency('hldiscord_rpc', DGit('https://github.com/gimmesoda/hldiscord_rpc')));
	inst.run(new SysPrompt());
}