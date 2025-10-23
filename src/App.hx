import tink.cli.Rest;
import sys.io.File;
import haxe.io.Path;
import tink.Cli;
import tink.cli.Prompt;

class App {
	@:flag('blind', '-b') @:alias(false) public var blind:Bool = false;

	public function new(prompt:Prompt) {
		final haxePath:Null<String> = Sys.getEnv('HAXEPATH');
		if (haxePath == null) {
			prompt.printeln('The HAXEPATH variable is not set');

			Sys.exit(1);
			return;
		}
	}

	@:defaultCommand
	public inline function help(prompt:Prompt) {
		prompt.println(Cli.getDoc(this));
	}

	@:command
	public function setup(prompt:Prompt) {
		var haxePath:String = Sys.getEnv('HAXEPATH');
		haxePath = Path.normalize(haxePath);

		if (Sys.systemName() == 'Windows') {
			File.saveContent('$haxePath/sdm.cmd', '@haxelib --global run sdm %*');
			prompt.println('$haxePath/sdm.cmd shortcut written');
		}

		File.saveContent('$haxePath/sdm', '#!/bin/sh\nhaxelib --global run sdm "$@"');
		prompt.println('$haxePath/sdm shortcut written');
	}

	@:command
	public function init(prompt:Prompt) {
		new Config().save(prompt);
	}

	@:command
	public function haxelib(name:String, args:Rest<String>, prompt:Prompt) {
		final config:Config = new Config();
		config.load(prompt);

		final version:Null<String> = args.shift();

		config.addDependency(name, DHaxelib(version), blind);
		config.save(prompt, true);
	}

	@:command
	public function git(name:String, url:String, args:Rest<String>, prompt:Prompt) {
		final config:Config = new Config();
		config.load(prompt);
		
		final ref:Null<String> = args.shift();
		final dir:Null<String> = args.shift();

		config.addDependency(name, DGit(url, ref, dir), blind);
		config.save(prompt, true);
	}

	@:command
	public inline function github(name:String, repo:String, args:Rest<String>, prompt:Prompt) {
		git(name, 'https://github.com/$repo.git', args, prompt);
	}

	@:command
	public inline function install(prompt:Prompt) {
		final config:Config = new Config();
		config.load(prompt);

		final inst:Installation = new Installation();
		for (d in config.getDependencies()) inst.add(d);

		inst.run(prompt);
	}
}