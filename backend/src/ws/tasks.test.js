import { expect, describe, test, beforeEach } from "vitest";
import {
	createTask,
	editTaskField,
	GRID_SIZE,
	updateTask,
} from "../jsLib/testHelpers/tasks.js";
import { createProject } from "../jsLib/testHelpers/projects.js";
import {
	errorOnlyOnSameClient,
	messageIsSentToAllClients,
} from "../jsLib/testHelpers/index.js";
import { randomInt } from "../jsLib/utils.js";
import { generateClient } from "../jsLib/ws.js";

// describe("Edit Task Field test suite", () => {
// 	const userEmail = "correo3@gmail.com";
// 	let projectId = 0;
// 	let taskId = 0;
//
// 	beforeEach(async () => {
// 		console.log("Creating project for test...");
// 		projectId = await createProject(
// 			userEmail,
// 			"UPDATE TASK TEST SUITE PROJECT",
// 			"😀",
// 			"https://img.freepik.com/free-photo/painting-mountain-lake-with-mountain-background_188544-9126.jpg",
// 			["correo1@gmail.com", "correo2@gmail.com"],
// 		);
// 		console.log("Created project with ID", projectId);
//
// 		console.log("Creating task for test...");
// 		taskId = await createTask(userEmail, projectId, null, "😀");
// 		console.log("Task created with ID", taskId);
// 	});
//
// 	test("Edit field of task", async () => {
// 		// FIXME: this test doesn't work!
// 		await editTaskField(userEmail, projectId, taskId, 1, )
// 	});
// });

describe("Change task Cords Test suite", () => {
	let projectId = 0;
	let taskId = 0;

	beforeEach(async () => {
		console.log("Creating project for test...");
		projectId = await createProject(
			"correo3@gmail.com",
			"UPDATE TASK TEST SUITE PROJECT",
			"😀",
			"https://img.freepik.com/free-photo/painting-mountain-lake-with-mountain-background_188544-9126.jpg",
			["correo1@gmail.com", "correo2@gmail.com"],
		);
		console.log("Created project with ID", projectId);

		console.log("Creating task for test...");
		taskId = await createTask("correo1@gmail.com", projectId, null, "😀");
		console.log("Task created with ID", taskId);
	});

	test("Edit task fields within range", async () => {
		const payload = {
			change_task_cords: {
				task_id: taskId,
				cords: {
					row: randomInt(GRID_SIZE),
					column: randomInt(GRID_SIZE),
				},
			},
		};

		const client = await generateClient("correo1@gmail.com", projectId);
		const promise = new Promise((res, rej) => {
			client.configureHandlers(rej, (recv) => {
				try {
					const data = JSON.parse(recv.toString());
					if (data.change_task_cords) {
						res(data);
					}
				} catch (err) {
					rej(err);
				}
			});
		});

		await client.send(JSON.stringify(payload));
		const response = await promise;
		await client.close();

		const expectedResponse = {
			change_task_cords: {
				task: {
					id: taskId,
					project_id: projectId,
					parent_id: null,
					display_id: expect.any(String),
					icon: expect.any(String),
					fields: [],
				},
			},
		};

		expect(response).toEqual(expectedResponse);
	});

	test("Can't give values outside range!", async () => {
		const payload = {
			change_task_cords: {
				task_id: taskId,
				cords: {
					row: 10, // Outside range!
					column: 5,
				},
			},
		};

		const client = await generateClient("correo1@gmail.com", projectId);
		const promise = new Promise((res, rej) => {
			client.configureHandlers(rej, (recv) => {
				try {
					const data = JSON.parse(recv.toString());
					if (data.err) {
						res(data);
					}
				} catch (err) {
					rej(err);
				}
			});
		});

		await client.send(JSON.stringify(payload));
		const response = await promise;
		await client.close();

		const expectedResponse = {
			err: "ChangeTaskCordsError",
		};

		expect(response).toEqual(expectedResponse);
	});
});

