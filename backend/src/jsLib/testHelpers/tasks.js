import { expect } from "vitest";
import axios from "axios";
import { generateClient } from "../ws";
import { API_HOST } from ".";

export const API_URL = `${API_HOST}/tasks`;

/**
 * @typedef {Object} APITaskField
 * @property {number} id
 * @property {string} name
 * @property {string} type
 * @property {string|null} value
 */

/**
 * @typedef {Object} APITask
 *@property {number} id
 *@property {number|null} parent_id
 *@property {number} project_id
 *@property {string} short_title
 *@property {string} icon
 *@property {APITaskField[]} fields
 */

/**
 * Gets a task from from the backend with a given id.
 * It also retrieves all the fields from it.
 * @param {number} taskId - The ID of the task to get
 * @returns {Promise<APITask>} The task in question.
 */
export async function getTask(taskId) {
	const params = { taskId };
	const response = await axios.get(API_URL, {
		params,
		validateStatus: () => true,
	});

	if (response.status !== 200) {
		console.error(response.data);
	}

	expect(response.status).toBe(200);

	/** @type {APITask} */
	const task = response.data.task;
	expect(task.id).toBe(taskId);
	expect(task.project_id).toEqual(expect.any(Number));
	expect(task.short_title).toEqual(expect.any(String));
	expect(task.icon).toEqual(expect.any(String));

	for (const field of task.fields) {
		expect(field.id).toEqual(expect.any(Number));
		expect(field.type).toEqual(expect.any(String));
		expect(field.name).toEqual(expect.any(String));
	}

	return task;
}

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
		edit_task_field: {
			task_id,
			task_field_id,
			value,
		},
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

	let found = false;
	for (const field of task.fields) {
		expect(field.id).toEqual(expect.any(Number));
		expect(field.name).toEqual(expect.any(String));
		expect(field.type).toEqual(expect.any(String));

		if (field.value === value) {
			found = true;
		}
	}

	expect(found).toBe(true);
}

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
