package;

import lime.system.Clipboard;
import flixel.tweens.FlxTween;
import ui.Hitbox;
import ui.Mobilecontrols;
import ui.FlxVirtualPad;
import flixel.addons.ui.FlxUISubState;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.util.FlxTimer;
import haxe.ds.Vector;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.math.FlxRandom;
import haxe.Json;
import flixel.addons.ui.FlxUISlider;
import flixel.addons.ui.FlxUI;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;
import flixel.input.FlxPointer;
import flixel.input.mouse.FlxMouse;
import flixel.util.typeLimit.OneOfTwo;
import flixel.input.touch.FlxTouch;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxUIButton;
import flixel.FlxSprite;
import flixel.FlxG;

using StringTools;

class ControlEditorState extends FlxState
{

	static var dPadList:Array<String> = ['buttonLeft', 'buttonUp', 'buttonRight', 'buttonDown'];
	static var actionsList:Array<String> = ['buttonA', 'buttonB'];

	var controlItems:Array<String> = ['hitbox', 'right control', 'left control', 'custom', 'keyboard'];
	var curSelected:Int;
	public var virtualpad:FlxVirtualPad;
	public var hitbox:Hitbox;
	var variantChoicer:CoolVariantChoicer;
	var deletebar:FlxSprite;


	override function create() 
	{
		#if !mobile
		FlxG.save.data.lastmousevisible = FlxG.mouse.visible;
		FlxG.mouse.visible = true;
		#end
		curSelected = FlxG.save.data.controlmode == null ? ControlsGroup.HITBOX : FlxG.save.data.controlmode;

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic('assets/images/menuBG.png');
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = FlxG.save.data.antialiasing;
		add(bg);

		hitbox = new Hitbox();
		hitbox.visible = false;
		add(hitbox);

		virtualpad = new FlxVirtualPad(FULL, A_B);
		virtualpad.visible = false;
		add(virtualpad);

		variantChoicer = new CoolVariantChoicer(100, 35, findbigger());
		variantChoicer.text = controlItems[curSelected];
		variantChoicer.onClick = changeSelection;
		add(variantChoicer);

		var exitbutton = new FlxUIButton(FlxG.width - 650,25,"exit", exit);
		exitbutton.resize(125, 50);
		exitbutton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		add(exitbutton);

		var exitSavebutton = new FlxUIButton((exitbutton.x + exitbutton.width + 25),25,"exit and save",() -> 
		{
			save();
			exit();
		});
		exitSavebutton.resize(250,50);
		exitSavebutton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		add(exitSavebutton);

		var optionsbutton = new FlxUIButton(exitSavebutton.x + exitSavebutton.width + 50, 25, "options", () -> {
			openSubState(new EditorOptions(this));
		});
		optionsbutton.resize(125,50);
		optionsbutton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		add(optionsbutton);

		deletebar = new FlxSprite().loadGraphic(Paths.image('delbar'));
		deletebar.y = FlxG.height - 77;
		deletebar.alpha = 0;
		add(deletebar);

		createOptionsUi();
		changeSelection();

		// FlxG.save.data.padPositions = null;
		// saveCustomPosition();
		// loadCustomPosition(virtualpad);

		super.create();
	}
	function save() {
		FlxG.save.data.controlmode = curSelected;
		switch (curSelected)
		{
			case 3:
				saveCustomPosition();

			default:
		}
	}

	public function createButton(type:String, x:Float, y:Float) {
		var multiply = 3;

		switch (type)
		{
			case "up":
				virtualpad.dPad.add(virtualpad.add(virtualpad.createButton(x, y, 44 * multiply, 45 * multiply, "up")));
			case "left":
				virtualpad.dPad.add(virtualpad.add(virtualpad.createButton(x, y, 44 * multiply, 45 * multiply, "left")));
			case "right":
				virtualpad.dPad.add(virtualpad.add(virtualpad.createButton(x, y, 44 * multiply, 45 * multiply, "right")));
			case "down":
				virtualpad.dPad.add(virtualpad.add(virtualpad.createButton(x, y, 44 * multiply, 45 * multiply, "down")));

		}
	}


