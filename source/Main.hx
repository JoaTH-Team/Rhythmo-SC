package;

#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.io.Process;
#end
import rhythmo.debug.FPS;
import haxe.ui.Toolkit;
import flixel.util.typeLimit.NextState;

/**
 * The main entry point for the game.
 */
#if linux
import hxgamemode.GamemodeClient;
#end
class Main extends openfl.display.Sprite
{
	/**
	 * The width of the game window in pixels.
	 */
	private static final GAME_WIDTH:Int = 1280;

	/**
	 * The height of the game window in pixels.
	 */
	private static final GAME_HEIGHT:Int = 720;

	/**
	 * The frame rate of the game, in frames per second (FPS).
	 */
	private static final GAME_FRAMERATE:Int = 60;

	/**
	 * The initial state of the game.
	 */
	private static final GAME_INITIAL_STATE:InitialState = () -> new jta.states.Startup();

	/**
	 * Whether to skip the splash screen on startup.
	 */
	private static final GAME_SKIP_SPLASH:Bool = true;

	/**
	 * Whether to start the game in fullscreen mode on desktop.
	 */
	private static final GAME_START_FULLSCREEN:Bool = false;

	/**
	 * The frame rate display.
	 */
	public static var fpsDisplay:FPS;

	/**
	 * The toast notification display.
	 */
	public static var toast:ToastCore;

	public static var framerate(get, set):Float;

	static function set_framerate(cap:Float):Float
	{
		if (FlxG.game != null)
		{
			FlxG.updateFramerate = Std.int(cap);
			FlxG.drawFramerate = Std.int(cap);
		}
		return Lib.current.stage.frameRate = cap;
	}

	static function get_framerate():Float
		return Lib.current.stage.frameRate;

	#if desktop
	static function __init__():Void
	{
		#if linux
		if (GamemodeClient.request_start() != 0)
			Sys.println('Failed to request gamemode start: ${GamemodeClient.error_string()}...');
		else
			Sys.println('Succesfully requested gamemode to start...');
		#end
		
		var origin:String = #if hl Sys.getCwd() #else Sys.programPath() #end;

		var configPath:String = Path.directory(Path.withoutExtension(origin));
		#if windows
		configPath += '/alsoft.ini';
		#elseif mac
		configPath = '${Path.directory(configPath)}/Resources/alsoft.conf';
		#else
		configPath += '/alsoft.conf';
		#end

		Sys.putEnv('ALSOFT_CONF', configPath);
	}
	#end

	/**
	 * Initializes the game and sets up the application.
	 */
	public function new():Void
	{
		super();

		Toolkit.init();
    	Toolkit.theme = 'dark'; 
    	Toolkit.autoScale = false;
    	haxe.ui.focus.FocusManager.instance.autoFocus = false;
    	haxe.ui.tooltips.ToolTipManager.defaultDelay = 200;

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onCrash);
		#end
		#end

		#if windows
		WindowsAPI.darkMode(true);
		#end

		framerate = GAME_FRAMERATE; // default framerate
		addChild(new FlxGame(GAME_WIDTH, GAME_HEIGHT, GAME_INITIAL_STATE, GAME_FRAMERATE, GAME_FRAMERATE, GAME_SKIP_SPLASH, GAME_START_FULLSCREEN));

		fpsDisplay = new FPS(10, 10, 0xffffff);
		addChild(fpsDisplay);

		#if (linux || mac)
		Lib.current.stage.window.setIcon(lime.graphics.Image.fromFile('icon.png'));
		#end

		#if FUTURE_DISCORD_RPC
		DiscordClient.load();
		#end

		Application.current.window.onFocusOut.add(onWindowFocusOut);
		Application.current.window.onFocusIn.add(onWindowFocusIn);

