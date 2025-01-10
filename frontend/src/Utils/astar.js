import { BinaryHeap } from "./binaryHeap";

/**
 * @template T
 * @typedef {Object} AStarNode
 * @property {number} x - The x index where this node is on the matrix
 * @property {number} y - The y index where this node is on the matrix
 * @property {number} f - g + cost + h
 * @property {number} g - The shortest path from start to this node.
 * @property {number} h - The shortest path from end to this node.
 * @property {number} cost - The extra cost to go to this node. By default should be 1.
 * @property {boolean} visited - Whether or not this node has been visited. This is different from being closed since we visit neighbors, we close current nodes.
 * @property {boolean} closed - Whether or not this node has already been processed.
 * @property {AStarNode|null} parent - The previous node in the path.
 * @property {T} value - The inner value this node holds
 */

/**
 * @template T
 * Creates a basic node. By default the cost is 1.
 * @param {T} value
 * @param {number} x
 * @param {number} y
 * @returns {AStarNode}
 */
export function createNode(value, x, y) {
	return {
		f: 0,
		g: 0,
		h: 0,
		x,
		y,
		cost: 1,
		visited: false,
		closed: false,
		parent: null,
		value,
	};
}

/**
 * @template T
 * Initializes a node grid
 * @param {T[][]} grid
 * @returns {AStarNode<T>[][]}
 */
function init(grid) {
	const outGrid = [];
	for (let y = 0, yl = grid.length; y < yl; y++) {
		outGrid.push([]);
		for (let x = 0, xl = grid[y].length; x < xl; x++) {
			outGrid[y].push(createNode(grid[y][x], x, y));
		}
	}

	return outGrid;
}

function heap(comparator) {
	return new BinaryHeap(
		(node) => node.f,
		(nodeA, nodeB) => comparator(nodeA.value, nodeB.value),
	);
}

function manhattan(x1, y1, x2, y2) {
	// See list of heuristics: http://theory.stanford.edu/~amitp/GameProgramming/Heuristics.html

	const d1 = Math.abs(x2 - x1);
	const d2 = Math.abs(y2 - y1);
	return d1 + d2;
}

function defaultComparator(a, b) {
	return a === b;
}

function defaultIsWall(a) {
	return !!a;
}

function neighbors(grid, node, diagonals) {
	const ret = [];
	const x = node.x;
	const y = node.y;

	// West
	if (grid[y - 1]?.[x]) {
		ret.push(grid[y - 1][x]);
	}

	// East
	if (grid[y + 1]?.[x]) {
		ret.push(grid[y + 1][x]);
	}

	// South
	if (grid[y]?.[x - 1]) {
		ret.push(grid[y][x - 1]);
	}

	// North
	if (grid[y]?.[x + 1]) {
		ret.push(grid[y][x + 1]);
	}

	// if (diagonals) {
	// 	// Southwest
	// 	if (grid[x - 1] && grid[x - 1][y - 1]) {
	// 		ret.push(grid[x - 1][y - 1]);
	// 	}
	//
	// 	// Southeast
	// 	if (grid[x + 1] && grid[x + 1][y - 1]) {
	// 		ret.push(grid[x + 1][y - 1]);
	// 	}
	//
	// 	// Northwest
	// 	if (grid[x - 1] && grid[x - 1][y + 1]) {
	// 		ret.push(grid[x - 1][y + 1]);
	// 	}
	//
	// 	// Northeast
	// 	if (grid[x + 1] && grid[x + 1][y + 1]) {
	// 		ret.push(grid[x + 1][y + 1]);
	// 	}
	// }

	return ret;
}

/**
 * @template T
 * @callback AStarSearchCallback
 * @param {T[][]} grid
 * @param {T} start
 * @param {T} end
 * @param {boolean} diagonal
 * @param {(a: T, b: T)=>boolean} comparator
 * @param {(a:T, b: T)=>} heuristic
 * @returns {AStarNode<T>[]} The shortest path from start to end
 */

/**
 * @template T
 * @type {AStarSearchCallback<T>}
 */
export function search(
	grid,
	start,
	end,
	diagonal,
	comparator = defaultComparator,
	isWall = defaultIsWall,
	heuristic = manhattan,
) {
	const nodeGrid = init(grid);
	// console.log("NODE GRID:", nodeGrid);

	const openHeap = heap(comparator);
	// If the end === start then we want to keep searching instead of
	// stopping right at the beginning!
	let hasFoundStart = !comparator(end.value, start.value);

	openHeap.push(start);

	while (openHeap.size() > 0) {
		// Grab the lowest f(x) to process next.  Heap keeps this sorted for us.
		const currentNode = openHeap.pop();

		// End case -- result has been found, return the traced path.
		if (comparator(currentNode.value, end.value)) {
			if (!hasFoundStart) {
				hasFoundStart = true;
			} else {
				let curr = currentNode;
				const ret = [];
				while (curr.parent) {
					ret.push(curr);
					curr = curr.parent;
				}
				return ret.reverse();
			}
		}

		// Normal case -- move currentNode from open to closed, process each of its neighbors.
		currentNode.closed = true;

		// Find all neighbors for the current node. Optionally find diagonal neighbors as well (false by default).
		const foundNeighbors = neighbors(nodeGrid, currentNode, diagonal);
		// console.log("VECINOS:", foundNeighbors);

		for (let i = 0, il = foundNeighbors.length; i < il; i++) {
			const neighbor = foundNeighbors[i];
			// console.log("NEIGHBOR:", neighbor);

			if (neighbor.closed || isWall(neighbor.value)) {
				// console.log("CLOSED OR IS WALL");
				// Not a valid node to process, skip to next neighbor.
				continue;
			}

			// The g score is the shortest distance from start to current node.
			// We need to check if the path we have arrived at this neighbor is the shortest one we have seen yet.
			const gScore = currentNode.g + neighbor.cost;
			const beenVisited = neighbor.visited;

			if (!beenVisited || gScore < neighbor.g) {
				// Found an optimal (so far) path to this node.  Take score for node to see how good it is.
				neighbor.visited = true;
				neighbor.parent = currentNode;
				neighbor.h =
					neighbor.h || heuristic(neighbor.x, neighbor.y, end.x, end.y);
				neighbor.g = gScore;
				neighbor.f = neighbor.g + neighbor.h;

				if (!beenVisited) {
					// Pushing to heap will put it in proper place based on the 'f' value.
					openHeap.push(neighbor);
				} else {
					// Already seen the node, but since it has been rescored we need to reorder it in the heap
					openHeap.rescoreElement(neighbor);
				}
			}
		}
	}

	// No result was found - empty array signifies failure to find path.
	return [];
}
