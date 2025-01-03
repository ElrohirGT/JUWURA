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

/**
 * @param {import("./types").TaskChangedCoordinatesEventDetails} detail
 * @returns {CustomEvent<import("./types").TaskChangedCoordinatesEventDetails>}
 */
export function TaskChangedCoordinatesEvent(detail) {
	return createCustomEvent("task-changed-coordinates", detail);
}

/**
 * @param {import("./types").CreateConnectionEventDetails} detail
 * @returns {CustomEvent<import("./types").CreateConnectionEvent>}
 */
export function CreateConnectionEvent(detail) {
	return createCustomEvent("create-connection", detail);
}
