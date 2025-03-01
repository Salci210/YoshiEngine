package dev_toolbox.file_explorer;

import sys.io.Process;
import haxe.io.Path;
import sys.FileSystem;
import flixel.FlxSprite;
import flixel.addons.ui.*;
import cpp.abi.Abi;

using StringTools;

enum FileExplorerType {
    Any;
    SparrowAtlas;
    Bitmap;
    XML;
    JSON;
    HScript;
    Lua;
    OGG;
}

@:enum
abstract FileExplorerIcon(Int) {
    var Unknown = 0;
    var Folder = 1;
    var JSON = 2;
    var Haxe = 3;
    var Audio = 4;
    var Text = 5;
    var XML = 6;
    var Bitmap = 7;
    var Sparrow = 8;
    var Executable = 9;
    var Lua = 10;
    var DLL = 11;
    var MP4 = 12;
}


class FileExplorer extends MusicBeatSubstate {
    var mod:String;
    var path:String = "";
    var type:FileExplorerType;

    var pathText:FlxUIText;
    var tab:FlxUI;
    var tabThingy:FlxUITabMenu;

    var spawnedElems:Array<FileExplorerElement> = [];

    var fileExt:String = "";
    var fileType:String = "";

    var callback:String->Void;

    public function navigateTo(path:String) {

        for (e in spawnedElems) {
            remove(e);
            e.destroy();
        }
        spawnedElems = [];
        this.path = path;
        var p = '${Paths.modsPath}/$mod/$path';
        #if trace_everything trace(p); #end


        // 256 + 20 = 276
        // TOTAL WIDTH = 276
        // MAX ITEMS PER COLUMN = 27
        
        var maxLength = 0;
        var dirs = [];
        var files = [];
        // TODO
        for (f in FileSystem.readDirectory(p)) {
            if (FileSystem.isDirectory('$p/$f')) {
                dirs.push(f);
            } else {
                files.push(f);
            }
            if (f.length > maxLength) maxLength = f.length;
        }
        maxLength *= 6;
        maxLength += 22;
        
        for (k=>f in dirs) {
            var nPath = '$path/$f';
            var el = new FileExplorerElement(f, Folder, () -> {navigateTo(nPath);}, maxLength);
            el.x = 10 + (maxLength * Math.floor(k / 27));
            el.y = 30 + (16 * (k % 27));
            tab.add(el);
            spawnedElems.push(el);
        }
        for (k=>f in files) {
            var t:FileExplorerIcon = Unknown;
            t = switch(Path.extension(f).toLowerCase()) {
                case "json":            JSON;
                case "hx" | "hscript":  Haxe;
                case "ogg" | "mp3":     Audio;
                case "log" | "txt":     Text;
                case "xml":             XML;
                case "png":             Bitmap;
                case "exe":             Executable;
                case "lua":             Lua;
                case "dll":             DLL;
                case "mp4":             MP4;
                default:                Unknown;
            }
            var el = new FileExplorerElement(f, t, () -> {
                if (fileExt != "") {
                    switch(type) {
                        case SparrowAtlas:
                            var ext = Path.extension(f).toLowerCase();
                            if (!fileExt.split(";").contains(ext)) {
                                showMessage("Error", 'You must select a $fileType');
                                return;
                            }
                            if (ext == "png") {
                                if (!FileSystem.exists('$p/${Path.withoutExtension(f)}.xml')) {
                                    showMessage("Error", 'The selected Sparrow Atlas doesn\'t have a corresponding XML file.');
                                    return;
                                }
                            } else {
                                if (!FileSystem.exists('$p/${Path.withoutExtension(f)}.png')) {
                                    showMessage("Error", 'The selected Sparrow Atlas doesn\'t have a corresponding PNG file.');
                                    return;
                                }
                            }
                            callback('$path/${Path.withoutExtension(f)}');
                            close();
                        
                        default:
                            if (!fileExt.split(";").contains(Path.extension(f).toLowerCase())) {
                                showMessage("Error", 'You must select a $fileType');
                                return;
                            }
                            callback('$path/$f');
                            close();
                    }
                }
            }, maxLength);
            el.x = 10 + (maxLength * Math.floor((dirs.length + k) / 27));
            el.y = 30 + (16 * ((dirs.length + k) % 27));
            tab.add(el);
            spawnedElems.push(el);
        }
        pathText.text = '$path/';

    }

