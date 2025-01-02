import { clamp } from "../../Utils/math";
import { CreateTaskEvent } from "./events";
import { ADD_BTN_RADIUS, drawCanvas, MINIFIED_VIEW } from "./render";
import { GRID_SIZE } from "./render";
import {
	canvasPosInsideCircle,
	canvasPosInsideRectangle,
	fromCanvasPosToCellCords,
	fromScreenPosToCanvasPos,
} from "./utils";

export const TAG_NAME = "uwu-senku";

const SCALE_DIMENSIONS = {
	min: 1,
	max: 4,
};

let lastTaskId = 0;
/**
 * @param {string} [title="Test Title"] - The title of the task
 * @returns {TaskData}
 */
function createTask(
	title = "MMM MMM MMMMMMM MMMM MMM MMMMMMMM MMM MM MMMMMM MMMM MMM MMMMMMMM",
) {
	return {
		id: lastTaskId++,
		title,
		icon: "😎",
		progress: 0.7,
		status: {
			name: "ON HOLD",
			color: "#3b5083",
		},
		due_date: new Date(),
	};
}

function genHorizontalStraight(cells, connections) {
	cells[0][0] = createTask();
	cells[0][5] = createTask();

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
	cells[1][1] = createTask();
	cells[2][2] = createTask();

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
	cells[3][3] = createTask();
	cells[8][8] = createTask();

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
	cells[3][4] = createTask();
	cells[3][7] = createTask();
	cells[3][8] = createTask();

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
		scale: SCALE_DIMENSIONS.min,
		translatePosition: { x: 0, y: 0 },
		startDragOffset: { x: 0, y: 0 },
		mouseDown: false,
		mode: "none",
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
			const debug = true;

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

			const { row, column } = fromCanvasPosToCellCords(
				mousePosOnCanvas,
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

			if (debug) {
				const ctx = canvas.getContext("2d");
				ctx.fillStyle = "red";
				ctx.fillRect(mousePosOnCanvas.x, mousePosOnCanvas.y, 5, 5);

				ctx.fillStyle = "purple";
				ctx.fillRect(cellTopLeft.x, cellTopLeft.y, 5, 5);
			}

			const indicesInRange =
				row >= 0 && row < GRID_SIZE && column >= 0 && column < GRID_SIZE;
			const clickedOnATaskCell = state.cells[row] && state.cells[row][column];
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
				const event = CreateTaskEvent({
					project_id: state.projectId,
					parent_id: null,
					icon: "💀",
				});
				this.dispatchEvent(event);
			} else if (clickedOnATask) {
			} else {
				state.mode = "drag";
				state.startDragOffset.x = ev.clientX - state.translatePosition.x;
				state.startDragOffset.y = ev.clientY - state.translatePosition.y;
			}
		});
		canvas.addEventListener("mouseup", () => {
			state.mouseDown = false;
			state.mode = "none";
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
			if (state.mouseDown && state.mode === "drag") {
				state.translatePosition.x = ev.clientX - state.startDragOffset.x;
				state.translatePosition.y = ev.clientY - state.startDragOffset.y;

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
				state.hoverPos = undefined;
			}
		});

		canvas.addEventListener("wheel", (ev) => {
			scale -= ev.deltaY * 1e-3;
			scale = clamp(scale, 1, 4);
			drawCanvas(canvas, this.getState(), scale, translatePos);
		});
	}
}

export const SenkuCanvasComponent = {
	register() {
		window.customElements.define(TAG_NAME, SenkuCanvas);
	},
};
