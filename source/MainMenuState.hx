package;

import dev_toolbox.ToolboxMessage;
import flixel.input.keyboard.FlxKey;
import flixel.addons.ui.FlxUIButton;
import lime.utils.Assets;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileCircle;
import EngineSettings.Settings;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
#if newgrounds
import io.newgrounds.NG;
import io.newgrounds.components.MedalComponent;
#end
import flixel.math.FlxPoint;
import lime.app.Application;

using StringTools;

class MainMenuState extends MusicBeatState
{
	var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	#if !switch
	var optionShit:Array<String> = ['story mode', 'freeplay', 'mods', 'donate', 'credits', 'options'];
	#else
	var optionShit:Array<String> = ['story mode', 'freeplay', 'options'];
	#end

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var backButton:FlxClickableSprite;

	var factor(get, never):Float;
	function get_factor() {
		return 650 / optionShit.length;
	}

	override function create()
	{
        persistentUpdate = false;
		if (Settings.engineSettings.data.developerMode) {
			optionShit.insert(4, 'toolbox');
		}
		if (Settings.engineSettings.data.memoryOptimization) {
			// Paths.clearCache();
			openfl.utils.Assets.cache.clear();
			Assets.cache.clear();
		}
			
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Main Menu", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		} else {
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		var fallBackBG:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFFFDE871);
		fallBackBG.scrollFactor.set();
		add(fallBackBG);

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);
		

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.x = 0;
		magenta.scrollFactor.y = 0.18;
		magenta.setGraphicSize(Std.int(magenta.width * 1.1));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = true;
		magenta.color = 0xFFfd719b;
		add(magenta);
		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var tex = Paths.getSparrowAtlas('FNF_main_menu_assets');

		for (i in 0...optionShit.length)
		{
			// var menuItem:FlxSprite = new FlxSprite(0, 60 + (i * 160));
			var menuItem:FlxSprite = new FlxSprite(0, (FlxG.height / optionShit.length * i) + (FlxG.height / (optionShit.length * 2)));
			menuItem.frames = tex;
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.updateHitbox();
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItem.scrollFactor.set(0, 1 / (optionShit.length));
			menuItem.setGraphicSize(Std.int(factor / menuItem.height * menuItem.width), Std.int(factor));
			menuItem.y -= menuItem.height / 2;
			menuItem.antialiasing = true;
			menuItems.add(menuItem);
		}

		FlxG.camera.follow(camFollow, null, 0.06 * 60 / Settings.engineSettings.data.fpsCap);

		var fnfVer = Application.current.meta.get('version');
		var yoshiEngineVer = Main.engineVer.join(".");
		var buildVer = Main.buildVer;
		if (buildVer.trim() != "") buildVer = " " + buildVer.trim();
		var versionShit:FlxText = new FlxText(5, FlxG.height - 18, 0, 'Yoshi Engine v$yoshiEngineVer$buildVer - FNF v$fnfVer', 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if MOBILE_UI
		backButton = new FlxClickableSprite(10, versionShit.y, function() {
			FlxG.switchState(new TitleState());
		});
		backButton.frames = Paths.getSparrowAtlas("ui_buttons", "preload");
		backButton.animation.addByPrefix("button", "exit button");
		backButton.animation.play("button");
		// backButton.scale.x = backButton.scale.y = 0.7;
		backButton.updateHitbox();
		backButton.y -= 10 + backButton.height;
		backButton.scrollFactor.set(0, 0);
		backButton.antialiasing = true;
		backButton.hoverColor = 0xFF66CAFF;
		add(backButton);
		#end

		super.create();
	}

	var selectedSomethin:Bool = false;
	var oldPos = FlxG.mouse.getScreenPosition();
	// static function calculatePos() {
	// 	return new FlxPoint(FlxG.game.mouseX / FlxG.scaleMode.gameSize.x * 1280, FlxG.game.mouseY / FlxG.scaleMode.gameSize.y * 720);
	// }
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (subState != null) return;

		if (FlxControls.justPressed.SEVEN) {
			if (Settings.engineSettings.data.developerMode) {
				// psych engine shortcut lol
				FlxG.switchState(new dev_toolbox.ToolboxMain());
			} else {
				openSubState(new ThisAintPsych());
			}
		}
		if ((FlxG.mouse.getScreenPosition().x != oldPos.x || FlxG.mouse.getScreenPosition().y != oldPos.y) && !selectedSomethin){
			oldPos = FlxG.mouse.getScreenPosition();
			for (i in 0...menuItems.length) {
				// if (FlxG.mouse.overlaps(menuItems.members[i])) {
				var pos = FlxG.mouse.getPositionInCameraView(FlxG.camera);
				if (pos.y > i / menuItems.length * FlxG.height && pos.y < (i + 1) / menuItems.length * FlxG.height && curSelected != i) {
					curSelected = i;
					changeItem();
					break;
				}
			}
		}
		if (FlxG.mouse.pressed && !selectedSomethin
			#if MOBILE_UI
			&& !backButton.hovering
			#end
			)
			select();

		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (!selectedSomethin)
		{
			if (controls.UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				FlxG.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				select();
			}
		}


		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});
	}

	function select() {
		if (optionShit[curSelected] == 'donate')
			{
				#if linux
				Sys.command('/usr/bin/xdg-open', ["https://ninja-muffin24.itch.io/funkin", "&"]);
				#else
				FlxG.openURL('https://ninja-muffin24.itch.io/funkin');
				#end
			}
			else
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				FlxFlicker.flicker(magenta, 1.1, 0.15, false);

				menuItems.forEach(function(spr:FlxSprite)
				{
					if (curSelected != spr.ID)
					{
						FlxTween.tween(spr, {alpha: 0}, 0.4, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween)
							{
								spr.kill();
							}
						});
					}
					else
					{
						FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
						{
							var daChoice:String = optionShit[curSelected];

							switch (daChoice)
							{
								case 'story mode':
									FlxG.switchState(new StoryMenuState());
									trace("Story Menu Selected");
								case 'freeplay':
									FlxG.switchState(new FreeplayState());
									trace("Freeplay Menu Selected");
								
								case 'mods':
									FlxG.switchState(new ModMenuState());
									trace ("Mods Menu Selected");
								
								case 'credits':
									FlxG.switchState(new CreditsState());
									trace ("Credits Menu Selected");
								
								case 'toolbox':
									FlxG.switchState(new dev_toolbox.ToolboxMain());
									trace ("Developer Toolbox Selected");

								case 'options':
									FlxTransitionableState.skipNextTransIn = true;
									FlxTransitionableState.skipNextTransOut = true;
									OptionsMenu.fromFreeplay = false;
									FlxG.switchState(new OptionsMenu(0, -camFollow.y * 0.18));
							}
						});
					}
				});
			}
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.offset.set(0,0);

			if (spr.ID == curSelected)
			{
				// spr.offset.set(0,-(Math.max(0, spr.height - spr.frames.getByIndex(spr.animation.getByName("idle").frames[0]).sourceSize.y)) / FlxG.height * spr.y);
				spr.animation.play('selected');
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
			}

			spr.updateHitbox();
		});
	}
}
