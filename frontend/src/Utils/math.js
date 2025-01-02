/**
 * Clamps a value between to other values (inclusive).
 * @param {number} value - The value to try to clamp.
 * @param {number} min - The minimum `value` can be.
 * @param {number} max - The maximum `value` can be.
 */
export function clamp(value, min, max) {
	return Math.min(Math.max(value, min), max);
}
