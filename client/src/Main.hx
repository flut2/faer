package;

import appengine.RequestHandler;
import core.Layers;
import engine.GLTextureData;
import map.Camera;
import network.NetworkHandler;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.display.Stage3D;
import openfl.display.Stage;
import openfl.display.StageQuality;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.ui.Mouse;
import openfl.utils.Assets;
import screens.AccountLoadingScreen;
import util.AssetLibrary;
import util.AssetLoader;
import util.BinPacker;
import util.ConditionEffect;
import util.NativeTypes.Float32;
import util.Settings;
import util.Utils;
#if !disable_rpc
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
#end

class Main extends Sprite {
	public static inline final PADDING = 2;
	public static inline final ATLAS_WIDTH = 4096;
	public static inline final ATLAS_HEIGHT = 4096;
	public static inline final BASE_TEXEL_W: Float32 = 1 / ATLAS_WIDTH;
	public static inline final BASE_TEXEL_H: Float32 = 1 / ATLAS_HEIGHT;

	public static var mouseXOffset: Int = 0;
	public static var mouseYOffset: Int = 0;
	public static var stageWidth = 1024;
	public static var stageHeight = 768;
	public static var primaryStage: Stage;
	public static var primaryStage3D: Stage3D;
	public static var tempAtlas: BitmapData;
	public static var atlasPacker: BinPacker;
	public static var atlas: GLTextureData;
	#if !disable_rpc
	public static var startTime: Int;
	public static var rpcReady: Bool;
	#end

	private static var baseCursorSprite: Bitmap;
	private static var clickCursorSprite: Bitmap;
	private static var mouseDown = false;

	public function new() {
		super();

		tempAtlas = new BitmapData(ATLAS_WIDTH, ATLAS_HEIGHT, true, 0);
		atlasPacker = new BinPacker(ATLAS_WIDTH, ATLAS_HEIGHT);
		primaryStage3D = stage.stage3Ds[0];
		primaryStage = stage;

		Global.backgroundImage = new Bitmap(Assets.getBitmapData("assets/ui/background.png"));
		Global.layers = new Layers();
		addChild(Global.layers);
		Global.layers.screens.setScreen(new AccountLoadingScreen());

		AssetLoader.load();
		Settings.load();

		#if !disable_rpc
		startTime = Std.int(Date.now().getTime() / 1000);
		final handlers = new DiscordEventHandlers();
		handlers.ready = cpp.Function.fromStaticFunction(onReady);
		handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		handlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize("1095646272171552811", cpp.RawPointer.addressOf(handlers), false, null);
		#end

		refreshCursor();

		ConditionEffect.initRects();
		Camera.init();
		NetworkHandler.init();
		RequestHandler.init();
		MathUtil.init();

		Global.init();

		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.quality = StageQuality.LOW;

		stage.addEventListener(Event.RESIZE, this.onResize);
		stage.addEventListener(Event.ENTER_FRAME, this.onEnterFrame);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUp);
		stage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMouseUp);
	}

	#if !disable_rpc
	private static function onReady(request: cpp.RawConstPointer<DiscordUser>) {
		rpcReady = true;
	}

	private static function onDisconnected(errorCode: Int, message: cpp.ConstCharStar) {
		trace('Discord RPC Disconnected (code $errorCode): ${cast (message, String)}');
	}

	private static function onError(errorCode: Int, message: cpp.ConstCharStar) {
		trace('Discord RPC Error (code $errorCode): ${cast (message, String)}');
	}
	#end

	public static function refreshCursor() {
		if (Settings.selectedCursor == -1) {
			Mouse.show();
			return;
		}

		Mouse.hide();
		if (primaryStage.contains(baseCursorSprite))
			primaryStage.removeChild(baseCursorSprite);
		baseCursorSprite = new Bitmap(AssetLibrary.getImageFromSet("cursors", Settings.selectedCursor * 2 + 1));
		primaryStage.addChild(baseCursorSprite);
		if (primaryStage.contains(clickCursorSprite))
			primaryStage.removeChild(clickCursorSprite);
		clickCursorSprite = new Bitmap(AssetLibrary.getImageFromSet("cursors", Settings.selectedCursor * 2));
		primaryStage.addChild(clickCursorSprite);
	}

	private final function onResize(_: Event) {
		stageHeight = stage.stageHeight;
		stageWidth = stage.stageWidth;
		mouseXOffset = stageWidth >> 1;
		mouseYOffset = stageHeight >> 1;

		Global.backgroundImage.width = stageWidth;
		Global.backgroundImage.height = stageHeight;
	}

	private final function onEnterFrame(_: Event) {
		#if !disable_rpc
		Discord.RunCallbacks();
		#end

		if (baseCursorSprite == null)
			return;

		clickCursorSprite.visible = mouseDown;
		baseCursorSprite.visible = !mouseDown;

		clickCursorSprite.x = baseCursorSprite.x = stage.mouseX - 32 / 2;
		clickCursorSprite.y = baseCursorSprite.y = stage.mouseY - 32 / 2;
	}

	private static function onMouseDown(_: MouseEvent) {
		mouseDown = true;
	}

	private static function onMouseUp(_: MouseEvent) {
		mouseDown = false;
	}
}
