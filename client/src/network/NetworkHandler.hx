package network;

import account.Account;
import assets.CharacterFactory;
import classes.model.CharacterSkin;
import classes.model.CharacterSkinState;
import constants.ActivationType;
import constants.ItemConstants;
import game.events.GuildResultEvent;
import haxe.Exception;
import lime.system.System;
import map.Camera;
import map.CharacterStatusText;
import map.SpeechBalloon;
import objects.GameObject;
import objects.ObjectLibrary;
import objects.Player;
import objects.Projectile;
import objects.particles.AOEEffect;
import objects.particles.FlowEffect;
import objects.particles.HealEffect;
import objects.particles.LineEffect;
import objects.particles.NovaEffect;
import objects.particles.RingEffect;
import objects.particles.StreamEffect;
import objects.particles.TeleportEffect;
import objects.particles.ThrowEffect;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.events.SecurityErrorEvent;
import openfl.net.Socket;
import openfl.utils.ByteArray;
import openfl.utils.Endian;
import servers.Server;
import sound.SoundEffectLibrary;
import ui.dialogs.Dialog;
import util.NativeTypes;
import util.Settings;

using util.Utils.ArrayUtils;

enum abstract C2SPacketId(UInt8) from UInt8 to UInt8 {
	final PlayerShoot = 0;
	final Move = 1;
	final PlayerText = 2;
	final UpdateAck = 3;
	final InvSwap = 4;
	final UseItem = 5;
	final Hello = 6;
	final InvDrop = 7;
	final Pong = 8;
	final Teleport = 9;
	final UsePortal = 10;
	final Buy = 11;
	final GroundDamage = 12;
	final PlayerHit = 13;
	final EnemyHit = 14;
	final AoeAck = 15;
	final ShootAck = 16;
	final OtherHit = 17;
	final SquareHit = 18;
	final GotoAck = 19;
	final EditAccountList = 20;
	final CreateGuild = 21;
	final GuildRemove = 22;
	final GuildInvite = 23;
	final RequestTrade = 24;
	final ChangeTrade = 25;
	final AcceptTrade = 26;
	final CancelTrade = 27;
	final Escape = 28;
	final JoinGuild = 29;
	final ChangeGuildRank = 30;
	final Reskin = 31;
	final MapHello = 32;
}

enum abstract S2CPacketId(UInt8) from UInt8 to UInt8 {
	final CreateSuccess = 0;
	final Text = 1;
	final ServerPlayerShoot = 2;
	final Damage = 3;
	final Update = 4;
	final Notification = 5;
	final NewTick = 6;
	final ShowEffect = 7;
	final Goto = 8;
	final InvResult = 9;
	final Ping = 10;
	final MapInfo = 11;
	final Death = 12;
	final BuyResult = 13;
	final Aoe = 14;
	final AccountList = 15;
	final QuestObjId = 16;
	final GuildResult = 17;
	final AllyShoot = 18;
	final EnemyShoot = 19;
	final TradeRequested = 20;
	final TradeStart = 21;
	final TradeChanged = 22;
	final TradeDone = 23;
	final TradeAccepted = 24;
	final InvitedToGuild = 25;
	final PlaySound = 26;
	final Failure = 27;
}

enum abstract BuyResultType(UInt8) from UInt8 to UInt8 {
	final Success = 0;
	final OpenDialog = 1;
}

enum abstract FailureType(UInt8) from UInt8 to UInt8 {
	final MessageNoDisconnect = -1;
	final MessageDisconnect = 0;
	final IncorrectVersion = 1;
	final ForceCloseGame = 2;
	final InvalidTeleportTarget = 3;
}

enum abstract ShowEffectType(UInt8) from UInt8 to UInt8 {
	final None = 0;
	final Heal = 1;
	final Teleport = 2;
	final Stream = 3;
	final Throw = 4;
	final Nova = 5;
	final Line = 7;
	final Burst = 8;
	final Flow = 9;
	final Ring = 10;
	final Jitter = 14;
	final Flash = 15;
	final ThrowProjectile = 16;
}

enum abstract TradeDone(UInt8) from UInt8 to UInt8 {
	final Success = 0;
	final Cancel = 1;
}

enum abstract StatType(UInt8) from UInt8 to UInt8 {
	final HP = 0;
	final Size = 1;
	final MP = 2;
	final Inv0 = 3;
	final Inv1 = 4;
	final Inv2 = 5;
	final Inv3 = 6;
	final Inv4 = 7;
	final Inv5 = 8;
	final Inv6 = 9;
	final Inv7 = 10;
	final Inv8 = 11;
	final Inv9 = 12;
	final Inv10 = 13;
	final Inv11 = 14;
	final Inv12 = 15;
	final Inv13 = 16;
	final Inv14 = 17;
	final Inv15 = 18;
	final Inv16 = 19;
	final Inv17 = 20;
	final Inv18 = 21;
	final Inv19 = 22;
	final Inv20 = 23;
	final Inv21 = 24;
	final Name = 25;
	final MerchType = 26;
	final MerchPrice = 27;
	final MerchCount = 28;
	final Gems = 29;
	final Gold = 30;
	final Crowns = 31;
	final OwnerAccountId = 32;
	final MaxHP = 33;
	final MaxMP = 34;
	final Strength = 35;
	final Defense = 36;
	final Speed = 37;
	final Stamina = 38;
	final Wit = 39;
	final Resistance = 40;
	final Intelligence = 41;
	final Penetration = 42;
	final Piercing = 43;
	final Haste = 44;
	final Tenacity = 45;
	final HPBonus = 46;
	final MPBonus = 47;
	final StrengthBonus = 48;
	final DefenseBonus = 49;
	final SpeedBonus = 50;
	final StaminaBonus = 51;
	final WitBonus = 52;
	final ResistanceBonus = 53;
	final IntelligenceBonus = 54;
	final PenetrationBonus = 55;
	final PiercingBonus = 56;
	final HasteBonus = 57;
	final TenacityBonus = 58;
	final Condition = 59;
	final Texture1 = 60;
	final Texture2 = 61;
	final SellablePrice = 62;
	final PortalUsable = 63;
	final AccountId = 64;
	final Level = 65;
	final DamageMultiplier = 66;
	final HitMultiplier = 67;
	final Glow = 68;
	final AltTextureIndex = 69;
	final Guild = 70;
	final GuildRank = 71;
	final Texture = 72;
}

@:structInit class TradeItem {
	public var item = 0;
	public var slotType = 0;
	public var tradeable = false;
	public var included = false;
}

class NetworkHandler {
	private static var socket = new Socket();

	public static var server: Server;
	public static var createCharacter = false;
	public static var charId = 0;
	public static var lastTickId: Int = -1;
	public static var fmMap: ByteArray;

	private static var playerId: Int = -1;
	private static var player: Player;
	private static var outgoingData: ByteArray;

	private static var readLen = 65535;

	public static function init() {
		outgoingData = new ByteArray();

		socket.addEventListener(Event.CONNECT, onConnect);
		socket.addEventListener(Event.CLOSE, onClose);
		socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
		socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
		socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
		socket.endian = Endian.LITTLE_ENDIAN;
	}

	public static function reset(newServer: Server, newCreateCharacter: Bool, newCharId: Int, newFmMap: ByteArray) {
		server = newServer;
		createCharacter = newCreateCharacter;
		charId = newCharId;
		fmMap = newFmMap;
		readLen = 65535;
	}

	// todo figure out how to stop server.address and server.port from being null
	public static function connect() {
		Global.gameSprite?.disconnect();
		socket.connect(server.address, server.port);
	}

	public static function disconnect() {
		try {
			socket.close();
		} catch (e) {}

		Global.gameSprite?.close();
		Global.gameSprite = null;
	}

