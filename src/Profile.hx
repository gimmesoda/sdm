import tink.io.Worker;
import tink.cli.Prompt;
import Dependency.DependencyKind;

using Lambda;

class Profile {
	public var name:String;
	private var dependencies:Array<Dependency> = [];

	public function new(name:String) {}

	public static function fromElement(el:Xml, prompt:Prompt):Promise<Profile> {
		final worker:Worker = Worker.get();

		if (el.nodeName != 'profile')
			return worker.work(() -> Failure(new Error('${el.nodeName} expected to be a profile')));

		return worker.work(() -> {
			try {
				final profile:Profile = new Profile(el.get('name'));
				for (sel in el.elements()) switch sel.nodeName {
					case 'haxelib':
						profile.addDependency(sel.get('name'),
							DHaxelib(sel.exists('version') ? sel.get('version') : null), 
							sel.exists('blind') && sel.get('blind') == 'true');
					case 'git':
						profile.addDependency(sel.get('name'),
							DGit(sel.get('url'), sel.exists('ref') ? sel.get('ref') : null,
							(sel.exists('dir') && sel.exists('ref')) ? sel.get('dir') : null),
							sel.exists('blind') && sel.get('blind') == 'true');
				}
				Success(profile);
			} catch (e:Dynamic)
				Failure(new Error(Std.string(e)));
		});
	}

	public function addDependency(name:String, kind:DependencyKind, blind:Bool = false) {
		final dep:Null<Dependency> = dependencies
			.find((d:Dependency) -> d.name == name);

		if (dep == null)
			dependencies.push(new Dependency(name, kind, blind));
		else {
			dep.kind = kind;
			dep.blind = blind;
		}
	}

	public function getDependencies():Array<Dependency> {
		return dependencies;
	}

	public function buildElement(prompt:Prompt):Xml {
		final el:Xml = Xml.createElement('profile');
		el.set('name', name);

		for (d in dependencies)
			el.addChild(d.buildElement(prompt));

		return el;
	}
}