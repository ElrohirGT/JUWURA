import { expect, describe, test, beforeEach } from "vitest";
import { createTask } from "../../jsLib/testHelpers/tasks";
import { createProject } from "../../jsLib/testHelpers/projects.js";
import {
	errorOnlyOnSameClient,
	messageIsSentToAllClients,
} from "../../jsLib/testHelpers/index.js";

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
		const type = "EPIC";
		const taskId = await createTask(email, type, projectId);

		expect(taskId).toEqual(expect.any(Number));
	});

	test(
		"Create task error is sent only to request client",
		errorOnlyOnSameClient(
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
		),
	);

	test(
		"Create task response is sent to all connected clients",
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
