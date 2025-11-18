package rhythmo.states.editors;

import rhythmo.backend.Conductor;
import rhythmo.backend.Song;
import rhythmo.objects.game.Note;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import openfl.net.FileFilter;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUIInputText;
import haxe.ui.backend.flixel.UIState;
import haxe.ui.core.Component;
import haxe.ui.components.TextField;
import haxe.ui.components.Button;
import haxe.ui.containers.VBox;

@:build(haxe.ui.ComponentBuilder.build("assets/ui/main-view.xml"))
class ChartingState extends haxe.ui.backend.flixel.UIState
{
	public static var instance:ChartingState = null;
	public static var song:SongData = null;

	var gridBG:FlxSprite;
	var gridSize:Int = 40;
	var columns:Int = 4;
	var rows:Int = 16;

	var curSection:Int = 0;
	var dummyArrow:FlxSprite;

	var beatSnap:Int = 16;

	var renderedNotes:FlxTypedGroup<Note>;
	var renderedSustains:FlxTypedGroup<FlxSprite>;
	var curSelectedNote:NoteData;

	var songInfoText:FlxText;

	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic> = [];

	var strumLine:FlxSprite;

    var metadataDialog:Dialog;
    var inputSongName:TextField;
    var inputSongBPM:TextField;
    var inputSongSig:TextField;
    var btnSaveMetadata:Button;
    var btnCancelMetadata:Button;

	var _file:FileReference;

	public function new():Void
	{
		super();

		if (song == null)
		{
			song = {
				song: 'Test',
				notes: [],
				bpm: 100,
				timeSignature: [4, 4]
			};
		}
		else
			song = Song.loadSongfromJson(Paths.formatToSongPath(song.song));

		instance = this;
	}

	override public function create():Void
	{
		super.create();

		Main.fpsDisplay.visible = false;

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if FUTURE_DISCORD_RPC
		DiscordClient.changePresence('Chart Editor', null, null, true);
		#end

        metadataDialog = findComponent("toolboxMetadata");
        inputSongName = findComponent("inputSongName");
        inputSongBPM = findComponent("inputSongBPM");
        inputSongSig = findComponent("inputSongSig");
        btnSaveMetadata = findComponent("btnSaveMetadata");
        btnCancelMetadata = findComponent("btnCancelMetadata");

        addMenuHandler("miLoadSong", function(_) { openSubState(new LoadSongSubState()); });
        addMenuHandler("miLoadJSON", function(_) { loadSongFromFile(); });
        addMenuHandler("miSave", function(_) { saveSong(); });
        addMenuHandler("miSaveAs", function(_) { saveSong(); }); // reuse saveSong for now
        addMenuHandler("miExit", function(_) { FlxG.resetState(); });

        addMenuHandler("miCopySection", function(_) { copySection(); });
        addMenuHandler("miPasteSection", function(_) { pasteSection(); });
        addMenuHandler("miClearSection", function(_) { clearSection(); });
        addMenuHandler("miClearSong", function(_) { clearSong(); });

        addMenuHandler("miPlaytest", function(_) { openPlayState(); });
        addMenuHandler("miEditMetadata", function(_) { openMetadataDialog(); });

        addMenuHandler("miControls", function(_) { openSubState(new HelpSubState()); });

        if (btnSaveMetadata != null)
            btnSaveMetadata.onClick = function(_) saveMetadata();
        if (btnCancelMetadata != null)
            btnCancelMetadata.onClick = function(_) closeMetadataDialog();

		var mouseSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('cursor/cursor'));
		FlxG.mouse.load(mouseSpr.pixels);
		FlxG.mouse.visible = true;

		Conductor.bpm = song.bpm;
		loadSong(Paths.formatToSongPath(song.song));
		beatSnap = Conductor.stepsPerSection;

		var bg:FlxSprite = new GameSprite().loadGraphic(Paths.image('gameplay/bg'));
		bg.color = 0xFF444444;
		add(bg);

		gridBG = FlxGridOverlay.create(gridSize, gridSize, gridSize * columns, gridSize * rows, true, 0xFF404040, 0xFF525252);
		gridBG.screenCenter();
		add(gridBG);

		dummyArrow = new FlxSprite().makeGraphic(gridSize, gridSize);
		add(dummyArrow);

		renderedNotes = new FlxTypedGroup<Note>();
		add(renderedNotes);

		renderedSustains = new FlxTypedGroup<FlxSprite>();
		add(renderedSustains);

