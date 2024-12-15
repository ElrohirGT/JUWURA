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
 * @property {(message: string)=>Promise<void>} send - Sends a message in the connection
 * @property {()=>Promise<void>} close - Closes the websocket connection.
 * @property {(onError: OnErrorCallback, onMesage: OnMessageCallback) => void} configureHandlers - Configures the handlers of the connection
 */

/**
 * @param {string} email - The email of the user that tries to connect
 * @param {number} projectId - The ID of the project to connect to
 * @returns {Promise<WSConnection>} - The client to connect to
 */
export async function generateClient(email, projectId) {
	const url = genURL(email, projectId);
	console.log("Connecting to:", url);
	const client = new WebSocket(url, {});

	let rejected = undefined;
	const isConnectedPromise = new Promise((res, rej) => {
		rejected = rej;
		client.on("open", () => {
			res();
		});
		client.on("error", rej);
	});

	client.on("message", (ev) => {
		console.info(`[${email}] Received message:`, ev.toString());
	});

	client.on("error", (err) => {
		console.error("ERROR!", err);
	});

	return {
		send: async (message) => {
			await isConnectedPromise;
			client.off("error", rejected);
			console.info(`[${email}] Sending message:`, message);
			client.send(message);
		},

		close: async () => {
			await isConnectedPromise;
			client.off("error", rejected);
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
