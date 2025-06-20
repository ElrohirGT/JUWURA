import { describe, test, expect } from "vitest";
import { BinaryHeap } from "./binaryHeap";

describe("Binary heap test suite", () => {
	test("Works with objects", () => {
		const objScore = (a) => a.f;
		const objEquality = (a, b) => a.x === b.x && a.y === b.y;

		const middle = { f: 20, x: 25, y: 20 };
		const last = { f: 50, x: 25, y: 10 };
		const start = { f: 10, x: 30, y: 15 };

		/** @type {BinaryHeap<{f: number, x: number, y: number}>} */
		const heap = new BinaryHeap(objScore, objEquality);
		heap.push(last);
		heap.push(start);
		heap.push(middle);

		expect(heap.size()).toBe(3);

		expect(heap.pop()).toStrictEqual(start);
		expect(heap.pop()).toStrictEqual(middle);
		expect(heap.pop()).toStrictEqual(last);
	});

	test("Reescore element works", () => {
		const objScore = (a) => a.f;
		const objEquality = (a, b) => a.x === b.x && a.y === b.y;

		const middle = { f: 20, x: 25, y: 20 };
		const last = { f: 50, x: 25, y: 10 };
		const start = { f: 10, x: 30, y: 15 };

		/** @type {BinaryHeap<{f: number, x: number, y: number}>} */
		const heap = new BinaryHeap(objScore, objEquality);
		heap.push(last);
		heap.push(start);
		heap.push(middle);

		expect(heap.size()).toBe(3);

		start.f = 100;
		heap.rescoreElement(start);

		expect(heap.pop()).toStrictEqual(middle);
	});
});