	function createOptionsUi() {
		// var buttonOptBar = new FlxUI();
		// buttonOptBar.x = 100;
		// buttonOptBar.y = 100;
		// add(buttonOptBar);
		// var zoomSlider = new FlxUISlider(virtualpad, 'scale', 0, 0, 1, 2);
		// zoomSlider.decimals = 0;
		// zoomSlider.callback = (f) -> {
		// 	virtualpad.updateHitbox();
		// }
		// buttonOptBar.add(zoomSlider);

		// add(new FlxButton(50, 200, "+", () -> {
		// 	// virtualpad.setGraphicSize(Std.int(virtualpad.width * 2));
		// 	virtualpad.updateHitbox();
		// }));
	}

	override function update(elapsed:Float) 
	{
		#if android
		if (FlxG.android.justReleased.BACK)
		{
			FlxG.switchState(new OptionsMenu());
		}
		#end

		if (FlxG.keys.justReleased.RIGHT)
		{
			changeSelection(1);
		}

		if (FlxG.keys.justReleased.LEFT)
		{
			changeSelection(-1);
		}

		if (curSelected == 3)
		{
			// virtualpad.forEachAlive(cast trackButton);
			virtualpad.forEach(cast trackButton);
		}

		// sry
		if (FlxG.mouse.justPressed && curSelected == 3){
			fpos[0] = FlxG.mouse.x;
			fpos[1] = FlxG.mouse.y;

			new FlxTimer().start(0.25, _ -> {
				if (FlxG.mouse.pressed && 
				Math.abs(FlxG.mouse.x - fpos[0]) < 50 && 
				Math.abs(FlxG.mouse.x - fpos[0]) < 50)
				{
					if (FlxG.mouse.overlaps(virtualpad)){
						virtualpad.forEachAlive(b -> {
							if (FlxG.mouse.overlaps(b))
								showButtonOption(cast b);
						});
					}
				}
			});
		}

		super.update(elapsed);
	}

	function showButtonOption(button:FlxButton) {
		var optState = new ButtonOptionSubState();
		optState.button = button;
		this.openSubState(optState);
	}

	var fpos:Vector<Int> = new Vector(2);
	function saveCustomPosition() 
	{
		FlxG.save.data.padPositions = generateSave();
		FlxG.save.flush();
	}
	
	public function generateSave() {
		var saveData:Array<SaveData> = [];

		for (button in virtualpad.members)
		{
			saveData.push({
				name: findButtonName(button),
				control: 'note_' + button.frame.name,
				position: { 
					x: button.x, y: 
					button.y, 
					width: button.frames.getByIndex(0).frame.width, 
					height: button.frames.getByIndex(0).frame.height 
				},
				alpha: button.alpha,
				scale: button.scale.x
			});
		}

		return saveData;
	}

	// for test
	public static function loadCustomPosition(virtualpad:FlxVirtualPad, ?data:Array<SaveData>) 
	{
		if (FlxG.save.data.padPositions == null)
			return virtualpad;

		var data:Array<SaveData> = data == null ? FlxG.save.data.padPositions : data;
		trace(data);

		for (button in virtualpad.members)
			destroyAndRemove(virtualpad, button);

		for (button in data)
		{
			var graphicName = button.name.replace('button', '').toLowerCase();

			var btn = virtualpad.createButton(button.position.x, button.position.y, button.position.width, button.position.height, graphicName);

			if (button.scale != 1)
			{
				btn.scale.x = btn.scale.y = button.scale;
				btn.updateHitbox();
			}

			btn.alpha = button.alpha;

			if (Reflect.hasField(virtualpad, button.name) && Reflect.field(virtualpad, button.name) == null)
				Reflect.setField(virtualpad, button.name, btn);

			if (dPadList.contains(button.name))
				virtualpad.dPad.add(btn);
			else
				virtualpad.actions.add(btn);

			virtualpad.add(btn);
		}

		return virtualpad;
	}

	static function destroyAndRemove(virtualpad:FlxVirtualPad, button:FlxSprite) {
		virtualpad.remove(button);
		virtualpad.dPad.remove(button);
		virtualpad.actions.remove(button);
		button.destroy();
	}

	function findButtonName(button:FlxSprite) {
		var fs = Reflect.fields(virtualpad);

		for (field in fs)
		{
			var fbutton = Reflect.field(virtualpad, field);
			if (fbutton == button && Std.isOfType(fbutton, FlxButton)) //  && field.indexOf("button") != -1
				return field;
		}
		
		trace(button.frame);
		trace(button.animation.name);
		if (button.frame.name != null)
			return 'button' + button.frame.name.charAt(0).toUpperCase() + button.frame.name.substr(1, button.frame.name.length);

		return 'unknown' + FlxG.random.int(0, 100);
	}
	
