import { expect, describe, test, beforeEach } from "vitest";
import { createTask, updateTask } from "../../jsLib/testHelpers/tasks";
import { createProject } from "../../jsLib/testHelpers/projects.js";
import {
	errorOnlyOnSameClient,
	messageIsSentToAllClients,
} from "../../jsLib/testHelpers/index.js";

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

	test.only("Can update a task", async () => {
		/**@type {import("../../jsLib/testHelpers/tasks").TaskData}*/
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

	test("Update task error is sent to only request client", async () =>
		await errorOnlyOnSameClient(
			"correo1@gmail.com",
			"correo2@gmail.com",
			projectId,
			{
				create_task: {
					task_type: "EPIC",
					project_id: 0, // This project id doesn't exist!
				},
			},
			"CreateTaskError",
		));

	test(
		"Update task response is sent to all connected clients",
		async () =>
			await messageIsSentToAllClients(
				"correo1@gmail.com",
				"correo2@gmail.com",
				projectId,
				{
					create_task: {
						task_type: "TASK",
						project_id: projectId,
					},
				},
				{
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
				},
				(response) => {
					const { task } = response.create_task;
					expect(task.project_id).toBe(projectId);
					expect(task.type).toBe("TASK");
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