	public static function sendPacket(packetId: Int) {
		if (socket == null || !socket.connected)
			return;

		try {
			#if log_packets
			trace('Sending $packetId, size: ${outgoingData.length}');
			#end
			if (outgoingData == null || outgoingData.length <= 0) {
				socket.writeByte(packetId);
				socket.flush();
				return;
			}

			outgoingData.position = 0;
			socket.writeByte(packetId);
			socket.writeBytes(outgoingData);
			socket.flush();
			outgoingData.clear();
		} catch (e: Exception) {
			Global.gameSprite?.textBox.addText('Socket Write Error: $e', 0xFF0000);
			trace('Socket Write Error: $e, stack trace: ${e.stack}');
		}
	}

	private static function onConnect(_: Event) {
		Global.gameSprite.textBox.addText("Connected!", 0x0000FF);

		if (fmMap == null || fmMap.length == 0) {
			outgoingData.writeUTF(Settings.BUILD_VERSION);
			outgoingData.writeInt(-2);
			outgoingData.writeUTF(Account.email);
			outgoingData.writeUTF(Account.password);
			outgoingData.writeShort(charId);
			outgoingData.writeBoolean(createCharacter);
			if (createCharacter) {
				var charClass = Global.classModel.getSelected();
				outgoingData.writeShort(charClass.id);
				outgoingData.writeShort(0); // todo skin
			}

			sendPacket(C2SPacketId.Hello);

			#if log_packets
			trace(Global.gameSprite.lastUpdate,
				"Hello: buildVer="
				+ Settings.BUILD_VERSION
				+ ", gameId="
				+ gameId
				+ ", email="
				+ Account.email
				+ ", pwd="
				+ Account.password
				+ ", charId="
				+ charId);
			#end
		} else {
			outgoingData.writeUTF(Settings.BUILD_VERSION);
			outgoingData.writeUTF(Account.email);
			outgoingData.writeUTF(Account.password);
			outgoingData.writeShort(charId);
			outgoingData.writeShort(fmMap.length);
			outgoingData.writeBytes(fmMap);

			sendPacket(C2SPacketId.MapHello);

			#if log_packets
			trace(Global.gameSprite.lastUpdate,
				"MapHello: buildVer="
				+ Settings.BUILD_VERSION
				+ ", email="
				+ Account.email
				+ ", pwd="
				+ Account.password
				+ ", charId="
				+ charId);
			#end
		}
	}

	private static function onClose(_: Event) {
		disconnect();
	}

	private static function onIOError(e: IOErrorEvent) {
		Global.gameSprite?.textBox.addText('Socket IO Error: ${e.text}', 0xFF0000);
		disconnect();
	}

	private static function onSecurityError(e: SecurityErrorEvent) {
		Global.gameSprite?.textBox.addText('Socket Security Error: ${e.text}', 0xFF0000);
		disconnect();
	}

	private static function onSocketData(_: ProgressEvent = null) {
		try {
			while (socket != null && socket.connected) {
				if (socket.bytesAvailable < 2)
					break;

				if (readLen == 65535)
					readLen = socket.readUnsignedShort();

				if (readLen != 65535 && readLen > socket.bytesAvailable)
					break;

				var data = new ByteArray();
				socket.readBytes(data, 0, readLen);

				readLen = 65535;

				var packetId: S2CPacketId = data.readUnsignedByte();
				#if log_packets
				trace('Receiving $packetId, left to read: ${socket.bytesAvailable}');
				#end

				switch (packetId) {
					case AllyShoot:
						handleAllyShoot(data);
					case AccountList:
						handleAccountList(data);
					case Aoe:
						handleAoe(data);
					case BuyResult:
						handleBuyResult(data);
					case CreateSuccess:
						handleCreateSuccess(data);
					case Damage:
						handleDamage(data);
					case Death:
						handleDeath(data);
					case EnemyShoot:
						handleEnemyShoot(data);
					case Failure:
						handleFailure(data);
					case Goto:
						handleGoto(data);
					case GuildResult:
						handleGuildResult(data);
					case InvitedToGuild:
						handleInvitedToGuild(data);
					case InvResult:
						handleInvResult(data);
					case MapInfo:
						handleMapInfo(data);
					case NewTick:
						handleNewTick(data);
					case Notification:
						handleNotification(data);
					case Ping:
						handlePing(data);
					case PlaySound:
						handlePlaySound(data);
					case QuestObjId:
						handleQuestObjId(data);
					case ServerPlayerShoot:
						handleServerPlayerShoot(data);
					case ShowEffect:
						handleShowEffect(data);
					case Text:
						handleText(data);
					case TradeAccepted:
						handleTradeAccepted(data);
					case TradeChanged:
						handleTradeChanged(data);
					case TradeDone:
						handleTradeDone(data);
					case TradeRequested:
						handleTradeRequested(data);
					case TradeStart:
						handleTradeStart(data);
					case Update:
						handleUpdate(data);
				}
			}
		} catch (e: Exception) {
			Global.gameSprite?.textBox.addText('Socket Read Error: $e', 0xFF0000);
			trace('Socket Read Error: $e, stack trace: ${e.stack}');
			disconnect();
		}
	}

	private static function handleAllyShoot(data: ByteArray) {
		var bulletId = data.readByte();
		var ownerId = data.readInt();
		var containerType = data.readUnsignedShort();
		var angle = data.readFloat();

		var owner = Global.gameSprite.map.getGameObject(ownerId);
		if (owner == null || owner.dead)
			return;

		var proj = Global.projPool.get();
		proj.reset(containerType, 0, ownerId, bulletId, angle, Global.gameSprite.lastFixedUpdate);
		Global.gameSprite.map.addGameObject(cast proj, owner.mapX, owner.mapY);
		owner.setAttack(containerType, angle);
	}

	private static function handleAccountList(data: ByteArray) {
		var listId = data.readInt();
		var ids = new Array<Int>();
		var num: Int = data.readShort();
		for (i in 0...num)
			ids.push(data.readInt());

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "AccountList: listId=" + listId + ", ids=" + ids);
		#end

