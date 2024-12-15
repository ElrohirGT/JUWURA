import { describe, test, expect } from "vitest";
import { generateClient } from "../../jsLib/ws.js";

describe.sequential("Websocket Implementation tests", () => {
	test("Can connect successfully", async () => {
		// FIXME: Once auth is implemented this should be updated!
		// The WS socket should check if the user is authenticated...

		const projectId = 1;
		const clientEmail1 = "correo1@gmail.com";
		const clientEmail2 = "correo2@gmail.com";

		const client1 = await generateClient(clientEmail1, projectId);
		const promise = new Promise((res, rej) => {
			const msgs = [];
			client1.configureHandlers(rej, (ev) => {
				try {
					const data = JSON.parse(ev.utf8Data);
					if (data.user_connected) {
						msgs.push(data);
					}

					if (msgs.length === 2) {
						res(msgs);
					}
				} catch {}
			});
		});

		// Connect a second client...
		const client2 = await generateClient(clientEmail2, projectId);
		client2.close();

		const expectedResponse = {
			user_connected: expect.any(String),
		};

		const responseMessages = await promise;
		for (const message of responseMessages) {
			expect(message).toEqual(expectedResponse);
		}

		client1.close();
	});

	test("Can close connections", async () => {
		const client = await generateClient("correo1@gmail.com", 1);
		const promise = new Promise((res, rej) => {
			client.configureHandlers(rej, (rev) => {
				try {
					const response = JSON.parse(rev.utf8Data);
					if (response.user_disconnected) {
						res(response);
					}
				} catch {}
			});
		});

		const client2 = await generateClient("correo2@gmail.com", 1);
		client2.close();

		const response = await promise;

		const expectedResponse = {
			user_disconnected: expect.any(String),
		};
		expect(response).toEqual(expectedResponse);
		expect(response.user_disconnected).toBe("correo2@gmail.com");

		client.close();
	});

	test("Malformed message error", async () => {
		const client = await generateClient("correo1@gmail.com", 1);
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

		client.close();
	});

	test("Can't connect unless an email is provided", async () => {
		const email = "";

		await expect(() => generateClient(email, "1").rejects.toThrowError());
		await expect(() => generateClient(undefined, "1").rejects.toThrowError());
	});

	test("Can't connect unless a project id is provided", async () => {
		const projectId = "";

		await expect(() =>
			generateClient("correo1@gmail.com", projectId).rejects.toThrowError(),
		);
		await expect(() =>
			generateClient("correo1@gmail.com", undefined).rejects.toThrowError(),
		);
	});
});
