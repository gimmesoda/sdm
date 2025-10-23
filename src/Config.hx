import tink.Stringly;
import sys.io.File;
import sys.FileSystem;
import tink.cli.Prompt;

using StringTools;
using Lambda;

class Config extends Profile {
	private var profiles:Array<Profile> = [];

	public function new() {
		super('');
	}

	public function load(prompt:Prompt) {
		if (!FileSystem.exists('sdm.xml')) {
			prompt.printeln('sdm.xml does not exist');
			return;
		}

		final el:Xml = Xml.parse(File.getContent('sdm.xml')).firstElement();
		for (sel in el.elements()) switch sel.nodeName {
			case 'profile':
				Profile.fromElement(sel, prompt).handle((result:Outcome<Profile, Error>) -> switch result {
					case Success(data):
						if (profiles.exists((p:Profile) -> p.name == data.name))
							prompt.printwln('Skip duplicate profile ${data.name}');
						else
							profiles.push(data);
					case Failure(failure):
						prompt.printwln('Failed to load profile');
						prompt.printwln('  >$failure');
				});
			case 'haxelib':
				addDependency(sel.get('name'),
					DHaxelib(sel.exists('version') ? sel.get('version') : null), 
					sel.exists('blind') && sel.get('blind') == 'true');
			case 'git':
				addDependency(sel.get('name'),
					DGit(sel.get('url'), sel.exists('ref') ? sel.get('ref') : null,
					(sel.exists('dir') && sel.exists('ref')) ? sel.get('dir') : null),
					sel.exists('blind') && sel.get('blind') == 'true');
		}
	}

	public function save(prompt:Prompt, force:Bool = false) {
		if (force || !FileSystem.exists('sdm.xml')) {
			final doc:Xml = buildDocument(prompt);

			final text:String = haxe.xml.Printer.print(doc, true);
			File.saveContent('sdm.xml', text);

			prompt.printsln('sdm.xml saved successfully!');
			return;
		}

		prompt.printwln('sdm.xml already exists');
		prompt.prompt('overwrite sdm.xml? [y/N]')
			.handle((result:Outcome<Stringly, Error>) -> switch result {
				case Success(data):
					if ((data : String).toLowerCase().trim() == 'y')
						save(prompt, true);
				case Failure(failure):
					prompt.printeln(failure.toString());
			});
	}

	private function buildDocument(prompt:Prompt):Xml {
		final doc:Xml = Xml.createDocument();
		doc.addChild(Xml.createDocType('sdm-config'));
		doc.addChild(buildElement(prompt));
		return doc;
	}

	override function buildElement(prompt:Prompt):Xml {
		final el:Xml = Xml.createElement('config');

		for (d in dependencies)
			el.addChild(d.buildElement(prompt));

		return el;
	}
}