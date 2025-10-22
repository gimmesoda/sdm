import tink.cli.Prompt;

class ProgressBar {
	public static inline var WIDTH:Int = 20;

	public var passed:Int = 0;
	public final total:Int;

	private var rendered:Bool = false;

	public function new(total:Int) {
		this.total = total;
	}

	public function render(prompt:Prompt) {
		if (rendered) {
			prompt.print('\x1b[0K');
			prompt.print('\x1b[u');
		}

		final progress:Float = passed / total;
		final filled:Int = Math.round(WIDTH * progress);
		
		prompt.print('\x1b[s');
		prompt.print('[');
		for (i in 0...filled) prompt.print('#');
		for (i in 0...WIDTH - filled) prompt.print(' ');
		prompt.print(']');

		rendered = true;
	}
}