import { expect, describe, test } from "vitest";
import { generateClient, genURL } from "../../jsLib/ws";

describe("Create Task test suite", () => {
	test("Can create a task", async () => {
		const payload = {
			create_task: {
				task_type: "EPIC",
				project_id: 1,
			},
		};
		const client = await generateClient(
			genURL("correo1@gmail.com", payload.create_task.project_id),
		);

		const promise = new Promise((res, rej) => {
			client.configureHandlers(rej, (rev) => {
				try {
					const response = JSON.parse(rev.utf8Data);
					if (response.create_task) {
						res(response);
					}
				} catch {}
			});

			client.send(JSON.stringify(payload));
		});
		const response = await promise;

		const expectedResponse = {
			create_task: {
				task: {
					id: expect.any(Number),
					project_id: expect.any(Number),
					type: expect.any(String),
				},
			},
		};
		expect(response).toEqual(expectedResponse);

		const { task } = response.create_task;
		expect(task.type).toEqual(payload.create_task.task_type);
		expect(task.project_id).toEqual(payload.create_task.project_id);
	});

	test("Create task response is sent to all connected clients", async () => {
		const payload = {
			create_task: {
				task_type: "EPIC",
				project_id: 1,
			},
		};

		const client1 = await generateClient(
			genURL("correo1@gmail.com", payload.create_task.project_id),
		);
		const client2 = await generateClient(
			genURL("correo2@gmail.com", payload.create_task.project_id),
		);

		const client1Waiter = new Promise((res, rej) => {
			client1.configureHandlers(rej, (rev) => {
				try {
					const response = JSON.parse(rev.utf8Data);
					if (response.create_task) {
						res(response);
					}
				} catch {}
			});
		});
		const client2Waiter = new Promise((res, rej) => {
			client2.configureHandlers(rej, (rev) => {
				try {
					const response = JSON.parse(rev.utf8Data);
					if (response.create_task) {
						res(response);
					}
				} catch {}
			});
		});

		client1.send(JSON.stringify(payload));
		const responses = await Promise.all([client1Waiter, client2Waiter]);

		const expectedResponse = {
			create_task: {
				task: {
					id: expect.any(Number),
					project_id: expect.any(Number),
					type: expect.any(String),
				},
			},
		};

		for (const response of responses) {
			expect(response).toEqual(expectedResponse);

			const { task } = response.create_task;
			expect(task.type).toEqual(payload.create_task.task_type);
			expect(task.project_id).toEqual(payload.create_task.project_id);
		}
	});
});
