import { expect } from "vitest";
import { generateClient } from "../ws";
import { randomInt } from "../utils";

export const GRID_SIZE = 10;

/**
 * Edits a field in a task from a given project.
 * @param {string} email - User email, to establish WS connection
 * @param {string} projectId - The project id, to establish WS connection
 * @param {string} task_id - The ID of the task with the field
 * @param {string} task_field_id - The ID of the task field
 * @param {string} value - The new value of the task field
 */
export async function editTaskField(
	email,
	projectId,
	task_id,
	task_field_id,
	value,
) {
	const payload = {
		task_id,
		task_field_id,
		value,
	};

	const client = await generateClient(email, projectId);
	const promise = new Promise((res, rej) => {
		client.configureHandlers(rej, (rev) => {
			try {
				const data = JSON.parse(rev.toString());

				if (data.edit_task_field) {
					res(data);
				}
			} catch {}
		});
	});
	await client.send(JSON.stringify(payload));

	const response = await promise;
	const { task } = response.edit_task_field;
	expect(task.fields).toBeDefined();

	const expectedField = {
		id: expect.any(Number),
		name: expect.any(String),
		type: expect.any(String),
		value: expect.any(String),
	};
	for (const field of task.fields) {
		expect(field).toEqual(expectedField);
		expect(field.value).toBe(value);
	}
}

/**
 * Creates a task given the auth and minimum data.
 * @param {string} email - The email of the user
 * @param {number} projectId - The id of the project
 * @param {number|null} parentId - The ID of the parent task
 * @param {string} icon - The task type
 * @param {number} row - The 0 index row of the senku canvas
 * @param {number} column - The 0 index column of the senku canvas
 * @returns {Promise<number>} The created task id
 */
export async function createTask(
	email,
	projectId,
	parentId,
	icon,
	row,
	column,
) {
	const payload = {
		create_task: {
			project_id: projectId,
			parent_id: parentId,
			icon,
			cords: {
				row: row ?? randomInt(GRID_SIZE),
				column: column ?? randomInt(GRID_SIZE),
			},
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
				display_id: expect.any(String),
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
 * @property {string} display_id
 * @property {string} icon
 * @property {[]TaskField} fields
 */

/**
 * @typedef {Object} UpdateTaskRequest
 * @property{number} task_id
 * @property{number|null} parent_id
 * @property{string} display_id
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
				display_id: taskData.display_id,
				project_id: projectId,
				fields: [],
			},
		},
	};
	expect(response).toEqual(expectedResponse);

	const { task } = response.update_task;
	return task.id;
}
