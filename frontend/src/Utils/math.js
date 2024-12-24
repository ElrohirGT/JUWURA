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
 * @typedef {[number, number,number]} RGBColor
 */

/**
 * Computes a lerp function between 3 colors.
 * @param {RGBColor} start
 * @param {RGBColor} middle
 * @param {RGBColor} end
 * @param {number} progress
 */
export function lerpColor3(start, middle, end, progress) {
	if (progress < 0.5) {
		return lerpColor(start, middle, progress * 2);
	} else {
		return lerpColor(middle, end, (progress - 0.5) * 2);
	}
}

/**
 * @param {RGBColor} start
 * @param {RGBColor} end
 * @param {number} progress - A number between 0 and 1
 * @returns {RGBColor}
 */
export function lerpColor(start, end, progress) {
	return [
		start[0] * (1 - progress) + end[0] * progress,
		start[1] * (1 - progress) + end[1] * progress,
		start[2] * (1 - progress) + end[2] * progress,
	];
}
