package;

import dev_toolbox.ToolboxMessage;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import lime.graphics.Image;
import openfl.display.Application;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.addons.transition.TransitionData;
import EngineSettings.Settings;
import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;

typedef FlxSpriteTypedGroup = FlxTypedGroup<FlxSprite>;
typedef FlxSpriteArray = Array<FlxSprite>;

class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var controls(get, never):Controls;

	public static var defaultIcon:Image = null;

	public function new(?transIn:TransitionData, ?transOut:TransitionData) {
		
		if (Settings.engineSettings != null) {
			if (Settings.engineSettings.data.developerMode) {
				try {
					Paths.clearCache();
				} catch(e) {

				}
			}
			Settings.engineSettings.flush();
		}
		if (FlxG.save.data != null) {
			FlxG.save.flush();
		}
		#if !android
			@:privateAccess
			FlxG.width = 1280;
			@:privateAccess
			FlxG.height = 720;
		#end
		
		FlxG.scaleMode = new RatioScaleMode();
		super(transIn, transOut);

		if (defaultIcon == null) defaultIcon = Image.fromFile("assets/images/icon.png");
		lime.app.Application.current.window.title = "Friday Night Funkin' - Yoshi Engine";
		if (PlayState.iconChanged) {
			lime.app.Application.current.window.setIcon(defaultIcon);
			PlayState.iconChanged = false;
		}
	}

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function create()
	{
		if (transIn != null)
			trace('reg ' + transIn.region);

		super.create();
		if (EngineSettings.Settings.engineSettings != null) {
			FlxG.drawFramerate = EngineSettings.Settings.engineSettings.data.fpsCap;
			FlxG.updateFramerate = EngineSettings.Settings.engineSettings.data.fpsCap;
		}
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();
		
		if (oldStep < curStep && curStep > 0)
			stepHit();
		// if (oldStep < curStep)

		super.update(elapsed);

		/*
		if (Settings.engineSettings != null)
			if (!Settings.engineSettings.data.antialiasing)
				for(e in members)
					if (Std.isOfType(e, FlxSprite))
						cast(e, FlxSprite).antialiasing = false;
		*/
		if (Settings.engineSettings != null) {
			if (!Settings.engineSettings.data.antialiasing) {
				for(e in members) {
					if (Std.isOfType(e, FlxSprite)) {
						cast(e, FlxSprite).antialiasing = false;
					} else if (Std.isOfType(e, FlxSpriteGroup)) {
						var grp:FlxSpriteGroup = cast e;
						for (m in grp.members) {
							m.antialiasing = false;
						}
					} else if (Std.isOfType(e, FlxSpriteTypedGroup)) {
						var grp:FlxTypedGroup<FlxSprite> = cast e;
						for (m in grp.members) {
							m.antialiasing = false;
						}
					}
				}
			}
		}
			
				
					
	}

	private function updateBeat():Void
	{
		curBeat = Std.int(Math.floor(curStep / 4));
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = Std.int(lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet));
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}

	public function onDropFile(path:String) {
		
	}

    function showMessage(title:String, text:String) {
        var m = ToolboxMessage.showMessage(title, text);
        m.cameras = cameras;
        openSubState(m);
    }
}
