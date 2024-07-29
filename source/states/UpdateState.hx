package states;

class UpdateState extends ExtendableState {
	public static var mustUpdate:Bool = false;
	public static var daJson:Dynamic;

	override function create() {
		super.create();

		var text:FlxText = new FlxText(0, 0, FlxG.width,
			"Hey! You're running an outdated version of Rhythmo!"
			+ '\nYour current version is v${Lib.application.meta.get('version')}!'
			+ '\nPress ENTER to update to v${updateVersion}! Otherwise, press ESCAPE.'
			+ "\nThanks for playing!",
			32);
		text.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.screenCenter(XY);
		add(text);
	}

	public static function updateCheck() {
		trace('checking for updates...');
		var http = new Http('https://raw.githubusercontent.com/Joalor64GH/RHythmo-SC/main/gitVersion.json');
		http.onData = (data:String) -> {
			var daRawJson:Dynamic = Json.parse(data);
			if (daRawJson.version != Lib.application.meta.get('version')) {
				trace('oh noo outdated!!');
				daJson = daRawJson;
				mustUpdate = true;
			} else
				mustUpdate = false;
		}

		http.onError = (error) -> trace('error: $error');
		http.request();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Input.is("accept")) {
			FlxG.sound.play(Paths.sound('select'));
			#if linux
			Sys.command('/usr/bin/xdg-open', ["https://github.com/Joalor64GH/Rhythmo-SC/releases"]);
			#else
			FlxG.openURL("https://github.com/Joalor64GH/Rhythmo-SC/releases");
			#end
		} else if (Input.is("exit")) {
			ExtendableState.switchState(new TitleState());
			FlxG.sound.play(Paths.sound('cancel'));
		}
	}
}