package host;

import haxe.iterators.ArrayKeyValueIterator;
import haxe.iterators.ArrayIterator;

using Lambda;

abstract Dependencies(Array<Dependency>) from Array<Dependency> to Array<Dependency> {
	public function new() {
		this = [];
	}

	public function add(name:String, kind:Dependency.Kind, blind:Bool) {
		final dep:Null<Dependency> = this.find((d:Dependency) -> d.name == name);
		if (dep != null) dep.set(kind, blind);
		else this.push(new Dependency(name, kind, blind));
	}

	public function remove(name:String) {
		final dep:Null<Dependency> = this.find((d:Dependency) -> d.name == name);
		if (dep != null) this.remove(dep);
	}

	public inline function iterator():ArrayIterator<Dependency> {
		return this.iterator();
	}

	public inline function keyValueIterator():ArrayKeyValueIterator<Dependency> {
		return this.keyValueIterator();
	}

	public inline function isEmpty():Bool {
		return this.length == 0;
	}

	public inline function copy():Dependencies {
		return this.copy();
	}
}