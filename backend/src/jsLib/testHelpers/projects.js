import { expect } from "vitest";
import axios from "axios";
import { API_HOST } from ".";

export const API_URL = `${API_HOST}/projects`;

/**
 * Creates a project with the given name.
 * @param {string} userEmail - The email of the owner of the project.
 * @param {string} name - The name of the project to create.
 * @param {string} icon - The icon of the project.
 * @param {string[]} members - The emails of the members.
 * @param {string} url - The banner URL.
 * @returns {Promise<number>} The project ID
 */
export async function createProject(userEmail, name, icon, url, members) {
	const payload = {
		email: userEmail,
		icon,
		name,
		members,
		photo_url: url,
		now_timestamp: new Date().getTime(),
	};

	const response = await axios.post(API_URL, payload, {
		validateStatus: () => true,
	});

	if (response.status !== 200) {
		console.error(response.data);
	}

	const expectedStructure = {
		project: {
			id: expect.any(Number),
			name: expect.any(String),
			photo_url: expect.any(String),
			icon: expect.any(String),
		},
	};

	expect(response.status).toBe(200);
	expect(response.data).toEqual(expectedStructure);

	const { project } = response.data;
	expect(project.name).toBe(payload.name);
	expect(project.icon).toBe(payload.icon);
	expect(project.photo_url).toBe(payload.photo_url);

	return response.data.project.id;
}
