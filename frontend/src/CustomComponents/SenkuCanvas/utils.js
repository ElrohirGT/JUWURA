/**
 * @param {import("./types").Point} screenPos The position in the screen to transform
 * @param {import("./types").Point} canvasTopLeft - The topleft corners in the screen of the canvas
 * @param {number} scale - The scale of zoom in the canvas
 * @param {import("./types").Point} translation - The translation of the canvas
 * @returns {import("./types").Point} The screen position transformed into a canvas position
 */
export function fromScreenPosToCanvasPos(
	screenPos,
	canvasTopLeft,
	scale,
	translation,
) {
	return {
		x: (screenPos.x - canvasTopLeft.x) / scale - translation.x,
		y: (screenPos.y - canvasTopLeft.y) / scale - translation.y,
	};
}

/**
 * @param {import("./types").Point} canvasPos - The position inside the canvas
 * @param {number} gridOffset - The initial grid offset
 * @param {number} cellWidth - The width in pixels of a cell
 * @param {number} cellHeight - The height in pixels of a cell
 * @returns {import("./types").CellCoord}
 */
export function fromCanvasPosToCellCords(
	canvasPos,
	gridOffset,
	cellWidth,
	cellHeight,
) {
	let column = Math.floor((canvasPos.x - gridOffset) / cellWidth);
	let row = Math.floor((canvasPos.y - gridOffset) / cellHeight);

	return {
		column,
		row,
	};
}

/**
 * @param {import("./types").Point} canvasPos
 * @param {import("./types").Point} center
 * @param {number} radius
 */
export function canvasPosInsideCircle(canvasPos, center, radius) {
	const distanceFromCenter = Math.sqrt(
		Math.pow(canvasPos.x - center.x, 2) + Math.pow(canvasPos.y - center.y, 2),
	);

	return distanceFromCenter <= radius;
}

/**
 * @param {import("./types").Point} canvasPos
 * @param {import("./types").Point} topLeft
 * @param {number} width
 * @param {number} height
 */
export function canvasPosInsideRectangle(canvasPos, topLeft, width, height) {
	const xIsBetween =
		canvasPos.x >= topLeft.x && canvasPos.x <= topLeft.x + width;
	const yIsBetween =
		canvasPos.y >= topLeft.y && canvasPos.y <= topLeft.y + height;

	return xIsBetween && yIsBetween;
}

/**
 * The minimum is inclusive
 *
 * @param {import("./types").CellCoord} coordinates
 * @param {number} min
 * @param {number} max
 * @returns {boolean}
 */
export function coordinatesAreBetweenIndices(coordinates, min, max) {
	return (
		coordinates.row >= min &&
		coordinates.row < max &&
		coordinates.column >= min &&
		coordinates.column < max
	);
}

/**
 * @param {import("./types").CellCoord} aCords
 * @param {import("./types").CellCoord} bCords
 * @returns {boolean}
 */
export function cellCoordsAreEqual(aCords, bCords) {
	return aCords.row === bCords.row && aCords.column === bCords.column;
}

/**
 * @param {import("./types").CellCoord} coords
 * @param {number} scalar
 * @returns{import("./types").CellCoord}
 */
export function scaleCoords(coords, scalar) {
	return {
		row: coords.row * scalar,
		column: coords.column * scalar,
	};
}
