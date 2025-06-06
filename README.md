# **Soda's Dependency Manager (SDM)**

**A lightweight and flexible dependency manager for Haxe with profile support and XML configuration**

**SDM** is a simple tool for managing dependencies in Haxe projects. It allows you to easily install libraries from Haxelib, Git, or local paths, and switch between different build profiles.

## **Features**
### **Multiple dependency types:**
- **Haxelib** (with version support)
- **Git repositories** (with commit hash or branch support)
- **Local dev dependencies** (`dev`)

#### **Profile support**
Different dependency sets for dev, release, or other scenarios.
#### **XML-based config**
Clean and structured dependency definitions.
#### **Minimal CLI**
Simple commands for installation and management.

---

## **Example Config (`sdm.xml`)**
```xml
<!DOCTYPE sdm-config>
<config>
	<dependency version="4.3.2" type="haxelib" name="hxcpp"/>
	<profile name="Haxelib Test">
		<dependency version="2.6.0" type="haxelib" name="hscript"/>
	</profile>
	<profile name="Git Test">
		<dependency url="https://github.com/HaxeFoundation/hscript.git" type="git" ref="f718d5f1a651296f6d9bcd6059d570e0d4e511b5" name="hscript"/>
	</profile>
</config>
```

---

### **SDM Command Reference**

| Command | Description | Usage | Options |
|---------|-------------|-------|---------|
| **setup** | Creates global shortcut | `sdm setup` | |
| **init** | Creates basic config | `sdm init` | |
| **install** | Installs dependencies | `sdm install` | `-p/--profile [name]`<br>`-g/--global` |
| **add profile** | Adds new profile | `sdm add profile [name]` | |
| **add haxelib** | Adds Haxelib dependency | `sdm add haxelib [name] [version?]` | `-p/--profile`<br>`--skip-dependencies` |
| **add git** | Adds Git dependency | `sdm add git [name] [url] [ref?]` | `-p/--profile`<br>`--skip-dependencies` |
| **add dev** | Adds local dependency | `sdm add dev [name] [path]` | `-p/--profile`<br>`--skip-dependencies` |

**Global Options:**
- `-p/--profile [name]` - Target specific profile
- `-g/--global` - Install dependencies globally
- `--skip-dependencies` - Skip installing sub-dependencies

**Example Usage:**
```sh
# Add a haxelib to specific profile
sdm add haxelib hscript 2.6.0 -p dev

# Add git dependency with commit ref
sdm add git heaps https://github.com/HeapsIO/heaps.git 1f6b60a2604d275855629353a72f1bf2417d0e39

# Install with all options
sdm install -p dev --global --skip-dependencies
```
