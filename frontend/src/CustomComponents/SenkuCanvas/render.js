import { lerpColor3 } from "../../Utils/color";
import { floatEquals } from "../../Utils/math";
import { search, createNode } from "../../Utils/astar";
import { fromCanvasPosToCellCords } from "./utils";

export const GRID_SIZE = 10;
export const GRID_LINES_COLOR = "#363636";

export const TASK_BACKGROUND = "#6e6e6e";

export const MINIFIED_VIEW = (() => {
	const cellSize = 100;
	return {
		cellSize,
		griddOffset: cellSize / 2,
		cellPadding: cellSize * 0.15,
		taskIconPadding: cellSize * 0.15,
		connectorCurveStart: cellSize / 4,
	};
})();

export const ADD_BTN_RADIUS = MINIFIED_VIEW.cellSize / 5;

/**
 * @param {HTMLCanvasElement} canvas
 * @param {import("./types").SenkuCanvasState} state - The input for rendering the component.
 * @param {number} scale - How much scale do we need? Value between 1 and 2.
 * @param {{x:number, y:number}} translatePos - The position inside the drawing the center of the canvas should be.
 * @param {{x: number, y: number}} [hoverPos=undefined] - The current hover position of the mouse (null if no hover).
 */
export function drawCanvas(
	canvas,
	state,
	scale,
	translatePos,
	hoverPos = undefined,
) {
	console.log("Drawing canvas with scale:", scale);

	const ctx = canvas.getContext("2d");
	ctx.clearRect(0, 0, canvas.offsetWidth, canvas.offsetHeight);
	ctx.save();

	ctx.scale(scale, scale);
	ctx.translate(translatePos.x, translatePos.y);

	ctx.strokeStyle = GRID_LINES_COLOR;
	ctx.lineWidth = 1;

	// console.log("STATE", state);
	for (let column = 0; column < GRID_SIZE; column += 1) {
		for (let row = 0; row < GRID_SIZE; row += 1) {
			let x = column * MINIFIED_VIEW.cellSize + MINIFIED_VIEW.griddOffset;
			let y = row * MINIFIED_VIEW.cellSize + MINIFIED_VIEW.griddOffset;
			ctx.strokeRect(x, y, MINIFIED_VIEW.cellSize, MINIFIED_VIEW.cellSize);

			const cell = state.cells[row][column];
			// console.log("CELL: ", { row, column }, cell);
			if (cell) {
				drawMinifiedTask(ctx, cell, { column, row });
			}
		}
	}

	// Adds border cells for the pathing algorithm
	// console.log(state.cells);
	const connMatrix = [];
	for (let row = 0; row < 2 * GRID_SIZE - 1; row++) {
		connMatrix.push([]);
		for (let column = 0; column < 2 * GRID_SIZE - 1; column++) {
			if (row % 2 !== 0) {
				connMatrix[row].push(undefined);
			} else if (column % 2 === 0) {
				connMatrix[row].push(state.cells[row / 2][column / 2]);
			} else {
				connMatrix[row].push(undefined);
			}
		}
	}
	// console.log(connMatrix);

	for (const connection of state.connections) {
		drawTaskConnection(ctx, connection, connMatrix);
	}

	if (hoverPos) {
		const debug = false;
		const { row, column } = fromCanvasPosToCellCords(
			hoverPos,
			MINIFIED_VIEW.griddOffset,
			MINIFIED_VIEW.cellSize,
			MINIFIED_VIEW.cellSize,
		);
		const cellTopLeft = {
			x: column * MINIFIED_VIEW.cellSize + MINIFIED_VIEW.griddOffset,
			y: row * MINIFIED_VIEW.cellSize + MINIFIED_VIEW.griddOffset,
		};
		const cellCenter = {
			x: cellTopLeft.x + MINIFIED_VIEW.cellSize / 2,
			y: cellTopLeft.y + MINIFIED_VIEW.cellSize / 2,
		};

		// Draw + circle on empty cells when hovering...
		if (row < GRID_SIZE && row >= 0 && column < GRID_SIZE && column >= 0) {
			if (!state.cells[row][column]) {
				ctx.beginPath();
				ctx.arc(cellCenter.x, cellCenter.y, ADD_BTN_RADIUS, 0, 2 * Math.PI);
				ctx.fillStyle = "#282828";
				ctx.fill();

				ctx.beginPath();
				ctx.arc(cellCenter.x, cellCenter.y, ADD_BTN_RADIUS, 0, 2 * Math.PI);
				ctx.strokeStyle = "#515151";
				ctx.lineWidth = 1;
				ctx.stroke();

				const plusSize = ADD_BTN_RADIUS * 3;
				ctx.font = `${plusSize}px IBM Plex Mono`;
				ctx.fillStyle = "#515151";
				ctx.textBaseline = "hanging";
				ctx.fillText(
					"+",
					cellCenter.x - plusSize / 3.25,
					cellCenter.y - plusSize / 3.25,
				);
			}
			// Draw task information
			else {
				const task = state.cells[row][column];

				const MAX_TASK_TITLE_CHARS = 20;
				const INFO_HEIGHT = 124;
				const INFO_WIDTH = 326;
				const TASK_INFO_PADDING = INFO_HEIGHT / 6;
				const INFO_ITEMS_SPACING = (INFO_HEIGHT - TASK_INFO_PADDING * 2) / 4;

				const taskInfoTopLeft = {
					x: cellCenter.x + MINIFIED_VIEW.cellSize / 4,
					y: cellCenter.y + MINIFIED_VIEW.cellSize / 4,
				};
				const taskInfoPaddedLeft = {
					x: taskInfoTopLeft.x + TASK_INFO_PADDING,
					y: taskInfoTopLeft.y + TASK_INFO_PADDING,
				};

				const radius = 8;
				drawCurvedRectangle(
					ctx,
					"#363636",
					taskInfoTopLeft,
					INFO_WIDTH,
					INFO_HEIGHT,
					radius,
				);

				const progressText = `${(task.progress * 100).toLocaleString(undefined, { maximumFractionDigits: 2 })}%`;
				const progressHeight = 14;
				ctx.font = `${progressHeight}px IBM Plex Mono`;
				ctx.textBaseline = "top";

				ctx.fillStyle = "white";
				ctx.fillText(progressText, taskInfoPaddedLeft.x, taskInfoPaddedLeft.y);

				const displayTitle =
					task.title.length < MAX_TASK_TITLE_CHARS
						? task.title
						: task.title.substring(0, MAX_TASK_TITLE_CHARS) + "...";
				const titleTextHeight = 16;
				ctx.font = `${titleTextHeight}px Parkinsans`;
				ctx.textBaseline = "top";

				const titleY =
					taskInfoPaddedLeft.y + progressHeight + INFO_ITEMS_SPACING;
				ctx.fillText(
					displayTitle,
					taskInfoPaddedLeft.x,
					titleY,
					INFO_WIDTH - TASK_INFO_PADDING * 2,
				);

				const statusTextHeight = 12;
				const statusContainerY = titleY + titleTextHeight + INFO_ITEMS_SPACING;
				const STATUS_CONTAINER_PADDING = 6;

				ctx.font = `${statusTextHeight}px IBM Plex Mono`;
				const textMeasurements = ctx.measureText(task.status.name);

				ctx.fillStyle = task.status.color;
				drawCurvedRectangle(
					ctx,
					task.status.color,
					{
						x: taskInfoPaddedLeft.x,
						y: statusContainerY,
					},
					textMeasurements.width + STATUS_CONTAINER_PADDING * 2,
					statusTextHeight + STATUS_CONTAINER_PADDING * 2,
					radius / 2,
				);

				ctx.fillStyle = "white";
				ctx.fillText(
					task.status.name,
					taskInfoPaddedLeft.x + STATUS_CONTAINER_PADDING,
					statusContainerY + STATUS_CONTAINER_PADDING,
				);

				const dateTextHeight = 12;
				const formatter = new Intl.DateTimeFormat(undefined, {
					day: "2-digit",
					month: "short",
				});
				const dateText = formatter.format(task.due_date).toLocaleUpperCase();

				ctx.fillStyle = "white";
				ctx.font = `${dateTextHeight}px IBM Plex Mono`;
				const dateMeasurements = ctx.measureText(dateText);
				ctx.fillText(
					dateText,
					taskInfoTopLeft.x +
						INFO_WIDTH -
						TASK_INFO_PADDING -
						dateMeasurements.width,
					statusContainerY + STATUS_CONTAINER_PADDING,
				);
			}
		}

		if (debug) {
			ctx.fillStyle = "purple";
			ctx.fillRect(cellTopLeft.x, cellTopLeft.y, 5, 5);

			ctx.fillStyle = "red";
			ctx.fillRect(hoverPos.x, hoverPos.y, 5, 5);
		}
	}

	ctx.restore();
}

