import { client as ClientGenerator, connection } from "websocket";

export async function generateClient(url) {
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
		console.info("Received message:", ev);
	});

	client.on("error", (err) => {
		console.error("ERROR!", err);
	});

	return {
		send: (message) => {
			client.send(message);
		},

		configureHandlers: (onError, onMessage) => {
			client.removeListener("message", onMessage);
			client.on("message", onMessage);

			client.removeListener("error", onError);
			client.on("error", onError);
		},
	};
}
