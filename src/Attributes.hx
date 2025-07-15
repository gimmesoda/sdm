import hxIni.IniManager;

class Attributes {
	public static var installProfile:Null<String>;

	public static function parse() {
		final path = '${Main.workingDirectory}/.sdmattributes.ini';
		final ini = IniManager.loadFromFile(path);
		if (ini == null) return;

		installProfile = ini['Global'].get('install-profile');
	}
}
