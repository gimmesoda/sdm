typedef Dependency = {
	name:String,
	type:DependencyType,
	blind:Bool
}

enum DependencyType {
	DHaxelib(?version:String);
	DGit(url:String, ?ref:String);
	DDev(path:String);
}
