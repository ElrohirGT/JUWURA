import { TAG_NAME } from "./SenkuCanvas";

/**
 * @template T
 * @param {string} type
 * @param {T} detail
 * @returns {CustomEvent<T>}
 */
function createCustomEvent(type, detail) {
	return new CustomEvent(`${TAG_NAME}:${type}`, {
		bubbles: false,
		cancelable: false,
		detail,
	});
}

/**
 * @param {import("./types").CreateTaskEventDetails} detail
 * @returns {CustomEvent<import("./types").CreateTaskEventDetails>}
 */
export function CreateTaskEvent(detail) {
	return createCustomEvent("create-task", detail);
}