	function delbarCheck(button:FlxButton) {
		if (button.y > FlxG.height - button.width / 2)
		{
			button.color = FlxColor.RED;
			deletebar.alpha = FlxMath.lerp(deletebar.alpha, 1, 0.9 * FlxG.elapsed * 3);
		}
		else
		{
			button.color = 0xffffff;
			deletebar.alpha = FlxMath.lerp(deletebar.alpha, 0, 0.9 * FlxG.elapsed * 3);

		}
	}

	function trackButton(button:FlxButton) 
	{
		delbarCheck(button);

		#if !desktop
		for (touch in FlxG.touches.list)
		{
			if (touch.justReleased)
			{
				// if (button.overlaps(deletebar))
				// 	destroyAndRemove(virtualpad, bindButtonsMap.get(touch.touchPointID).button);

				if (bindButtonsMap.exists(touch.touchPointID)){
					var btn = bindButtonsMap.get(touch.touchPointID).button;
					if (btn.y > FlxG.height - btn.width / 2)
						destroyAndRemove(virtualpad, btn);
				}

				bindButtonsMap.remove(touch.touchPointID);
			}

			if (button.exists && touch.overlaps(button) && touch.justPressed)
				bindButtonsMap.set(touch.touchPointID, {
					button: button, 
					offset: FlxPoint.get(touch.justPressedPosition.x - button.x, touch.justPressedPosition.y - button.y)
				});

			if (bindButtonsMap.exists(touch.touchPointID))
				moveButton(touch, bindButtonsMap.get(touch.touchPointID));
		}
		#else
		if (FlxG.mouse.pressed && button.pressed) // for debug
		{
			var p = FlxPoint.get(button.width / 2, button.height / 2);
			moveButton(FlxG.mouse, {button: button, offset: p});
			p = FlxDestroyUtil.put(p);
		}else{
			var btn = button;
				if (btn.y > FlxG.height - btn.width / 2)
					destroyAndRemove(virtualpad, btn);
		}
		#end
	}

	inline function moveButton(touch:FlxPointer, data:{ button:FlxButton, offset:FlxPoint }) 
	{
		data.button.x = touch.x - data.offset.x;
		data.button.y = touch.y - data.offset.y;
	}
	

	var bindButtonsMap:Map<Int, { button:FlxButton, offset:FlxPoint }> = new Map();

	function changeSelection(change:Int = 0, ?forceChange:Int)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = controlItems.length - 1;
		if (curSelected >= controlItems.length)
			curSelected = 0;
		trace('current control mode is: $curSelected');
	
		if (forceChange != null)
			curSelected = forceChange;
	
		variantChoicer.text = controlItems[curSelected];

		// what is that
		// if (forceChange != null)
		// {
		// 	if (curSelected == 2)
		// 	{
		// 		_pad.visible = true;
		// 	}
		// 	return;
		// }

		changeControl(curSelected);
	}

	inline function changeControl(mode:ui.Mobilecontrols.ControlsGroup) 
	{		
		switch (mode)
		{
			case HITBOX:
				hitbox.visible = true;
				virtualpad.visible = false;
			
			case VIRTUALPAD_RIGHT:
				hitbox.visible = false;
				virtualpad.destroy();
				add(virtualpad = new FlxVirtualPad(RIGHT_FULL, NONE));
				// virtualpad.visible = true;

			case VIRTUALPAD_LEFT:
				hitbox.visible = false;
				virtualpad.destroy();
				add(virtualpad = new FlxVirtualPad(FULL, NONE));
				// virtualpad.visible = true;

			case VIRTUALPAD_CUSTOM:
				hitbox.visible = false;
				virtualpad.destroy();
				add(virtualpad = new FlxVirtualPad(FULL, NONE));
				loadCustomPosition(virtualpad);
				// saveCustomPosition();
				// virtualpad.visible = true;
				// loadshit()

			case KEYBOARD:
				hitbox.visible = false;
				virtualpad.visible = false;
		}
	}

	inline function findbigger() 
	{
		var mostbig = "";
		for (s in controlItems)
			if (s.length > mostbig.length)
				mostbig = s;
		return mostbig;
	}

	function exit() 
	{
		FlxG.mouse.visible = FlxG.save.data.lastmousevisible;
		FlxG.save.data.lastmousevisible = null;
		FlxG.switchState(new ui.OptionsState());
	}
}