    // function showMessage(title:String, text:String) {
    //     var m = ToolboxMessage.showMessage(title, text);
    //     m.cameras = cameras;
    //     openSubState(m);
    // }

    public override function new(mod:String, type:FileExplorerType, ?defaultFolder:String = "", callback:String->Void) {
        super();
        path = defaultFolder;
        this.mod = mod;
        this.callback = callback;

        add(new FlxSprite(0, 0).makeGraphic(1280, 720, 0x88000000));

        this.type = type;
        fileType = switch(type) {
            case Any:
                "file";
            case SparrowAtlas:
                "Sparrow atlas";
            case Bitmap:
                "Bitmap (PNG)";
            case XML:
                "XML file";
            case JSON:
                "JSON file";
            case HScript:
                ".hx or .hscript script";
            case Lua:
                ".lua script";
            case OGG:
                "OGG sound";
        }

        fileExt = switch(type) {
            case Any:
                "";
            case SparrowAtlas:
                "png;xml";
            case Bitmap:
                "png";
            case XML:
                "xml";
            case JSON:
                "json";
            case HScript:
                "hx;hscript";
            case Lua:
                "lua";
            case OGG:
                "ogg";
        }
        tabThingy = new FlxUITabMenu(null, [
            {
                label: 'Select a $fileType.',
                name: 'explorer'
            }
        ], true);
        tabThingy.resize(1280 * 0.75, 720 * 0.75);

        tab = new FlxUI(null, tabThingy);
        tab.name = "explorer";

        var upButton = new FlxUIButton(10, 10, "", function() {
            if (mod.replace("/", "").trim() == "") return;
            var split = path.split("/");
            navigateTo([for (k=>p in split) if (p.trim() != "" && k < split.length - 1) p].join("/"));
        });
        upButton.resize(20, 20);

        var refreshButton = new FlxUIButton(upButton.x + upButton.width + 10, 10, "", function() {
            navigateTo(path);
        });
        refreshButton.resize(20, 20);
        
        pathText = new FlxUIText(refreshButton.x + refreshButton.width + 10, 10, 0, '$path/');
        
        refreshButton.y = upButton.y -= (upButton.height - pathText.height) / 2;
        

        var upIcon = new FlxSprite().loadGraphic(Paths.image("uiIcons", "preload"), true, 16, 16);
        upIcon.animation.add("icon", [0], 0, false);
        upIcon.animation.play("icon");
        upIcon.x = upButton.x + (upButton.width / 2) - (upIcon.width / 2);
        upIcon.y = upButton.y + (upButton.height / 2) - (upIcon.height / 2);

        var refreshIcon = new FlxSprite().loadGraphic(Paths.image("uiIcons", "preload"), true, 16, 16);
        refreshIcon.animation.add("icon", [1], 0, false);
        refreshIcon.animation.play("icon");
        refreshIcon.x = refreshButton.x + (refreshButton.width / 2) - (upIcon.width / 2);
        refreshIcon.y = refreshButton.y + (refreshButton.height / 2) - (upIcon.height / 2);

        
        var buttons:Array<FlxUIButton> = [];
        buttons.push(new FlxUIButton(0, 0, "Cancel", function() {
            close();
        }));
        #if windows
            buttons.push(new FlxUIButton(0, 0, "Open Folder", function() {
                var p = ('explorer "${Paths.modsPath}/$mod/$path"').replace("/", "\\").replace("\\\\", "\\");
                trace(p);
                new Process(p);
            }));
        #end

        for(k=>b in buttons) {
            b.y = tabThingy.height - 50;
            b.x = (1280 * 0.325) + ((k - (buttons.length / 2) + 1) * 90);
            tab.add(b);
        }

        tab.add(upButton);
        tab.add(upIcon);
        tab.add(refreshButton);
        tab.add(refreshIcon);
        tab.add(pathText);

        navigateTo(defaultFolder);

        tabThingy.screenCenter();
        tabThingy.addGroup(tab);
        add(tabThingy);
        @:privateAccess
        cast(tabThingy._tabs[0], FlxUIButton).skipButtonUpdate = true;
    }
}