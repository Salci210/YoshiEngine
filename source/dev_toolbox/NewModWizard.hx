package dev_toolbox;

import haxe.Json;
import sys.io.File;
import flixel.group.FlxGroup;
import lime.graphics.Image;
import lime.app.Application;
import ModSupport.ModConfig;
import flixel.addons.transition.FlxTransitionableState;
import lime.ui.FileDialogType;
import openfl.display.BitmapData;
import lime.ui.FileDialog;
import flixel.addons.ui.FlxUIDropDownMenu.FlxUIDropDownHeader;
import sys.FileSystem;
import flixel.FlxSprite;
import flixel.text.FlxText.FlxTextAlign;
import flixel.util.FlxColor;
import openfl.sensors.Accelerometer;
import flixel.addons.ui.*;
import flixel.FlxG;
import flixel.FlxState;

// You're a wizard, Harry !
class NewModWizard extends MusicBeatState {

    public override function new() {
        #if desktop
            Discord.DiscordClient.changePresence("Creating a new mod...", null, "Toolbox Icon");
        #end
        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;
        super();
        CoolUtil.addBG(this);
        var tabs = [
			{name: "main", label: 'New mod wizard'}
		];
        var UI_Main = new FlxUITabMenu(null, tabs, true);
        UI_Main.resize(640, 308);
        UI_Main.screenCenter();
        add(UI_Main);

        var closeButton = new FlxUIButton(UI_Main.x + UI_Main.width - 23, UI_Main.y + 3, "X", function() {
            FlxG.switchState(new ToolboxMain());
        });
        closeButton.color = 0xFFFF4444;
        closeButton.label.color = FlxColor.WHITE;
        closeButton.resize(20, 20);
        add(closeButton);

        
		var tab = new FlxUI(null, UI_Main);
		tab.name = "main";
        
		var label = new FlxUIText(10, 10, 620, "Mod name");
        var mod_name = new FlxUIInputText(10, label.y + label.height, 620, "New Mod");
        tab.add(label);
        tab.add(mod_name);

		var label = new FlxUIText(10, mod_name.y + mod_name.height + 10, 620, "Mod description");
        var mod_description = new FlxUIInputText(10, label.y + label.height, 620, "(No description)");
        tab.add(label);
        tab.add(mod_description);

		var label = new FlxUIText(10, mod_description.y + mod_description.height + 10, 620, "Titlebar Name");
        var titlebarName = new FlxUIInputText(10, label.y + label.height, 500, "Friday Night Funkin - Mod Name");
        tab.add(label);
        tab.add(titlebarName);

        var icon = new FlxUISprite(520, titlebarName.y).loadGraphic(Paths.image("defaultTitlebarIcon", "preload"));
        icon.antialiasing = true;
        icon.setGraphicSize(20, 20);
        icon.updateHitbox();
        tab.add(icon);

        var chooseIconButton = new FlxUIButton(icon.x + 30, icon.y, "Choose game icon", function() {
            var fDial = new FileDialog();
			fDial.onSelect.add(function(path) {
				var img = Paths.getBitmapOutsideAssets(path);
                if (img == null) return;
                icon.loadGraphic(img);
                icon.setGraphicSize(20, 20);
                icon.updateHitbox();
			});
			fDial.browse(FileDialogType.OPEN, null, null, "Select an icon.");
        });
        chooseIconButton.resize(620 - 546, 20);
        tab.add(chooseIconButton);

        var modIcon = new FlxUISprite(10, titlebarName.y + titlebarName.height + 10).loadGraphic(Paths.image("modEmptyIcon", "preload"));
        modIcon.setGraphicSize(150, 150);
        modIcon.updateHitbox();
        tab.add(modIcon);

        var chooseIconButton = new FlxUIButton(modIcon.x + modIcon.width + 10, modIcon.y, "Choose a mod icon", function() {
            var fDial = new FileDialog();
			fDial.onSelect.add(function(path) {
				var img = Paths.getBitmapOutsideAssets(path);
                if (img == null) return;
                modIcon.loadGraphic(img);
                modIcon.setGraphicSize(150, 150);
                modIcon.updateHitbox();
			});
			fDial.browse(FileDialogType.OPEN, null, null, "Select an mod icon.");
        });
        chooseIconButton.resize(150, 20);
        tab.add(chooseIconButton);

        var createButton = new FlxUIButton(640 - 110, 308 - 50, "Create your mod", function() {
            var folderName = Toolbox.generateModFolderName(mod_name.text);
            trace(folderName);
            if (FileSystem.exists('${Paths.modsPath}/$folderName')) {
                openSubState(ToolboxMessage.showMessage("Error", 'The folder for your mod ("$folderName") already exists. Please rename the existing one or give another name to your mod.'));
                return;
            }
            
            var json:ModConfig = {
                titleBarName: titlebarName.text,
                name: mod_name.text,
                description: mod_description.text,
                keyNumbers: [4],
                skinnableGFs: [],
                skinnableBFs: [],
                BFskins: [],
                GFskins: [],
                locked: false
            }

            Toolbox.createMod(json, folderName, modIcon.pixels, icon.pixels);
            openSubState(ToolboxMessage.showMessage("Success", 'Your mod has been created.', function() {
                FlxG.switchState(new ToolboxMain(folderName));
                
            }));
        });
        createButton.resize(100, 20);
        tab.add(createButton);

        var testTitlebarButton = new FlxUIButton(640 - 230, 308 - 50, "Test your titlebar", function() {
            Application.current.window.title = titlebarName.text;
            Application.current.window.setIcon(icon.pixels.image);

        });
        testTitlebarButton.resize(110, 20);
        tab.add(testTitlebarButton);
		UI_Main.addGroup(tab);
    }
}