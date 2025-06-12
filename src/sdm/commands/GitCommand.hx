package sdm.commands;

import sdm.Config.ConfigPrinter;
import sys.io.File;
import core.cli.Application;
import sdm.commands.base.BaseDependencyCommand;

class GitCommand extends BaseDependencyCommand {
	public function new() {
		super('git', ['name', 'url', 'ref?'], 'Adds Git dependency');
	}

	override function execute(args:Array<String>, app:Application) {
		super.execute(args, app);

		final params = _resolveParams(args);

		final profile = _resolveTargetProfile(params.profile);
		_addDependency(profile, params.name, DGit(params.others[0], params.others[1]), params.skipSubDeps);

		File.saveContent('sdm.xml', ConfigPrinter.print());

		if (params.others.length > 1)
			Sys.println('Added dependency ${params.name} (${params.others[0]}/${params.others[1]})');
		else
			Sys.println('Added dependency ${params.name} (${params.others[0]})');
	}
}
