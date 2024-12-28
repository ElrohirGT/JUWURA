import { clamp } from "../../Utils/math";
import { lerpColor3 } from "../../Utils/color";
import { floatEquals } from "../../Utils/math";
import { search, createNode } from "../../Utils/astar";

/**
 * @typedef {Object} CellCoord
 * @property {number} column
 * @property {number} row
 */

/**
 * @typedef {Object} TaskData
 * @property {number} id
 * @property {Date} due_date
 * @property {String} title
 * @property {String} status
 * @property {String} icon
 * @property {number} progress
 */

/**
 * @typedef {Object} TaskConnection
 * @property {CellCoord} start
 * @property {CellCoord} end
 */

const SCALE_DIMENSIONS = {
	min: 1,
	max: 4,
};
const GRID_SIZE = 10;
const GRID_LINES_COLOR = "#515151";

const TASK_BACKGROUND = "#6e6e6e";

const MINIFIED_VIEW = (() => {
	const cellSize = 100;
	return {
		cellSize,
		griddOffset: cellSize / 2,
		cellPadding: cellSize * 0.15,
		taskIconPadding: cellSize * 0.15,
		connectorCurveStart: cellSize / 4,
	};
})();

/**
 * @typedef {(TaskData|undefined)[][]} Cells
 */

/**
 * @typedef {Object} SenkuCanvasState
 * @property {Cells} cells
 * @property {TaskConnection[]} connections
 */

function genHorizontalStraight(cells, connections) {
	cells[0][0] = { id: 1, icon: "😎", progress: 1.0 };
	cells[0][5] = { id: 2, icon: "😎", progress: 1.0 };

	connections.push({
		start: {
			row: 0,
			column: 0,
		},
		end: {
			row: 0,
			column: 10,
		},
	});
}

function genSmallDiagonal(cells, connections) {
	cells[1][1] = { id: 3, icon: "😎", progress: 1.0 };
	cells[2][2] = { id: 4, icon: "😎", progress: 1.0 };

	connections.push({
		start: {
			row: 2,
			column: 2,
		},
		end: {
			row: 4,
			column: 4,
		},
	});
}

function genBigDiagonal(cells, connections) {
	cells[3][3] = { id: 5, icon: "😎", progress: 1.0 };
	cells[8][8] = { id: 6, icon: "😎", progress: 1.0 };

	connections.push({
		start: {
			row: 6,
			column: 6,
		},
		end: {
			row: 16,
			column: 16,
		},
	});
}

function genObstacle(cells, connections) {
	cells[3][4] = { id: 7, icon: "😎", progress: 1.0 };
	cells[3][7] = { id: 8, icon: "😎", progress: 1.0 };
	cells[3][8] = { id: 9, icon: "😎", progress: 1.0 };

	connections.push({
		start: {
			row: 6,
			column: 8,
		},
		end: {
			row: 6,
			column: 16,
		},
	});
}

/**
 * Generates dummy data for the graph
 * @returns {SenkuCanvasState}
 */
function generateDummyData() {
	/**@type {TaskConnection[]}*/
	const connections = [];
	/** @type {Cells}*/
	const cells = [];
	for (let i = 0; i < GRID_SIZE; i++) {
		cells.push([]);
		for (let j = 0; j < GRID_SIZE; j++) {
			cells[i].push(undefined);
		}
	}

	// genHorizontalStraight(cells, connections);
	// genSmallDiagonal(cells, connections);
	genBigDiagonal(cells, connections);
	// genObstacle(cells, connections);

	return {
		cells,
		connections,
	};
}

class SenkuCanvas extends HTMLElement {
	static observedAttributes = ["widthPct", "heightPct", "zoom"];

	constructor() {
		super();
	}

