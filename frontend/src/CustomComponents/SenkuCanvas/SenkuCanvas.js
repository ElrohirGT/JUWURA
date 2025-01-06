import { clamp } from "../../Utils/math";
import {
	CreateConnectionEvent,
	CreateTaskEvent,
	DeleteConnectionEvent,
	DeleteTaskEvent,
	TaskChangedCoordinatesEvent,
	ViewTaskEvent,
} from "./events";
import { ADD_BTN_RADIUS, drawCanvas, MINIFIED_VIEW } from "./render";
import { GRID_SIZE } from "./render";
import {
	canvasPosInsideCircle,
	canvasPosInsideRectangle,
	cellCoordsAreEqual,
	coordinatesAreBetweenIndices,
	fromCanvasPosToCellCords,
	fromScreenPosToCanvasPos,
	scaleCoords,
} from "./utils";

export const TAG_NAME = "uwu-senku";
const EMOJIS = [
	"🐩",
	"💙",
	"🙇",
	"📐",
	"🗿",
	"💍",
	"🍩",
	"🎌",
	"➰",
	"📝",
	"🤔",
	"🏊",
	"🍀",
	"👦",
];

const SCALE_DIMENSIONS = {
	min: 1,
	max: 4,
};

let lastTaskId = 0;

/**
 * @param {import("./types").CellCoord} coordinates
 * @param {string} [title="Test Title"] - The title of the task
 * @returns {TaskData}
 */
function createTask(
	coordinates,
	title = "MMM MMM MMMMMMM MMMM MMM MMMMMMMM MMM MM MMMMMM MMMM MMM MMMMMMMM",
) {
	return {
		id: lastTaskId++,
		title,
		coordinates,
		icon: "😎",
		progress: Math.random(),
		status: {
			name: "ON HOLD",
			color: "#3b5083",
		},
		due_date: new Date(),
	};
}

