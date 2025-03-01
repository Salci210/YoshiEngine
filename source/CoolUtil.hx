package;

import flixel.util.FlxColor;
import openfl.display.BitmapData;
import lime.ui.FileDialogType;
import lime.ui.FileDialog;
import flixel.FlxState;
import flixel.FlxSprite;
import sys.FileSystem;
import flixel.FlxG;
import haxe.DynamicAccess;
import lime.utils.Assets;

using StringTools;

class CoolUtil
{
	/**
	* Array for difficulty names
	*/
	public static var difficultyArray:Array<String> = ['EASY', "NORMAL", "HARD"];

	public static function calculateAverageColorLight(icon:BitmapData) {
		var r:Float = 0;
		var g:Float = 0;
		var b:Float = 0;
		var t:Float = 0;
		for (x in 0...icon.width) {
			for (y in 0...icon.height) {
				var c:FlxColor = icon.getPixel32(x, y);
				r += c.redFloat * c.lightness * c.alpha;
				g += c.greenFloat * c.lightness * c.alpha;
				b += c.blueFloat * c.lightness * c.alpha;
				t += c.lightness * c.alpha;
			}
		}
		if (t == 0) {
			return 0xFF000000;
		} else {
			return FlxColor.fromRGBFloat(r / t, g / t, b / t);
		}
	}
	public static function calculateAverageColor(icon:BitmapData) {
		var r:Float = 0;
		var g:Float = 0;
		var b:Float = 0;
		var t:Float = 0;
		for (x in 0...icon.width) {
			for (y in 0...icon.height) {
				var c:FlxColor = icon.getPixel32(x, y);
				r += c.redFloat * c.alpha;
				g += c.greenFloat * c.alpha;
				b += c.blueFloat * c.alpha;
				t += c.alpha;
			}
		}
		if (t == 0) {
			return 0xFF000000;
		} else {
			return FlxColor.fromRGBFloat(r / t, g / t, b / t);
		}
	}

	public static function getMostPresentColor(icon:BitmapData) {
		var colors:Map<FlxColor, Int> = [];
		for (x in 0...icon.width) {
			for (y in 0...icon.height) {
				var c:FlxColor = cast(icon.getPixel32(x, y), FlxColor).to24Bit();
				if (colors[c] == null) {
					colors[c] = 1;
				} else {
					colors[c]++;
				}
			}
		}

		var maxColor:Int = 0xFF000000;
		var maxColorAmount:Int = 0;
		for (color=>amount in colors) {
			if (amount > maxColorAmount) {
				maxColor = color;
				maxColorAmount = amount;
			}
		}

		return maxColor;
	}

	public static function getMostPresentColor2(icon:BitmapData) {
		var colors:Map<FlxColor, Int> = [];
		for (x in 0...icon.width) {
			for (y in 0...icon.height) {
				var c:FlxColor = cast(icon.getPixel32(x, y), FlxColor).to24Bit();
				if (c.redFloat == 0 && c.greenFloat == 0 && c.blueFloat == 0) continue;
				if (colors[c] == null) {
					colors[c] = 1;
				} else {
					colors[c]++;
				}
			}
		}

		var maxColor:FlxColor = 0xFF000000;
		var maxColorAmount:Int = 0;
		for (color=>amount in colors) {
			if (amount > maxColorAmount && color.to24Bit() != FlxColor.BLACK) {
				maxColor = color;
				maxColorAmount = amount;
			}
		}

		return maxColor;
	}



	public static function addBG(f:FlxState) {
		var bg = new FlxSprite(0,0).loadGraphic(Paths.image("menuBGYoshi", "preload"));
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.screenCenter();
		f.add(bg);
		return bg;
	}

	public static function addWhiteBG(f:FlxState) {
		var bg = new FlxSprite(0,0).loadGraphic(Paths.image("menuDesat", "preload"));
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.screenCenter();
		bg.scrollFactor.set();
		f.add(bg);
		return bg;
	}

