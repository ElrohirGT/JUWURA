// From:
// https://discourse.elm-lang.org/t/how-to-incorporate-a-string-of-html-mark-up/8610/4
class Icon extends HTMLElement {
	constructor() {
		super();
		const shadowRoot = this.attachShadow({ mode: "open" });
		this.render = () => {
			shadowRoot.innerHTML = this.content;
		};
	}
	get content() {
		return this.getAttribute("content") || "";
	}

	set content(val) {
		this.shadowRoot.innerHtml = val;
	}

	static get observedAttributes() {
		return ["content"];
	}

	connectedCallback() {
		this.render();
	}

	attributeChangedCallback() {
		this.render();
	}
}

window.customElements.define("uwu-icon", Icon);
