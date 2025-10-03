Scripts in Rhythmo can be active in only one song, or be applied globally to every song. You can use scripts to make custom backgrounds, add special functions, make cool mechanics, etc.

Your script should either be located in `assets/scripts/`, or in `assets/songs/[song-name]/`. <br>
However, if your script is a scripted state or substate, it should be located in `assets/states/` or `assets/substates/`.

Currently, the following extensions are supported:
* `.hscript`
* `.hx`
* `.hxc`
* `.hxs`
* `.lua`

# HScript
## Limitations
The following are not supported:
* Keywords:
    * `typedef`, `metadata`, `final`
* Wildcard imports (`import flixel.*`)
* Access modifiers (e.g., `private`, `public`)

## Default Variables
* `Function_Stop` - Cancels functions (e.g., `startCountdown`, `endSong`).
* `Function_Continue` - Continues the game like normal.
* `platform` - Returns the current platform (e.g., Windows, Linux).
* `version` - Returns the current game version.

## Default Functions
* `trace(value:Dynamic)` - The equivalent of `trace` in normal Haxe.
* `stopScript()` - Stops the current script.
* `addScript(path:String)` - Adds a new script during gameplay (PlayState).
* `importScript(source:String)` - Gives access to another script's local functions and variables.

## Imports
Below is a list of the current classes you can use that are already imported:

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
* `DiscordClient`
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
* `LuaScript`
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
* `Util`

