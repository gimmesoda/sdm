package host;

using StringTools;

class Installation {
	private static inline var PROGRESS_BAR_WIDTH:Int = 30;

	private var queue:Array<Dependency> = [];
	private var lockQueue:Bool = false;

	private var installed:Int = 0;

	public function new() {}

	public inline function add(d:Dependency) {
		if (!lockQueue) queue.push(d);
	}

	public function run(cwd:String, global:Bool) {
		if (queue.length == 0) {
			Sys.println('There are no dependencies');
			return;
		}

		lockQueue = true;

		if (!global) Sys.command('haxelib', ['-cwd', cwd, 'newrepo']);

		Sys.println('Installing dependencies...');
		renderBar();

		final failures:Array<String> = [];

		for (dep in queue) {
			dep.install(cwd, global);

			installed++;
			renderBar(false, installed == queue.length);
		};

		if (failures.length > 0) {
			Sys.println('\033[31mFailed to install libraries:');
			for (f in failures) Sys.println('  > $f\033[39m');
		} else
			Sys.println('\033[32mAll libraries installed successfully!\033[39m');

		lockQueue = false;
	}

	private function renderBar(firstTime:Bool = true, completed:Bool = false) {
		final filled:Int = Math.round(installed / queue.length * PROGRESS_BAR_WIDTH);
		final empty:Int = PROGRESS_BAR_WIDTH - filled;

		final bar:StringBuf = new StringBuf();
		bar.addChar('['.code);
		for (i in 0...filled) bar.addChar('#'.code);
		for (i in 0...empty) bar.addChar(' '.code);
		bar.addChar(']'.code);

		if (!firstTime) {
			Sys.print('\033[u');
			Sys.print('\033[0J');
		}
		Sys.print('\033[s');

		final message:String = '$bar  $installed / ${queue.length}';
		completed ? Sys.println('\033[32m$message\033[39m') : Sys.println(message);
	}
}