		addSection();
		updateGrid();

		songInfoText = new FlxText(10, 40, 0, 18);
		add(songInfoText);

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width / 2, gridBG.y).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		add(gridBlackLine);

		strumLine = new FlxSprite(gridBG.x, 50).makeGraphic(Std.int(gridBG.width), 4);
		add(strumLine);

		var charterVer:FlxText = new FlxText(0, FlxG.height - 24, 0, 'Charter v0.3', 12);
		charterVer.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		charterVer.screenCenter(X);
		charterVer.scrollFactor.set();
		add(charterVer);
	}

	function addMenuHandler(id:String, f:ComponentEvent->Void):Void
    {
        var comp:Component = this.findComponent(id);
        if (comp != null)
        {
            comp.addEventListener(ComponentEvent.ACTION, f);
        }
    }

	function openMetadataDialog():Void
    {
        if (metadataDialog == null) return;

        if (inputSongName != null) inputSongName.text = song.song;
        if (inputSongBPM != null) inputSongBPM.text = Std.string(song.bpm);
        if (inputSongSig != null) inputSongSig.text = '${song.timeSignature[0]},${song.timeSignature[1]}';

        metadataDialog.show();
    }

    function saveMetadata():Void
    {
        if (inputSongName != null) song.song = inputSongName.text;
        if (inputSongBPM != null) song.bpm = Std.parseFloat(inputSongBPM.text);
        if (inputSongSig != null)
        {
            var parts = inputSongSig.text.split(',');
            if (parts.length >= 2)
            {
                song.timeSignature = [Std.parseInt(parts[0]), Std.parseInt(parts[1])];
            }
        }

        Conductor.bpm = song.bpm;
        ChartingState.instance.updateGrid();
        closeMetadataDialog();
    }

    function closeMetadataDialog():Void
    {
        if (metadataDialog != null) metadataDialog.hide();
    }

    function copySection():Void
    {
        notesCopied = [];
        sectionToCopy = curSection;
        for (i in 0...song.notes[curSection].sectionNotes.length)
            notesCopied.push(song.notes[curSection].sectionNotes[i]);
    }

    function pasteSection():Void
    {
        if (notesCopied == null || notesCopied.length < 1) return;
        for (note in notesCopied)
        {
            var clonedNote = {
                noteStrum: note.noteStrum + Conductor.stepCrochet * (4 * 4 * (curSection - sectionToCopy)),
                noteData: note.noteData,
                noteSus: note.noteSus
            };
            song.notes[curSection].sectionNotes.push(clonedNote);
        }
        updateGrid();
    }

    function clearSection():Void
    {
        song.notes[curSection].sectionNotes = [];
        updateGrid();
    }

    function clearSong():Void
    {
        openSubState(new PromptSubState(Localization.get('youDecide'), () ->
        {
            for (daSection in 0...song.notes.length)
                song.notes[daSection].sectionNotes = [];
            updateGrid();
        }));
    }

	override public function update(elapsed:Float):Void
	{
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * song.notes[curSection].stepsPerSection));

		if (curBeat % 4 == 0 && curStep > 16 * (curSection + 1))
		{
			if (song.notes[curSection + 1] == null)
				addSection();

			changeSection(curSection + 1, false);
		}

		if (Input.justPressed('left'))
			changeSection(curSection - 1);
		if (Input.justPressed('right'))
			changeSection(curSection + 1);

		if (Input.justPressed('accept'))
			openPlayState();

		if (Input.justPressed('space'))
		{
			if (FlxG.sound.music.playing)
				FlxG.sound.music.pause();
			else
				FlxG.sound.music.play();
		}

		if (Input.justPressed('e'))
			changeNoteSustain(Conductor.stepCrochet);
		if (Input.justPressed('q'))
			changeNoteSustain(-Conductor.stepCrochet);

		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (gridSize * Conductor.stepsPerSection))
		{
			var snappedGridSize = (gridSize / (beatSnap / Conductor.stepsPerSection));

			dummyArrow.visible = true;
			dummyArrow.x = Math.floor(FlxG.mouse.x / gridSize) * gridSize;
			dummyArrow.y = (Input.pressed('shift')) ? FlxG.mouse.y : Math.floor(FlxG.mouse.y / snappedGridSize) * snappedGridSize;
		}
		else
			dummyArrow.visible = false;

		if (FlxG.mouse.justPressed)
		{
			var coolNess = true;

			if (FlxG.mouse.overlaps(renderedNotes))
			{
				renderedNotes.forEach(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note)
						&& (Math.floor((gridBG.x + FlxG.mouse.x / gridSize) - 2)) == note.rawNoteData && coolNess)
					{
						coolNess = false;

						if (Input.pressed('control'))
							selectNote(note);
						else
						{
							trace('trying to delete note');
							deleteNote(note);
						}
					}
				});
			}

			if (coolNess)
			{
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (gridSize * Conductor.stepsPerSection))
				{
					addNote();
				}
			}
		}

		Conductor.songPosition = FlxG.sound.music.time;

		songInfoText.text = ('Time: '
			+ Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
			+ ' / '
			+ Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2))
			+ '\nSection: '
			+ curSection
			+ '\nBPM: '
			+ song.bpm
			+ '\nTime Signature: '
			+ song.timeSignature[0]
			+ '/'
			+ song.timeSignature[1]
			+ '\nCurStep: '
			+ curStep
			+ '\nCurBeat: '
			+ curBeat
			+ '\nNote Snap: '
			+ beatSnap
			+ '\n'
			+ (Input.pressed('shift') ? '(DISABLED)' : '(CONTROL + ARROWS)'));

		super.update(elapsed);
	}

	function openPlayState():Void
	{
		FlxG.mouse.visible = false;
		if (FlxG.sound.music.playing)
			FlxG.sound.music.stop();
		ExtendableState.switchState(new PlayState());
		PlayState.song = song;
	}

	function loadSong(daSong:String):Void
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.sound.music = new FlxSound().loadEmbedded(Paths.song(daSong));
		FlxG.sound.music.pause();
		FlxG.sound.music.onComplete = function()
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
			curSection = 0;
			updateGrid();
		};
	}

	function addNote():Void
	{
		var noteData:Int = Math.floor((gridBG.x + (FlxG.mouse.x / gridSize)) - 2);
		var strumTime:Float = getStrumTime(dummyArrow.y) + sectionStartTime();

		var newNote:NoteData = {
			noteStrum: strumTime,
			noteData: noteData,
			noteSus: 0
		};

		if (song.notes[curSection] == null)
			addSection();

		song.notes[curSection].sectionNotes.push(newNote);

		updateGrid();

		for (note in renderedNotes.members)
			if (note != null && Math.abs(note.strum - strumTime) < 1 && note.rawNoteData == noteData)
				selectNote(note);
	}

	function deleteNote(note:Note):Void
	{
		for (sectionNote in song.notes[curSection].sectionNotes)
			if (sectionNote.noteStrum == note.strum && sectionNote.noteData % 4 == Util.getNoteIndex(note.dir))
				song.notes[curSection].sectionNotes.remove(sectionNote);

		updateGrid();
	}

	function selectNote(note:Note):Void
	{
		var swagNum:Int = 0;

		for (sectionNote in song.notes[curSection].sectionNotes)
		{
			if (sectionNote.noteStrum == note.strum && sectionNote.noteData % 4 == Util.getNoteIndex(note.dir))
				curSelectedNote = sectionNote;

			swagNum++;
		}

		updateGrid();
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			curSelectedNote.noteSus += value;
			curSelectedNote.noteSus = Math.max(curSelectedNote.noteSus, 0);
		}

		updateGrid();
	}

	public function updateGrid():Void
	{
		renderedNotes.forEach(function(note:Note)
		{
			note.kill();
			note.destroy();
		}, true);

		renderedNotes.clear();

		while (renderedSustains.members.length > 0)
			renderedSustains.remove(renderedSustains.members[0], true);

		for (sectionNote in song.notes[curSection].sectionNotes)
		{
			var daSus = sectionNote.noteSus;
			var direction:String = Util.getDirection(sectionNote.noteData % 4);
			var note:Note = new Note(0, 0, direction, 'note');
			note.strum = sectionNote.noteStrum;
			note.sustainLength = daSus;

			note.setGraphicSize(gridSize, gridSize);
			note.updateHitbox();

			note.x = gridBG.x + Math.floor((sectionNote.noteData % 4) * gridSize);
			note.y = Math.floor(getYfromStrum((sectionNote.noteStrum - sectionStartTime())));

			note.rawNoteData = sectionNote.noteData;

			renderedNotes.add(note);

			if (daSus > 0)
			{
				var rgb = SaveData.settings.notesRGB[sectionNote.noteData % 4];
				var sustainVis:FlxSprite = new FlxSprite(note.x + (gridSize / 2),
					note.y + gridSize).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, gridBG.height)),
						FlxColor.fromRGB(rgb[0], rgb[1], rgb[2]));
				renderedSustains.add(sustainVis);
			}
		}
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height, 0, Conductor.stepsPerSection * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, Conductor.stepsPerSection * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height);
	}

	function addSection(?coolLength:Int = 0):Void
	{
		var col:Int = Conductor.stepsPerSection;

		if (coolLength == 0)
			col = Std.int(Conductor.timeScale[0] * Conductor.timeScale[1]);

		var sec:SectionData = {
			sectionNotes: [],
			bpm: song.bpm,
			changeBPM: false,
			timeScale: Conductor.timeScale,
			changeTimeScale: false,
			stepsPerSection: 16
		};

		song.notes.push(sec);
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		trace('changing section' + sec);

		if (song.notes[sec] != null)
		{
			curSection = sec;

			if (curSection < 0)
				curSection = 0;

			updateGrid();

			if (updateMusic)
			{
				FlxG.sound.music.pause();

				FlxG.sound.music.time = sectionStartTime();
				updateCurStep();
			}

			updateGrid();
		}
		else
		{
			addSection();

			curSection = sec;

			if (curSection < 0)
				curSection = 0;

			updateGrid();

			if (updateMusic)
			{
				FlxG.sound.music.pause();

				FlxG.sound.music.time = sectionStartTime();
				updateCurStep();
			}

			updateGrid();
		}
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		updateCurStep();
		updateGrid();
	}

	function sectionStartTime(?section:Int):Float
	{
		if (section == null)
			section = curSection;

		var daBPM:Float = song.bpm;
		var daPos:Float = 0;

		for (i in 0...section)
		{
			if (song.notes[i].changeBPM)
				daBPM = song.notes[i].bpm;

			daPos += Conductor.timeScale[0] * (1000 * (60 / daBPM));
		}

		return daPos;
	}

	override function destroy()
	{
		Main.fpsDisplay.visible = SaveData.settings.fpsCounter;
		super.destroy();
	}

	function loadSongFromFile():Void
	{
		_file = new FileReference();
		_file.addEventListener(Event.SELECT, onFileSelected);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([#if !mac new FileFilter('JSON Files', '*.json') #end]);
	}

	function onFileSelected(event:Event):Void
	{
		_file.addEventListener(Event.COMPLETE, onLoadComplete);
		_file.load();
	}

	function onLoadComplete(event:Event):Void
	{
		_file.removeEventListener(Event.COMPLETE, onLoadComplete);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		var jsonData:String = _file.data.readUTFBytes(_file.data.length);
		var loadedSong:SongData = Json.parse(jsonData);

		song = loadedSong;
		updateGrid();
	}

	function onLoadError(event:IOErrorEvent):Void
	{
		_file.removeEventListener(Event.COMPLETE, onLoadComplete);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		trace('Error loading song: ' + event.text);
	}

	function saveSong():Void
	{
		var data:String = Json.stringify(song, null, '\t');
		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), Paths.formatToSongPath(song.song) + '.json');
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		trace('Successfully saved song.');
	}

	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		trace('Problem saving song');
	}
}

