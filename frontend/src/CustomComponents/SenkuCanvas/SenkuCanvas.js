import { clamp } from "../../Utils/math";
import { drawCanvas } from "./render";
import { GRID_SIZE } from "./render";

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

	genHorizontalStraight(cells, connections);
	genSmallDiagonal(cells, connections);
	genBigDiagonal(cells, connections);
	genObstacle(cells, connections);

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

				drawCanvas(
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

	getState() {
		// TODO: This should be computed from a property in JS
		return generateDummyData();
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
			console.log(mouseDown);
			if (mouseDown) {
				translatePos.x = ev.clientX - startDragOffset.x;
				translatePos.y = ev.clientY - startDragOffset.y;
				drawCanvas(canvas, this.getState(), scale, translatePos);
			} else {
				const canvasPos = canvas.getBoundingClientRect();
				const mousePosOnCanvas = {
					x: (ev.clientX - canvasPos.left) / scale - translatePos.x,
					y: (ev.clientY - canvasPos.top) / scale - translatePos.y,
				};

				drawCanvas(
					canvas,
					this.getState(),
					scale,
					translatePos,
					mousePosOnCanvas,
				);
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
		window.customElements.define("uwu-senku", SenkuCanvas);
	},
};
