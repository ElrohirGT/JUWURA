import { describe, test, expect } from "vitest";
import { malformedJSON, noPayloadSupplied } from "./testHelpers";
import { API_URL, createProject } from "./testHelpers/project";

describe("Project POST integration tests", () => {
	test("Successfully creates a project", async () => {
		await createProject("JUWURA test project", "correo1@gmail.com");
	});
	test("No payload supplied", noPayloadSupplied(API_URL));
	test("Malformed JSON", malformedJSON(API_URL));
});