class LoadSongSubState extends ExtendableSubState
{
	var input:FlxUIInputText;

	public function new():Void
	{
		super(0xA6FFFFFF);
	}

	override public function create():Void
	{
		var text:FlxText = new FlxText(0, 180, 0, 'Enter a song to load.\n(Note: Unsaved progress will be lost!)', 32);
		text.setFormat(Paths.font('vcr.ttf'), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.screenCenter(X);
		add(text);

		input = new FlxUIInputText(10, 10, FlxG.width, '', 8);
		input.setFormat(Paths.font('vcr.ttf'), 96, FlxColor.WHITE, FlxTextAlign.CENTER);
		input.alignment = CENTER;
		input.setBorderStyle(OUTLINE, 0xFF000000, 5, 1);
		input.screenCenter();
		input.y += 50;
		input.backgroundColor = 0xFF000000;
		input.lines = 1;
		input.caretColor = 0xFFFFFFFF;
		add(input);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		input.hasFocus = true;

		if (Input.justPressed('accept') && input.text != '')
		{
			try
			{
				ChartingState.song = Song.loadSongfromJson(Paths.formatToSongPath(input.text));
				FlxG.resetState();
			}
			catch (e:Dynamic)
			{
				trace('Error loading chart!\n$e');
			}
		}
		else if (Input.justPressed('exit'))
			close();

		super.update(elapsed);
	}
}

class SongDataSubState extends ExtendableSubState
{
	var songNameInput:FlxInputText;
	var bpmInput:FlxInputText;
	var timeSignatureInput:FlxInputText;
	var inputs:Array<FlxInputText> = [];

