import { describe, test } from "vitest";
import { malformedJSON, noPayloadSupplied } from "./testHelpers";
import { getUser } from "./testHelpers/users";

describe("User GET integration tests", () => {
	test("Successfully GETs a user", async () =>
		await getUser("correo1@gmail.com"));
});