	public static function openDialogue(t:FileDialogType, name:String, callback:String->Void) {
		var fDial = new FileDialog();
		fDial.onSelect.add(callback);
		
		fDial.browse(t, null, null, name);
	}
	/**
	* Copies folder. Used to copy default skins to prevent crashes
	* 
	* @param path Path of the original folder
	* @param path Path of the new folder
	*/
	public static function deleteFolder(delete:String) {
		#if sys
		if (!sys.FileSystem.exists(delete)) return;
		var files:Array<String> = sys.FileSystem.readDirectory(delete);
		for(file in files) {
			if (sys.FileSystem.isDirectory(delete + "/" + file)) {
				deleteFolder(delete + "/" + file);
				FileSystem.deleteDirectory(delete + "/" + file);
			} else {
				FileSystem.deleteFile(delete + "/" + file);
			}
		}
		#end
	}
	
	public static function copyFolder(path:String, copyTo:String) {
		#if sys
		if (!sys.FileSystem.exists(copyTo)) {
			sys.FileSystem.createDirectory(copyTo);
		}
		var files:Array<String> = sys.FileSystem.readDirectory(path);
		for(file in files) {
			if (sys.FileSystem.isDirectory(path + "/" + file)) {
				copyFolder(path + "/" + file, copyTo + "/" + file);
			} else {
				sys.io.File.copy(path + "/" + file, copyTo + "/" + file);
			}
		}
		#end
	}

	/**
	* Get the difficulty name based on the actual song
	*/
	public static function difficultyString():String
	{
		// return difficultyArray[PlayState.storyDifficulty];
		return PlayState.storyDifficulty.toUpperCase();
	}

	public static function prettySong(song:String):String {
		var split = song.replace("-", " ").split(" ");
		for(i in 0...split.length) {
			if (split[i].length > 0) split[i] = split[i].charAt(0).toUpperCase() + split[i].substr(1).toLowerCase();
		}
		return split.join(" ");
	}

	/**
	* Get text, then convert it to a array of trimmed strings. Used for lists.
	* @param path Path of the text
	*/
	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = Assets.getText(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	/**
	* Creates an array of numbers. Equivalent of `[for (i in min...max) i]`.
	* @param max Maximum amount
	* @param min Number to start with
	*/
	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	public static function playMenuSFX(id:Int) {
		switch(id) {
			case 0:
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			case 1:
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.4);
			case 2:
				FlxG.sound.play(Paths.sound('cancelMenu'), 0.4);
		}
	}
	
	public static function wrapFloat(value:Float, min:Float, max:Float) {
		if (value < min)
			return min;
		if (value > max)
			return max;
		return value;
	}
	
	public static function addZeros(v:String, length:Int) {
		var r = v;
		while(r.length < length) {
			r = '0$r';
		}
		return r;
	}

	public static function getCharacterFullString(char:String, mod:String):String {
		return getCharacterFull(char, mod).join(":");
	}
	public static function getCharacterFull(char:String, mod:String):Array<String> {
		var splitChar = char.split(":");
		if (splitChar.length == 1) {
			for (fileExt in Main.supportedFileTypes) {
				if (FileSystem.exists('${Paths.modsPath}/$mod/characters/${splitChar[0]}/Character.$fileExt')) {
					splitChar.insert(0, mod);
					break;
				}
			}
			if (splitChar.length == 1) {
				for (fileExt in Main.supportedFileTypes) {
					if (FileSystem.exists('${Paths.modsPath}/Friday Night Funkin\'/characters/${splitChar[0]}/Character.$fileExt')) {
						splitChar.insert(0, "Friday Night Funkin'");
						break;
					}
				}
			}
		}
        if (splitChar.length == 1) splitChar = ["Friday Night Funkin'", "unknown"];

		
		return splitChar;
	}
	public static function getNoteTypeFullString(char:String, mod:String):String {
		return getNoteTypeFull(char, mod).join(":");
	}
	public static function getNoteTypeFull(char:String, mod:String):Array<String> {
		var splitChar = char.split(":");
		if (splitChar.length == 1) {
			for (fileExt in Main.supportedFileTypes) {
				if (FileSystem.exists('${Paths.modsPath}/$mod/notes/${splitChar[0]}.$fileExt')) {
					splitChar.insert(0, mod);
					break;
				}
			}
			if (splitChar.length == 1) {
				for (fileExt in Main.supportedFileTypes) {
					if (FileSystem.exists('${Paths.modsPath}/Friday Night Funkin\'/notes/${splitChar[0]}.$fileExt')) {
						splitChar.insert(0, "Friday Night Funkin'");
						break;
					}
				}
			}
		}
        if (splitChar.length == 1) splitChar = ["Friday Night Funkin'", "Default Note"];
		return splitChar;
	}
}
