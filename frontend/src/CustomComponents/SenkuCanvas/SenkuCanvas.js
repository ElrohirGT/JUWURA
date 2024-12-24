import { clamp, lerpColor3 } from "../../Utils/math";

/**
 * @typedef {Object} TaskData
 * @property {Date} due_date
 * @property {String} title
 * @property {String} status
 * @property {String} icon
 * @property {number} progress
 */

const CELL_SIZE = 100;
const CELL_PADDING = CELL_SIZE * 0.15;

const GRID_OFFSET = 10;
const GRID_LINES_COLOR = "#515151";

const TASK_BACKGROUND = "#6e6e6e";
const TASK_ICON_PADDING = CELL_PADDING;

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

				this.drawCanvas(canvas, this.getAttribute("zoom") ?? 1, { x: 0, y: 0 });
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
	 * @param {number} scale - How much scale do we need? Value between 1 and 2.
	 * @param {{x:number, y:number}} translatePos - The position inside the drawing the center of the canvas should be.
	 */
	drawCanvas(canvas, scale, translatePos) {
		console.log("Drawing canvas with scale:", scale);

		const ctx = canvas.getContext("2d");
		ctx.clearRect(0, 0, canvas.offsetWidth, canvas.offsetHeight);
		ctx.save();

		ctx.scale(scale, scale);
		ctx.translate(translatePos.x, translatePos.y);

		ctx.strokeStyle = GRID_LINES_COLOR;
		ctx.lineWidth = 1;

		for (let x = -GRID_OFFSET; x < canvas.offsetWidth; x += CELL_SIZE) {
			for (let y = -GRID_OFFSET; y < canvas.offsetHeight; y += CELL_SIZE) {
				ctx.strokeRect(x, y, CELL_SIZE, CELL_SIZE);
			}
		}

		this.drawMinifiedTask(ctx, { icon: "😎", progress: 0.9 }, 1, 1);
		ctx.restore();
	}

	/**
	 * @param {CanvasRenderingContext2D} ctx
	 * @param {TaskData} taskData
	 * @param {number} column
	 * @param {number} row
	 */
	drawMinifiedTask(ctx, taskData, column, row) {
		const topLeft = {
			x: CELL_SIZE * column + CELL_PADDING - GRID_OFFSET,
			y: CELL_SIZE * row + CELL_PADDING - GRID_OFFSET,
		};
		const dimensions = {
			width: CELL_SIZE - CELL_PADDING * 2,
			height: CELL_SIZE - CELL_PADDING * 2,
		};

		const bottomLeft = {
			x: topLeft.x,
			y: topLeft.y + dimensions.height,
		};

		// DRAW BACKGROUND TASK
		ctx.fillStyle = TASK_BACKGROUND;
		ctx.fillRect(topLeft.x, topLeft.y, dimensions.width, dimensions.height);

		// DRAW EMOJI
		const emojiSize = dimensions.width - TASK_ICON_PADDING * 2;
		ctx.font = `${emojiSize}px Parkinsans`;
		ctx.textBaseline = "top";
		ctx.fillText(
			taskData.icon,
			topLeft.x + TASK_ICON_PADDING,
			topLeft.y + TASK_ICON_PADDING,
		);

		// DRAW PROGRESS
		const red_500 = [202, 50, 61];
		const yellow = [200, 119, 49];
		const green = [75, 106, 55];
		const interpolated = lerpColor3(red_500, yellow, green, taskData.progress);
		const barHeight = dimensions.height * 0.1;
		ctx.fillStyle = `rgb(${interpolated[0]}, ${interpolated[1]}, ${interpolated[2]})`;
		ctx.fillRect(
			bottomLeft.x,
			bottomLeft.y - barHeight,
			dimensions.width * taskData.progress,
			dimensions.height * 0.1,
		);
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

		let scale = this.getAttribute("zoom") ?? 1;
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
				this.drawCanvas(canvas, scale, translatePos);
			}
		});

		canvas.addEventListener("wheel", (ev) => {
			scale -= ev.deltaY * 1e-3;
			scale = clamp(scale, 1, 4);
			this.drawCanvas(canvas, scale, translatePos);
		});
	}
}

export const SenkuCanvasComponent = {
	register() {
		window.customElements.define("uwu-senku", SenkuCanvas);
	},
};
