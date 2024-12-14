import { describe, test, expect } from "vitest";
import { API_HOST, generateClient } from "../jsLib/ws.js";

function genURL(email, projectId) {
	return encodeURI(`${API_HOST}?email=${email}&projectId=${projectId}`);
}

describe("Websocket Implementation tests", () => {
	test("Can connect successfully", async () => {
		// FIXME: Once auth is implemented this should be updated!
		// The WS socket should check if the user is authenticated...

		const projectId = 1;
		const clientEmail1 = "correo1@gmail.com";
		const clientEmail2 = "correo2@gmail.com";

		const client1 = await generateClient(genURL(clientEmail1, projectId));
		const promise = new Promise((res, rej) => {
			let msgs = [];
			client1.configureHandlers(rej, (ev) => {
				/**@type {string}*/
				const data = ev.utf8Data;
				if (data.includes("joined the ws for project")) {
					msgs.push(data);
				}

				if (msgs.length === 2) {
					res(msgs);
				}
			});
		});

		// Connect a second client...
		await generateClient(genURL(clientEmail2, projectId));

		const response = await promise;
		const expected = [
			`${clientEmail1} joined the ws for project ${projectId}.`,
			`${clientEmail2} joined the ws for project ${projectId}.`,
		];
		expect(response).toStrictEqual(expected);
	});

	test("Malformed message error", async () => {
		const client = await generateClient(genURL("correo1@gmail.com", 1));
		const promise = new Promise((res, rej) => {
			client.configureHandlers(rej, (rev) => {
				try {
					const response = JSON.parse(rev.utf8Data);
					if (response.err) {
						res(response);
					}
				} catch {}
			});

			client.send(JSON.stringify({ h: "abcd" }));
		});

		const response = await promise;
		expect(response.err).toBe("MalformedMessage");
	});

	test("Can't connect unless an email is provided", async () => {
		const email = "";

		await expect(() =>
			generateClient(genURL(email, "1")).rejects.toThrowError(),
		);
		await expect(() =>
			generateClient(genURL(undefined, "1")).rejects.toThrowError(),
		);
	});

	test("Can't connect unless a project id is provided", async () => {
		const projectId = "";

		await expect(() =>
			generateClient(
				genURL("correo1@gmail.com", projectId),
			).rejects.toThrowError(),
		);
		await expect(() =>
			generateClient(
				genURL("correo1@gmail.com", undefined),
			).rejects.toThrowError(),
		);
	});
});
