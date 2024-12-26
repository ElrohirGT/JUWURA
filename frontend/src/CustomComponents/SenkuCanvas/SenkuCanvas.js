import { clamp } from "../../Utils/math";
import { lerpColor3 } from "../../Utils/color";
import { floatEquals } from "../../Utils/math";

/**
 * @typedef {Object} CellCoord
 * @property {number} column
 * @property {number} row
 */

/**
 * @typedef {"UP" | "DOWN" | "LEFT" | "RIGHT"} ConnectionDirection
 */

/**
 * @typedef {Object} ConnectionPoint
 * @property {CellCoord} cords
 * @property {ConnectionDirection} dir
 */

/**
 * @typedef {Object} TaskData
 * @property {Date} due_date
 * @property {String} title
 * @property {String} status
 * @property {String} icon
 * @property {number} progress
 */

/**
 * @typedef {Object} TaskConnection
 * @property {ConnectionPoint} start
 * @property {ConnectionPoint} end
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

/**
 * Generates dummy data for the graph
 * @returns {SenkuCanvasState}
 */
function generateDummyData() {
	/** @type {Cells}*/
	const cells = [];
	for (let i = 0; i < GRID_SIZE; i++) {
		cells.push([]);
		for (let j = 0; j < GRID_SIZE; j++) {
			cells[i].push(undefined);
		}
	}
	cells[0][0] = { icon: "😎", progress: 1.0 };
	cells[0][2] = { icon: "😎", progress: 1.0 };

	return {
		cells,
		connections: [
			{
				start: {
					row: 0,
					column: 0,
				},
				end: {
					row: 0,
					column: 0,
				},
			},
		],
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
					this.getAttribute("zoom") ?? SCALE_DIMENSIONS.max,
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

		ctx.restore();
	}

	getState() {
		// TODO: This should be computed from a property in JS
		return generateDummyData();
	}

	/**
	 * @param {CanvasRenderingContext2D} ctx
	 * @param {TaskConnection} connInfo
	 */
	drawTaskConnection(ctx, connInfo) {
		const { start, end } = connInfo;
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

export const SenkuCanvasComponent = {
	register() {
		window.customElements.define("uwu-senku", SenkuCanvas);
	},
};
