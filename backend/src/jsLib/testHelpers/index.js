import { expect } from "vitest";
import { generateClient } from "../ws";
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
 * @param {string} c1Email - The user email of the first client
 * @param {string} c2Email - The user email of the second client
 * @param {number} projectId - The project id to connect to
 * @param {string} errorToCheck - The error value to check for
 * @param {any} erroneousPayload The payload to send in the websocket
 */
export function errorOnlyOnSameClient(
	c1Email,
	c2Email,
	projectId,
	erroneousPayload,
	errorToCheck,
) {
	return async () => {
		const client1 = await generateClient(c1Email, projectId);
		const client2 = await generateClient(c2Email, projectId);

		const promise = new Promise((res, rej) => {
			const client2Msgs = [];
			const client1Msgs = [];

			setTimeout(() => {
				res([client1Msgs, client2Msgs]);
			}, 2500);

			client1.configureHandlers(rej, (rev) => {
				try {
					const data = JSON.parse(rev.toString());
					client1Msgs.push(data);
				} catch {}
			});

			client2.configureHandlers(rej, (rev) => {
				try {
					const data = JSON.parse(rev.toString());
					client2Msgs.push(data);
				} catch {}
			});
		});
		await client1.send(JSON.stringify(erroneousPayload));
		await client1.close();
		await client2.close();

		/**@type{[any[], any[]]}*/
		const [c1Msgs, c2Msgs] = await promise;

		let foundError = false;
		for (const msg of c1Msgs) {
			if (msg.err === errorToCheck) {
				foundError = true;
			}
		}

		if (!foundError) {
			console.error("Client 1 MSGs:", c1Msgs);
			throw new Error("No error found on messages of the first client!");
		}

		foundError = false;
		for (const msg of c2Msgs) {
			if (msg.err === errorToCheck) {
				foundError = true;
			}
		}

		if (foundError) {
			console.error("Client 2 MSGs:", c2Msgs);
			throw new Error("Error found on messages of the second client!");
		}
	};
}

/**
 * Checks if the given payload request generates the same response on both clients!
 * @param {string} c1Email - The user email of the first client
 * @param {string} c2Email - The user email of the second client
 * @param {number} projectId - The project id to connect to
 * @param {any} payload - The payload to send through connection 1
 * @param {any} expectedResponse - The response that both connection 1 and 2 must receive
 * @param {(response: any) => void} additionalChecks - Additional checks to make on the websocket response
 */
export function messageIsSentToAllClients(
	c1Email,
	c2Email,
	projectId,
	payload,
	expectedResponse,
	additionalChecks,
) {
	return async () => {
		const client1 = await generateClient(c1Email, projectId);
		const client2 = await generateClient(c2Email, projectId);

		const client1Waiter = new Promise((res, rej) => {
			client1.configureHandlers(rej, (rev) => {
				try {
					const response = JSON.parse(rev);
					if (response.create_task) {
						res(response);
					}
				} catch {}
			});
		});
		const client2Waiter = new Promise((res, rej) => {
			client2.configureHandlers(rej, (rev) => {
				try {
					const response = JSON.parse(rev);
					if (response.create_task) {
						res(response);
					}
				} catch {}
			});
		});

		await client1.send(JSON.stringify(payload));
		const responses = await Promise.all([client1Waiter, client2Waiter]);

		for (const response of responses) {
			// console.log("SERVER:", response, "EXPECTED:", expectedResponse);
			// console.log("EXPECTED: ", response);
			expect(response).toEqual(expectedResponse);
			additionalChecks(response);
		}
	};
}
