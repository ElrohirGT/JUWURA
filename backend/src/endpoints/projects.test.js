import { describe, test, beforeEach } from "vitest";
import {
	malformedJSON,
	noPayloadSupplied,
} from "../jsLib/testHelpers/index.js";
import {
	API_URL,
	createProject,
	updateProject,
} from "../jsLib/testHelpers/projects.js";

describe("Project POST integration tests", () => {
	test.only("Successfully creates a project", async () =>
		await createProject(
			"correo1@gmail.com",
			"JUWURA test project",
			"💀",
			"https://cdn.lazyshop.com/files/d2c4f2c8-ada5-455a-86be-728796b838ee/other/192115ca73ec8c98c62e3cbc95b96d32.jpg",
			[],
		));
	test("No payload supplied", noPayloadSupplied(API_URL, "post"));
	test("Malformed JSON", malformedJSON(API_URL, "post"));
});

describe("Project PUT integration tests", () => {
	let projectId = null;
	beforeEach(async () => {
		projectId = await createProject(
			"correo1@gmail.com",
			"PUT TESTS PROJECT",
			"💀",
			"https://cdn.lazyshop.com/files/d2c4f2c8-ada5-455a-86be-728796b838ee/other/192115ca73ec8c98c62e3cbc95b96d32.jpg",
			["correo2@gmail.com", "correo3@gmail.com"],
		);
	});

	test("Successfully updated a project", async () =>
		await updateProject(
			projectId,
			"PUT UPDATED",
			"https://cdn.lazyshop.com/files/d2c4f2c8-ada5-455a-86be-728796b838ee/other/192115ca73ec8c98c62e3cbc95b96d32.jpg",
			"😎",
			// NOTE: REMEMBER TO ADD THE OWNER!
			// Removed correo3!
			["correo1@gmail.com", "correo2@gmail.com"],
		));

	test("No payload supplied", noPayloadSupplied(API_URL, "put"));
	test("Malformed JSON", malformedJSON(API_URL, "put"));
});
