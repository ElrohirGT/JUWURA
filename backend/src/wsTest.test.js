import { describe, test, expect } from "vitest";
import { generateClient } from "./jsLib/ws";

describe("Websocket tests", () => {
	test("Echo chat", async () => {
		const payload = "Hola!";

		const promise = new Promise(async (res, rej) => {
			const client = await generateClient("wss://echo.websocket.org");
			client.configureHandlers(rej, (ev) => {
				if (ev.utf8Data === payload) {
					res(ev.utf8Data);
				}
			});

			client.send(payload);
		});

		const response = await promise;
		expect(response).toBe(payload);
	});
});
