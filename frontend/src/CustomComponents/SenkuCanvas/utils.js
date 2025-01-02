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
