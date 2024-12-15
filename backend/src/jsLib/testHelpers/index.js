import { expect } from "vitest";
import axios from "axios";

export const API_HOST = "http://127.0.0.1:3000";

/**
 * Represents a vitest test case.
 * @callback TestCase
 * @returns {Promise<void>}
 */

/**
 * Generates a test case that POSTs a request to the supplied URL with no body attached!
 * @param {string} url The HTTP url endpoint to check when no payload is supplied
 * @returns {TestCase} The test implemented test case.
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
 * Generates a test case that POSTs a request to
 * the supplied URL with a malformed JSON as payload!
 * @param {any} url The HTTP url endpoint to check when the payload JSON is malformed.
 * @returns {TestCase} The implemented test case.
 */
export function malformedJSON(url) {
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
 * Checks if the given erroneous payload generates an error and
 * it's only received on the same client that sent the payload!
 * @param {string} email - The user email
 * @param {number} projectId - The project id to connect to
 * @param {any} erroneousPayload The payload to send in the websocket
 */
export function errorOnlyOnSameClient(email, projectId, erroneousPayload) {}
