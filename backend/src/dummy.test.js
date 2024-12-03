import { describe, test, expect } from "vitest";

describe("Dummy tests", () => {
	test("1+1 = ?", () => {
		const payload = 1;
		const result = 1 + payload;
		expect(result).toBe(2);
	});
});