class CoolVariantChoicer extends FlxSpriteGroup
{
	var leftArrow:FlxButton;
	var txt:FlxText;
	var rightArrow:FlxButton;

	public var text(default, set):String;

	public function new(?x, ?y, text) {
		super(x, y);
		// var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var ui_tex = FlxAtlasFrames.fromSparrow('assets/images/campaign_menu_UI_assets.png',
			'assets/images/campaign_menu_UI_assets.xml');

		txt = new FlxText(0, 0, 0, text, 48);
		txt.setBorderStyle(OUTLINE_FAST, FlxColor.BLACK, 1);

		leftArrow = new FlxButton(txt.x - 60, txt.y - 10, "", () -> onClick(-1));
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix("normal", "arrow left");
		leftArrow.animation.addByPrefix("highlight", "arrow left");
		leftArrow.animation.addByPrefix("pressed", "arrow push left");

		rightArrow = new FlxButton(txt.x + txt.width + 10, leftArrow.y, "", () -> onClick(1));
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix("normal", 'arrow right');
		rightArrow.animation.addByPrefix("highlight", 'arrow right');
		rightArrow.animation.addByPrefix("pressed", "arrow push right", 24, false);

		add(txt);
		add(leftArrow);
		add(rightArrow);
	}

	// why not
	public dynamic function onClick(num:Int, ?_) {
		
	} 

	function set_text(value:String):String {
		txt.text = value; // so sorry
		txt.x = ((rightArrow.x - (leftArrow.x + leftArrow.width)) / 2) - (txt.width / 2) - leftArrow.x + leftArrow.width + (x - 100);
		return value;
	}
}



class ButtonOptionSubState extends FlxUISubState
{
	var buttonName:FlxText;
	var scaleSlider:FlxUISlider;
	var scale(default, set):Float;
	var alphaButton(default, set):Float;
	var bg:FlxSprite;
	var alphaSlider:FlxUISlider;
	public var button(default, set):FlxButton;
	
	public function new() 
	{
		super();
		bg = new FlxSprite().makeGraphic(350, 225, FlxColor.BLACK);
		bg.alpha = 0.75;
		add(bg);
		buttonName = new FlxText(5, 0, 0, 'button name');
		buttonName.size = 16;
		add(buttonName);
		scaleSlider = new FlxUISlider(this, 'scale', 5, 10, 0.5, 3, 300, 45, 9, FlxColor.WHITE);
		add(scaleSlider);
		alphaSlider = new FlxUISlider(this, 'alphaButton', 5, 20, 0.1, 1, 300, 45, 9, FlxColor.WHITE);
		add(alphaSlider);
	}

	override function update(elapsed:Float) {
		if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(bg))
			close();
		super.update(elapsed);
	}

	function setSliderScale(slider:FlxUISlider, scale:Float = 1.5) 
	{
		for (obj in [slider.body, slider.handle, slider.minLabel, slider.maxLabel, slider.nameLabel, slider.valueLabel])
		{
			obj.scale.x = obj.scale.y = scale;
			obj.updateHitbox();
		}	
		slider.handle.setPosition(slider.handle.x * scale, slider.handle.y);
	}

	function set_button(value:FlxButton):FlxButton 
	{
		var rightCornerDist = FlxG.width - (value.x + value.width);
		var bottomCornerDist = FlxG.height - (value.y + value.height);
		var xReflect = false;
		var yReflect = false;

		if (rightCornerDist < 350)
			xReflect = true;

		if (bottomCornerDist < 250)
			yReflect = true;

		var offset = FlxPoint.get(xReflect ? -350 : value.width, yReflect ? -250 : value.height);

		buttonName.text = "Button: " + value.frames.frames[0].name;
		button = value;
		alphaButton = value.alpha;
		scale = value.scale.x;
		bg.setPosition(value.x + offset.x, value.y + offset.y);
		buttonName.setPosition(value.x + ( (350 - buttonName.width) / 2 ) + offset.x, value.y + offset.y + 5);
		scaleSlider.setPosition(value.x + 15 + offset.x, value.y + 40 + offset.y);
		alphaSlider.setPosition(value.x + 15 + offset.x, value.y + 130 + offset.y);

		offset.put();

		return value;
	}

	function set_scale(value:Float):Float {
		scale = button.scale.x = button.scale.y = value;
		button.updateHitbox();
		return value;
	}

	function set_alphaButton(value:Float):Float {
		return alphaButton = button.alpha = value;
	}
}