		#if windows
		Lib.current.stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, (evt:openfl.events.KeyboardEvent) ->
		{
			if (evt.keyCode == openfl.ui.Keyboard.F2)
			{
				var sp = Lib.current.stage;
				var position = new openfl.geom.Rectangle(0, 0, Lib.current.stage.stageWidth, Lib.current.stage.stageHeight);

				var image:BitmapData = new BitmapData(Std.int(position.width), Std.int(position.height), false, 0xFEFEFE);
				image.draw(sp, true);

				if (!FileSystem.exists('./screenshots/'))
					FileSystem.createDirectory('./screenshots/');

				var bytes = image.encode(position, new openfl.display.PNGEncoderOptions());

				var curDate:String = Date.now().toString();
				curDate = StringTools.replace(curDate, ' ', '_');

				File.saveBytes('screenshots/Screenshot-' + curDate + '.png', bytes);
			}
		});
		#end

		FlxG.mouse.visible = false;

		toast = new ToastCore();
		addChild(toast);
	}

	var oldVol:Float = 1.0;
	var newVol:Float = 0.3;

	var focused:Bool = true;
	var focusMusicTween:FlxTween;

	function onWindowFocusOut():Void
	{
		focused = false;

		if (Type.getClass(FlxG.state) != PlayState)
		{
			oldVol = FlxG.sound.volume;
			newVol = (oldVol > 0.3) ? 0.3 : (oldVol > 0.1) ? 0.1 : 0;

			trace('Game unfocused');

			if (focusMusicTween != null)
				focusMusicTween.cancel();
			focusMusicTween = FlxTween.tween(FlxG.sound, {volume: newVol}, 0.5);

			FlxG.drawFramerate = 30;
		}
	}

	function onWindowFocusIn():Void
	{
		new FlxTimer().start(0.2, (tmr:FlxTimer) ->
		{
			focused = true;
		});

		if (Type.getClass(FlxG.state) != PlayState)
		{
			trace('Game focused');

			if (focusMusicTween != null)
				focusMusicTween.cancel();

			focusMusicTween = FlxTween.tween(FlxG.sound, {volume: oldVol}, 0.5);

			FlxG.drawFramerate = Std.int(framerate);
		}
	}

	#if CRASH_HANDLER
	private static function onCrash(e:UncaughtErrorEvent):Void
	{
		var stack:Array<String> = [];
		stack.push(e.error);

		for (stackItem in CallStack.exceptionStack(true))
		{
			switch (stackItem)
			{
				case CFunction:
					stack.push('C Function');
				case Module(m):
					stack.push('Module ($m)');
				case FilePos(s, file, line, column):
					stack.push('$file (line $line)');
				case Method(classname, method):
					stack.push('$classname (method $method)');
				case LocalFunction(name):
					stack.push('Local Function ($name)');
			}
		}

		e.preventDefault();
		e.stopPropagation();
		e.stopImmediatePropagation();

		final msg:String = stack.join('\n');

		#if sys
		try
		{
			if (!FileSystem.exists('./crash/'))
				FileSystem.createDirectory('./crash/');

			File.saveContent('./crash/${Lib.application.meta.get('file')}-${Date.now().toString().replace(' ', '-').replace(':', "'")}.txt', '$msg\n');
		}
		catch (e:Dynamic)
			Sys.println('Error!\nCouldn\'t save the crash dump because:\n$e');
		#end

		#if (flixel < '6.0.0')
		FlxG.bitmap.dumpCache();
		#end
		FlxG.bitmap.clearCache();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.sound.play(Paths.sound('error'));

		#if FUTURE_DISCORD_RPC
		DiscordClient.shutdown();
		#end

		#if windows
		WindowsAPI.messageBox('Error!', 'Uncaught Error: \n$msg
			\n\nIf you think this shouldn\'t have happened, report this error to GitHub repository!\nhttps://github.com/JoaTH-Team/Rhythmo-SC/issues', MSG_ERROR);
		#else
		Lib.application.window.alert('Uncaught Error: \n$msg
			\n\nIf you think this shouldn\'t have happened, report this error to GitHub repository!\nhttps://github.com/JoaTH-Team/Rhythmo-SC/issues', 'Error!');
		#end
		Sys.println('Uncaught Error: \n$msg
			\n\nIf you think this shouldn\'t have happened, report this error to GitHub repository!\nhttps://github.com/JoaTH-Team/Rhythmo-SC/issues');
		Sys.exit(1);
	}

	#if cpp
	private static function onFatalCrash(msg:String):Void
	{
		var errMsg:String = '';
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(' ', '_');
		dateNow = dateNow.replace(':', "'");

		path = './crash/Rhythmo_$dateNow.txt';

		errMsg += '${msg}\n';

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += 'in ${file} (line ${line})\n';
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += '\n\nPlease report this error to the GitHub page: https://github.com/JoaTH-Team/Rhythmo-SC/issues';

		if (!FileSystem.exists('./crash/'))
			FileSystem.createDirectory('./crash/');

		File.saveContent(path, '$errMsg\n');

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		Sys.println(errMsg);
		Sys.println('Crash dump saved in ${Path.normalize(path)}');

		Application.current.window.alert(errMsg, 'CRITICAL ERROR!');
		#if FUTURE_DISCORD_RPC
		DiscordClient.shutdown();
		#end
		Sys.exit(1);
	}
	#end
	#end
}
