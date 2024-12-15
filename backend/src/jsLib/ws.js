import { client as ClientGenerator, connection } from "websocket";

export const API_HOST = "ws://127.0.0.1:3000";

export function genURL(email, projectId) {
	return encodeURI(`${API_HOST}?email=${email}&projectId=${projectId}`);
}

export async function generateClient(email, projectId) {
	const url = genURL(email, projectId);
	const wrapper = new Promise((res, rej) => {
		const generator = new ClientGenerator();
		generator.on("connect", (client) => {
			res(client);
		});
		generator.on("connectFailed", (err) => {
			rej(err);
		});

		generator.connect(url);
	});

	/**@type {connection}*/
	const client = await wrapper;

	client.on("message", (ev) => {
		console.info(`[${email}] Received message:`, ev);
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