		/*if (listId == 0)
				Global.gameSprite.map.party.setStars(ids);
			if (listId == 1)
				Global.gameSprite.map.party.setIgnores(ids); */
	}

	private static function handleAoe(data: ByteArray) {
		var x = data.readFloat();
		var y = data.readFloat();
		var radius = data.readFloat();
		var damage = data.readUnsignedShort();
		var effect = data.readUnsignedByte();
		var duration = data.readFloat();
		var origType = data.readUnsignedShort();
		var color = data.readUnsignedInt();

		#if log_packets
		trace(Global.gameSprite.lastUpdate,
			"Aoe: x="
			+ x
			+ ", y="
			+ y
			+ ", radius="
			+ radius
			+ ", damage="
			+ damage
			+ ", effect="
			+ effect
			+ ", duration="
			+ duration
			+ ", origType="
			+ origType
			+ ", color="
			+ color);
		#end

		var d = 0;
		var effects: Array<Int32> = null;
		if (Global.gameSprite.map.player == null) {
			aoeAck(Global.gameSprite.lastFixedUpdate, 0, 0);
			return;
		}

		Global.gameSprite.map.addGameObject(new AOEEffect(x, y, radius, color), x, y);
		var hit = Global.gameSprite.map.player.distTo(x, y) <= radius;
		if (hit) {
			d = Std.int(GameObject.physicalDamage(damage, Global.gameSprite.map.player.defense,
				Global.gameSprite.map.player.condition) * Global.gameSprite.map.player.hitMult);
			effects = null;
			if (effect != 0) {
				effects = new Array<Int32>();
				effects.push(effect);
			}

			Global.gameSprite.map.player.damage(origType, d, effects, false, null);
		}

		aoeAck(Global.gameSprite.lastFixedUpdate, Global.gameSprite.map.player.mapX, Global.gameSprite.map.player.mapY);
	}

	private static function handleBuyResult(data: ByteArray) {
		var result: BuyResultType = data.readInt();
		var resultStr = data.readUTF();

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "BuyResult: result=" + result + ", resultStr=" + resultStr);
		#end

		switch (result) {
			case OpenDialog:
				Global.layers.dialogs.openDialog(new Dialog("Purchase Error", resultStr, "Close", null));
			default:
				Global.gameSprite.textBox.addText(resultStr, result == Success ? 0x0000FF : 0xFF0000);
		}
	}

	private static function handleCreateSuccess(data: ByteArray) {
		playerId = data.readInt();
		charId = data.readInt();

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "CreateSuccess: playerId=" + playerId + ", charId=" + charId);
		#end

		Global.gameSprite.initialize();
		createCharacter = false;
	}

	private static function handleDamage(data: ByteArray) {
		var targetId = data.readInt();
		var effects = new Array<Int32>();
		var effBitMask = data.readUnsignedInt();
		for (i in 0...31)
			if (effBitMask & (1 << i) != 0)
				effects.push(i);

		var damageAmount = data.readUnsignedShort();
		var kill = data.readBoolean();
		var bulletId = data.readUnsignedByte();
		var objectId = data.readInt();

		#if log_packets
		trace(Global.gameSprite.lastUpdate,
			"Damage: targetId="
			+ targetId
			+ ", effects="
			+ effects
			+ ", damageAmount="
			+ damageAmount
			+ ", kill="
			+ kill
			+ ", bulletId="
			+ bulletId
			+ ", objectId="
			+ objectId);
		#end

		var map = Global.gameSprite.map;
		var proj: Projectile = null;
		if (objectId >= 0 && bulletId > 0) {
			var projId = Projectile.findObjId(objectId, bulletId);
			proj = cast map.getGameObject(projId);
			if (proj != null && !proj.projProps.multiHit)
				map.removeGameObject(projId);
		}

		var go = map.getGameObject(targetId);
		if (go != null)
			go.damage(-1, damageAmount, effects, kill, proj);
	}

	private static function handleDeath(data: ByteArray) {
		// todo...
		var accountId = data.readInt();
		var charId = data.readInt();
		var killedBy = data.readUTF();

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "Death: accountId=" + accountId + ", charId=" + charId + ", killedBy=" + killedBy);
		#end

		disconnect();
	}

	private static function handleEnemyShoot(data: ByteArray) {
		var bulletId = data.readUnsignedByte();
		var ownerId = data.readInt();
		var bulletType = data.readUnsignedByte();
		var startX = data.readFloat();
		var startY = data.readFloat();
		var angle = data.readFloat();
		var damage = data.readShort();
		var magicDamage = data.readShort();
		var trueDamage = data.readShort();
		var numShots = data.readUnsignedByte();
		var angleInc = data.readFloat();

		#if log_packets
		trace(Global.gameSprite.lastUpdate,
			"EnemyShoot: bulletId="
			+ bulletId
			+ ", ownerId="
			+ ownerId
			+ ", bulletType="
			+ bulletType
			+ ", startX="
			+ startX
			+ ", startY="
			+ startY
			+ ", angle="
			+ angle
			+ ", damage="
			+ damage
			+ ", numShots="
			+ numShots
			+ ", angleInc="
			+ angleInc);
		#end

		var owner: GameObject = Global.gameSprite.map.getGameObject(ownerId);
		if (owner == null || owner.dead) {
			shootAck(-1);
			return;
		}

		for (i in 0...numShots) {
			var proj = Global.projPool.get();
			proj.reset(owner.objectType, bulletType, ownerId, (bulletId + i) % 256, angle, Global.gameSprite.lastFixedUpdate);
			angle += angleInc;
			proj.setDamages(damage, magicDamage, trueDamage);
			Global.gameSprite.map.addGameObject(cast proj, startX, startY);
		}

		shootAck(Global.gameSprite.lastFixedUpdate);
		owner.setAttack(owner.objectType, angle + angleInc * ((numShots - 1) / 2));
	}

	private static function handleFailure(data: ByteArray) {
		var errorId: FailureType = data.readInt();
		var errorDescription = data.readUTF();

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "Failure: errorId=" + errorId + ", errorDesc=" + errorDescription);
		#end

		switch (errorId) {
			case IncorrectVersion:
				disconnect();

				var dialog: Dialog = new Dialog("Client version: " + Settings.BUILD_VERSION + "\nServer version: " + errorDescription, "Client Update Needed",
					"Ok", null);
				dialog.addEventListener(Dialog.BUTTON1_EVENT, function(event: Event) {
					var dialog: Dialog = cast(event.currentTarget, Dialog);
					dialog.parent.removeChild(dialog);
				});
				Global.layers.dialogs.openDialog(dialog);
			case ForceCloseGame | MessageDisconnect:
				disconnect();

				var dialog: Dialog = new Dialog(errorDescription, "Connection error", "Ok", null);
				dialog.addEventListener(Dialog.BUTTON1_EVENT, function(event: Event) {
					var dialog: Dialog = cast(event.currentTarget, Dialog);
					dialog.parent.removeChild(dialog);
				});
				Global.layers.dialogs.openDialog(dialog);
			case InvalidTeleportTarget:
				Global.gameSprite.textBox.addText(errorDescription, 0xFF0000);
				player.nextTeleportAt = 0;
			case MessageNoDisconnect:
				Global.gameSprite.textBox.addText(errorDescription, 0xFF0000);
			default:
				disconnect();

				var dialog: Dialog = new Dialog(errorDescription, "Connection error", "Ok", null);
				dialog.addEventListener(Dialog.BUTTON1_EVENT, function(event: Event) {
					var dialog: Dialog = cast(event.currentTarget, Dialog);
					dialog.parent.removeChild(dialog);
				});
				Global.layers.dialogs.openDialog(dialog);
		}
	}

	private static function handleGoto(data: ByteArray) {
		var objId = data.readInt();
		var x = data.readFloat();
		var y = data.readFloat();

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "Goto: objId=" + objId + ", x=" + x + ", y=" + y);
		#end

		var player = Global.gameSprite.map.getGameObject(objId);
		if (player == null)
			return;

		player.onGoto(x, y, Global.gameSprite.lastFixedUpdate);

		gotoAck(Global.gameSprite.lastFixedUpdate);
	}

	private static function handleGuildResult(data: ByteArray) {
		var success = data.readBoolean();
		var errorText = data.readUTF();

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "GuildResult: success=" + success + ", errorText=" + errorText);
		#end

		Global.gameSprite.textBox.addText(errorText, 0xFF0000);
		Global.gameSprite.dispatchEvent(new GuildResultEvent(success, errorText));
	}

	private static function handleInvitedToGuild(data: ByteArray) {
		var name = data.readUTF();
		var guildName = data.readUTF();

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "InvitedToGuild: name=" + name + ", guildName=" + guildName);
		#end

		// Global.gameSprite.interactPanel.setOverride(new GuildInvitePanel(Global.gameSprite, name, guildName));
		Global.gameSprite.textBox.addText("You have been invited by " + name + " to join the guild " + guildName + ".\n  If you wish to join type \"/join "
			+ guildName + "\"", 0x0000FF);
	}

	private static function handleInvResult(data: ByteArray) {
		var result = data.readInt();

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "InvResult: result=" + result);
		#end

		if (result != 0)
			SoundEffectLibrary.play("error");
	}

	private static function handleMapInfo(data: ByteArray) {
		var width = data.readInt();
		var height = data.readInt();
		var name = data.readUTF();
		var bgLightColor = data.readInt();
		var bgLightIntensity = data.readFloat();
		var allowPlayerTeleport = data.readBoolean();
		var usesDayNightCycle = data.readBoolean();
		var dayLightIntensity = -1.0,
			nightLightIntensity = -1.0,
			serverTimeOffset = 0;
		if (usesDayNightCycle) {
			dayLightIntensity = data.readFloat();
			nightLightIntensity = data.readFloat();
			serverTimeOffset = data.readInt() - System.getTimer();
		}

		Global.gameSprite.map.setProps(width, height, name, allowPlayerTeleport, bgLightColor, bgLightIntensity, dayLightIntensity, nightLightIntensity,
			serverTimeOffset);

		Camera.isJittering = false;
		Camera.jitter = 0.0;

		#if log_packets
		trace(Global.gameSprite.lastUpdate,
			"MapInfo: width="
			+ width
			+ ", height="
			+ height
			+ ", name="
			+ name
			+ ", bgLightColor="
			+ bgLightColor
			+ ", bgLightIntensity="
			+ bgLightIntensity
			+ ", allowPlayerTeleport="
			+ allowPlayerTeleport
			+ ", usesDayNightCycle="
			+ usesDayNightCycle
			+ ", dayLightIntensity="
			+ dayLightIntensity
			+ ", nightLightIntensity="
			+ nightLightIntensity
			+ ", serverTimeOffset="
			+ serverTimeOffset);
		#end
	}

	private static function handleNewTick(data: ByteArray) {
		if (Global.gameSprite == null)
			return;

		var tickId = data.readUnsignedByte();
		var tickTime = Std.int(1000 / data.readUnsignedByte());
		var len = data.readShort();
		for (i in 0...len) {
			var objId = data.readInt();
			var x = data.readFloat();
			var y = data.readFloat();

			var map = Global.gameSprite.map;
			var go = map.getGameObject(objId);
			if (go != null) {
				if (tickTime != 0 && objId != playerId)
					go.onTickPos(x, y, tickTime, tickId);
				for (j in 0...data.readShort())
					parseStat(go, data.readUnsignedByte(), data);

				#if log_packets
				trace(Global.gameSprite.lastUpdate, "NewTick");
				#end
				move(tickId, player);
				lastTickId = tickId;
				continue;
			}

			trace('Could not find NewTick GameObject: objId=$objId, x=$x, y=$y');
			for (j in 0...data.readShort())
				parseStat(null, data.readUnsignedByte(), data);
		}

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "NewTick");
		#end

		move(tickId, player);

		lastTickId = tickId;
	}

	private static function handleNotification(data: ByteArray) {
		var objectId = data.readInt();
		var text = data.readUTF();
		var color = data.readUnsignedInt();
		#if log_packets
		trace(Global.gameSprite.lastUpdate, "Notification: objId=" + objectId + ", text=" + text + ", color=" + color);
		#end

		var go = Global.gameSprite.map.getGameObject(objectId);
		if (go != null)
			Global.gameSprite.map.addStatusText(new CharacterStatusText(go, text, color, 2000));
		else {
			var p = Global.gameSprite.map.getGameObject(objectId);
			if (p != null) {
				Global.gameSprite.map.addStatusText(new CharacterStatusText(p, text, color, 2000));
				if (p == player && text == "Quest Complete!")
					Global.gameSprite.map.quest.completed();
			}
		}
	}

	private static function handlePing(data: ByteArray) {
		var serial = data.readInt();

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "Ping: serial=" + serial);
		#end

		pong(serial, System.getTimer());
	}

	private static function handlePlaySound(data: ByteArray) {
		var ownerId = data.readInt();
		var soundId = data.readUnsignedByte();
		#if log_packets
		trace(Global.gameSprite.lastUpdate, "PlaySound: ownerId=" + ownerId + ", soundId=" + soundId);
		#end

		var obj = Global.gameSprite.map.getGameObject(ownerId);
		if (obj != null)
			obj.playSound(soundId);
	}

	private static function handleQuestObjId(data: ByteArray) {
		var objId = data.readInt();

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "QuestObjId: objId=" + objId);
		#end

		Global.gameSprite.map.quest.setObject(objId);
	}

	private static function handleServerPlayerShoot(data: ByteArray) {
		var bulletId = data.readUnsignedByte();
		var ownerId = data.readInt();
		var containerType = data.readShort();
		var startX = data.readFloat();
		var startY = data.readFloat();
		var angle = data.readFloat();
		var damage = data.readShort();

		#if log_packets
		trace(Global.gameSprite.lastUpdate,
			"ServerPlayerShoot: bulletId="
			+ bulletId
			+ ", ownerId="
			+ ownerId
			+ ", containerType="
			+ containerType
			+ ", startX="
			+ startX
			+ ", startY="
			+ startY
			+ ", angle="
			+ angle
			+ ", damage="
			+ damage);
		#end

		var needsAck: Bool = ownerId == playerId;
		var owner = Global.gameSprite.map.getGameObject(ownerId);
		if (owner == null || owner.dead) {
			if (needsAck)
				shootAck(-1);
			return;
		}

		var proj = Global.projPool.get();
		proj.reset(containerType, 0, ownerId, bulletId, angle, Global.gameSprite.lastFixedUpdate);
		proj.setDamages(damage, 0, 0);
		Global.gameSprite.map.addGameObject(cast proj, startX, startY);
		if (needsAck)
			shootAck(Global.gameSprite.lastFixedUpdate);
	}

	private static function handleShowEffect(data: ByteArray) {
		var effectType: ShowEffectType = data.readUnsignedByte();
		var targetObjectId = data.readInt();
		var x1 = data.readFloat();
		var y1 = data.readFloat();
		var x2 = data.readFloat();
		var y2 = data.readFloat();
		var color = data.readUnsignedInt();

		#if log_packets
		trace(Global.gameSprite.lastUpdate,
			"ShowEffect: effectType="
			+ effectType
			+ ", targetObjectId="
			+ targetObjectId
			+ ", x1="
			+ x1
			+ ", y1="
			+ y1
			+ ", x2="
			+ x2
			+ ", y2="
			+ y2
			+ ", color="
			+ color);
		#end

		var map = Global.gameSprite.map;
		switch (effectType) {
			case Heal:
				var go = map.getGameObject(targetObjectId);
				if (go == null)
					return;

				map.addGameObject(new HealEffect(go, color), go.mapX, go.mapY);
			case Teleport:
				map.addGameObject(new TeleportEffect(), x1, y1);
			case Stream:
				map.addGameObject(new StreamEffect(x1, y1, x2, y2, color), x1, y2);
			case Throw:
				var go = map.getGameObject(targetObjectId);
				if (go == null)
					return;

				var startX = go != null ? go.mapX : x2;
				var startY = go != null ? go.mapY : y2;
				map.addGameObject(new ThrowEffect(startX, startY, x1, y1, color), startX, startY);
			case Nova:
				var go = map.getGameObject(targetObjectId);
				if (go == null)
					return;

				map.addGameObject(new NovaEffect(go.mapX, go.mapY, x1, color), go.mapX, go.mapY);
			case Flow:
				var go = map.getGameObject(targetObjectId);
				if (go == null)
					return;

				map.addGameObject(new FlowEffect(x1, y1, go, color), x1, y1);
			case Line:
				var go = map.getGameObject(targetObjectId);
				if (go == null)
					return;

				map.addGameObject(new LineEffect(go.mapX, go.mapY, x1, y1, color), x1, y1);
			case Ring:
				var go = map.getGameObject(targetObjectId);
				if (go == null)
					return;

				map.addGameObject(new RingEffect(go, x1, color, 0), go.mapX, go.mapY);
			case Jitter:
				Camera.startJitter();
			case Flash:
				var go = map.getGameObject(targetObjectId);
				if (go == null)
					return;

				go.flashStartTime = System.getTimer();
				go.flashColor = color;
				go.flashPeriodMs = Std.int(x1 * 1000);
				go.flashRepeats = Std.int(y1);
			default:
				trace("ERROR: Unknown effect type: " + effectType);
		}
	}

	private static function handleText(data: ByteArray) {
		var name = data.readUTF();
		var objectId = data.readInt();
		var bubbleTime = data.readUnsignedByte();
		var recipient = data.readUTF();
		var text = data.readUTF();
		var textColor = 0xFFFFFF;
		var nameColor = 0xFF00FF;
		if (text != "")
			textColor = data.readUnsignedInt();
		if (name != "")
			nameColor = data.readUnsignedInt();

		#if log_packets
		trace(Global.gameSprite.lastUpdate,
			"Text: name="
			+ name
			+ ", objectId="
			+ objectId
			+ ", bubbleTime="
			+ bubbleTime
			+ ", recipient="
			+ recipient
			+ ", text="
			+ text
			+ ", textColor="
			+ textColor
			+ ", nameColor="
			+ nameColor);
		#end

		if (objectId != -1) {
			var go = Global.gameSprite.map.getGameObject(objectId);
			if (go != null) {
				if (go.props.isEnemy) {
					Global.gameSprite.map.addSpeechBalloon(new SpeechBalloon(go, text, SpeechBalloon.ENEMY_BUBBLE, bubbleTime));
					return;
				}

				var sbType = SpeechBalloon.DEFAULT_BUBBLE;
				if (recipient != "")
					sbType = SpeechBalloon.MESSAGE_BUBBLE;

				switch (nameColor) {
					case 0xF2CA46:
						sbType = SpeechBalloon.ADMIN_BUBBLE;
					// todo
					case 0x000000:
						sbType = SpeechBalloon.GUILD_BUBBLE;
					case 0x000001:
						sbType = SpeechBalloon.PARTY_BUBBLE;
				}

				Global.gameSprite.map.addSpeechBalloon(new SpeechBalloon(go, text, sbType, bubbleTime));
			}
		}

		Global.gameSprite.textBox.addTextFull(name, recipient, text, nameColor, textColor);
	}

	private static function handleTradeAccepted(data: ByteArray) {
		var myOffer = new Array<Bool>();
		var num = data.readShort();
		for (i in 0...num)
			myOffer.push(data.readBoolean());

		var yourOffer = new Array<Bool>();
		num = data.readShort();
		for (i in 0...num)
			yourOffer.push(data.readBoolean());

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "TradeAccepted: myOffer=" + myOffer + ", yourOffer=" + yourOffer);
		#end

		// todo trade
		// Global.gameSprite.hudView.tradeAccepted(tradeAccepted);
	}

	private static function handleTradeChanged(data: ByteArray) {
		var offer = new Array<Bool>();
		var num = data.readShort();
		for (i in 0...num)
			offer.push(data.readBoolean());

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "TradeChanged: offer=" + offer);
		#end

		// todo trade
		// Global.gameSprite.hudView.tradeChanged(tradeChanged);
	}

	private static function handleTradeDone(data: ByteArray) {
		var code = data.readInt();
		var description = data.readUTF();

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "TradeDone: code=" + code + ", description=" + description);
		#end

		// todo trade
		// Global.gameSprite.hudView.tradeDone();
		Global.gameSprite.textBox.addText(description, 0x0000FF);
	}

	private static function handleTradeRequested(data: ByteArray) {
		var name = data.readUTF();

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "TradeRequested: name=" + name);
		#end

		// Global.gameSprite.interactPanel.setOverride(new TradeRequestPanel(Global.gameSprite, name));
		Global.gameSprite.textBox.addText(name + " wants to " + "trade with you.  Type \"/trade " + name + "\" to trade.", 0x0000FF);
	}

	private static function handleTradeStart(data: ByteArray) {
		var myItems = new Array<TradeItem>();
		for (i in 0...data.readShort())
			myItems.push({
				item: data.readInt(),
				slotType: data.readInt(),
				tradeable: data.readBoolean(),
				included: data.readBoolean()
			});

		var yourName = data.readUTF();
		var yourItems = new Array<TradeItem>();
		for (i in 0...data.readShort())
			yourItems.push({
				item: data.readInt(),
				slotType: data.readInt(),
				tradeable: data.readBoolean(),
				included: data.readBoolean()
			});

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "TradeStart: myItems=" + myItems + ", yourName=" + yourName + ", yourItems=" + yourItems);
		#end

		// todo trade
		// Global.gameSprite.hudView.startTrade(Global.gameSprite_, tradeStart);
	}

	private static function handleUpdate(data: ByteArray) {
		for (i in 0...data.readShort()) {
			var x = data.readShort();
			var y = data.readShort();
			var tileType = data.readUnsignedShort();
			Global.gameSprite.map.setGroundTile(x, y, tileType);
			Global.gameSprite.miniMap.setGroundTile(x, y, tileType);
		}

		for (i in 0...data.readShort())
			Global.gameSprite.map.removeObj(data.readInt());

		for (i in 0...data.readShort()) {
			var objType = data.readUnsignedShort();
			var objId = data.readInt();
			var x = data.readFloat();
			var y = data.readFloat();

			var map = Global.gameSprite.map;
			var go = ObjectLibrary.getObjectFromType(objType);
			go?.setObjectId(objId);

			for (j in 0...data.readShort())
				parseStat(go, data.readUnsignedByte(), data);

			if (go == null) {
				trace('Could not find Update GameObject: objId=$objId, x=$x, y=$y');
				continue;
			}

			map.addGameObject(go, x, y);
			if (go.props.isPlayer) {
				var newPlayer = cast(go, Player);
				setPlayerSkinTemplate(newPlayer, 0);
				if (newPlayer.objectId == playerId) {
					player = newPlayer;
					map.player = newPlayer;
					Global.gameSprite.setFocus(newPlayer);
				}
			}

			if (go.props.staticObj && go.props.occupySquare && !go.props.noMiniMap)
				Global.gameSprite.miniMap.setGameObjectTile(Std.int(go.mapX), Std.int(go.mapY), go);
		}

		updateAck();

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "Update");
		#end
	}

	private static function updateAck() {
		sendPacket(C2SPacketId.UpdateAck);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "UpdateAck");
		#end
	}

	private static function aoeAck(time: Int, x: Float, y: Float) {
		/*outgoingData.writeInt(time);
			outgoingData.writeFloat(x);
			outgoingData.writeFloat(y);
			sendPacket(AOEACK); */
	}

	private static function gotoAck(time: Int) {
		outgoingData.writeInt(time);
		sendPacket(C2SPacketId.GotoAck);
		#if log_packets
		trace(Global.gameSprite.lastUpdate, "GotoAck: time=" + time);
		#end
	}

	private static function shootAck(time: Int) {
		/*outgoingData.writeInt(time);
			sendPacket(SHOOTACK); */
	}

	private static function pong(serial: Int, time: Int) {
		outgoingData.writeInt(serial);
		outgoingData.writeInt(time);
		sendPacket(C2SPacketId.Pong);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "Pong: serial=" + serial + ", time=" + time);
		#end
	}

	public static function playerShoot(time: Int, proj: Projectile) {
		outgoingData.writeInt(time);
		outgoingData.writeByte(proj.bulletId);
		outgoingData.writeShort(proj.containerType);
		outgoingData.writeFloat(proj.mapX);
		outgoingData.writeFloat(proj.mapY);
		outgoingData.writeFloat(proj.angle);
		sendPacket(C2SPacketId.PlayerShoot);

		#if log_packets
		trace(Global.gameSprite.lastUpdate,
			"PlayerShoot: time="
			+ time
			+ ", bulletId="
			+ proj.bulletId
			+ ", objType="
			+ proj.containerType
			+ ", x="
			+ proj.mapX
			+ ", y="
			+ proj.mapY
			+ ", angle="
			+ proj.angle);
		#end
	}

	public static function playerHit(bulletId: Int, objectId: Int) {
		outgoingData.writeByte(bulletId);
		outgoingData.writeInt(objectId);
		sendPacket(C2SPacketId.PlayerHit);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "PlayerHit: bulletId=" + bulletId + ", objectId=" + objectId);
		#end
	}

	public static function enemyHit(time: Int, bulletId: Int, targetId: Int, kill: Bool) {
		// outgoingData.writeInt(time);
		outgoingData.writeByte(bulletId);
		outgoingData.writeInt(targetId);
		// outgoingData.writeBoolean(kill);
		sendPacket(C2SPacketId.EnemyHit);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "EnemyHit: time="
			+ time
			+ ", bulletId="
			+ bulletId
			+ ", targetId="
			+ targetId
			+ ", kill="
			+ kill);
		#end
	}

	public static function otherHit(time: Int, bulletId: Int, objectId: Int, targetId: Int) {
		/*outgoingData.writeInt(time);
			outgoingData.writeByte(bulletId);
			outgoingData.writeInt(objectId);
			outgoingData.writeInt(targetId);
			sendPacket(C2SPacketId.OtherHit); */
	}

	public static function squareHit(time: Int, bulletId: Int, objectId: Int) {
		/*outgoingData.writeInt(time);
			outgoingData.writeByte(bulletId);
			outgoingData.writeInt(objectId);
			sendPacket(C2SPacketId.SquareHit); */
	}

	public static function groundDamage(time: Int, x: Float, y: Float) {
		outgoingData.writeInt(time);
		outgoingData.writeFloat(x);
		outgoingData.writeFloat(y);
		sendPacket(C2SPacketId.GroundDamage);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "GroundDamage: time=" + time + ", x=" + x + ", y=" + y);
		#end
	}

	public static function playerText(textStr: String) {
		outgoingData.writeUTF(textStr);
		sendPacket(C2SPacketId.PlayerText);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "PlayerText: text=" + textStr);
		#end
	}

	public static function invSwap(player: Player, sourceObj: GameObject, slotId1: Int, itemId: Int, targetObj: GameObject, slotId2: Int, objectType2: Int) {
		if (Global.gameSprite == null)
			return false;

		outgoingData.writeInt(sourceObj.objectId);
		outgoingData.writeByte(slotId1);
		outgoingData.writeInt(targetObj.objectId);
		outgoingData.writeByte(slotId2);
		sendPacket(C2SPacketId.InvSwap);

		#if log_packets
		trace(Global.gameSprite.lastUpdate,
			"InvSwap: objId1="
			+ sourceObj.objectId
			+ ", slotId1="
			+ slotId1
			+ ", objId2="
			+ targetObj.objectId
			+ ", slotId2="
			+ slotId2);
		#end

		var tempType: Int = sourceObj.equipment[slotId1];
		sourceObj.equipment[slotId1] = targetObj.equipment[slotId2];
		targetObj.equipment[slotId2] = tempType;

		SoundEffectLibrary.play("inventory_move_item");
		return true;
	}

	public static function invSwapVial(player: Player, sourceObj: GameObject, slotId1: Int, itemId: Int, targetObj: GameObject, slotId2: Int,
			objectType2: Int) {
		if (Global.gameSprite == null)
			return false;

		outgoingData.writeInt(sourceObj.objectId);
		outgoingData.writeByte(slotId1);
		outgoingData.writeInt(targetObj.objectId);
		outgoingData.writeByte(slotId2);
		sendPacket(C2SPacketId.InvSwap);

		#if log_packets
		trace(Global.gameSprite.lastUpdate,
			"InvSwap (vial): objId1="
			+ sourceObj.objectId
			+ ", slotId1="
			+ slotId1
			+ ", objId2="
			+ targetObj.objectId
			+ ", slotId2="
			+ slotId2);
		#end

		sourceObj.equipment[slotId1] = ItemConstants.NO_ITEM;

		SoundEffectLibrary.play("inventory_move_item");
		return true;
	}

	public static function invDrop(object: GameObject, slotId: Int, objectType: Int) {
		outgoingData.writeInt(object.objectId);
		outgoingData.writeByte(slotId);
		outgoingData.writeShort(objectType);
		sendPacket(C2SPacketId.InvDrop);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "InvDrop: objId=" + object.objectId + ", slotId=" + slotId + ", objType=" + objectType);
		#end
	}

	public static function useItem(time: Int, objectId: Int, slotId: Int, objectType: Int, posX: Float, posY: Float, useType: Int) {
		outgoingData.writeInt(time);
		outgoingData.writeInt(objectId);
		outgoingData.writeByte(slotId);
		outgoingData.writeShort(objectType);
		outgoingData.writeFloat(posX);
		outgoingData.writeFloat(posY);
		outgoingData.writeByte(useType);
		sendPacket(C2SPacketId.UseItem);

		#if log_packets
		trace(Global.gameSprite.lastUpdate,
			"UseItem: time="
			+ time
			+ ", objId="
			+ objectId
			+ ", slotId="
			+ slotId
			+ ", objType="
			+ objectType
			+ ", posX="
			+ posX
			+ ", posY="
			+ posY
			+ ", useType="
			+ useType);
		#end
	}

	public static function useItem_new(itemOwner: GameObject, slotId: Int) {
		var itemId: Int = itemOwner.equipment[slotId];
		var objectXML: Xml = ObjectLibrary.xmlLibrary.get(itemId);
		if (objectXML == null)
			return false;

		if (objectXML.elementsNamed("Consumable").hasNext() || objectXML.elementsNamed("InvUse").hasNext()) {
			if (!objectXML.elementsNamed("Activate").hasNext()) {
				useItem(System.getTimer(), itemOwner.objectId, slotId, itemId, 0, 0, 0);
				if (objectXML.elementsNamed("Consumable").hasNext())
					itemOwner.equipment[slotId] = -1;
				SoundEffectLibrary.play("use_potion");
				return true;
			}

			var plr: Player = cast(itemOwner, Player);
			var totalActivate = 0;
			var failedActivate = 0;

			for (activateXML in objectXML.elementsNamed("Activate")) {
				totalActivate++;

				var activationType: String = activateXML.toString();
				if (activationType == ActivationType.UNLOCK_SKIN) {
					var skin: CharacterSkin = Global.classModel.getCharacterSkin(Std.parseInt(activateXML.get("objType")));

					if (skin.getState() == CharacterSkinState.OWNED) {
						Global.gameSprite.textBox.addText("You already own this skin!", 0xFF0000);
						return false;
					} else {
						skin.setState(CharacterSkinState.OWNED);
						Global.gameSprite.textBox.addText("Skin unlocked successfully.", 0x0000FF);
					}
				}

				switch (activationType) {
					case ActivationType.HEAL:
						if (plr.hp >= plr.maxHP)
							failedActivate++;
						break;
					case ActivationType.MAGIC:
						if (plr.mp >= plr.maxMP || plr.objectType == ObjectLibrary.idToType.get("Warlock"))
							failedActivate++;
						break;
				}
			}

			if (failedActivate >= totalActivate) {
				SoundEffectLibrary.play("error");
				return false;
			}
		}

		if (objectXML.elementsNamed("SlotType").hasNext()) {
			var slotType: Int = Std.parseInt(objectXML.elementsNamed("SlotType").next().firstChild().nodeValue);
			var slotTypes: Array<Int32> = itemOwner.slotTypes.slice(0, 4);
			for (i in 0...slotTypes.length)
				if (ObjectLibrary.slotsMatching(slotTypes[i], slotType)) {
					var equips: Array<Int32> = itemOwner.equipment;
					invSwap(cast(itemOwner, Player), itemOwner, i, equips[i], itemOwner, slotId, equips[slotId]);
					return true;
				}
		}

		SoundEffectLibrary.play("error");
		return false;
	}

	public static function teleport(objectId: Int) {
		outgoingData.writeInt(objectId);
		sendPacket(C2SPacketId.Teleport);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "Teleport: objId=" + objectId);
		#end
	}

	public static function usePortal(objectId: Int) {
		if (Global.gameSprite != null) {
			Camera.mapX = Global.gameSprite.map.player.mapX = -1;
			Camera.mapY = Global.gameSprite.map.player.mapY = -1;
			Global.gameSprite.disconnect();
		}

		outgoingData.writeInt(objectId);
		sendPacket(C2SPacketId.UsePortal);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "UsePortal: objId=" + objectId);
		#end
	}

	public static function buy(objectId: Int) {
		outgoingData.writeInt(objectId);
		sendPacket(C2SPacketId.Buy);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "Buy: objId=" + objectId);
		#end
	}

	public static function editAccountList(accountListId: Int, add: Bool, objectId: Int) {
		outgoingData.writeInt(accountListId);
		outgoingData.writeBoolean(add);
		outgoingData.writeInt(objectId);
		sendPacket(C2SPacketId.EditAccountList);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "EditAccountList: listId=" + accountListId + ", add=" + add + ", objId=" + objectId);
		#end
	}

	public static function createGuild(name: String) {
		outgoingData.writeUTF(name);
		sendPacket(C2SPacketId.CreateGuild);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "CreateGuild: name=" + name);
		#end
	}

	public static function guildRemove(name: String) {
		outgoingData.writeUTF(name);
		sendPacket(C2SPacketId.GuildRemove);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "GuildRemove: name=" + name);
		#end
	}

	public static function guildInvite(name: String) {
		outgoingData.writeUTF(name);
		sendPacket(C2SPacketId.GuildInvite);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "GuildInvite: name=" + name);
		#end
	}

	public static function requestTrade(name: String) {
		outgoingData.writeUTF(name);
		sendPacket(C2SPacketId.RequestTrade);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "RequestTrade: name=" + name);
		#end
	}

	public static function changeTrade(offer: Array<Bool>) {
		outgoingData.writeShort(offer.length);
		for (i in 0...offer.length)
			outgoingData.writeBoolean(offer[i]);
		sendPacket(C2SPacketId.ChangeTrade);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "ChangeTrade: offers=" + offer);
		#end
	}

	public static function acceptTrade(myOffer: Array<Bool>, yourOffer: Array<Bool>) {
		outgoingData.writeShort(myOffer.length);
		for (i in 0...myOffer.length)
			outgoingData.writeBoolean(myOffer[i]);
		outgoingData.writeShort(yourOffer.length);
		for (i in 0...yourOffer.length)
			outgoingData.writeBoolean(yourOffer[i]);
		sendPacket(C2SPacketId.AcceptTrade);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "AcceptTrade: myOffers=" + myOffer + ", yourOffers=" + yourOffer);
		#end
	}

	public static function cancelTrade() {
		sendPacket(C2SPacketId.CancelTrade);
		#if log_packets
		trace(Global.gameSprite.lastUpdate, "CancelTrade");
		#end
	}

	public static function escape() {
		if (playerId == -1)
			return;
		if (Global.gameSprite.map.mapName == "Hub") {
			#if log_packets
			trace(Global.gameSprite.lastUpdate, "Escape -> Already in Hub");
			#end
			return;
		}
		if (Global.gameSprite.fromEditor) {
			#if log_packets
			trace(Global.gameSprite.lastUpdate, "Escape (Map Editor)");
			#end
			disconnect();
			return;
		}
		Camera.mapX = Global.gameSprite.map.player.mapX = -1;
		Camera.mapY = Global.gameSprite.map.player.mapY = -1;
		Global.gameSprite.disconnect();
		sendPacket(C2SPacketId.Escape);
		#if log_packets
		trace(Global.gameSprite.lastUpdate, "Escape");
		#end
	}

	public static function joinGuild(guildName: String) {
		outgoingData.writeUTF(guildName);
		sendPacket(C2SPacketId.JoinGuild);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "JoinGuild: guildName=" + guildName);
		#end
	}

	public static function changeGuildRank(name: String, rank: Int) {
		outgoingData.writeUTF(name);
		outgoingData.writeInt(rank);
		sendPacket(C2SPacketId.ChangeGuildRank);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "ChangeGuildRank: name=" + name + ", rank=" + rank);
		#end
	}

	public static function reskin(skinId: Int, player: Player = null) {
		outgoingData.writeInt(skinId);
		sendPacket(C2SPacketId.Reskin);

		#if log_packets
		trace(Global.gameSprite.lastUpdate, "Reskin: skinId=" + skinId);
		#end

		setPlayerSkinTemplate(player, skinId);
	}

	private static function setPlayerSkinTemplate(player: Player, skinId: Int) {
		var player = player != null ? player : Global.gameSprite.map.player;
		var skinID = skinId;
		var charType = Global.classModel.getCharacterClass(player.objectType);
		var skin = charType.skins.getSkin(skinID);
		player.skinId = skinID;
		player.skin = CharacterFactory.makeCharacter(skin.template);
		player.isDefaultAnimatedChar = false;
	}

	public static function move(tickId: Int, player: Player) {
		var len = 0;
		var x = -1.0;
		var y = -1.0;
		if (player != null) {
			x = player.mapX;
			y = player.mapY;
		}

		outgoingData.writeByte(tickId);
		outgoingData.writeInt(Global.gameSprite.lastFixedUpdate);
		outgoingData.writeFloat(x);
		outgoingData.writeFloat(y);

		var lastMove = Global.gameSprite.moveRecords.lastClearTime;
		if (lastMove >= 0 && Global.gameSprite.lastFixedUpdate - lastMove > 125) {
			len = Std.int(Math.min(10, Global.gameSprite.moveRecords.recordIdx));
			var actualLen: UInt16 = 0;
			for (i in 0...len)
				if (Global.gameSprite.moveRecords.records[i].time < Global.gameSprite.lastFixedUpdate - 25)
					actualLen++;

			outgoingData.writeShort(actualLen);
			for (i in 0...len) {
				if (Global.gameSprite.moveRecords.records[i].time >= Global.gameSprite.lastFixedUpdate - 25)
					break;

				var rec = Global.gameSprite.moveRecords.records[i];
				outgoingData.writeInt(rec.time);
				outgoingData.writeFloat(rec.x);
				outgoingData.writeFloat(rec.y);
			}
		} else
			outgoingData.writeShort(0);

		Global.gameSprite.moveRecords.clear(Global.gameSprite.lastFixedUpdate);
		sendPacket(C2SPacketId.Move);

		#if log_packets
		trace(Global.gameSprite.lastUpdate,
			"Move: tickId="
			+ tickId
			+ ", time="
			+ Global.gameSprite.lastFixedUpdate
			+ ", x="
			+ x
			+ ", y="
			+ y
			+ ", records="
			+ Global.gameSprite.moveRecords.records);
		#end

		if (player != null) {
			if (Global.gameSprite.map == null)
				return;

			var square = Global.gameSprite.map.lookupSquare(Std.int(player.mapX), Std.int(player.mapY));
			if (square == null)
				return;

			if (square.props.sinking) {
				player.sinkLevel = Math.min(player.sinkLevel + 0.1, 1.8);
				player.moveMultiplier = 0.1 + (1 - player.sinkLevel / 1.8) * (square.props.speed - 0.1);
			} else {
				player.sinkLevel = 0;
				player.moveMultiplier = square.props.speed;
			}
		}
	}

	private static inline function parseStat(go: GameObject, statType: StatType, data: ByteArray) {
		switch (statType) {
			case MaxHP:
				var maxHP = data.readInt();
				if (go == null)
					return;

				go.maxHP = maxHP;
			case HP:
				var hp = data.readInt();
				if (go == null)
					return;

				go.hp = hp;
			case Size:
				var size = data.readUnsignedShort();
				if (go != null && size != 100)
					go.size = size / 100;
			case MaxMP:
				var maxMP = data.readShort();
				if (go == null)
					return;

				cast(go, Player).maxMP = maxMP;
			case MP:
				var mp = data.readShort();
				if (go == null)
					return;

				cast(go, Player).mp = mp;
			case Strength:
				var strength = data.readShort();
				if (go == null)
					return;

				cast(go, Player).strength = strength;
			case Wit:
				var wit = data.readShort();
				if (go == null)
					return;

				cast(go, Player).wit = wit;
			case Defense:
				var defense = data.readShort();
				if (go == null)
					return;

				go.defense = defense;
			case Resistance:
				var res = data.readShort();
				if (go == null)
					return;

				cast(go, Player).resistance = res;
			case Speed:
				var speed = data.readShort();
				if (go == null)
					return;

				cast(go, Player).speed = speed;
			case Haste:
				var haste = data.readShort();
				if (go == null)
					return;

				cast(go, Player).haste = haste;
			case Stamina:
				var stam = data.readShort();
				if (go == null)
					return;

				cast(go, Player).stamina = stam;
			case Intelligence:
				var int = data.readShort();
				if (go == null)
					return;

				cast(go, Player).intelligence = int;
			case Piercing:
				var pier = data.readShort();
				if (go == null)
					return;

				cast(go, Player).piercing = pier;
			case Penetration:
				var pen = data.readShort();
				if (go == null)
					return;

				cast(go, Player).penetration = pen;
			case Tenacity:
				var ten = data.readShort();
				if (go == null)
					return;

				cast(go, Player).tenacity = ten;
			case Condition:
				var cond = data.readInt();
				if (go == null)
					return;

				go.condition = cond;
			case Inv0 | Inv1 | Inv2 | Inv3 | Inv4 | Inv5 | Inv6 | Inv7 | Inv8 | Inv9 | Inv10 | Inv11 | Inv12 | Inv13 | Inv14 | Inv15 | Inv16 | Inv17 | Inv18 |
				Inv19 | Inv20 | Inv21:
				var itemType = data.readUnsignedShort();
				if (itemType == 65535)
					itemType = -1;
				if (go == null)
					return;

				go.equipment[statType - StatType.Inv0] = itemType;
			case Name:
				var newName = data.readUTF();
				if (go == null)
					return;

				if (newName == "" && go.objClass == "Portal")
					return;

				if (go.name != newName) {
					go.name = newName;
					go.nameTex = null;
				}
			case MerchType:
				var merchType = data.readUnsignedShort();
			// if (go == null)
			// return;

			// go.setMerchandiseType(merchType);
			case MerchPrice:
				var merchPrice = data.readUnsignedByte();
			// if (go == null)
			// return;

			// go.setPrice(merchPrice);
			case PortalUsable:
				var portalActive = data.readBoolean();
			// if (go == null)
			// return;

			// go.portalActive = portalActive;
			case AccountId:
				var accId = data.readInt();
				if (go == null)
					return;

				cast(go, Player).accountId = accId;
			case MerchCount:
				var merchCount = data.readByte();
			// if (go == null)
			// return;

			// go.merchCount = merchCount;
			case HPBonus:
				var maxHPBoost = data.readShort();
				if (go == null)
					return;

				cast(go, Player).maxHPBoost = maxHPBoost;
			case MPBonus:
				var maxMPBoost = data.readShort();
				if (go == null)
					return;

				cast(go, Player).maxMPBoost = maxMPBoost;
			case StrengthBonus:
				var strengthBoost = data.readShort();
				if (go == null)
					return;

				cast(go, Player).strengthBoost = strengthBoost;
			case WitBonus:
				var witBoost = data.readShort();
				if (go == null)
					return;

				cast(go, Player).witBoost = witBoost;
			case DefenseBonus:
				var defenseBoost = data.readShort();
				if (go == null)
					return;

				cast(go, Player).defenseBoost = defenseBoost;
			case ResistanceBonus:
				var resBoost = data.readShort();
				if (go == null)
					return;

				cast(go, Player).resistanceBoost = resBoost;
			case SpeedBonus:
				var speedBoost = data.readShort();
				if (go == null)
					return;

				cast(go, Player).speedBoost = speedBoost;
			case HasteBonus:
				var hasteBoost = data.readShort();
				if (go == null)
					return;

				cast(go, Player).hasteBoost = hasteBoost;
			case StaminaBonus:
				var staminaBoost = data.readShort();
				if (go == null)
					return;

				cast(go, Player).staminaBoost = staminaBoost;
			case IntelligenceBonus:
				var intBoost = data.readShort();
				if (go == null)
					return;

				cast(go, Player).intelligenceBoost = intBoost;
			case PiercingBonus:
				var pierBoost = data.readShort();
				if (go == null)
					return;

				cast(go, Player).piercingBoost = pierBoost;
			case PenetrationBonus:
				var penBoost = data.readShort();
				if (go == null)
					return;

				cast(go, Player).penetrationBoost = penBoost;
			case TenacityBonus:
				var tenBoost = data.readShort();
				if (go == null)
					return;

				cast(go, Player).tenacityBoost = tenBoost;
			case OwnerAccountId:
				var ownerId = data.readInt();
				if (go == null)
					return;

				go.ownerId = ownerId;
			case AltTextureIndex:
				var altTex = data.readUnsignedShort();
				if (go == null)
					return;

				go.setAltTexture(altTex);
			case Guild:
				var guildName = data.readUTF();
				if (go == null)
					return;

				cast(go, Player).setGuildName(guildName);
			case GuildRank:
				var guildRank = data.readByte();
				if (go == null)
					return;

				cast(go, Player).guildRank = guildRank;
			case Texture:
				var skinId = data.readUnsignedShort();
				if (go == null)
					return;

				var player = cast(go, Player);
				if (player.skinId != skinId)
					setPlayerSkinTemplate(player, skinId);
			case DamageMultiplier:
				var damageMult = data.readFloat();
				if (go == null)
					return;

				cast(go, Player).damageMult = damageMult;
			case HitMultiplier:
				var hitMult = data.readFloat();
				if (go == null)
					return;

				cast(go, Player).hitMult = hitMult;
			case Level:
				var level = data.readUnsignedByte();
				if (go == null)
					return;

				cast(go, Player).level = level;
				cast(go, Player).updateMaxValues();
			case Gems:
				var gems = data.readInt();
				if (go == null)
					return;

				cast(go, Player).gems = gems;
			case Gold:
				var gold = data.readInt();
				if (go == null)
					return;

				cast(go, Player).gold = gold;
			case Crowns:
				var crowns = data.readInt();
				if (go == null)
					return;

				cast(go, Player).crowns = crowns;

			case SellablePrice:
				var price = data.readUnsignedShort();
			default:
				trace('Unhandled stat: type=${statType}');
		}
	}
}
