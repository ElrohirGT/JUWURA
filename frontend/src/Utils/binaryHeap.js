/**
 * @template T - The type of the object that will represent a node in the binary heap
 * A binary heap is a structure which has all its values ordered from lowest to greater.
 */
export class BinaryHeap {
	/**
	 * Creates a new binary heap. The `scoreFunction` must always return a number value.
	 * @param {(obj: T)=> number} compareFunction - Function used to order elements.
	 * @param {(a: T, b: T)=> boolean} equalsFunction - Function used to compare elements.
	 */
	constructor(scoreFunction, equalsFunction) {
		this._content = [];
		this.scoreFunction = scoreFunction;
		this.equalsFunction = equalsFunction;
	}
	/**
	 * Adds an element to the heap
	 * @param {T} element
	 */
	push(element) {
		// Add the new element to the end of the array.
		this._content.push(element);
		// Allow it to bubble up.
		this._bubbleUp(this._content.length - 1);
	}

	/**
	 * Removes the element with the least score according to the scoreFunction provided.
	 * @returns {T}
	 */
	pop() {
		// Store the first element so we can return it later.
		const result = this._content[0];
		// Get the element at the end of the array.
		const end = this._content.pop();
		// If there are any elements left, put the end element at the
		// start, and let it sink down.
		if (this._content.length > 0) {
			this._content[0] = end;
			this._sinkdown(0);
		}
		return result;
	}

	/**
	 * Removes an element from the list
	 */
	_remove(node) {
		const length = this._content.length;
		// To remove a value, we must search through the array to find
		// it.
		for (let i = 0; i < length; i++) {
			if (!this.equalsFunction(this._content[i], node)) continue;
			// When it is found, the process seen in 'pop' is repeated
			// to fill up the hole.
			const end = this._content.pop();
			// If the element we popped was the one we needed to remove,
			// we're done.
			if (i === length - 1) break;
			// Otherwise, we replace the removed element with the popped
			// one, and allow it to float up or sink down as appropriate.
			this._content[i] = end;
			this._bubbleUp(i);
			this._sinkdown(i);
			break;
		}
	}

	/**
	 * Returns the number of elements inside the binary heap
	 * @returns {number}
	 */
	size() {
		return this._content.length;
	}

	rescoreElement(node) {
		this._remove(node);
		this._content.unshift(node);
		this._sinkdown(0);
	}

	_bubbleUp(n) {
		// Fetch the element that has to be moved.
		const element = this._content[n];
		const score = this.scoreFunction(element);

		let idx = n;
		// When at 0, an element can not go up any further.
		while (idx > 0) {
			// Compute the parent element's index, and fetch it.
			const parentN = Math.floor((idx + 1) / 2) - 1;
			const parent = this._content[parentN];
			// If the parent has a lesser score, things are in order and we
			// are done.
			if (score >= this.scoreFunction(parent)) break;

			// Otherwise, swap the parent with the current element and
			// continue.
			this._content[parentN] = element;
			this._content[idx] = parent;
			idx = parentN;
		}
	}

	_sinkdown(n) {
		// Look up the target element and its score.
		const length = this._content.length;
		const element = this._content[n];
		const elemScore = this.scoreFunction(element);

		let idx = n;
		while (true) {
			// Compute the indices of the child elements.
			const child2N = (idx + 1) * 2;
			const child1N = child2N - 1;
			// This is used to store the new position of the element,
			// if any.
			let swap = null;
			// If the first child exists (is inside the array)...
			const child1Score = undefined;
			if (child1N < length) {
				// Look it up and compute its score.
				const child1 = this._content[child1N];
				const child1Score = this.scoreFunction(child1);
				// If the score is less than our element's, we need to swap.
				if (child1Score < elemScore) swap = child1N;
			}
			// Do the same checks for the other child.
			if (child2N < length) {
				const child2 = this._content[child2N];
				const child2Score = this.scoreFunction(child2);
				if (child2Score < (swap == null ? elemScore : child1Score))
					swap = child2N;
			}

			// No need to swap further, we are done.
			if (swap == null) break;

			// Otherwise, swap and continue.
			this._content[n] = this._content[swap];
			this._content[swap] = element;
			idx = swap;
		}
	}
}
