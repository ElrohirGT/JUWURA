import { expect, describe, test } from "vitest";
import { generateClient } from "../../jsLib/ws";
import { createTask } from "../../jsLib/testHelpers/tasks";

describe.sequential("Create Task test suite", () => {
	test("Can create a task", async () => {
		const email = "correo1@gmail.com";
		const type = "EPIC";
		const projectId = 1;

		const taskId = await createTask(email, type, projectId);

		expect(taskId).toEqual(expect.any(Number));
	});

	test("Create task error is sent only to request client", async () => {
		const erroneousPayload = {
			create_task: {
				task_type: "EPIC",
				project_id: 0, // This ID doesn't exists
			},
		};

		const client1 = await generateClient("correo1@gmail.com", 1);

		const client2 = await generateClient("correo2@gmail.com", 2);

		const promise = new Promise((res, rej) => {
			const client2Msgs = [];
			const client1Msgs = [];

			setTimeout(() => {
				res([client1Msgs, client2Msgs]);
			}, 4500);

			client1.configureHandlers(rej, (rev) => {
				try {
					const data = JSON.parse(rev.toString());
					client1Msgs.push(data);
				} catch {}
			});

			client2.configureHandlers(rej, (rev) => {
				try {
					const data = JSON.parse(rev.toString());
					client2Msgs.push(data);
				} catch {}
			});

			client1.send(JSON.stringify(erroneousPayload));
			client1.close();
			client2.close();
		});

		/**@type{[any[], any[]]}*/
		const [c1Msgs, c2Msgs] = await promise;

		expect(c1Msgs.length).toBe(2);
		expect(c2Msgs.length).toBe(1);

		expect(c1Msgs).toStrictEqual([
			{ user_connected: "correo1@gmail.com" },
			{ err: "CreateTaskError" },
		]);
		expect(c2Msgs).toStrictEqual([{ user_connected: "correo2@gmail.com" }]);
	});

	test("Create task response is sent to all connected clients", async () => {
		const payload = {
			create_task: {
				task_type: "EPIC",
				project_id: 1,
			},
		};

		const client1 = await generateClient(
			"correo1@gmail.com",
			payload.create_task.project_id,
		);
		const client2 = await generateClient(
			"correo2@gmail.com",
			payload.create_task.project_id,
		);

		const client1Waiter = new Promise((res, rej) => {
			client1.configureHandlers(rej, (rev) => {
				try {
					const response = JSON.parse(rev);
					if (response.create_task) {
						res(response);
					}
				} catch {}
			});
		});
		const client2Waiter = new Promise((res, rej) => {
			client2.configureHandlers(rej, (rev) => {
				try {
					const response = JSON.parse(rev);
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
					due_date: null,
					name: null,
					priority: null,
					sprint: null,
					status: null,
				},
			},
		};

		for (const response of responses) {
			// console.log("SERVER:", response, "EXPECTED:", expectedResponse);
			// console.log("EXPECTED: ", response);
			expect(response).toEqual(expectedResponse);

			const { task } = response.create_task;
			expect(task.type).toEqual(payload.create_task.task_type);
			expect(task.project_id).toEqual(payload.create_task.project_id);
		}
	}, 7000);
});
