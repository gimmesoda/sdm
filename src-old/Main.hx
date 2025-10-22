import tink.Cli;

function main() {
	final args:Array<String> = Sys.args();
	// Sys.setCwd(args.pop());
	Cli.process(args, new Sdm()).handle(Cli.exit);
}