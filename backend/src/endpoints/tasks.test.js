import { describe, test, expect, beforeAll } from "vitest";
import axios from "axios";
import { getTask, API_URL, createTask } from "../jsLib/testHelpers/tasks.js";
import { createProject } from "../jsLib/testHelpers/projects.js";

describe("TASK GET integration tests", () => {
	let taskId = 0;
	beforeAll(async () => {
		const email = "correo1@gmail.com";
		const projectId = await createProject(
			email,
			"TASK GET INTEGRATION TESTS",
			"💀",
			"https://cdn.lazyshop.com/files/d2c4f2c8-ada5-455a-86be-728796b838ee/other/192115ca73ec8c98c62e3cbc95b96d32.jpg",
			[],
		);
		taskId = await createTask(email, projectId, null, "💀");
	});

	test("Successfully GETs a task", async () => await getTask(taskId));

	test("Returns 404 for not existing taskId", async () => {
		const params = { taskId: -5 };
		const response = await axios.get(API_URL, {
			params,
			validateStatus: () => true,
		});

		if (response.status !== 404) {
			console.error(response.data);
		}

		expect(response.status).toBe(404);
		expect(response.data).toBe("TASK DOESN'T EXISTS");
	});

	test("Returns 400 for no taskId supplied", async () => {
		const invalidTaskIds = [undefined, ""];
		for (const taskId of invalidTaskIds) {
			const params = { email: taskId };
			const response = await axios.get(API_URL, {
				params,
				validateStatus: () => true,
			});

			if (response.status !== 400) {
				console.error(response.data);
				console.log(`TaskId: "${taskId}"`);
			}

			expect(response.status).toBe(400);
			expect(response.data).toBe("BAD REQUEST PARAMS");
		}
	});
});
