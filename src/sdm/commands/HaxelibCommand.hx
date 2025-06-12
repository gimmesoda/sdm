package sdm.commands;

import sdm.Config.ConfigPrinter;
import sys.io.File;
import core.cli.Application;
import sdm.commands.base.BaseDependencyCommand;

class HaxelibCommand extends BaseDependencyCommand {
	public function new() {
		super('haxelib', ['name', 'version?'], 'Adds Haxelib dependency');
	}

	override function execute(args:Array<String>, app:Application) {
		super.execute(args, app);

		final params = _resolveParams(args);

		final profile = _resolveTargetProfile(params.profile);
		_addDependency(profile, params.name, DHaxelib(params.others[0]), params.skipSubDeps);

		File.saveContent('sdm.xml', ConfigPrinter.print());

		Sys.println('Added dependency ${params.name} (${params.others[0]})');
	}
}
