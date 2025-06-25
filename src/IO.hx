class IO {
	public static function ask(msg:Dynamic, callback:(Bool) -> Void, defaultResult:Bool = false) {
		Sys.stdout().writeString('$msg [${defaultResult ? 'Y/n' : 'y/N'}]: ');
		Sys.stdout().flush();
		final input = Sys.stdin().readLine().toLowerCase().charAt(0);
		callback(defaultResult ? input != 'n' : input == 'y');
	}

	public static function showInfo(msg:Dynamic) {
		Sys.stdout().writeString('$msg\n');
		Sys.stdout().flush();
	}

	public static function showWarning(msg:Dynamic) {
		Sys.stderr().writeString('$msg\n');
		Sys.stderr().flush();
	}

	public static function showError(msg:Dynamic) {
		Sys.stderr().writeString('$msg\n');
		Sys.stderr().flush();
	}
}
