package;

import flixel.input.keyboard.FlxKey;
import openfl.media.Sound;
import FreeplayGraph.GraphData;
import Highscore.AdvancedSaveData;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.ColorTween;
import haxe.Json;
import sys.io.File;
import sys.FileSystem;
import openfl.geom.ColorTransform;
import EngineSettings.Settings;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.FlxSound;
#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;

using StringTools;

/**
* Freeplay menu
*/
typedef FreeplaySongList = {
	public var songs:Array<FreeplaySong>;
}

typedef FreeplaySong = {
	public var name:String;
	public var char:String;
	public var displayName:String;
	public var difficulties:Array<String>;
	public var color:String;
	public var bpm:Null<Int>;
}
class FreeplayState extends MusicBeatState
{
	public static var songs:Array<SongMetadata> = null;

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var modSourceText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var songPlaying:FlxSound = null;

	
	var advancedBG:FlxSprite;
	var moreInfoText:FlxText;
	var accuracyText:FlxText;
	var missesText:FlxText;
	var graph:FlxSprite;
	var ratingTexts:Array<FlxText> = [];

	var bg:FlxSprite = null;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;
	private var instPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];
	
	var currentInstPath:String = "";
	var instCooldown:Float = 0;

	public static function loadFreeplaySongs() {
		var mPath = Paths.modsPath;
		
		songs = [];
		var fnfSongs = [];
		for(mod in FileSystem.readDirectory('$mPath/')) {
			if (FileSystem.exists('$mPath/$mod/data/freeplaySonglist.json')) {
				var jsonContent:FreeplaySongList = null;
				try {
					jsonContent = Json.parse(Paths.getTextOutsideAssets('$mPath/$mod/data/freeplaySonglist.json'));
				} catch(e) {
					trace('Freeplay song list for $mod is invalid.\r\n$e');
				}
				if (jsonContent.songs != null) {
					for(song in jsonContent.songs) {
						(mod == "Friday Night Funkin'" ? fnfSongs : songs).push(SongMetadata.fromFreeplaySong(song, mod));
					}
				}
			}
		}
		if (!(Settings.engineSettings.data.hideOriginalGame && songs.length > 0)) for (s in fnfSongs) songs.push(s);
	}
	override function create()
	{
		Assets.loadLibrary("songs");
		
		if (songs == null || Settings.engineSettings.data.developerMode) loadFreeplaySongs();
		// var initSonglist = ModSupport.getFreeplaySongs();

		// for (i in 0...initSonglist.length)
		// {
		// 	var splittedThingy:Array<String> = initSonglist[i].trim().split(":");
		// 	songs.push(new SongMetadata(splittedThingy[1], splittedThingy[0], splittedThingy[2]));
		// }

		/* 
			if (FlxG.sound.music != null)
			{
				if (!FlxG.sound.music.playing)
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		 */

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Freeplay Menu", null);
		#end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end


		// var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = FlxColor.fromRGB(129, 99, 223);
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songName = songs[i].songName;
			if (songs[i].displayName != null) songName = songs[i].displayName;
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			if (songText.width > FlxG.width - 256) {
				var ratio = (FlxG.width - 256) / songText.width;
				for (m in songText.members) {
					m.scale.x *= ratio;
					m.updateHitbox();
					m.x *= ratio;
				}
			}
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter, false, songs[i].mod);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		scoreText.antialiasing = true;
		// scoreText.alignment = RIGHT;

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 126, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		diffText.antialiasing = true;
		add(diffText);

		modSourceText = new FlxText(scoreText.x, diffText.y + 27, 0, "", 24);
		modSourceText.font = scoreText.font;
		modSourceText.antialiasing = true;
		add(modSourceText);

		moreInfoText = new FlxText(scoreText.x, modSourceText.y + 27, 0, "[Ctrl] for more info", 24);
		moreInfoText.font = scoreText.font;
		moreInfoText.antialiasing = true;
		add(moreInfoText);

		advancedBG = new FlxSprite(scoreText.x - 6, 126).makeGraphic(Std.int(FlxG.width * 0.35), 720 - 126, 0xFF000000);
		advancedBG.alpha = 0.4;
		add(advancedBG);

		accuracyText = new FlxText(scoreText.x, moreInfoText.y + 32, 0, "Accuracy : ???% (N/A)", 24);
		accuracyText.font = scoreText.font;
		accuracyText.antialiasing = true;
		add(accuracyText);

		missesText = new FlxText(scoreText.x, accuracyText.y + 27, 0, "??? Misses", 24);
		missesText.font = scoreText.font;
		missesText.antialiasing = true;
		add(missesText);

		graph = new FlxSprite(scoreText.x, missesText.y + 27 - 40).makeGraphic(350, 175, FlxColor.TRANSPARENT);
		graph.antialiasing = true;
		graph.x = advancedBG.x + 20;
		graph.flipX = true;
		graph.scale.x = graph.scale.y = 0.5;
		add(graph);

		if (!Settings.engineSettings.data.autoplayInFreeplay) {
			var t = new FlxText(scoreBG.x + 5, 0, scoreBG.width - 10, "[Space] Listen to selected song");
			t.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			t.y = 715 - t.height;
			add(t);
		}

		add(scoreText);

		for (k=>s in songs) {
			if ('${s.mod}:${s.songName.toLowerCase()}' == Settings.engineSettings.data.lastSelectedSong) {
				curSelected = k;
				break;
			}
		}
		curDifficulty = Std.int(Settings.engineSettings.data.lastSelectedSongDifficulty % songs[curSelected].difficulties.length);
		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		 
		advancedBG.visible = false;
		accuracyText.visible = false;
		missesText.visible = false;
		graph.visible = false;
		for(t in ratingTexts) {
			t.visible = false;
		}

		#if MOBILE_UI
			var closeButton = new FlxClickableSprite(15, 15);
			closeButton.frames = Paths.getSparrowAtlas("ui_buttons", "preload");
			closeButton.animation.addByPrefix("x", "x button");
			closeButton.animation.play("x");
			closeButton.key = FlxKey.BACKSPACE;
			add(closeButton);
		#end

		super.create();  
	}

	public function addSong(songName:String, modName:String, songCharacter:String)
	{
		songs.push(new SongMetadata(songName, modName, songCharacter));
	}

	// public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	// {
	// 	if (songCharacters == null)
	// 		songCharacters = ['bf'];

	// 	var num:Int = 0;
	// 	for (song in songs)
	// 	{
	// 		addSong(song, weekNum, songCharacters[num]);

	// 		if (songCharacters.length != 1)
	// 			num++;
	// 	}
	// }

	function updateAdvancedData() {
		var mod = ModSupport.getModName(songs[curSelected].mod);
		var song = songs[curSelected].songName;
		var diff = songs[curSelected].difficulties[curDifficulty];
		var daSong = 'advanced/' + Highscore.formatSong('$mod:$song', diff);
		#if debug
			trace(daSong);
		#end
		var advancedData:AdvancedSaveData = Reflect.field(FlxG.save.data, daSong);

		var acc = "???";
		var rating = "N/A";
		var misses = "???";
		
		for (t in ratingTexts) {
			remove(t);
			t.destroy();
		}
		
		if (advancedData != null) {
			acc = Std.string((Math.round(advancedData.accuracy * 10000) / 100));
			rating = advancedData.rating;
			misses = Std.string(advancedData.misses);
			
			var shit:Array<GraphData> = [];
			var tAm = 0;
			for(h in advancedData.hits) {
				var t = h.name;
				var am = h.amount;
				shit.push({color : h.color, number : h.amount});
				var r = new FlxText(scoreText.x, graph.y + (graph.height * 0.75) + (37 * tAm), 0, '$t: $am', 24);
				r.font = scoreText.font;
				r.borderStyle = FlxTextBorderStyle.OUTLINE;
				r.borderSize = 1;
				r.borderColor = FlxColor.BLACK;
				r.color = h.color;
				r.antialiasing = true;
				add(r);
				ratingTexts.push(r);
				tAm++;
			}
			shit.push({color : 0xFF222222, number : advancedData.misses});
			graph.alpha = 1;
			graph.pixels = FreeplayGraph.generate(shit, 350, 150, 30);
		} else {
			graph.alpha = 0;
		}
		// var acc = 
		accuracyText.text = 'Accuracy: $acc% ($rating)';
		missesText.text = '$misses Misses';
	}

	var shiftCooldown:Float = 0;

	function playSelectedSong() {
		instPlaying = true;
		currentInstPath = selectedSongInstPath;
		var ost = Sound.fromFile(currentInstPath);
		if (ost != null) {
			FlxG.sound.playMusic(ost, 0);
			FlxG.sound.music.persist = true;
		}
		trace(songs[curSelected].bpm);
		if (songs[curSelected].bpm == null) {
			iconBumping = false;
		} else {
			Conductor.lastSongPos = 0;
			Conductor.songPosition = 0;
			Conductor.bpmChangeMap = [];
			Conductor.changeBPM(songs[curSelected].bpm);
			iconBumping = true;
		}
	}

	var iconBumping = true;

	public override function beatHit() {
		super.beatHit();
		// trace(selectedSongInstPath);
		// trace(currentInstPath);
		// trace(iconBumping);
		if ((selectedSongInstPath == currentInstPath) && iconBumping) {
			var i = iconArray[curSelected];
			i.scale.set(1.2, 1.2);
		}
	}
	var selectedSongInstPath = "";
	override function update(elapsed:Float)
	{
		Conductor.songPosition = FlxG.sound.music == null ? 0 : FlxG.sound.music.time;
		super.update(elapsed);
		shiftCooldown += elapsed;
		for (i in iconArray) {
			i.scale.x = i.scale.y = FlxMath.lerp(i.scale.x, 1, 0.50 * 60 * elapsed);
		}

		if (!instPlaying && Settings.engineSettings.data.autoplayInFreeplay) {
			instCooldown += elapsed;
			if (instCooldown > Settings.engineSettings.data.freeplayCooldown) {
				playSelectedSong();
			}
		}
		if (instPlaying) {

			if (FlxG.sound.music.volume < 0.7)
			{
				FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			}
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4 * 60 * elapsed));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + lerpScore;

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;
		var cursorAccept = false;
		if (FlxG.mouse.justPressed) {
			var posY = FlxG.mouse.getScreenPosition().y;
			var posX = FlxG.mouse.getScreenPosition().x;
			if (posX < advancedBG.x) {
				var i = Math.floor(posY / 720 * 5) - 2;
				if (i == 0) {
					accepted = true;
					cursorAccept = true;
				} else {
					changeSelection(i);
				}
			} else {
				if (posY < moreInfoText.y + moreInfoText.height && posY > moreInfoText.y)
					showAdvancedData();
				else {
					if (posY < diffText.y + diffText.height && posY > diffText.y) {
						if (posX < diffText.x + (diffText.width / 2))
							changeDiff(-1);
						else
							changeDiff(1);
					}
				}

			}
		}

		if (FlxG.mouse.wheel != 0) changeSelection(-FlxG.mouse.wheel);
		if (upP || (controls.UP && FlxControls.pressed.SHIFT && shiftCooldown > 0.05))
		{
			changeSelection(-1);
			shiftCooldown = 0;
		}
		if (downP || (controls.DOWN && FlxControls.pressed.SHIFT && shiftCooldown > 0.05))
		{
			changeSelection(1);
			shiftCooldown = 0;
		}

		if (controls.LEFT_P)
			changeDiff(-1);
		if (controls.RIGHT_P || FlxG.mouse.justReleasedRight)
			changeDiff(1);

		if (controls.BACK)
		{
			if (Settings.engineSettings.data.memoryOptimization) {
				// for (k=>v in ) {
				// 	trace(k);
				// 	v.dispose();
				// 	Assets.cache.audio.remove(k);
				// }
				
				openfl.utils.Assets.cache.clear("assets");

			}
			FlxG.switchState(new MainMenuState());
			
		}

		if (FlxControls.pressed.ENTER || (accepted && Settings.engineSettings.data.autoplayInFreeplay) || cursorAccept)
		{
			select();
		}
		if (FlxControls.pressed.SPACE) {
			if (selectedSongInstPath == currentInstPath) {
				select();
			} else {
				playSelectedSong();
			}
		}

		if (FlxControls.justReleased.CONTROL) {
			showAdvancedData();
		}
	}
	
	function showAdvancedData() {
		if (advancedBG.visible) {
			advancedBG.visible = false;
			accuracyText.visible = false;
			missesText.visible = false;
			graph.visible = false;
			for(t in ratingTexts) {
				t.visible = false;
			}
		} else {
			advancedBG.visible = true;
			accuracyText.visible = true;
			missesText.visible = true;
			graph.visible = true;
			for(t in ratingTexts) {
				t.visible = true;
			}
			updateAdvancedData();
		}
	}

	function select() {
		var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), songs[curSelected].difficulties[curDifficulty]);

		trace(poop);

		Settings.engineSettings.data.lastSelectedSong = '${songs[curSelected].mod}:${songs[curSelected].songName.toLowerCase()}';
		Settings.engineSettings.data.lastSelectedSongDifficulty = curDifficulty;
		// PlayState._SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
		try {
			PlayState._SONG = Song.loadModFromJson(poop, songs[curSelected].mod, songs[curSelected].songName.toLowerCase());
		} catch(e) {
			openSubState(new MenuMessage('Error while loading the chart. Make sure the ${songs[curSelected].difficulties[curDifficulty]} chart for ${songs[curSelected].songName} exists in the ${songs[curSelected].mod} mod.'));
			return;
		}
		PlayState._SONG.validScore = true;
		PlayState.isStoryMode = false;
		PlayState.songMod = songs[curSelected].mod;
		PlayState.storyDifficulty = songs[curSelected].difficulties[curDifficulty];
		PlayState.fromCharter = false;

		// PlayState.storyWeek = songs[curSelected].week;
		trace('CUR WEEK' + PlayState.storyWeek);
		LoadingState.loadAndSwitchState(new PlayState());
	}

	function updateSongInstPath() {
		selectedSongInstPath = Paths.getInstPath(songs[curSelected].songName, songs[curSelected].mod, songs[curSelected].difficulties[curDifficulty]);
	}
	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = songs[curSelected].difficulties.length - 1;
		if (curDifficulty >= songs[curSelected].difficulties.length)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getModScore(songs[curSelected].mod, songs[curSelected].songName, songs[curSelected].difficulties[curDifficulty]);
		#end
		

		// switch (curDifficulty)
		// {
		// 	case 0:
		// 		diffText.text = "EASY";
		// 	case 1:
		// 		diffText.text = 'NORMAL';
		// 	case 2:
		// 		diffText.text = "HARD";
		// }
		var dText = songs[curSelected].difficulties[curDifficulty].toUpperCase();
		if (songs[curSelected].difficulties.length > 1) dText = '< $dText >';
		diffText.text = dText;

		if (advancedBG.visible) {
			updateAdvancedData();
		}
		updateSongInstPath();
	}

	var colorTween:ColorTween;

	function changeSelection(change:Int = 0)
	{
		// // NGio .logEvent('Fresh');
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var diff = songs[curSelected].difficulties[curDifficulty];
		var oldNumDiff = songs[curSelected].difficulties.length;
		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		if (colorTween == null) {
			colorTween = FlxTween.color(bg, 1.5, bg.color, songs[curSelected].color, {ease: FlxEase.quintOut});
		} else if (songs[curSelected].color == colorTween.color) {

		} else {
			colorTween.cancel();
			colorTween = FlxTween.color(bg, 1.5, bg.color, songs[curSelected].color, {ease: FlxEase.quintOut});
		}
		

		var difficultyShit = songs[curSelected].difficulties.indexOf(diff);
		if (difficultyShit != -1) {
			curDifficulty = difficultyShit;
		} else {
			curDifficulty = Math.floor(curDifficulty / oldNumDiff * songs[curSelected].difficulties.length);
		}
		changeDiff(0);

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getModScore(songs[curSelected].mod, songs[curSelected].songName, songs[curSelected].difficulties[curDifficulty]);
		// lerpScore = 0;
		#end

		
		
		// FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
		if (Settings.engineSettings.data.autoplayInFreeplay)
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
		instPlaying = false;
		instCooldown = 0;

		modSourceText.text = ModSupport.getModName(songs[curSelected].mod);
		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}

		if (advancedBG.visible) {
			updateAdvancedData();
		}
	}

	public override function destroy() {
		super.destroy();

		
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var displayName:String = null;
	public var mod:String = "";
	public var bpm:Null<Int> = null;
	public var songCharacter:String = "";

	public var difficulties:Array<String> = ["Easy", "Normal", "Hard"];
	public var color:FlxColor = FlxColor.fromRGB(165, 128, 255);

	public static function fromFreeplaySong(song:FreeplaySong, mod:String) {
		var songName = song.name;
		var songCharacter = song.char;
		if (songCharacter == null) {
			songCharacter == "gf";
		}

		var m = new SongMetadata(songName, mod, songCharacter);
		if (song.difficulties != null) {
			m.difficulties = song.difficulties;
		}
		var parsedColor = FlxColor.fromString(song.color);
		m.color = (parsedColor == null) ? FlxColor.fromRGB(129, 99, 223) : parsedColor;
		m.bpm = song.bpm;

		if (song.displayName != null) m.displayName = song.displayName;

		return m;
	}
	public function new(song:String, mod:String, songCharacter:String)
	{
		this.songName = song;
		this.mod = mod;
		this.songCharacter = songCharacter;
	}
}
