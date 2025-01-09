/**
 * @typedef {Object} ElmWSConnectMessage
 * @property {"CONNECT"} type
 * @property {number} projectId
 * @property {string} email
 */

/**
 * @typedef {ElmWSConnectMessage} ElmWSMessage
 */

export function initializeWsPorts(app) {
	/** @type {string|WebSocket}*/
	let socket = "UNITILIAZED WEB SOCKET";

	const sendDataToElm = (event) => {
		console.log("RECEIVED MSG FROM WESOCKET:", event.data);
		app.ports.wsMessageReceiver.send(event.data);
	};

	app.ports.wsSendMessage.subscribe(
		/** @param {ElmWSMessage} message */
		(message) => {
			console.log("RECEIVED MSG FROM PORT:", message);

			if (message.type === "CONNECT") {
				if (socket.addEventListener) {
					console.error("Connect received while socket is already connected!");
					throw new Error("Socket is already connected!");
				}

				const url = `${import.meta.env.VITE_BACKEND_URL}?email=${message.email}&projectId=${message.projectId}`;
				console.log("Trying to connect to url:", url);
				socket = new WebSocket(url);
				socket.addEventListener("message", sendDataToElm);
			}
		},
	);
}
