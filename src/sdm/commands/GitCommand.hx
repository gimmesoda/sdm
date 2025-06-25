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
		final dependency = _addDependency(profile, params.name, DGit(params.others[0], params.others[1]), params.skipSubDeps);

		Config.write();

		if (params.others.length > 1)
			IO.showInfo('Added dependency ${params.name} (${params.others[0]}/${params.others[1]})');
		else
			IO.showInfo('Added dependency ${params.name} (${params.others[0]})');
	}
}
