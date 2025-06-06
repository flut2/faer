package map;

import engine.GLTextureData;
import engine.TextureFactory;
import haxe.Exception;
import haxe.ds.IntMap;
import haxe.ds.Vector;
import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLFramebuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLTexture;
import lime.graphics.opengl.GLUniformLocation;
import lime.graphics.opengl.GLVertexArrayObject;
import lime.utils.Float32Array;
import lime.utils.Int16Array;
import lime.utils.Int32Array;
import objects.GameObject;
import objects.Player;
import objects.Projectile;
import objects.animation.Animations;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.filters.GlowFilter;
import openfl.geom.Matrix;
import openfl.geom.Point;
import ui.SimpleText;
import util.AnimatedChar;
import util.AssetLibrary;
import util.BinPacker.Rect;
import util.ConditionEffect;
import util.NativeTypes;
import util.Settings;
import util.Utils.KeyCodeUtil;
import util.Utils.MathUtil;
import util.Utils.RenderUtils;

using util.Utils.ArrayUtils;

@:structInit
class RenderDataSingle {
	public var texture: GLTexture;
	public var cosX: Float32;
	public var sinX: Float32;
	public var sinY: Float32;
	public var cosY: Float32;
	public var x: Float32;
	public var y: Float32;
	public var texelW: Float32;
	public var texelH: Float32;
	public var alpha: Float32 = 1.0;
}

@:unreflective
class Map {
	private static inline var TILE_UPDATE_MS = 100; // tick rate
	private static inline var BUFFER_UPDATE_MS = 500;
	private static inline var MAX_VISIBLE_SQUARES = 729;
	private static inline var DAY_CYCLE_MS = 10 * 60 * 1000; // 10 minutes

	public static var emptyBarU: Float32 = 0.0;
	public static var emptyBarV: Float32 = 0.0;
	public static var emptyBarW: Float32 = 0.0;
	public static var emptyBarH: Float32 = 0.0;
	public static var hpBarU: Float32 = 0.0;
	public static var hpBarV: Float32 = 0.0;
	public static var hpBarW: Float32 = 0.0;
	public static var hpBarH: Float32 = 0.0;
	public static var mpBarU: Float32 = 0.0;
	public static var mpBarV: Float32 = 0.0;
	public static var mpBarW: Float32 = 0.0;
	public static var mpBarH: Float32 = 0.0;
	public static var oxygenBarU: Float32 = 0.0;
	public static var oxygenBarV: Float32 = 0.0;
	public static var oxygenBarW: Float32 = 0.0;
	public static var oxygenBarH: Float32 = 0.0;
	public static var shieldBarU: Float32 = 0.0;
	public static var shieldBarV: Float32 = 0.0;
	public static var shieldBarW: Float32 = 0.0;
	public static var shieldBarH: Float32 = 0.0;
	public static var leftMaskU: Float32 = 0.0;
	public static var leftMaskV: Float32 = 0.0;
	public static var topMaskU: Float32 = 0.0;
	public static var topMaskV: Float32 = 0.0;
	public static var rightMaskU: Float32 = 0.0;
	public static var rightMaskV: Float32 = 0.0;
	public static var bottomMaskU: Float32 = 0.0;
	public static var bottomMaskV: Float32 = 0.0;

	public static var wallBackfaceU: Float32 = 0.0;
	public static var wallBackfaceV: Float32 = 0.0;

	public static var vertScaleUniformLoc: GLUniformLocation;
	public static var vertPosUniformLoc: GLUniformLocation;
	public static var texelSizeUniformLoc: GLUniformLocation;
	public static var colorUniformLoc: GLUniformLocation;
	public static var alphaMultUniformLoc: GLUniformLocation;
	public static var leftMaskUniformLoc: GLUniformLocation;
	public static var topMaskUniformLoc: GLUniformLocation;
	public static var rightMaskUniformLoc: GLUniformLocation;
	public static var bottomMaskUniformLoc: GLUniformLocation;

	public var mapWidth: UInt16 = 0;
	public var mapHeight: UInt16 = 0;
	public var mapName = "";
	public var back = 0;
	public var allowPlayerTeleport = false;
	public var squares: Vector<Square>;
	public var gameObjectsLen: Int32 = 0;
	public var gameObjects: Array<GameObject>;

	private var goRemove: Array<GameObject>;

	public var vertDataList: Float32Array;
	public var indexDataList: Int32Array;
	public var lightDataList: Float32Array;
	public var rdSingle: Array<RenderDataSingle>;
	public var player: Player = null;
	public var quest: Quest = null;
	public var lastWidth: Int16 = -1;
	public var lastHeight: Int16 = -1;
	public var c3d: Context3D;
	public var lastTileUpdate: Int32 = -1;

	public var count: Int = 0;
	public var vertIdx: Int = 0;
	public var indexIdx: Int = 0;
	public var lightIdx: Int = 0;

	private var lastBufferUpdate: Int32 = -1;
	private var visSquares: Vector<Square>;
	private var visSquareLen: UInt16 = 0;

	public var defaultProgram: GLProgram;
	public var lowGlowProgram: GLProgram;
	public var medGlowProgram: GLProgram;
	public var highGlowProgram: GLProgram;
	public var veryHighGlowProgram: GLProgram;
	public var singleProgram: GLProgram;
	public var groundProgram: GLProgram;
	public var lightProgram: GLProgram;

	public var singleVBO: GLBuffer;
	public var singleIBO: GLBuffer;
	public var groundVAO: GLVertexArrayObject;
	public var groundVBO: GLBuffer;
	public var groundVBOLen: Int32 = 0;
	public var groundIBO: GLBuffer;
	public var groundIBOLen: Int32 = 0;
	public var objVAO: GLVertexArrayObject;
	public var objVBO: GLBuffer;
	public var objVBOLen: Int32 = 0;
	public var objIBO: GLBuffer;
	public var objIBOLen: Int32 = 0;
	public var lightVAO: GLVertexArrayObject;
	public var lightVBO: GLBuffer;
	public var lightVBOLen: Int32 = 0;
	public var lightIBO: GLBuffer;
	public var lightIBOLen: Int32 = 0;

	private var backBuffer: GLFramebuffer;
	private var frontBuffer: GLFramebuffer;
	private var backBufferTexture: GLTexture;
	private var frontBufferTexture: GLTexture;
	private var screenData: GLTextureData;
	private var screenTex: GLTexture;
	private var lightData: GLTextureData;
	private var lightTex: GLTexture;
	private var bgLightColor: Int32 = -1;
	private var bgLightIntensity: Float32 = 0.1;
	private var dayLightIntensity: Float32 = -1.0;
	private var nightLightIntensity: Float32 = -1.0;
	private var serverTimeOffset: Int32 = 0;

	public var speechBalloons: IntMap<SpeechBalloon>;
	public var statusTexts: Array<CharacterStatusText>;

	private var normalBalloonTex: BitmapData;
	private var tellBalloonTex: BitmapData;
	private var guildBalloonTex: BitmapData;
	private var enemyBalloonTex: BitmapData;
	private var partyBalloonTex: BitmapData;
	private var adminBalloonTex: BitmapData;

	public function new() {
		this.gameObjects = [];
		this.goRemove = [];
		this.vertDataList = new Float32Array(56000);
		this.indexDataList = new Int32Array(8400);
		this.lightDataList = new Float32Array(60000);
		this.rdSingle = [];
		this.quest = new Quest(this);
		this.visSquares = new Vector<Square>(MAX_VISIBLE_SQUARES);
		this.speechBalloons = new IntMap<SpeechBalloon>();
		this.statusTexts = [];
	}

	public function addSpeechBalloon(sb: SpeechBalloon) {
		this.speechBalloons.set(sb.go.objectId, sb);
	}

	public function addStatusText(text: CharacterStatusText) {
		this.statusTexts.push(text);
	}

	public function setProps(width: Int32, height: Int32, name: String, allowPlayerTeleport: Bool, bgLightColor: Int32, bgLightIntensity: Float32,
			dayLightIntensity: Float32, nightLightIntensity: Float32, serverTimeOffset: Int32) {
		this.mapWidth = width;
		this.mapHeight = height;
		this.squares = new Vector<Square>(this.mapWidth * this.mapHeight);
		this.mapName = name;
		this.allowPlayerTeleport = allowPlayerTeleport;
		this.bgLightColor = bgLightColor;
		this.bgLightIntensity = bgLightIntensity;
		this.dayLightIntensity = dayLightIntensity;
		this.nightLightIntensity = nightLightIntensity;
		this.serverTimeOffset = serverTimeOffset;
	}

