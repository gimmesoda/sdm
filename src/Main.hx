import host.App;

function main() {
	final args:Array<String> = Sys.args();
	final cwd:String = args.pop();
	new App(cwd).run(args);
}