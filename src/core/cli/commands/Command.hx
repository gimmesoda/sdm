package core.cli.commands;

using StringTools;

abstract class Command {
	public final name:String;
	public final params:Null<Array<String>>;
	public final doc:Null<String>;

	public function new(name:String, ?params:Array<String>, ?doc:String) {
		if (name.startsWith('-') || name.contains(' '))
			throw 'Command name cannot be set to $name';

		this.name = name;
		this.params = params;
		this.doc = doc;
	}

	public abstract function execute(args:Array<String>, app:Application):Void;

	public function buildHelpString(nameLength:Int):String {
		if (doc != null)
			return '${buildNameString().rpad(' ', nameLength)}  $doc';
		return buildNameString();
	}

	public function buildNameString():String {
		var nameString = '$name';
		if (params?.length > 0) {
			for (param in params)
				nameString += ' [$param]';
		}
		return nameString;
	}
}
