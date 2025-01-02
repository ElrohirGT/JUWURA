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
 * @typedef {Object} Point
 * @property {number} x
 * @property {number} y
 */

/**
 * @typedef {Object} CreateTaskEventDetails
 * @property {number} project_id
 * @property {number|null} parent_id
 * @property {string} icon
 */

/**
 * @typedef {"none"|"drag"} SenkuCanvasMode
 */

/**
 * @typedef {Object} SenkuCanvasState
 * @property {number} projectId
 * @property {Cells} cells
 * @property {TaskConnection[]} connections
 * @property {number} scale
 * @property {Point} translatePosition
 * @property {Point|undefined} hoverPos
 * @property {Point} startDragOffset
 * @property {boolean} mouseDown
 * @property {SenkuCanvasMode} mode
 */

export default {};
