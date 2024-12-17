import { expect } from "vitest";
import { API_HOST } from ".";
import axios from "axios";

export const API_URL = `${API_HOST}/users`;

export async function getUser(email) {
	const params = { email };
	const response = await axios.get(API_URL, {
		params,
		validateStatus: () => true,
	});

	if (response.status !== 200) {
		console.error(response.data);
	}

	const expectedFormat = {
		user: {
			email: expect.any(String),
			name: expect.any(String),
			photo_url: expect.any(String),
		},
	};

	expect(response.status).toBe(200);
	expect(response.data).toEqual(expectedFormat);
}
