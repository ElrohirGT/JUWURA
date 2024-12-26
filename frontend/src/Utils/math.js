/**
 * Clamps a value between to other values (inclusive).
 * @param {number} value - The value to try to clamp.
 * @param {number} min - The minimum `value` can be.
 * @param {number} max - The maximum `value` can be.
 */
export function clamp(value, min, max) {
	return Math.min(Math.max(value, min), max);
}

/**
 * Compares two float values
 * @param {number} a - First number
 * @param {number} b - Second number
 * @param {number} [epsilon=Number.EPSILON] - The maximum delta between the numbers to consider them equals. By default is: `Number.EPSILON`.
 * @returns {boolean} True if the numbers are considered equal, false otherwise
 */
export function floatEquals(a, b, epsilon = Number.EPSILON) {
	return Math.abs(a - b) <= epsilon;
}
