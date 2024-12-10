import { describe, test, expect } from "vitest";
import axios from "axios";
import { malformedJSON, noPayloadSupplied } from "./testHelpers";

const API_URL = "http://127.0.0.1:3000/projects";

describe("Project POST integration tests", () => {
	test("Successfully creates a project", async () => {
		const payload = {
			email: "correo1@gmail.com",
			name: "JUWURA Example",
			// photo_url: null,
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
	});

	test("No payload supplied", noPayloadSupplied(API_URL));
	test("Malformed JSON", malformedJSON(API_URL));
});
