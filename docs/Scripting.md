Scripts in Rhythmo can be active in only one song, or be applied globally to every song. You can use scripts to make custom backgrounds, add special functions, make cool mechanics, etc.

Your script should either be located in `assets/scripts/[name].hxs`, or in `assets/songs/[song-name]/[name].hxs`. <br>
However, if your script is a scripted state or substate, it should be located in `assets/classes/[name].hxs`.

But also, it doesn't have to be an `.hxs` file. <br>
The following extensions are also supported: 
* `.hx`
* `.hxc`
* `.hscript`

## Limitations
The following are not supported:
* Keywords:
    * `package`, `import` (another function emulates this), `class`, `typedef`, `metadata`, `final`
* Wildcard imports (`import flixel.*`)
* Access modifiers (e.g., `private`, `public`)

## Default Variables
* `Function_Stop` - Cancels functions (e.g., `startCountdown`, `endSong`).
* `Function_Continue` - Continues the game like normal.
* `platform` - Returns the current platform (e.g., Windows, Linux).
* `version` - Returns the current game version.

## Default Functions
* `import(daClass:String, ?asDa:String)` - See [Imports](https://github.com/Joalor64GH/Rhythmo-SC/wiki/Scripting#imports) for more.
* `trace(value:Dynamic)` - The equivalent of `trace` in normal Haxe.
* `stopScript()` - Stops the current script.
* `addScript(path:String)` - Adds a new script during gameplay (PlayState).
* `importScript(source:String)` - Gives access to another script's local functions and variables.

## Imports
To import a class, use:
```hx
import('package.Class');
```

To import an enumerator, use:
```hx
import('package.Enum');
```

To import with an alias, use:
```hx
import('package.Class', 'Name');

var aliasClass:Name;
```

You can basically use this to import any class/enum you'd like. <br>
Otherwise, here is a list of the current classes you can use that are already imported:

### Standard Haxe Classes
* `Array`
* `Bool`
* `Date`
* `DateTools`
* `Dynamic`
* `EReg`
* `Float`
* `Int`
* `Lambda`
* `Math`
* `Reflect`
* `Std`
* `String`
* `StringBuf`
* `StringTools`
* `Sys`
* `Type`
* `Xml`

### Game-Specific Classes
* `Achievements`
* `Application`
* `Assets`
* `Bar`
* `Conductor`
* `ExtendableState`
* `ExtendableSubState`
* `File`
* `FileSystem`
* `FlxAxes`
* `FlxBackdrop`
* `FlxBasic`
* `FlxCamera`
* `FlxCameraFollowStyle`
* `FlxColor`
* `FlxEase`
* `FlxG`
* `FlxGroup`
* `FlxMath`
* `FlxObject`
* `FlxRuntimeShader`
* `FlxSound`
* `FlxSprite`
* `FlxSpriteGroup`
* `FlxText`
* `FlxTextAlign`
* `FlxTextBorderStyle`
* `FlxTimer`
* `FlxTween`
* `FlxTypedGroup`
* `GameSprite`
* `HighScore`
* `Input`
* `Json`
* `Lib`
* `Localization`
* `Main`
* `ModHandler`
* `Note`
* `Path`
* `Paths`
* `PlayState`
* `Rating`
* `SaveData`
* `ScriptedState`
* `ScriptedSubState`
* `Song`
* `TJSON`
* `Utilities`

## Templates
Some useful templates to get started. For the default template, use [this](https://raw.githubusercontent.com/JoaTH-Team/Rhythmo-SC/main/assets/scripts/template.hxs).

### FlxSprite
```hx
import('flixel.FlxSprite');
import('states.PlayState');

function create() {
	var spr:FlxSprite = new FlxSprite(0, 0).makeGraphic(50, 50, FlxColor.BLACK);
	add(spr);
}
```

#### Animated Sprite
```hx
import('flixel.FlxSprite');
import('states.PlayState');
import('backend.Paths');

function create() {
	var spr:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('gameplay/banan'), true, 102, 103);
	spr.animation.add('rotate', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], 14);
	spr.animation.play('rotate');
	spr.screenCenter();
	add(spr);
}
```

### FlxText
```hx
import('flixel.text.FlxText');
import('states.PlayState');

function create() {
	var text:FlxText = new FlxText(0, 0, 0, "Hello World", 64);
	text.screenCenter();
	add(text);
}
```

### Parsing a JSON
```hx
import('sys.FileSystem');
import('sys.io.File');
import('haxe.Json');

var json:Dynamic;

function create() {
	if (FileSystem.exists('assets/data.json'))
		json = Json.parse(File.getContent('assets/data.json'));

	trace(json);
}
```

### Custom States/Substates
```hx
import('states.ScriptedState');
import('substates.ScriptedSubState');
import('backend.ExtendableState');
import('flixel.text.FlxText');
import('flixel.FlxSprite');
import('backend.Input');
import('flixel.FlxG');

function create() {
	var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(1280, 720, FlxColor.WHITE);
	add(bg);

	var text:FlxText = new FlxText(0, 0, FlxG.width, "I am a custom state!", 48);
	text.color = FlxColor.BLACK;
	add(text);
}

function update(elapsed:Float) {
	if (Input.justPressed('accept'))
		ExtendableState.switchState(new ScriptedState('name', [/* arguments, if any */])); // load custom state

	if (Input.justPressed('exit'))
		state.openSubState(new ScriptedSubState('name', [/* arguments, if any */])); // load custom substate
}
```

Additionally, if you want to load your custom state from the main menu, navigate to `assets/data/menuList.txt` and add in your state's name, as well as a main menu asset for it in `assets/images/menu/mainmenu/[name].png`.

And just in case your script doesn't load or something goes wrong, press `F4` to be sent to the main menu.

### Using Imported Scripts
Script 1:
```hx
// assets/helpers/spriteHandler.hxs
import('flixel.FlxSprite');
import('backend.Paths');
import('flixel.FlxG');

function createSprite(x:Float, y:Float, graphic:String) {
	var spr:FlxSprite = new FlxSprite(x, y);
	spr.loadGraphic(Paths.image(graphic));
	state.add(spr);

	trace("sprite " + sprite + " created");
}
```

Script 2:
```hx
var otherScript = importScript('helpers.spriteHandler');

function create() {
	otherScript.createSprite(0, 0, 'sprite');
}
```

### Using a Custom Shader
```hx
import('flixel.addons.display.FlxRuntimeShader');
import('openfl.filters.ShaderFilter');
import('openfl.utils.Assets');
import('flixel.FlxG');
import('backend.Paths');

var shader:FlxRuntimeShader;
var shader2:FlxRunTimeShader;

function create() {
	shader = new FlxRuntimeShader(Assets.getText(Paths.frag('rain')), null);
	shader.setFloat('uTime', 0);
	shader.setFloatArray('uScreenResolution', [FlxG.width, FlxG.height]);
	shader.setFloat('uScale', FlxG.height / 200);
	shader.setFloat("uIntensity", 0.5);
	shader2 = new ShaderFilter(shader);
	FlxG.camera.filters = [shader2];
}

function update(elapsed:Float) {
	shader.setFloat("uTime", shader.getFloat("uTime") + elapsed);
	shader.setFloatArray("uCameraBounds", [
		FlxG.camera.scroll.x + FlxG.camera.viewMarginX,
		FlxG.camera.scroll.y + FlxG.camera.viewMarginY,
		FlxG.camera.scroll.x + FlxG.camera.width,
		FlxG.camera.scroll.y + FlxG.camera.height
	]);
}
```

## Need Help?
If you need any general help or something goes wrong with your script, report an issue [here](https://github.com/Joalor64GH/Rhythmo-SC/issues).