package dev_toolbox;

import openfl.display.PNGEncoderOptions;
import flixel.addons.transition.FlxTransitionableState;
import haxe.Json;
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import flixel.util.FlxColor;
import flixel.FlxG;
import openfl.display.BitmapData;
import flixel.addons.ui.*;
import flixel.FlxSprite;

using StringTools;

class CharacterCreator extends MusicBeatSubstate {
    public override function new() {
        super();
        var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(1280, 720, 0x88000000);
        add(bg);

        var tabs = [
            {name: "char", label: 'Create a character'}
		];
        var UI_Tabs = new FlxUITabMenu(null, tabs, true);
        UI_Tabs.x = 0;
        UI_Tabs.resize(420, 720);
        UI_Tabs.scrollFactor.set();
        add(UI_Tabs);

		var tab = new FlxUI(null, UI_Tabs);
		tab.name = "char";

		var label = new FlxUIText(10, 10, 400, "Character name");
        var char_name = new FlxUIInputText(10, label.y + label.height, 400, "your-char");
        tab.add(label);
        tab.add(char_name);

		var label = new FlxUIText(10, char_name.y + char_name.height + 10, 400, "Character Icon");
        var char_icon:BitmapData = null;
        var icon_path_button:FlxUIButton = null;
        icon_path_button = new FlxUIButton(10, label.y + label.height, "Browse...", function() {
            CoolUtil.openDialogue(OPEN, "Select your character's icon grid.", function(path) {
                char_icon = BitmapData.fromFile(path);
                if (char_icon == null) {
                    icon_path_button.color = 0xFFFF2222;
                    icon_path_button.label.text = "(Browse...) File couldn't be opened.";
                    return;
                }
                var res = Math.floor(char_icon.width / 150) * Math.floor(char_icon.height / 150);
                if (res < 1) {
                    icon_path_button.color = 0xFFFF2222;
                    icon_path_button.label.text = "(Browse...) The 150x150 grid must have 1 sprite or more.";
                    return;
                }
                icon_path_button.color = 0xFF22FF22;
                icon_path_button.label.text = '(Browse...) $res icons loaded.';
            });
        });
        icon_path_button.resize(400, 20);
        tab.add(label);
        tab.add(icon_path_button);

		var label = new FlxUIText(10, icon_path_button.y + icon_path_button.height + 10, 400, "Character Spritesheet");
        var char_spritesheet:String = null;
        var spritesheet_path_button:FlxUIButton = null;
        spritesheet_path_button = new FlxUIButton(10, label.y + label.height, "Browse...", function() {
            CoolUtil.openDialogue(OPEN, "Select your character's spritesheet.png or spritesheet.xml.", function(path) {
                var areFilesThere = [false, false];
                char_spritesheet = "";
                if (Path.extension(path) == "xml") {
                    areFilesThere[1] = true;
                    if (FileSystem.exists(Path.withoutExtension(path) + ".png")) {
                        areFilesThere[0] = true;
                    }
                } else if (Path.extension(path) == "png") {
                    areFilesThere[0] = true;
                    if (FileSystem.exists(Path.withoutExtension(path) + ".xml")) {
                        areFilesThere[1] = true;
                    }
                } else {
                    spritesheet_path_button.color = 0xFFFF2222;
                    spritesheet_path_button.label.text = "(Browse...) Selected file isn't of type XML or PNG.";
                    return;
                }

                if (!areFilesThere[0]) {
                    spritesheet_path_button.color = 0xFFFF2222;
                    spritesheet_path_button.label.text = "(Browse...) PNG file is missing.";
                    return;
                }
                if (!areFilesThere[1]) {
                    spritesheet_path_button.color = 0xFFFF2222;
                    spritesheet_path_button.label.text = "(Browse...) XML file is missing.";
                    return;
                }
                var bMap = BitmapData.fromFile(Path.withoutExtension(path) + ".png");
                if (bMap == null) {
                    spritesheet_path_button.color = 0xFFFF2222;
                    spritesheet_path_button.label.text = '(Browse...) PNG file is invalid.';
                    return;
                }
                bMap.dispose();
                char_spritesheet = Path.withoutExtension(path);
                spritesheet_path_button.color = 0xFF22FF22;
                spritesheet_path_button.label.text = '(Browse...) Spritesheet selected.';
            });
        });
        spritesheet_path_button.resize(400, 20);
        tab.add(label);
        tab.add(spritesheet_path_button);
        
        var createButton:FlxUIButton = null;
        createButton = new FlxUIButton(10, spritesheet_path_button.y + spritesheet_path_button.height + 10, "Create", function() {
            var charName = Toolbox.generateModFolderName(char_name.text);
            if (FileSystem.exists('${Paths.modsPath}/${ToolboxHome.selectedMod}/characters/$charName')) {
                createButton.color = 0xFFFF2222;
                createButton.label.text = "(Create) Character with this name already exists.";
                return;
            }
            if (char_icon == null) {
                createButton.color = 0xFFFF2222;
                createButton.label.text = icon_path_button.color == 0xFFFF2222 ? "(Create) Icon Grid is invalid." : "(Create) Character's icon grid haven't been selected yet.";
                return;
            }
            if (char_spritesheet == null || char_spritesheet.trim() == "") {
                createButton.color = 0xFFFF2222;
                createButton.label.text = spritesheet_path_button.color == 0xFFFF2222 ? "(Create) Spritesheet is invalid." : "(Create) Character's Spritesheet haven't been selected yet.";
                return;
            }
            FileSystem.createDirectory('${Paths.modsPath}/${ToolboxHome.selectedMod}/characters/$charName');
            var averageColor:FlxColor;
            {
                var cR:Float = 0;
                var cG:Float = 0;
                var cB:Float = 0;
                var cT:Float = 0;
                for(x in 0...char_icon.width) {
                    for(y in 0...char_icon.height) {
                        var c:FlxColor = char_icon.getPixel32(x, y);
                        cR += c.redFloat * c.alphaFloat;
                        cG += c.greenFloat * c.alphaFloat;
                        cB += c.blueFloat * c.alphaFloat;
                        cT += c.alphaFloat;
                    }
                }
                averageColor = FlxColor.fromRGBFloat(cR / cT, cG / cT, cB / cT);
            }
            var json:CharacterJSON = {
                anims: [],
                globalOffset: {
                    x: 0,
                    y: 0
                },
                camOffset: {
                    x: 0,
                    y: 0
                },
                antialiasing: true,
                scale: 1,
                danceSteps: ["idle"],
                healthIconSteps: [[20, 0], [0, 1]],
                healthbarColor: averageColor.toWebString(),
                arrowColors: null,
                flipX: false
            };
            File.saveContent('${Paths.modsPath}/${ToolboxHome.selectedMod}/characters/$charName/Character.json', Json.stringify(json, "\t"));
            File.copy(char_spritesheet + ".xml", '${Paths.modsPath}/${ToolboxHome.selectedMod}/characters/$charName/spritesheet.xml');
            File.copy(char_spritesheet + ".png", '${Paths.modsPath}/${ToolboxHome.selectedMod}/characters/$charName/spritesheet.png');
            var characterHX = 'function create() {\r\n\tcharacter.frames = Paths.getCharacter(character.curCharacter);\r\n\tcharacter.loadJSON(true);\r\n}';
            File.saveContent('${Paths.modsPath}/${ToolboxHome.selectedMod}/characters/$charName/Character.hx', characterHX);
            File.saveBytes('${Paths.modsPath}/${ToolboxHome.selectedMod}/characters/$charName/icon.png', char_icon.encode(char_icon.rect, new PNGEncoderOptions(true)));

            openSubState(ToolboxMessage.showMessage("Success", "Character successfully created.", function() {
                close();
                FlxTransitionableState.skipNextTransIn = true;
                FlxTransitionableState.skipNextTransOut = true;
                FlxG.resetState();
            }));
        });
        createButton.resize(400, 20);
        tab.add(createButton);

        UI_Tabs.addGroup(tab);
        UI_Tabs.resize(420, 30 + createButton.y + createButton.height);
        UI_Tabs.screenCenter();

        var closeButton = new FlxUIButton(UI_Tabs.x + UI_Tabs.width - 23, UI_Tabs.y + 3, "X", function() {
            close();
        });
        closeButton.color = 0xFFFF4444;
        closeButton.resize(20, 20);
        closeButton.label.color = FlxColor.WHITE;
        add(closeButton);
    }
}