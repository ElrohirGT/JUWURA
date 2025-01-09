/**
 * @typedef {Object} ElmWSConnectMessage
 * @property {"CONNECT"} type
 * @property {number} projectId
 * @property {string} email
 */

/**
 * @typedef {Object} ElmWSGetSenkuStateMessage
 * @property {"GET_SENKU_STATE"} type
 * @property {{get_senku_state: {project_id: number}}} payload
 */

/**
 * @typedef {ElmWSConnectMessage|ElmWSGetSenkuStateMessage} ElmWSMessage
 */

export function initializeWsPorts(app) {
	/** @type {string|WebSocket}*/
	let socket = "UNITILIAZED WEB SOCKET";

	/**
	* @param {{data: string}} event
	*/
	const sendDataToElm = (event) => {
		console.log("RECEIVED MSG FROM WESOCKET:", event.data);
		app.ports.wsMessageReceiver.send(event.data);
		// app.ports.wsMessageReceiver.send(JSON.stringify({ hello: "INVALID!" }));
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
				try {
					socket = new WebSocket(url);
					socket.addEventListener("message", sendDataToElm);
					socket.addEventListener("error", () => {
						if (socket.readyState === 3) {
							console.error("CANT ESTABLISH CONNECTION!");
							sendDataToElm({
								data: JSON.stringify({ connection_error: null }),
							});
						}
					});
				} catch (err) {}
			} else if (message.type === "GET_SENKU_STATE") {
				socket.send(message.payload);
			}
		},
	);
}