	public function initialize() {
		this.normalBalloonTex = AssetLibrary.getImageFromSet("speechBalloons", 0x0);
		this.tellBalloonTex = AssetLibrary.getImageFromSet("speechBalloons", 0x1);
		this.guildBalloonTex = AssetLibrary.getImageFromSet("speechBalloons", 0x2);
		this.enemyBalloonTex = AssetLibrary.getImageFromSet("speechBalloons", 0x3);
		this.partyBalloonTex = AssetLibrary.getImageFromSet("speechBalloons", 0x4);
		this.adminBalloonTex = AssetLibrary.getImageFromSet("speechBalloons", 0x5);

		var wallBackfaceRect = AssetLibrary.getRectFromSet("wallBackface", 0);
		wallBackfaceU = (wallBackfaceRect.x + Main.PADDING) / Main.ATLAS_WIDTH;
		wallBackfaceV = (wallBackfaceRect.y + Main.PADDING) / Main.ATLAS_HEIGHT;

		var leftMaskRect = AssetLibrary.getRectFromSet("ground", 0x6b);
		leftMaskU = (leftMaskRect.x + Main.PADDING) / Main.ATLAS_WIDTH;
		leftMaskV = (leftMaskRect.y + Main.PADDING) / Main.ATLAS_HEIGHT;

		var topMaskRect = AssetLibrary.getRectFromSet("ground", 0x6c);
		topMaskU = (topMaskRect.x + Main.PADDING) / Main.ATLAS_WIDTH;
		topMaskV = (topMaskRect.y + Main.PADDING) / Main.ATLAS_HEIGHT;

		var rightMaskRect = AssetLibrary.getRectFromSet("ground", 0x6d);
		rightMaskU = (rightMaskRect.x + Main.PADDING) / Main.ATLAS_WIDTH;
		rightMaskV = (rightMaskRect.y + Main.PADDING) / Main.ATLAS_HEIGHT;

		var bottomMaskRect = AssetLibrary.getRectFromSet("ground", 0x6e);
		bottomMaskU = (bottomMaskRect.x + Main.PADDING) / Main.ATLAS_WIDTH;
		bottomMaskV = (bottomMaskRect.y + Main.PADDING) / Main.ATLAS_HEIGHT;

		var hpBarRect = AssetLibrary.getRectFromSet("bars", 0x0);
		hpBarU = hpBarRect.x / Main.ATLAS_WIDTH;
		hpBarV = hpBarRect.y / Main.ATLAS_HEIGHT;
		hpBarW = hpBarRect.width;
		hpBarH = hpBarRect.height;

		var mpBarRect = AssetLibrary.getRectFromSet("bars", 0x1);
		mpBarU = mpBarRect.x / Main.ATLAS_WIDTH;
		mpBarV = mpBarRect.y / Main.ATLAS_HEIGHT;
		mpBarW = mpBarRect.width;
		mpBarH = mpBarRect.height;

		var oxygenBarRect = AssetLibrary.getRectFromSet("bars", 0x2);
		oxygenBarU = oxygenBarRect.x / Main.ATLAS_WIDTH;
		oxygenBarV = oxygenBarRect.y / Main.ATLAS_HEIGHT;
		oxygenBarW = oxygenBarRect.width;
		oxygenBarH = oxygenBarRect.height;

		var shieldBarRect = AssetLibrary.getRectFromSet("bars", 0x3);
		shieldBarU = shieldBarRect.x / Main.ATLAS_WIDTH;
		shieldBarV = shieldBarRect.y / Main.ATLAS_HEIGHT;
		shieldBarW = hpBarRect.width;
		shieldBarH = hpBarRect.height;

		var emptyBarRect = AssetLibrary.getRectFromSet("bars", 0x4);
		emptyBarU = emptyBarRect.x / Main.ATLAS_WIDTH;
		emptyBarV = emptyBarRect.y / Main.ATLAS_HEIGHT;
		emptyBarW = hpBarRect.width;
		emptyBarH = hpBarRect.height;

		this.defaultProgram = RenderUtils.compileShaders(Assets.getText("assets/shaders/base.vert"), Assets.getText("assets/shaders/base.frag"));
		this.lowGlowProgram = RenderUtils.compileShaders(Assets.getText("assets/shaders/base.vert"), Assets.getText("assets/shaders/baseLowGlow.frag"));
		this.medGlowProgram = RenderUtils.compileShaders(Assets.getText("assets/shaders/base.vert"), Assets.getText("assets/shaders/baseMedGlow.frag"));
		this.highGlowProgram = RenderUtils.compileShaders(Assets.getText("assets/shaders/base.vert"), Assets.getText("assets/shaders/baseHighGlow.frag"));
		this.veryHighGlowProgram = RenderUtils.compileShaders(Assets.getText("assets/shaders/base.vert"), Assets.getText("assets/shaders/baseVHighGlow.frag"));
		this.singleProgram = RenderUtils.compileShaders(Assets.getText("assets/shaders/baseSingle.vert"), Assets.getText("assets/shaders/baseSingle.frag"));
		this.groundProgram = RenderUtils.compileShaders(Assets.getText("assets/shaders/ground.vert"), Assets.getText("assets/shaders/ground.frag"));
		this.lightProgram = RenderUtils.compileShaders(Assets.getText("assets/shaders/lightBatch.vert"), Assets.getText("assets/shaders/lightBatch.frag"));

		vertScaleUniformLoc = GL.getUniformLocation(this.singleProgram, "vertScale");
		vertPosUniformLoc = GL.getUniformLocation(this.singleProgram, "vertPos");
		texelSizeUniformLoc = GL.getUniformLocation(this.singleProgram, "texelSize");
		colorUniformLoc = GL.getUniformLocation(this.singleProgram, "color");
		alphaMultUniformLoc = GL.getUniformLocation(this.singleProgram, "alphaMult");

		leftMaskUniformLoc = GL.getUniformLocation(this.groundProgram, "leftMaskUV");
		topMaskUniformLoc = GL.getUniformLocation(this.groundProgram, "topMaskUV");
		rightMaskUniformLoc = GL.getUniformLocation(this.groundProgram, "rightMaskUV");
		bottomMaskUniformLoc = GL.getUniformLocation(this.groundProgram, "bottomMaskUV");

		this.singleVBO = RenderUtils.createVertexBuffer(new Float32Array([
			 0.5, -0.5, 0, 0,
			-0.5, -0.5, 1, 0,
			 0.5,  0.5, 0, 1,
			-0.5,  0.5, 1, 1
		]));
		this.singleIBO = RenderUtils.createIndexBuffer(new Int16Array([0, 1, 2, 2, 1, 3]));

		this.groundVAO = GL.createVertexArray();
		this.groundIBO = GL.createBuffer();
		this.groundVBO = GL.createBuffer();

		GL.bindBuffer(GL.ARRAY_BUFFER, this.groundVBO);
		GL.bufferData(GL.ARRAY_BUFFER, 0, new Float32Array([]), GL.DYNAMIC_DRAW);
		GL.enableVertexAttribArray(0);
		GL.vertexAttribPointer(0, 4, GL.FLOAT, false, 56, 0);
		GL.enableVertexAttribArray(1);
		GL.vertexAttribPointer(1, 2, GL.FLOAT, false, 56, 16);
		GL.enableVertexAttribArray(2);
		GL.vertexAttribPointer(2, 2, GL.FLOAT, false, 56, 24);
		GL.enableVertexAttribArray(3);
		GL.vertexAttribPointer(3, 2, GL.FLOAT, false, 56, 32);
		GL.enableVertexAttribArray(4);
		GL.vertexAttribPointer(4, 2, GL.FLOAT, false, 56, 40);
		GL.enableVertexAttribArray(5);
		GL.vertexAttribPointer(5, 2, GL.FLOAT, false, 56, 48);
		GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, this.groundIBO);
		GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, 0, new Int32Array([]), GL.DYNAMIC_DRAW);

		this.objVAO = GL.createVertexArray();
		this.objIBO = GL.createBuffer();
		this.objVBO = GL.createBuffer();

		GL.bindBuffer(GL.ARRAY_BUFFER, this.objVBO);
		GL.bufferData(GL.ARRAY_BUFFER, 0, new Float32Array([]), GL.DYNAMIC_DRAW);
		GL.enableVertexAttribArray(0);
		GL.vertexAttribPointer(0, 4, GL.FLOAT, false, 40, 0);
		GL.enableVertexAttribArray(1);
		GL.vertexAttribPointer(1, 2, GL.FLOAT, false, 40, 16);
		GL.enableVertexAttribArray(2);
		GL.vertexAttribPointer(2, 2, GL.FLOAT, false, 40, 24);
		GL.enableVertexAttribArray(3);
		GL.vertexAttribPointer(3, 1, GL.FLOAT, false, 40, 32);
		GL.enableVertexAttribArray(4);
		GL.vertexAttribPointer(4, 1, GL.FLOAT, false, 40, 36);
		GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, this.objIBO);
		GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, 0, new Int32Array([]), GL.DYNAMIC_DRAW);

		this.lightVAO = GL.createVertexArray();
		this.lightVBO = GL.createBuffer();
		this.lightIBO = GL.createBuffer();

		GL.bindBuffer(GL.ARRAY_BUFFER, this.lightVBO);
		GL.bufferData(GL.ARRAY_BUFFER, 0, new Float32Array([]), GL.DYNAMIC_DRAW);
		GL.enableVertexAttribArray(0);
		GL.vertexAttribPointer(0, 4, GL.FLOAT, false, 32, 0);
		GL.enableVertexAttribArray(1);
		GL.vertexAttribPointer(1, 3, GL.FLOAT, false, 32, 16);
		GL.enableVertexAttribArray(2);
		GL.vertexAttribPointer(2, 1, GL.FLOAT, false, 32, 28);
		GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, this.lightIBO);
		GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, 0, new Int32Array([]), GL.DYNAMIC_DRAW);

		this.c3d = Main.primaryStage3D.context3D;
		this.c3d.configureBackBuffer(Main.stageWidth, Main.stageHeight, 0, true);
		this.c3d.setScissorRectangle(new openfl.geom.Rectangle(0, 0, Main.stageWidth, Main.stageHeight));

		this.screenData = TextureFactory.make(new BitmapData(1, 1, false, 0xFFFFFF), false);
		this.screenTex = this.screenData.texture;

		this.lightData = TextureFactory.make(AssetLibrary.getImageFromSet("light", 0), true, GL.LINEAR);
		this.lightTex = this.lightData.texture;

		this.lastWidth = Main.stageWidth;
		this.lastHeight = Main.stageHeight;
		RenderUtils.clipSpaceScaleX = 2 / Main.stageWidth;
		RenderUtils.clipSpaceScaleY = 2 / Main.stageHeight;
	}

	public function dispose() {
		this.squares = null;
		this.visSquares = null;

		if (this.gameObjects != null)
			for (obj in this.gameObjects)
				obj.dispose();

		this.gameObjects = null;
		this.goRemove = null;
		this.rdSingle = null;

		this.player = null;
		this.quest = null;
		TextureFactory.disposeTextures();
	}

	public function update(time: Int32, dt: Int16) {
		var i = 0;
		this.goRemove.resize(0);
		while (i < this.gameObjectsLen) {
			var go = this.gameObjects.unsafeGet(i);
			if (!go.update(time, dt))
				this.goRemove.push(go);
			i++;
		}

		i = 0;

		while (i < this.goRemove.length) {
			var go = this.goRemove[i];
			go.removeFromMap();
			this.gameObjects.remove(go);
			this.gameObjectsLen--;
			i++;
		}
	}

	private inline function validPos(x: UInt16, y: UInt16) {
		return !(x < 0 || x >= this.mapWidth || y < 0 || y >= this.mapHeight);
	}

	private inline function updateBlends(x: UInt16, y: UInt16, square: Square) {
		if (validPos(x - 1, y)) {
			var leftSq = this.squares[x - 1 + y * this.mapWidth];
			if (leftSq != null) {
				if (leftSq.props.blendPriority > square.props.blendPriority) {
					square.leftBlendU = leftSq.baseU;
					square.leftBlendV = leftSq.baseV;
				} else if (leftSq.props.blendPriority < square.props.blendPriority) {
					leftSq.rightBlendU = square.baseU;
					leftSq.rightBlendV = square.baseV;
				} else {
					square.leftBlendU = square.leftBlendV = -1.0;
					leftSq.rightBlendU = leftSq.rightBlendV = -1.0;
				}
			}
		}

		if (validPos(x, y - 1)) {
			var topSq = this.squares[x + (y - 1) * this.mapWidth];
			if (topSq != null) {
				if (topSq.props.blendPriority > square.props.blendPriority) {
					square.topBlendU = topSq.baseU;
					square.topBlendV = topSq.baseV;
				} else if (topSq.props.blendPriority < square.props.blendPriority) {
					topSq.bottomBlendU = square.baseU;
					topSq.bottomBlendV = square.baseV;
				} else {
					square.topBlendU = square.topBlendV = -1.0;
					topSq.bottomBlendU = topSq.bottomBlendV = -1.0;
				}
			}
		}

		if (validPos(x + 1, y)) {
			var rightSq = this.squares[x + 1 + y * this.mapWidth];
			if (rightSq != null) {
				if (rightSq.props.blendPriority > square.props.blendPriority) {
					square.rightBlendU = rightSq.baseU;
					square.rightBlendV = rightSq.baseV;
				} else if (rightSq.props.blendPriority < square.props.blendPriority) {
					rightSq.leftBlendU = square.baseU;
					rightSq.leftBlendV = square.baseV;
				} else {
					square.rightBlendU = square.rightBlendV = -1.0;
					rightSq.leftBlendU = rightSq.leftBlendV = -1.0;
				}
			}
		}

		if (validPos(x, y + 1)) {
			var bottomSq = this.squares[x + (y + 1) * this.mapWidth];
			if (bottomSq != null) {
				if (bottomSq.props.blendPriority > square.props.blendPriority) {
					square.bottomBlendU = bottomSq.baseU;
					square.bottomBlendV = bottomSq.baseV;
				} else if (bottomSq.props.blendPriority < square.props.blendPriority) {
					bottomSq.topBlendU = square.baseU;
					bottomSq.topBlendV = square.baseV;
				} else {
					square.bottomBlendU = square.bottomBlendV = -1.0;
					bottomSq.topBlendU = bottomSq.topBlendV = -1.0;
				}
			}
		}
	}

	public function setGroundTile(x: UInt16, y: UInt16, tileType: UInt16) {
		if (!validPos(x, y))
			return;

		var idx: Int32 = x + y * this.mapWidth;
		var square = this.squares[idx];
		if (square == null) {
			square = new Square(x + 0.5, y + 0.5);
			this.squares[idx] = square;
		}

		square.tileType = tileType;
		square.props = GroundLibrary.propsLibrary.get(tileType);
		var texData = GroundLibrary.typeToTextureData.get(tileType).getTextureData();
		square.baseU = texData.uValue + Main.PADDING / Main.ATLAS_WIDTH;
		square.baseV = texData.vValue + Main.PADDING / Main.ATLAS_HEIGHT;
		var animationsData = GroundLibrary.typeToAnimationsData.get(tileType);
		if (animationsData != null)
			square.animations = new Animations(animationsData);
		square.sink = square.props != null && square.props.sink ? 0.6 : 0;

		updateBlends(x, y, square);
	}

	public function addGameObject(go: GameObject, posX: Float32, posY: Float32) {
		go.mapX = posX;
		go.mapY = posY;

		if (!go.addTo(this, go.mapX, go.mapY))
			return;

		this.gameObjects.push(go);
		this.gameObjectsLen++;
	}

	public function removeObj(objectId: Int32) {
		var i = 0;
		while (i < this.gameObjectsLen) {
			var go = this.gameObjects.unsafeGet(i);
			if (go.objectId == objectId) {
				go.removeFromMap();
				this.gameObjects.splice(i, 1);
				this.gameObjectsLen--;
				return;
			}
			i++;
		}
	}

	public function getGameObject(objectId: Int32) {
		var i = 0;
		while (i < this.gameObjectsLen) {
			var go = this.gameObjects.unsafeGet(i);
			if (go.objectId == objectId)
				return go;
			i++;
		}

		return null;
	}

	public function removeGameObject(objectId: Int32) {
		var i = 0;
		while (i < this.gameObjectsLen) {
			var go = this.gameObjects.unsafeGet(i);
			if (go.objectId == objectId) {
				go.removeFromMap();
				this.gameObjects.splice(i, 1);
				this.gameObjectsLen--;
				return;
			}
			i++;
		}
	}

	public function lookupSquare(x: UInt16, y: UInt16) {
		return x < 0
			|| x >= this.mapWidth
			|| y < 0
			|| y >= this.mapHeight
			|| player != null
			&& (player.mapX < 0 || player.mapY < 0) ? null : this.squares[x + y * this.mapWidth];
	}

	public function forceLookupSquare(x: UInt16, y: UInt16) {
		if (x < 0 || x >= this.mapWidth || y < 0 || y >= this.mapHeight || player != null && (player.mapX < 0 || player.mapY < 0))
			return null;

		var idx = x + y * this.mapWidth;
		var square = this.squares[idx];
		if (square == null) {
			square = new Square(x + 0.5, y + 0.5);
			this.squares[idx] = square;
		}

		return square;
	}

	private final inline function drawGeneric(x1: Float32, y1: Float32, x2: Float32, y2: Float32, x3: Float32, y3: Float32, x4: Float32, y4: Float32,
			texU: Float32, texV: Float32, texW: Float32, texH: Float32, texelW: Float32 = 0, texelH: Float32 = 0, glowColor: Float32 = 0,
			flashColor: Float32 = 0, flashStrength: Float32 = 0, alphaMult: Float32 = -1) {
		this.vertDataList[this.vertIdx++] = x1;
		this.vertDataList[this.vertIdx++] = y1;
		this.vertDataList[this.vertIdx++] = texU;
		this.vertDataList[this.vertIdx++] = texV;

		this.vertDataList[this.vertIdx++] = texelW;
		this.vertDataList[this.vertIdx++] = texelH;
		this.vertDataList[this.vertIdx++] = glowColor;
		this.vertDataList[this.vertIdx++] = flashColor;
		this.vertDataList[this.vertIdx++] = flashStrength;
		this.vertDataList[this.vertIdx++] = alphaMult;

		this.vertDataList[this.vertIdx++] = x2;
		this.vertDataList[this.vertIdx++] = y2;
		this.vertDataList[this.vertIdx++] = texU + texW;
		this.vertDataList[this.vertIdx++] = texV;

		this.vertDataList[this.vertIdx++] = texelW;
		this.vertDataList[this.vertIdx++] = texelH;
		this.vertDataList[this.vertIdx++] = glowColor;
		this.vertDataList[this.vertIdx++] = flashColor;
		this.vertDataList[this.vertIdx++] = flashStrength;
		this.vertDataList[this.vertIdx++] = alphaMult;

		this.vertDataList[this.vertIdx++] = x3;
		this.vertDataList[this.vertIdx++] = y3;
		this.vertDataList[this.vertIdx++] = texU;
		this.vertDataList[this.vertIdx++] = texV + texH;

		this.vertDataList[this.vertIdx++] = texelW;
		this.vertDataList[this.vertIdx++] = texelH;
		this.vertDataList[this.vertIdx++] = glowColor;
		this.vertDataList[this.vertIdx++] = flashColor;
		this.vertDataList[this.vertIdx++] = flashStrength;
		this.vertDataList[this.vertIdx++] = alphaMult;

		this.vertDataList[this.vertIdx++] = x4;
		this.vertDataList[this.vertIdx++] = y4;
		this.vertDataList[this.vertIdx++] = texU + texW;
		this.vertDataList[this.vertIdx++] = texV + texH;

		this.vertDataList[this.vertIdx++] = texelW;
		this.vertDataList[this.vertIdx++] = texelH;
		this.vertDataList[this.vertIdx++] = glowColor;
		this.vertDataList[this.vertIdx++] = flashColor;
		this.vertDataList[this.vertIdx++] = flashStrength;
		this.vertDataList[this.vertIdx++] = alphaMult;

		final i4 = this.count * 4;
		this.indexDataList[this.indexIdx++] = i4;
		this.indexDataList[this.indexIdx++] = 1 + i4;
		this.indexDataList[this.indexIdx++] = 2 + i4;
		this.indexDataList[this.indexIdx++] = 2 + i4;
		this.indexDataList[this.indexIdx++] = 1 + i4;
		this.indexDataList[this.indexIdx++] = 3 + i4;
		this.count++;
	}

	private final function getLightIntensity(time: Int32) {
		if (this.serverTimeOffset == 0)
			return this.bgLightIntensity;

		var serverTimeClamped = (time + this.serverTimeOffset) % DAY_CYCLE_MS;
		if (serverTimeClamped <= DAY_CYCLE_MS / 2)
			return this.nightLightIntensity + (this.dayLightIntensity - this.nightLightIntensity) * (serverTimeClamped / (DAY_CYCLE_MS / 2));
		else
			return this.dayLightIntensity
				- (this.dayLightIntensity - this.nightLightIntensity) * ((serverTimeClamped - DAY_CYCLE_MS / 2) / (DAY_CYCLE_MS / 2));
	}

	public final function draw(time: Int32) {
		var camX = Camera.mapX, camY = Camera.mapY;

		var minX = Camera.minX;
		var maxX = Camera.maxX;
		if (maxX > this.mapWidth)
			maxX = this.mapWidth;
		var minY = Camera.minY;
		var maxY = Camera.maxY;
		if (maxY > this.mapHeight)
			maxY = this.mapHeight;

		if (time - this.lastTileUpdate > TILE_UPDATE_MS && camX >= 0 && camY >= 0) {
			var visIdx: UInt16 = 0;
			for (x in minX...maxX)
				for (y in minY...maxY) {
					var dx: Float32 = camX - x - 0.5;
					var dy: Float32 = camY - y - 0.5;
					if (dx * dx + dy * dy > Camera.maxDistSq)
						continue;

					var square = this.squares[x + y * mapWidth];
					if (square == null)
						continue;

					this.visSquares[visIdx++] = square;
					#if debug
					if (visIdx > MAX_VISIBLE_SQUARES)
						throw new Exception("Client sees more tiles than it should");
					#end
					square.lastVisible = time + TILE_UPDATE_MS;
				}

			this.visSquareLen = visIdx;
			this.lastTileUpdate = time;
		}

		if (time - this.lastBufferUpdate > BUFFER_UPDATE_MS) {
			if (Main.stageWidth != this.lastWidth || Main.stageHeight != this.lastHeight) {
				this.c3d.configureBackBuffer(Main.stageWidth, Main.stageHeight, 0, false);
				this.c3d.setScissorRectangle(new openfl.geom.Rectangle(0, 0, Main.stageWidth, Main.stageHeight));

				this.lastWidth = Main.stageWidth;
				this.lastHeight = Main.stageHeight;
				RenderUtils.clipSpaceScaleX = 2 / Main.stageWidth;
				RenderUtils.clipSpaceScaleY = 2 / Main.stageHeight;
			}

			this.lastBufferUpdate = time;
		}

		this.c3d.clear();
		this.rdSingle.resize(0);

		GL.disable(GL.DEPTH_TEST);
		GL.disable(GL.STENCIL_TEST);
		GL.disable(GL.DITHER);

		GL.activeTexture(GL.TEXTURE0);
		GL.bindTexture(GL.TEXTURE_2D, Main.atlas.texture);

		var i: Int32 = 0;

		this.count = this.vertIdx = this.indexIdx = this.lightIdx = 0;

		final xScaledCos = Camera.xScaledCos;
		final yScaledCos = Camera.yScaledCos;
		final xScaledSin = Camera.xScaledSin;
		final yScaledSin = Camera.yScaledSin;

		GL.useProgram(this.groundProgram);
		GL.uniform2f(leftMaskUniformLoc, leftMaskU, leftMaskV);
		GL.uniform2f(topMaskUniformLoc, topMaskU, topMaskV);
		GL.uniform2f(rightMaskUniformLoc, rightMaskU, rightMaskV);
		GL.uniform2f(bottomMaskUniformLoc, bottomMaskU, bottomMaskV);

		while (i < this.visSquareLen) {
			final square = this.visSquares[i];

			if (square.animations != null) {
				var rect = square.animations.getTexture(time);
				if (rect != null) {
					square.baseU = (rect.x + Main.PADDING) / Main.ATLAS_WIDTH;
					square.baseV = (rect.y + Main.PADDING) / Main.ATLAS_WIDTH;
					updateBlends(square.x, square.y, square);
				}
			}

			square.clipX = (square.middleX * Camera.cos + square.middleY * Camera.sin + Camera.csX) * RenderUtils.clipSpaceScaleX;
			square.clipY = (square.middleX * -Camera.sin + square.middleY * Camera.cos + Camera.csY) * RenderUtils.clipSpaceScaleY;

			if (square.props.lightColor != -1) {
				this.lightDataList[this.lightIdx++] = Camera.PX_PER_TILE * RenderUtils.clipSpaceScaleX * 8 * square.props.lightRadius;
				this.lightDataList[this.lightIdx++] = Camera.PX_PER_TILE * RenderUtils.clipSpaceScaleY * 8 * square.props.lightRadius;
				this.lightDataList[this.lightIdx++] = square.clipX;
				this.lightDataList[this.lightIdx++] = square.clipY;
				this.lightDataList[this.lightIdx++] = square.props.lightColor;
				this.lightDataList[this.lightIdx++] = square.props.lightIntensity;
			}

			final w: Float32 = 8 / Main.ATLAS_WIDTH;
			final h: Float32 = 8 / Main.ATLAS_HEIGHT;

			this.vertDataList[this.vertIdx++] = -xScaledCos - xScaledSin + square.clipX;
			this.vertDataList[this.vertIdx++] = yScaledSin - yScaledCos + square.clipY;
			this.vertDataList[this.vertIdx++] = 0;
			this.vertDataList[this.vertIdx++] = 0;

			this.vertDataList[this.vertIdx++] = square.leftBlendU;
			this.vertDataList[this.vertIdx++] = square.leftBlendV;
			this.vertDataList[this.vertIdx++] = square.topBlendU;
			this.vertDataList[this.vertIdx++] = square.topBlendV;

			this.vertDataList[this.vertIdx++] = square.rightBlendU;
			this.vertDataList[this.vertIdx++] = square.rightBlendV;
			this.vertDataList[this.vertIdx++] = square.bottomBlendU;
			this.vertDataList[this.vertIdx++] = square.bottomBlendV;

			this.vertDataList[this.vertIdx++] = square.baseU;
			this.vertDataList[this.vertIdx++] = square.baseV;

			this.vertDataList[this.vertIdx++] = xScaledCos - xScaledSin + square.clipX;
			this.vertDataList[this.vertIdx++] = -yScaledSin - yScaledCos + square.clipY;
			this.vertDataList[this.vertIdx++] = w;
			this.vertDataList[this.vertIdx++] = 0;

			this.vertDataList[this.vertIdx++] = square.leftBlendU;
			this.vertDataList[this.vertIdx++] = square.leftBlendV;
			this.vertDataList[this.vertIdx++] = square.topBlendU;
			this.vertDataList[this.vertIdx++] = square.topBlendV;

			this.vertDataList[this.vertIdx++] = square.rightBlendU;
			this.vertDataList[this.vertIdx++] = square.rightBlendV;
			this.vertDataList[this.vertIdx++] = square.bottomBlendU;
			this.vertDataList[this.vertIdx++] = square.bottomBlendV;

			this.vertDataList[this.vertIdx++] = square.baseU;
			this.vertDataList[this.vertIdx++] = square.baseV;

			this.vertDataList[this.vertIdx++] = -xScaledCos + xScaledSin + square.clipX;
			this.vertDataList[this.vertIdx++] = yScaledSin + yScaledCos + square.clipY;
			this.vertDataList[this.vertIdx++] = 0;
			this.vertDataList[this.vertIdx++] = h;

			this.vertDataList[this.vertIdx++] = square.leftBlendU;
			this.vertDataList[this.vertIdx++] = square.leftBlendV;
			this.vertDataList[this.vertIdx++] = square.topBlendU;
			this.vertDataList[this.vertIdx++] = square.topBlendV;

			this.vertDataList[this.vertIdx++] = square.rightBlendU;
			this.vertDataList[this.vertIdx++] = square.rightBlendV;
			this.vertDataList[this.vertIdx++] = square.bottomBlendU;
			this.vertDataList[this.vertIdx++] = square.bottomBlendV;

			this.vertDataList[this.vertIdx++] = square.baseU;
			this.vertDataList[this.vertIdx++] = square.baseV;

			this.vertDataList[this.vertIdx++] = xScaledCos + xScaledSin + square.clipX;
			this.vertDataList[this.vertIdx++] = -yScaledSin + yScaledCos + square.clipY;
			this.vertDataList[this.vertIdx++] = w;
			this.vertDataList[this.vertIdx++] = h;

			this.vertDataList[this.vertIdx++] = square.leftBlendU;
			this.vertDataList[this.vertIdx++] = square.leftBlendV;
			this.vertDataList[this.vertIdx++] = square.topBlendU;
			this.vertDataList[this.vertIdx++] = square.topBlendV;

			this.vertDataList[this.vertIdx++] = square.rightBlendU;
			this.vertDataList[this.vertIdx++] = square.rightBlendV;
			this.vertDataList[this.vertIdx++] = square.bottomBlendU;
			this.vertDataList[this.vertIdx++] = square.bottomBlendV;

			this.vertDataList[this.vertIdx++] = square.baseU;
			this.vertDataList[this.vertIdx++] = square.baseV;

			final i4 = i * 4;
			this.indexDataList[this.indexIdx++] = i4;
			this.indexDataList[this.indexIdx++] = 1 + i4;
			this.indexDataList[this.indexIdx++] = 2 + i4;
			this.indexDataList[this.indexIdx++] = 2 + i4;
			this.indexDataList[this.indexIdx++] = 1 + i4;
			this.indexDataList[this.indexIdx++] = 3 + i4;
			i++;
		}

		GL.bindVertexArray(this.groundVAO);

		// think about 2x scaling factor... todo
		GL.bindBuffer(GL.ARRAY_BUFFER, this.groundVBO);
		if (this.vertIdx > this.groundVBOLen) {
			GL.bufferData(GL.ARRAY_BUFFER, this.vertIdx * 4, vertDataList, GL.DYNAMIC_DRAW);
			this.groundVBOLen = this.vertIdx;
		} else
			GL.bufferSubData(GL.ARRAY_BUFFER, 0, this.vertIdx * 4, vertDataList);

		GL.enableVertexAttribArray(0);
		GL.vertexAttribPointer(0, 4, GL.FLOAT, false, 56, 0);
		GL.enableVertexAttribArray(1);
		GL.vertexAttribPointer(1, 2, GL.FLOAT, false, 56, 16);
		GL.enableVertexAttribArray(2);
		GL.vertexAttribPointer(2, 2, GL.FLOAT, false, 56, 24);
		GL.enableVertexAttribArray(3);
		GL.vertexAttribPointer(3, 2, GL.FLOAT, false, 56, 32);
		GL.enableVertexAttribArray(4);
		GL.vertexAttribPointer(4, 2, GL.FLOAT, false, 56, 40);
		GL.enableVertexAttribArray(5);
		GL.vertexAttribPointer(5, 2, GL.FLOAT, false, 56, 48);

		GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, this.groundIBO);
		if (this.indexIdx > this.groundIBOLen) {
			GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, this.indexIdx * 4, this.indexDataList, GL.DYNAMIC_DRAW);
			this.groundIBOLen = this.indexIdx;
		} else
			GL.bufferSubData(GL.ELEMENT_ARRAY_BUFFER, 0, this.indexIdx * 4, this.indexDataList);
		GL.drawElements(GL.TRIANGLES, this.indexIdx, GL.UNSIGNED_INT, 0);

		if (this.gameObjectsLen == 0) {
			this.c3d.present();
			return;
		}

		i = this.vertIdx = this.indexIdx = 0;

		while (i < this.gameObjectsLen) {
			var obj = this.gameObjects.unsafeGet(i);
			obj.screenYNoZ = obj.mapX * -Camera.sin + obj.mapY * Camera.cos + Camera.csY;
			obj.sortValue = obj.screenYNoZ - (obj.props.drawOnGround ? Main.stageHeight : 0) + obj.props.sortPriority;
			i++;
		}

		i = 0;

		this.gameObjects.sort((a: GameObject, b: GameObject) -> Std.int(a.sortValue - b.sortValue));

		GL.blendEquation(GL.FUNC_ADD);
		GL.enable(GL.BLEND);
		GL.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
		switch (Settings.glowType) {
			case GlowType.None:
				GL.useProgram(this.defaultProgram);
			case GlowType.Low:
				GL.useProgram(this.lowGlowProgram);
			case GlowType.Medium:
				GL.useProgram(this.medGlowProgram);
			case GlowType.High:
				GL.useProgram(this.highGlowProgram);
			case GlowType.VeryHigh:
				GL.useProgram(this.veryHighGlowProgram);
		}

		while (i < this.gameObjectsLen) {
			var obj = this.gameObjects.unsafeGet(i);
			i++;

			if (i > 0 && i % 1400 == 0 && i != this.gameObjectsLen - 1) {
				GL.bindVertexArray(this.objVAO);

				GL.bindBuffer(GL.ARRAY_BUFFER, this.objVBO);
				if (this.vertIdx > this.objVBOLen) {
					GL.bufferData(GL.ARRAY_BUFFER, this.vertIdx * 4, vertDataList, GL.DYNAMIC_DRAW);
					this.objVBOLen = this.vertIdx;
				} else
					GL.bufferSubData(GL.ARRAY_BUFFER, 0, this.vertIdx * 4, vertDataList);

				GL.enableVertexAttribArray(0);
				GL.vertexAttribPointer(0, 4, GL.FLOAT, false, 40, 0);
				GL.enableVertexAttribArray(1);
				GL.vertexAttribPointer(1, 2, GL.FLOAT, false, 40, 16);
				GL.enableVertexAttribArray(2);
				GL.vertexAttribPointer(2, 2, GL.FLOAT, false, 40, 24);
				GL.enableVertexAttribArray(3);
				GL.vertexAttribPointer(3, 1, GL.FLOAT, false, 40, 32);
				GL.enableVertexAttribArray(4);
				GL.vertexAttribPointer(4, 1, GL.FLOAT, false, 40, 36);

				GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, this.objIBO);
				if (this.indexIdx > this.objIBOLen) {
					GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, this.indexIdx * 4, this.indexDataList, GL.DYNAMIC_DRAW);
					this.objIBOLen = this.indexIdx;
				} else
					GL.bufferSubData(GL.ELEMENT_ARRAY_BUFFER, 0, this.indexIdx * 4, this.indexDataList);

				GL.drawElements(GL.TRIANGLES, this.indexIdx, GL.UNSIGNED_INT, 0);
			}

			if (obj.mapX >= minX && obj.mapX <= maxX && obj.mapY >= minY && obj.mapY <= maxY) {
				switch (obj.objClass) {
					case "Wall":
						{
							if (obj.animations != null) {
								var rect = obj.animations.getTexture(time);
								if (rect != null) {
									obj.uValue = (rect.x + 2) / Main.ATLAS_WIDTH;
									obj.vValue = (rect.y + 2) / Main.ATLAS_WIDTH;
								}
							}

							var size = 8 / Main.ATLAS_WIDTH;
							var objX = obj.mapX;
							var objY = obj.mapY;
							var xBaseTop = (objX * Camera.cos + objY * Camera.sin + Camera.csX) * RenderUtils.clipSpaceScaleX;
							var yBaseTop = (objX * -Camera.sin + objY * Camera.cos + Camera.csY - Camera.PX_PER_TILE) * RenderUtils.clipSpaceScaleY;
							var xBase = (objX * Camera.cos + objY * Camera.sin + Camera.csX) * RenderUtils.clipSpaceScaleX;
							var yBase = (objX * -Camera.sin + objY * Camera.cos + Camera.csY) * RenderUtils.clipSpaceScaleY;

							if (obj.props.isEnemy) {
								obj.hBase = size * Camera.SIZE_MULT;
								obj.screenX = xBaseTop;
								obj.screenYNoZ = yBaseTop;
							}

							var xScaledCos = Camera.xScaledCos;
							var yScaledCos = Camera.yScaledCos;
							var xScaledSin = Camera.xScaledSin;
							var yScaledSin = Camera.yScaledSin;

							final floorX = Math.floor(objX);
							final floorY = Math.floor(objY);

							var uValue: Float32 = 0.0, vValue: Float32 = 0.0;
							var boundAngle = MathUtil.halfBound(Camera.angleRad);
							if (boundAngle >= MathUtil.PI_DIV_2 && boundAngle <= MathUtil.PI || boundAngle >= -MathUtil.PI && boundAngle <=
								-MathUtil.PI_DIV_2) {
								var topSquare = validPos(floorX, floorY - 1) ? this.squares[(floorY - 1) * this.mapWidth + floorX] : null;
								var topSqNull = topSquare == null;
								if (topSqNull || topSquare.obj == null || topSquare.obj.objClass != "Wall") {
									if (topSqNull || topSquare.tileType == 0xFF) {
										uValue = wallBackfaceU;
										vValue = wallBackfaceV;
									} else {
										uValue = obj.uValue + Main.PADDING / Main.ATLAS_WIDTH;
										vValue = obj.vValue + Main.PADDING / Main.ATLAS_HEIGHT;
									}

									this.drawGeneric(-xScaledCos
										+ xScaledSin
										+ xBaseTop
										- xScaledSin * 2,
										yScaledSin
										+ yScaledCos
										+ yBaseTop
										- yScaledCos * 2, xScaledCos
										+ xScaledSin
										+ xBaseTop
										- xScaledSin * 2,
										-yScaledSin
										+ yScaledCos
										+ yBaseTop
										- yScaledCos * 2,
										-xScaledCos
										+ xScaledSin
										+ xBase
										- xScaledSin * 2,
										yScaledSin
										+ yScaledCos
										+ yBase
										- yScaledCos * 2, xScaledCos
										+ xScaledSin
										+ xBase
										- xScaledSin * 2,
										-yScaledSin
										+ yScaledCos
										+ yBase
										- yScaledCos * 2, uValue, vValue, size, size, 0, 0, 0, 1.0, 0.25);
								}
							}

							if (boundAngle <= MathUtil.PI_DIV_2 && boundAngle >= -MathUtil.PI_DIV_2) {
								var bottomSquare = validPos(floorX, floorY + 1) ? this.squares[(floorY + 1) * this.mapWidth + floorX] : null;
								var bottomSqNull = bottomSquare == null;
								if (bottomSqNull || bottomSquare.obj == null || bottomSquare.obj.objClass != "Wall") {
									if (bottomSqNull || bottomSquare.tileType == 0xFF) {
										uValue = wallBackfaceU;
										vValue = wallBackfaceV;
									} else {
										uValue = obj.uValue + Main.PADDING / Main.ATLAS_WIDTH;
										vValue = obj.vValue + Main.PADDING / Main.ATLAS_HEIGHT;
									}

									this.drawGeneric(-xScaledCos
										+ xScaledSin
										+ xBaseTop, yScaledSin
										+ yScaledCos
										+ yBaseTop,
										xScaledCos
										+ xScaledSin
										+ xBaseTop,
										-yScaledSin
										+ yScaledCos
										+ yBaseTop,
										-xScaledCos
										+ xScaledSin
										+ xBase,
										yScaledSin
										+ yScaledCos
										+ yBase, xScaledCos
										+ xScaledSin
										+ xBase,
										-yScaledSin
										+ yScaledCos
										+ yBase, uValue, vValue,
										size, size, 0, 0, 0, 1.0, 0.25);
								}
							}

							if (boundAngle >= 0 && boundAngle <= MathUtil.PI) {
								var leftSquare = validPos(floorX - 1, floorY) ? this.squares[floorY * this.mapWidth + floorX - 1] : null;
								var leftSqNull = leftSquare == null;
								if (leftSqNull || leftSquare.obj == null || leftSquare.obj.objClass != "Wall") {
									if (leftSqNull || leftSquare.tileType == 0xFF) {
										uValue = wallBackfaceU;
										vValue = wallBackfaceV;
									} else {
										uValue = obj.uValue + Main.PADDING / Main.ATLAS_WIDTH;
										vValue = obj.vValue + Main.PADDING / Main.ATLAS_HEIGHT;
									}

									this.drawGeneric(-xScaledCos
										- xScaledSin
										+ xBaseTop, yScaledSin
										- yScaledCos
										+ yBaseTop,
										-xScaledCos
										+ xScaledSin
										+ xBaseTop, yScaledSin
										+ yScaledCos
										+ yBaseTop,
										-xScaledCos
										+ xScaledSin
										+ xBase
										- xScaledSin * 2, yScaledSin
										+ yScaledCos
										+ yBase
										- yScaledCos * 2,
										-xScaledCos
										+ xScaledSin
										+ xBase, yScaledSin
										+ yScaledCos
										+ yBase, uValue, vValue, size, size, 0, 0, 0, 1.0, 0.25);
								}
							}

							if (boundAngle <= 0 && boundAngle >= -MathUtil.PI) {
								var rightSquare = validPos(floorX + 1, floorY) ? this.squares[floorY * this.mapWidth + floorX + 1] : null;
								var rightSqNull = rightSquare == null;
								if (rightSqNull || rightSquare.obj == null || rightSquare.obj.objClass != "Wall") {
									if (rightSqNull || rightSquare.tileType == 0xFF) {
										uValue = wallBackfaceU;
										vValue = wallBackfaceV;
									} else {
										uValue = obj.uValue + Main.PADDING / Main.ATLAS_WIDTH;
										vValue = obj.vValue + Main.PADDING / Main.ATLAS_HEIGHT;
									}

									this.drawGeneric(xScaledCos
										- xScaledSin
										+ xBaseTop,
										-yScaledSin
										- yScaledCos
										+ yBaseTop,
										xScaledCos
										+ xScaledSin
										+ xBaseTop,
										-yScaledSin
										+ yScaledCos
										+ yBaseTop,
										xScaledCos
										+ xScaledSin
										+ xBase
										- xScaledSin * 2,
										-yScaledSin
										+ yScaledCos
										+ yBase
										- yScaledCos * 2,
										xScaledCos
										+ xScaledSin
										+ xBase,
										-yScaledSin
										+ yScaledCos
										+ yBase, uValue, vValue, size, size, 0, 0, 0, 1.0, 0.25);
								}
							}

							this.drawGeneric(-xScaledCos
								- xScaledSin
								+ xBaseTop, yScaledSin
								- yScaledCos
								+ yBaseTop, xScaledCos
								- xScaledSin
								+ xBaseTop,
								-yScaledSin
								- yScaledCos
								+ yBaseTop,
								-xScaledCos
								+ xScaledSin
								+ xBaseTop, yScaledSin
								+ yScaledCos
								+ yBaseTop,
								xScaledCos
								+ xScaledSin
								+ xBaseTop,
								-yScaledSin
								+ yScaledCos
								+ yBaseTop, obj.topUValue + Main.PADDING / Main.ATLAS_WIDTH, obj.topVValue + Main.PADDING / Main.ATLAS_HEIGHT, size, size, 0, 0, 0,
								1.0, 0.1);
						}
					case "Player":
						{
							var player: Player = cast obj;
							var screenX = player.screenX = player.mapX * Camera.cos + player.mapY * Camera.sin + Camera.csX;
							var screenY = player.screenYNoZ + player.mapZ * -Camera.PX_PER_TILE;

							var texW = player.width * Main.ATLAS_WIDTH,
								texH = player.height * Main.ATLAS_HEIGHT;

							var action = AnimatedChar.STAND;
							var p: Float32 = 0.0;
							var rect: Rect = null;
							if (player.animatedChar != null) {
								if (time < player.attackStart + GameObject.ATTACK_PERIOD) {
									if (!player.props.dontFaceAttacks)
										player.facing = player.attackAngle;

									p = (time - player.attackStart) % GameObject.ATTACK_PERIOD / GameObject.ATTACK_PERIOD;
									action = AnimatedChar.ATTACK;
								} else if (player.moveVec.x != 0 || player.moveVec.y != 0) {
									var walkPer = Std.int(0.5 / player.moveVec.length);
									walkPer += 400 - walkPer % 400;
									if (player.moveVec.x > GameObject.ZERO_LIMIT
										|| player.moveVec.x < GameObject.NEGATIVE_ZERO_LIMIT
										|| player.moveVec.y > GameObject.ZERO_LIMIT
										|| player.moveVec.y < GameObject.NEGATIVE_ZERO_LIMIT) {
										player.facing = Math.atan2(player.moveVec.y, player.moveVec.x);
										action = AnimatedChar.WALK;
									} else
										action = AnimatedChar.STAND;

									p = time % walkPer / walkPer;
								}

								rect = player.animatedChar.rectFromFacing(player.facing, action, p);
							} else if (player.animations != null)
								rect = player.animations.getTexture(time);

							if (rect != null) {
								player.uValue = rect.x / Main.ATLAS_WIDTH;
								player.vValue = rect.y / Main.ATLAS_WIDTH;
								texW = rect.width;
								player.width = texW / Main.ATLAS_WIDTH;
								texH = rect.height;
								player.height = texH / Main.ATLAS_HEIGHT;
							}

							var sink: Float32 = 1.0;
							if (player.curSquare != null
								&& !(player.flying || player.curSquare.obj != null && player.curSquare.obj.props.protectFromSink))
								sink += player.curSquare.sink + player.sinkLevel;

							var flashStrength: Float32 = 0.0;
							if (player.flashPeriodMs > 0) {
								if (player.flashRepeats != -1 && time > player.flashStartTime + player.flashPeriodMs * player.flashRepeats)
									player.flashRepeats = player.flashStartTime = player.flashPeriodMs = player.flashColor = 0;
								else
									flashStrength = MathUtil.sin((time - player.flashStartTime) % player.flashPeriodMs / player.flashPeriodMs * MathUtil.PI) * 0.5;
							}

							var size = Camera.SIZE_MULT * player.size;
							var w = size * texW * RenderUtils.clipSpaceScaleX * 0.5;
							var hBase = player.hBase = size * texH;
							var h = hBase * RenderUtils.clipSpaceScaleY * 0.5 / sink;
							var yBase = (screenY - (hBase / 2 - size * Main.PADDING)) * RenderUtils.clipSpaceScaleY;
							var xOffset: Float32 = 0.0;
							if (action == AnimatedChar.ATTACK && p >= 0.5) {
								var dir = player.animatedChar.facingToDir(player.facing);
								if (dir == AnimatedChar.LEFT)
									xOffset = -w / 2 + size * Main.PADDING * RenderUtils.clipSpaceScaleX * 0.5;
								else
									xOffset = w / 2 - size * Main.PADDING * RenderUtils.clipSpaceScaleX * 0.5;
							}
							var xBase = screenX * RenderUtils.clipSpaceScaleX + xOffset;
							var texelW: Float32 = Main.BASE_TEXEL_W * 2 / size;
							var texelH: Float32 = Main.BASE_TEXEL_H * 2 / size;
							var alphaMult: Float32 = ((player.condition & ConditionEffect.INVISIBLE_BIT) != 0 ? 0.6 : player.props.alphaMult);

							if (player.props.lightColor != -1) {
								this.lightDataList[this.lightIdx++] = w * 8 * player.props.lightRadius;
								this.lightDataList[this.lightIdx++] = h * 8 * player.props.lightRadius;
								this.lightDataList[this.lightIdx++] = xBase;
								this.lightDataList[this.lightIdx++] = yBase;
								this.lightDataList[this.lightIdx++] = player.props.lightColor;
								this.lightDataList[this.lightIdx++] = player.props.lightIntensity;
							}

							this.drawGeneric(-w + xBase, -h + yBase, w + xBase, -h + yBase, -w + xBase, h + yBase, w + xBase, h + yBase, player.uValue,
								player.vValue, player.width, player.height / sink, texelW, texelH, player.glowColor, player.flashColor, flashStrength,
								alphaMult);

							var yPos: Int32 = 15 + (sink != 0 ? 5 : 0);
							if (player.props == null || !player.props.noMiniMap) {
								xBase = screenX * RenderUtils.clipSpaceScaleX;

								if (player.hp > player.maxHP)
									player.maxHP = player.hp;

								var scaledEmptyBarW: Float32 = emptyBarW / Main.ATLAS_WIDTH;
								var scaledEmptyBarH: Float32 = emptyBarH / Main.ATLAS_HEIGHT;
								if (player.hp >= 0 && player.hp < player.maxHP) {
									var scaledBarW: Float32 = hpBarW / Main.ATLAS_WIDTH;
									var scaledBarH: Float32 = hpBarH / Main.ATLAS_HEIGHT;
									w = hpBarW * RenderUtils.clipSpaceScaleX;
									h = hpBarH * RenderUtils.clipSpaceScaleY;
									yBase = (screenY + yPos - (hpBarH / 2 - Main.PADDING)) * RenderUtils.clipSpaceScaleY;
									texelW = Main.BASE_TEXEL_W * 0.5;
									texelH = Main.BASE_TEXEL_H * 0.5;

									this.drawGeneric(-w + xBase, -h + yBase, w + xBase, -h + yBase, -w + xBase, h + yBase, w + xBase, h + yBase, emptyBarU,
										emptyBarV, scaledEmptyBarW, scaledEmptyBarH, texelW, texelH);

									var hpPerc = 1 / (player.hp / player.maxHP);
									var hpPercOffset = (1 - player.hp / player.maxHP) * hpBarW * RenderUtils.clipSpaceScaleX;
									w /= hpPerc;

									this.drawGeneric(-w
										+ xBase
										- hpPercOffset,
										-h
										+ yBase, w
										+ xBase
										- hpPercOffset,
										-h
										+ yBase,
										-w
										+ xBase
										- hpPercOffset,
										h
										+ yBase, w
										+ xBase
										- hpPercOffset, h
										+ yBase, hpBarU, hpBarV, scaledBarW / hpPerc, scaledBarH, texelW, texelH);

									yPos += 20;
								}

								if (player.mp >= 0 && player.mp < player.maxMP) {
									var scaledBarW: Float32 = mpBarW / Main.ATLAS_WIDTH;
									var scaledBarH: Float32 = mpBarH / Main.ATLAS_HEIGHT;
									w = mpBarW * RenderUtils.clipSpaceScaleX;
									h = mpBarH * RenderUtils.clipSpaceScaleY;
									yBase = (screenY + yPos - (hpBarH / 2 - Main.PADDING)) * RenderUtils.clipSpaceScaleY;
									texelW = Main.BASE_TEXEL_W * 0.5;
									texelH = Main.BASE_TEXEL_H * 0.5;

									this.drawGeneric(-w + xBase, -h + yBase, w + xBase, -h + yBase, -w + xBase, h + yBase, w + xBase, h + yBase, emptyBarU,
										emptyBarV, scaledEmptyBarW, scaledEmptyBarH, texelW, texelH);

									var mpPerc = 1 / (player.mp / player.maxMP);
									var mpPercOffset = (1 - player.mp / player.maxMP) * mpBarW * RenderUtils.clipSpaceScaleX;
									w /= mpPerc;

									this.drawGeneric(-w
										+ xBase
										- mpPercOffset,
										-h
										+ yBase, w
										+ xBase
										- mpPercOffset,
										-h
										+ yBase,
										-w
										+ xBase
										- mpPercOffset,
										h
										+ yBase, w
										+ xBase
										- mpPercOffset, h
										+ yBase, mpBarU, mpBarV, scaledBarW / mpPerc, scaledBarH, texelW, texelH);

									yPos += 20;
								}
							}

							if (player.condition > 0) {
								var len = 0;
								for (i in 0...32)
									if (player.condition & (1 << i) != 0)
										len++;

								len >>= 1;
								var num_filled = 0;
								for (i in 0...32)
									if (player.condition & (1 << i) != 0) {
										var rect = ConditionEffect.effectRects[i];
										if (rect == null)
											continue;

										var scaledW: Float32 = rect.width / Main.ATLAS_WIDTH;
										var scaledH: Float32 = rect.height / Main.ATLAS_HEIGHT;
										var scaledU: Float32 = rect.x / Main.ATLAS_WIDTH;
										var scaledV: Float32 = rect.y / Main.ATLAS_HEIGHT;
										w = rect.width * RenderUtils.clipSpaceScaleX;
										h = rect.height * RenderUtils.clipSpaceScaleY;
										xBase = (screenX - (rect.width * len) / 2.0 + num_filled * (rect.width + Main.PADDING * 2 + 5)) * RenderUtils.clipSpaceScaleX;
										yBase = (screenY + yPos + (rect.height / 2.0 - Main.PADDING)) * RenderUtils.clipSpaceScaleY;
										texelW = Main.BASE_TEXEL_W * 0.5;
										texelH = Main.BASE_TEXEL_H * 0.5;

										this.drawGeneric(-w + xBase, -h + yBase, w + xBase, -h + yBase, -w + xBase, h + yBase, w + xBase, h + yBase, scaledU,
											scaledV, scaledW, scaledH, texelW, texelH);
										num_filled++;
									}
							}

							if (player.name != null && player.name != "") {
								if (player.nameTex == null) {
									player.nameText = new SimpleText(16, player.isFellowGuild ? Settings.FELLOW_GUILD_COLOR : Settings.DEFAULT_COLOR);
									player.nameText.setBold(true);
									player.nameText.text = player.name;
									player.nameText.updateMetrics();
									player.nameTex = new BitmapData(Std.int(player.nameText.width + 20), 64, true, 0);
									player.nameTex.draw(player.nameText, new Matrix(1, 0, 0, 1, 12, 0));
									player.nameTex.applyFilter(player.nameTex, player.nameTex.rect, new Point(0, 0), new GlowFilter(0, 1, 3, 3, 2, 1));
								}
								var textureData = TextureFactory.make(player.nameTex);
								this.rdSingle.push({
									cosX: textureData.width * RenderUtils.clipSpaceScaleX,
									sinX: 0,
									sinY: 0,
									cosY: textureData.height * RenderUtils.clipSpaceScaleY,
									x: screenX * RenderUtils.clipSpaceScaleX,
									y: (screenY - hBase + 30 + (sink - 1) * hBase / 3) * RenderUtils.clipSpaceScaleY,
									texelW: 0,
									texelH: 0,
									texture: textureData.texture
								});
							}
						}
					case "Projectile":
						{
							var proj: Projectile = cast obj;
							var screenX = proj.mapX * Camera.cos + proj.mapY * Camera.sin + Camera.csX;
							var screenY = proj.mapX * -Camera.sin + proj.mapY * Camera.cos + Camera.csY;

							var texW = proj.width * Main.ATLAS_WIDTH,
								texH = proj.height * Main.ATLAS_HEIGHT;

							final size = Camera.SIZE_MULT * proj.size;
							final w = size * texW;
							final h = size * texH;
							final yBase = (screenY - (h / 2 - size * Main.PADDING)) * RenderUtils.clipSpaceScaleY;
							final xBase = screenX * RenderUtils.clipSpaceScaleX;
							final texelW = Main.BASE_TEXEL_W * 2 / size;
							final texelH = Main.BASE_TEXEL_H * 2 / size;
							final rotation = proj.projProps.rotation;
							final angle = proj.getDirectionAngle(time) + proj.projProps.angleCorrection + (rotation == 0 ? 0 : time / rotation)
								- Camera.angleRad;
							final cosAngle = MathUtil.cos(angle);
							final sinAngle = MathUtil.sin(angle);
							final xScaledCos = cosAngle * w * RenderUtils.clipSpaceScaleX * 0.5;
							final xScaledSin = sinAngle * h * RenderUtils.clipSpaceScaleX * 0.5;
							final yScaledCos = cosAngle * w * RenderUtils.clipSpaceScaleY * 0.5;
							final yScaledSinInv = -sinAngle * h * RenderUtils.clipSpaceScaleY * 0.5;

							if (proj.projProps.lightColor != -1) {
								this.lightDataList[this.lightIdx++] = w * RenderUtils.clipSpaceScaleX * 0.5 * 8 * proj.projProps.lightRadius;
								this.lightDataList[this.lightIdx++] = h * RenderUtils.clipSpaceScaleY * 0.5 * 8 * proj.projProps.lightRadius;
								this.lightDataList[this.lightIdx++] = xBase;
								this.lightDataList[this.lightIdx++] = yBase;
								this.lightDataList[this.lightIdx++] = proj.projProps.lightColor;
								this.lightDataList[this.lightIdx++] = proj.projProps.lightIntensity;
							}

							this.drawGeneric(-xScaledCos
								+ xScaledSin
								+ xBase, yScaledSinInv
								+ -yScaledCos + yBase, xScaledCos
								+ xScaledSin
								+ xBase,
								-(yScaledSinInv + yScaledCos)
								+ yBase,
								-(xScaledCos + xScaledSin)
								+ xBase, yScaledSinInv
								+ yScaledCos
								+ yBase,
								xScaledCos
								+ -xScaledSin + xBase,
								-yScaledSinInv
								+ yScaledCos
								+ yBase, proj.uValue, proj.vValue, proj.width, proj.height,
								texelW, texelH);
						}
					case "Particle":
						{
							var screenX = obj.screenX = obj.mapX * Camera.cos + obj.mapY * Camera.sin + Camera.csX;
							var screenY = obj.screenYNoZ + obj.mapZ * -Camera.PX_PER_TILE;

							var texW = obj.width * Main.ATLAS_WIDTH,
								texH = obj.height * Main.ATLAS_HEIGHT;

							var size = Camera.SIZE_MULT * obj.size;
							var hBase = obj.hBase = size * texH;
							var rect: Rect = null;
							if (obj.animations != null)
								rect = obj.animations.getTexture(time);

							if (rect != null) {
								obj.uValue = rect.x / Main.ATLAS_WIDTH;
								obj.vValue = rect.y / Main.ATLAS_WIDTH;
								texW = rect.width;
								obj.width = texW / Main.ATLAS_WIDTH;
								texH = rect.height;
								obj.height = texH / Main.ATLAS_HEIGHT;
							}

							var flashStrength: Float32 = 0.0;
							if (obj.flashPeriodMs > 0) {
								if (obj.flashRepeats != -1 && time > obj.flashStartTime + obj.flashPeriodMs * obj.flashRepeats)
									obj.flashRepeats = obj.flashStartTime = obj.flashPeriodMs = obj.flashColor = 0;
								else
									flashStrength = MathUtil.sin((time - obj.flashStartTime) % obj.flashPeriodMs / obj.flashPeriodMs * MathUtil.PI) * 0.5;
							} else if (obj.flashRepeats == -1)
								flashStrength = 1; // more hackyness

							var w = size * texW * RenderUtils.clipSpaceScaleX * 0.5;
							var h = hBase * RenderUtils.clipSpaceScaleY * 0.5;
							var yBase = (screenY - (hBase / 2 - size * Main.PADDING)) * RenderUtils.clipSpaceScaleY;
							var xBase = screenX * RenderUtils.clipSpaceScaleX;
							var texelW: Float32 = Main.BASE_TEXEL_W * obj.outlineSize / size;
							var texelH: Float32 = Main.BASE_TEXEL_H * obj.outlineSize / size;

							this.drawGeneric(-w + xBase, -h + yBase, w + xBase, -h + yBase, -w + xBase, h + yBase, w + xBase, h + yBase, obj.uValue,
								obj.vValue, obj.width, obj.height, texelW, texelH, obj.glowColor, obj.flashColor, flashStrength, -2);
						}
					default:
						if (obj.objClass != "ParticleEffect") {
							var screenX = obj.screenX = obj.mapX * Camera.cos + obj.mapY * Camera.sin + Camera.csX;
							var screenY = obj.screenYNoZ + obj.mapZ * -Camera.PX_PER_TILE;

							var texW = obj.width * Main.ATLAS_WIDTH,
								texH = obj.height * Main.ATLAS_HEIGHT;

							var size = Camera.SIZE_MULT * obj.size;
							var hBase = obj.hBase = size * texH;

							if (obj.props.drawOnGround) {
								if (obj.curSquare != null)
									continue;

								final xScaledCos = Camera.xScaledCos;
								final yScaledCos = Camera.yScaledCos;
								final xScaledSin = Camera.xScaledSin;
								final yScaledSin = Camera.yScaledSin;
								final clipX = obj.curSquare.clipX;
								final clipY = obj.curSquare.clipY;

								this.drawGeneric(-xScaledCos
									- xScaledSin
									+ clipX, yScaledSin
									- yScaledCos
									+ clipY, xScaledCos
									- xScaledSin
									+ clipX,
									-yScaledSin
									- yScaledCos
									+ clipY,
									-xScaledCos
									+ xScaledSin
									+ clipX, yScaledSin
									+ yScaledCos
									+ clipY,
									xScaledCos
									+ xScaledSin
									+ clipX,
									-yScaledSin
									+ yScaledCos
									+ clipY, obj.uValue, obj.vValue, obj.width, obj.height);

								var isPortal = obj.objClass == "Portal";
								if ((obj.props.showName || isPortal) && obj.name != null && obj.name != "") {
									if (obj.nameTex == null) {
										obj.nameText = new SimpleText(16, 0xFFFFFF);
										obj.nameText.setBold(true);
										obj.nameText.text = obj.name;
										obj.nameText.updateMetrics();
										obj.nameTex = new BitmapData(Std.int(obj.nameText.width + 20), 64, true, 0);
										obj.nameTex.draw(obj.nameText, new Matrix(1, 0, 0, 1, 12, 0));
										obj.nameTex.applyFilter(obj.nameTex, obj.nameTex.rect, new Point(0, 0), new GlowFilter(0, 1, 3, 3, 2, 1));
									}
									var textureData = TextureFactory.make(obj.nameTex);
									this.rdSingle.push({
										cosX: textureData.width * RenderUtils.clipSpaceScaleX,
										sinX: 0,
										sinY: 0,
										cosY: textureData.height * RenderUtils.clipSpaceScaleY,
										x: clipX - 3 * RenderUtils.clipSpaceScaleX,
										y: clipY - hBase / 2 * RenderUtils.clipSpaceScaleY,
										texelW: 0,
										texelH: 0,
										texture: textureData.texture
									});
								}
							} else {
								var rect: Rect = null;
								var action = AnimatedChar.STAND;
								var p: Float32 = 0.0;
								if (obj.animatedChar != null) {
									if (time < obj.attackStart + GameObject.ATTACK_PERIOD) {
										if (!obj.props.dontFaceAttacks)
											obj.facing = obj.attackAngle;

										p = (time - obj.attackStart) % GameObject.ATTACK_PERIOD / GameObject.ATTACK_PERIOD;
										action = AnimatedChar.ATTACK;
									} else if (obj.moveVec.x != 0 || obj.moveVec.y != 0) {
										var walkPer = Std.int(0.5 / obj.moveVec.length);
										walkPer += 400 - walkPer % 400;
										if (obj.moveVec.x > GameObject.ZERO_LIMIT
											|| obj.moveVec.x < GameObject.NEGATIVE_ZERO_LIMIT
											|| obj.moveVec.y > GameObject.ZERO_LIMIT
											|| obj.moveVec.y < GameObject.NEGATIVE_ZERO_LIMIT) {
											obj.facing = Math.atan2(obj.moveVec.y, obj.moveVec.x);
											action = AnimatedChar.WALK;
										} else
											action = AnimatedChar.STAND;

										p = time % walkPer / walkPer;
									}

									rect = obj.animatedChar.rectFromFacing(obj.facing, action, p);
								} else if (obj.animations != null)
									rect = obj.animations.getTexture(time);

								if (rect != null) {
									obj.uValue = rect.x / Main.ATLAS_WIDTH;
									obj.vValue = rect.y / Main.ATLAS_WIDTH;
									texW = rect.width;
									obj.width = texW / Main.ATLAS_WIDTH;
									texH = rect.height;
									obj.height = texH / Main.ATLAS_HEIGHT;
								}

								var sink: Float32 = 1.0;
								if (obj.curSquare != null
									&& !(obj.flying || obj.curSquare.obj != null && obj.curSquare.obj.props.protectFromSink))
									sink += obj.curSquare.sink + obj.sinkLevel;

								var flashStrength: Float32 = 0.0;
								if (obj.flashPeriodMs > 0) {
									if (obj.flashRepeats != -1 && time > obj.flashStartTime + obj.flashPeriodMs * obj.flashRepeats)
										obj.flashRepeats = obj.flashStartTime = obj.flashPeriodMs = obj.flashColor = 0;
									else
										flashStrength = MathUtil.sin((time - obj.flashStartTime) % obj.flashPeriodMs / obj.flashPeriodMs * MathUtil.PI) * 0.5;
								}

								var w = size * texW * RenderUtils.clipSpaceScaleX * 0.5;
								var h = hBase * RenderUtils.clipSpaceScaleY * 0.5 / sink;
								var yBase = (screenY - (hBase / 2 - size * Main.PADDING)) * RenderUtils.clipSpaceScaleY;
								var xOffset: Float32 = 0.0;
								if (action == AnimatedChar.ATTACK && p >= 0.5) {
									var dir = obj.animatedChar.facingToDir(obj.facing);
									if (dir == AnimatedChar.LEFT)
										xOffset = -w / 2 + size * Main.PADDING * RenderUtils.clipSpaceScaleX * 0.5;
									else
										xOffset = w / 2 - size * Main.PADDING * RenderUtils.clipSpaceScaleX * 0.5;
								}
								var xBase = screenX * RenderUtils.clipSpaceScaleX + xOffset;
								var texelW: Float32 = Main.BASE_TEXEL_W * 2 / size;
								var texelH: Float32 = Main.BASE_TEXEL_H * 2 / size;
								var alphaMult: Float32 = ((obj.condition & ConditionEffect.INVISIBLE_BIT) != 0 ? 0.6 : obj.props.alphaMult);

								if (obj.props.lightColor != -1) {
									this.lightDataList[this.lightIdx++] = w * 8 * obj.props.lightRadius;
									this.lightDataList[this.lightIdx++] = h * 8 * obj.props.lightRadius;
									this.lightDataList[this.lightIdx++] = xBase;
									this.lightDataList[this.lightIdx++] = yBase;
									this.lightDataList[this.lightIdx++] = obj.props.lightColor;
									this.lightDataList[this.lightIdx++] = obj.props.lightIntensity;
								}

								this.drawGeneric(-w + xBase, -h + yBase, w + xBase, -h + yBase, -w + xBase, h + yBase, w + xBase, h + yBase, obj.uValue,
									obj.vValue, obj.width, obj.height / sink, texelW, texelH, obj.glowColor, obj.flashColor, flashStrength, alphaMult);

								var yPos: Int32 = 15 + (sink != 0 ? 5 : 0);
								if (obj.props == null || !obj.props.noMiniMap) {
									xBase = screenX * RenderUtils.clipSpaceScaleX;

									if (obj.hp > obj.maxHP)
										obj.maxHP = obj.hp;

									var scaledEmptyBarW: Float32 = emptyBarW / Main.ATLAS_WIDTH;
									var scaledEmptyBarH: Float32 = emptyBarH / Main.ATLAS_HEIGHT;
									if (obj.hp >= 0 && obj.hp < obj.maxHP) {
										var scaledBarW: Float32 = hpBarW / Main.ATLAS_WIDTH;
										var scaledBarH: Float32 = hpBarH / Main.ATLAS_HEIGHT;
										w = hpBarW * RenderUtils.clipSpaceScaleX;
										h = hpBarH * RenderUtils.clipSpaceScaleY;
										yBase = (screenY + yPos - (hpBarH / 2 - Main.PADDING)) * RenderUtils.clipSpaceScaleY;
										texelW = Main.BASE_TEXEL_W * 0.5;
										texelH = Main.BASE_TEXEL_H * 0.5;

										this.drawGeneric(-w + xBase, -h + yBase, w + xBase, -h + yBase, -w + xBase, h + yBase, w + xBase, h + yBase,
											emptyBarU, emptyBarV, scaledEmptyBarW, scaledEmptyBarH, texelW, texelH);

										var hpPerc = 1 / (obj.hp / obj.maxHP);
										var hpPercOffset = (1 - obj.hp / obj.maxHP) * hpBarW * RenderUtils.clipSpaceScaleX;
										w /= hpPerc;

										this.drawGeneric(-w
											+ xBase
											- hpPercOffset,
											-h
											+ yBase, w
											+ xBase
											- hpPercOffset,
											-h
											+ yBase,
											-w
											+ xBase
											- hpPercOffset, h
											+ yBase, w
											+ xBase
											- hpPercOffset, h
											+ yBase, hpBarU, hpBarV, scaledBarW / hpPerc,
											scaledBarH, texelW, texelH);

										yPos += 20;
									}
								}

								if (obj.condition > 0) {
									var len = 0;
									for (i in 0...32)
										if (obj.condition & (1 << i) != 0)
											len++;

									len >>= 1;
									var num_filled = 0;
									for (i in 0...32)
										if (obj.condition & (1 << i) != 0) {
											var rect = ConditionEffect.effectRects[i];
											if (rect == null)
												continue;

											var scaledW: Float32 = rect.width / Main.ATLAS_WIDTH;
											var scaledH: Float32 = rect.height / Main.ATLAS_HEIGHT;
											var scaledU: Float32 = rect.x / Main.ATLAS_WIDTH;
											var scaledV: Float32 = rect.y / Main.ATLAS_HEIGHT;
											w = rect.width * RenderUtils.clipSpaceScaleX;
											h = rect.height * RenderUtils.clipSpaceScaleY;
											xBase = (screenX - (rect.width * len) / 2.0 + num_filled * (rect.width + Main.PADDING * 2 + 5)) * RenderUtils.clipSpaceScaleX;
										yBase = (screenY + yPos + (rect.height / 2.0 - Main.PADDING)) * RenderUtils.clipSpaceScaleY;
											texelW = Main.BASE_TEXEL_W * 0.5;
											texelH = Main.BASE_TEXEL_H * 0.5;

											this.drawGeneric(-w + xBase, -h + yBase, w + xBase, -h + yBase, -w + xBase, h + yBase, w + xBase, h + yBase,
												scaledU, scaledV, scaledW, scaledH, texelW, texelH);
											num_filled++;
										}
								}

								var isPortal = obj.objClass == "Portal";
								if ((obj.props.showName || isPortal) && obj.name != null && obj.name != "") {
									if (obj.nameTex == null) {
										obj.nameText = new SimpleText(16, 0xFFFFFF);
										obj.nameText.setBold(true);
										obj.nameText.text = obj.name;
										obj.nameText.updateMetrics();
										obj.nameTex = new BitmapData(Std.int(obj.nameText.width + 20), 64, true, 0);
										obj.nameTex.draw(obj.nameText, new Matrix(1, 0, 0, 1, 12, 0));
										obj.nameTex.applyFilter(obj.nameTex, obj.nameTex.rect, new Point(0, 0), new GlowFilter(0, 1, 3, 3, 2, 1));
									}
									var textureData = TextureFactory.make(obj.nameTex);
									this.rdSingle.push({
										cosX: textureData.width * RenderUtils.clipSpaceScaleX,
										sinX: 0,
										sinY: 0,
										cosY: textureData.height * RenderUtils.clipSpaceScaleY,
										x: (screenX - 3) * RenderUtils.clipSpaceScaleX,
										y: (screenY - hBase + 30 + (sink - 1) * hBase / 3) * RenderUtils.clipSpaceScaleY,
										texelW: 0,
										texelH: 0,
										texture: textureData.texture
									});

									if (isPortal && Global.currentInteractiveTarget == obj.objectId) {
										if (obj.enterTex == null) {
											var enterText = new SimpleText(16, 0xFFFFFF);
											enterText.setBold(true);
											enterText.text = "Enter";
											enterText.updateMetrics();
											obj.enterTex = new BitmapData(Std.int(enterText.width + 20), 64, true, 0);
											obj.enterTex.draw(enterText, new Matrix(1, 0, 0, 1, 12, 0));
											obj.enterTex.applyFilter(obj.enterTex, obj.enterTex.rect, new Point(0, 0), new GlowFilter(0, 1, 3, 3, 2, 1));
										}

										var textureData = TextureFactory.make(obj.enterTex);
										this.rdSingle.push({
											cosX: textureData.width * RenderUtils.clipSpaceScaleX,
											sinX: 0,
											sinY: 0,
											cosY: textureData.height * RenderUtils.clipSpaceScaleY,
											x: (screenX + 8) * RenderUtils.clipSpaceScaleX,
											y: (screenY + 40) * RenderUtils.clipSpaceScaleY,
											texelW: 0,
											texelH: 0,
											texture: textureData.texture
										});
										if (obj.enterKeyTex == null)
											obj.enterKeyTex = AssetLibrary.getImageFromSet("keyIndicators", KeyCodeUtil.charCodeIconIndices[Settings.interact]);

										var textureData = TextureFactory.make(obj.enterKeyTex);
										this.rdSingle.push({
											cosX: (textureData.width >> 2) * RenderUtils.clipSpaceScaleX,
											sinX: 0,
											sinY: 0,
											cosY: (textureData.height >> 2) * RenderUtils.clipSpaceScaleY,
											x: (screenX - 22) * RenderUtils.clipSpaceScaleX,
											y: (screenY + 19) * RenderUtils.clipSpaceScaleY,
											texelW: 0,
											texelH: 0,
											texture: textureData.texture
										});
									}
								}
							}
						}
				}
			}
		}

		GL.bindVertexArray(this.objVAO);

		GL.bindBuffer(GL.ARRAY_BUFFER, this.objVBO);
		if (this.vertIdx > this.objVBOLen) {
			GL.bufferData(GL.ARRAY_BUFFER, this.vertIdx * 4, this.vertDataList, GL.DYNAMIC_DRAW);
			this.objVBOLen = this.vertIdx;
		} else
			GL.bufferSubData(GL.ARRAY_BUFFER, 0, this.vertIdx * 4, this.vertDataList);

		GL.enableVertexAttribArray(0);
		GL.vertexAttribPointer(0, 4, GL.FLOAT, false, 40, 0);
		GL.enableVertexAttribArray(1);
		GL.vertexAttribPointer(1, 2, GL.FLOAT, false, 40, 16);
		GL.enableVertexAttribArray(2);
		GL.vertexAttribPointer(2, 2, GL.FLOAT, false, 40, 24);
		GL.enableVertexAttribArray(3);
		GL.vertexAttribPointer(3, 1, GL.FLOAT, false, 40, 32);
		GL.enableVertexAttribArray(4);
		GL.vertexAttribPointer(4, 1, GL.FLOAT, false, 40, 36);

		GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, this.objIBO);
		if (this.indexIdx > this.objIBOLen) {
			GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, this.indexIdx * 4, this.indexDataList, GL.DYNAMIC_DRAW);
			this.objIBOLen = this.indexIdx;
		} else
			GL.bufferSubData(GL.ELEMENT_ARRAY_BUFFER, 0, this.indexIdx * 4, this.indexDataList);

		GL.drawElements(GL.TRIANGLES, this.indexIdx, GL.UNSIGNED_INT, 0);

		for (sb in this.speechBalloons) {
			if (sb.disposed || sb.go?.map == null)
				continue;

			var dt = time - sb.startTime;
			if (dt > sb.lifetime) {
				sb.disposed = true;
				continue;
			}

			var textureData: GLTextureData;
			switch (sb.sbType) {
				case SpeechBalloon.MESSAGE_BUBBLE:
					textureData = TextureFactory.make(tellBalloonTex);
				case SpeechBalloon.GUILD_BUBBLE:
					textureData = TextureFactory.make(guildBalloonTex);
				case SpeechBalloon.ENEMY_BUBBLE:
					textureData = TextureFactory.make(enemyBalloonTex);
				case SpeechBalloon.PARTY_BUBBLE:
					textureData = TextureFactory.make(partyBalloonTex);
				case SpeechBalloon.ADMIN_BUBBLE:
					textureData = TextureFactory.make(adminBalloonTex);
				default:
					textureData = TextureFactory.make(normalBalloonTex);
			}

			var alpha = 1.0;
			if (dt < 333)
				alpha = -(MathUtil.cos(dt / 333 * MathUtil.PI) - 1) / 2;
			else if (dt > sb.lifetime - 333)
				alpha = -(MathUtil.cos((1 - (dt - sb.lifetime + 333) / 333) * MathUtil.PI) - 1) / 2;

			this.rdSingle.push({
				cosX: (textureData.width << 2) * RenderUtils.clipSpaceScaleX,
				sinX: 0,
				sinY: 0,
				cosY: (textureData.height << 2) * RenderUtils.clipSpaceScaleY,
				x: (sb.go.screenX + 45) * RenderUtils.clipSpaceScaleX,
				y: (sb.go.screenYNoZ - sb.go.hBase - 40) * RenderUtils.clipSpaceScaleY,
				texelW: 0,
				texelH: 0,
				texture: textureData.texture,
				alpha: alpha
			});

			var textureData = TextureFactory.make(sb.textTex);
			this.rdSingle.push({
				cosX: textureData.width * RenderUtils.clipSpaceScaleX,
				sinX: 0,
				sinY: 0,
				cosY: textureData.height * RenderUtils.clipSpaceScaleY,
				x: (sb.go.screenX + 42) * RenderUtils.clipSpaceScaleX,
				y: (sb.go.screenYNoZ - sb.go.hBase - 33 - (sb.numLines * 6)) * RenderUtils.clipSpaceScaleY,
				texelW: 0,
				texelH: 0,
				texture: textureData.texture,
				alpha: alpha
			});
		}

		for (st in this.statusTexts) {
			if (st.disposed || st.go?.map == null)
				continue;

			var dt = time - st.startTime;
			if (dt > st.lifetime) {
				st.disposed = true;
				continue;
			}

			var frac = dt / st.lifetime;
			var scale = Math.min(1, Math.max(0.7, 1 - frac * 0.3 + 0.075));
			var textureData = TextureFactory.make(st.textTex);
			this.rdSingle.push({
				cosX: textureData.width * scale * RenderUtils.clipSpaceScaleX,
				sinX: 0,
				sinY: 0,
				cosY: textureData.height * scale * RenderUtils.clipSpaceScaleY,
				x: (st.go.screenX + st.xOffset) * RenderUtils.clipSpaceScaleX,
				y: (st.go.screenYNoZ + st.yOffset - st.go.hBase - frac * CharacterStatusText.MAX_DRIFT) * RenderUtils.clipSpaceScaleY,
				texelW: 0,
				texelH: 0,
				texture: textureData.texture,
				alpha: 1 - frac + 0.33
			});
		}

		i = 0;
		var rdsLen = this.rdSingle.length;
		if (rdsLen > 0) {
			RenderUtils.bindVertexBuffer(0, this.singleVBO);
			GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, this.singleIBO);
			GL.useProgram(this.singleProgram);
		}

		while (i < rdsLen) {
			var rd = this.rdSingle[i];
			GL.uniform4f(vertScaleUniformLoc, rd.cosX, rd.sinX, rd.sinY, rd.cosY);
			GL.uniform2f(vertPosUniformLoc, rd.x, rd.y);
			GL.uniform2f(texelSizeUniformLoc, rd.texelW, rd.texelH);
			GL.uniform1i(colorUniformLoc, -1);
			GL.uniform1f(alphaMultUniformLoc, rd.alpha);
			GL.bindTexture(GL.TEXTURE_2D, rd.texture);
			GL.drawElements(GL.TRIANGLES, 6, GL.UNSIGNED_SHORT, 0);
			i++;
		}

		if (this.bgLightColor != -1) {
			GL.uniform4f(vertScaleUniformLoc, Main.stageWidth, 0, 0, Main.stageHeight);
			GL.uniform2f(vertPosUniformLoc, -1, -1);
			GL.uniform2f(texelSizeUniformLoc, 0, 0);
			GL.uniform1i(colorUniformLoc, this.bgLightColor);
			GL.uniform1f(alphaMultUniformLoc, this.getLightIntensity(time));
			GL.bindTexture(GL.TEXTURE_2D, this.screenTex);
			GL.drawElements(GL.TRIANGLES, 6, GL.UNSIGNED_SHORT, 0);
		}

		var lightsLen = Math.floor(lightIdx / 6);
		if (lightsLen > 0) {
			i = this.count = this.vertIdx = this.indexIdx = 0;

			GL.blendFunc(GL.SRC_ALPHA, GL.ONE);
			GL.useProgram(this.lightProgram);
			GL.bindTexture(GL.TEXTURE_2D, this.lightTex);

			while (i < lightsLen) {
				if (i > 0 && i % 2800 == 0 && i != lightsLen - 1) {
					GL.bindVertexArray(this.lightVAO);

					GL.bindBuffer(GL.ARRAY_BUFFER, this.lightVBO);
					if (this.vertIdx > this.lightVBOLen) {
						GL.bufferData(GL.ARRAY_BUFFER, this.vertIdx * 4, vertDataList, GL.DYNAMIC_DRAW);
						this.lightVBOLen = this.vertIdx;
					} else
						GL.bufferSubData(GL.ARRAY_BUFFER, 0, this.vertIdx * 4, vertDataList);

					GL.enableVertexAttribArray(0);
					GL.vertexAttribPointer(0, 4, GL.FLOAT, false, 32, 0);
					GL.enableVertexAttribArray(1);
					GL.vertexAttribPointer(1, 3, GL.FLOAT, false, 32, 16);
					GL.enableVertexAttribArray(2);
					GL.vertexAttribPointer(2, 1, GL.FLOAT, false, 32, 28);

					GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, this.lightIBO);
					if (this.indexIdx > this.lightIBOLen) {
						GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, this.indexIdx * 4, this.indexDataList, GL.DYNAMIC_DRAW);
						this.lightIBOLen = this.indexIdx;
					} else
						GL.bufferSubData(GL.ELEMENT_ARRAY_BUFFER, 0, this.indexIdx * 4, this.indexDataList);

					GL.drawElements(GL.TRIANGLES, this.indexIdx, GL.UNSIGNED_INT, 0);

					this.count = this.vertIdx = this.indexIdx = 0;
				}

				var idx = this.count * 6;
				var width = this.lightDataList[idx];
				var height = this.lightDataList[idx + 1];
				var x = this.lightDataList[idx + 2];
				var y = this.lightDataList[idx + 3];
				var color = this.lightDataList[idx + 4];
				var intensity = this.lightDataList[idx + 5];

				var intColor = Std.int(color);
				var colorR: Float32 = ((intColor >> 16) & 0xFF) / 255.0;
				var colorG: Float32 = ((intColor >> 8) & 0xFF) / 255.0;
				var colorB: Float32 = (intColor & 0xFF) / 255.0;

				this.vertDataList[this.vertIdx++] = width * -0.5 + x;
				this.vertDataList[this.vertIdx++] = height * -0.5 + y;
				this.vertDataList[this.vertIdx++] = 0;
				this.vertDataList[this.vertIdx++] = 0;

				this.vertDataList[this.vertIdx++] = colorR;
				this.vertDataList[this.vertIdx++] = colorG;
				this.vertDataList[this.vertIdx++] = colorB;
				this.vertDataList[this.vertIdx++] = intensity;

				this.vertDataList[this.vertIdx++] = width * 0.5 + x;
				this.vertDataList[this.vertIdx++] = height * -0.5 + y;
				this.vertDataList[this.vertIdx++] = 1;
				this.vertDataList[this.vertIdx++] = 0;

				this.vertDataList[this.vertIdx++] = colorR;
				this.vertDataList[this.vertIdx++] = colorG;
				this.vertDataList[this.vertIdx++] = colorB;
				this.vertDataList[this.vertIdx++] = intensity;

				this.vertDataList[this.vertIdx++] = width * -0.5 + x;
				this.vertDataList[this.vertIdx++] = height * 0.5 + y;
				this.vertDataList[this.vertIdx++] = 0;
				this.vertDataList[this.vertIdx++] = 1;

				this.vertDataList[this.vertIdx++] = colorR;
				this.vertDataList[this.vertIdx++] = colorG;
				this.vertDataList[this.vertIdx++] = colorB;
				this.vertDataList[this.vertIdx++] = intensity;

				this.vertDataList[this.vertIdx++] = width * 0.5 + x;
				this.vertDataList[this.vertIdx++] = height * 0.5 + y;
				this.vertDataList[this.vertIdx++] = 1;
				this.vertDataList[this.vertIdx++] = 1;

				this.vertDataList[this.vertIdx++] = colorR;
				this.vertDataList[this.vertIdx++] = colorG;
				this.vertDataList[this.vertIdx++] = colorB;
				this.vertDataList[this.vertIdx++] = intensity;

				final i4 = i * 4;
				this.indexDataList[this.indexIdx++] = i4;
				this.indexDataList[this.indexIdx++] = 1 + i4;
				this.indexDataList[this.indexIdx++] = 2 + i4;
				this.indexDataList[this.indexIdx++] = 2 + i4;
				this.indexDataList[this.indexIdx++] = 1 + i4;
				this.indexDataList[this.indexIdx++] = 3 + i4;
				i++;
				this.count++;
			}

			GL.bindVertexArray(this.lightVAO);

			GL.bindBuffer(GL.ARRAY_BUFFER, this.lightVBO);
			if (this.vertIdx > this.lightVBOLen) {
				GL.bufferData(GL.ARRAY_BUFFER, this.vertIdx * 4, this.vertDataList, GL.DYNAMIC_DRAW);
				this.lightVBOLen = this.vertIdx;
			} else
				GL.bufferSubData(GL.ARRAY_BUFFER, 0, this.vertIdx * 4, this.vertDataList);

			GL.enableVertexAttribArray(0);
			GL.vertexAttribPointer(0, 4, GL.FLOAT, false, 32, 0);
			GL.enableVertexAttribArray(1);
			GL.vertexAttribPointer(1, 3, GL.FLOAT, false, 32, 16);
			GL.enableVertexAttribArray(2);
			GL.vertexAttribPointer(2, 1, GL.FLOAT, false, 32, 28);

			GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, this.lightIBO);
			if (this.indexIdx > this.lightIBOLen) {
				GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, this.indexIdx * 4, this.indexDataList, GL.DYNAMIC_DRAW);
				this.lightIBOLen = this.indexIdx;
			} else
				GL.bufferSubData(GL.ELEMENT_ARRAY_BUFFER, 0, this.indexIdx * 4, this.indexDataList);

			GL.drawElements(GL.TRIANGLES, this.indexIdx, GL.UNSIGNED_INT, 0);
		}

		this.c3d.present();
	}
}
