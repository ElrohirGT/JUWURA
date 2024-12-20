import { expect, describe, test, beforeEach } from "vitest";
import {
	createTask,
	editTaskField,
	updateTask,
} from "../jsLib/testHelpers/tasks.js";
import { createProject } from "../jsLib/testHelpers/projects.js";
import {
	errorOnlyOnSameClient,
	messageIsSentToAllClients,
} from "../jsLib/testHelpers/index.js";

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
			short_title: "Task Title",
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
			short_title: "Task Title",
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
					project_id: 0,
				},
			},
			"UpdateTaskError",
		));

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
						short_title: "SHORT TITLE",
						icon: "🤣",
					},
				},
				{
					update_task: {
						task: {
							id: taskId,
							icon: "🤣",
							parent_id: null,
							short_title: "SHORT TITLE",
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
		));

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
							short_title: expect.any(String),
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