class EditorOptions extends FlxUISubState {
	public function new(state:ControlEditorState) 
	{
		super();

		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		add(bg);
		FlxTween.num(0, 0.5, 0.125, {}, (v) -> {
			bg.alpha = v;
		});

		var createButtonText = new FlxText(0, 125, 0, "create button", 64);
		createButtonText.screenCenter(X);
		add(createButtonText);

		var createUpButton = new FlxUIButton(50, 300, "Create up Button", () -> 
		{
			state.createButton("up", 50, 300);
			close();
		});
		createUpButton.resize(250,85);
		createUpButton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		add(createUpButton);

		var createDownButton = new FlxUIButton(350, 300, "Create down Button", () -> 
		{
			state.createButton("down", 350, 300);
			close();
		});
		createDownButton.resize(250,85);
		createDownButton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		add(createDownButton);

		var createLeftButton = new FlxUIButton(650, 300, "Create left Button", () -> 
		{
			state.createButton("left", 650, 300);
			close();
		});
		createLeftButton.resize(250,85);
		createLeftButton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		add(createLeftButton);

		var createRightButton = new FlxUIButton(950, 300, "Create right Button", () -> 
		{
			state.createButton("right", 950, 300);
			close();
		});
		createRightButton.resize(250,85);
		createRightButton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		add(createRightButton);

		var exitButton = new FlxUIButton(1050, 50, "exit", () -> 
		{
			close();
		});
		exitButton.resize(150,85);
		exitButton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		add(exitButton);

		var exportSave = new FlxText(0, 425, 0, "export save", 48);
		exportSave.screenCenter(X);
		add(exportSave);

		var saveButton = new FlxUIButton(150, 550, "save buttons in clipboard", () -> 
		{
			Clipboard.text = Json.stringify(state.generateSave());

			// var saved = new FlxText()
			// close();
		});
		saveButton.resize(450,50);
		saveButton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		add(saveButton);

		var loadSaveButton = new FlxUIButton(700, 550, "load save from clipboard", () -> 
		{
			try{
				var data:Array<SaveData> = Json.parse(Clipboard.text);

				if (!(data is Array))
					throw 'invalid save data';

				for (b in data){

					var bFields = Reflect.fields(b);

					if (bFields.contains('name') &&
						bFields.contains('control') &&
						bFields.contains('position') &&
						bFields.contains('alpha') &&
						bFields.contains('scale'))
					{
						continue;
					}
					else{
						throw 'invalid save data';
					}
				}

				state.virtualpad = ControlEditorState.loadCustomPosition(state.virtualpad, data);
			}catch(e){
				trace(e);
			}

			// var saved = new FlxText()
			// close();
		});
		loadSaveButton.resize(450,50);
		loadSaveButton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		add(loadSaveButton);

		// var resetButton = new FlxUIButton(150, 550, "reset", () -> 
		// {

		// });
		// resetButton.resize(450,50);
		// resetButton.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		// add(resetButton);
	}
}

// class ButtonOptions extends FlxTypedGroup<FlxObject> {
// 	var buttonName:FlxText;
// 	var scaleSlider:FlxUISlider;
// 	var scale:Float;
	
// 	public function new() 
// 	{
// 		super();
// 		var bg = new FlxSprite().makeGraphic(100, 50, FlxColor.GRAY);
// 		add(bg);
// 		buttonName = new FlxText(5, 0, 0, 'button name');
// 		add(buttonName);
// 		scaleSlider = new FlxUISlider(this, 'scale', 5, 10, 0.5, 3);
// 		add(scaleSlider);
// 	}
// }

typedef SaveData = {
	var name:String; // graphicName
	var control:String; // like Control.UP
	var position:{ x:Dynamic, y:Dynamic, width:Dynamic, height:Dynamic }; // w and h graphic
	var alpha:Float;
	var scale:Float;
}