package sdm;

import sdm.Dependency.DependencyType;

class Profile {
	private var _dependencies:Array<Dependency>;

	public function new() {
		_dependencies = [];
	}

	public static function fromXmlElement(element:Xml):Profile {
		if (element.nodeName != 'profile')
			throw '${element.nodeName} should be profile';

		final profile = new Profile();

		for (dependencyElement in element.elementsNamed('dependency')) {
			try {
				final name = dependencyElement.get('name');
				final type = switch dependencyElement.get('type') {
					case 'haxelib':
						HAXELIB(dependencyElement.exists('version') ? dependencyElement.get('version') : null);
					case 'git':
						GIT(dependencyElement.get('url'), dependencyElement.exists('ref') ? dependencyElement.get('ref') : null);
					case 'dev':
						DEV(dependencyElement.get('path'));
					case _: throw 'Invalid dependency $name type';
				}
				final skipDependencies = dependencyElement.exists('skip-dependencies')
					&& dependencyElement.get('skip-dependencies') == 'true';

				profile.addDependency(name, type, skipDependencies);
			}
		}

		return profile;
	}

	public function addDependency(name:String, type:DependencyType, skipDependencies:Bool) {
		for (dependency in _dependencies) {
			if (dependency.name == name) {
				dependency.set(name, type, skipDependencies);
				return;
			}
		}
		_dependencies.push(new Dependency(name, type, skipDependencies));
	}

	public inline function installDependencies() {
		for (dependency in _dependencies)
			dependency.install();
	}

	public function toXmlElement():Xml {
		final element = Xml.createElement('profile');

		for (dependency in _dependencies) {
			final dependencyElement = Xml.createElement('dependency');
			dependencyElement.set('name', dependency.name);
			switch dependency.type {
				case HAXELIB(version):
					dependencyElement.set('type', 'haxelib');
					if (version != null)
						dependencyElement.set('version', version);

				case GIT(url, ref):
					dependencyElement.set('type', 'git');
					dependencyElement.set('url', url);
					if (ref != null)
						dependencyElement.set('ref', ref);

				case DEV(path):
					dependencyElement.set('type', 'dev');
					dependencyElement.set('path', path);
			}
			if (dependency.skipDependencies)
				dependencyElement.set('skip-dependencies', 'true');

			element.addChild(dependencyElement);
		}

		return element;
	}
}