	/**
	 * Function that runs when the element is added to the page.
	 */
	connectedCallback() {
		console.log("Senku canvas element added to page.");

		const shadow = this.attachShadow({ mode: "open" });
		const canvas = document.createElement("canvas");
		canvas.width =
			(this.getAttribute("widthPct") / 100) * document.body.offsetWidth;
		canvas.height =
			(this.getAttribute("heightPct") / 100) * document.body.offsetHeight;

		this.registerEvents(canvas);

		const viewTopbar = document.getElementById("viewTopbar");

		// FIXME: This is a programming warcrime!
		// Since the senku canvas needs to be the length of the rest of the page
		// but the canvas element needs specific measurements, I have to wait until
		// all the CSS has loaded! there is no event for this, so I just wait a bit...
		requestAnimationFrame(() => {
			setTimeout(() => {
				canvas.height =
					(this.getAttribute("heightPct") / 100) * document.body.offsetHeight -
					viewTopbar.offsetHeight;
				console.log(
					"LOADED! HEIGHT:",
					`${this.getAttribute("heightPct")} / 100 * ${document.body.offsetHeight} - ${viewTopbar.offsetHeight} = ${canvas.height}`,
				);

				this.drawCanvas(
					canvas,
					this.getState(),
					this.getAttribute("zoom") ?? SCALE_DIMENSIONS.min,
					{
						x: 0,
						y: 0,
					},
				);
			}, 1000);
		});

		shadow.appendChild(canvas);
	}

	/**
	 * Function that runs when the element is removed from the page.
	 */
	disconnectedCallback() {
		console.log("Custom element removed from page.");
	}

	/**
	 * Function that runs when the element is moved to a new page.
	 */
	adoptedCallback() {
		console.log("Custom element moved to new page.");
	}

	/**
	 * Callback that runs when an attribute inside the static `observedAttributes`
	 * field is changed!
	 */
	attributeChangedCallback(name, oldValue, newValue) {
		console.log(`Attribute ${name} has changed. ${oldValue} -> ${newValue}`);
	}

	/**
	 * @param {HTMLCanvasElement} canvas
	 * @param {SenkuCanvasState} state - The input for rendering the component.
	 * @param {number} scale - How much scale do we need? Value between 1 and 2.
	 * @param {{x:number, y:number}} translatePos - The position inside the drawing the center of the canvas should be.
	 */
	drawCanvas(canvas, state, scale, translatePos) {
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
					this.drawMinifiedTask(ctx, cell, { column, row });
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
			this.drawTaskConnection(ctx, connection, connMatrix);
		}

