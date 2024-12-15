import { expect, describe, test, beforeEach } from "vitest";
import { generateClient } from "../../jsLib/ws";
import { createTask } from "../../jsLib/testHelpers/tasks";
import { createProject } from "../../jsLib/testHelpers/projects.js";

describe("Create Task test suite", () => {
	let projectId = 0;

	beforeEach(async () => {
		projectId = await createProject(
			"correo3@gmail.com",
			"CREATE TASK TEST SUITE PROJECT",
			"😀",
			"https://img.freepik.com/free-photo/painting-mountain-lake-with-mountain-background_188544-9126.jpg",
			["correo1@gmail.com", "correo2@gmail.com"],
		);
	});

	test("Can create a task", async () => {
		const email = "correo1@gmail.com";
		const type = "EPIC";
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

		const client1 = await generateClient("correo1@gmail.com", projectId);
		const client2 = await generateClient("correo2@gmail.com", projectId);

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
		});
		await client1.send(JSON.stringify(erroneousPayload));
		await client1.close();
		await client2.close();

		/**@type{[any[], any[]]}*/
		const [c1Msgs, c2Msgs] = await promise;

		let foundError = false;
		for (const msg of c1Msgs) {
			if (msg.err === "CreateTaskError") {
				foundError = true;
			}
		}

		if (!foundError) {
			console.error("Client 1 MSGs:", c1Msgs);
			throw new Error("No error found on messages of the first client!");
		}

		foundError = false;
		for (const msg of c2Msgs) {
			if (msg.err === "CreateTaskError") {
				foundError = true;
			}
		}

		if (foundError) {
			console.error("Client 2 MSGs:", c2Msgs);
			throw new Error("Error found on messages of the second client!");
		}
	});

	test("Create task response is sent to all connected clients", async () => {
		const payload = {
			create_task: {
				task_type: "EPIC",
				project_id: projectId,
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
