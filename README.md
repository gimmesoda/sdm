# **Soda's Dependency Manager (SDM)**

**A lightweight dependency manager for Haxe with profile support and XML configuration**

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
	<haxelib version="4.3.2" name="hxcpp"/>
	<profile name="Haxelib Test">
		<haxelib version="2.6.0" name="hscript"/>
	</profile>
	<profile name="Git Test">
		<git url="https://github.com/HaxeFoundation/hscript.git" ref="f718d5f1a651296f6d9bcd6059d570e0d4e511b5" name="hscript"/>
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
| **haxelib** | Adds Haxelib dependency | `sdm haxelib [name] [version?]` | `-p/--profile`<br>`-b/--blind` |
| **git** | Adds Git dependency | `sdm git [name] [url] [ref?]` | `-p/--profile`<br>`-b/--blind` |
| **dev** | Adds local dependency | `sdm dev [name] [path]` | `-p/--profile`<br>`-b/--blind` |
| **remove** | Removes dependency | `sdm remove [name]` | `-p/--profile` |
| **task** | Adds post-install cmd | `sdm task [cmd] [dir?]` | |

**Options:**
- `-p/--profile [name]` - Target specific profile
- `-g/--global` - Install dependencies globally
- `-b/--blind` - Skip installing sub-dependencies

**Example Usage:**
```sh
sdm init

# Add a haxelib to specific profile
sdm haxelib hscript 2.6.0 -p dev

# Add git dependency with commit ref
sdm git heaps https://github.com/HeapsIO/heaps.git 1f6b60a2604d275855629353a72f1bf2417d0e39

# Add a dependency that needs to be built manually
sdm haxelib hxcpp
sdm git hashcord https://github.com/CCobaltDev/hashcord.git
sdm task "haxelib run hxcpp Build.xml" ".\.haxelib\hashcord\git\project"
sdm task "copy .\.haxelib\hashcord\git\project\out\discord_rpc.hdll discord_rpc.hdll"

# Install with all options
sdm install -p dev
```
