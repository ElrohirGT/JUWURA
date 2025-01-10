import { expect, describe, test, beforeEach } from "vitest";
import { createProject } from "../jsLib/testHelpers/projects";
import { createTask } from "../jsLib/testHelpers/tasks";
import { generateClient } from "../jsLib/ws";

describe("Get senku test suite", () => {
	let projectId = 0;

	beforeEach(async () => {
		console.log("Creating project for test...");
		projectId = await createProject(
			"correo4@gmail.com",
			"GET SENKU TEST SUITE PROJECT",
			"🤠",
			"https://img.freepik.com/free-photo/painting-mountain-lake-with-mountain-background_188544-9126.jpg",
			["correo1@gmail.com", "correo2@gmail.com"],
		);
		console.log("Created project with ID", projectId);

		await createTask("correo1@gmail.com", projectId, null, "🤠", 0, 0);
		await createTask("correo1@gmail.com", projectId, null, "🤠", 1, 1);
		await createTask("correo1@gmail.com", projectId, null, "🤠", 2, 2);
	});

	test("Can get state", async () => {
		const payload = {
			get_senku_state: {
				project_id: projectId,
			},
		};

		const client = await generateClient("correo1@gmail.com", projectId);
		const promise = new Promise((res, rej) => {
			client.configureHandlers(rej, (rec) => {
				try {
					const data = JSON.parse(rec.toString());

					if (data.get_senku_state) {
						res(data);
					}
				} catch (err) {
					rej(err);
				}
			});
		});

		await client.send(JSON.stringify(payload));
		const response = await promise;
		await client.close();

		const expectedResponse = {
			get_senku_state: {
				state: {
					cells: expect.any(Array),
					connections: expect.any(Array),
				},
			},
		};

		expect(response).toEqual(expectedResponse);

		const state = response.get_senku_state.state;
		expect(state.cells[0][0].id).toBeDefined();
		expect(state.cells[1][1].id).toBeDefined();
		expect(state.cells[2][2].id).toBeDefined();
	});
});
