package sdm;

import sdm.Dependency.DependencyType;

class Config extends Profile {
	private var _profiles:Map<String, Profile> = [];

	public function new() {
		super();
		_profiles = [];
	}

	public static function fromXmlElement(element:Xml) {
		if (element.nodeName != 'config')
			throw '${element.nodeName} should be config';

		final config = new Config();

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
					case _: null;
				}
				final skipDependencies = dependencyElement.exists('skip-dependencies')
					&& dependencyElement.get('skip-dependencies') == 'true';

				config.addDependency(name, type, skipDependencies);
			}
		}

		for (profileElement in element.elementsNamed('profile')) {
			try {
				final name = profileElement.get('name');
				final profile = Profile.fromXmlElement(profileElement);
				config._profiles[name] = profile;
			}
		}

		return config;
	}

	public function installDependenciesWithProfile(?profile:String) {
		installDependencies();

		if (profile != null && _profiles.exists(profile))
			_profiles[profile].installDependencies();
	}

	override function toXmlElement():Xml {
		final element = super.toXmlElement();
		element.nodeName = 'config';

		for (name => profile in _profiles) {
			final profileElement = profile.toXmlElement();
			profileElement.set('name', name);
			element.addChild(profileElement);
		}

		return element;
	}

	public function addProfile(name:String) {
		if (!_profiles.exists(name))
			_profiles[name] = new Profile();
	}

	public function getProfile(name:String):Null<Profile> {
		return _profiles.get(name);
	}
}