/**
 * @param {CanvasRenderingContext2D} ctx
 * @param {TaskData} taskData
 * @param {CellCoord} cords
 */
function drawMinifiedTask(ctx, taskData, cords) {
	// Converts from idx to column/row number.
	let { column, row } = cords;
	column += 1;
	row += 1;

	const topLeft = {
		x:
			MINIFIED_VIEW.cellSize * column +
			MINIFIED_VIEW.cellPadding -
			MINIFIED_VIEW.griddOffset,
		y:
			MINIFIED_VIEW.cellSize * row +
			MINIFIED_VIEW.cellPadding -
			MINIFIED_VIEW.griddOffset,
	};
	const dimensions = {
		width: MINIFIED_VIEW.cellSize - MINIFIED_VIEW.cellPadding * 2,
		height: MINIFIED_VIEW.cellSize - MINIFIED_VIEW.cellPadding * 2,
	};

	const bottomLeft = {
		x: topLeft.x,
		y: topLeft.y + dimensions.height,
	};

	// DRAW TASK BACKGROUND
	const radius = 10;
	drawCurvedRectangle(
		ctx,
		TASK_BACKGROUND,
		topLeft,
		dimensions.width,
		dimensions.height,
		radius,
	);

	// DRAW EMOJI
	const emojiSize = dimensions.width - MINIFIED_VIEW.taskIconPadding * 2;
	ctx.font = `${emojiSize}px Parkinsans`;
	ctx.textBaseline = "top";
	ctx.fillText(
		taskData.icon,
		topLeft.x + MINIFIED_VIEW.taskIconPadding,
		topLeft.y + MINIFIED_VIEW.taskIconPadding,
	);

	// DRAW PROGRESS
	const red_500 = [202, 50, 61];
	const yellow = [200, 119, 49];
	const green = [75, 106, 55];
	const interpolated = lerpColor3(red_500, yellow, green, taskData.progress);
	const barHeight = dimensions.height * 0.1;

	ctx.fillStyle = `rgb(${interpolated[0]}, ${interpolated[1]}, ${interpolated[2]})`;
	ctx.beginPath();
	ctx.moveTo(topLeft.x, bottomLeft.y - barHeight);
	ctx.quadraticCurveTo(
		topLeft.x,
		bottomLeft.y,
		topLeft.x + radius,
		bottomLeft.y,
	);

	const xProgressBarEnd = topLeft.x + dimensions.width * taskData.progress;
	ctx.lineTo(xProgressBarEnd - radius, bottomLeft.y);

	if (floatEquals(taskData.progress, 1.0, 1e-10)) {
		ctx.quadraticCurveTo(
			bottomLeft.x + dimensions.width,
			bottomLeft.y,
			bottomLeft.x + dimensions.width,
			bottomLeft.y - barHeight,
		);
	} else {
		const endRadius = barHeight / 2;
		ctx.arc(
			xProgressBarEnd - endRadius,
			bottomLeft.y - endRadius,
			endRadius,
			Math.PI / 2,
			(3 * Math.PI) / 2,
			true,
		);
	}
	ctx.lineTo(bottomLeft.x, bottomLeft.y - barHeight);

	ctx.closePath();
	ctx.fill();
}

