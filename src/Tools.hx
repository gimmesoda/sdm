using StringTools;

class Tools {
	public static function getStringOrNull(s:String):Null<String> {
		return s?.trim()?.length > 0 ? s : null;
	}
}