		ctx.restore();
	}

	getState() {
		// TODO: This should be computed from a property in JS
		return generateDummyData();
	}

	/**
	 * @param {CanvasRenderingContext2D} ctx
	 * @param {TaskConnection} connInfo
	 * @param {Cells} matrix
	 */
	drawTaskConnection(ctx, connInfo, matrix) {
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
			// ctx.closePath();
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

		for (let i = 0; i < 13; i++) {
			// for (let i = 0; i < path.length - 2; i++) {
			console.log("GETTING TRIPLET: ", i, i + 1, i + 2);
			const [startNode, middleNode, endNode] = getNodeTriplet(path, i);
			console.log("TRIPLET:", startNode, middleNode, endNode);

			const currentTripletInfo = getTripletInfo(startNode, middleNode, endNode);
			console.log("TRIPLET INFO:", currentTripletInfo);

			const { direction } = currentTripletInfo;
			const {
				start: startPoint,
				middle: middlePoint,
				end: endPoint,
			} = fromTripletToPoints(
				startNode,
				middleNode,
				endNode,
				basicOffset,
				MINIFIED_VIEW.cellSize,
				MINIFIED_VIEW.cellSize,
			);

			ctx.beginPath();
			ctx.arc(middlePoint.x, middlePoint.y, 1, 0, 2 * Math.PI);
			ctx.fillStyle = "red";
			ctx.fill();

			if (currentTripletInfo.isCurve()) {
				ctx.beginPath();
				const debug = i === 10 || i === 11 ? true : false;
				// const debug = false;
				// DRAWING CURVE
				const curveStart = startPoint;
				const curveControl = middlePoint;
				const curveEnd = endPoint;
				console.log("CURVE CONTROL", curveControl, "CURVE END", curveEnd);

				const originDirection = {
					x: middleNode.x - startNode.x,
					y: middleNode.y - startNode.y,
				};
				const endDirection = {
					x: middleNode.x - endNode.x,
					y: middleNode.y - endNode.y,
				};

				const preCurveSegment = {
					start: curveStart,
					end: {
						x:
							curveStart.x +
							originDirection.x * MINIFIED_VIEW.connectorCurveStart,
						y:
							curveStart.y +
							originDirection.y * MINIFIED_VIEW.connectorCurveStart,
					},
				};

				const postCurveSegment = {
					start: {
						x: curveEnd.x + endDirection.x * MINIFIED_VIEW.connectorCurveStart,
						y: curveEnd.y + endDirection.y * MINIFIED_VIEW.connectorCurveStart,
					},
					end: curveEnd,
				};

				const nextTriplet = getNodeTriplet(path, i + 1);
				if (
					!nextTriplet[2] || // next next2 is invalid
					!getTripletInfo(...nextTriplet).isCurve() // next triplet is not a curve
				) {
					// const nextInfo = getTripletInfo(...nextTriplet);
					// console.log("NEXT INFO:", nextInfo.isCurve());
					ctx.moveTo(postCurveSegment.start.x, postCurveSegment.start.y);
					ctx.lineTo(postCurveSegment.end.x, postCurveSegment.end.y);
					i++;
				}

				if (middleNode.x % 2 === 0 && middleNode.y % 2 === 0) {
					ctx.moveTo(preCurveSegment.start.x, preCurveSegment.start.y);
					ctx.lineTo(preCurveSegment.end.x, preCurveSegment.end.y);
				} else {
					ctx.moveTo(preCurveSegment.end.x, preCurveSegment.end.y);
				}

				ctx.bezierCurveTo(
					curveControl.x,
					curveControl.y,
					curveControl.x,
					curveControl.y,
					postCurveSegment.start.x,
					postCurveSegment.start.y,
				);

				if (debug) {
					// ctx.closePath();

					ctx.strokeStyle = "red";
					ctx.lineWidth = 1;
					ctx.stroke();

					ctx.fillStyle = "green";
					ctx.fillRect(
						postCurveSegment.start.x,
						postCurveSegment.start.y,
						5,
						5,
					);

					ctx.fillStyle = "purple";
					ctx.fillRect(curveControl.x, curveControl.y, 5, 5);

					ctx.fillStyle = "pink";
					ctx.fillRect(curveEnd.x, curveEnd.y, 5, 5);

					ctx.fillStyle = "yellow";
					ctx.fillRect(curveStart.x, curveStart.y, 5, 5);
				} else {
					finishDrawing();
				}
				continue;
			}

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
			else if (startNode.y === middleNode.y) {
				ctx.beginPath();
				const debug = false;

				const origin = startPoint;
				const target = middlePoint;

				console.log("DRAWING STRAIGHT HORIZONTAL", { origin, target });

				ctx.moveTo(origin.x, origin.y);
				ctx.lineTo(target.x, target.y);

				const nextTriplet = getNodeTriplet(path, i + 1);
				if (nextTriplet[2] && getTripletInfo(...nextTriplet).isCurve()) {
					ctx.lineTo(target.x + MINIFIED_VIEW.connectorCurveStart, target.y);
				}

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
			else if (middleNode.x === startNode.x) {
				ctx.beginPath();
				// const debug = i === 6 ? true : false;
				const debug = false;

				const origin = startPoint;
				const target = middlePoint;

				console.log("DRAWING STRAIGHT VERTICAL", { origin, target });
				ctx.moveTo(origin.x, origin.y);
				ctx.lineTo(target.x, target.y);

				const nextTriplet = getNodeTriplet(path, i + 1);
				if (nextTriplet[2] && getTripletInfo(...nextTriplet).isCurve()) {
					ctx.lineTo(target.x, target.y + MINIFIED_VIEW.connectorCurveStart);
				}

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
	 * @param {TaskData} taskData
	 * @param {CellCoord} cords
	 */
	drawMinifiedTask(ctx, taskData, cords) {
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
		ctx.fillStyle = TASK_BACKGROUND;
		ctx.beginPath();
		ctx.moveTo(topLeft.x + radius, topLeft.y);

		ctx.quadraticCurveTo(topLeft.x, topLeft.y, topLeft.x, topLeft.y + radius);
		ctx.lineTo(topLeft.x, topLeft.y + dimensions.height - radius);

		ctx.quadraticCurveTo(
			topLeft.x,
			topLeft.y + dimensions.height,
			topLeft.x + radius,
			topLeft.y + dimensions.height,
		);
		ctx.lineTo(
			topLeft.x + dimensions.width - radius,
			topLeft.y + dimensions.height,
		);

		ctx.quadraticCurveTo(
			topLeft.x + dimensions.width,
			topLeft.y + dimensions.height,
			topLeft.x + dimensions.width,
			topLeft.y + dimensions.height - radius,
		);
		ctx.lineTo(topLeft.x + dimensions.width, topLeft.y + radius);

		ctx.quadraticCurveTo(
			topLeft.x + dimensions.width,
			topLeft.y,
			topLeft.x + dimensions.width - radius,
			topLeft.y,
		);
		ctx.lineTo(topLeft.x + radius, topLeft.y);

		ctx.closePath();
		ctx.fill();

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
	 * Registers all event callbacks for the canvas element
	 * @param {HTMLCanvasElement} canvas
	 */
	registerEvents(canvas) {
		let translatePos = {
			x: 0,
			y: 0,
		};

		let scale = this.getAttribute("zoom") ?? SCALE_DIMENSIONS.min;
		let startDragOffset = {};
		let mouseDown = false;

		canvas.addEventListener("mousedown", (ev) => {
			mouseDown = true;
			startDragOffset.x = ev.clientX - translatePos.x;
			startDragOffset.y = ev.clientY - translatePos.y;
		});
		canvas.addEventListener("mouseup", () => {
			mouseDown = false;
		});
		canvas.addEventListener("mouseover", () => {
			mouseDown = false;
		});
		canvas.addEventListener("mouseout", () => {
			mouseDown = false;
		});

		canvas.addEventListener("mousemove", (ev) => {
			if (mouseDown) {
				translatePos.x = ev.clientX - startDragOffset.x;
				translatePos.y = ev.clientY - startDragOffset.y;
				this.drawCanvas(canvas, this.getState(), scale, translatePos);
			}
		});

		canvas.addEventListener("wheel", (ev) => {
			scale -= ev.deltaY * 1e-3;
			scale = clamp(scale, 1, 4);
			this.drawCanvas(canvas, this.getState(), scale, translatePos);
		});
	}
}

function getNodeTriplet(path, startingIdx) {
	return [path[startingIdx], path[startingIdx + 1], path[startingIdx + 2]];
}

function getTripletInfo(current, next, next2) {
	const xDirection = next.x - current.x;
	const yDirection = next.y - current.y;

	const xCurved = next2.x - current.x;
	const yCurved = next2.y - current.y;
	return {
		direction: { x: xDirection, y: yDirection },
		curvature: { x: xCurved, y: yCurved },

		// If we're making a curve both should not be 0.
		// If any of them is 0 then it's a straight
		isCurve: () => {
			return xCurved !== 0 && yCurved !== 0;
		},
	};
}

function fromTripletToPoints(
	current,
	next,
	next2,
	offset,
	cellWidth,
	cellHeight,
) {
	return {
		start: {
			x: offset.x + (current.x / 2) * cellWidth + cellWidth / 2,
			y: offset.y + (current.y / 2) * cellHeight + cellHeight / 2,
		},
		middle: {
			x: offset.x + (next.x / 2) * cellWidth + cellWidth / 2,
			y: offset.y + (next.y / 2) * cellHeight + cellHeight / 2,
		},
		end: {
			x: offset.x + (next2.x / 2) * cellWidth + cellWidth / 2,
			y: offset.y + (next2.y / 2) * cellHeight + cellHeight / 2,
		},
	};
}

export const SenkuCanvasComponent = {
	register() {
		window.customElements.define("uwu-senku", SenkuCanvas);
	},
};