/**
 * @param {CanvasRenderingContext2D} ctx
 * @param {import("./types").TaskConnection} connInfo
 * @param {import("./types").Cells} matrix
 */
function drawTaskConnection(ctx, connInfo, matrix) {
	const { start, end } = connInfo;
	console.log("DRAWING CONNECTION", connInfo);
	const startTask = matrix[start.row][start.column];
	const endTask = matrix[end.row][end.column];
	const path = search(
		matrix,
		createNode(startTask, start.column, start.row),
		createNode(endTask, end.column, end.row),
		false,
		(a, b) => {
			// console.log("A:", a, "B:", b);
			if (a && b) {
				return a.id === b.id;
			}
			return false;
		},
		(a) => {
			return a !== undefined && a.id !== endTask.id;
		},
	);
	console.log("PATH:", path);

	path.unshift(createNode(startTask, start.column, start.row));

	const finishDrawing = () => {
		ctx.lineWidth = 1;
		ctx.strokeStyle = "white";
		ctx.stroke();
	};

	const basicOffset = {
		x: MINIFIED_VIEW.griddOffset,
		y: MINIFIED_VIEW.griddOffset,
	};

	// ctx.fillStyle = "red";
	// ctx.fillRect(basicDelta.x, basicDelta.y, 5, 5);

	// for (let i = 0; i < 13; i++) {
	for (let i = 0; i < path.length - 1; i++) {
		console.log("GETTING TRIPLET: ", i, i + 1, i + 2);
		const [startNode, endNode] = getPathNodes(path, i);
		console.log("TRIPLET:", startNode, endNode);

		const nodesInfo = getNodesInfo(startNode, endNode);
		console.log("TRIPLET INFO:", nodesInfo);

		const { direction } = nodesInfo;
		const { start: startPoint, end: middlePoint } = fromNodesToPoints(
			startNode,
			endNode,
			basicOffset,
			MINIFIED_VIEW.cellSize,
			MINIFIED_VIEW.cellSize,
		);

		// ctx.beginPath();
		// ctx.arc(middlePoint.x, middlePoint.y, 1, 0, 2 * Math.PI);
		// ctx.fillStyle = "red";
		// ctx.fill();

		// START
		if (start.column === startNode.x && start.row === startNode.y) {
			ctx.beginPath();
			const debug = false;

			const origin = {
				x:
					basicOffset.x +
					(start.column / 2) * MINIFIED_VIEW.cellSize +
					MINIFIED_VIEW.cellSize / 2 +
					(direction.x *
						(MINIFIED_VIEW.cellSize - MINIFIED_VIEW.cellPadding * 2)) /
						2,
				y:
					basicOffset.y +
					(start.row / 2) * MINIFIED_VIEW.cellSize +
					MINIFIED_VIEW.cellSize / 2 +
					(direction.y *
						(MINIFIED_VIEW.cellSize - MINIFIED_VIEW.cellPadding * 2)) /
						2,
			};
			const target = {
				x: origin.x + direction.x * MINIFIED_VIEW.cellPadding,
				y: origin.y + direction.y * MINIFIED_VIEW.cellPadding,
			};

			console.log("DRAWING START", { origin, target });
			ctx.moveTo(origin.x, origin.y);
			ctx.lineTo(target.x, target.y);

			if (debug) {
				ctx.strokeStyle = "red";
				ctx.stroke();

				ctx.fillStyle = "purple";
				ctx.fillRect(origin.x, origin.y, 5, 5);

				ctx.fillStyle = "pink";
				ctx.fillRect(target.x, target.y, 5, 5);
			} else {
				finishDrawing();
			}
		}

		// DRAW END
		else if (endNode.x === end.column && endNode.y === end.row) {
			ctx.beginPath();
			const origin = {
				x:
					basicOffset.x +
					(end.column / 2) * MINIFIED_VIEW.cellSize +
					MINIFIED_VIEW.cellSize / 2 +
					(-direction.x *
						(MINIFIED_VIEW.cellSize - MINIFIED_VIEW.cellPadding * 2)) /
						2,
				y:
					basicOffset.y +
					(end.row / 2) * MINIFIED_VIEW.cellSize +
					MINIFIED_VIEW.cellSize / 2 +
					(-direction.y *
						(MINIFIED_VIEW.cellSize - MINIFIED_VIEW.cellPadding * 2)) /
						2,
			};
			const target = {
				x: origin.x + -direction.x * MINIFIED_VIEW.cellPadding,
				y: origin.y + -direction.y * MINIFIED_VIEW.cellPadding,
			};
			console.log("DRAWING END", { origin, target });
			ctx.moveTo(origin.x, origin.y);
			ctx.lineTo(target.x, target.y);

			finishDrawing();

			// DRAWING END NOTCH
			const notchRadius = 3;
			ctx.beginPath();
			if (direction.x > 0) {
				// LEFT NOTCH
				ctx.arc(
					origin.x,
					origin.y,
					notchRadius,
					Math.PI / 2,
					(3 * Math.PI) / 2,
				);
			} else if (direction.x < 0) {
				// RIGHT NOTCH
				ctx.arc(
					origin.x,
					origin.y,
					notchRadius,
					Math.PI / 2,
					(3 * Math.PI) / 2,
					true,
				);
			} else if (direction.y > 0) {
				// UP NOTCH
				ctx.arc(origin.x, origin.y, notchRadius, 0, Math.PI, true);
			} else {
				// DOWN NOTCH
				ctx.arc(origin.x, origin.y, notchRadius, 0, Math.PI);
			}
			ctx.closePath();

			ctx.fillStyle = "white";
			ctx.fill();
		}

		// DRAW STRAIGHT HORIZONTAL
		else if (startNode.y === endNode.y) {
			ctx.beginPath();
			const debug = false;

			const origin = startPoint;
			const target = middlePoint;

			console.log("DRAWING STRAIGHT HORIZONTAL", { origin, target });

			ctx.moveTo(origin.x, origin.y);
			ctx.lineTo(target.x, target.y);

			if (debug) {
				ctx.strokeStyle = "red";
				ctx.stroke();

				ctx.fillStyle = "purple";
				ctx.fillRect(origin.x, origin.y, 5, 5);
				ctx.fillStyle = "pink";
				ctx.fillRect(target.x, target.y, 5, 5);
			} else {
				finishDrawing();
			}
		}

		// DRAW STRAIGHT VERTICAL
		else if (endNode.x === startNode.x) {
			ctx.beginPath();
			// const debug = i === 6 ? true : false;
			const debug = false;

			const origin = startPoint;
			const target = middlePoint;

			console.log("DRAWING STRAIGHT VERTICAL", { origin, target });
			ctx.moveTo(origin.x, origin.y);
			ctx.lineTo(target.x, target.y);

			if (debug) {
				ctx.strokeStyle = "red";
				ctx.stroke();

				ctx.fillStyle = "purple";
				ctx.fillRect(origin.x, origin.y, 5, 5);
				ctx.fillStyle = "pink";
				ctx.fillRect(target.x, target.y, 5, 5);
			} else {
				finishDrawing();
			}
		}
		// DRAW NOTHING
		else {
			console.log("DRAWING NOTHING");
			continue;
		}
	}

	// FIXME: Remove this once we don't need to debug
	// The end case on the if's above is in charge of painting everything!
	// ctx.closePath();
	// ctx.strokeStyle = "white";
	// ctx.stroke();
}

