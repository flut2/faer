package util;

import util.NativeTypes;
import util.Utils.MathUtil;

final class Rect {
	public var x = 0.0;
	public var y = 0.0;
	public var width = 0.0;
	public var height = 0.0;

	public final inline function new(x: Float32 = 0, y: Float32 = 0, width: Float32 = 0, height: Float32 = 0) {
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
}

final class BinPacker {
	private static inline final MIN_WIDTH: Float32 = 8;
	private static inline final MIN_HEIGHT: Float32 = 8;

	public final binWidth: Float32;
	public final binHeight: Float32;
	public final freeRectangles: Array<Rect>;

	public final function new(width: Float32, height: Float32) {
		binWidth = width;
		binHeight = height;
		freeRectangles = [];
		freeRectangles.push(new Rect(0, 0, width, height));
	}

	public final function insert(width: Float32, height: Float32) {
		var newNode = findPositionForNewNodeBestAreaFit(width, height);

		if (newNode == null)
			return newNode;

		var numRectanglesToProcess: Int32 = freeRectangles.length;
		var i = 0;
		while (i < numRectanglesToProcess) {
			if (splitFreeNode(freeRectangles[i], newNode)) {
				freeRectangles.splice(i, 1);
				--numRectanglesToProcess;
				--i;
			}
			i++;
		}

		pruneFreeList();

		return newNode;
	}

	private final inline function findPositionForNewNodeBestAreaFit(width: Float32, height: Float32) {
		var score = MathUtil.FLOAT_MAX;
		var areaFit: Float32 = 0.0;
		var bestNode = new Rect();

		for (r in freeRectangles)
			if (r.width >= width && r.height >= height) {
				areaFit = r.width * r.height - width * height;
				if (areaFit < score) {
					bestNode.x = r.x;
					bestNode.y = r.y;
					bestNode.width = width;
					bestNode.height = height;
					score = areaFit;
				}
			}

		return bestNode.height != 0 ? bestNode : null;
	}

	private final function splitFreeNode(freeNode: Rect, usedNode: Rect) {
		if (usedNode.x >= freeNode.x + freeNode.width
			|| usedNode.x + usedNode.width <= freeNode.x
			|| usedNode.y >= freeNode.y + freeNode.height
			|| usedNode.y + usedNode.height <= freeNode.y)
			return false;

		var left = Math.max(freeNode.x, usedNode.x);
		var right = Math.min(freeNode.x + freeNode.width, usedNode.x + usedNode.width);

		if (usedNode.y > freeNode.y)
			if (freeNode.width >= MIN_WIDTH && usedNode.y - freeNode.y >= MIN_HEIGHT)
				freeRectangles.push(new Rect(freeNode.x, freeNode.y, freeNode.width, usedNode.y - freeNode.y));

		if (usedNode.y + usedNode.height < freeNode.y + freeNode.height)
			if (freeNode.width >= MIN_WIDTH && freeNode.y + freeNode.height - (usedNode.y + usedNode.height) >= MIN_HEIGHT)
				freeRectangles.push(new Rect(freeNode.x, usedNode.y + usedNode.height, freeNode.width,
					freeNode.y + freeNode.height - (usedNode.y + usedNode.height)));

		var top = Math.max(freeNode.y, usedNode.y);
		var bottom = Math.min(freeNode.y + freeNode.height, usedNode.y + usedNode.height);

		if (usedNode.x > freeNode.x)
			if (usedNode.x - freeNode.x >= MIN_WIDTH && bottom - top >= MIN_HEIGHT)
				freeRectangles.push(new Rect(freeNode.x, top, usedNode.x - freeNode.x, bottom - top));

		if (usedNode.x + usedNode.width < freeNode.x + freeNode.width)
			if (freeNode.x + freeNode.width - (usedNode.x + usedNode.width) >= MIN_WIDTH && bottom - top >= MIN_HEIGHT)
				freeRectangles.push(new Rect(usedNode.x + usedNode.width, top, freeNode.x + freeNode.width - (usedNode.x + usedNode.width), bottom - top));

		return true;
	}

	private final function pruneFreeList() {
		var i: Int32 = 0;
		var j: Int32 = 0;
		var len: Int32 = freeRectangles.length;
		while (i < len) {
			j = i + 1;
			var tmpRect = freeRectangles[i];
			while (j < len) {
				var tmpRect2 = freeRectangles[j];
				if (isContainedIn(tmpRect, tmpRect2)) {
					freeRectangles.splice(i, 1);
					--i;
					--len;
					break;
				}
				if (isContainedIn(tmpRect2, tmpRect)) {
					freeRectangles.splice(j, 1);
					--len;
					--j;
				}
				j++;
			}
			i++;
		}
	}

	private final inline function isContainedIn(a: Rect, b: Rect) {
		return a.x >= b.x && a.y >= b.y && a.x + a.width <= b.x + b.width && a.y + a.height <= b.y + b.height;
	}
}
