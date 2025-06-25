package sdm;

import sys.io.File;
import hxIni.IniManager;
import sys.FileSystem;

class Attributes {
	public static var installProfile:Null<String>;

	public static function read() {
		if (!FileSystem.exists('.sdmattributes.ini') || FileSystem.isDirectory('.sdmattributes.ini'))
			return;

		final ini = IniManager.loadFromString(File.getContent('.sdmattributes.ini'));
		installProfile = ini['Global'].get('install-profile');
	}
}