/**
 * @param {CanvasRenderingContext2D} ctx
 * @param {string} fillColor
 * @param {import("./types").Point} topLeft
 * @param {number} width
 * @param {number} height
 * @param {number} borderRadius
 */
function drawCurvedRectangle(
	ctx,
	fillColor,
	topLeft,
	width,
	height,
	borderRadius,
) {
	const bottomRight = {
		x: topLeft.x + width,
		y: topLeft.y + height,
	};
	ctx.beginPath();

	ctx.moveTo(topLeft.x, topLeft.y + borderRadius);
	ctx.quadraticCurveTo(
		topLeft.x,
		topLeft.y,
		topLeft.x + borderRadius,
		topLeft.y,
	);

	ctx.lineTo(bottomRight.x - borderRadius, topLeft.y);
	ctx.quadraticCurveTo(
		bottomRight.x,
		topLeft.y,
		bottomRight.x,
		topLeft.y + borderRadius,
	);

	ctx.lineTo(bottomRight.x, bottomRight.y - borderRadius);
	ctx.quadraticCurveTo(
		bottomRight.x,
		bottomRight.y,
		bottomRight.x - borderRadius,
		bottomRight.y,
	);

	ctx.lineTo(topLeft.x + borderRadius, bottomRight.y);
	ctx.quadraticCurveTo(
		topLeft.x,
		bottomRight.y,
		topLeft.x,
		bottomRight.y - borderRadius,
	);

	ctx.closePath();
	ctx.fillStyle = fillColor;
	ctx.fill();
}

function getPathNodes(path, startingIdx) {
	return [path[startingIdx], path[startingIdx + 1]];
}

function getNodesInfo(current, next) {
	const xDirection = next.x - current.x;
	const yDirection = next.y - current.y;

	return {
		direction: { x: xDirection, y: yDirection },
	};
}

function fromNodesToPoints(current, next, offset, cellWidth, cellHeight) {
	return {
		start: {
			x: offset.x + (current.x / 2) * cellWidth + cellWidth / 2,
			y: offset.y + (current.y / 2) * cellHeight + cellHeight / 2,
		},
		end: {
			x: offset.x + (next.x / 2) * cellWidth + cellWidth / 2,
			y: offset.y + (next.y / 2) * cellHeight + cellHeight / 2,
		},
	};
}
