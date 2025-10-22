import tink.io.Worker;
import tink.core.Noise;
import tink.core.Promise;
import sys.io.Process;
import Config.Dependency;
import tink.Cli;
import tink.core.Error;
import tink.Stringly;
import tink.core.Outcome;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import tink.cli.Prompt;

using StringTools;

class Sdm {
	/** (install) Install dependencies into the global Haxelib repository **/
	@:flag('global', '-g') @:alias(false) public var global:Bool = false;

	/** (haxelib/git/github) Skip subdependencies during installation **/
	@:flag('blind', '-b') @:alias(false) public var blind:Bool = false;

	/** (haxelib/git/github, install) Set working profile **/
	@:flag('profile', '-p') @:alias(false) public var profile:Null<String> = null;

	/** (haxelib/git/github) Prevent library from installing **/
	@:flag('no-install', '-ni') @:alias(false) public var noInstall:Bool = false;

	/** (haxelib) Set haxelib dependency version **/
	@:flag('-v') @:alias(false) public var haxelibVer:Null<String> = null;

	/** (git/github) Set git dependency reference **/
	@:flag('-ref') @:alias(false) public var gitRef:Null<String> = null;
	/** (git/github) Set git dependency directory **/
	@:flag('-dir') @:alias(false) public var gitDir:Null<String> = null;

	private var worker:Worker;

	public function new() {
		worker = Worker.get();
	}

	@:defaultCommand
	public function help(prompt:Prompt) {
		prompt.println(Cli.getDoc(this));
	}

	/** Create shortcuts in the Haxe installation path **/
	@:command
	public function setup(prompt:Prompt) {
		var haxePath:String = Sys.getEnv('HAXEPATH');
		haxePath = Path.normalize(haxePath);

		// Create Windows shortcut
		if (Sys.systemName() == 'Windows') {
			File.saveContent('$haxePath/sdm.cmd', '@haxelib --global run sdm %*');
			prompt.println('$haxePath/sdm.cmd shortcut written');
		}

		// Create Unix shortcut
		File.saveContent('$haxePath/sdm', '#!/bin/sh\nhaxelib --global run sdm "$@"');
		prompt.println('$haxePath/sdm shortcut written');
	}

	/** Create a configuration file **/
	@:command
	public function init(prompt:Prompt) {
		// Create non-existing config
		if (!FileSystem.exists('sdm.xml')) return new Config().write(prompt);

		prompt.println('sdm.xml already exists');
		// Ask user to overwrite config
		prompt.prompt('overwrite sdm.xml? [y/N]')
			.handle((result:Outcome<Stringly, Error>) -> switch result {
					case Success(data):
						// Overwrite file
						if ((data : String).toLowerCase().trim() == 'y') new Config().write(prompt);
					case Failure(failure):
						// Print error
						prompt.println(failure.toString());
				});
	}

	/** Add haxelib dependency **/
	@:command
	public function haxelib(name:String, prompt:Prompt) {
		final config:Config = new Config().parse(prompt);
		// Resolve working list
		final list:Array<Dependency> = profile == null ? config.global : (config.profiles[profile] ??= []);
		list.push({
			kind: DHaxelib(name, haxelibVer),
			blind: blind
		});
		config.write(prompt);
	}

	/** Add git dependency **/
	@:command
	public function git(name:String, url:String, prompt:Prompt) {
		final config:Config = new Config().parse(prompt);
		// Resolve working list
		final list:Array<Dependency> = profile == null ? config.global : (config.profiles[profile] ??= []);
		list.push({
			kind: DGit(name, url, gitRef, gitDir),
			blind: blind
		});
		config.write(prompt);
	}

	/** Shortcut to add github dependency **/
	@:command
	public function github(repo:String, prompt:Prompt) {
		if (!repo.contains('/')) {
			prompt.println('Invalid GitHub repo');
			return;
		}
		final name:String = repo.substring(repo.indexOf('/') + 1);
		git(name, 'https://github.com/$repo', prompt);
	}

	@:command
	public function install(prompt:Prompt) {
		if (!FileSystem.exists('sdm.xml')) {
			prompt.println('No config provided');
			return;
		}

		if (!global && !FileSystem.exists('.haxelib/')) {
			FileSystem.createDirectory('.haxelib');
			prompt.println('Local Haxelib repo created');
		}

		final config:Config = new Config().parse(prompt);

		var total:Int = config.global.length;
		if (profile != null && config.profiles.exists(profile))
			total += config.profiles[profile].length;

		final progressBar:ProgressBar = new ProgressBar(total);
		progressBar.render(prompt);

		// Install global dependencies
		for (d in config.global) {
			installDependency(d)
				.handle((result:Outcome<Noise, Error>) -> {
					progressBar.passed++;
					progressBar.render(prompt);
				});
		}
		// Install profile dependencies
		if (profile != null && config.profiles.exists(profile)) {
			for (d in config.profiles[profile]) {
				installDependency(d)
					.handle((result:Outcome<Noise, Error>) -> {
						progressBar.passed++;
						progressBar.render(prompt);
					});
			}
		}
	}

	private function installDependency(dependency:Dependency):Promise<Noise> {
		final args:Array<String> = switch dependency.kind {
			case DHaxelib(name, version): ['install', name, version ?? ''];
			case DGit(name, url, ref, dir): ['git', name, url, ref ?? '', dir ?? ''];
		}
		if (dependency.blind) args.push('--skip-dependencies');

		return worker.work(() -> {
			final haxelib:Process = new Process('haxelib', args);
			// Wait for dependency to install
			haxelib.exitCode();
			return Success(Noise);
		});
	}
}