describe("Update Task test suite", () => {
	let projectId = 0;
	let taskId = 0;

	beforeEach(async () => {
		console.log("Creating project for test...");
		projectId = await createProject(
			"correo3@gmail.com",
			"UPDATE TASK TEST SUITE PROJECT",
			"😀",
			"https://img.freepik.com/free-photo/painting-mountain-lake-with-mountain-background_188544-9126.jpg",
			["correo1@gmail.com", "correo2@gmail.com"],
		);
		console.log("Created project with ID", projectId);

		console.log("Creating task for test...");
		taskId = await createTask("correo1@gmail.com", projectId, null, "😀");
		console.log("Task created with ID", taskId);
	});

	test("Can update a task", async () => {
		/**@type {import("../jsLib/testHelpers/tasks.js").TaskData}*/
		const data = {
			task_id: taskId,
			parent_id: null,
			display_id: "Task Title",
			icon: "💀",
		};
		const updatedTaskId = await updateTask(
			"correo1@gmail.com",
			projectId,
			data,
		);

		expect(updatedTaskId).toEqual(expect.any(Number));
	});

	test("Can add a parent id for task", async () => {
		/**@type {import("../jsLib/testHelpers/tasks.js").TaskData}*/
		const parentId = await createTask(
			"correo1@gmail.com",
			projectId,
			null,
			"😀",
		);
		const data = {
			task_id: taskId,
			parent_id: parentId,
			display_id: "Task Title",
			icon: "💀",
		};
		const updatedTaskId = await updateTask(
			"correo1@gmail.com",
			projectId,
			data,
		);

		expect(updatedTaskId).toEqual(expect.any(Number));
	});

	test("Update task error is sent to only request client", async () =>
		await errorOnlyOnSameClient(
			"correo1@gmail.com",
			"correo2@gmail.com",
			projectId,
			{
				// Invalid task payload
				update_task: {
					task_id: 0,
					parent_id: null,
					display_id: "Task Title",
					icon: "💀",
				},
			},
			"UpdateTaskError",
		)());

	test(
		"Update task response is sent to all connected clients",
		async () =>
			await messageIsSentToAllClients(
				"correo1@gmail.com",
				"correo2@gmail.com",
				"update_task",
				projectId,
				{
					update_task: {
						task_id: taskId,
						parent_id: null,
						display_id: "SHORT TITLE",
						icon: "🤣",
					},
				},
				{
					update_task: {
						task: {
							id: taskId,
							icon: "🤣",
							parent_id: null,
							display_id: "SHORT TITLE",
							project_id: projectId,
							fields: [],
						},
					},
				},
			)(),
		7000,
	);
});

describe("Create Task test suite", () => {
	let projectId = 0;

	beforeEach(async () => {
		console.log("Creating project for test...");
		projectId = await createProject(
			"correo3@gmail.com",
			"CREATE TASK TEST SUITE PROJECT",
			"😀",
			"https://img.freepik.com/free-photo/painting-mountain-lake-with-mountain-background_188544-9126.jpg",
			["correo1@gmail.com", "correo2@gmail.com"],
		);
		console.log("Created project with ID", projectId);
	});

	test("Can create a task", async () => {
		const email = "correo1@gmail.com";
		const parentId = null;
		const taskId = await createTask(email, projectId, parentId, "😀");

		expect(taskId).toEqual(expect.any(Number));
	});

	test("Create task error is sent only to request client", async () =>
		await errorOnlyOnSameClient(
			"correo1@gmail.com",
			"correo2@gmail.com",
			projectId,
			{
				create_task: {
					project_id: 0, // This project id doesn't exist!
					parent_id: null,
					icon: "😀",
				},
			},
			"CreateTaskError",
		)());

	test(
		"Create task response is sent to all connected clients",
		async () =>
			await messageIsSentToAllClients(
				"correo1@gmail.com",
				"correo2@gmail.com",
				"create_task",
				projectId,
				{
					create_task: {
						project_id: projectId,
						parent_id: null,
						icon: "😀",
					},
				},
				{
					create_task: {
						task: {
							id: expect.any(Number),
							project_id: expect.any(Number),
							parent_id: null,
							display_id: expect.any(String),
							icon: "😀",
							fields: [],
						},
					},
				},
				(response) => {
					const { task } = response.create_task;
					expect(task.project_id).toBe(projectId);
				},
			)(),
		7000,
	);
});
