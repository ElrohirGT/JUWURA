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
					const data = JSON.parse(ev.toString());
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
					const response = JSON.parse(rev);
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

	// NOTE: Tested this behaviour manually and it worked!
	// But when I tried making an automated test it fails because the handlers seem to not be called!
	//
	test.only("Messages dont get shared across projects", async () => {
		const project1Client = await generateClient("correo1@gmail.com", 1);
		const project2Client = await generateClient("correo2@gmail.com", 2);

		const promise = new Promise((res, rej) => {
			const project1Msgs = [];
			const project2Msgs = [];

			project1Client.configureHandlers(rej, (rev) => {
				try {
					const data = JSON.parse(rev);
					if (data.user_connected) {
						project1Msgs.push(data);
					}

					console.log("Project 1", project1Msgs.length, project2Msgs.length);
					if (project1Msgs.length === 1 && project2Msgs.length === 1) {
						res({ p1: project1Msgs, p2: project2Msgs });
					}
				} catch {}
			});

			project2Client.configureHandlers(rej, (rev) => {
				try {
					const data = JSON.parse(rev);
					if (data.user_connected) {
						project2Msgs.push(data);
					}

					console.log("Project 2", project1Msgs.length, project2Msgs.length);
					if (project1Msgs.length === 1 && project2Msgs.length === 1) {
						res({ p1: project1Msgs, p2: project2Msgs });
					}
				} catch {}
			});
		});

		const msgsByProject = await promise;
		const p1Msgs = msgsByProject.p1;
		expect(p1Msgs).toStrictEqual([{ user_connected: "correo1@gmail.com" }]);

		const p2Msgs = msgsByProject.p2;
		expect(p2Msgs).toStrictEqual([{ user_connected: "correo2@gmail.com" }]);

		project1Client.close();
		project2Client.close();
	}, 10_000);

	test("Malformed message error", async () => {
		const client = await generateClient("correo1@gmail.com", 1);
		const promise = new Promise((res, rej) => {
			client.configureHandlers(rej, (rev) => {
				try {
					const response = JSON.parse(rev);
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