function genHorizontalStraight(cells, connections) {
	cells[0][0] = createTask({ row: 0, column: 0 });
	cells[0][5] = createTask({ row: 0, column: 5 });

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
	cells[1][1] = createTask({ row: 1, column: 1 });
	cells[2][2] = createTask({ row: 2, column: 2 });

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
	cells[3][3] = createTask({ row: 3, column: 3 });
	cells[8][8] = createTask({ row: 8, column: 8 });

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
	cells[3][4] = createTask({ row: 3, column: 4 });
	cells[3][7] = createTask({ row: 3, column: 7 });
	cells[3][8] = createTask({ row: 3, column: 8 });

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
 * @returns {import("./types").SenkuCanvasState}
 */
function generateDummyData() {
	/**@type {import("./types").TaskConnection}*/
	const connections = [];
	/** @type {import("./types").Cells}*/
	const cells = [];
	for (let i = 0; i < GRID_SIZE; i++) {
		cells.push([]);
		for (let j = 0; j < GRID_SIZE; j++) {
			cells[i].push(undefined);
		}
	}

	genHorizontalStraight(cells, connections);
	genSmallDiagonal(cells, connections);
	genBigDiagonal(cells, connections);
	genObstacle(cells, connections);

	return {
		cells,
		connections,
		projectId: 1,
		mouseDown: false,
		scale: SCALE_DIMENSIONS.min,
		mode: "none",
		hoverPos: undefined,
		// Drag grid
		translatePosition: { x: 0, y: 0 },
		startDragOffset: { x: 0, y: 0 },
		// Drag task
		taskTranslatePosition: { x: 0, y: 0 },
		draggedTaskOriginalCords: undefined,
	};
}

class SenkuCanvas extends HTMLElement {
	static observedAttributes = ["widthPct", "heightPct", "zoom"];

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

		this.initState();
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

				drawCanvas(canvas, this.getState());
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

	initState() {
		this.senkuState = generateDummyData();
	}

	getState() {
		// TODO: This should be computed from a property in JS
		return this.senkuState;
	}

	/**
	 * Registers all event callbacks for the canvas element.
	 * This function creates all the lambdas that modify the state of the canvas.
	 * If you need to modify some behaviour chances are you need to modify this function.
	 * @param {HTMLCanvasElement} canvas
	 */
	registerEvents(canvas) {
		const state = this.getState();

		canvas.addEventListener("mousedown", (ev) => {
			state.mouseDown = true;
			const debug = false;

			const isLeftClick = ev.button === 0;
			const isRightClick = ev.button === 2;

			const canvasPos = canvas.getBoundingClientRect();
			const mousePosOnCanvas = fromScreenPosToCanvasPos(
				{
					x: ev.clientX,
					y: ev.clientY,
				},
				{
					x: canvasPos.left,
					y: canvasPos.top,
				},
				state.scale,
				state.translatePosition,
			);

			const cellCords = fromCanvasPosToCellCords(
				mousePosOnCanvas,
				MINIFIED_VIEW.griddOffset,
				MINIFIED_VIEW.cellSize,
				MINIFIED_VIEW.cellSize,
			);
			const { row, column } = cellCords;

			const cellTopLeft = {
				x: column * MINIFIED_VIEW.cellSize + MINIFIED_VIEW.griddOffset,
				y: row * MINIFIED_VIEW.cellSize + MINIFIED_VIEW.griddOffset,
			};
			const cellCenter = {
				x: cellTopLeft.x + MINIFIED_VIEW.cellSize / 2,
				y: cellTopLeft.y + MINIFIED_VIEW.cellSize / 2,
			};

			if (debug) {
				const ctx = canvas.getContext("2d");
				ctx.fillStyle = "red";
				ctx.fillRect(mousePosOnCanvas.x, mousePosOnCanvas.y, 5, 5);

				ctx.fillStyle = "purple";
				ctx.fillRect(cellTopLeft.x, cellTopLeft.y, 5, 5);
			}

			const indicesInRange =
				row >= 0 && row < GRID_SIZE && column >= 0 && column < GRID_SIZE;
			const clickedOnATaskCell = state.cells[row]?.[column];
			const clickedOnAddTaskBtn =
				indicesInRange &&
				!clickedOnATaskCell &&
				canvasPosInsideCircle(mousePosOnCanvas, cellCenter, ADD_BTN_RADIUS);
			const clickedOnATask =
				clickedOnATaskCell &&
				canvasPosInsideRectangle(
					mousePosOnCanvas,
					{
						x: cellTopLeft.x + MINIFIED_VIEW.cellPadding,
						y: cellTopLeft.y + MINIFIED_VIEW.cellPadding,
					},
					MINIFIED_VIEW.innerTaskSize,
					MINIFIED_VIEW.innerTaskSize,
				);

			if (clickedOnAddTaskBtn) {
				const icon = EMOJIS[Math.floor(Math.random() * EMOJIS.length)];

				state.cells[cellCords.row][cellCords.column] = createDefaultTask(
					icon,
					state.projectId,
					cellCords,
				);

				const event = CreateTaskEvent({
					project_id: state.projectId,
					parent_id: null,
					icon,
				});
				this.dispatchEvent(event);
			} else if (clickedOnATask) {
				state.draggedTaskOriginalCords = cellCords;
				if (isLeftClick) {
					state.mode = "dragTask";
				} else if (isRightClick) {
					state.mode = "createConnection";
					state.futureTaskIcon =
						EMOJIS[Math.floor(Math.random() * EMOJIS.length)];
				}
			} else {
				state.mode = "dragGrid";
				state.startDragOffset.x = ev.clientX - state.translatePosition.x;
				state.startDragOffset.y = ev.clientY - state.translatePosition.y;
			}
		});
		canvas.addEventListener("mouseup", (ev) => {
			if (state.mode === "dragTask") {
				const canvasPos = canvas.getBoundingClientRect();
				const mousePosOnCanvas = fromScreenPosToCanvasPos(
					{
						x: ev.clientX,
						y: ev.clientY,
					},
					{
						x: canvasPos.left,
						y: canvasPos.top,
					},
					state.scale,
					state.translatePosition,
				);
				const coordinates = fromCanvasPosToCellCords(
					mousePosOnCanvas,
					MINIFIED_VIEW.griddOffset,
					MINIFIED_VIEW.cellSize,
					MINIFIED_VIEW.cellSize,
				);
				const { row, column } = coordinates;

				const newCoordinatesHaveATask = state.cells[row]?.[column];

				if (cellCoordsAreEqual(coordinates, state.draggedTaskOriginalCords)) {
					const taskId = state.cells[row][column].id;
					const event = ViewTaskEvent({
						taskId,
					});

					this.dispatchEvent(event);
				} else if (
					coordinatesAreBetweenIndices(coordinates, 0, GRID_SIZE) &&
					!newCoordinatesHaveATask
				) {
					moveTaskToNewCoords(
						state,
						state.draggedTaskOriginalCords,
						coordinates,
					);

					const event = TaskChangedCoordinatesEvent({
						coordinates,
						taskId: state.cells[coordinates.row][coordinates.column].id,
					});
					this.dispatchEvent(event);
				} else {
					console.error("Cant move task to cords:", coordinates);
				}
			} else if (state.mode === "createConnection") {
				const canvasPos = canvas.getBoundingClientRect();
				const mousePosOnCanvas = fromScreenPosToCanvasPos(
					{
						x: ev.clientX,
						y: ev.clientY,
					},
					{
						x: canvasPos.left,
						y: canvasPos.top,
					},
					state.scale,
					state.translatePosition,
				);
				const coordinates = fromCanvasPosToCellCords(
					mousePosOnCanvas,
					MINIFIED_VIEW.griddOffset,
					MINIFIED_VIEW.cellSize,
					MINIFIED_VIEW.cellSize,
				);
				const { row, column } = coordinates;

				const newCoordinatesHaveATask = state.cells[row]?.[column];

				if (cellCoordsAreEqual(coordinates, state.draggedTaskOriginalCords)) {
					const taskId = state.cells[row][column].id;
					const event = DeleteTaskEvent({
						taskId,
					});
					this.dispatchEvent(event);

					state.cells[row][column] = undefined;
					const cords = scaleCoords(coordinates, 2);
					state.connections = state.connections.filter(
						(conn) =>
							!cellCoordsAreEqual(conn.start, cords) &&
							!cellCoordsAreEqual(conn.end, cords),
					);
				} else if (coordinatesAreBetweenIndices(coordinates, 0, GRID_SIZE)) {
					const { existingConnection, index } = findConnection(
						state,
						scaleCoords(state.draggedTaskOriginalCords, 2),
						scaleCoords(coordinates, 2),
					);

					if (!newCoordinatesHaveATask) {
						const taskData = createDefaultTask(
							state.futureTaskIcon,
							state.projectId,
							coordinates,
						);

						state.cells[row][column] = taskData;

						const event = CreateTaskEvent({
							project_id: state.projectId,
							parent_id: null,
							icon: taskData.icon,
						});

						this.dispatchEvent(event);
					} else if (existingConnection) {
						state.connections.splice(index, 1);
						let { start, end } = existingConnection;
						start = scaleCoords(start, 0.5);
						end = scaleCoords(end, 0.5);

						const event = DeleteConnectionEvent({
							originTaskId: state.cells[start.row][start.column].id,
							targetTaskId: state.cells[end.row][end.column].id,
						});
						this.dispatchEvent(event);
					} else {
						createConnectionBetweenCords(
							state,
							state.draggedTaskOriginalCords,
							coordinates,
						);

						const originTaskId =
							state.cells[state.draggedTaskOriginalCords.row][
								state.draggedTaskOriginalCords.column
							].id;
						const targetTaskId =
							state.cells[coordinates.row][coordinates.column].id;
						const event = CreateConnectionEvent({
							originTaskId,
							targetTaskId,
						});
						this.dispatchEvent(event);
					}
				}
			}

			state.mouseDown = false;
			state.mode = "none";
			drawCanvas(canvas, this.getState());
		});

		canvas.addEventListener("mouseover", () => {
			state.mouseDown = false;
			state.mode = "none";
		});
		canvas.addEventListener("mouseout", () => {
			state.mouseDown = false;
			state.mode = "none";
		});

		canvas.addEventListener("contextmenu", (ev) => {
			ev.preventDefault();
		});

		canvas.addEventListener("mousemove", (ev) => {
			if (state.mouseDown && state.mode === "dragGrid") {
				state.translatePosition.x = ev.clientX - state.startDragOffset.x;
				state.translatePosition.y = ev.clientY - state.startDragOffset.y;

				drawCanvas(canvas, this.getState());
			} else if (state.mouseDown && state.mode === "dragTask") {
				const canvasPos = canvas.getBoundingClientRect();

				state.hoverPos = fromScreenPosToCanvasPos(
					// state.taskTranslatePosition = fromScreenPosToCanvasPos(
					{
						x: ev.clientX,
						y: ev.clientY,
					},
					{
						x: canvasPos.left,
						y: canvasPos.top,
					},
					state.scale,
					state.translatePosition,
				);

				drawCanvas(canvas, this.getState());
			} else {
				const canvasPos = canvas.getBoundingClientRect();
				const mousePosOnCanvas = fromScreenPosToCanvasPos(
					{
						x: ev.clientX,
						y: ev.clientY,
					},
					{
						x: canvasPos.left,
						y: canvasPos.top,
					},
					state.scale,
					state.translatePosition,
				);

				state.hoverPos = mousePosOnCanvas;
				drawCanvas(canvas, this.getState());
			}
		});

		canvas.addEventListener("wheel", (ev) => {
			state.scale -= ev.deltaY * 1e-3;
			state.scale = clamp(state.scale, 1, 4);
			drawCanvas(canvas, this.getState());
		});
	}
}

/**
 * @param {import("./types").SenkuCanvasState} state
 * @param {import("./types").CellCoord} originalCords
 * @param {import("./types").CellCoord} newCords
 */
function moveTaskToNewCoords(state, originalCords, newCords) {
	const { row, column } = originalCords;
	for (const conn of state.connections) {
		if (conn.start.row === row * 2 && conn.start.column === column * 2) {
			conn.start = {
				row: newCords.row * 2,
				column: newCords.column * 2,
			};
		}

		if (conn.end.row === row * 2 && conn.end.column === column * 2) {
			conn.end = {
				row: newCords.row * 2,
				column: newCords.column * 2,
			};
		}
	}

	state.cells[row][column].coordinates = newCords;
	state.cells[newCords.row][newCords.column] = structuredClone(
		state.cells[row][column],
	);
	state.cells[row][column] = undefined;
}

/**
 * @param {import("./types").SenkuCanvasState} state
 * @param {import("./types").CellCoord} originalCords
 * @param {import("./types").CellCoord} newCords
 */
function createConnectionBetweenCords(state, originalCords, newCords) {
	state.connections.push({
		start: {
			row: originalCords.row * 2,
			column: originalCords.column * 2,
		},

		end: {
			row: newCords.row * 2,
			column: newCords.column * 2,
		},
	});
}

/**
 * @param {string} icon
 * @param {number} projectId
 * @param {import("./types").CellCoord} cellCords
 * @returns {import("./types").TaskData}
 */
function createDefaultTask(icon, projectId, cellCords) {
	return {
		id: lastTaskId++,
		icon,
		title: "",
		projectId,
		parent_id: null,
		progress: 0.0,
		coordinates: cellCords,
	};
}

/**
 * @param {import("./types").SenkuCanvasState} state
 * @param {import("./types").CellCoord} cordsA
 * @param {import("./types").CellCoord} cordsB
 * @returns {{existingConnection: import("./types").TaskConnection, index: number}}
 */
function findConnection(state, cordsA, cordsB) {
	const index = state.connections.findIndex((conn) => {
		return (
			(cellCoordsAreEqual(conn.start, cordsA) &&
				cellCoordsAreEqual(conn.end, cordsB)) ||
			(cellCoordsAreEqual(conn.start, cordsB) &&
				cellCoordsAreEqual(conn.end, cordsA))
		);
	});
	const existingConnection = state.connections[index];
	return { index, existingConnection };
}

export const SenkuCanvasComponent = {
	register() {
		window.customElements.define(TAG_NAME, SenkuCanvas);
	},
};
