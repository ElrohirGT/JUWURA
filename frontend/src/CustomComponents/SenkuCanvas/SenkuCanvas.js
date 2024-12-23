class SenkuCanvas extends HTMLElement {
	static observedAttributes = ["widthPct", "heightPct", "zoom"];

	constructor() {
		super();
	}

	/**
	 * Function that runs when the element is added to the page.
	 */
	connectedCallback() {
		console.log("Custom element added to page.");

		const shadow = this.attachShadow({ mode: "open" });
		const canvas = document.createElement("canvas");
		canvas.width =
			(this.getAttribute("widthPct") / 100) * document.body.offsetWidth;
		canvas.height =
			(this.getAttribute("heightPct") / 100) * document.body.offsetHeight;

		const ctx = canvas.getContext("2d");

		ctx.fillStyle = "rgb(200 0 0)";
		ctx.fillRect(10, 10, 50, 50);

		ctx.fillStyle = "rgb(0 0 200 / 50%)";
		ctx.fillRect(30, 30, 50, 50);

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
		console.log(`Attribute ${name} has changed.`);
	}
}

window.customElements.define("uwu-senku", SenkuCanvas);
