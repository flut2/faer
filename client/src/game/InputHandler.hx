package game;

import map.Camera;
import network.NetworkHandler;
import lime.system.System;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import ui.options.Options;
import util.Utils;
import util.Settings;
import openfl.utils.ByteArray;

class InputHandler {
	public var isWalking = false;

	private var moveLeft = 0;
	private var moveRight = 0;
	private var moveUp = 0;
	private var moveDown = 0;
	private var rotateLeft = 0;
	private var rotateRight = 0;
	private var shootDown = false;

	private static var abilityData = new ByteArray();

	public function new(gs: GameSprite) {
		gs.addEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage);
		gs.addEventListener(Event.REMOVED_FROM_STAGE, this.onRemovedFromStage);
	}

	public function clearInput() {
		this.moveLeft = this.moveRight = this.moveUp = this.moveDown = this.rotateLeft = this.rotateRight = 0;
		this.shootDown = false;

		this.setPlayerMovement();
	}

	private function setPlayerMovement() {
		Global.gameSprite?.map.player?.setRelativeMovement(this.rotateRight - this.rotateLeft, this.moveRight - this.moveLeft, this.moveDown - this.moveUp);
	}

	private function togglePerformanceStats() {
		if (Global.gameSprite.fpsView != null) {
			Global.gameSprite.fpsView.visible = false;
			Global.gameSprite.fpsView = null;
			Settings.perfStatsOpen = false;
			Settings.save();
		} else {
			Global.gameSprite.addFpsView();
			Global.gameSprite.lastFrameUpdate = System.getTimer();
			Settings.perfStatsOpen = true;
			Settings.save();
		}
	}

	private function onAddedToStage(event: Event) {
		Main.primaryStage.addEventListener(Event.DEACTIVATE, this.onDeactivate);
		Main.primaryStage.addEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDown);
		Main.primaryStage.addEventListener(KeyboardEvent.KEY_UP, this.onKeyUp);
		Main.primaryStage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		Main.primaryStage.addEventListener(MouseEvent.MOUSE_DOWN, this.onMouseDown);
		Main.primaryStage.addEventListener(MouseEvent.MOUSE_UP, this.onMouseUp);
		Main.primaryStage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, this.onRightMouseDown);
		Main.primaryStage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, this.onRightMouseUp);
		Main.primaryStage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, this.onMiddleMouseDown);
		Main.primaryStage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, this.onMiddleMouseUp);
		Main.primaryStage.addEventListener(Event.ENTER_FRAME, this.onEnterFrame);
	}

	private function onRemovedFromStage(event: Event) {
		Main.primaryStage.removeEventListener(Event.DEACTIVATE, this.onDeactivate);
		Main.primaryStage.removeEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDown);
		Main.primaryStage.removeEventListener(KeyboardEvent.KEY_UP, this.onKeyUp);
		Main.primaryStage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		Main.primaryStage.removeEventListener(MouseEvent.MOUSE_DOWN, this.onMouseDown);
		Main.primaryStage.removeEventListener(MouseEvent.MOUSE_UP, this.onMouseUp);
		Main.primaryStage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, this.onRightMouseDown);
		Main.primaryStage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, this.onRightMouseUp);
		Main.primaryStage.removeEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, this.onMiddleMouseDown);
		Main.primaryStage.removeEventListener(MouseEvent.MIDDLE_MOUSE_UP, this.onMiddleMouseUp);
		Main.primaryStage.removeEventListener(Event.ENTER_FRAME, this.onEnterFrame);
	}

	private function onDeactivate(event: Event) {
		this.clearInput();
	}

	private function onMouseDown(event: MouseEvent) {
		downAction(KeyCode.Mouse1, event.currentTarget == event.target
			|| event.target == Global.gameSprite.map
			|| event.target == Global.gameSprite);
	}

	private function onMouseUp(_: MouseEvent) {
		upAction(KeyCode.Mouse1);
	}

	private function onRightMouseDown(event: MouseEvent) {
		downAction(KeyCode.Mouse2, event.currentTarget == event.target
			|| event.target == Global.gameSprite.map
			|| event.target == Global.gameSprite);
	}

	private function onRightMouseUp(_: MouseEvent) {
		upAction(KeyCode.Mouse2);
	}

	private function onMiddleMouseDown(event: MouseEvent) {
		downAction(KeyCode.Mouse3, event.currentTarget == event.target
			|| event.target == Global.gameSprite.map
			|| event.target == Global.gameSprite);
	}

	private function onMiddleMouseUp(_: MouseEvent) {
		upAction(KeyCode.Mouse3);
	}

	private static function onMouseWheel(event: MouseEvent) {
		Global.gameSprite?.miniMap?.onMiniMapZoom(event.delta > 0 ? "in" : "out");
	}

	private function onEnterFrame(event: Event) {
		if (!this.shootDown)
			return;

		Global.gameSprite.map.player?.attemptAttackAngle(Math.atan2(Main.primaryStage.mouseY - Main.mouseYOffset + 20,
			Main.primaryStage.mouseX - Main.mouseXOffset));
	}

	private function onKeyDown(event: KeyboardEvent) {
		if (Main.primaryStage.focus != null)
			return;

		downAction(event.keyCode);
	}

	private function onKeyUp(event: KeyboardEvent) {
		if (Main.primaryStage.focus != null)
			return;

		upAction(event.keyCode);
	}

	private function downAction(keyCode: KeyCode, shootCheck: Bool = true) {
		var player = Global.gameSprite.map.player;

		if (keyCode == Settings.shoot) {
			if (shootCheck)
				player?.attemptAttackAngle(Math.atan2(Main.primaryStage.mouseY - Main.mouseYOffset + 20, Main.primaryStage.mouseX - Main.mouseXOffset));
			else
				return;

			this.shootDown = true;
		} 
		
		if (keyCode == Settings.walk)
			this.isWalking = true;
		
		if (keyCode == Settings.moveUp)
			this.moveUp = 1;
		
		if (keyCode == Settings.moveDown)
			this.moveDown = 1;
		
		if (keyCode == Settings.moveLeft)
			this.moveLeft = 1;
		
		if (keyCode == Settings.moveRight)
			this.moveRight = 1;
		
		if (keyCode == Settings.rotateLeft)
			this.rotateLeft = 1;
		
		if (keyCode == Settings.rotateRight)
			this.rotateRight = 1;
		
		if (keyCode == Settings.resetCamera)
			Camera.angleRad = 0;
		
		if (keyCode == Settings.perfStats)
			this.togglePerformanceStats();
		
		if (keyCode == Settings.goToHub)
			NetworkHandler.escape();
		
		if (keyCode == Settings.options) {
			this.clearInput();
			var options = new Options(Global.gameSprite);
			options.x = (Main.stageWidth - 800) / 2;
			options.y = (Main.stageHeight - 600) / 2;
			Global.layers.overlay.addChild(options);
		} 
		
		if (keyCode == Settings.openStats) {
			if (Global.gameSprite == null)
				return;

			Global.gameSprite.toggleStats();
		} 
		
		if (keyCode == Settings.interact && Global.currentInteractiveTarget > 0 && Global.currentInteractiveClass == "Portal")
			NetworkHandler.usePortal(Global.currentInteractiveTarget);

		this.setPlayerMovement();
	}

	private function upAction(keyCode: KeyCode) {
		if (keyCode == Settings.shoot)
			this.shootDown = false;
		
		if (keyCode == Settings.walk)
			this.isWalking = false;
		
		if (keyCode == Settings.moveUp)
			this.moveUp = 0;
		
		if (keyCode == Settings.moveDown)
			this.moveDown = 0;
		
		if (keyCode == Settings.moveLeft)
			this.moveLeft = 0;
		
		if (keyCode == Settings.moveRight)
			this.moveRight = 0;
		
		if (keyCode == Settings.rotateLeft)
			this.rotateLeft = 0;
		
		if (keyCode == Settings.rotateRight)
			this.rotateRight = 0;

		this.setPlayerMovement();
	}
}
