import { expect } from "vitest";
import axios from "axios";

export const API_HOST = "http://127.0.0.1:3000";

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
