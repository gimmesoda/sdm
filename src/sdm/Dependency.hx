package sdm;

typedef Dependency = {name:String, type:DependencyType, skipSubDeps:Bool}

enum DependencyType {
	DHaxelib(?version:String);
	DGit(url:String, ?ref:String);
	DDev(path:String);
}
