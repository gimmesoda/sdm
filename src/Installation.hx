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
		return worker.work(() -> lockQueue
			? Failure(new Error(NotAcceptable, 'Queue is locked'))
			: {
				queue.push(dep);
				Success(Noise);
			});
	}

	public function run(prompt:Prompt) {
		if (queue.length == 0) {
			prompt.println('There are no dependencies');
			return;
		}

		prompt.println('Installing dependencies...');
		renderBar(prompt);

		final errors:Array<Error> = [];

		for (dep in queue) dep.install().handle((result:Outcome<Noise, Error>) -> {
			switch result {
				case Failure(failure): errors.push(failure);
				default:
			}

			installed++;
			renderBar(prompt, false, installed == queue.length);
		});
		prompt.println('');

		if (errors.length > 0) {
			prompt.println('Errors occurred:');
			for (e in errors) prompt.println(e.toString());
		}
	}

	private function renderBar(prompt:Prompt, firstTime:Bool = true, completed:Bool = false) {
		final filled:Int = Math.round(installed / queue.length * PROGRESS_BAR_WIDTH);
		final empty:Int = PROGRESS_BAR_WIDTH - filled;

		final buf:StringBuf = new StringBuf();
		buf.addChar('['.code);
		for (i in 0...filled) buf.addChar('#'.code);
		for (i in 0...empty) buf.addChar(' '.code);
		buf.add('] ');

		if (!firstTime) {
			prompt.print('\x1b[u');
			prompt.print('\x1b[K');
		}
		prompt.print('\x1b[s');

		if (completed) prompt.print('\x1b[32m');

		prompt.print(buf.toString());
		prompt.print('$installed / ${queue.length}');

		if (completed) prompt.print('\x1b[39m');
	}
}