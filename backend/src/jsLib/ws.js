import WebSocket from "ws";

export const API_HOST = "ws://127.0.0.1:3000";

export function genURL(email, projectId) {
	return encodeURI(`${API_HOST}?email=${email}&projectId=${projectId}`);
}

/**
 * @callback OnErrorCallback
 */

/**
 * @callback OnMessageCallback
 * @param {WebSocket.RawData} message - The message to send in the websocket
 */

/**
 * @typedef {Object} WSConnection
 * @property {(message: string)=>void} send - Sends a message in the connection
 * @property {()=>void} close - Closes the websocket connection.
 * @property {(onError: OnErrorCallback, onMesage: OnMessageCallback) => void} configureHandlers - Configures the handlers of the connection
 */

/**
 * @param {string} email - The email of the user that tries to connect
 * @param {number} projectId - The ID of the project to connect to
 * @returns {Promise<WSConnection>} - The client to connect to
 */
export async function generateClient(email, projectId) {
	const url = genURL(email, projectId);
	let rejected = null;
	const wrapper = new Promise((res, rej) => {
		rejected = rej;

		console.log("Connecting to:", url);
		const ws = new WebSocket(url);
		ws.on("open", () => {
			res(ws);
		});
		ws.on("error", rej);
	});

	/**@type {WebSocket}*/
	const client = await wrapper;
	client.off("error", rejected);

	client.on("message", (ev) => {
		console.info(`[${email}] Received message:`, ev.toString());
	});

	client.on("error", (err) => {
		console.error("ERROR!", err);
	});

	return {
		send: (message) => {
			client.send(message);
		},

		close: () => {
			client.close();
		},

		configureHandlers: (onError, onMessage) => {
			client.removeListener("message", onMessage);
			client.on("message", onMessage);

			client.removeListener("error", onError);
			client.on("error", onError);
		},
	};
}
