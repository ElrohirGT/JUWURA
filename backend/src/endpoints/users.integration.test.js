import { describe, test, expect } from "vitest";
import axios from "axios";
import { getUser, API_URL } from "./testHelpers/users";

describe("User GET integration tests", () => {
	test("Successfully GETs a user", async () =>
		await getUser("correo1@gmail.com"));

	test("Returns 404 for not existing user", async () => {
		const params = { email: "cr@gmail.com" };
		const response = await axios.get(API_URL, {
			params,
			validateStatus: () => true,
		});

		if (response.status !== 404) {
			console.error(response.data);
		}

		expect(response.status).toBe(404);
		expect(response.data).toBe("USER DOESN'T EXISTS");
	});

	test("Returns 400 for no email supplied", async () => {
		const invalidEmails = [undefined, ""];
		for (const email of invalidEmails) {
			const params = { email };
			const response = await axios.get(API_URL, {
				params,
				validateStatus: () => true,
			});

			if (response.status !== 400) {
				console.error(response.data);
				console.log(`Email: "${email}"`);
			}

			expect(response.status).toBe(400);
			expect(response.data).toBe("BAD REQUEST PARAMS");
		}
	});
});
