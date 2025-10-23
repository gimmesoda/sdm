import tink.io.Worker;
import tink.cli.Prompt;

using StringTools;

class Installation {
	private static inline var PROGRESS_BAR_WIDTH:Int = 30;

	private var queue:Array<Dependency> = [];
	private var lockQueue:Bool = false;

	private var installed:Int = 0;

	private var worker:Worker;

	public function new() {
		worker = Worker.get();
	}

	public inline function add(dep:Dependency):Promise<Noise> {
		return worker.work(() -> !lockQueue
			? {
				queue.push(dep);
				Success(Noise);
			} : Failure(new Error(NotAcceptable, 'Queue is locked')));
	}

	public function run(prompt:Prompt) {
		if (queue.length == 0) {
			prompt.println('There are no dependencies');
			return;
		}

		lockQueue = false;

		prompt.println('Installing dependencies...');
		renderBar(prompt);

		final failed:Array<String> = [];

		for (dep in queue) dep.install(prompt).handle((result:Outcome<Noise, Error>) -> {
			switch result {
				case Failure(failure): failed.push(dep.name);
				default:
			}

			installed++;
			renderBar(prompt, false, installed == queue.length);
		});

		if (failed.length > 0) {
			prompt.printeln('Failed to install libraries:');
			for (f in failed) prompt.printeln('  > $f');
		} else
			prompt.printsln('All libraries installed successfully!');

		lockQueue = false;
	}

	private function renderBar(prompt:Prompt, firstTime:Bool = true, completed:Bool = false) {
		final filled:Int = Math.round(installed / queue.length * PROGRESS_BAR_WIDTH);
		final empty:Int = PROGRESS_BAR_WIDTH - filled;

		final bar:StringBuf = new StringBuf();
		bar.addChar('['.code);
		for (i in 0...filled) bar.addChar('#'.code);
		for (i in 0...empty) bar.addChar(' '.code);
		bar.addChar(']'.code);

		if (!firstTime) {
			prompt.print('\033[u');
			prompt.print('\033[0J');
		}
		prompt.print('\033[s');

		final message:String = '$bar  $installed / ${queue.length}';
		completed ? prompt.printsln(message) : prompt.println(message);
	}
}