import { describe, test } from "vitest";
import { malformedJSON, noPayloadSupplied } from "./testHelpers";
import { API_URL, createProject } from "./testHelpers/project";

describe("Project POST integration tests", () => {
	test("Successfully creates a project", async () =>
		await createProject(
			"correo1@gmail.com",
			"JUWURA test project",
			"💀",
			"https://cdn.lazyshop.com/files/d2c4f2c8-ada5-455a-86be-728796b838ee/other/192115ca73ec8c98c62e3cbc95b96d32.jpg",
			[],
		));
	test("No payload supplied", noPayloadSupplied(API_URL));
	test("Malformed JSON", malformedJSON(API_URL));
});
