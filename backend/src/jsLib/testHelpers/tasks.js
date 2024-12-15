import { expect } from "vitest";
import { generateClient } from "../ws";

/**
 * Creates a task given the auth and minimum data.
 * @param {string} email - The email of the user
 * @param {string} type - The task type
 * @param {number} projectId The id of the project
 * @returns {Promise<number>} The created task id
 */
export async function createTask(email, type, projectId) {
	const payload = {
		create_task: {
			task_type: type,
			project_id: projectId,
		},
	};

	const client = await generateClient(email, projectId);
	const promise = new Promise((res, rej) => {
		client.configureHandlers(rej, (rev) => {
			try {
				const data = JSON.parse(rev.toString());

				if (data.create_task) {
					res(data);
				}
			} catch {}
		});
	});
	await client.send(JSON.stringify(payload));

	const response = await promise;
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
	expect(response).toEqual(expectedResponse);

	const { task } = response.create_task;
	expect(task.project_id).toBe(projectId);
	expect(task.type).toBe(type);

	return task.id;
}
