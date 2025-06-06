package ui.itemgrids;

import objects.GameObject;
import objects.Player;
import ui.itemgrids.itemtiles.InventoryTile;
import util.NativeTypes;

class InventoryGrid extends ItemGrid {
	private var tiles: Array<InventoryTile>;
	private var isBackpack = false;

	public function new(gridOwner: GameObject, currentPlayer: Player, itemIndexOffset: Int = 0, isBackpack: Bool = false, disableBgDraw: Bool = false) {
		var tile: InventoryTile = null;
		super(gridOwner, currentPlayer, itemIndexOffset, disableBgDraw);
		this.tiles = new Array<InventoryTile>();
		this.isBackpack = isBackpack;
		for (i in 0...18) {
			tile = new InventoryTile(i + indexOffset, this, interactive);
			addToGrid(tile, 1, i, 6);
			this.tiles[i] = tile;
		}
	}

	override public function setItems(items: Array<Int32>, itemIndexOffset: Int32 = 0) {
		var numItems = 0;
		if (items != null) {
			numItems = items.length;
			for (i in 0...18) {
				if (i + indexOffset < numItems)
					this.tiles[i].setItem(items[i + indexOffset]);
				else
					this.tiles[i].setItem(-1);
			}
		}
	}
}
