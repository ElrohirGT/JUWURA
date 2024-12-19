import { expect } from "vitest";
import { generateClient } from "../ws";

/**
 * Creates a task given the auth and minimum data.
 * @param {string} email - The email of the user
 * @param {number} projectId - The id of the project
 * @param {number|null} parentId - The ID of the parent task
 * @param {string} icon - The task type
 * @returns {Promise<number>} The created task id
 */
export async function createTask(email, projectId, parentId, icon) {
	const payload = {
		create_task: {
			project_id: projectId,
			parent_id: parentId,
			icon,
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
	await client.close();

	const expectedResponse = {
		create_task: {
			task: {
				id: expect.any(Number),
				project_id: expect.any(Number),
				parent_id: parentId,
				short_title: expect.any(String),
				icon: expect.any(String),
				fields: [],
			},
		},
	};
	expect(response).toEqual(expectedResponse);

	const { task } = response.create_task;
	expect(task.project_id).toBe(projectId);
	expect(task.parent_id).toBe(parentId);
	expect(task.icon).toBe(icon);
	expect(task.fields).toEqual([]);

	return task.id;
}

/**
 * @typedef {Object} TaskField
 * @property {number} id
 * @property {"TEXT"|"DATE"|"CHOICE"|"NUMBER"|"ASSIGNEE"} type
 * @property {string} value
 */

/**
 * @typedef {Object} TaskData
 * @property {number} id
 * @property {number} project_id
 * @property {number|null} parent_id
 * @property {string} short_title
 * @property {string} icon
 * @property {[]TaskField} fields
 */

/**
 * @typedef {Object} UpdateTaskRequest
 * @property{number} task_id
 * @property{number|null} parent_id
 * @property{string} short_title
 * @property{string} icon
 */

/**
 * Creates a task given the auth and minimum data.
 * @param {string} email - The email of the user
 * @param {number} projectId - The project ID for the connection
 * @param {UpdateTaskRequest} taskData - The data of the task to update
 * @returns {Promise<number>} The updated task id
 */
export async function updateTask(email, projectId, taskData) {
	const payload = { update_task: taskData };
	const client = await generateClient(email, projectId);

	const promise = new Promise((res, rej) => {
		client.configureHandlers(rej, (rev) => {
			try {
				const data = JSON.parse(rev.toString());

				if (data.update_task) {
					res(data);
				}
			} catch {}
		});
	});
	await client.send(JSON.stringify(payload));

	const response = await promise;
	await client.close();

	const expectedResponse = {
		update_task: {
			task: {
				id: taskData.task_id,
				icon: taskData.icon,
				parent_id: taskData.parent_id,
				short_title: taskData.short_title,
				project_id: projectId,
				fields: [],
			},
		},
	};
	expect(response).toEqual(expectedResponse);

	const { task } = response.update_task;
	return task.id;
}
