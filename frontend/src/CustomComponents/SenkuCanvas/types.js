/**
 * @typedef {Object} TaskStatus
 * @property {string} name
 * @property {string} color
 */

/**
 * @typedef {Object} TaskData
 * @property {number} id
 * @property {Date} due_date
 * @property {String} title
 * @property {TaskStatus} status
 * @property {String} icon
 * @property {number} progress
 */

/**
 * @typedef {Object} CellCoord
 * @property {number} column
 * @property {number} row
 */

/**
 * @typedef {Object} TaskConnection
 * @property {CellCoord} start
 * @property {CellCoord} end
 */

/**
 * @typedef {(TaskData|undefined)[][]} Cells
 */

/**
 * @typedef {Object} SenkuCanvasState
 * @property {Cells} cells
 * @property {TaskConnection[]} connections
 */

/**
 * @typedef {Object} Point
 * @property {number} x
 * @property {number} y
 */
