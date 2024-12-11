import { expect } from "vitest";
import axios from "axios";
import { API_HOST } from ".";

export const API_URL = `${API_HOST}/projects`;

/**
 * Creates a project with the given name.
 * @param {string} name - The name of the project to create.
 * @param {string} userEmail - The email of the owner of the project.
 * @returns {number} The project ID
 */
export async function createProject(name, userEmail) {
	const payload = {
		email: userEmail,
		name,
		now_timestamp: new Date().getTime(),
	};

	const response = await axios.post(API_URL, payload, {
		validateStatus: () => true,
	});

	if (response.status !== 200) {
		console.error(response.data);
	}

	expect(response.status).toBe(200);
	expect(response.data.project.photo_url).toBeNull();
	expect(response.data.project.id).toEqual(expect.any(Number));
	expect(response.data.project.name).toEqual(payload.name);

	return response.data.project.id;
}