## Templates
Some useful templates to get started. For the default template, use [this](https://raw.githubusercontent.com/JoaTH-Team/Rhythmo-SC/main/assets/scripts/template.hxs).

### FlxSprite
```hx
import flixel.FlxSprite;

function create() 
{
	var spr:FlxSprite = new FlxSprite(0, 0).makeGraphic(50, 50, FlxColor.BLACK);
	add(spr);
}
```

#### Animated Sprite
```hx
import flixel.FlxSprite;
import rhythmo.Paths;

function create() 
{
	var spr:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('gameplay/banan'), true, 102, 103);
	spr.animation.add('rotate', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], 14);
	spr.animation.play('rotate');
	spr.screenCenter();
	add(spr);
}
```

### FlxText
```hx
import flixel.text.FlxText;

function create() 
{
	var text:FlxText = new FlxText(0, 0, 0, "Hello World", 64);
	text.screenCenter();
	add(text);
}
```

### Parsing a JSON
```hx
import sys.FileSystem;
import sys.io.File;
import haxe.Json;

var json:Dynamic;

function create() 
{
	if (FileSystem.exists('assets/data.json'))
		json = Json.parse(File.getContent('assets/data.json'));

	trace(json);
}
```

### Custom States/Substates
```hx
import rhythmo.states.ScriptedState;
import rhythmo.states.ExtendableState;
import rhythmo.substates.ScriptedSubState;
import rhythmo.input.Input;
import flixel.text.FlxText;
import flixel.FlxSprite;

function create() 
{
	var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(1280, 720, FlxColor.WHITE);
	add(bg);

	var text:FlxText = new FlxText(0, 0, FlxG.width, "I am a custom state!", 48);
	text.color = FlxColor.BLACK;
	add(text);
}

function update(elapsed:Float) 
{
	if (Input.justPressed('accept'))
		ExtendableState.switchState(new ScriptedState('name', [/* arguments, if any */])); // load custom state

	if (Input.justPressed('exit'))
		openSubState(new ScriptedSubState('name', [/* arguments, if any */])); // load custom substate
}
```

Additionally, if you want to load your custom state from the main menu, navigate to `assets/data/menuList.txt` and add in your state's name, as well as a main menu asset for it in `assets/images/menu/mainmenu/[name].png`.

And just in case your script doesn't load or something goes wrong, press `F4` to be sent to the main menu.

### Using Imported Scripts
Script 1:
```hx
// assets/helpers/spriteHandler.hxs
package helpers;

import flixel.FlxSprite;
import rhythmo.Paths;

function createSprite(x:Float, y:Float, graphic:String) 
{
	var spr:FlxSprite = new FlxSprite(x, y);
	spr.loadGraphic(Paths.image(graphic));
	add(spr);

	trace("sprite " + graphic + " created");
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
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets;
import flixel.FlxG;
import rhythmo.Paths;

var shader:FlxRuntimeShader;
var shader2:FlxRunTimeShader;

function create() 
{
	shader = new FlxRuntimeShader(Assets.getText(Paths.frag('rain')), null);
	shader.setFloat('uTime', 0);
	shader.setFloatArray('uScreenResolution', [FlxG.width, FlxG.height]);
	shader.setFloat('uScale', FlxG.height / 200);
	shader.setFloat("uIntensity", 0.5);
	shader2 = new ShaderFilter(shader);
	FlxG.camera.filters = [shader2];
}

function update(elapsed:Float) 
{
	shader.setFloat("uTime", shader.getFloat("uTime") + elapsed);
	shader.setFloatArray("uCameraBounds", [
		FlxG.camera.scroll.x + FlxG.camera.viewMarginX,
		FlxG.camera.scroll.y + FlxG.camera.viewMarginY,
		FlxG.camera.scroll.x + FlxG.camera.width,
		FlxG.camera.scroll.y + FlxG.camera.height
	]);
}
```

# Lua
## Default Variables
* `Function_Stop` - Cancels functions (e.g., startCountdown, endSong).
* `Function_Continue` - Continues the game like normal.
* `platform` - Returns the current platform (e.g., Windows, Linux).
* `version` - Returns the current game version.
* `lua.version` - Returns the current lua version.
* `lua.versionJIT` - Returns the current luajit version.

## Default Functions
* `trace(value:Dynamic)` - The equivalent of `trace` in normal Haxe.
	* Additionally, you can also use `print` instead.
* `stopScript()` - Stops the current script.
* `stdInt(x:Float)` - Converts a floating point number into an integer.

## Basic Object Functions
* `createObject(type:String, tag:String, config:Dynamic)` - Creates an object with a specific configuration.
* `addObject(tag:String)` - Adds an object.
* `removeObject(tag:String)` - Removes an object.
* `insertObject(tag:String, pos:Int = 0)` - Inserts an object at a specific position.
* `setPosition(tag:String, x:Float, y:Float)` - Sets an object's position.
* `setScale(tag:String, x:Float, y:Float)` - Sets the scaling of an object.
* `setProperty(propertyGame:String, value:Dynamic)` - Sets the property of an object.
* `getProperty(propertyGame:String)` - Gets the property of an object.

### Text
* `createObject("text", "tag", {x = 0, y = 0, width = 0, text = "Text goes here.", size = 16})` - Creates a text object.
* `setText(tag:String, newText:String)` - Changes the current text for a text object.
* `configText(tag:String, config:Dynamic)` - Configures a text object with various properties.
	* `x`, `y`: Position
    * `width`: Text width
    * `text`: Text content
    * `size`: Font size
    * `color`: Text color
    * `alignment`: Text alignment
    * `alpha`: Transparency
    * `scale`: Scaling
    * `angle`: Rotation angle
    * `visible`: Visibility
    * `active`: Active
    * `scrollFactor`: Scroll speed
    * `antialiasing`: Anti-aliasing
    * `font`: Custom font
    * `borderSize`: Text border size
    * `borderColor`: Border color
    * `borderStyle`: Border style
    * `borderQuality`: Border quality

### Sprites
* `createObject("sprite", "tag", {x = 0, y = 0, image = "image"})` - Creates a sprite.
* `makeAnimationSprite(tag:String, x:Float, y:Float, path:String)` - Creates an animated sprite.
* `addAnimationByPrefix(tag:String, name:String, prefix:String, fps:Int, looped:Bool)` - Adds an animation to an animated sprite.
* `playAnimation(tag:String, name:String, force:Bool = false, rev:Bool = false, frames:Int = 0)` - Plays an animation for an animated sprite.
* `configSprite(tag:String, config:Dynamic)` - Configures a sprite with various properties.
	* `image`: Image path
    * `x`, `y`: Position
    * `width`, `height`: Dimensions
    * `alpha`: Transparency
    * `scale`: Scaling
    * `angle`: Rotation angle
    * `visible`: Visibility
    * `active`: Active
    * `scrollFactor`: Scroll speed

## Sound Functions
* `playSound(name:String, volume:Float, loop:Bool)` - Plays a sound.
* `playMusic(name:String, volume:Float, loop:Bool)` - Plays music.

## Using Haxe in Lua
* `runHaxeCode(code:String)` - Runs Haxe code.
* `runHaxeFunction(func:String, ?args:Array<Dynamic>)` - Runs a Haxe function.
* `importHaxeLibrary(lib:String, ?packageName:String)` - Imports a Haxe library.

## Misc. Functions
* `getInput(state:String, key:String)` - Checks for a specific input.

## Templates
For the default template, use [this](https://raw.githubusercontent.com/JoaTH-Team/Rhythmo-SC/main/assets/scripts/template.lua).

### Making a Sprite
```lua
function create()
	createObject("sprite", "sun", {x = 0, y = 0, image = "sun"})
	addObject("sun")
end
```

#### Making an Animated Sprite
```lua
function create()
	makeAnimationSprite("player", 500, 0, "example")
	addAnimationByPrefix("player", "idle", "Idle", 24, false)
	addAnimationByPrefix("player", "singUP", "Up", 24, true)
	addAnimationByPrefix("player", "singDOWN", "Down", 24, true)
	addAnimationByPrefix("player", "singLEFT", "Left", 24, true)
	addAnimationByPrefix("player", "singRIGHT", "Right", 24, true)
	playAnimation("player", "idle", false, false, 0)
	addObject("player")
end

function update(elapsed)
	if getInput("pressed", "LEFT") then
		playAnimation("player", "singLEFT", true, false, 0)
	elseif getInput("pressed", "RIGHT") then
		playAnimation("player", "singRIGHT", true, false, 0)
	elseif getInput("pressed", "UP") then
		playAnimation("player", "singUP", true, false, 0)
	elseif getInput("pressed", "DOWN") then
		playAnimation("player", "singDOWN", true, false, 0)
	else
		playAnimation("player", "idle", false, false, 0)
	end
end
```

### Making Text
```lua
function create()
	createObject("text", "tutoText", {x = screenWidth / 2, y = screenHeight / 2, width = 0, text = "Press the notes!", size = 64})
	configText("tutoText", {font = "vcr"})
	addObject("tutoText")
end
```

### Using Haxe in Lua
```lua
function create()
	importHaxeLibrary("FlxG", "flixel")
	runHaxeCode([[
		FlxG.openURL("https://github.com/JoaTH-Team/Rhythmo-SC");
	]])
end
```

# Need Help?
If you need any general help or something goes wrong with your script, report an issue [here](https://github.com/Joalor64GH/Rhythmo-SC/issues).