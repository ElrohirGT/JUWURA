import { expect } from "vitest";
import axios from "axios";

export const API_HOST = "http://127.0.0.1:3000";

/**
 * Generates a function that tests the case when a POST request is made
 * to the specified URL without it being provided with a body.
 *
 * It expects for the response to be plaintext "NO BODY FOUND"
 * and the status 400.
 * @param {string} url The URL to make the request to
 * @returns {Function} The function that tests the endpoint for the test case
 */
export function noPayloadSupplied(url) {
	return async () => {
		const payload = null;
		const response = await axios.post(url, payload, {
			validateStatus: () => true,
		});

		if (response.status !== 400) {
			console.error(response.data);
		}

		expect(response.status).toBe(400);
		expect(response.data).toBe("NO BODY FOUND");
	};
}

/**
 * Generates a function that tests the case when a POST request is made
 * to the specified URL with an invalid JSON in the body.
 *
 * It expects the response to be plaintext "INCORRECT BODY" and
 * the status to be 400.
 * @param {string} url The URL to make the request
 * @returns {Function} The function that tests the endpoint for the test case.
 */
export function malformedJSON(url) {
	return async () => {
		const payload = {
			hello: "Hola",
		};

		const response = await axios.post(url, payload, {
			validateStatus: () => true,
		});

		if (response.status !== 400) {
			console.error(response.data);
		}

		expect(response.status).toBe(400);
		expect(response.data).toBe("INCORRECT BODY");
	};
}