	public function new():Void
	{
		super(0xA6FFFFFF);
	}

	override public function create():Void
	{
		var panelWidth = 500;
		var panelHeight = 300;
		var panelX = (FlxG.width - panelWidth) / 2;
		var panelY = (FlxG.height - panelHeight) / 2;

		var panel:RoundedSprite = new RoundedSprite(panelX, panelY, 500, 300, FlxColor.GRAY);
		panel.alpha = 0.9;
		add(panel);

		var title:FlxText = new FlxText(0, panelY + 10, FlxG.width, 'Edit Song Metadata', 20);
		title.alignment = CENTER;
		title.screenCenter(X);
		add(title);

		var fieldX = panelX + 30;
		var fieldY = panelY + 60;
		var spacing = 55;
		var labelWidth = 100;
		var inputOffset = 10;

		var label1:FlxText = new FlxText(fieldX, fieldY, labelWidth + 120, 'Name:', 16);
		songNameInput = new FlxInputText(fieldX + labelWidth + inputOffset, fieldY + 5, 300);
		songNameInput.text = ChartingState.song.song;
		inputs.push(songNameInput);
		add(label1);
		add(songNameInput);

		fieldY += spacing;
		var label2:FlxText = new FlxText(fieldX, fieldY, labelWidth, 'BPM:', 16);
		bpmInput = new FlxInputText(fieldX + labelWidth + inputOffset, fieldY + 5, 100);
		bpmInput.text = Std.string(ChartingState.song.bpm);
		inputs.push(bpmInput);
		add(label2);
		add(bpmInput);

		fieldY += spacing;
		var label3:FlxText = new FlxText(fieldX, fieldY, labelWidth + 200, 'Time Sig.:', 16);
		timeSignatureInput = new FlxInputText(fieldX + labelWidth + inputOffset, fieldY + 5, 150);
		timeSignatureInput.text = '${Std.string(ChartingState.song.timeSignature[0])},${Std.string(ChartingState.song.timeSignature[1])}';
		inputs.push(timeSignatureInput);
		add(label3);
		add(timeSignatureInput);

		var buttonY = panelY + panelHeight - 50;
		var saveBtn:FlxButton = new FlxButton(panelX + 80, buttonY, 'Save', function()
		{
			ChartingState.song.song = songNameInput.text;
			ChartingState.song.bpm = Std.parseFloat(bpmInput.text);
			ChartingState.song.timeSignature = [
				Std.parseInt(timeSignatureInput.text.split(',')[0]),
				Std.parseInt(timeSignatureInput.text.split(',')[1])
			];
			ChartingState.instance.updateGrid();
			close();
		});
		add(saveBtn);

		var cancelBtn:FlxButton = new FlxButton(panelX + panelWidth - 150, buttonY, 'Cancel', function()
		{
			close();
		});
		add(cancelBtn);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		var lockInputs:Bool = false;
		for (input in inputs)
		{
			if (input.hasFocus)
			{
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				lockInputs = true;
				break;
			}
		}

		if (!lockInputs)
		{
			FlxG.sound.muteKeys = [FlxKey.ZERO];
			FlxG.sound.volumeDownKeys = [FlxKey.MINUS];
			FlxG.sound.volumeUpKeys = [FlxKey.PLUS];
		}

		if (Input.justPressed('exit'))
			close();

		super.update(elapsed);
	}
}

class HelpSubState extends ExtendableSubState
{
	public function new():Void
	{
		super(0xA6FFFFFF);
	}

	override public function create():Void
	{
		var text:FlxText = new FlxText(0, 180, 0,
			'LEFT/RIGHT - Next/Previous Section\nLMB - Add/Remove Note\nCTRL + LMB - Select Note\nE/Q - Increase/Decrease Note Sustain\nSHIFT - Disable Chart Snapping\nSPACE - Play/Pause Music\nENTER - Playtest Chart',
			32);
		text.setFormat(Paths.font('vcr.ttf'), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.screenCenter();
		add(text);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		if (Input.justPressed('exit'))
			close();

		super.update(elapsed);
	}
}
