
(function() {
'use strict';

function F2(fun)
{
  function wrapper(a) { return function(b) { return fun(a,b); }; }
  wrapper.arity = 2;
  wrapper.func = fun;
  return wrapper;
}

function F3(fun)
{
  function wrapper(a) {
    return function(b) { return function(c) { return fun(a, b, c); }; };
  }
  wrapper.arity = 3;
  wrapper.func = fun;
  return wrapper;
}

function F4(fun)
{
  function wrapper(a) { return function(b) { return function(c) {
    return function(d) { return fun(a, b, c, d); }; }; };
  }
  wrapper.arity = 4;
  wrapper.func = fun;
  return wrapper;
}

function F5(fun)
{
  function wrapper(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return fun(a, b, c, d, e); }; }; }; };
  }
  wrapper.arity = 5;
  wrapper.func = fun;
  return wrapper;
}

function F6(fun)
{
  function wrapper(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return fun(a, b, c, d, e, f); }; }; }; }; };
  }
  wrapper.arity = 6;
  wrapper.func = fun;
  return wrapper;
}

function F7(fun)
{
  function wrapper(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return fun(a, b, c, d, e, f, g); }; }; }; }; }; };
  }
  wrapper.arity = 7;
  wrapper.func = fun;
  return wrapper;
}

function F8(fun)
{
  function wrapper(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) {
    return fun(a, b, c, d, e, f, g, h); }; }; }; }; }; }; };
  }
  wrapper.arity = 8;
  wrapper.func = fun;
  return wrapper;
}

function F9(fun)
{
  function wrapper(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) { return function(i) {
    return fun(a, b, c, d, e, f, g, h, i); }; }; }; }; }; }; }; };
  }
  wrapper.arity = 9;
  wrapper.func = fun;
  return wrapper;
}

function A2(fun, a, b)
{
  return fun.arity === 2
    ? fun.func(a, b)
    : fun(a)(b);
}
function A3(fun, a, b, c)
{
  return fun.arity === 3
    ? fun.func(a, b, c)
    : fun(a)(b)(c);
}
function A4(fun, a, b, c, d)
{
  return fun.arity === 4
    ? fun.func(a, b, c, d)
    : fun(a)(b)(c)(d);
}
function A5(fun, a, b, c, d, e)
{
  return fun.arity === 5
    ? fun.func(a, b, c, d, e)
    : fun(a)(b)(c)(d)(e);
}
function A6(fun, a, b, c, d, e, f)
{
  return fun.arity === 6
    ? fun.func(a, b, c, d, e, f)
    : fun(a)(b)(c)(d)(e)(f);
}
function A7(fun, a, b, c, d, e, f, g)
{
  return fun.arity === 7
    ? fun.func(a, b, c, d, e, f, g)
    : fun(a)(b)(c)(d)(e)(f)(g);
}
function A8(fun, a, b, c, d, e, f, g, h)
{
  return fun.arity === 8
    ? fun.func(a, b, c, d, e, f, g, h)
    : fun(a)(b)(c)(d)(e)(f)(g)(h);
}
function A9(fun, a, b, c, d, e, f, g, h, i)
{
  return fun.arity === 9
    ? fun.func(a, b, c, d, e, f, g, h, i)
    : fun(a)(b)(c)(d)(e)(f)(g)(h)(i);
}

//import Native.List //

var _elm_lang$core$Native_Array = function() {

// A RRB-Tree has two distinct data types.
// Leaf -> "height"  is always 0
//         "table"   is an array of elements
// Node -> "height"  is always greater than 0
//         "table"   is an array of child nodes
//         "lengths" is an array of accumulated lengths of the child nodes

// M is the maximal table size. 32 seems fast. E is the allowed increase
// of search steps when concatting to find an index. Lower values will
// decrease balancing, but will increase search steps.
var M = 32;
var E = 2;

// An empty array.
var empty = {
	ctor: '_Array',
	height: 0,
	table: []
};


function get(i, array)
{
	if (i < 0 || i >= length(array))
	{
		throw new Error(
			'Index ' + i + ' is out of range. Check the length of ' +
			'your array first or use getMaybe or getWithDefault.');
	}
	return unsafeGet(i, array);
}


function unsafeGet(i, array)
{
	for (var x = array.height; x > 0; x--)
	{
		var slot = i >> (x * 5);
		while (array.lengths[slot] <= i)
		{
			slot++;
		}
		if (slot > 0)
		{
			i -= array.lengths[slot - 1];
		}
		array = array.table[slot];
	}
	return array.table[i];
}


// Sets the value at the index i. Only the nodes leading to i will get
// copied and updated.
function set(i, item, array)
{
	if (i < 0 || length(array) <= i)
	{
		return array;
	}
	return unsafeSet(i, item, array);
}


function unsafeSet(i, item, array)
{
	array = nodeCopy(array);

	if (array.height === 0)
	{
		array.table[i] = item;
	}
	else
	{
		var slot = getSlot(i, array);
		if (slot > 0)
		{
			i -= array.lengths[slot - 1];
		}
		array.table[slot] = unsafeSet(i, item, array.table[slot]);
	}
	return array;
}


function initialize(len, f)
{
	if (len <= 0)
	{
		return empty;
	}
	var h = Math.floor( Math.log(len) / Math.log(M) );
	return initialize_(f, h, 0, len);
}

function initialize_(f, h, from, to)
{
	if (h === 0)
	{
		var table = new Array((to - from) % (M + 1));
		for (var i = 0; i < table.length; i++)
		{
		  table[i] = f(from + i);
		}
		return {
			ctor: '_Array',
			height: 0,
			table: table
		};
	}

	var step = Math.pow(M, h);
	var table = new Array(Math.ceil((to - from) / step));
	var lengths = new Array(table.length);
	for (var i = 0; i < table.length; i++)
	{
		table[i] = initialize_(f, h - 1, from + (i * step), Math.min(from + ((i + 1) * step), to));
		lengths[i] = length(table[i]) + (i > 0 ? lengths[i-1] : 0);
	}
	return {
		ctor: '_Array',
		height: h,
		table: table,
		lengths: lengths
	};
}

function fromList(list)
{
	if (list.ctor === '[]')
	{
		return empty;
	}

	// Allocate M sized blocks (table) and write list elements to it.
	var table = new Array(M);
	var nodes = [];
	var i = 0;

	while (list.ctor !== '[]')
	{
		table[i] = list._0;
		list = list._1;
		i++;

		// table is full, so we can push a leaf containing it into the
		// next node.
		if (i === M)
		{
			var leaf = {
				ctor: '_Array',
				height: 0,
				table: table
			};
			fromListPush(leaf, nodes);
			table = new Array(M);
			i = 0;
		}
	}

	// Maybe there is something left on the table.
	if (i > 0)
	{
		var leaf = {
			ctor: '_Array',
			height: 0,
			table: table.splice(0, i)
		};
		fromListPush(leaf, nodes);
	}

	// Go through all of the nodes and eventually push them into higher nodes.
	for (var h = 0; h < nodes.length - 1; h++)
	{
		if (nodes[h].table.length > 0)
		{
			fromListPush(nodes[h], nodes);
		}
	}

	var head = nodes[nodes.length - 1];
	if (head.height > 0 && head.table.length === 1)
	{
		return head.table[0];
	}
	else
	{
		return head;
	}
}

// Push a node into a higher node as a child.
function fromListPush(toPush, nodes)
{
	var h = toPush.height;

	// Maybe the node on this height does not exist.
	if (nodes.length === h)
	{
		var node = {
			ctor: '_Array',
			height: h + 1,
			table: [],
			lengths: []
		};
		nodes.push(node);
	}

	nodes[h].table.push(toPush);
	var len = length(toPush);
	if (nodes[h].lengths.length > 0)
	{
		len += nodes[h].lengths[nodes[h].lengths.length - 1];
	}
	nodes[h].lengths.push(len);

	if (nodes[h].table.length === M)
	{
		fromListPush(nodes[h], nodes);
		nodes[h] = {
			ctor: '_Array',
			height: h + 1,
			table: [],
			lengths: []
		};
	}
}

// Pushes an item via push_ to the bottom right of a tree.
function push(item, a)
{
	var pushed = push_(item, a);
	if (pushed !== null)
	{
		return pushed;
	}

	var newTree = create(item, a.height);
	return siblise(a, newTree);
}

// Recursively tries to push an item to the bottom-right most
// tree possible. If there is no space left for the item,
// null will be returned.
function push_(item, a)
{
	// Handle resursion stop at leaf level.
	if (a.height === 0)
	{
		if (a.table.length < M)
		{
			var newA = {
				ctor: '_Array',
				height: 0,
				table: a.table.slice()
			};
			newA.table.push(item);
			return newA;
		}
		else
		{
		  return null;
		}
	}

	// Recursively push
	var pushed = push_(item, botRight(a));

	// There was space in the bottom right tree, so the slot will
	// be updated.
	if (pushed !== null)
	{
		var newA = nodeCopy(a);
		newA.table[newA.table.length - 1] = pushed;
		newA.lengths[newA.lengths.length - 1]++;
		return newA;
	}

	// When there was no space left, check if there is space left
	// for a new slot with a tree which contains only the item
	// at the bottom.
	if (a.table.length < M)
	{
		var newSlot = create(item, a.height - 1);
		var newA = nodeCopy(a);
		newA.table.push(newSlot);
		newA.lengths.push(newA.lengths[newA.lengths.length - 1] + length(newSlot));
		return newA;
	}
	else
	{
		return null;
	}
}

// Converts an array into a list of elements.
function toList(a)
{
	return toList_(_elm_lang$core$Native_List.Nil, a);
}

function toList_(list, a)
{
	for (var i = a.table.length - 1; i >= 0; i--)
	{
		list =
			a.height === 0
				? _elm_lang$core$Native_List.Cons(a.table[i], list)
				: toList_(list, a.table[i]);
	}
	return list;
}

// Maps a function over the elements of an array.
function map(f, a)
{
	var newA = {
		ctor: '_Array',
		height: a.height,
		table: new Array(a.table.length)
	};
	if (a.height > 0)
	{
		newA.lengths = a.lengths;
	}
	for (var i = 0; i < a.table.length; i++)
	{
		newA.table[i] =
			a.height === 0
				? f(a.table[i])
				: map(f, a.table[i]);
	}
	return newA;
}

// Maps a function over the elements with their index as first argument.
function indexedMap(f, a)
{
	return indexedMap_(f, a, 0);
}

function indexedMap_(f, a, from)
{
	var newA = {
		ctor: '_Array',
		height: a.height,
		table: new Array(a.table.length)
	};
	if (a.height > 0)
	{
		newA.lengths = a.lengths;
	}
	for (var i = 0; i < a.table.length; i++)
	{
		newA.table[i] =
			a.height === 0
				? A2(f, from + i, a.table[i])
				: indexedMap_(f, a.table[i], i == 0 ? from : from + a.lengths[i - 1]);
	}
	return newA;
}

function foldl(f, b, a)
{
	if (a.height === 0)
	{
		for (var i = 0; i < a.table.length; i++)
		{
			b = A2(f, a.table[i], b);
		}
	}
	else
	{
		for (var i = 0; i < a.table.length; i++)
		{
			b = foldl(f, b, a.table[i]);
		}
	}
	return b;
}

function foldr(f, b, a)
{
	if (a.height === 0)
	{
		for (var i = a.table.length; i--; )
		{
			b = A2(f, a.table[i], b);
		}
	}
	else
	{
		for (var i = a.table.length; i--; )
		{
			b = foldr(f, b, a.table[i]);
		}
	}
	return b;
}

// TODO: currently, it slices the right, then the left. This can be
// optimized.
function slice(from, to, a)
{
	if (from < 0)
	{
		from += length(a);
	}
	if (to < 0)
	{
		to += length(a);
	}
	return sliceLeft(from, sliceRight(to, a));
}

function sliceRight(to, a)
{
	if (to === length(a))
	{
		return a;
	}

	// Handle leaf level.
	if (a.height === 0)
	{
		var newA = { ctor:'_Array', height:0 };
		newA.table = a.table.slice(0, to);
		return newA;
	}

	// Slice the right recursively.
	var right = getSlot(to, a);
	var sliced = sliceRight(to - (right > 0 ? a.lengths[right - 1] : 0), a.table[right]);

	// Maybe the a node is not even needed, as sliced contains the whole slice.
	if (right === 0)
	{
		return sliced;
	}

	// Create new node.
	var newA = {
		ctor: '_Array',
		height: a.height,
		table: a.table.slice(0, right),
		lengths: a.lengths.slice(0, right)
	};
	if (sliced.table.length > 0)
	{
		newA.table[right] = sliced;
		newA.lengths[right] = length(sliced) + (right > 0 ? newA.lengths[right - 1] : 0);
	}
	return newA;
}

function sliceLeft(from, a)
{
	if (from === 0)
	{
		return a;
	}

	// Handle leaf level.
	if (a.height === 0)
	{
		var newA = { ctor:'_Array', height:0 };
		newA.table = a.table.slice(from, a.table.length + 1);
		return newA;
	}

	// Slice the left recursively.
	var left = getSlot(from, a);
	var sliced = sliceLeft(from - (left > 0 ? a.lengths[left - 1] : 0), a.table[left]);

	// Maybe the a node is not even needed, as sliced contains the whole slice.
	if (left === a.table.length - 1)
	{
		return sliced;
	}

	// Create new node.
	var newA = {
		ctor: '_Array',
		height: a.height,
		table: a.table.slice(left, a.table.length + 1),
		lengths: new Array(a.table.length - left)
	};
	newA.table[0] = sliced;
	var len = 0;
	for (var i = 0; i < newA.table.length; i++)
	{
		len += length(newA.table[i]);
		newA.lengths[i] = len;
	}

	return newA;
}

// Appends two trees.
function append(a,b)
{
	if (a.table.length === 0)
	{
		return b;
	}
	if (b.table.length === 0)
	{
		return a;
	}

	var c = append_(a, b);

	// Check if both nodes can be crunshed together.
	if (c[0].table.length + c[1].table.length <= M)
	{
		if (c[0].table.length === 0)
		{
			return c[1];
		}
		if (c[1].table.length === 0)
		{
			return c[0];
		}

		// Adjust .table and .lengths
		c[0].table = c[0].table.concat(c[1].table);
		if (c[0].height > 0)
		{
			var len = length(c[0]);
			for (var i = 0; i < c[1].lengths.length; i++)
			{
				c[1].lengths[i] += len;
			}
			c[0].lengths = c[0].lengths.concat(c[1].lengths);
		}

		return c[0];
	}

	if (c[0].height > 0)
	{
		var toRemove = calcToRemove(a, b);
		if (toRemove > E)
		{
			c = shuffle(c[0], c[1], toRemove);
		}
	}

	return siblise(c[0], c[1]);
}

// Returns an array of two nodes; right and left. One node _may_ be empty.
function append_(a, b)
{
	if (a.height === 0 && b.height === 0)
	{
		return [a, b];
	}

	if (a.height !== 1 || b.height !== 1)
	{
		if (a.height === b.height)
		{
			a = nodeCopy(a);
			b = nodeCopy(b);
			var appended = append_(botRight(a), botLeft(b));

			insertRight(a, appended[1]);
			insertLeft(b, appended[0]);
		}
		else if (a.height > b.height)
		{
			a = nodeCopy(a);
			var appended = append_(botRight(a), b);

			insertRight(a, appended[0]);
			b = parentise(appended[1], appended[1].height + 1);
		}
		else
		{
			b = nodeCopy(b);
			var appended = append_(a, botLeft(b));

			var left = appended[0].table.length === 0 ? 0 : 1;
			var right = left === 0 ? 1 : 0;
			insertLeft(b, appended[left]);
			a = parentise(appended[right], appended[right].height + 1);
		}
	}

	// Check if balancing is needed and return based on that.
	if (a.table.length === 0 || b.table.length === 0)
	{
		return [a, b];
	}

	var toRemove = calcToRemove(a, b);
	if (toRemove <= E)
	{
		return [a, b];
	}
	return shuffle(a, b, toRemove);
}

// Helperfunctions for append_. Replaces a child node at the side of the parent.
function insertRight(parent, node)
{
	var index = parent.table.length - 1;
	parent.table[index] = node;
	parent.lengths[index] = length(node);
	parent.lengths[index] += index > 0 ? parent.lengths[index - 1] : 0;
}

function insertLeft(parent, node)
{
	if (node.table.length > 0)
	{
		parent.table[0] = node;
		parent.lengths[0] = length(node);

		var len = length(parent.table[0]);
		for (var i = 1; i < parent.lengths.length; i++)
		{
			len += length(parent.table[i]);
			parent.lengths[i] = len;
		}
	}
	else
	{
		parent.table.shift();
		for (var i = 1; i < parent.lengths.length; i++)
		{
			parent.lengths[i] = parent.lengths[i] - parent.lengths[0];
		}
		parent.lengths.shift();
	}
}

// Returns the extra search steps for E. Refer to the paper.
function calcToRemove(a, b)
{
	var subLengths = 0;
	for (var i = 0; i < a.table.length; i++)
	{
		subLengths += a.table[i].table.length;
	}
	for (var i = 0; i < b.table.length; i++)
	{
		subLengths += b.table[i].table.length;
	}

	var toRemove = a.table.length + b.table.length;
	return toRemove - (Math.floor((subLengths - 1) / M) + 1);
}

// get2, set2 and saveSlot are helpers for accessing elements over two arrays.
function get2(a, b, index)
{
	return index < a.length
		? a[index]
		: b[index - a.length];
}

function set2(a, b, index, value)
{
	if (index < a.length)
	{
		a[index] = value;
	}
	else
	{
		b[index - a.length] = value;
	}
}

function saveSlot(a, b, index, slot)
{
	set2(a.table, b.table, index, slot);

	var l = (index === 0 || index === a.lengths.length)
		? 0
		: get2(a.lengths, a.lengths, index - 1);

	set2(a.lengths, b.lengths, index, l + length(slot));
}

// Creates a node or leaf with a given length at their arrays for perfomance.
// Is only used by shuffle.
function createNode(h, length)
{
	if (length < 0)
	{
		length = 0;
	}
	var a = {
		ctor: '_Array',
		height: h,
		table: new Array(length)
	};
	if (h > 0)
	{
		a.lengths = new Array(length);
	}
	return a;
}

// Returns an array of two balanced nodes.
function shuffle(a, b, toRemove)
{
	var newA = createNode(a.height, Math.min(M, a.table.length + b.table.length - toRemove));
	var newB = createNode(a.height, newA.table.length - (a.table.length + b.table.length - toRemove));

	// Skip the slots with size M. More precise: copy the slot references
	// to the new node
	var read = 0;
	while (get2(a.table, b.table, read).table.length % M === 0)
	{
		set2(newA.table, newB.table, read, get2(a.table, b.table, read));
		set2(newA.lengths, newB.lengths, read, get2(a.lengths, b.lengths, read));
		read++;
	}

	// Pulling items from left to right, caching in a slot before writing
	// it into the new nodes.
	var write = read;
	var slot = new createNode(a.height - 1, 0);
	var from = 0;

	// If the current slot is still containing data, then there will be at
	// least one more write, so we do not break this loop yet.
	while (read - write - (slot.table.length > 0 ? 1 : 0) < toRemove)
	{
		// Find out the max possible items for copying.
		var source = get2(a.table, b.table, read);
		var to = Math.min(M - slot.table.length, source.table.length);

		// Copy and adjust size table.
		slot.table = slot.table.concat(source.table.slice(from, to));
		if (slot.height > 0)
		{
			var len = slot.lengths.length;
			for (var i = len; i < len + to - from; i++)
			{
				slot.lengths[i] = length(slot.table[i]);
				slot.lengths[i] += (i > 0 ? slot.lengths[i - 1] : 0);
			}
		}

		from += to;

		// Only proceed to next slots[i] if the current one was
		// fully copied.
		if (source.table.length <= to)
		{
			read++; from = 0;
		}

		// Only create a new slot if the current one is filled up.
		if (slot.table.length === M)
		{
			saveSlot(newA, newB, write, slot);
			slot = createNode(a.height - 1, 0);
			write++;
		}
	}

	// Cleanup after the loop. Copy the last slot into the new nodes.
	if (slot.table.length > 0)
	{
		saveSlot(newA, newB, write, slot);
		write++;
	}

	// Shift the untouched slots to the left
	while (read < a.table.length + b.table.length )
	{
		saveSlot(newA, newB, write, get2(a.table, b.table, read));
		read++;
		write++;
	}

	return [newA, newB];
}

// Navigation functions
function botRight(a)
{
	return a.table[a.table.length - 1];
}
function botLeft(a)
{
	return a.table[0];
}

// Copies a node for updating. Note that you should not use this if
// only updating only one of "table" or "lengths" for performance reasons.
function nodeCopy(a)
{
	var newA = {
		ctor: '_Array',
		height: a.height,
		table: a.table.slice()
	};
	if (a.height > 0)
	{
		newA.lengths = a.lengths.slice();
	}
	return newA;
}

// Returns how many items are in the tree.
function length(array)
{
	if (array.height === 0)
	{
		return array.table.length;
	}
	else
	{
		return array.lengths[array.lengths.length - 1];
	}
}

// Calculates in which slot of "table" the item probably is, then
// find the exact slot via forward searching in  "lengths". Returns the index.
function getSlot(i, a)
{
	var slot = i >> (5 * a.height);
	while (a.lengths[slot] <= i)
	{
		slot++;
	}
	return slot;
}

// Recursively creates a tree with a given height containing
// only the given item.
function create(item, h)
{
	if (h === 0)
	{
		return {
			ctor: '_Array',
			height: 0,
			table: [item]
		};
	}
	return {
		ctor: '_Array',
		height: h,
		table: [create(item, h - 1)],
		lengths: [1]
	};
}

// Recursively creates a tree that contains the given tree.
function parentise(tree, h)
{
	if (h === tree.height)
	{
		return tree;
	}

	return {
		ctor: '_Array',
		height: h,
		table: [parentise(tree, h - 1)],
		lengths: [length(tree)]
	};
}

// Emphasizes blood brotherhood beneath two trees.
function siblise(a, b)
{
	return {
		ctor: '_Array',
		height: a.height + 1,
		table: [a, b],
		lengths: [length(a), length(a) + length(b)]
	};
}

function toJSArray(a)
{
	var jsArray = new Array(length(a));
	toJSArray_(jsArray, 0, a);
	return jsArray;
}

function toJSArray_(jsArray, i, a)
{
	for (var t = 0; t < a.table.length; t++)
	{
		if (a.height === 0)
		{
			jsArray[i + t] = a.table[t];
		}
		else
		{
			var inc = t === 0 ? 0 : a.lengths[t - 1];
			toJSArray_(jsArray, i + inc, a.table[t]);
		}
	}
}

function fromJSArray(jsArray)
{
	if (jsArray.length === 0)
	{
		return empty;
	}
	var h = Math.floor(Math.log(jsArray.length) / Math.log(M));
	return fromJSArray_(jsArray, h, 0, jsArray.length);
}

function fromJSArray_(jsArray, h, from, to)
{
	if (h === 0)
	{
		return {
			ctor: '_Array',
			height: 0,
			table: jsArray.slice(from, to)
		};
	}

	var step = Math.pow(M, h);
	var table = new Array(Math.ceil((to - from) / step));
	var lengths = new Array(table.length);
	for (var i = 0; i < table.length; i++)
	{
		table[i] = fromJSArray_(jsArray, h - 1, from + (i * step), Math.min(from + ((i + 1) * step), to));
		lengths[i] = length(table[i]) + (i > 0 ? lengths[i - 1] : 0);
	}
	return {
		ctor: '_Array',
		height: h,
		table: table,
		lengths: lengths
	};
}

return {
	empty: empty,
	fromList: fromList,
	toList: toList,
	initialize: F2(initialize),
	append: F2(append),
	push: F2(push),
	slice: F3(slice),
	get: F2(get),
	set: F3(set),
	map: F2(map),
	indexedMap: F2(indexedMap),
	foldl: F3(foldl),
	foldr: F3(foldr),
	length: length,

	toJSArray: toJSArray,
	fromJSArray: fromJSArray
};

}();
//import Native.Utils //

var _elm_lang$core$Native_Basics = function() {

function div(a, b)
{
	return (a / b) | 0;
}
function rem(a, b)
{
	return a % b;
}
function mod(a, b)
{
	if (b === 0)
	{
		throw new Error('Cannot perform mod 0. Division by zero error.');
	}
	var r = a % b;
	var m = a === 0 ? 0 : (b > 0 ? (a >= 0 ? r : r + b) : -mod(-a, -b));

	return m === b ? 0 : m;
}
function logBase(base, n)
{
	return Math.log(n) / Math.log(base);
}
function negate(n)
{
	return -n;
}
function abs(n)
{
	return n < 0 ? -n : n;
}

function min(a, b)
{
	return _elm_lang$core$Native_Utils.cmp(a, b) < 0 ? a : b;
}
function max(a, b)
{
	return _elm_lang$core$Native_Utils.cmp(a, b) > 0 ? a : b;
}
function clamp(lo, hi, n)
{
	return _elm_lang$core$Native_Utils.cmp(n, lo) < 0
		? lo
		: _elm_lang$core$Native_Utils.cmp(n, hi) > 0
			? hi
			: n;
}

var ord = ['LT', 'EQ', 'GT'];

function compare(x, y)
{
	return { ctor: ord[_elm_lang$core$Native_Utils.cmp(x, y) + 1] };
}

function xor(a, b)
{
	return a !== b;
}
function not(b)
{
	return !b;
}
function isInfinite(n)
{
	return n === Infinity || n === -Infinity;
}

function truncate(n)
{
	return n | 0;
}

function degrees(d)
{
	return d * Math.PI / 180;
}
function turns(t)
{
	return 2 * Math.PI * t;
}
function fromPolar(point)
{
	var r = point._0;
	var t = point._1;
	return _elm_lang$core$Native_Utils.Tuple2(r * Math.cos(t), r * Math.sin(t));
}
function toPolar(point)
{
	var x = point._0;
	var y = point._1;
	return _elm_lang$core$Native_Utils.Tuple2(Math.sqrt(x * x + y * y), Math.atan2(y, x));
}

return {
	div: F2(div),
	rem: F2(rem),
	mod: F2(mod),

	pi: Math.PI,
	e: Math.E,
	cos: Math.cos,
	sin: Math.sin,
	tan: Math.tan,
	acos: Math.acos,
	asin: Math.asin,
	atan: Math.atan,
	atan2: F2(Math.atan2),

	degrees: degrees,
	turns: turns,
	fromPolar: fromPolar,
	toPolar: toPolar,

	sqrt: Math.sqrt,
	logBase: F2(logBase),
	negate: negate,
	abs: abs,
	min: F2(min),
	max: F2(max),
	clamp: F3(clamp),
	compare: F2(compare),

	xor: F2(xor),
	not: not,

	truncate: truncate,
	ceiling: Math.ceil,
	floor: Math.floor,
	round: Math.round,
	toFloat: function(x) { return x; },
	isNaN: isNaN,
	isInfinite: isInfinite
};

}();
//import //

var _elm_lang$core$Native_Utils = function() {

// COMPARISONS

function eq(x, y)
{
	var stack = [];
	var isEqual = eqHelp(x, y, 0, stack);
	var pair;
	while (isEqual && (pair = stack.pop()))
	{
		isEqual = eqHelp(pair.x, pair.y, 0, stack);
	}
	return isEqual;
}


function eqHelp(x, y, depth, stack)
{
	if (depth > 100)
	{
		stack.push({ x: x, y: y });
		return true;
	}

	if (x === y)
	{
		return true;
	}

	if (typeof x !== 'object')
	{
		if (typeof x === 'function')
		{
			throw new Error(
				'Trying to use `(==)` on functions. There is no way to know if functions are "the same" in the Elm sense.'
				+ ' Read more about this at http://package.elm-lang.org/packages/elm-lang/core/latest/Basics#=='
				+ ' which describes why it is this way and what the better version will look like.'
			);
		}
		return false;
	}

	if (x === null || y === null)
	{
		return false
	}

	if (x instanceof Date)
	{
		return x.getTime() === y.getTime();
	}

	if (!('ctor' in x))
	{
		for (var key in x)
		{
			if (!eqHelp(x[key], y[key], depth + 1, stack))
			{
				return false;
			}
		}
		return true;
	}

	// convert Dicts and Sets to lists
	if (x.ctor === 'RBNode_elm_builtin' || x.ctor === 'RBEmpty_elm_builtin')
	{
		x = _elm_lang$core$Dict$toList(x);
		y = _elm_lang$core$Dict$toList(y);
	}
	if (x.ctor === 'Set_elm_builtin')
	{
		x = _elm_lang$core$Set$toList(x);
		y = _elm_lang$core$Set$toList(y);
	}

	// check if lists are equal without recursion
	if (x.ctor === '::')
	{
		var a = x;
		var b = y;
		while (a.ctor === '::' && b.ctor === '::')
		{
			if (!eqHelp(a._0, b._0, depth + 1, stack))
			{
				return false;
			}
			a = a._1;
			b = b._1;
		}
		return a.ctor === b.ctor;
	}

	// check if Arrays are equal
	if (x.ctor === '_Array')
	{
		var xs = _elm_lang$core$Native_Array.toJSArray(x);
		var ys = _elm_lang$core$Native_Array.toJSArray(y);
		if (xs.length !== ys.length)
		{
			return false;
		}
		for (var i = 0; i < xs.length; i++)
		{
			if (!eqHelp(xs[i], ys[i], depth + 1, stack))
			{
				return false;
			}
		}
		return true;
	}

	if (!eqHelp(x.ctor, y.ctor, depth + 1, stack))
	{
		return false;
	}

	for (var key in x)
	{
		if (!eqHelp(x[key], y[key], depth + 1, stack))
		{
			return false;
		}
	}
	return true;
}

// Code in Generate/JavaScript.hs, Basics.js, and List.js depends on
// the particular integer values assigned to LT, EQ, and GT.

var LT = -1, EQ = 0, GT = 1;

function cmp(x, y)
{
	if (typeof x !== 'object')
	{
		return x === y ? EQ : x < y ? LT : GT;
	}

	if (x instanceof String)
	{
		var a = x.valueOf();
		var b = y.valueOf();
		return a === b ? EQ : a < b ? LT : GT;
	}

	if (x.ctor === '::' || x.ctor === '[]')
	{
		while (x.ctor === '::' && y.ctor === '::')
		{
			var ord = cmp(x._0, y._0);
			if (ord !== EQ)
			{
				return ord;
			}
			x = x._1;
			y = y._1;
		}
		return x.ctor === y.ctor ? EQ : x.ctor === '[]' ? LT : GT;
	}

	if (x.ctor.slice(0, 6) === '_Tuple')
	{
		var ord;
		var n = x.ctor.slice(6) - 0;
		var err = 'cannot compare tuples with more than 6 elements.';
		if (n === 0) return EQ;
		if (n >= 1) { ord = cmp(x._0, y._0); if (ord !== EQ) return ord;
		if (n >= 2) { ord = cmp(x._1, y._1); if (ord !== EQ) return ord;
		if (n >= 3) { ord = cmp(x._2, y._2); if (ord !== EQ) return ord;
		if (n >= 4) { ord = cmp(x._3, y._3); if (ord !== EQ) return ord;
		if (n >= 5) { ord = cmp(x._4, y._4); if (ord !== EQ) return ord;
		if (n >= 6) { ord = cmp(x._5, y._5); if (ord !== EQ) return ord;
		if (n >= 7) throw new Error('Comparison error: ' + err); } } } } } }
		return EQ;
	}

	throw new Error(
		'Comparison error: comparison is only defined on ints, '
		+ 'floats, times, chars, strings, lists of comparable values, '
		+ 'and tuples of comparable values.'
	);
}


// COMMON VALUES

var Tuple0 = {
	ctor: '_Tuple0'
};

function Tuple2(x, y)
{
	return {
		ctor: '_Tuple2',
		_0: x,
		_1: y
	};
}

function chr(c)
{
	return new String(c);
}


// GUID

var count = 0;
function guid(_)
{
	return count++;
}


// RECORDS

function update(oldRecord, updatedFields)
{
	var newRecord = {};

	for (var key in oldRecord)
	{
		newRecord[key] = oldRecord[key];
	}

	for (var key in updatedFields)
	{
		newRecord[key] = updatedFields[key];
	}

	return newRecord;
}


//// LIST STUFF ////

var Nil = { ctor: '[]' };

function Cons(hd, tl)
{
	return {
		ctor: '::',
		_0: hd,
		_1: tl
	};
}

function append(xs, ys)
{
	// append Strings
	if (typeof xs === 'string')
	{
		return xs + ys;
	}

	// append Lists
	if (xs.ctor === '[]')
	{
		return ys;
	}
	var root = Cons(xs._0, Nil);
	var curr = root;
	xs = xs._1;
	while (xs.ctor !== '[]')
	{
		curr._1 = Cons(xs._0, Nil);
		xs = xs._1;
		curr = curr._1;
	}
	curr._1 = ys;
	return root;
}


// CRASHES

function crash(moduleName, region)
{
	return function(message) {
		throw new Error(
			'Ran into a `Debug.crash` in module `' + moduleName + '` ' + regionToString(region) + '\n'
			+ 'The message provided by the code author is:\n\n    '
			+ message
		);
	};
}

function crashCase(moduleName, region, value)
{
	return function(message) {
		throw new Error(
			'Ran into a `Debug.crash` in module `' + moduleName + '`\n\n'
			+ 'This was caused by the `case` expression ' + regionToString(region) + '.\n'
			+ 'One of the branches ended with a crash and the following value got through:\n\n    ' + toString(value) + '\n\n'
			+ 'The message provided by the code author is:\n\n    '
			+ message
		);
	};
}

function regionToString(region)
{
	if (region.start.line == region.end.line)
	{
		return 'on line ' + region.start.line;
	}
	return 'between lines ' + region.start.line + ' and ' + region.end.line;
}


// TO STRING

function toString(v)
{
	var type = typeof v;
	if (type === 'function')
	{
		return '<function>';
	}

	if (type === 'boolean')
	{
		return v ? 'True' : 'False';
	}

	if (type === 'number')
	{
		return v + '';
	}

	if (v instanceof String)
	{
		return '\'' + addSlashes(v, true) + '\'';
	}

	if (type === 'string')
	{
		return '"' + addSlashes(v, false) + '"';
	}

	if (v === null)
	{
		return 'null';
	}

	if (type === 'object' && 'ctor' in v)
	{
		var ctorStarter = v.ctor.substring(0, 5);

		if (ctorStarter === '_Tupl')
		{
			var output = [];
			for (var k in v)
			{
				if (k === 'ctor') continue;
				output.push(toString(v[k]));
			}
			return '(' + output.join(',') + ')';
		}

		if (ctorStarter === '_Task')
		{
			return '<task>'
		}

		if (v.ctor === '_Array')
		{
			var list = _elm_lang$core$Array$toList(v);
			return 'Array.fromList ' + toString(list);
		}

		if (v.ctor === '<decoder>')
		{
			return '<decoder>';
		}

		if (v.ctor === '_Process')
		{
			return '<process:' + v.id + '>';
		}

		if (v.ctor === '::')
		{
			var output = '[' + toString(v._0);
			v = v._1;
			while (v.ctor === '::')
			{
				output += ',' + toString(v._0);
				v = v._1;
			}
			return output + ']';
		}

		if (v.ctor === '[]')
		{
			return '[]';
		}

		if (v.ctor === 'Set_elm_builtin')
		{
			return 'Set.fromList ' + toString(_elm_lang$core$Set$toList(v));
		}

		if (v.ctor === 'RBNode_elm_builtin' || v.ctor === 'RBEmpty_elm_builtin')
		{
			return 'Dict.fromList ' + toString(_elm_lang$core$Dict$toList(v));
		}

		var output = '';
		for (var i in v)
		{
			if (i === 'ctor') continue;
			var str = toString(v[i]);
			var c0 = str[0];
			var parenless = c0 === '{' || c0 === '(' || c0 === '<' || c0 === '"' || str.indexOf(' ') < 0;
			output += ' ' + (parenless ? str : '(' + str + ')');
		}
		return v.ctor + output;
	}

	if (type === 'object')
	{
		if (v instanceof Date)
		{
			return '<' + v.toString() + '>';
		}

		if (v.elm_web_socket)
		{
			return '<websocket>';
		}

		var output = [];
		for (var k in v)
		{
			output.push(k + ' = ' + toString(v[k]));
		}
		if (output.length === 0)
		{
			return '{}';
		}
		return '{ ' + output.join(', ') + ' }';
	}

	return '<internal structure>';
}

function addSlashes(str, isChar)
{
	var s = str.replace(/\\/g, '\\\\')
			  .replace(/\n/g, '\\n')
			  .replace(/\t/g, '\\t')
			  .replace(/\r/g, '\\r')
			  .replace(/\v/g, '\\v')
			  .replace(/\0/g, '\\0');
	if (isChar)
	{
		return s.replace(/\'/g, '\\\'');
	}
	else
	{
		return s.replace(/\"/g, '\\"');
	}
}


return {
	eq: eq,
	cmp: cmp,
	Tuple0: Tuple0,
	Tuple2: Tuple2,
	chr: chr,
	update: update,
	guid: guid,

	append: F2(append),

	crash: crash,
	crashCase: crashCase,

	toString: toString
};

}();
var _elm_lang$core$Basics$never = function (_p0) {
	never:
	while (true) {
		var _p1 = _p0;
		var _v1 = _p1._0;
		_p0 = _v1;
		continue never;
	}
};
var _elm_lang$core$Basics$uncurry = F2(
	function (f, _p2) {
		var _p3 = _p2;
		return A2(f, _p3._0, _p3._1);
	});
var _elm_lang$core$Basics$curry = F3(
	function (f, a, b) {
		return f(
			{ctor: '_Tuple2', _0: a, _1: b});
	});
var _elm_lang$core$Basics$flip = F3(
	function (f, b, a) {
		return A2(f, a, b);
	});
var _elm_lang$core$Basics$always = F2(
	function (a, _p4) {
		return a;
	});
var _elm_lang$core$Basics$identity = function (x) {
	return x;
};
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['<|'] = F2(
	function (f, x) {
		return f(x);
	});
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['|>'] = F2(
	function (x, f) {
		return f(x);
	});
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['>>'] = F3(
	function (f, g, x) {
		return g(
			f(x));
	});
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['<<'] = F3(
	function (g, f, x) {
		return g(
			f(x));
	});
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['++'] = _elm_lang$core$Native_Utils.append;
var _elm_lang$core$Basics$toString = _elm_lang$core$Native_Utils.toString;
var _elm_lang$core$Basics$isInfinite = _elm_lang$core$Native_Basics.isInfinite;
var _elm_lang$core$Basics$isNaN = _elm_lang$core$Native_Basics.isNaN;
var _elm_lang$core$Basics$toFloat = _elm_lang$core$Native_Basics.toFloat;
var _elm_lang$core$Basics$ceiling = _elm_lang$core$Native_Basics.ceiling;
var _elm_lang$core$Basics$floor = _elm_lang$core$Native_Basics.floor;
var _elm_lang$core$Basics$truncate = _elm_lang$core$Native_Basics.truncate;
var _elm_lang$core$Basics$round = _elm_lang$core$Native_Basics.round;
var _elm_lang$core$Basics$not = _elm_lang$core$Native_Basics.not;
var _elm_lang$core$Basics$xor = _elm_lang$core$Native_Basics.xor;
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['||'] = _elm_lang$core$Native_Basics.or;
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['&&'] = _elm_lang$core$Native_Basics.and;
var _elm_lang$core$Basics$max = _elm_lang$core$Native_Basics.max;
var _elm_lang$core$Basics$min = _elm_lang$core$Native_Basics.min;
var _elm_lang$core$Basics$compare = _elm_lang$core$Native_Basics.compare;
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['>='] = _elm_lang$core$Native_Basics.ge;
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['<='] = _elm_lang$core$Native_Basics.le;
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['>'] = _elm_lang$core$Native_Basics.gt;
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['<'] = _elm_lang$core$Native_Basics.lt;
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['/='] = _elm_lang$core$Native_Basics.neq;
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['=='] = _elm_lang$core$Native_Basics.eq;
var _elm_lang$core$Basics$e = _elm_lang$core$Native_Basics.e;
var _elm_lang$core$Basics$pi = _elm_lang$core$Native_Basics.pi;
var _elm_lang$core$Basics$clamp = _elm_lang$core$Native_Basics.clamp;
var _elm_lang$core$Basics$logBase = _elm_lang$core$Native_Basics.logBase;
var _elm_lang$core$Basics$abs = _elm_lang$core$Native_Basics.abs;
var _elm_lang$core$Basics$negate = _elm_lang$core$Native_Basics.negate;
var _elm_lang$core$Basics$sqrt = _elm_lang$core$Native_Basics.sqrt;
var _elm_lang$core$Basics$atan2 = _elm_lang$core$Native_Basics.atan2;
var _elm_lang$core$Basics$atan = _elm_lang$core$Native_Basics.atan;
var _elm_lang$core$Basics$asin = _elm_lang$core$Native_Basics.asin;
var _elm_lang$core$Basics$acos = _elm_lang$core$Native_Basics.acos;
var _elm_lang$core$Basics$tan = _elm_lang$core$Native_Basics.tan;
var _elm_lang$core$Basics$sin = _elm_lang$core$Native_Basics.sin;
var _elm_lang$core$Basics$cos = _elm_lang$core$Native_Basics.cos;
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['^'] = _elm_lang$core$Native_Basics.exp;
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['%'] = _elm_lang$core$Native_Basics.mod;
var _elm_lang$core$Basics$rem = _elm_lang$core$Native_Basics.rem;
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['//'] = _elm_lang$core$Native_Basics.div;
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['/'] = _elm_lang$core$Native_Basics.floatDiv;
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['*'] = _elm_lang$core$Native_Basics.mul;
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['-'] = _elm_lang$core$Native_Basics.sub;
var _elm_lang$core$Basics_ops = _elm_lang$core$Basics_ops || {};
_elm_lang$core$Basics_ops['+'] = _elm_lang$core$Native_Basics.add;
var _elm_lang$core$Basics$toPolar = _elm_lang$core$Native_Basics.toPolar;
var _elm_lang$core$Basics$fromPolar = _elm_lang$core$Native_Basics.fromPolar;
var _elm_lang$core$Basics$turns = _elm_lang$core$Native_Basics.turns;
var _elm_lang$core$Basics$degrees = _elm_lang$core$Native_Basics.degrees;
var _elm_lang$core$Basics$radians = function (t) {
	return t;
};
var _elm_lang$core$Basics$GT = {ctor: 'GT'};
var _elm_lang$core$Basics$EQ = {ctor: 'EQ'};
var _elm_lang$core$Basics$LT = {ctor: 'LT'};
var _elm_lang$core$Basics$JustOneMore = function (a) {
	return {ctor: 'JustOneMore', _0: a};
};

var _elm_lang$core$Maybe$withDefault = F2(
	function ($default, maybe) {
		var _p0 = maybe;
		if (_p0.ctor === 'Just') {
			return _p0._0;
		} else {
			return $default;
		}
	});
var _elm_lang$core$Maybe$Nothing = {ctor: 'Nothing'};
var _elm_lang$core$Maybe$andThen = F2(
	function (callback, maybeValue) {
		var _p1 = maybeValue;
		if (_p1.ctor === 'Just') {
			return callback(_p1._0);
		} else {
			return _elm_lang$core$Maybe$Nothing;
		}
	});
var _elm_lang$core$Maybe$Just = function (a) {
	return {ctor: 'Just', _0: a};
};
var _elm_lang$core$Maybe$map = F2(
	function (f, maybe) {
		var _p2 = maybe;
		if (_p2.ctor === 'Just') {
			return _elm_lang$core$Maybe$Just(
				f(_p2._0));
		} else {
			return _elm_lang$core$Maybe$Nothing;
		}
	});
var _elm_lang$core$Maybe$map2 = F3(
	function (func, ma, mb) {
		var _p3 = {ctor: '_Tuple2', _0: ma, _1: mb};
		if (((_p3.ctor === '_Tuple2') && (_p3._0.ctor === 'Just')) && (_p3._1.ctor === 'Just')) {
			return _elm_lang$core$Maybe$Just(
				A2(func, _p3._0._0, _p3._1._0));
		} else {
			return _elm_lang$core$Maybe$Nothing;
		}
	});
var _elm_lang$core$Maybe$map3 = F4(
	function (func, ma, mb, mc) {
		var _p4 = {ctor: '_Tuple3', _0: ma, _1: mb, _2: mc};
		if ((((_p4.ctor === '_Tuple3') && (_p4._0.ctor === 'Just')) && (_p4._1.ctor === 'Just')) && (_p4._2.ctor === 'Just')) {
			return _elm_lang$core$Maybe$Just(
				A3(func, _p4._0._0, _p4._1._0, _p4._2._0));
		} else {
			return _elm_lang$core$Maybe$Nothing;
		}
	});
var _elm_lang$core$Maybe$map4 = F5(
	function (func, ma, mb, mc, md) {
		var _p5 = {ctor: '_Tuple4', _0: ma, _1: mb, _2: mc, _3: md};
		if (((((_p5.ctor === '_Tuple4') && (_p5._0.ctor === 'Just')) && (_p5._1.ctor === 'Just')) && (_p5._2.ctor === 'Just')) && (_p5._3.ctor === 'Just')) {
			return _elm_lang$core$Maybe$Just(
				A4(func, _p5._0._0, _p5._1._0, _p5._2._0, _p5._3._0));
		} else {
			return _elm_lang$core$Maybe$Nothing;
		}
	});
var _elm_lang$core$Maybe$map5 = F6(
	function (func, ma, mb, mc, md, me) {
		var _p6 = {ctor: '_Tuple5', _0: ma, _1: mb, _2: mc, _3: md, _4: me};
		if ((((((_p6.ctor === '_Tuple5') && (_p6._0.ctor === 'Just')) && (_p6._1.ctor === 'Just')) && (_p6._2.ctor === 'Just')) && (_p6._3.ctor === 'Just')) && (_p6._4.ctor === 'Just')) {
			return _elm_lang$core$Maybe$Just(
				A5(func, _p6._0._0, _p6._1._0, _p6._2._0, _p6._3._0, _p6._4._0));
		} else {
			return _elm_lang$core$Maybe$Nothing;
		}
	});

//import Native.Utils //

var _elm_lang$core$Native_List = function() {

var Nil = { ctor: '[]' };

function Cons(hd, tl)
{
	return { ctor: '::', _0: hd, _1: tl };
}

function fromArray(arr)
{
	var out = Nil;
	for (var i = arr.length; i--; )
	{
		out = Cons(arr[i], out);
	}
	return out;
}

function toArray(xs)
{
	var out = [];
	while (xs.ctor !== '[]')
	{
		out.push(xs._0);
		xs = xs._1;
	}
	return out;
}

function foldr(f, b, xs)
{
	var arr = toArray(xs);
	var acc = b;
	for (var i = arr.length; i--; )
	{
		acc = A2(f, arr[i], acc);
	}
	return acc;
}

function map2(f, xs, ys)
{
	var arr = [];
	while (xs.ctor !== '[]' && ys.ctor !== '[]')
	{
		arr.push(A2(f, xs._0, ys._0));
		xs = xs._1;
		ys = ys._1;
	}
	return fromArray(arr);
}

function map3(f, xs, ys, zs)
{
	var arr = [];
	while (xs.ctor !== '[]' && ys.ctor !== '[]' && zs.ctor !== '[]')
	{
		arr.push(A3(f, xs._0, ys._0, zs._0));
		xs = xs._1;
		ys = ys._1;
		zs = zs._1;
	}
	return fromArray(arr);
}

function map4(f, ws, xs, ys, zs)
{
	var arr = [];
	while (   ws.ctor !== '[]'
		   && xs.ctor !== '[]'
		   && ys.ctor !== '[]'
		   && zs.ctor !== '[]')
	{
		arr.push(A4(f, ws._0, xs._0, ys._0, zs._0));
		ws = ws._1;
		xs = xs._1;
		ys = ys._1;
		zs = zs._1;
	}
	return fromArray(arr);
}

function map5(f, vs, ws, xs, ys, zs)
{
	var arr = [];
	while (   vs.ctor !== '[]'
		   && ws.ctor !== '[]'
		   && xs.ctor !== '[]'
		   && ys.ctor !== '[]'
		   && zs.ctor !== '[]')
	{
		arr.push(A5(f, vs._0, ws._0, xs._0, ys._0, zs._0));
		vs = vs._1;
		ws = ws._1;
		xs = xs._1;
		ys = ys._1;
		zs = zs._1;
	}
	return fromArray(arr);
}

function sortBy(f, xs)
{
	return fromArray(toArray(xs).sort(function(a, b) {
		return _elm_lang$core$Native_Utils.cmp(f(a), f(b));
	}));
}

function sortWith(f, xs)
{
	return fromArray(toArray(xs).sort(function(a, b) {
		var ord = f(a)(b).ctor;
		return ord === 'EQ' ? 0 : ord === 'LT' ? -1 : 1;
	}));
}

return {
	Nil: Nil,
	Cons: Cons,
	cons: F2(Cons),
	toArray: toArray,
	fromArray: fromArray,

	foldr: F3(foldr),

	map2: F3(map2),
	map3: F4(map3),
	map4: F5(map4),
	map5: F6(map5),
	sortBy: F2(sortBy),
	sortWith: F2(sortWith)
};

}();
var _elm_lang$core$List$sortWith = _elm_lang$core$Native_List.sortWith;
var _elm_lang$core$List$sortBy = _elm_lang$core$Native_List.sortBy;
var _elm_lang$core$List$sort = function (xs) {
	return A2(_elm_lang$core$List$sortBy, _elm_lang$core$Basics$identity, xs);
};
var _elm_lang$core$List$singleton = function (value) {
	return {
		ctor: '::',
		_0: value,
		_1: {ctor: '[]'}
	};
};
var _elm_lang$core$List$drop = F2(
	function (n, list) {
		drop:
		while (true) {
			if (_elm_lang$core$Native_Utils.cmp(n, 0) < 1) {
				return list;
			} else {
				var _p0 = list;
				if (_p0.ctor === '[]') {
					return list;
				} else {
					var _v1 = n - 1,
						_v2 = _p0._1;
					n = _v1;
					list = _v2;
					continue drop;
				}
			}
		}
	});
var _elm_lang$core$List$map5 = _elm_lang$core$Native_List.map5;
var _elm_lang$core$List$map4 = _elm_lang$core$Native_List.map4;
var _elm_lang$core$List$map3 = _elm_lang$core$Native_List.map3;
var _elm_lang$core$List$map2 = _elm_lang$core$Native_List.map2;
var _elm_lang$core$List$any = F2(
	function (isOkay, list) {
		any:
		while (true) {
			var _p1 = list;
			if (_p1.ctor === '[]') {
				return false;
			} else {
				if (isOkay(_p1._0)) {
					return true;
				} else {
					var _v4 = isOkay,
						_v5 = _p1._1;
					isOkay = _v4;
					list = _v5;
					continue any;
				}
			}
		}
	});
var _elm_lang$core$List$all = F2(
	function (isOkay, list) {
		return !A2(
			_elm_lang$core$List$any,
			function (_p2) {
				return !isOkay(_p2);
			},
			list);
	});
var _elm_lang$core$List$foldr = _elm_lang$core$Native_List.foldr;
var _elm_lang$core$List$foldl = F3(
	function (func, acc, list) {
		foldl:
		while (true) {
			var _p3 = list;
			if (_p3.ctor === '[]') {
				return acc;
			} else {
				var _v7 = func,
					_v8 = A2(func, _p3._0, acc),
					_v9 = _p3._1;
				func = _v7;
				acc = _v8;
				list = _v9;
				continue foldl;
			}
		}
	});
var _elm_lang$core$List$length = function (xs) {
	return A3(
		_elm_lang$core$List$foldl,
		F2(
			function (_p4, i) {
				return i + 1;
			}),
		0,
		xs);
};
var _elm_lang$core$List$sum = function (numbers) {
	return A3(
		_elm_lang$core$List$foldl,
		F2(
			function (x, y) {
				return x + y;
			}),
		0,
		numbers);
};
var _elm_lang$core$List$product = function (numbers) {
	return A3(
		_elm_lang$core$List$foldl,
		F2(
			function (x, y) {
				return x * y;
			}),
		1,
		numbers);
};
var _elm_lang$core$List$maximum = function (list) {
	var _p5 = list;
	if (_p5.ctor === '::') {
		return _elm_lang$core$Maybe$Just(
			A3(_elm_lang$core$List$foldl, _elm_lang$core$Basics$max, _p5._0, _p5._1));
	} else {
		return _elm_lang$core$Maybe$Nothing;
	}
};
var _elm_lang$core$List$minimum = function (list) {
	var _p6 = list;
	if (_p6.ctor === '::') {
		return _elm_lang$core$Maybe$Just(
			A3(_elm_lang$core$List$foldl, _elm_lang$core$Basics$min, _p6._0, _p6._1));
	} else {
		return _elm_lang$core$Maybe$Nothing;
	}
};
var _elm_lang$core$List$member = F2(
	function (x, xs) {
		return A2(
			_elm_lang$core$List$any,
			function (a) {
				return _elm_lang$core$Native_Utils.eq(a, x);
			},
			xs);
	});
var _elm_lang$core$List$isEmpty = function (xs) {
	var _p7 = xs;
	if (_p7.ctor === '[]') {
		return true;
	} else {
		return false;
	}
};
var _elm_lang$core$List$tail = function (list) {
	var _p8 = list;
	if (_p8.ctor === '::') {
		return _elm_lang$core$Maybe$Just(_p8._1);
	} else {
		return _elm_lang$core$Maybe$Nothing;
	}
};
var _elm_lang$core$List$head = function (list) {
	var _p9 = list;
	if (_p9.ctor === '::') {
		return _elm_lang$core$Maybe$Just(_p9._0);
	} else {
		return _elm_lang$core$Maybe$Nothing;
	}
};
var _elm_lang$core$List_ops = _elm_lang$core$List_ops || {};
_elm_lang$core$List_ops['::'] = _elm_lang$core$Native_List.cons;
var _elm_lang$core$List$map = F2(
	function (f, xs) {
		return A3(
			_elm_lang$core$List$foldr,
			F2(
				function (x, acc) {
					return {
						ctor: '::',
						_0: f(x),
						_1: acc
					};
				}),
			{ctor: '[]'},
			xs);
	});
var _elm_lang$core$List$filter = F2(
	function (pred, xs) {
		var conditionalCons = F2(
			function (front, back) {
				return pred(front) ? {ctor: '::', _0: front, _1: back} : back;
			});
		return A3(
			_elm_lang$core$List$foldr,
			conditionalCons,
			{ctor: '[]'},
			xs);
	});
var _elm_lang$core$List$maybeCons = F3(
	function (f, mx, xs) {
		var _p10 = f(mx);
		if (_p10.ctor === 'Just') {
			return {ctor: '::', _0: _p10._0, _1: xs};
		} else {
			return xs;
		}
	});
var _elm_lang$core$List$filterMap = F2(
	function (f, xs) {
		return A3(
			_elm_lang$core$List$foldr,
			_elm_lang$core$List$maybeCons(f),
			{ctor: '[]'},
			xs);
	});
var _elm_lang$core$List$reverse = function (list) {
	return A3(
		_elm_lang$core$List$foldl,
		F2(
			function (x, y) {
				return {ctor: '::', _0: x, _1: y};
			}),
		{ctor: '[]'},
		list);
};
var _elm_lang$core$List$scanl = F3(
	function (f, b, xs) {
		var scan1 = F2(
			function (x, accAcc) {
				var _p11 = accAcc;
				if (_p11.ctor === '::') {
					return {
						ctor: '::',
						_0: A2(f, x, _p11._0),
						_1: accAcc
					};
				} else {
					return {ctor: '[]'};
				}
			});
		return _elm_lang$core$List$reverse(
			A3(
				_elm_lang$core$List$foldl,
				scan1,
				{
					ctor: '::',
					_0: b,
					_1: {ctor: '[]'}
				},
				xs));
	});
var _elm_lang$core$List$append = F2(
	function (xs, ys) {
		var _p12 = ys;
		if (_p12.ctor === '[]') {
			return xs;
		} else {
			return A3(
				_elm_lang$core$List$foldr,
				F2(
					function (x, y) {
						return {ctor: '::', _0: x, _1: y};
					}),
				ys,
				xs);
		}
	});
var _elm_lang$core$List$concat = function (lists) {
	return A3(
		_elm_lang$core$List$foldr,
		_elm_lang$core$List$append,
		{ctor: '[]'},
		lists);
};
var _elm_lang$core$List$concatMap = F2(
	function (f, list) {
		return _elm_lang$core$List$concat(
			A2(_elm_lang$core$List$map, f, list));
	});
var _elm_lang$core$List$partition = F2(
	function (pred, list) {
		var step = F2(
			function (x, _p13) {
				var _p14 = _p13;
				var _p16 = _p14._0;
				var _p15 = _p14._1;
				return pred(x) ? {
					ctor: '_Tuple2',
					_0: {ctor: '::', _0: x, _1: _p16},
					_1: _p15
				} : {
					ctor: '_Tuple2',
					_0: _p16,
					_1: {ctor: '::', _0: x, _1: _p15}
				};
			});
		return A3(
			_elm_lang$core$List$foldr,
			step,
			{
				ctor: '_Tuple2',
				_0: {ctor: '[]'},
				_1: {ctor: '[]'}
			},
			list);
	});
var _elm_lang$core$List$unzip = function (pairs) {
	var step = F2(
		function (_p18, _p17) {
			var _p19 = _p18;
			var _p20 = _p17;
			return {
				ctor: '_Tuple2',
				_0: {ctor: '::', _0: _p19._0, _1: _p20._0},
				_1: {ctor: '::', _0: _p19._1, _1: _p20._1}
			};
		});
	return A3(
		_elm_lang$core$List$foldr,
		step,
		{
			ctor: '_Tuple2',
			_0: {ctor: '[]'},
			_1: {ctor: '[]'}
		},
		pairs);
};
var _elm_lang$core$List$intersperse = F2(
	function (sep, xs) {
		var _p21 = xs;
		if (_p21.ctor === '[]') {
			return {ctor: '[]'};
		} else {
			var step = F2(
				function (x, rest) {
					return {
						ctor: '::',
						_0: sep,
						_1: {ctor: '::', _0: x, _1: rest}
					};
				});
			var spersed = A3(
				_elm_lang$core$List$foldr,
				step,
				{ctor: '[]'},
				_p21._1);
			return {ctor: '::', _0: _p21._0, _1: spersed};
		}
	});
var _elm_lang$core$List$takeReverse = F3(
	function (n, list, taken) {
		takeReverse:
		while (true) {
			if (_elm_lang$core$Native_Utils.cmp(n, 0) < 1) {
				return taken;
			} else {
				var _p22 = list;
				if (_p22.ctor === '[]') {
					return taken;
				} else {
					var _v23 = n - 1,
						_v24 = _p22._1,
						_v25 = {ctor: '::', _0: _p22._0, _1: taken};
					n = _v23;
					list = _v24;
					taken = _v25;
					continue takeReverse;
				}
			}
		}
	});
var _elm_lang$core$List$takeTailRec = F2(
	function (n, list) {
		return _elm_lang$core$List$reverse(
			A3(
				_elm_lang$core$List$takeReverse,
				n,
				list,
				{ctor: '[]'}));
	});
var _elm_lang$core$List$takeFast = F3(
	function (ctr, n, list) {
		if (_elm_lang$core$Native_Utils.cmp(n, 0) < 1) {
			return {ctor: '[]'};
		} else {
			var _p23 = {ctor: '_Tuple2', _0: n, _1: list};
			_v26_5:
			do {
				_v26_1:
				do {
					if (_p23.ctor === '_Tuple2') {
						if (_p23._1.ctor === '[]') {
							return list;
						} else {
							if (_p23._1._1.ctor === '::') {
								switch (_p23._0) {
									case 1:
										break _v26_1;
									case 2:
										return {
											ctor: '::',
											_0: _p23._1._0,
											_1: {
												ctor: '::',
												_0: _p23._1._1._0,
												_1: {ctor: '[]'}
											}
										};
									case 3:
										if (_p23._1._1._1.ctor === '::') {
											return {
												ctor: '::',
												_0: _p23._1._0,
												_1: {
													ctor: '::',
													_0: _p23._1._1._0,
													_1: {
														ctor: '::',
														_0: _p23._1._1._1._0,
														_1: {ctor: '[]'}
													}
												}
											};
										} else {
											break _v26_5;
										}
									default:
										if ((_p23._1._1._1.ctor === '::') && (_p23._1._1._1._1.ctor === '::')) {
											var _p28 = _p23._1._1._1._0;
											var _p27 = _p23._1._1._0;
											var _p26 = _p23._1._0;
											var _p25 = _p23._1._1._1._1._0;
											var _p24 = _p23._1._1._1._1._1;
											return (_elm_lang$core$Native_Utils.cmp(ctr, 1000) > 0) ? {
												ctor: '::',
												_0: _p26,
												_1: {
													ctor: '::',
													_0: _p27,
													_1: {
														ctor: '::',
														_0: _p28,
														_1: {
															ctor: '::',
															_0: _p25,
															_1: A2(_elm_lang$core$List$takeTailRec, n - 4, _p24)
														}
													}
												}
											} : {
												ctor: '::',
												_0: _p26,
												_1: {
													ctor: '::',
													_0: _p27,
													_1: {
														ctor: '::',
														_0: _p28,
														_1: {
															ctor: '::',
															_0: _p25,
															_1: A3(_elm_lang$core$List$takeFast, ctr + 1, n - 4, _p24)
														}
													}
												}
											};
										} else {
											break _v26_5;
										}
								}
							} else {
								if (_p23._0 === 1) {
									break _v26_1;
								} else {
									break _v26_5;
								}
							}
						}
					} else {
						break _v26_5;
					}
				} while(false);
				return {
					ctor: '::',
					_0: _p23._1._0,
					_1: {ctor: '[]'}
				};
			} while(false);
			return list;
		}
	});
var _elm_lang$core$List$take = F2(
	function (n, list) {
		return A3(_elm_lang$core$List$takeFast, 0, n, list);
	});
var _elm_lang$core$List$repeatHelp = F3(
	function (result, n, value) {
		repeatHelp:
		while (true) {
			if (_elm_lang$core$Native_Utils.cmp(n, 0) < 1) {
				return result;
			} else {
				var _v27 = {ctor: '::', _0: value, _1: result},
					_v28 = n - 1,
					_v29 = value;
				result = _v27;
				n = _v28;
				value = _v29;
				continue repeatHelp;
			}
		}
	});
var _elm_lang$core$List$repeat = F2(
	function (n, value) {
		return A3(
			_elm_lang$core$List$repeatHelp,
			{ctor: '[]'},
			n,
			value);
	});
var _elm_lang$core$List$rangeHelp = F3(
	function (lo, hi, list) {
		rangeHelp:
		while (true) {
			if (_elm_lang$core$Native_Utils.cmp(lo, hi) < 1) {
				var _v30 = lo,
					_v31 = hi - 1,
					_v32 = {ctor: '::', _0: hi, _1: list};
				lo = _v30;
				hi = _v31;
				list = _v32;
				continue rangeHelp;
			} else {
				return list;
			}
		}
	});
var _elm_lang$core$List$range = F2(
	function (lo, hi) {
		return A3(
			_elm_lang$core$List$rangeHelp,
			lo,
			hi,
			{ctor: '[]'});
	});
var _elm_lang$core$List$indexedMap = F2(
	function (f, xs) {
		return A3(
			_elm_lang$core$List$map2,
			f,
			A2(
				_elm_lang$core$List$range,
				0,
				_elm_lang$core$List$length(xs) - 1),
			xs);
	});

var _elm_lang$core$Array$append = _elm_lang$core$Native_Array.append;
var _elm_lang$core$Array$length = _elm_lang$core$Native_Array.length;
var _elm_lang$core$Array$isEmpty = function (array) {
	return _elm_lang$core$Native_Utils.eq(
		_elm_lang$core$Array$length(array),
		0);
};
var _elm_lang$core$Array$slice = _elm_lang$core$Native_Array.slice;
var _elm_lang$core$Array$set = _elm_lang$core$Native_Array.set;
var _elm_lang$core$Array$get = F2(
	function (i, array) {
		return ((_elm_lang$core$Native_Utils.cmp(0, i) < 1) && (_elm_lang$core$Native_Utils.cmp(
			i,
			_elm_lang$core$Native_Array.length(array)) < 0)) ? _elm_lang$core$Maybe$Just(
			A2(_elm_lang$core$Native_Array.get, i, array)) : _elm_lang$core$Maybe$Nothing;
	});
var _elm_lang$core$Array$push = _elm_lang$core$Native_Array.push;
var _elm_lang$core$Array$empty = _elm_lang$core$Native_Array.empty;
var _elm_lang$core$Array$filter = F2(
	function (isOkay, arr) {
		var update = F2(
			function (x, xs) {
				return isOkay(x) ? A2(_elm_lang$core$Native_Array.push, x, xs) : xs;
			});
		return A3(_elm_lang$core$Native_Array.foldl, update, _elm_lang$core$Native_Array.empty, arr);
	});
var _elm_lang$core$Array$foldr = _elm_lang$core$Native_Array.foldr;
var _elm_lang$core$Array$foldl = _elm_lang$core$Native_Array.foldl;
var _elm_lang$core$Array$indexedMap = _elm_lang$core$Native_Array.indexedMap;
var _elm_lang$core$Array$map = _elm_lang$core$Native_Array.map;
var _elm_lang$core$Array$toIndexedList = function (array) {
	return A3(
		_elm_lang$core$List$map2,
		F2(
			function (v0, v1) {
				return {ctor: '_Tuple2', _0: v0, _1: v1};
			}),
		A2(
			_elm_lang$core$List$range,
			0,
			_elm_lang$core$Native_Array.length(array) - 1),
		_elm_lang$core$Native_Array.toList(array));
};
var _elm_lang$core$Array$toList = _elm_lang$core$Native_Array.toList;
var _elm_lang$core$Array$fromList = _elm_lang$core$Native_Array.fromList;
var _elm_lang$core$Array$initialize = _elm_lang$core$Native_Array.initialize;
var _elm_lang$core$Array$repeat = F2(
	function (n, e) {
		return A2(
			_elm_lang$core$Array$initialize,
			n,
			_elm_lang$core$Basics$always(e));
	});
var _elm_lang$core$Array$Array = {ctor: 'Array'};

//import Native.Utils //

var _elm_lang$core$Native_Char = function() {

return {
	fromCode: function(c) { return _elm_lang$core$Native_Utils.chr(String.fromCharCode(c)); },
	toCode: function(c) { return c.charCodeAt(0); },
	toUpper: function(c) { return _elm_lang$core$Native_Utils.chr(c.toUpperCase()); },
	toLower: function(c) { return _elm_lang$core$Native_Utils.chr(c.toLowerCase()); },
	toLocaleUpper: function(c) { return _elm_lang$core$Native_Utils.chr(c.toLocaleUpperCase()); },
	toLocaleLower: function(c) { return _elm_lang$core$Native_Utils.chr(c.toLocaleLowerCase()); }
};

}();
var _elm_lang$core$Char$fromCode = _elm_lang$core$Native_Char.fromCode;
var _elm_lang$core$Char$toCode = _elm_lang$core$Native_Char.toCode;
var _elm_lang$core$Char$toLocaleLower = _elm_lang$core$Native_Char.toLocaleLower;
var _elm_lang$core$Char$toLocaleUpper = _elm_lang$core$Native_Char.toLocaleUpper;
var _elm_lang$core$Char$toLower = _elm_lang$core$Native_Char.toLower;
var _elm_lang$core$Char$toUpper = _elm_lang$core$Native_Char.toUpper;
var _elm_lang$core$Char$isBetween = F3(
	function (low, high, $char) {
		var code = _elm_lang$core$Char$toCode($char);
		return (_elm_lang$core$Native_Utils.cmp(
			code,
			_elm_lang$core$Char$toCode(low)) > -1) && (_elm_lang$core$Native_Utils.cmp(
			code,
			_elm_lang$core$Char$toCode(high)) < 1);
	});
var _elm_lang$core$Char$isUpper = A2(
	_elm_lang$core$Char$isBetween,
	_elm_lang$core$Native_Utils.chr('A'),
	_elm_lang$core$Native_Utils.chr('Z'));
var _elm_lang$core$Char$isLower = A2(
	_elm_lang$core$Char$isBetween,
	_elm_lang$core$Native_Utils.chr('a'),
	_elm_lang$core$Native_Utils.chr('z'));
var _elm_lang$core$Char$isDigit = A2(
	_elm_lang$core$Char$isBetween,
	_elm_lang$core$Native_Utils.chr('0'),
	_elm_lang$core$Native_Utils.chr('9'));
var _elm_lang$core$Char$isOctDigit = A2(
	_elm_lang$core$Char$isBetween,
	_elm_lang$core$Native_Utils.chr('0'),
	_elm_lang$core$Native_Utils.chr('7'));
var _elm_lang$core$Char$isHexDigit = function ($char) {
	return _elm_lang$core$Char$isDigit($char) || (A3(
		_elm_lang$core$Char$isBetween,
		_elm_lang$core$Native_Utils.chr('a'),
		_elm_lang$core$Native_Utils.chr('f'),
		$char) || A3(
		_elm_lang$core$Char$isBetween,
		_elm_lang$core$Native_Utils.chr('A'),
		_elm_lang$core$Native_Utils.chr('F'),
		$char));
};

//import Native.Utils //

var _elm_lang$core$Native_Scheduler = function() {

var MAX_STEPS = 10000;


// TASKS

function succeed(value)
{
	return {
		ctor: '_Task_succeed',
		value: value
	};
}

function fail(error)
{
	return {
		ctor: '_Task_fail',
		value: error
	};
}

function nativeBinding(callback)
{
	return {
		ctor: '_Task_nativeBinding',
		callback: callback,
		cancel: null
	};
}

function andThen(callback, task)
{
	return {
		ctor: '_Task_andThen',
		callback: callback,
		task: task
	};
}

function onError(callback, task)
{
	return {
		ctor: '_Task_onError',
		callback: callback,
		task: task
	};
}

function receive(callback)
{
	return {
		ctor: '_Task_receive',
		callback: callback
	};
}


// PROCESSES

function rawSpawn(task)
{
	var process = {
		ctor: '_Process',
		id: _elm_lang$core$Native_Utils.guid(),
		root: task,
		stack: null,
		mailbox: []
	};

	enqueue(process);

	return process;
}

function spawn(task)
{
	return nativeBinding(function(callback) {
		var process = rawSpawn(task);
		callback(succeed(process));
	});
}

function rawSend(process, msg)
{
	process.mailbox.push(msg);
	enqueue(process);
}

function send(process, msg)
{
	return nativeBinding(function(callback) {
		rawSend(process, msg);
		callback(succeed(_elm_lang$core$Native_Utils.Tuple0));
	});
}

function kill(process)
{
	return nativeBinding(function(callback) {
		var root = process.root;
		if (root.ctor === '_Task_nativeBinding' && root.cancel)
		{
			root.cancel();
		}

		process.root = null;

		callback(succeed(_elm_lang$core$Native_Utils.Tuple0));
	});
}

function sleep(time)
{
	return nativeBinding(function(callback) {
		var id = setTimeout(function() {
			callback(succeed(_elm_lang$core$Native_Utils.Tuple0));
		}, time);

		return function() { clearTimeout(id); };
	});
}


// STEP PROCESSES

function step(numSteps, process)
{
	while (numSteps < MAX_STEPS)
	{
		var ctor = process.root.ctor;

		if (ctor === '_Task_succeed')
		{
			while (process.stack && process.stack.ctor === '_Task_onError')
			{
				process.stack = process.stack.rest;
			}
			if (process.stack === null)
			{
				break;
			}
			process.root = process.stack.callback(process.root.value);
			process.stack = process.stack.rest;
			++numSteps;
			continue;
		}

		if (ctor === '_Task_fail')
		{
			while (process.stack && process.stack.ctor === '_Task_andThen')
			{
				process.stack = process.stack.rest;
			}
			if (process.stack === null)
			{
				break;
			}
			process.root = process.stack.callback(process.root.value);
			process.stack = process.stack.rest;
			++numSteps;
			continue;
		}

		if (ctor === '_Task_andThen')
		{
			process.stack = {
				ctor: '_Task_andThen',
				callback: process.root.callback,
				rest: process.stack
			};
			process.root = process.root.task;
			++numSteps;
			continue;
		}

		if (ctor === '_Task_onError')
		{
			process.stack = {
				ctor: '_Task_onError',
				callback: process.root.callback,
				rest: process.stack
			};
			process.root = process.root.task;
			++numSteps;
			continue;
		}

		if (ctor === '_Task_nativeBinding')
		{
			process.root.cancel = process.root.callback(function(newRoot) {
				process.root = newRoot;
				enqueue(process);
			});

			break;
		}

		if (ctor === '_Task_receive')
		{
			var mailbox = process.mailbox;
			if (mailbox.length === 0)
			{
				break;
			}

			process.root = process.root.callback(mailbox.shift());
			++numSteps;
			continue;
		}

		throw new Error(ctor);
	}

	if (numSteps < MAX_STEPS)
	{
		return numSteps + 1;
	}
	enqueue(process);

	return numSteps;
}


// WORK QUEUE

var working = false;
var workQueue = [];

function enqueue(process)
{
	workQueue.push(process);

	if (!working)
	{
		setTimeout(work, 0);
		working = true;
	}
}

function work()
{
	var numSteps = 0;
	var process;
	while (numSteps < MAX_STEPS && (process = workQueue.shift()))
	{
		if (process.root)
		{
			numSteps = step(numSteps, process);
		}
	}
	if (!process)
	{
		working = false;
		return;
	}
	setTimeout(work, 0);
}


return {
	succeed: succeed,
	fail: fail,
	nativeBinding: nativeBinding,
	andThen: F2(andThen),
	onError: F2(onError),
	receive: receive,

	spawn: spawn,
	kill: kill,
	sleep: sleep,
	send: F2(send),

	rawSpawn: rawSpawn,
	rawSend: rawSend
};

}();
//import //

var _elm_lang$core$Native_Platform = function() {


// PROGRAMS

function program(impl)
{
	return function(flagDecoder)
	{
		return function(object, moduleName)
		{
			object['worker'] = function worker(flags)
			{
				if (typeof flags !== 'undefined')
				{
					throw new Error(
						'The `' + moduleName + '` module does not need flags.\n'
						+ 'Call ' + moduleName + '.worker() with no arguments and you should be all set!'
					);
				}

				return initialize(
					impl.init,
					impl.update,
					impl.subscriptions,
					renderer
				);
			};
		};
	};
}

function programWithFlags(impl)
{
	return function(flagDecoder)
	{
		return function(object, moduleName)
		{
			object['worker'] = function worker(flags)
			{
				if (typeof flagDecoder === 'undefined')
				{
					throw new Error(
						'Are you trying to sneak a Never value into Elm? Trickster!\n'
						+ 'It looks like ' + moduleName + '.main is defined with `programWithFlags` but has type `Program Never`.\n'
						+ 'Use `program` instead if you do not want flags.'
					);
				}

				var result = A2(_elm_lang$core$Native_Json.run, flagDecoder, flags);
				if (result.ctor === 'Err')
				{
					throw new Error(
						moduleName + '.worker(...) was called with an unexpected argument.\n'
						+ 'I tried to convert it to an Elm value, but ran into this problem:\n\n'
						+ result._0
					);
				}

				return initialize(
					impl.init(result._0),
					impl.update,
					impl.subscriptions,
					renderer
				);
			};
		};
	};
}

function renderer(enqueue, _)
{
	return function(_) {};
}


// HTML TO PROGRAM

function htmlToProgram(vnode)
{
	var emptyBag = batch(_elm_lang$core$Native_List.Nil);
	var noChange = _elm_lang$core$Native_Utils.Tuple2(
		_elm_lang$core$Native_Utils.Tuple0,
		emptyBag
	);

	return _elm_lang$virtual_dom$VirtualDom$program({
		init: noChange,
		view: function(model) { return main; },
		update: F2(function(msg, model) { return noChange; }),
		subscriptions: function (model) { return emptyBag; }
	});
}


// INITIALIZE A PROGRAM

function initialize(init, update, subscriptions, renderer)
{
	// ambient state
	var managers = {};
	var updateView;

	// init and update state in main process
	var initApp = _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
		var model = init._0;
		updateView = renderer(enqueue, model);
		var cmds = init._1;
		var subs = subscriptions(model);
		dispatchEffects(managers, cmds, subs);
		callback(_elm_lang$core$Native_Scheduler.succeed(model));
	});

	function onMessage(msg, model)
	{
		return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
			var results = A2(update, msg, model);
			model = results._0;
			updateView(model);
			var cmds = results._1;
			var subs = subscriptions(model);
			dispatchEffects(managers, cmds, subs);
			callback(_elm_lang$core$Native_Scheduler.succeed(model));
		});
	}

	var mainProcess = spawnLoop(initApp, onMessage);

	function enqueue(msg)
	{
		_elm_lang$core$Native_Scheduler.rawSend(mainProcess, msg);
	}

	var ports = setupEffects(managers, enqueue);

	return ports ? { ports: ports } : {};
}


// EFFECT MANAGERS

var effectManagers = {};

function setupEffects(managers, callback)
{
	var ports;

	// setup all necessary effect managers
	for (var key in effectManagers)
	{
		var manager = effectManagers[key];

		if (manager.isForeign)
		{
			ports = ports || {};
			ports[key] = manager.tag === 'cmd'
				? setupOutgoingPort(key)
				: setupIncomingPort(key, callback);
		}

		managers[key] = makeManager(manager, callback);
	}

	return ports;
}

function makeManager(info, callback)
{
	var router = {
		main: callback,
		self: undefined
	};

	var tag = info.tag;
	var onEffects = info.onEffects;
	var onSelfMsg = info.onSelfMsg;

	function onMessage(msg, state)
	{
		if (msg.ctor === 'self')
		{
			return A3(onSelfMsg, router, msg._0, state);
		}

		var fx = msg._0;
		switch (tag)
		{
			case 'cmd':
				return A3(onEffects, router, fx.cmds, state);

			case 'sub':
				return A3(onEffects, router, fx.subs, state);

			case 'fx':
				return A4(onEffects, router, fx.cmds, fx.subs, state);
		}
	}

	var process = spawnLoop(info.init, onMessage);
	router.self = process;
	return process;
}

function sendToApp(router, msg)
{
	return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback)
	{
		router.main(msg);
		callback(_elm_lang$core$Native_Scheduler.succeed(_elm_lang$core$Native_Utils.Tuple0));
	});
}

function sendToSelf(router, msg)
{
	return A2(_elm_lang$core$Native_Scheduler.send, router.self, {
		ctor: 'self',
		_0: msg
	});
}


// HELPER for STATEFUL LOOPS

function spawnLoop(init, onMessage)
{
	var andThen = _elm_lang$core$Native_Scheduler.andThen;

	function loop(state)
	{
		var handleMsg = _elm_lang$core$Native_Scheduler.receive(function(msg) {
			return onMessage(msg, state);
		});
		return A2(andThen, loop, handleMsg);
	}

	var task = A2(andThen, loop, init);

	return _elm_lang$core$Native_Scheduler.rawSpawn(task);
}


// BAGS

function leaf(home)
{
	return function(value)
	{
		return {
			type: 'leaf',
			home: home,
			value: value
		};
	};
}

function batch(list)
{
	return {
		type: 'node',
		branches: list
	};
}

function map(tagger, bag)
{
	return {
		type: 'map',
		tagger: tagger,
		tree: bag
	}
}


// PIPE BAGS INTO EFFECT MANAGERS

function dispatchEffects(managers, cmdBag, subBag)
{
	var effectsDict = {};
	gatherEffects(true, cmdBag, effectsDict, null);
	gatherEffects(false, subBag, effectsDict, null);

	for (var home in managers)
	{
		var fx = home in effectsDict
			? effectsDict[home]
			: {
				cmds: _elm_lang$core$Native_List.Nil,
				subs: _elm_lang$core$Native_List.Nil
			};

		_elm_lang$core$Native_Scheduler.rawSend(managers[home], { ctor: 'fx', _0: fx });
	}
}

function gatherEffects(isCmd, bag, effectsDict, taggers)
{
	switch (bag.type)
	{
		case 'leaf':
			var home = bag.home;
			var effect = toEffect(isCmd, home, taggers, bag.value);
			effectsDict[home] = insert(isCmd, effect, effectsDict[home]);
			return;

		case 'node':
			var list = bag.branches;
			while (list.ctor !== '[]')
			{
				gatherEffects(isCmd, list._0, effectsDict, taggers);
				list = list._1;
			}
			return;

		case 'map':
			gatherEffects(isCmd, bag.tree, effectsDict, {
				tagger: bag.tagger,
				rest: taggers
			});
			return;
	}
}

function toEffect(isCmd, home, taggers, value)
{
	function applyTaggers(x)
	{
		var temp = taggers;
		while (temp)
		{
			x = temp.tagger(x);
			temp = temp.rest;
		}
		return x;
	}

	var map = isCmd
		? effectManagers[home].cmdMap
		: effectManagers[home].subMap;

	return A2(map, applyTaggers, value)
}

function insert(isCmd, newEffect, effects)
{
	effects = effects || {
		cmds: _elm_lang$core$Native_List.Nil,
		subs: _elm_lang$core$Native_List.Nil
	};
	if (isCmd)
	{
		effects.cmds = _elm_lang$core$Native_List.Cons(newEffect, effects.cmds);
		return effects;
	}
	effects.subs = _elm_lang$core$Native_List.Cons(newEffect, effects.subs);
	return effects;
}


// PORTS

function checkPortName(name)
{
	if (name in effectManagers)
	{
		throw new Error('There can only be one port named `' + name + '`, but your program has multiple.');
	}
}


// OUTGOING PORTS

function outgoingPort(name, converter)
{
	checkPortName(name);
	effectManagers[name] = {
		tag: 'cmd',
		cmdMap: outgoingPortMap,
		converter: converter,
		isForeign: true
	};
	return leaf(name);
}

var outgoingPortMap = F2(function cmdMap(tagger, value) {
	return value;
});

function setupOutgoingPort(name)
{
	var subs = [];
	var converter = effectManagers[name].converter;

	// CREATE MANAGER

	var init = _elm_lang$core$Native_Scheduler.succeed(null);

	function onEffects(router, cmdList, state)
	{
		while (cmdList.ctor !== '[]')
		{
			// grab a separate reference to subs in case unsubscribe is called
			var currentSubs = subs;
			var value = converter(cmdList._0);
			for (var i = 0; i < currentSubs.length; i++)
			{
				currentSubs[i](value);
			}
			cmdList = cmdList._1;
		}
		return init;
	}

	effectManagers[name].init = init;
	effectManagers[name].onEffects = F3(onEffects);

	// PUBLIC API

	function subscribe(callback)
	{
		subs.push(callback);
	}

	function unsubscribe(callback)
	{
		// copy subs into a new array in case unsubscribe is called within a
		// subscribed callback
		subs = subs.slice();
		var index = subs.indexOf(callback);
		if (index >= 0)
		{
			subs.splice(index, 1);
		}
	}

	return {
		subscribe: subscribe,
		unsubscribe: unsubscribe
	};
}


// INCOMING PORTS

function incomingPort(name, converter)
{
	checkPortName(name);
	effectManagers[name] = {
		tag: 'sub',
		subMap: incomingPortMap,
		converter: converter,
		isForeign: true
	};
	return leaf(name);
}

var incomingPortMap = F2(function subMap(tagger, finalTagger)
{
	return function(value)
	{
		return tagger(finalTagger(value));
	};
});

function setupIncomingPort(name, callback)
{
	var sentBeforeInit = [];
	var subs = _elm_lang$core$Native_List.Nil;
	var converter = effectManagers[name].converter;
	var currentOnEffects = preInitOnEffects;
	var currentSend = preInitSend;

	// CREATE MANAGER

	var init = _elm_lang$core$Native_Scheduler.succeed(null);

	function preInitOnEffects(router, subList, state)
	{
		var postInitResult = postInitOnEffects(router, subList, state);

		for(var i = 0; i < sentBeforeInit.length; i++)
		{
			postInitSend(sentBeforeInit[i]);
		}

		sentBeforeInit = null; // to release objects held in queue
		currentSend = postInitSend;
		currentOnEffects = postInitOnEffects;
		return postInitResult;
	}

	function postInitOnEffects(router, subList, state)
	{
		subs = subList;
		return init;
	}

	function onEffects(router, subList, state)
	{
		return currentOnEffects(router, subList, state);
	}

	effectManagers[name].init = init;
	effectManagers[name].onEffects = F3(onEffects);

	// PUBLIC API

	function preInitSend(value)
	{
		sentBeforeInit.push(value);
	}

	function postInitSend(value)
	{
		var temp = subs;
		while (temp.ctor !== '[]')
		{
			callback(temp._0(value));
			temp = temp._1;
		}
	}

	function send(incomingValue)
	{
		var result = A2(_elm_lang$core$Json_Decode$decodeValue, converter, incomingValue);
		if (result.ctor === 'Err')
		{
			throw new Error('Trying to send an unexpected type of value through port `' + name + '`:\n' + result._0);
		}

		currentSend(result._0);
	}

	return { send: send };
}

return {
	// routers
	sendToApp: F2(sendToApp),
	sendToSelf: F2(sendToSelf),

	// global setup
	effectManagers: effectManagers,
	outgoingPort: outgoingPort,
	incomingPort: incomingPort,

	htmlToProgram: htmlToProgram,
	program: program,
	programWithFlags: programWithFlags,
	initialize: initialize,

	// effect bags
	leaf: leaf,
	batch: batch,
	map: F2(map)
};

}();

var _elm_lang$core$Platform_Cmd$batch = _elm_lang$core$Native_Platform.batch;
var _elm_lang$core$Platform_Cmd$none = _elm_lang$core$Platform_Cmd$batch(
	{ctor: '[]'});
var _elm_lang$core$Platform_Cmd_ops = _elm_lang$core$Platform_Cmd_ops || {};
_elm_lang$core$Platform_Cmd_ops['!'] = F2(
	function (model, commands) {
		return {
			ctor: '_Tuple2',
			_0: model,
			_1: _elm_lang$core$Platform_Cmd$batch(commands)
		};
	});
var _elm_lang$core$Platform_Cmd$map = _elm_lang$core$Native_Platform.map;
var _elm_lang$core$Platform_Cmd$Cmd = {ctor: 'Cmd'};

var _elm_lang$core$Platform_Sub$batch = _elm_lang$core$Native_Platform.batch;
var _elm_lang$core$Platform_Sub$none = _elm_lang$core$Platform_Sub$batch(
	{ctor: '[]'});
var _elm_lang$core$Platform_Sub$map = _elm_lang$core$Native_Platform.map;
var _elm_lang$core$Platform_Sub$Sub = {ctor: 'Sub'};

var _elm_lang$core$Platform$hack = _elm_lang$core$Native_Scheduler.succeed;
var _elm_lang$core$Platform$sendToSelf = _elm_lang$core$Native_Platform.sendToSelf;
var _elm_lang$core$Platform$sendToApp = _elm_lang$core$Native_Platform.sendToApp;
var _elm_lang$core$Platform$programWithFlags = _elm_lang$core$Native_Platform.programWithFlags;
var _elm_lang$core$Platform$program = _elm_lang$core$Native_Platform.program;
var _elm_lang$core$Platform$Program = {ctor: 'Program'};
var _elm_lang$core$Platform$Task = {ctor: 'Task'};
var _elm_lang$core$Platform$ProcessId = {ctor: 'ProcessId'};
var _elm_lang$core$Platform$Router = {ctor: 'Router'};

var _elm_lang$core$Result$toMaybe = function (result) {
	var _p0 = result;
	if (_p0.ctor === 'Ok') {
		return _elm_lang$core$Maybe$Just(_p0._0);
	} else {
		return _elm_lang$core$Maybe$Nothing;
	}
};
var _elm_lang$core$Result$withDefault = F2(
	function (def, result) {
		var _p1 = result;
		if (_p1.ctor === 'Ok') {
			return _p1._0;
		} else {
			return def;
		}
	});
var _elm_lang$core$Result$Err = function (a) {
	return {ctor: 'Err', _0: a};
};
var _elm_lang$core$Result$andThen = F2(
	function (callback, result) {
		var _p2 = result;
		if (_p2.ctor === 'Ok') {
			return callback(_p2._0);
		} else {
			return _elm_lang$core$Result$Err(_p2._0);
		}
	});
var _elm_lang$core$Result$Ok = function (a) {
	return {ctor: 'Ok', _0: a};
};
var _elm_lang$core$Result$map = F2(
	function (func, ra) {
		var _p3 = ra;
		if (_p3.ctor === 'Ok') {
			return _elm_lang$core$Result$Ok(
				func(_p3._0));
		} else {
			return _elm_lang$core$Result$Err(_p3._0);
		}
	});
var _elm_lang$core$Result$map2 = F3(
	function (func, ra, rb) {
		var _p4 = {ctor: '_Tuple2', _0: ra, _1: rb};
		if (_p4._0.ctor === 'Ok') {
			if (_p4._1.ctor === 'Ok') {
				return _elm_lang$core$Result$Ok(
					A2(func, _p4._0._0, _p4._1._0));
			} else {
				return _elm_lang$core$Result$Err(_p4._1._0);
			}
		} else {
			return _elm_lang$core$Result$Err(_p4._0._0);
		}
	});
var _elm_lang$core$Result$map3 = F4(
	function (func, ra, rb, rc) {
		var _p5 = {ctor: '_Tuple3', _0: ra, _1: rb, _2: rc};
		if (_p5._0.ctor === 'Ok') {
			if (_p5._1.ctor === 'Ok') {
				if (_p5._2.ctor === 'Ok') {
					return _elm_lang$core$Result$Ok(
						A3(func, _p5._0._0, _p5._1._0, _p5._2._0));
				} else {
					return _elm_lang$core$Result$Err(_p5._2._0);
				}
			} else {
				return _elm_lang$core$Result$Err(_p5._1._0);
			}
		} else {
			return _elm_lang$core$Result$Err(_p5._0._0);
		}
	});
var _elm_lang$core$Result$map4 = F5(
	function (func, ra, rb, rc, rd) {
		var _p6 = {ctor: '_Tuple4', _0: ra, _1: rb, _2: rc, _3: rd};
		if (_p6._0.ctor === 'Ok') {
			if (_p6._1.ctor === 'Ok') {
				if (_p6._2.ctor === 'Ok') {
					if (_p6._3.ctor === 'Ok') {
						return _elm_lang$core$Result$Ok(
							A4(func, _p6._0._0, _p6._1._0, _p6._2._0, _p6._3._0));
					} else {
						return _elm_lang$core$Result$Err(_p6._3._0);
					}
				} else {
					return _elm_lang$core$Result$Err(_p6._2._0);
				}
			} else {
				return _elm_lang$core$Result$Err(_p6._1._0);
			}
		} else {
			return _elm_lang$core$Result$Err(_p6._0._0);
		}
	});
var _elm_lang$core$Result$map5 = F6(
	function (func, ra, rb, rc, rd, re) {
		var _p7 = {ctor: '_Tuple5', _0: ra, _1: rb, _2: rc, _3: rd, _4: re};
		if (_p7._0.ctor === 'Ok') {
			if (_p7._1.ctor === 'Ok') {
				if (_p7._2.ctor === 'Ok') {
					if (_p7._3.ctor === 'Ok') {
						if (_p7._4.ctor === 'Ok') {
							return _elm_lang$core$Result$Ok(
								A5(func, _p7._0._0, _p7._1._0, _p7._2._0, _p7._3._0, _p7._4._0));
						} else {
							return _elm_lang$core$Result$Err(_p7._4._0);
						}
					} else {
						return _elm_lang$core$Result$Err(_p7._3._0);
					}
				} else {
					return _elm_lang$core$Result$Err(_p7._2._0);
				}
			} else {
				return _elm_lang$core$Result$Err(_p7._1._0);
			}
		} else {
			return _elm_lang$core$Result$Err(_p7._0._0);
		}
	});
var _elm_lang$core$Result$mapError = F2(
	function (f, result) {
		var _p8 = result;
		if (_p8.ctor === 'Ok') {
			return _elm_lang$core$Result$Ok(_p8._0);
		} else {
			return _elm_lang$core$Result$Err(
				f(_p8._0));
		}
	});
var _elm_lang$core$Result$fromMaybe = F2(
	function (err, maybe) {
		var _p9 = maybe;
		if (_p9.ctor === 'Just') {
			return _elm_lang$core$Result$Ok(_p9._0);
		} else {
			return _elm_lang$core$Result$Err(err);
		}
	});

var _elm_lang$core$Task$onError = _elm_lang$core$Native_Scheduler.onError;
var _elm_lang$core$Task$andThen = _elm_lang$core$Native_Scheduler.andThen;
var _elm_lang$core$Task$spawnCmd = F2(
	function (router, _p0) {
		var _p1 = _p0;
		return _elm_lang$core$Native_Scheduler.spawn(
			A2(
				_elm_lang$core$Task$andThen,
				_elm_lang$core$Platform$sendToApp(router),
				_p1._0));
	});
var _elm_lang$core$Task$fail = _elm_lang$core$Native_Scheduler.fail;
var _elm_lang$core$Task$mapError = F2(
	function (convert, task) {
		return A2(
			_elm_lang$core$Task$onError,
			function (_p2) {
				return _elm_lang$core$Task$fail(
					convert(_p2));
			},
			task);
	});
var _elm_lang$core$Task$succeed = _elm_lang$core$Native_Scheduler.succeed;
var _elm_lang$core$Task$map = F2(
	function (func, taskA) {
		return A2(
			_elm_lang$core$Task$andThen,
			function (a) {
				return _elm_lang$core$Task$succeed(
					func(a));
			},
			taskA);
	});
var _elm_lang$core$Task$map2 = F3(
	function (func, taskA, taskB) {
		return A2(
			_elm_lang$core$Task$andThen,
			function (a) {
				return A2(
					_elm_lang$core$Task$andThen,
					function (b) {
						return _elm_lang$core$Task$succeed(
							A2(func, a, b));
					},
					taskB);
			},
			taskA);
	});
var _elm_lang$core$Task$map3 = F4(
	function (func, taskA, taskB, taskC) {
		return A2(
			_elm_lang$core$Task$andThen,
			function (a) {
				return A2(
					_elm_lang$core$Task$andThen,
					function (b) {
						return A2(
							_elm_lang$core$Task$andThen,
							function (c) {
								return _elm_lang$core$Task$succeed(
									A3(func, a, b, c));
							},
							taskC);
					},
					taskB);
			},
			taskA);
	});
var _elm_lang$core$Task$map4 = F5(
	function (func, taskA, taskB, taskC, taskD) {
		return A2(
			_elm_lang$core$Task$andThen,
			function (a) {
				return A2(
					_elm_lang$core$Task$andThen,
					function (b) {
						return A2(
							_elm_lang$core$Task$andThen,
							function (c) {
								return A2(
									_elm_lang$core$Task$andThen,
									function (d) {
										return _elm_lang$core$Task$succeed(
											A4(func, a, b, c, d));
									},
									taskD);
							},
							taskC);
					},
					taskB);
			},
			taskA);
	});
var _elm_lang$core$Task$map5 = F6(
	function (func, taskA, taskB, taskC, taskD, taskE) {
		return A2(
			_elm_lang$core$Task$andThen,
			function (a) {
				return A2(
					_elm_lang$core$Task$andThen,
					function (b) {
						return A2(
							_elm_lang$core$Task$andThen,
							function (c) {
								return A2(
									_elm_lang$core$Task$andThen,
									function (d) {
										return A2(
											_elm_lang$core$Task$andThen,
											function (e) {
												return _elm_lang$core$Task$succeed(
													A5(func, a, b, c, d, e));
											},
											taskE);
									},
									taskD);
							},
							taskC);
					},
					taskB);
			},
			taskA);
	});
var _elm_lang$core$Task$sequence = function (tasks) {
	var _p3 = tasks;
	if (_p3.ctor === '[]') {
		return _elm_lang$core$Task$succeed(
			{ctor: '[]'});
	} else {
		return A3(
			_elm_lang$core$Task$map2,
			F2(
				function (x, y) {
					return {ctor: '::', _0: x, _1: y};
				}),
			_p3._0,
			_elm_lang$core$Task$sequence(_p3._1));
	}
};
var _elm_lang$core$Task$onEffects = F3(
	function (router, commands, state) {
		return A2(
			_elm_lang$core$Task$map,
			function (_p4) {
				return {ctor: '_Tuple0'};
			},
			_elm_lang$core$Task$sequence(
				A2(
					_elm_lang$core$List$map,
					_elm_lang$core$Task$spawnCmd(router),
					commands)));
	});
var _elm_lang$core$Task$init = _elm_lang$core$Task$succeed(
	{ctor: '_Tuple0'});
var _elm_lang$core$Task$onSelfMsg = F3(
	function (_p7, _p6, _p5) {
		return _elm_lang$core$Task$succeed(
			{ctor: '_Tuple0'});
	});
var _elm_lang$core$Task$command = _elm_lang$core$Native_Platform.leaf('Task');
var _elm_lang$core$Task$Perform = function (a) {
	return {ctor: 'Perform', _0: a};
};
var _elm_lang$core$Task$perform = F2(
	function (toMessage, task) {
		return _elm_lang$core$Task$command(
			_elm_lang$core$Task$Perform(
				A2(_elm_lang$core$Task$map, toMessage, task)));
	});
var _elm_lang$core$Task$attempt = F2(
	function (resultToMessage, task) {
		return _elm_lang$core$Task$command(
			_elm_lang$core$Task$Perform(
				A2(
					_elm_lang$core$Task$onError,
					function (_p8) {
						return _elm_lang$core$Task$succeed(
							resultToMessage(
								_elm_lang$core$Result$Err(_p8)));
					},
					A2(
						_elm_lang$core$Task$andThen,
						function (_p9) {
							return _elm_lang$core$Task$succeed(
								resultToMessage(
									_elm_lang$core$Result$Ok(_p9)));
						},
						task))));
	});
var _elm_lang$core$Task$cmdMap = F2(
	function (tagger, _p10) {
		var _p11 = _p10;
		return _elm_lang$core$Task$Perform(
			A2(_elm_lang$core$Task$map, tagger, _p11._0));
	});
_elm_lang$core$Native_Platform.effectManagers['Task'] = {pkg: 'elm-lang/core', init: _elm_lang$core$Task$init, onEffects: _elm_lang$core$Task$onEffects, onSelfMsg: _elm_lang$core$Task$onSelfMsg, tag: 'cmd', cmdMap: _elm_lang$core$Task$cmdMap};

//import Native.Utils //

var _elm_lang$core$Native_Debug = function() {

function log(tag, value)
{
	var msg = tag + ': ' + _elm_lang$core$Native_Utils.toString(value);
	var process = process || {};
	if (process.stdout)
	{
		process.stdout.write(msg);
	}
	else
	{
		console.log(msg);
	}
	return value;
}

function crash(message)
{
	throw new Error(message);
}

return {
	crash: crash,
	log: F2(log)
};

}();
//import Maybe, Native.List, Native.Utils, Result //

var _elm_lang$core$Native_String = function() {

function isEmpty(str)
{
	return str.length === 0;
}
function cons(chr, str)
{
	return chr + str;
}
function uncons(str)
{
	var hd = str[0];
	if (hd)
	{
		return _elm_lang$core$Maybe$Just(_elm_lang$core$Native_Utils.Tuple2(_elm_lang$core$Native_Utils.chr(hd), str.slice(1)));
	}
	return _elm_lang$core$Maybe$Nothing;
}
function append(a, b)
{
	return a + b;
}
function concat(strs)
{
	return _elm_lang$core$Native_List.toArray(strs).join('');
}
function length(str)
{
	return str.length;
}
function map(f, str)
{
	var out = str.split('');
	for (var i = out.length; i--; )
	{
		out[i] = f(_elm_lang$core$Native_Utils.chr(out[i]));
	}
	return out.join('');
}
function filter(pred, str)
{
	return str.split('').map(_elm_lang$core$Native_Utils.chr).filter(pred).join('');
}
function reverse(str)
{
	return str.split('').reverse().join('');
}
function foldl(f, b, str)
{
	var len = str.length;
	for (var i = 0; i < len; ++i)
	{
		b = A2(f, _elm_lang$core$Native_Utils.chr(str[i]), b);
	}
	return b;
}
function foldr(f, b, str)
{
	for (var i = str.length; i--; )
	{
		b = A2(f, _elm_lang$core$Native_Utils.chr(str[i]), b);
	}
	return b;
}
function split(sep, str)
{
	return _elm_lang$core$Native_List.fromArray(str.split(sep));
}
function join(sep, strs)
{
	return _elm_lang$core$Native_List.toArray(strs).join(sep);
}
function repeat(n, str)
{
	var result = '';
	while (n > 0)
	{
		if (n & 1)
		{
			result += str;
		}
		n >>= 1, str += str;
	}
	return result;
}
function slice(start, end, str)
{
	return str.slice(start, end);
}
function left(n, str)
{
	return n < 1 ? '' : str.slice(0, n);
}
function right(n, str)
{
	return n < 1 ? '' : str.slice(-n);
}
function dropLeft(n, str)
{
	return n < 1 ? str : str.slice(n);
}
function dropRight(n, str)
{
	return n < 1 ? str : str.slice(0, -n);
}
function pad(n, chr, str)
{
	var half = (n - str.length) / 2;
	return repeat(Math.ceil(half), chr) + str + repeat(half | 0, chr);
}
function padRight(n, chr, str)
{
	return str + repeat(n - str.length, chr);
}
function padLeft(n, chr, str)
{
	return repeat(n - str.length, chr) + str;
}

function trim(str)
{
	return str.trim();
}
function trimLeft(str)
{
	return str.replace(/^\s+/, '');
}
function trimRight(str)
{
	return str.replace(/\s+$/, '');
}

function words(str)
{
	return _elm_lang$core$Native_List.fromArray(str.trim().split(/\s+/g));
}
function lines(str)
{
	return _elm_lang$core$Native_List.fromArray(str.split(/\r\n|\r|\n/g));
}

function toUpper(str)
{
	return str.toUpperCase();
}
function toLower(str)
{
	return str.toLowerCase();
}

function any(pred, str)
{
	for (var i = str.length; i--; )
	{
		if (pred(_elm_lang$core$Native_Utils.chr(str[i])))
		{
			return true;
		}
	}
	return false;
}
function all(pred, str)
{
	for (var i = str.length; i--; )
	{
		if (!pred(_elm_lang$core$Native_Utils.chr(str[i])))
		{
			return false;
		}
	}
	return true;
}

function contains(sub, str)
{
	return str.indexOf(sub) > -1;
}
function startsWith(sub, str)
{
	return str.indexOf(sub) === 0;
}
function endsWith(sub, str)
{
	return str.length >= sub.length &&
		str.lastIndexOf(sub) === str.length - sub.length;
}
function indexes(sub, str)
{
	var subLen = sub.length;

	if (subLen < 1)
	{
		return _elm_lang$core$Native_List.Nil;
	}

	var i = 0;
	var is = [];

	while ((i = str.indexOf(sub, i)) > -1)
	{
		is.push(i);
		i = i + subLen;
	}

	return _elm_lang$core$Native_List.fromArray(is);
}


function toInt(s)
{
	var len = s.length;

	// if empty
	if (len === 0)
	{
		return intErr(s);
	}

	// if hex
	var c = s[0];
	if (c === '0' && s[1] === 'x')
	{
		for (var i = 2; i < len; ++i)
		{
			var c = s[i];
			if (('0' <= c && c <= '9') || ('A' <= c && c <= 'F') || ('a' <= c && c <= 'f'))
			{
				continue;
			}
			return intErr(s);
		}
		return _elm_lang$core$Result$Ok(parseInt(s, 16));
	}

	// is decimal
	if (c > '9' || (c < '0' && c !== '-' && c !== '+'))
	{
		return intErr(s);
	}
	for (var i = 1; i < len; ++i)
	{
		var c = s[i];
		if (c < '0' || '9' < c)
		{
			return intErr(s);
		}
	}

	return _elm_lang$core$Result$Ok(parseInt(s, 10));
}

function intErr(s)
{
	return _elm_lang$core$Result$Err("could not convert string '" + s + "' to an Int");
}


function toFloat(s)
{
	// check if it is a hex, octal, or binary number
	if (s.length === 0 || /[\sxbo]/.test(s))
	{
		return floatErr(s);
	}
	var n = +s;
	// faster isNaN check
	return n === n ? _elm_lang$core$Result$Ok(n) : floatErr(s);
}

function floatErr(s)
{
	return _elm_lang$core$Result$Err("could not convert string '" + s + "' to a Float");
}


function toList(str)
{
	return _elm_lang$core$Native_List.fromArray(str.split('').map(_elm_lang$core$Native_Utils.chr));
}
function fromList(chars)
{
	return _elm_lang$core$Native_List.toArray(chars).join('');
}

return {
	isEmpty: isEmpty,
	cons: F2(cons),
	uncons: uncons,
	append: F2(append),
	concat: concat,
	length: length,
	map: F2(map),
	filter: F2(filter),
	reverse: reverse,
	foldl: F3(foldl),
	foldr: F3(foldr),

	split: F2(split),
	join: F2(join),
	repeat: F2(repeat),

	slice: F3(slice),
	left: F2(left),
	right: F2(right),
	dropLeft: F2(dropLeft),
	dropRight: F2(dropRight),

	pad: F3(pad),
	padLeft: F3(padLeft),
	padRight: F3(padRight),

	trim: trim,
	trimLeft: trimLeft,
	trimRight: trimRight,

	words: words,
	lines: lines,

	toUpper: toUpper,
	toLower: toLower,

	any: F2(any),
	all: F2(all),

	contains: F2(contains),
	startsWith: F2(startsWith),
	endsWith: F2(endsWith),
	indexes: F2(indexes),

	toInt: toInt,
	toFloat: toFloat,
	toList: toList,
	fromList: fromList
};

}();

var _elm_lang$core$String$fromList = _elm_lang$core$Native_String.fromList;
var _elm_lang$core$String$toList = _elm_lang$core$Native_String.toList;
var _elm_lang$core$String$toFloat = _elm_lang$core$Native_String.toFloat;
var _elm_lang$core$String$toInt = _elm_lang$core$Native_String.toInt;
var _elm_lang$core$String$indices = _elm_lang$core$Native_String.indexes;
var _elm_lang$core$String$indexes = _elm_lang$core$Native_String.indexes;
var _elm_lang$core$String$endsWith = _elm_lang$core$Native_String.endsWith;
var _elm_lang$core$String$startsWith = _elm_lang$core$Native_String.startsWith;
var _elm_lang$core$String$contains = _elm_lang$core$Native_String.contains;
var _elm_lang$core$String$all = _elm_lang$core$Native_String.all;
var _elm_lang$core$String$any = _elm_lang$core$Native_String.any;
var _elm_lang$core$String$toLower = _elm_lang$core$Native_String.toLower;
var _elm_lang$core$String$toUpper = _elm_lang$core$Native_String.toUpper;
var _elm_lang$core$String$lines = _elm_lang$core$Native_String.lines;
var _elm_lang$core$String$words = _elm_lang$core$Native_String.words;
var _elm_lang$core$String$trimRight = _elm_lang$core$Native_String.trimRight;
var _elm_lang$core$String$trimLeft = _elm_lang$core$Native_String.trimLeft;
var _elm_lang$core$String$trim = _elm_lang$core$Native_String.trim;
var _elm_lang$core$String$padRight = _elm_lang$core$Native_String.padRight;
var _elm_lang$core$String$padLeft = _elm_lang$core$Native_String.padLeft;
var _elm_lang$core$String$pad = _elm_lang$core$Native_String.pad;
var _elm_lang$core$String$dropRight = _elm_lang$core$Native_String.dropRight;
var _elm_lang$core$String$dropLeft = _elm_lang$core$Native_String.dropLeft;
var _elm_lang$core$String$right = _elm_lang$core$Native_String.right;
var _elm_lang$core$String$left = _elm_lang$core$Native_String.left;
var _elm_lang$core$String$slice = _elm_lang$core$Native_String.slice;
var _elm_lang$core$String$repeat = _elm_lang$core$Native_String.repeat;
var _elm_lang$core$String$join = _elm_lang$core$Native_String.join;
var _elm_lang$core$String$split = _elm_lang$core$Native_String.split;
var _elm_lang$core$String$foldr = _elm_lang$core$Native_String.foldr;
var _elm_lang$core$String$foldl = _elm_lang$core$Native_String.foldl;
var _elm_lang$core$String$reverse = _elm_lang$core$Native_String.reverse;
var _elm_lang$core$String$filter = _elm_lang$core$Native_String.filter;
var _elm_lang$core$String$map = _elm_lang$core$Native_String.map;
var _elm_lang$core$String$length = _elm_lang$core$Native_String.length;
var _elm_lang$core$String$concat = _elm_lang$core$Native_String.concat;
var _elm_lang$core$String$append = _elm_lang$core$Native_String.append;
var _elm_lang$core$String$uncons = _elm_lang$core$Native_String.uncons;
var _elm_lang$core$String$cons = _elm_lang$core$Native_String.cons;
var _elm_lang$core$String$fromChar = function ($char) {
	return A2(_elm_lang$core$String$cons, $char, '');
};
var _elm_lang$core$String$isEmpty = _elm_lang$core$Native_String.isEmpty;

var _elm_lang$core$Dict$foldr = F3(
	function (f, acc, t) {
		foldr:
		while (true) {
			var _p0 = t;
			if (_p0.ctor === 'RBEmpty_elm_builtin') {
				return acc;
			} else {
				var _v1 = f,
					_v2 = A3(
					f,
					_p0._1,
					_p0._2,
					A3(_elm_lang$core$Dict$foldr, f, acc, _p0._4)),
					_v3 = _p0._3;
				f = _v1;
				acc = _v2;
				t = _v3;
				continue foldr;
			}
		}
	});
var _elm_lang$core$Dict$keys = function (dict) {
	return A3(
		_elm_lang$core$Dict$foldr,
		F3(
			function (key, value, keyList) {
				return {ctor: '::', _0: key, _1: keyList};
			}),
		{ctor: '[]'},
		dict);
};
var _elm_lang$core$Dict$values = function (dict) {
	return A3(
		_elm_lang$core$Dict$foldr,
		F3(
			function (key, value, valueList) {
				return {ctor: '::', _0: value, _1: valueList};
			}),
		{ctor: '[]'},
		dict);
};
var _elm_lang$core$Dict$toList = function (dict) {
	return A3(
		_elm_lang$core$Dict$foldr,
		F3(
			function (key, value, list) {
				return {
					ctor: '::',
					_0: {ctor: '_Tuple2', _0: key, _1: value},
					_1: list
				};
			}),
		{ctor: '[]'},
		dict);
};
var _elm_lang$core$Dict$foldl = F3(
	function (f, acc, dict) {
		foldl:
		while (true) {
			var _p1 = dict;
			if (_p1.ctor === 'RBEmpty_elm_builtin') {
				return acc;
			} else {
				var _v5 = f,
					_v6 = A3(
					f,
					_p1._1,
					_p1._2,
					A3(_elm_lang$core$Dict$foldl, f, acc, _p1._3)),
					_v7 = _p1._4;
				f = _v5;
				acc = _v6;
				dict = _v7;
				continue foldl;
			}
		}
	});
var _elm_lang$core$Dict$merge = F6(
	function (leftStep, bothStep, rightStep, leftDict, rightDict, initialResult) {
		var stepState = F3(
			function (rKey, rValue, _p2) {
				stepState:
				while (true) {
					var _p3 = _p2;
					var _p9 = _p3._1;
					var _p8 = _p3._0;
					var _p4 = _p8;
					if (_p4.ctor === '[]') {
						return {
							ctor: '_Tuple2',
							_0: _p8,
							_1: A3(rightStep, rKey, rValue, _p9)
						};
					} else {
						var _p7 = _p4._1;
						var _p6 = _p4._0._1;
						var _p5 = _p4._0._0;
						if (_elm_lang$core$Native_Utils.cmp(_p5, rKey) < 0) {
							var _v10 = rKey,
								_v11 = rValue,
								_v12 = {
								ctor: '_Tuple2',
								_0: _p7,
								_1: A3(leftStep, _p5, _p6, _p9)
							};
							rKey = _v10;
							rValue = _v11;
							_p2 = _v12;
							continue stepState;
						} else {
							if (_elm_lang$core$Native_Utils.cmp(_p5, rKey) > 0) {
								return {
									ctor: '_Tuple2',
									_0: _p8,
									_1: A3(rightStep, rKey, rValue, _p9)
								};
							} else {
								return {
									ctor: '_Tuple2',
									_0: _p7,
									_1: A4(bothStep, _p5, _p6, rValue, _p9)
								};
							}
						}
					}
				}
			});
		var _p10 = A3(
			_elm_lang$core$Dict$foldl,
			stepState,
			{
				ctor: '_Tuple2',
				_0: _elm_lang$core$Dict$toList(leftDict),
				_1: initialResult
			},
			rightDict);
		var leftovers = _p10._0;
		var intermediateResult = _p10._1;
		return A3(
			_elm_lang$core$List$foldl,
			F2(
				function (_p11, result) {
					var _p12 = _p11;
					return A3(leftStep, _p12._0, _p12._1, result);
				}),
			intermediateResult,
			leftovers);
	});
var _elm_lang$core$Dict$reportRemBug = F4(
	function (msg, c, lgot, rgot) {
		return _elm_lang$core$Native_Debug.crash(
			_elm_lang$core$String$concat(
				{
					ctor: '::',
					_0: 'Internal red-black tree invariant violated, expected ',
					_1: {
						ctor: '::',
						_0: msg,
						_1: {
							ctor: '::',
							_0: ' and got ',
							_1: {
								ctor: '::',
								_0: _elm_lang$core$Basics$toString(c),
								_1: {
									ctor: '::',
									_0: '/',
									_1: {
										ctor: '::',
										_0: lgot,
										_1: {
											ctor: '::',
											_0: '/',
											_1: {
												ctor: '::',
												_0: rgot,
												_1: {
													ctor: '::',
													_0: '\nPlease report this bug to <https://github.com/elm-lang/core/issues>',
													_1: {ctor: '[]'}
												}
											}
										}
									}
								}
							}
						}
					}
				}));
	});
var _elm_lang$core$Dict$isBBlack = function (dict) {
	var _p13 = dict;
	_v14_2:
	do {
		if (_p13.ctor === 'RBNode_elm_builtin') {
			if (_p13._0.ctor === 'BBlack') {
				return true;
			} else {
				break _v14_2;
			}
		} else {
			if (_p13._0.ctor === 'LBBlack') {
				return true;
			} else {
				break _v14_2;
			}
		}
	} while(false);
	return false;
};
var _elm_lang$core$Dict$sizeHelp = F2(
	function (n, dict) {
		sizeHelp:
		while (true) {
			var _p14 = dict;
			if (_p14.ctor === 'RBEmpty_elm_builtin') {
				return n;
			} else {
				var _v16 = A2(_elm_lang$core$Dict$sizeHelp, n + 1, _p14._4),
					_v17 = _p14._3;
				n = _v16;
				dict = _v17;
				continue sizeHelp;
			}
		}
	});
var _elm_lang$core$Dict$size = function (dict) {
	return A2(_elm_lang$core$Dict$sizeHelp, 0, dict);
};
var _elm_lang$core$Dict$get = F2(
	function (targetKey, dict) {
		get:
		while (true) {
			var _p15 = dict;
			if (_p15.ctor === 'RBEmpty_elm_builtin') {
				return _elm_lang$core$Maybe$Nothing;
			} else {
				var _p16 = A2(_elm_lang$core$Basics$compare, targetKey, _p15._1);
				switch (_p16.ctor) {
					case 'LT':
						var _v20 = targetKey,
							_v21 = _p15._3;
						targetKey = _v20;
						dict = _v21;
						continue get;
					case 'EQ':
						return _elm_lang$core$Maybe$Just(_p15._2);
					default:
						var _v22 = targetKey,
							_v23 = _p15._4;
						targetKey = _v22;
						dict = _v23;
						continue get;
				}
			}
		}
	});
var _elm_lang$core$Dict$member = F2(
	function (key, dict) {
		var _p17 = A2(_elm_lang$core$Dict$get, key, dict);
		if (_p17.ctor === 'Just') {
			return true;
		} else {
			return false;
		}
	});
var _elm_lang$core$Dict$maxWithDefault = F3(
	function (k, v, r) {
		maxWithDefault:
		while (true) {
			var _p18 = r;
			if (_p18.ctor === 'RBEmpty_elm_builtin') {
				return {ctor: '_Tuple2', _0: k, _1: v};
			} else {
				var _v26 = _p18._1,
					_v27 = _p18._2,
					_v28 = _p18._4;
				k = _v26;
				v = _v27;
				r = _v28;
				continue maxWithDefault;
			}
		}
	});
var _elm_lang$core$Dict$NBlack = {ctor: 'NBlack'};
var _elm_lang$core$Dict$BBlack = {ctor: 'BBlack'};
var _elm_lang$core$Dict$Black = {ctor: 'Black'};
var _elm_lang$core$Dict$blackish = function (t) {
	var _p19 = t;
	if (_p19.ctor === 'RBNode_elm_builtin') {
		var _p20 = _p19._0;
		return _elm_lang$core$Native_Utils.eq(_p20, _elm_lang$core$Dict$Black) || _elm_lang$core$Native_Utils.eq(_p20, _elm_lang$core$Dict$BBlack);
	} else {
		return true;
	}
};
var _elm_lang$core$Dict$Red = {ctor: 'Red'};
var _elm_lang$core$Dict$moreBlack = function (color) {
	var _p21 = color;
	switch (_p21.ctor) {
		case 'Black':
			return _elm_lang$core$Dict$BBlack;
		case 'Red':
			return _elm_lang$core$Dict$Black;
		case 'NBlack':
			return _elm_lang$core$Dict$Red;
		default:
			return _elm_lang$core$Native_Debug.crash('Can\'t make a double black node more black!');
	}
};
var _elm_lang$core$Dict$lessBlack = function (color) {
	var _p22 = color;
	switch (_p22.ctor) {
		case 'BBlack':
			return _elm_lang$core$Dict$Black;
		case 'Black':
			return _elm_lang$core$Dict$Red;
		case 'Red':
			return _elm_lang$core$Dict$NBlack;
		default:
			return _elm_lang$core$Native_Debug.crash('Can\'t make a negative black node less black!');
	}
};
var _elm_lang$core$Dict$LBBlack = {ctor: 'LBBlack'};
var _elm_lang$core$Dict$LBlack = {ctor: 'LBlack'};
var _elm_lang$core$Dict$RBEmpty_elm_builtin = function (a) {
	return {ctor: 'RBEmpty_elm_builtin', _0: a};
};
var _elm_lang$core$Dict$empty = _elm_lang$core$Dict$RBEmpty_elm_builtin(_elm_lang$core$Dict$LBlack);
var _elm_lang$core$Dict$isEmpty = function (dict) {
	return _elm_lang$core$Native_Utils.eq(dict, _elm_lang$core$Dict$empty);
};
var _elm_lang$core$Dict$RBNode_elm_builtin = F5(
	function (a, b, c, d, e) {
		return {ctor: 'RBNode_elm_builtin', _0: a, _1: b, _2: c, _3: d, _4: e};
	});
var _elm_lang$core$Dict$ensureBlackRoot = function (dict) {
	var _p23 = dict;
	if ((_p23.ctor === 'RBNode_elm_builtin') && (_p23._0.ctor === 'Red')) {
		return A5(_elm_lang$core$Dict$RBNode_elm_builtin, _elm_lang$core$Dict$Black, _p23._1, _p23._2, _p23._3, _p23._4);
	} else {
		return dict;
	}
};
var _elm_lang$core$Dict$lessBlackTree = function (dict) {
	var _p24 = dict;
	if (_p24.ctor === 'RBNode_elm_builtin') {
		return A5(
			_elm_lang$core$Dict$RBNode_elm_builtin,
			_elm_lang$core$Dict$lessBlack(_p24._0),
			_p24._1,
			_p24._2,
			_p24._3,
			_p24._4);
	} else {
		return _elm_lang$core$Dict$RBEmpty_elm_builtin(_elm_lang$core$Dict$LBlack);
	}
};
var _elm_lang$core$Dict$balancedTree = function (col) {
	return function (xk) {
		return function (xv) {
			return function (yk) {
				return function (yv) {
					return function (zk) {
						return function (zv) {
							return function (a) {
								return function (b) {
									return function (c) {
										return function (d) {
											return A5(
												_elm_lang$core$Dict$RBNode_elm_builtin,
												_elm_lang$core$Dict$lessBlack(col),
												yk,
												yv,
												A5(_elm_lang$core$Dict$RBNode_elm_builtin, _elm_lang$core$Dict$Black, xk, xv, a, b),
												A5(_elm_lang$core$Dict$RBNode_elm_builtin, _elm_lang$core$Dict$Black, zk, zv, c, d));
										};
									};
								};
							};
						};
					};
				};
			};
		};
	};
};
var _elm_lang$core$Dict$blacken = function (t) {
	var _p25 = t;
	if (_p25.ctor === 'RBEmpty_elm_builtin') {
		return _elm_lang$core$Dict$RBEmpty_elm_builtin(_elm_lang$core$Dict$LBlack);
	} else {
		return A5(_elm_lang$core$Dict$RBNode_elm_builtin, _elm_lang$core$Dict$Black, _p25._1, _p25._2, _p25._3, _p25._4);
	}
};
var _elm_lang$core$Dict$redden = function (t) {
	var _p26 = t;
	if (_p26.ctor === 'RBEmpty_elm_builtin') {
		return _elm_lang$core$Native_Debug.crash('can\'t make a Leaf red');
	} else {
		return A5(_elm_lang$core$Dict$RBNode_elm_builtin, _elm_lang$core$Dict$Red, _p26._1, _p26._2, _p26._3, _p26._4);
	}
};
var _elm_lang$core$Dict$balanceHelp = function (tree) {
	var _p27 = tree;
	_v36_6:
	do {
		_v36_5:
		do {
			_v36_4:
			do {
				_v36_3:
				do {
					_v36_2:
					do {
						_v36_1:
						do {
							_v36_0:
							do {
								if (_p27.ctor === 'RBNode_elm_builtin') {
									if (_p27._3.ctor === 'RBNode_elm_builtin') {
										if (_p27._4.ctor === 'RBNode_elm_builtin') {
											switch (_p27._3._0.ctor) {
												case 'Red':
													switch (_p27._4._0.ctor) {
														case 'Red':
															if ((_p27._3._3.ctor === 'RBNode_elm_builtin') && (_p27._3._3._0.ctor === 'Red')) {
																break _v36_0;
															} else {
																if ((_p27._3._4.ctor === 'RBNode_elm_builtin') && (_p27._3._4._0.ctor === 'Red')) {
																	break _v36_1;
																} else {
																	if ((_p27._4._3.ctor === 'RBNode_elm_builtin') && (_p27._4._3._0.ctor === 'Red')) {
																		break _v36_2;
																	} else {
																		if ((_p27._4._4.ctor === 'RBNode_elm_builtin') && (_p27._4._4._0.ctor === 'Red')) {
																			break _v36_3;
																		} else {
																			break _v36_6;
																		}
																	}
																}
															}
														case 'NBlack':
															if ((_p27._3._3.ctor === 'RBNode_elm_builtin') && (_p27._3._3._0.ctor === 'Red')) {
																break _v36_0;
															} else {
																if ((_p27._3._4.ctor === 'RBNode_elm_builtin') && (_p27._3._4._0.ctor === 'Red')) {
																	break _v36_1;
																} else {
																	if (((((_p27._0.ctor === 'BBlack') && (_p27._4._3.ctor === 'RBNode_elm_builtin')) && (_p27._4._3._0.ctor === 'Black')) && (_p27._4._4.ctor === 'RBNode_elm_builtin')) && (_p27._4._4._0.ctor === 'Black')) {
																		break _v36_4;
																	} else {
																		break _v36_6;
																	}
																}
															}
														default:
															if ((_p27._3._3.ctor === 'RBNode_elm_builtin') && (_p27._3._3._0.ctor === 'Red')) {
																break _v36_0;
															} else {
																if ((_p27._3._4.ctor === 'RBNode_elm_builtin') && (_p27._3._4._0.ctor === 'Red')) {
																	break _v36_1;
																} else {
																	break _v36_6;
																}
															}
													}
												case 'NBlack':
													switch (_p27._4._0.ctor) {
														case 'Red':
															if ((_p27._4._3.ctor === 'RBNode_elm_builtin') && (_p27._4._3._0.ctor === 'Red')) {
																break _v36_2;
															} else {
																if ((_p27._4._4.ctor === 'RBNode_elm_builtin') && (_p27._4._4._0.ctor === 'Red')) {
																	break _v36_3;
																} else {
																	if (((((_p27._0.ctor === 'BBlack') && (_p27._3._3.ctor === 'RBNode_elm_builtin')) && (_p27._3._3._0.ctor === 'Black')) && (_p27._3._4.ctor === 'RBNode_elm_builtin')) && (_p27._3._4._0.ctor === 'Black')) {
																		break _v36_5;
																	} else {
																		break _v36_6;
																	}
																}
															}
														case 'NBlack':
															if (_p27._0.ctor === 'BBlack') {
																if ((((_p27._4._3.ctor === 'RBNode_elm_builtin') && (_p27._4._3._0.ctor === 'Black')) && (_p27._4._4.ctor === 'RBNode_elm_builtin')) && (_p27._4._4._0.ctor === 'Black')) {
																	break _v36_4;
																} else {
																	if ((((_p27._3._3.ctor === 'RBNode_elm_builtin') && (_p27._3._3._0.ctor === 'Black')) && (_p27._3._4.ctor === 'RBNode_elm_builtin')) && (_p27._3._4._0.ctor === 'Black')) {
																		break _v36_5;
																	} else {
																		break _v36_6;
																	}
																}
															} else {
																break _v36_6;
															}
														default:
															if (((((_p27._0.ctor === 'BBlack') && (_p27._3._3.ctor === 'RBNode_elm_builtin')) && (_p27._3._3._0.ctor === 'Black')) && (_p27._3._4.ctor === 'RBNode_elm_builtin')) && (_p27._3._4._0.ctor === 'Black')) {
																break _v36_5;
															} else {
																break _v36_6;
															}
													}
												default:
													switch (_p27._4._0.ctor) {
														case 'Red':
															if ((_p27._4._3.ctor === 'RBNode_elm_builtin') && (_p27._4._3._0.ctor === 'Red')) {
																break _v36_2;
															} else {
																if ((_p27._4._4.ctor === 'RBNode_elm_builtin') && (_p27._4._4._0.ctor === 'Red')) {
																	break _v36_3;
																} else {
																	break _v36_6;
																}
															}
														case 'NBlack':
															if (((((_p27._0.ctor === 'BBlack') && (_p27._4._3.ctor === 'RBNode_elm_builtin')) && (_p27._4._3._0.ctor === 'Black')) && (_p27._4._4.ctor === 'RBNode_elm_builtin')) && (_p27._4._4._0.ctor === 'Black')) {
																break _v36_4;
															} else {
																break _v36_6;
															}
														default:
															break _v36_6;
													}
											}
										} else {
											switch (_p27._3._0.ctor) {
												case 'Red':
													if ((_p27._3._3.ctor === 'RBNode_elm_builtin') && (_p27._3._3._0.ctor === 'Red')) {
														break _v36_0;
													} else {
														if ((_p27._3._4.ctor === 'RBNode_elm_builtin') && (_p27._3._4._0.ctor === 'Red')) {
															break _v36_1;
														} else {
															break _v36_6;
														}
													}
												case 'NBlack':
													if (((((_p27._0.ctor === 'BBlack') && (_p27._3._3.ctor === 'RBNode_elm_builtin')) && (_p27._3._3._0.ctor === 'Black')) && (_p27._3._4.ctor === 'RBNode_elm_builtin')) && (_p27._3._4._0.ctor === 'Black')) {
														break _v36_5;
													} else {
														break _v36_6;
													}
												default:
													break _v36_6;
											}
										}
									} else {
										if (_p27._4.ctor === 'RBNode_elm_builtin') {
											switch (_p27._4._0.ctor) {
												case 'Red':
													if ((_p27._4._3.ctor === 'RBNode_elm_builtin') && (_p27._4._3._0.ctor === 'Red')) {
														break _v36_2;
													} else {
														if ((_p27._4._4.ctor === 'RBNode_elm_builtin') && (_p27._4._4._0.ctor === 'Red')) {
															break _v36_3;
														} else {
															break _v36_6;
														}
													}
												case 'NBlack':
													if (((((_p27._0.ctor === 'BBlack') && (_p27._4._3.ctor === 'RBNode_elm_builtin')) && (_p27._4._3._0.ctor === 'Black')) && (_p27._4._4.ctor === 'RBNode_elm_builtin')) && (_p27._4._4._0.ctor === 'Black')) {
														break _v36_4;
													} else {
														break _v36_6;
													}
												default:
													break _v36_6;
											}
										} else {
											break _v36_6;
										}
									}
								} else {
									break _v36_6;
								}
							} while(false);
							return _elm_lang$core$Dict$balancedTree(_p27._0)(_p27._3._3._1)(_p27._3._3._2)(_p27._3._1)(_p27._3._2)(_p27._1)(_p27._2)(_p27._3._3._3)(_p27._3._3._4)(_p27._3._4)(_p27._4);
						} while(false);
						return _elm_lang$core$Dict$balancedTree(_p27._0)(_p27._3._1)(_p27._3._2)(_p27._3._4._1)(_p27._3._4._2)(_p27._1)(_p27._2)(_p27._3._3)(_p27._3._4._3)(_p27._3._4._4)(_p27._4);
					} while(false);
					return _elm_lang$core$Dict$balancedTree(_p27._0)(_p27._1)(_p27._2)(_p27._4._3._1)(_p27._4._3._2)(_p27._4._1)(_p27._4._2)(_p27._3)(_p27._4._3._3)(_p27._4._3._4)(_p27._4._4);
				} while(false);
				return _elm_lang$core$Dict$balancedTree(_p27._0)(_p27._1)(_p27._2)(_p27._4._1)(_p27._4._2)(_p27._4._4._1)(_p27._4._4._2)(_p27._3)(_p27._4._3)(_p27._4._4._3)(_p27._4._4._4);
			} while(false);
			return A5(
				_elm_lang$core$Dict$RBNode_elm_builtin,
				_elm_lang$core$Dict$Black,
				_p27._4._3._1,
				_p27._4._3._2,
				A5(_elm_lang$core$Dict$RBNode_elm_builtin, _elm_lang$core$Dict$Black, _p27._1, _p27._2, _p27._3, _p27._4._3._3),
				A5(
					_elm_lang$core$Dict$balance,
					_elm_lang$core$Dict$Black,
					_p27._4._1,
					_p27._4._2,
					_p27._4._3._4,
					_elm_lang$core$Dict$redden(_p27._4._4)));
		} while(false);
		return A5(
			_elm_lang$core$Dict$RBNode_elm_builtin,
			_elm_lang$core$Dict$Black,
			_p27._3._4._1,
			_p27._3._4._2,
			A5(
				_elm_lang$core$Dict$balance,
				_elm_lang$core$Dict$Black,
				_p27._3._1,
				_p27._3._2,
				_elm_lang$core$Dict$redden(_p27._3._3),
				_p27._3._4._3),
			A5(_elm_lang$core$Dict$RBNode_elm_builtin, _elm_lang$core$Dict$Black, _p27._1, _p27._2, _p27._3._4._4, _p27._4));
	} while(false);
	return tree;
};
var _elm_lang$core$Dict$balance = F5(
	function (c, k, v, l, r) {
		var tree = A5(_elm_lang$core$Dict$RBNode_elm_builtin, c, k, v, l, r);
		return _elm_lang$core$Dict$blackish(tree) ? _elm_lang$core$Dict$balanceHelp(tree) : tree;
	});
var _elm_lang$core$Dict$bubble = F5(
	function (c, k, v, l, r) {
		return (_elm_lang$core$Dict$isBBlack(l) || _elm_lang$core$Dict$isBBlack(r)) ? A5(
			_elm_lang$core$Dict$balance,
			_elm_lang$core$Dict$moreBlack(c),
			k,
			v,
			_elm_lang$core$Dict$lessBlackTree(l),
			_elm_lang$core$Dict$lessBlackTree(r)) : A5(_elm_lang$core$Dict$RBNode_elm_builtin, c, k, v, l, r);
	});
var _elm_lang$core$Dict$removeMax = F5(
	function (c, k, v, l, r) {
		var _p28 = r;
		if (_p28.ctor === 'RBEmpty_elm_builtin') {
			return A3(_elm_lang$core$Dict$rem, c, l, r);
		} else {
			return A5(
				_elm_lang$core$Dict$bubble,
				c,
				k,
				v,
				l,
				A5(_elm_lang$core$Dict$removeMax, _p28._0, _p28._1, _p28._2, _p28._3, _p28._4));
		}
	});
var _elm_lang$core$Dict$rem = F3(
	function (color, left, right) {
		var _p29 = {ctor: '_Tuple2', _0: left, _1: right};
		if (_p29._0.ctor === 'RBEmpty_elm_builtin') {
			if (_p29._1.ctor === 'RBEmpty_elm_builtin') {
				var _p30 = color;
				switch (_p30.ctor) {
					case 'Red':
						return _elm_lang$core$Dict$RBEmpty_elm_builtin(_elm_lang$core$Dict$LBlack);
					case 'Black':
						return _elm_lang$core$Dict$RBEmpty_elm_builtin(_elm_lang$core$Dict$LBBlack);
					default:
						return _elm_lang$core$Native_Debug.crash('cannot have bblack or nblack nodes at this point');
				}
			} else {
				var _p33 = _p29._1._0;
				var _p32 = _p29._0._0;
				var _p31 = {ctor: '_Tuple3', _0: color, _1: _p32, _2: _p33};
				if ((((_p31.ctor === '_Tuple3') && (_p31._0.ctor === 'Black')) && (_p31._1.ctor === 'LBlack')) && (_p31._2.ctor === 'Red')) {
					return A5(_elm_lang$core$Dict$RBNode_elm_builtin, _elm_lang$core$Dict$Black, _p29._1._1, _p29._1._2, _p29._1._3, _p29._1._4);
				} else {
					return A4(
						_elm_lang$core$Dict$reportRemBug,
						'Black/LBlack/Red',
						color,
						_elm_lang$core$Basics$toString(_p32),
						_elm_lang$core$Basics$toString(_p33));
				}
			}
		} else {
			if (_p29._1.ctor === 'RBEmpty_elm_builtin') {
				var _p36 = _p29._1._0;
				var _p35 = _p29._0._0;
				var _p34 = {ctor: '_Tuple3', _0: color, _1: _p35, _2: _p36};
				if ((((_p34.ctor === '_Tuple3') && (_p34._0.ctor === 'Black')) && (_p34._1.ctor === 'Red')) && (_p34._2.ctor === 'LBlack')) {
					return A5(_elm_lang$core$Dict$RBNode_elm_builtin, _elm_lang$core$Dict$Black, _p29._0._1, _p29._0._2, _p29._0._3, _p29._0._4);
				} else {
					return A4(
						_elm_lang$core$Dict$reportRemBug,
						'Black/Red/LBlack',
						color,
						_elm_lang$core$Basics$toString(_p35),
						_elm_lang$core$Basics$toString(_p36));
				}
			} else {
				var _p40 = _p29._0._2;
				var _p39 = _p29._0._4;
				var _p38 = _p29._0._1;
				var newLeft = A5(_elm_lang$core$Dict$removeMax, _p29._0._0, _p38, _p40, _p29._0._3, _p39);
				var _p37 = A3(_elm_lang$core$Dict$maxWithDefault, _p38, _p40, _p39);
				var k = _p37._0;
				var v = _p37._1;
				return A5(_elm_lang$core$Dict$bubble, color, k, v, newLeft, right);
			}
		}
	});
var _elm_lang$core$Dict$map = F2(
	function (f, dict) {
		var _p41 = dict;
		if (_p41.ctor === 'RBEmpty_elm_builtin') {
			return _elm_lang$core$Dict$RBEmpty_elm_builtin(_elm_lang$core$Dict$LBlack);
		} else {
			var _p42 = _p41._1;
			return A5(
				_elm_lang$core$Dict$RBNode_elm_builtin,
				_p41._0,
				_p42,
				A2(f, _p42, _p41._2),
				A2(_elm_lang$core$Dict$map, f, _p41._3),
				A2(_elm_lang$core$Dict$map, f, _p41._4));
		}
	});
var _elm_lang$core$Dict$Same = {ctor: 'Same'};
var _elm_lang$core$Dict$Remove = {ctor: 'Remove'};
var _elm_lang$core$Dict$Insert = {ctor: 'Insert'};
var _elm_lang$core$Dict$update = F3(
	function (k, alter, dict) {
		var up = function (dict) {
			var _p43 = dict;
			if (_p43.ctor === 'RBEmpty_elm_builtin') {
				var _p44 = alter(_elm_lang$core$Maybe$Nothing);
				if (_p44.ctor === 'Nothing') {
					return {ctor: '_Tuple2', _0: _elm_lang$core$Dict$Same, _1: _elm_lang$core$Dict$empty};
				} else {
					return {
						ctor: '_Tuple2',
						_0: _elm_lang$core$Dict$Insert,
						_1: A5(_elm_lang$core$Dict$RBNode_elm_builtin, _elm_lang$core$Dict$Red, k, _p44._0, _elm_lang$core$Dict$empty, _elm_lang$core$Dict$empty)
					};
				}
			} else {
				var _p55 = _p43._2;
				var _p54 = _p43._4;
				var _p53 = _p43._3;
				var _p52 = _p43._1;
				var _p51 = _p43._0;
				var _p45 = A2(_elm_lang$core$Basics$compare, k, _p52);
				switch (_p45.ctor) {
					case 'EQ':
						var _p46 = alter(
							_elm_lang$core$Maybe$Just(_p55));
						if (_p46.ctor === 'Nothing') {
							return {
								ctor: '_Tuple2',
								_0: _elm_lang$core$Dict$Remove,
								_1: A3(_elm_lang$core$Dict$rem, _p51, _p53, _p54)
							};
						} else {
							return {
								ctor: '_Tuple2',
								_0: _elm_lang$core$Dict$Same,
								_1: A5(_elm_lang$core$Dict$RBNode_elm_builtin, _p51, _p52, _p46._0, _p53, _p54)
							};
						}
					case 'LT':
						var _p47 = up(_p53);
						var flag = _p47._0;
						var newLeft = _p47._1;
						var _p48 = flag;
						switch (_p48.ctor) {
							case 'Same':
								return {
									ctor: '_Tuple2',
									_0: _elm_lang$core$Dict$Same,
									_1: A5(_elm_lang$core$Dict$RBNode_elm_builtin, _p51, _p52, _p55, newLeft, _p54)
								};
							case 'Insert':
								return {
									ctor: '_Tuple2',
									_0: _elm_lang$core$Dict$Insert,
									_1: A5(_elm_lang$core$Dict$balance, _p51, _p52, _p55, newLeft, _p54)
								};
							default:
								return {
									ctor: '_Tuple2',
									_0: _elm_lang$core$Dict$Remove,
									_1: A5(_elm_lang$core$Dict$bubble, _p51, _p52, _p55, newLeft, _p54)
								};
						}
					default:
						var _p49 = up(_p54);
						var flag = _p49._0;
						var newRight = _p49._1;
						var _p50 = flag;
						switch (_p50.ctor) {
							case 'Same':
								return {
									ctor: '_Tuple2',
									_0: _elm_lang$core$Dict$Same,
									_1: A5(_elm_lang$core$Dict$RBNode_elm_builtin, _p51, _p52, _p55, _p53, newRight)
								};
							case 'Insert':
								return {
									ctor: '_Tuple2',
									_0: _elm_lang$core$Dict$Insert,
									_1: A5(_elm_lang$core$Dict$balance, _p51, _p52, _p55, _p53, newRight)
								};
							default:
								return {
									ctor: '_Tuple2',
									_0: _elm_lang$core$Dict$Remove,
									_1: A5(_elm_lang$core$Dict$bubble, _p51, _p52, _p55, _p53, newRight)
								};
						}
				}
			}
		};
		var _p56 = up(dict);
		var flag = _p56._0;
		var updatedDict = _p56._1;
		var _p57 = flag;
		switch (_p57.ctor) {
			case 'Same':
				return updatedDict;
			case 'Insert':
				return _elm_lang$core$Dict$ensureBlackRoot(updatedDict);
			default:
				return _elm_lang$core$Dict$blacken(updatedDict);
		}
	});
var _elm_lang$core$Dict$insert = F3(
	function (key, value, dict) {
		return A3(
			_elm_lang$core$Dict$update,
			key,
			_elm_lang$core$Basics$always(
				_elm_lang$core$Maybe$Just(value)),
			dict);
	});
var _elm_lang$core$Dict$singleton = F2(
	function (key, value) {
		return A3(_elm_lang$core$Dict$insert, key, value, _elm_lang$core$Dict$empty);
	});
var _elm_lang$core$Dict$union = F2(
	function (t1, t2) {
		return A3(_elm_lang$core$Dict$foldl, _elm_lang$core$Dict$insert, t2, t1);
	});
var _elm_lang$core$Dict$filter = F2(
	function (predicate, dictionary) {
		var add = F3(
			function (key, value, dict) {
				return A2(predicate, key, value) ? A3(_elm_lang$core$Dict$insert, key, value, dict) : dict;
			});
		return A3(_elm_lang$core$Dict$foldl, add, _elm_lang$core$Dict$empty, dictionary);
	});
var _elm_lang$core$Dict$intersect = F2(
	function (t1, t2) {
		return A2(
			_elm_lang$core$Dict$filter,
			F2(
				function (k, _p58) {
					return A2(_elm_lang$core$Dict$member, k, t2);
				}),
			t1);
	});
var _elm_lang$core$Dict$partition = F2(
	function (predicate, dict) {
		var add = F3(
			function (key, value, _p59) {
				var _p60 = _p59;
				var _p62 = _p60._1;
				var _p61 = _p60._0;
				return A2(predicate, key, value) ? {
					ctor: '_Tuple2',
					_0: A3(_elm_lang$core$Dict$insert, key, value, _p61),
					_1: _p62
				} : {
					ctor: '_Tuple2',
					_0: _p61,
					_1: A3(_elm_lang$core$Dict$insert, key, value, _p62)
				};
			});
		return A3(
			_elm_lang$core$Dict$foldl,
			add,
			{ctor: '_Tuple2', _0: _elm_lang$core$Dict$empty, _1: _elm_lang$core$Dict$empty},
			dict);
	});
var _elm_lang$core$Dict$fromList = function (assocs) {
	return A3(
		_elm_lang$core$List$foldl,
		F2(
			function (_p63, dict) {
				var _p64 = _p63;
				return A3(_elm_lang$core$Dict$insert, _p64._0, _p64._1, dict);
			}),
		_elm_lang$core$Dict$empty,
		assocs);
};
var _elm_lang$core$Dict$remove = F2(
	function (key, dict) {
		return A3(
			_elm_lang$core$Dict$update,
			key,
			_elm_lang$core$Basics$always(_elm_lang$core$Maybe$Nothing),
			dict);
	});
var _elm_lang$core$Dict$diff = F2(
	function (t1, t2) {
		return A3(
			_elm_lang$core$Dict$foldl,
			F3(
				function (k, v, t) {
					return A2(_elm_lang$core$Dict$remove, k, t);
				}),
			t1,
			t2);
	});

//import Native.Scheduler //

var _elm_lang$core$Native_Time = function() {

var now = _elm_lang$core$Native_Scheduler.nativeBinding(function(callback)
{
	callback(_elm_lang$core$Native_Scheduler.succeed(Date.now()));
});

function setInterval_(interval, task)
{
	return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback)
	{
		var id = setInterval(function() {
			_elm_lang$core$Native_Scheduler.rawSpawn(task);
		}, interval);

		return function() { clearInterval(id); };
	});
}

return {
	now: now,
	setInterval_: F2(setInterval_)
};

}();
var _elm_lang$core$Time$setInterval = _elm_lang$core$Native_Time.setInterval_;
var _elm_lang$core$Time$spawnHelp = F3(
	function (router, intervals, processes) {
		var _p0 = intervals;
		if (_p0.ctor === '[]') {
			return _elm_lang$core$Task$succeed(processes);
		} else {
			var _p1 = _p0._0;
			var spawnRest = function (id) {
				return A3(
					_elm_lang$core$Time$spawnHelp,
					router,
					_p0._1,
					A3(_elm_lang$core$Dict$insert, _p1, id, processes));
			};
			var spawnTimer = _elm_lang$core$Native_Scheduler.spawn(
				A2(
					_elm_lang$core$Time$setInterval,
					_p1,
					A2(_elm_lang$core$Platform$sendToSelf, router, _p1)));
			return A2(_elm_lang$core$Task$andThen, spawnRest, spawnTimer);
		}
	});
var _elm_lang$core$Time$addMySub = F2(
	function (_p2, state) {
		var _p3 = _p2;
		var _p6 = _p3._1;
		var _p5 = _p3._0;
		var _p4 = A2(_elm_lang$core$Dict$get, _p5, state);
		if (_p4.ctor === 'Nothing') {
			return A3(
				_elm_lang$core$Dict$insert,
				_p5,
				{
					ctor: '::',
					_0: _p6,
					_1: {ctor: '[]'}
				},
				state);
		} else {
			return A3(
				_elm_lang$core$Dict$insert,
				_p5,
				{ctor: '::', _0: _p6, _1: _p4._0},
				state);
		}
	});
var _elm_lang$core$Time$inMilliseconds = function (t) {
	return t;
};
var _elm_lang$core$Time$millisecond = 1;
var _elm_lang$core$Time$second = 1000 * _elm_lang$core$Time$millisecond;
var _elm_lang$core$Time$minute = 60 * _elm_lang$core$Time$second;
var _elm_lang$core$Time$hour = 60 * _elm_lang$core$Time$minute;
var _elm_lang$core$Time$inHours = function (t) {
	return t / _elm_lang$core$Time$hour;
};
var _elm_lang$core$Time$inMinutes = function (t) {
	return t / _elm_lang$core$Time$minute;
};
var _elm_lang$core$Time$inSeconds = function (t) {
	return t / _elm_lang$core$Time$second;
};
var _elm_lang$core$Time$now = _elm_lang$core$Native_Time.now;
var _elm_lang$core$Time$onSelfMsg = F3(
	function (router, interval, state) {
		var _p7 = A2(_elm_lang$core$Dict$get, interval, state.taggers);
		if (_p7.ctor === 'Nothing') {
			return _elm_lang$core$Task$succeed(state);
		} else {
			var tellTaggers = function (time) {
				return _elm_lang$core$Task$sequence(
					A2(
						_elm_lang$core$List$map,
						function (tagger) {
							return A2(
								_elm_lang$core$Platform$sendToApp,
								router,
								tagger(time));
						},
						_p7._0));
			};
			return A2(
				_elm_lang$core$Task$andThen,
				function (_p8) {
					return _elm_lang$core$Task$succeed(state);
				},
				A2(_elm_lang$core$Task$andThen, tellTaggers, _elm_lang$core$Time$now));
		}
	});
var _elm_lang$core$Time$subscription = _elm_lang$core$Native_Platform.leaf('Time');
var _elm_lang$core$Time$State = F2(
	function (a, b) {
		return {taggers: a, processes: b};
	});
var _elm_lang$core$Time$init = _elm_lang$core$Task$succeed(
	A2(_elm_lang$core$Time$State, _elm_lang$core$Dict$empty, _elm_lang$core$Dict$empty));
var _elm_lang$core$Time$onEffects = F3(
	function (router, subs, _p9) {
		var _p10 = _p9;
		var rightStep = F3(
			function (_p12, id, _p11) {
				var _p13 = _p11;
				return {
					ctor: '_Tuple3',
					_0: _p13._0,
					_1: _p13._1,
					_2: A2(
						_elm_lang$core$Task$andThen,
						function (_p14) {
							return _p13._2;
						},
						_elm_lang$core$Native_Scheduler.kill(id))
				};
			});
		var bothStep = F4(
			function (interval, taggers, id, _p15) {
				var _p16 = _p15;
				return {
					ctor: '_Tuple3',
					_0: _p16._0,
					_1: A3(_elm_lang$core$Dict$insert, interval, id, _p16._1),
					_2: _p16._2
				};
			});
		var leftStep = F3(
			function (interval, taggers, _p17) {
				var _p18 = _p17;
				return {
					ctor: '_Tuple3',
					_0: {ctor: '::', _0: interval, _1: _p18._0},
					_1: _p18._1,
					_2: _p18._2
				};
			});
		var newTaggers = A3(_elm_lang$core$List$foldl, _elm_lang$core$Time$addMySub, _elm_lang$core$Dict$empty, subs);
		var _p19 = A6(
			_elm_lang$core$Dict$merge,
			leftStep,
			bothStep,
			rightStep,
			newTaggers,
			_p10.processes,
			{
				ctor: '_Tuple3',
				_0: {ctor: '[]'},
				_1: _elm_lang$core$Dict$empty,
				_2: _elm_lang$core$Task$succeed(
					{ctor: '_Tuple0'})
			});
		var spawnList = _p19._0;
		var existingDict = _p19._1;
		var killTask = _p19._2;
		return A2(
			_elm_lang$core$Task$andThen,
			function (newProcesses) {
				return _elm_lang$core$Task$succeed(
					A2(_elm_lang$core$Time$State, newTaggers, newProcesses));
			},
			A2(
				_elm_lang$core$Task$andThen,
				function (_p20) {
					return A3(_elm_lang$core$Time$spawnHelp, router, spawnList, existingDict);
				},
				killTask));
	});
var _elm_lang$core$Time$Every = F2(
	function (a, b) {
		return {ctor: 'Every', _0: a, _1: b};
	});
var _elm_lang$core$Time$every = F2(
	function (interval, tagger) {
		return _elm_lang$core$Time$subscription(
			A2(_elm_lang$core$Time$Every, interval, tagger));
	});
var _elm_lang$core$Time$subMap = F2(
	function (f, _p21) {
		var _p22 = _p21;
		return A2(
			_elm_lang$core$Time$Every,
			_p22._0,
			function (_p23) {
				return f(
					_p22._1(_p23));
			});
	});
_elm_lang$core$Native_Platform.effectManagers['Time'] = {pkg: 'elm-lang/core', init: _elm_lang$core$Time$init, onEffects: _elm_lang$core$Time$onEffects, onSelfMsg: _elm_lang$core$Time$onSelfMsg, tag: 'sub', subMap: _elm_lang$core$Time$subMap};

var _elm_lang$core$Debug$crash = _elm_lang$core$Native_Debug.crash;
var _elm_lang$core$Debug$log = _elm_lang$core$Native_Debug.log;

//import Maybe, Native.Array, Native.List, Native.Utils, Result //

var _elm_lang$core$Native_Json = function() {


// CORE DECODERS

function succeed(msg)
{
	return {
		ctor: '<decoder>',
		tag: 'succeed',
		msg: msg
	};
}

function fail(msg)
{
	return {
		ctor: '<decoder>',
		tag: 'fail',
		msg: msg
	};
}

function decodePrimitive(tag)
{
	return {
		ctor: '<decoder>',
		tag: tag
	};
}

function decodeContainer(tag, decoder)
{
	return {
		ctor: '<decoder>',
		tag: tag,
		decoder: decoder
	};
}

function decodeNull(value)
{
	return {
		ctor: '<decoder>',
		tag: 'null',
		value: value
	};
}

function decodeField(field, decoder)
{
	return {
		ctor: '<decoder>',
		tag: 'field',
		field: field,
		decoder: decoder
	};
}

function decodeIndex(index, decoder)
{
	return {
		ctor: '<decoder>',
		tag: 'index',
		index: index,
		decoder: decoder
	};
}

function decodeKeyValuePairs(decoder)
{
	return {
		ctor: '<decoder>',
		tag: 'key-value',
		decoder: decoder
	};
}

function mapMany(f, decoders)
{
	return {
		ctor: '<decoder>',
		tag: 'map-many',
		func: f,
		decoders: decoders
	};
}

function andThen(callback, decoder)
{
	return {
		ctor: '<decoder>',
		tag: 'andThen',
		decoder: decoder,
		callback: callback
	};
}

function oneOf(decoders)
{
	return {
		ctor: '<decoder>',
		tag: 'oneOf',
		decoders: decoders
	};
}


// DECODING OBJECTS

function map1(f, d1)
{
	return mapMany(f, [d1]);
}

function map2(f, d1, d2)
{
	return mapMany(f, [d1, d2]);
}

function map3(f, d1, d2, d3)
{
	return mapMany(f, [d1, d2, d3]);
}

function map4(f, d1, d2, d3, d4)
{
	return mapMany(f, [d1, d2, d3, d4]);
}

function map5(f, d1, d2, d3, d4, d5)
{
	return mapMany(f, [d1, d2, d3, d4, d5]);
}

function map6(f, d1, d2, d3, d4, d5, d6)
{
	return mapMany(f, [d1, d2, d3, d4, d5, d6]);
}

function map7(f, d1, d2, d3, d4, d5, d6, d7)
{
	return mapMany(f, [d1, d2, d3, d4, d5, d6, d7]);
}

function map8(f, d1, d2, d3, d4, d5, d6, d7, d8)
{
	return mapMany(f, [d1, d2, d3, d4, d5, d6, d7, d8]);
}


// DECODE HELPERS

function ok(value)
{
	return { tag: 'ok', value: value };
}

function badPrimitive(type, value)
{
	return { tag: 'primitive', type: type, value: value };
}

function badIndex(index, nestedProblems)
{
	return { tag: 'index', index: index, rest: nestedProblems };
}

function badField(field, nestedProblems)
{
	return { tag: 'field', field: field, rest: nestedProblems };
}

function badIndex(index, nestedProblems)
{
	return { tag: 'index', index: index, rest: nestedProblems };
}

function badOneOf(problems)
{
	return { tag: 'oneOf', problems: problems };
}

function bad(msg)
{
	return { tag: 'fail', msg: msg };
}

function badToString(problem)
{
	var context = '_';
	while (problem)
	{
		switch (problem.tag)
		{
			case 'primitive':
				return 'Expecting ' + problem.type
					+ (context === '_' ? '' : ' at ' + context)
					+ ' but instead got: ' + jsToString(problem.value);

			case 'index':
				context += '[' + problem.index + ']';
				problem = problem.rest;
				break;

			case 'field':
				context += '.' + problem.field;
				problem = problem.rest;
				break;

			case 'oneOf':
				var problems = problem.problems;
				for (var i = 0; i < problems.length; i++)
				{
					problems[i] = badToString(problems[i]);
				}
				return 'I ran into the following problems'
					+ (context === '_' ? '' : ' at ' + context)
					+ ':\n\n' + problems.join('\n');

			case 'fail':
				return 'I ran into a `fail` decoder'
					+ (context === '_' ? '' : ' at ' + context)
					+ ': ' + problem.msg;
		}
	}
}

function jsToString(value)
{
	return value === undefined
		? 'undefined'
		: JSON.stringify(value);
}


// DECODE

function runOnString(decoder, string)
{
	var json;
	try
	{
		json = JSON.parse(string);
	}
	catch (e)
	{
		return _elm_lang$core$Result$Err('Given an invalid JSON: ' + e.message);
	}
	return run(decoder, json);
}

function run(decoder, value)
{
	var result = runHelp(decoder, value);
	return (result.tag === 'ok')
		? _elm_lang$core$Result$Ok(result.value)
		: _elm_lang$core$Result$Err(badToString(result));
}

function runHelp(decoder, value)
{
	switch (decoder.tag)
	{
		case 'bool':
			return (typeof value === 'boolean')
				? ok(value)
				: badPrimitive('a Bool', value);

		case 'int':
			if (typeof value !== 'number') {
				return badPrimitive('an Int', value);
			}

			if (-2147483647 < value && value < 2147483647 && (value | 0) === value) {
				return ok(value);
			}

			if (isFinite(value) && !(value % 1)) {
				return ok(value);
			}

			return badPrimitive('an Int', value);

		case 'float':
			return (typeof value === 'number')
				? ok(value)
				: badPrimitive('a Float', value);

		case 'string':
			return (typeof value === 'string')
				? ok(value)
				: (value instanceof String)
					? ok(value + '')
					: badPrimitive('a String', value);

		case 'null':
			return (value === null)
				? ok(decoder.value)
				: badPrimitive('null', value);

		case 'value':
			return ok(value);

		case 'list':
			if (!(value instanceof Array))
			{
				return badPrimitive('a List', value);
			}

			var list = _elm_lang$core$Native_List.Nil;
			for (var i = value.length; i--; )
			{
				var result = runHelp(decoder.decoder, value[i]);
				if (result.tag !== 'ok')
				{
					return badIndex(i, result)
				}
				list = _elm_lang$core$Native_List.Cons(result.value, list);
			}
			return ok(list);

		case 'array':
			if (!(value instanceof Array))
			{
				return badPrimitive('an Array', value);
			}

			var len = value.length;
			var array = new Array(len);
			for (var i = len; i--; )
			{
				var result = runHelp(decoder.decoder, value[i]);
				if (result.tag !== 'ok')
				{
					return badIndex(i, result);
				}
				array[i] = result.value;
			}
			return ok(_elm_lang$core$Native_Array.fromJSArray(array));

		case 'maybe':
			var result = runHelp(decoder.decoder, value);
			return (result.tag === 'ok')
				? ok(_elm_lang$core$Maybe$Just(result.value))
				: ok(_elm_lang$core$Maybe$Nothing);

		case 'field':
			var field = decoder.field;
			if (typeof value !== 'object' || value === null || !(field in value))
			{
				return badPrimitive('an object with a field named `' + field + '`', value);
			}

			var result = runHelp(decoder.decoder, value[field]);
			return (result.tag === 'ok') ? result : badField(field, result);

		case 'index':
			var index = decoder.index;
			if (!(value instanceof Array))
			{
				return badPrimitive('an array', value);
			}
			if (index >= value.length)
			{
				return badPrimitive('a longer array. Need index ' + index + ' but there are only ' + value.length + ' entries', value);
			}

			var result = runHelp(decoder.decoder, value[index]);
			return (result.tag === 'ok') ? result : badIndex(index, result);

		case 'key-value':
			if (typeof value !== 'object' || value === null || value instanceof Array)
			{
				return badPrimitive('an object', value);
			}

			var keyValuePairs = _elm_lang$core$Native_List.Nil;
			for (var key in value)
			{
				var result = runHelp(decoder.decoder, value[key]);
				if (result.tag !== 'ok')
				{
					return badField(key, result);
				}
				var pair = _elm_lang$core$Native_Utils.Tuple2(key, result.value);
				keyValuePairs = _elm_lang$core$Native_List.Cons(pair, keyValuePairs);
			}
			return ok(keyValuePairs);

		case 'map-many':
			var answer = decoder.func;
			var decoders = decoder.decoders;
			for (var i = 0; i < decoders.length; i++)
			{
				var result = runHelp(decoders[i], value);
				if (result.tag !== 'ok')
				{
					return result;
				}
				answer = answer(result.value);
			}
			return ok(answer);

		case 'andThen':
			var result = runHelp(decoder.decoder, value);
			return (result.tag !== 'ok')
				? result
				: runHelp(decoder.callback(result.value), value);

		case 'oneOf':
			var errors = [];
			var temp = decoder.decoders;
			while (temp.ctor !== '[]')
			{
				var result = runHelp(temp._0, value);

				if (result.tag === 'ok')
				{
					return result;
				}

				errors.push(result);

				temp = temp._1;
			}
			return badOneOf(errors);

		case 'fail':
			return bad(decoder.msg);

		case 'succeed':
			return ok(decoder.msg);
	}
}


// EQUALITY

function equality(a, b)
{
	if (a === b)
	{
		return true;
	}

	if (a.tag !== b.tag)
	{
		return false;
	}

	switch (a.tag)
	{
		case 'succeed':
		case 'fail':
			return a.msg === b.msg;

		case 'bool':
		case 'int':
		case 'float':
		case 'string':
		case 'value':
			return true;

		case 'null':
			return a.value === b.value;

		case 'list':
		case 'array':
		case 'maybe':
		case 'key-value':
			return equality(a.decoder, b.decoder);

		case 'field':
			return a.field === b.field && equality(a.decoder, b.decoder);

		case 'index':
			return a.index === b.index && equality(a.decoder, b.decoder);

		case 'map-many':
			if (a.func !== b.func)
			{
				return false;
			}
			return listEquality(a.decoders, b.decoders);

		case 'andThen':
			return a.callback === b.callback && equality(a.decoder, b.decoder);

		case 'oneOf':
			return listEquality(a.decoders, b.decoders);
	}
}

function listEquality(aDecoders, bDecoders)
{
	var len = aDecoders.length;
	if (len !== bDecoders.length)
	{
		return false;
	}
	for (var i = 0; i < len; i++)
	{
		if (!equality(aDecoders[i], bDecoders[i]))
		{
			return false;
		}
	}
	return true;
}


// ENCODE

function encode(indentLevel, value)
{
	return JSON.stringify(value, null, indentLevel);
}

function identity(value)
{
	return value;
}

function encodeObject(keyValuePairs)
{
	var obj = {};
	while (keyValuePairs.ctor !== '[]')
	{
		var pair = keyValuePairs._0;
		obj[pair._0] = pair._1;
		keyValuePairs = keyValuePairs._1;
	}
	return obj;
}

return {
	encode: F2(encode),
	runOnString: F2(runOnString),
	run: F2(run),

	decodeNull: decodeNull,
	decodePrimitive: decodePrimitive,
	decodeContainer: F2(decodeContainer),

	decodeField: F2(decodeField),
	decodeIndex: F2(decodeIndex),

	map1: F2(map1),
	map2: F3(map2),
	map3: F4(map3),
	map4: F5(map4),
	map5: F6(map5),
	map6: F7(map6),
	map7: F8(map7),
	map8: F9(map8),
	decodeKeyValuePairs: decodeKeyValuePairs,

	andThen: F2(andThen),
	fail: fail,
	succeed: succeed,
	oneOf: oneOf,

	identity: identity,
	encodeNull: null,
	encodeArray: _elm_lang$core$Native_Array.toJSArray,
	encodeList: _elm_lang$core$Native_List.toArray,
	encodeObject: encodeObject,

	equality: equality
};

}();

var _elm_lang$core$Json_Encode$list = _elm_lang$core$Native_Json.encodeList;
var _elm_lang$core$Json_Encode$array = _elm_lang$core$Native_Json.encodeArray;
var _elm_lang$core$Json_Encode$object = _elm_lang$core$Native_Json.encodeObject;
var _elm_lang$core$Json_Encode$null = _elm_lang$core$Native_Json.encodeNull;
var _elm_lang$core$Json_Encode$bool = _elm_lang$core$Native_Json.identity;
var _elm_lang$core$Json_Encode$float = _elm_lang$core$Native_Json.identity;
var _elm_lang$core$Json_Encode$int = _elm_lang$core$Native_Json.identity;
var _elm_lang$core$Json_Encode$string = _elm_lang$core$Native_Json.identity;
var _elm_lang$core$Json_Encode$encode = _elm_lang$core$Native_Json.encode;
var _elm_lang$core$Json_Encode$Value = {ctor: 'Value'};

var _elm_lang$core$Json_Decode$null = _elm_lang$core$Native_Json.decodeNull;
var _elm_lang$core$Json_Decode$value = _elm_lang$core$Native_Json.decodePrimitive('value');
var _elm_lang$core$Json_Decode$andThen = _elm_lang$core$Native_Json.andThen;
var _elm_lang$core$Json_Decode$fail = _elm_lang$core$Native_Json.fail;
var _elm_lang$core$Json_Decode$succeed = _elm_lang$core$Native_Json.succeed;
var _elm_lang$core$Json_Decode$lazy = function (thunk) {
	return A2(
		_elm_lang$core$Json_Decode$andThen,
		thunk,
		_elm_lang$core$Json_Decode$succeed(
			{ctor: '_Tuple0'}));
};
var _elm_lang$core$Json_Decode$decodeValue = _elm_lang$core$Native_Json.run;
var _elm_lang$core$Json_Decode$decodeString = _elm_lang$core$Native_Json.runOnString;
var _elm_lang$core$Json_Decode$map8 = _elm_lang$core$Native_Json.map8;
var _elm_lang$core$Json_Decode$map7 = _elm_lang$core$Native_Json.map7;
var _elm_lang$core$Json_Decode$map6 = _elm_lang$core$Native_Json.map6;
var _elm_lang$core$Json_Decode$map5 = _elm_lang$core$Native_Json.map5;
var _elm_lang$core$Json_Decode$map4 = _elm_lang$core$Native_Json.map4;
var _elm_lang$core$Json_Decode$map3 = _elm_lang$core$Native_Json.map3;
var _elm_lang$core$Json_Decode$map2 = _elm_lang$core$Native_Json.map2;
var _elm_lang$core$Json_Decode$map = _elm_lang$core$Native_Json.map1;
var _elm_lang$core$Json_Decode$oneOf = _elm_lang$core$Native_Json.oneOf;
var _elm_lang$core$Json_Decode$maybe = function (decoder) {
	return A2(_elm_lang$core$Native_Json.decodeContainer, 'maybe', decoder);
};
var _elm_lang$core$Json_Decode$index = _elm_lang$core$Native_Json.decodeIndex;
var _elm_lang$core$Json_Decode$field = _elm_lang$core$Native_Json.decodeField;
var _elm_lang$core$Json_Decode$at = F2(
	function (fields, decoder) {
		return A3(_elm_lang$core$List$foldr, _elm_lang$core$Json_Decode$field, decoder, fields);
	});
var _elm_lang$core$Json_Decode$keyValuePairs = _elm_lang$core$Native_Json.decodeKeyValuePairs;
var _elm_lang$core$Json_Decode$dict = function (decoder) {
	return A2(
		_elm_lang$core$Json_Decode$map,
		_elm_lang$core$Dict$fromList,
		_elm_lang$core$Json_Decode$keyValuePairs(decoder));
};
var _elm_lang$core$Json_Decode$array = function (decoder) {
	return A2(_elm_lang$core$Native_Json.decodeContainer, 'array', decoder);
};
var _elm_lang$core$Json_Decode$list = function (decoder) {
	return A2(_elm_lang$core$Native_Json.decodeContainer, 'list', decoder);
};
var _elm_lang$core$Json_Decode$nullable = function (decoder) {
	return _elm_lang$core$Json_Decode$oneOf(
		{
			ctor: '::',
			_0: _elm_lang$core$Json_Decode$null(_elm_lang$core$Maybe$Nothing),
			_1: {
				ctor: '::',
				_0: A2(_elm_lang$core$Json_Decode$map, _elm_lang$core$Maybe$Just, decoder),
				_1: {ctor: '[]'}
			}
		});
};
var _elm_lang$core$Json_Decode$float = _elm_lang$core$Native_Json.decodePrimitive('float');
var _elm_lang$core$Json_Decode$int = _elm_lang$core$Native_Json.decodePrimitive('int');
var _elm_lang$core$Json_Decode$bool = _elm_lang$core$Native_Json.decodePrimitive('bool');
var _elm_lang$core$Json_Decode$string = _elm_lang$core$Native_Json.decodePrimitive('string');
var _elm_lang$core$Json_Decode$Decoder = {ctor: 'Decoder'};

var _elm_lang$core$Process$kill = _elm_lang$core$Native_Scheduler.kill;
var _elm_lang$core$Process$sleep = _elm_lang$core$Native_Scheduler.sleep;
var _elm_lang$core$Process$spawn = _elm_lang$core$Native_Scheduler.spawn;

var _elm_lang$core$Tuple$mapSecond = F2(
	function (func, _p0) {
		var _p1 = _p0;
		return {
			ctor: '_Tuple2',
			_0: _p1._0,
			_1: func(_p1._1)
		};
	});
var _elm_lang$core$Tuple$mapFirst = F2(
	function (func, _p2) {
		var _p3 = _p2;
		return {
			ctor: '_Tuple2',
			_0: func(_p3._0),
			_1: _p3._1
		};
	});
var _elm_lang$core$Tuple$second = function (_p4) {
	var _p5 = _p4;
	return _p5._1;
};
var _elm_lang$core$Tuple$first = function (_p6) {
	var _p7 = _p6;
	return _p7._0;
};

var _elm_lang$dom$Native_Dom = function() {

var fakeNode = {
	addEventListener: function() {},
	removeEventListener: function() {}
};

var onDocument = on(typeof document !== 'undefined' ? document : fakeNode);
var onWindow = on(typeof window !== 'undefined' ? window : fakeNode);

function on(node)
{
	return function(eventName, decoder, toTask)
	{
		return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {

			function performTask(event)
			{
				var result = A2(_elm_lang$core$Json_Decode$decodeValue, decoder, event);
				if (result.ctor === 'Ok')
				{
					_elm_lang$core$Native_Scheduler.rawSpawn(toTask(result._0));
				}
			}

			node.addEventListener(eventName, performTask);

			return function()
			{
				node.removeEventListener(eventName, performTask);
			};
		});
	};
}

var rAF = typeof requestAnimationFrame !== 'undefined'
	? requestAnimationFrame
	: function(callback) { callback(); };

function withNode(id, doStuff)
{
	return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback)
	{
		rAF(function()
		{
			var node = document.getElementById(id);
			if (node === null)
			{
				callback(_elm_lang$core$Native_Scheduler.fail({ ctor: 'NotFound', _0: id }));
				return;
			}
			callback(_elm_lang$core$Native_Scheduler.succeed(doStuff(node)));
		});
	});
}


// FOCUS

function focus(id)
{
	return withNode(id, function(node) {
		node.focus();
		return _elm_lang$core$Native_Utils.Tuple0;
	});
}

function blur(id)
{
	return withNode(id, function(node) {
		node.blur();
		return _elm_lang$core$Native_Utils.Tuple0;
	});
}


// SCROLLING

function getScrollTop(id)
{
	return withNode(id, function(node) {
		return node.scrollTop;
	});
}

function setScrollTop(id, desiredScrollTop)
{
	return withNode(id, function(node) {
		node.scrollTop = desiredScrollTop;
		return _elm_lang$core$Native_Utils.Tuple0;
	});
}

function toBottom(id)
{
	return withNode(id, function(node) {
		node.scrollTop = node.scrollHeight;
		return _elm_lang$core$Native_Utils.Tuple0;
	});
}

function getScrollLeft(id)
{
	return withNode(id, function(node) {
		return node.scrollLeft;
	});
}

function setScrollLeft(id, desiredScrollLeft)
{
	return withNode(id, function(node) {
		node.scrollLeft = desiredScrollLeft;
		return _elm_lang$core$Native_Utils.Tuple0;
	});
}

function toRight(id)
{
	return withNode(id, function(node) {
		node.scrollLeft = node.scrollWidth;
		return _elm_lang$core$Native_Utils.Tuple0;
	});
}


// SIZE

function width(options, id)
{
	return withNode(id, function(node) {
		switch (options.ctor)
		{
			case 'Content':
				return node.scrollWidth;
			case 'VisibleContent':
				return node.clientWidth;
			case 'VisibleContentWithBorders':
				return node.offsetWidth;
			case 'VisibleContentWithBordersAndMargins':
				var rect = node.getBoundingClientRect();
				return rect.right - rect.left;
		}
	});
}

function height(options, id)
{
	return withNode(id, function(node) {
		switch (options.ctor)
		{
			case 'Content':
				return node.scrollHeight;
			case 'VisibleContent':
				return node.clientHeight;
			case 'VisibleContentWithBorders':
				return node.offsetHeight;
			case 'VisibleContentWithBordersAndMargins':
				var rect = node.getBoundingClientRect();
				return rect.bottom - rect.top;
		}
	});
}

return {
	onDocument: F3(onDocument),
	onWindow: F3(onWindow),

	focus: focus,
	blur: blur,

	getScrollTop: getScrollTop,
	setScrollTop: F2(setScrollTop),
	getScrollLeft: getScrollLeft,
	setScrollLeft: F2(setScrollLeft),
	toBottom: toBottom,
	toRight: toRight,

	height: F2(height),
	width: F2(width)
};

}();

var _elm_lang$dom$Dom$blur = _elm_lang$dom$Native_Dom.blur;
var _elm_lang$dom$Dom$focus = _elm_lang$dom$Native_Dom.focus;
var _elm_lang$dom$Dom$NotFound = function (a) {
	return {ctor: 'NotFound', _0: a};
};

var _elm_lang$dom$Dom_LowLevel$onWindow = _elm_lang$dom$Native_Dom.onWindow;
var _elm_lang$dom$Dom_LowLevel$onDocument = _elm_lang$dom$Native_Dom.onDocument;

var _elm_lang$virtual_dom$VirtualDom_Debug$wrap;
var _elm_lang$virtual_dom$VirtualDom_Debug$wrapWithFlags;

var _elm_lang$virtual_dom$Native_VirtualDom = function() {

var STYLE_KEY = 'STYLE';
var EVENT_KEY = 'EVENT';
var ATTR_KEY = 'ATTR';
var ATTR_NS_KEY = 'ATTR_NS';

var localDoc = typeof document !== 'undefined' ? document : {};


////////////  VIRTUAL DOM NODES  ////////////


function text(string)
{
	return {
		type: 'text',
		text: string
	};
}


function node(tag)
{
	return F2(function(factList, kidList) {
		return nodeHelp(tag, factList, kidList);
	});
}


function nodeHelp(tag, factList, kidList)
{
	var organized = organizeFacts(factList);
	var namespace = organized.namespace;
	var facts = organized.facts;

	var children = [];
	var descendantsCount = 0;
	while (kidList.ctor !== '[]')
	{
		var kid = kidList._0;
		descendantsCount += (kid.descendantsCount || 0);
		children.push(kid);
		kidList = kidList._1;
	}
	descendantsCount += children.length;

	return {
		type: 'node',
		tag: tag,
		facts: facts,
		children: children,
		namespace: namespace,
		descendantsCount: descendantsCount
	};
}


function keyedNode(tag, factList, kidList)
{
	var organized = organizeFacts(factList);
	var namespace = organized.namespace;
	var facts = organized.facts;

	var children = [];
	var descendantsCount = 0;
	while (kidList.ctor !== '[]')
	{
		var kid = kidList._0;
		descendantsCount += (kid._1.descendantsCount || 0);
		children.push(kid);
		kidList = kidList._1;
	}
	descendantsCount += children.length;

	return {
		type: 'keyed-node',
		tag: tag,
		facts: facts,
		children: children,
		namespace: namespace,
		descendantsCount: descendantsCount
	};
}


function custom(factList, model, impl)
{
	var facts = organizeFacts(factList).facts;

	return {
		type: 'custom',
		facts: facts,
		model: model,
		impl: impl
	};
}


function map(tagger, node)
{
	return {
		type: 'tagger',
		tagger: tagger,
		node: node,
		descendantsCount: 1 + (node.descendantsCount || 0)
	};
}


function thunk(func, args, thunk)
{
	return {
		type: 'thunk',
		func: func,
		args: args,
		thunk: thunk,
		node: undefined
	};
}

function lazy(fn, a)
{
	return thunk(fn, [a], function() {
		return fn(a);
	});
}

function lazy2(fn, a, b)
{
	return thunk(fn, [a,b], function() {
		return A2(fn, a, b);
	});
}

function lazy3(fn, a, b, c)
{
	return thunk(fn, [a,b,c], function() {
		return A3(fn, a, b, c);
	});
}



// FACTS


function organizeFacts(factList)
{
	var namespace, facts = {};

	while (factList.ctor !== '[]')
	{
		var entry = factList._0;
		var key = entry.key;

		if (key === ATTR_KEY || key === ATTR_NS_KEY || key === EVENT_KEY)
		{
			var subFacts = facts[key] || {};
			subFacts[entry.realKey] = entry.value;
			facts[key] = subFacts;
		}
		else if (key === STYLE_KEY)
		{
			var styles = facts[key] || {};
			var styleList = entry.value;
			while (styleList.ctor !== '[]')
			{
				var style = styleList._0;
				styles[style._0] = style._1;
				styleList = styleList._1;
			}
			facts[key] = styles;
		}
		else if (key === 'namespace')
		{
			namespace = entry.value;
		}
		else if (key === 'className')
		{
			var classes = facts[key];
			facts[key] = typeof classes === 'undefined'
				? entry.value
				: classes + ' ' + entry.value;
		}
 		else
		{
			facts[key] = entry.value;
		}
		factList = factList._1;
	}

	return {
		facts: facts,
		namespace: namespace
	};
}



////////////  PROPERTIES AND ATTRIBUTES  ////////////


function style(value)
{
	return {
		key: STYLE_KEY,
		value: value
	};
}


function property(key, value)
{
	return {
		key: key,
		value: value
	};
}


function attribute(key, value)
{
	return {
		key: ATTR_KEY,
		realKey: key,
		value: value
	};
}


function attributeNS(namespace, key, value)
{
	return {
		key: ATTR_NS_KEY,
		realKey: key,
		value: {
			value: value,
			namespace: namespace
		}
	};
}


function on(name, options, decoder)
{
	return {
		key: EVENT_KEY,
		realKey: name,
		value: {
			options: options,
			decoder: decoder
		}
	};
}


function equalEvents(a, b)
{
	if (a.options !== b.options)
	{
		if (a.options.stopPropagation !== b.options.stopPropagation || a.options.preventDefault !== b.options.preventDefault)
		{
			return false;
		}
	}
	return _elm_lang$core$Native_Json.equality(a.decoder, b.decoder);
}


function mapProperty(func, property)
{
	if (property.key !== EVENT_KEY)
	{
		return property;
	}
	return on(
		property.realKey,
		property.value.options,
		A2(_elm_lang$core$Json_Decode$map, func, property.value.decoder)
	);
}


////////////  RENDER  ////////////


function render(vNode, eventNode)
{
	switch (vNode.type)
	{
		case 'thunk':
			if (!vNode.node)
			{
				vNode.node = vNode.thunk();
			}
			return render(vNode.node, eventNode);

		case 'tagger':
			var subNode = vNode.node;
			var tagger = vNode.tagger;

			while (subNode.type === 'tagger')
			{
				typeof tagger !== 'object'
					? tagger = [tagger, subNode.tagger]
					: tagger.push(subNode.tagger);

				subNode = subNode.node;
			}

			var subEventRoot = { tagger: tagger, parent: eventNode };
			var domNode = render(subNode, subEventRoot);
			domNode.elm_event_node_ref = subEventRoot;
			return domNode;

		case 'text':
			return localDoc.createTextNode(vNode.text);

		case 'node':
			var domNode = vNode.namespace
				? localDoc.createElementNS(vNode.namespace, vNode.tag)
				: localDoc.createElement(vNode.tag);

			applyFacts(domNode, eventNode, vNode.facts);

			var children = vNode.children;

			for (var i = 0; i < children.length; i++)
			{
				domNode.appendChild(render(children[i], eventNode));
			}

			return domNode;

		case 'keyed-node':
			var domNode = vNode.namespace
				? localDoc.createElementNS(vNode.namespace, vNode.tag)
				: localDoc.createElement(vNode.tag);

			applyFacts(domNode, eventNode, vNode.facts);

			var children = vNode.children;

			for (var i = 0; i < children.length; i++)
			{
				domNode.appendChild(render(children[i]._1, eventNode));
			}

			return domNode;

		case 'custom':
			var domNode = vNode.impl.render(vNode.model);
			applyFacts(domNode, eventNode, vNode.facts);
			return domNode;
	}
}



////////////  APPLY FACTS  ////////////


function applyFacts(domNode, eventNode, facts)
{
	for (var key in facts)
	{
		var value = facts[key];

		switch (key)
		{
			case STYLE_KEY:
				applyStyles(domNode, value);
				break;

			case EVENT_KEY:
				applyEvents(domNode, eventNode, value);
				break;

			case ATTR_KEY:
				applyAttrs(domNode, value);
				break;

			case ATTR_NS_KEY:
				applyAttrsNS(domNode, value);
				break;

			case 'value':
				if (domNode[key] !== value)
				{
					domNode[key] = value;
				}
				break;

			default:
				domNode[key] = value;
				break;
		}
	}
}

function applyStyles(domNode, styles)
{
	var domNodeStyle = domNode.style;

	for (var key in styles)
	{
		domNodeStyle[key] = styles[key];
	}
}

function applyEvents(domNode, eventNode, events)
{
	var allHandlers = domNode.elm_handlers || {};

	for (var key in events)
	{
		var handler = allHandlers[key];
		var value = events[key];

		if (typeof value === 'undefined')
		{
			domNode.removeEventListener(key, handler);
			allHandlers[key] = undefined;
		}
		else if (typeof handler === 'undefined')
		{
			var handler = makeEventHandler(eventNode, value);
			domNode.addEventListener(key, handler);
			allHandlers[key] = handler;
		}
		else
		{
			handler.info = value;
		}
	}

	domNode.elm_handlers = allHandlers;
}

function makeEventHandler(eventNode, info)
{
	function eventHandler(event)
	{
		var info = eventHandler.info;

		var value = A2(_elm_lang$core$Native_Json.run, info.decoder, event);

		if (value.ctor === 'Ok')
		{
			var options = info.options;
			if (options.stopPropagation)
			{
				event.stopPropagation();
			}
			if (options.preventDefault)
			{
				event.preventDefault();
			}

			var message = value._0;

			var currentEventNode = eventNode;
			while (currentEventNode)
			{
				var tagger = currentEventNode.tagger;
				if (typeof tagger === 'function')
				{
					message = tagger(message);
				}
				else
				{
					for (var i = tagger.length; i--; )
					{
						message = tagger[i](message);
					}
				}
				currentEventNode = currentEventNode.parent;
			}
		}
	};

	eventHandler.info = info;

	return eventHandler;
}

function applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		if (typeof value === 'undefined')
		{
			domNode.removeAttribute(key);
		}
		else
		{
			domNode.setAttribute(key, value);
		}
	}
}

function applyAttrsNS(domNode, nsAttrs)
{
	for (var key in nsAttrs)
	{
		var pair = nsAttrs[key];
		var namespace = pair.namespace;
		var value = pair.value;

		if (typeof value === 'undefined')
		{
			domNode.removeAttributeNS(namespace, key);
		}
		else
		{
			domNode.setAttributeNS(namespace, key, value);
		}
	}
}



////////////  DIFF  ////////////


function diff(a, b)
{
	var patches = [];
	diffHelp(a, b, patches, 0);
	return patches;
}


function makePatch(type, index, data)
{
	return {
		index: index,
		type: type,
		data: data,
		domNode: undefined,
		eventNode: undefined
	};
}


function diffHelp(a, b, patches, index)
{
	if (a === b)
	{
		return;
	}

	var aType = a.type;
	var bType = b.type;

	// Bail if you run into different types of nodes. Implies that the
	// structure has changed significantly and it's not worth a diff.
	if (aType !== bType)
	{
		patches.push(makePatch('p-redraw', index, b));
		return;
	}

	// Now we know that both nodes are the same type.
	switch (bType)
	{
		case 'thunk':
			var aArgs = a.args;
			var bArgs = b.args;
			var i = aArgs.length;
			var same = a.func === b.func && i === bArgs.length;
			while (same && i--)
			{
				same = aArgs[i] === bArgs[i];
			}
			if (same)
			{
				b.node = a.node;
				return;
			}
			b.node = b.thunk();
			var subPatches = [];
			diffHelp(a.node, b.node, subPatches, 0);
			if (subPatches.length > 0)
			{
				patches.push(makePatch('p-thunk', index, subPatches));
			}
			return;

		case 'tagger':
			// gather nested taggers
			var aTaggers = a.tagger;
			var bTaggers = b.tagger;
			var nesting = false;

			var aSubNode = a.node;
			while (aSubNode.type === 'tagger')
			{
				nesting = true;

				typeof aTaggers !== 'object'
					? aTaggers = [aTaggers, aSubNode.tagger]
					: aTaggers.push(aSubNode.tagger);

				aSubNode = aSubNode.node;
			}

			var bSubNode = b.node;
			while (bSubNode.type === 'tagger')
			{
				nesting = true;

				typeof bTaggers !== 'object'
					? bTaggers = [bTaggers, bSubNode.tagger]
					: bTaggers.push(bSubNode.tagger);

				bSubNode = bSubNode.node;
			}

			// Just bail if different numbers of taggers. This implies the
			// structure of the virtual DOM has changed.
			if (nesting && aTaggers.length !== bTaggers.length)
			{
				patches.push(makePatch('p-redraw', index, b));
				return;
			}

			// check if taggers are "the same"
			if (nesting ? !pairwiseRefEqual(aTaggers, bTaggers) : aTaggers !== bTaggers)
			{
				patches.push(makePatch('p-tagger', index, bTaggers));
			}

			// diff everything below the taggers
			diffHelp(aSubNode, bSubNode, patches, index + 1);
			return;

		case 'text':
			if (a.text !== b.text)
			{
				patches.push(makePatch('p-text', index, b.text));
				return;
			}

			return;

		case 'node':
			// Bail if obvious indicators have changed. Implies more serious
			// structural changes such that it's not worth it to diff.
			if (a.tag !== b.tag || a.namespace !== b.namespace)
			{
				patches.push(makePatch('p-redraw', index, b));
				return;
			}

			var factsDiff = diffFacts(a.facts, b.facts);

			if (typeof factsDiff !== 'undefined')
			{
				patches.push(makePatch('p-facts', index, factsDiff));
			}

			diffChildren(a, b, patches, index);
			return;

		case 'keyed-node':
			// Bail if obvious indicators have changed. Implies more serious
			// structural changes such that it's not worth it to diff.
			if (a.tag !== b.tag || a.namespace !== b.namespace)
			{
				patches.push(makePatch('p-redraw', index, b));
				return;
			}

			var factsDiff = diffFacts(a.facts, b.facts);

			if (typeof factsDiff !== 'undefined')
			{
				patches.push(makePatch('p-facts', index, factsDiff));
			}

			diffKeyedChildren(a, b, patches, index);
			return;

		case 'custom':
			if (a.impl !== b.impl)
			{
				patches.push(makePatch('p-redraw', index, b));
				return;
			}

			var factsDiff = diffFacts(a.facts, b.facts);
			if (typeof factsDiff !== 'undefined')
			{
				patches.push(makePatch('p-facts', index, factsDiff));
			}

			var patch = b.impl.diff(a,b);
			if (patch)
			{
				patches.push(makePatch('p-custom', index, patch));
				return;
			}

			return;
	}
}


// assumes the incoming arrays are the same length
function pairwiseRefEqual(as, bs)
{
	for (var i = 0; i < as.length; i++)
	{
		if (as[i] !== bs[i])
		{
			return false;
		}
	}

	return true;
}


// TODO Instead of creating a new diff object, it's possible to just test if
// there *is* a diff. During the actual patch, do the diff again and make the
// modifications directly. This way, there's no new allocations. Worth it?
function diffFacts(a, b, category)
{
	var diff;

	// look for changes and removals
	for (var aKey in a)
	{
		if (aKey === STYLE_KEY || aKey === EVENT_KEY || aKey === ATTR_KEY || aKey === ATTR_NS_KEY)
		{
			var subDiff = diffFacts(a[aKey], b[aKey] || {}, aKey);
			if (subDiff)
			{
				diff = diff || {};
				diff[aKey] = subDiff;
			}
			continue;
		}

		// remove if not in the new facts
		if (!(aKey in b))
		{
			diff = diff || {};
			diff[aKey] =
				(typeof category === 'undefined')
					? (typeof a[aKey] === 'string' ? '' : null)
					:
				(category === STYLE_KEY)
					? ''
					:
				(category === EVENT_KEY || category === ATTR_KEY)
					? undefined
					:
				{ namespace: a[aKey].namespace, value: undefined };

			continue;
		}

		var aValue = a[aKey];
		var bValue = b[aKey];

		// reference equal, so don't worry about it
		if (aValue === bValue && aKey !== 'value'
			|| category === EVENT_KEY && equalEvents(aValue, bValue))
		{
			continue;
		}

		diff = diff || {};
		diff[aKey] = bValue;
	}

	// add new stuff
	for (var bKey in b)
	{
		if (!(bKey in a))
		{
			diff = diff || {};
			diff[bKey] = b[bKey];
		}
	}

	return diff;
}


function diffChildren(aParent, bParent, patches, rootIndex)
{
	var aChildren = aParent.children;
	var bChildren = bParent.children;

	var aLen = aChildren.length;
	var bLen = bChildren.length;

	// FIGURE OUT IF THERE ARE INSERTS OR REMOVALS

	if (aLen > bLen)
	{
		patches.push(makePatch('p-remove-last', rootIndex, aLen - bLen));
	}
	else if (aLen < bLen)
	{
		patches.push(makePatch('p-append', rootIndex, bChildren.slice(aLen)));
	}

	// PAIRWISE DIFF EVERYTHING ELSE

	var index = rootIndex;
	var minLen = aLen < bLen ? aLen : bLen;
	for (var i = 0; i < minLen; i++)
	{
		index++;
		var aChild = aChildren[i];
		diffHelp(aChild, bChildren[i], patches, index);
		index += aChild.descendantsCount || 0;
	}
}



////////////  KEYED DIFF  ////////////


function diffKeyedChildren(aParent, bParent, patches, rootIndex)
{
	var localPatches = [];

	var changes = {}; // Dict String Entry
	var inserts = []; // Array { index : Int, entry : Entry }
	// type Entry = { tag : String, vnode : VNode, index : Int, data : _ }

	var aChildren = aParent.children;
	var bChildren = bParent.children;
	var aLen = aChildren.length;
	var bLen = bChildren.length;
	var aIndex = 0;
	var bIndex = 0;

	var index = rootIndex;

	while (aIndex < aLen && bIndex < bLen)
	{
		var a = aChildren[aIndex];
		var b = bChildren[bIndex];

		var aKey = a._0;
		var bKey = b._0;
		var aNode = a._1;
		var bNode = b._1;

		// check if keys match

		if (aKey === bKey)
		{
			index++;
			diffHelp(aNode, bNode, localPatches, index);
			index += aNode.descendantsCount || 0;

			aIndex++;
			bIndex++;
			continue;
		}

		// look ahead 1 to detect insertions and removals.

		var aLookAhead = aIndex + 1 < aLen;
		var bLookAhead = bIndex + 1 < bLen;

		if (aLookAhead)
		{
			var aNext = aChildren[aIndex + 1];
			var aNextKey = aNext._0;
			var aNextNode = aNext._1;
			var oldMatch = bKey === aNextKey;
		}

		if (bLookAhead)
		{
			var bNext = bChildren[bIndex + 1];
			var bNextKey = bNext._0;
			var bNextNode = bNext._1;
			var newMatch = aKey === bNextKey;
		}


		// swap a and b
		if (aLookAhead && bLookAhead && newMatch && oldMatch)
		{
			index++;
			diffHelp(aNode, bNextNode, localPatches, index);
			insertNode(changes, localPatches, aKey, bNode, bIndex, inserts);
			index += aNode.descendantsCount || 0;

			index++;
			removeNode(changes, localPatches, aKey, aNextNode, index);
			index += aNextNode.descendantsCount || 0;

			aIndex += 2;
			bIndex += 2;
			continue;
		}

		// insert b
		if (bLookAhead && newMatch)
		{
			index++;
			insertNode(changes, localPatches, bKey, bNode, bIndex, inserts);
			diffHelp(aNode, bNextNode, localPatches, index);
			index += aNode.descendantsCount || 0;

			aIndex += 1;
			bIndex += 2;
			continue;
		}

		// remove a
		if (aLookAhead && oldMatch)
		{
			index++;
			removeNode(changes, localPatches, aKey, aNode, index);
			index += aNode.descendantsCount || 0;

			index++;
			diffHelp(aNextNode, bNode, localPatches, index);
			index += aNextNode.descendantsCount || 0;

			aIndex += 2;
			bIndex += 1;
			continue;
		}

		// remove a, insert b
		if (aLookAhead && bLookAhead && aNextKey === bNextKey)
		{
			index++;
			removeNode(changes, localPatches, aKey, aNode, index);
			insertNode(changes, localPatches, bKey, bNode, bIndex, inserts);
			index += aNode.descendantsCount || 0;

			index++;
			diffHelp(aNextNode, bNextNode, localPatches, index);
			index += aNextNode.descendantsCount || 0;

			aIndex += 2;
			bIndex += 2;
			continue;
		}

		break;
	}

	// eat up any remaining nodes with removeNode and insertNode

	while (aIndex < aLen)
	{
		index++;
		var a = aChildren[aIndex];
		var aNode = a._1;
		removeNode(changes, localPatches, a._0, aNode, index);
		index += aNode.descendantsCount || 0;
		aIndex++;
	}

	var endInserts;
	while (bIndex < bLen)
	{
		endInserts = endInserts || [];
		var b = bChildren[bIndex];
		insertNode(changes, localPatches, b._0, b._1, undefined, endInserts);
		bIndex++;
	}

	if (localPatches.length > 0 || inserts.length > 0 || typeof endInserts !== 'undefined')
	{
		patches.push(makePatch('p-reorder', rootIndex, {
			patches: localPatches,
			inserts: inserts,
			endInserts: endInserts
		}));
	}
}



////////////  CHANGES FROM KEYED DIFF  ////////////


var POSTFIX = '_elmW6BL';


function insertNode(changes, localPatches, key, vnode, bIndex, inserts)
{
	var entry = changes[key];

	// never seen this key before
	if (typeof entry === 'undefined')
	{
		entry = {
			tag: 'insert',
			vnode: vnode,
			index: bIndex,
			data: undefined
		};

		inserts.push({ index: bIndex, entry: entry });
		changes[key] = entry;

		return;
	}

	// this key was removed earlier, a match!
	if (entry.tag === 'remove')
	{
		inserts.push({ index: bIndex, entry: entry });

		entry.tag = 'move';
		var subPatches = [];
		diffHelp(entry.vnode, vnode, subPatches, entry.index);
		entry.index = bIndex;
		entry.data.data = {
			patches: subPatches,
			entry: entry
		};

		return;
	}

	// this key has already been inserted or moved, a duplicate!
	insertNode(changes, localPatches, key + POSTFIX, vnode, bIndex, inserts);
}


function removeNode(changes, localPatches, key, vnode, index)
{
	var entry = changes[key];

	// never seen this key before
	if (typeof entry === 'undefined')
	{
		var patch = makePatch('p-remove', index, undefined);
		localPatches.push(patch);

		changes[key] = {
			tag: 'remove',
			vnode: vnode,
			index: index,
			data: patch
		};

		return;
	}

	// this key was inserted earlier, a match!
	if (entry.tag === 'insert')
	{
		entry.tag = 'move';
		var subPatches = [];
		diffHelp(vnode, entry.vnode, subPatches, index);

		var patch = makePatch('p-remove', index, {
			patches: subPatches,
			entry: entry
		});
		localPatches.push(patch);

		return;
	}

	// this key has already been removed or moved, a duplicate!
	removeNode(changes, localPatches, key + POSTFIX, vnode, index);
}



////////////  ADD DOM NODES  ////////////
//
// Each DOM node has an "index" assigned in order of traversal. It is important
// to minimize our crawl over the actual DOM, so these indexes (along with the
// descendantsCount of virtual nodes) let us skip touching entire subtrees of
// the DOM if we know there are no patches there.


function addDomNodes(domNode, vNode, patches, eventNode)
{
	addDomNodesHelp(domNode, vNode, patches, 0, 0, vNode.descendantsCount, eventNode);
}


// assumes `patches` is non-empty and indexes increase monotonically.
function addDomNodesHelp(domNode, vNode, patches, i, low, high, eventNode)
{
	var patch = patches[i];
	var index = patch.index;

	while (index === low)
	{
		var patchType = patch.type;

		if (patchType === 'p-thunk')
		{
			addDomNodes(domNode, vNode.node, patch.data, eventNode);
		}
		else if (patchType === 'p-reorder')
		{
			patch.domNode = domNode;
			patch.eventNode = eventNode;

			var subPatches = patch.data.patches;
			if (subPatches.length > 0)
			{
				addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
			}
		}
		else if (patchType === 'p-remove')
		{
			patch.domNode = domNode;
			patch.eventNode = eventNode;

			var data = patch.data;
			if (typeof data !== 'undefined')
			{
				data.entry.data = domNode;
				var subPatches = data.patches;
				if (subPatches.length > 0)
				{
					addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
				}
			}
		}
		else
		{
			patch.domNode = domNode;
			patch.eventNode = eventNode;
		}

		i++;

		if (!(patch = patches[i]) || (index = patch.index) > high)
		{
			return i;
		}
	}

	switch (vNode.type)
	{
		case 'tagger':
			var subNode = vNode.node;

			while (subNode.type === "tagger")
			{
				subNode = subNode.node;
			}

			return addDomNodesHelp(domNode, subNode, patches, i, low + 1, high, domNode.elm_event_node_ref);

		case 'node':
			var vChildren = vNode.children;
			var childNodes = domNode.childNodes;
			for (var j = 0; j < vChildren.length; j++)
			{
				low++;
				var vChild = vChildren[j];
				var nextLow = low + (vChild.descendantsCount || 0);
				if (low <= index && index <= nextLow)
				{
					i = addDomNodesHelp(childNodes[j], vChild, patches, i, low, nextLow, eventNode);
					if (!(patch = patches[i]) || (index = patch.index) > high)
					{
						return i;
					}
				}
				low = nextLow;
			}
			return i;

		case 'keyed-node':
			var vChildren = vNode.children;
			var childNodes = domNode.childNodes;
			for (var j = 0; j < vChildren.length; j++)
			{
				low++;
				var vChild = vChildren[j]._1;
				var nextLow = low + (vChild.descendantsCount || 0);
				if (low <= index && index <= nextLow)
				{
					i = addDomNodesHelp(childNodes[j], vChild, patches, i, low, nextLow, eventNode);
					if (!(patch = patches[i]) || (index = patch.index) > high)
					{
						return i;
					}
				}
				low = nextLow;
			}
			return i;

		case 'text':
		case 'thunk':
			throw new Error('should never traverse `text` or `thunk` nodes like this');
	}
}



////////////  APPLY PATCHES  ////////////


function applyPatches(rootDomNode, oldVirtualNode, patches, eventNode)
{
	if (patches.length === 0)
	{
		return rootDomNode;
	}

	addDomNodes(rootDomNode, oldVirtualNode, patches, eventNode);
	return applyPatchesHelp(rootDomNode, patches);
}

function applyPatchesHelp(rootDomNode, patches)
{
	for (var i = 0; i < patches.length; i++)
	{
		var patch = patches[i];
		var localDomNode = patch.domNode
		var newNode = applyPatch(localDomNode, patch);
		if (localDomNode === rootDomNode)
		{
			rootDomNode = newNode;
		}
	}
	return rootDomNode;
}

function applyPatch(domNode, patch)
{
	switch (patch.type)
	{
		case 'p-redraw':
			return applyPatchRedraw(domNode, patch.data, patch.eventNode);

		case 'p-facts':
			applyFacts(domNode, patch.eventNode, patch.data);
			return domNode;

		case 'p-text':
			domNode.replaceData(0, domNode.length, patch.data);
			return domNode;

		case 'p-thunk':
			return applyPatchesHelp(domNode, patch.data);

		case 'p-tagger':
			if (typeof domNode.elm_event_node_ref !== 'undefined')
			{
				domNode.elm_event_node_ref.tagger = patch.data;
			}
			else
			{
				domNode.elm_event_node_ref = { tagger: patch.data, parent: patch.eventNode };
			}
			return domNode;

		case 'p-remove-last':
			var i = patch.data;
			while (i--)
			{
				domNode.removeChild(domNode.lastChild);
			}
			return domNode;

		case 'p-append':
			var newNodes = patch.data;
			for (var i = 0; i < newNodes.length; i++)
			{
				domNode.appendChild(render(newNodes[i], patch.eventNode));
			}
			return domNode;

		case 'p-remove':
			var data = patch.data;
			if (typeof data === 'undefined')
			{
				domNode.parentNode.removeChild(domNode);
				return domNode;
			}
			var entry = data.entry;
			if (typeof entry.index !== 'undefined')
			{
				domNode.parentNode.removeChild(domNode);
			}
			entry.data = applyPatchesHelp(domNode, data.patches);
			return domNode;

		case 'p-reorder':
			return applyPatchReorder(domNode, patch);

		case 'p-custom':
			var impl = patch.data;
			return impl.applyPatch(domNode, impl.data);

		default:
			throw new Error('Ran into an unknown patch!');
	}
}


function applyPatchRedraw(domNode, vNode, eventNode)
{
	var parentNode = domNode.parentNode;
	var newNode = render(vNode, eventNode);

	if (typeof newNode.elm_event_node_ref === 'undefined')
	{
		newNode.elm_event_node_ref = domNode.elm_event_node_ref;
	}

	if (parentNode && newNode !== domNode)
	{
		parentNode.replaceChild(newNode, domNode);
	}
	return newNode;
}


function applyPatchReorder(domNode, patch)
{
	var data = patch.data;

	// remove end inserts
	var frag = applyPatchReorderEndInsertsHelp(data.endInserts, patch);

	// removals
	domNode = applyPatchesHelp(domNode, data.patches);

	// inserts
	var inserts = data.inserts;
	for (var i = 0; i < inserts.length; i++)
	{
		var insert = inserts[i];
		var entry = insert.entry;
		var node = entry.tag === 'move'
			? entry.data
			: render(entry.vnode, patch.eventNode);
		domNode.insertBefore(node, domNode.childNodes[insert.index]);
	}

	// add end inserts
	if (typeof frag !== 'undefined')
	{
		domNode.appendChild(frag);
	}

	return domNode;
}


function applyPatchReorderEndInsertsHelp(endInserts, patch)
{
	if (typeof endInserts === 'undefined')
	{
		return;
	}

	var frag = localDoc.createDocumentFragment();
	for (var i = 0; i < endInserts.length; i++)
	{
		var insert = endInserts[i];
		var entry = insert.entry;
		frag.appendChild(entry.tag === 'move'
			? entry.data
			: render(entry.vnode, patch.eventNode)
		);
	}
	return frag;
}


// PROGRAMS

var program = makeProgram(checkNoFlags);
var programWithFlags = makeProgram(checkYesFlags);

function makeProgram(flagChecker)
{
	return F2(function(debugWrap, impl)
	{
		return function(flagDecoder)
		{
			return function(object, moduleName, debugMetadata)
			{
				var checker = flagChecker(flagDecoder, moduleName);
				if (typeof debugMetadata === 'undefined')
				{
					normalSetup(impl, object, moduleName, checker);
				}
				else
				{
					debugSetup(A2(debugWrap, debugMetadata, impl), object, moduleName, checker);
				}
			};
		};
	});
}

function staticProgram(vNode)
{
	var nothing = _elm_lang$core$Native_Utils.Tuple2(
		_elm_lang$core$Native_Utils.Tuple0,
		_elm_lang$core$Platform_Cmd$none
	);
	return A2(program, _elm_lang$virtual_dom$VirtualDom_Debug$wrap, {
		init: nothing,
		view: function() { return vNode; },
		update: F2(function() { return nothing; }),
		subscriptions: function() { return _elm_lang$core$Platform_Sub$none; }
	})();
}


// FLAG CHECKERS

function checkNoFlags(flagDecoder, moduleName)
{
	return function(init, flags, domNode)
	{
		if (typeof flags === 'undefined')
		{
			return init;
		}

		var errorMessage =
			'The `' + moduleName + '` module does not need flags.\n'
			+ 'Initialize it with no arguments and you should be all set!';

		crash(errorMessage, domNode);
	};
}

function checkYesFlags(flagDecoder, moduleName)
{
	return function(init, flags, domNode)
	{
		if (typeof flagDecoder === 'undefined')
		{
			var errorMessage =
				'Are you trying to sneak a Never value into Elm? Trickster!\n'
				+ 'It looks like ' + moduleName + '.main is defined with `programWithFlags` but has type `Program Never`.\n'
				+ 'Use `program` instead if you do not want flags.'

			crash(errorMessage, domNode);
		}

		var result = A2(_elm_lang$core$Native_Json.run, flagDecoder, flags);
		if (result.ctor === 'Ok')
		{
			return init(result._0);
		}

		var errorMessage =
			'Trying to initialize the `' + moduleName + '` module with an unexpected flag.\n'
			+ 'I tried to convert it to an Elm value, but ran into this problem:\n\n'
			+ result._0;

		crash(errorMessage, domNode);
	};
}

function crash(errorMessage, domNode)
{
	if (domNode)
	{
		domNode.innerHTML =
			'<div style="padding-left:1em;">'
			+ '<h2 style="font-weight:normal;"><b>Oops!</b> Something went wrong when starting your Elm program.</h2>'
			+ '<pre style="padding-left:1em;">' + errorMessage + '</pre>'
			+ '</div>';
	}

	throw new Error(errorMessage);
}


//  NORMAL SETUP

function normalSetup(impl, object, moduleName, flagChecker)
{
	object['embed'] = function embed(node, flags)
	{
		while (node.lastChild)
		{
			node.removeChild(node.lastChild);
		}

		return _elm_lang$core$Native_Platform.initialize(
			flagChecker(impl.init, flags, node),
			impl.update,
			impl.subscriptions,
			normalRenderer(node, impl.view)
		);
	};

	object['fullscreen'] = function fullscreen(flags)
	{
		return _elm_lang$core$Native_Platform.initialize(
			flagChecker(impl.init, flags, document.body),
			impl.update,
			impl.subscriptions,
			normalRenderer(document.body, impl.view)
		);
	};
}

function normalRenderer(parentNode, view)
{
	return function(tagger, initialModel)
	{
		var eventNode = { tagger: tagger, parent: undefined };
		var initialVirtualNode = view(initialModel);
		var domNode = render(initialVirtualNode, eventNode);
		parentNode.appendChild(domNode);
		return makeStepper(domNode, view, initialVirtualNode, eventNode);
	};
}


// STEPPER

var rAF =
	typeof requestAnimationFrame !== 'undefined'
		? requestAnimationFrame
		: function(callback) { setTimeout(callback, 1000 / 60); };

function makeStepper(domNode, view, initialVirtualNode, eventNode)
{
	var state = 'NO_REQUEST';
	var currNode = initialVirtualNode;
	var nextModel;

	function updateIfNeeded()
	{
		switch (state)
		{
			case 'NO_REQUEST':
				throw new Error(
					'Unexpected draw callback.\n' +
					'Please report this to <https://github.com/elm-lang/virtual-dom/issues>.'
				);

			case 'PENDING_REQUEST':
				rAF(updateIfNeeded);
				state = 'EXTRA_REQUEST';

				var nextNode = view(nextModel);
				var patches = diff(currNode, nextNode);
				domNode = applyPatches(domNode, currNode, patches, eventNode);
				currNode = nextNode;

				return;

			case 'EXTRA_REQUEST':
				state = 'NO_REQUEST';
				return;
		}
	}

	return function stepper(model)
	{
		if (state === 'NO_REQUEST')
		{
			rAF(updateIfNeeded);
		}
		state = 'PENDING_REQUEST';
		nextModel = model;
	};
}


// DEBUG SETUP

function debugSetup(impl, object, moduleName, flagChecker)
{
	object['fullscreen'] = function fullscreen(flags)
	{
		var popoutRef = { doc: undefined };
		return _elm_lang$core$Native_Platform.initialize(
			flagChecker(impl.init, flags, document.body),
			impl.update(scrollTask(popoutRef)),
			impl.subscriptions,
			debugRenderer(moduleName, document.body, popoutRef, impl.view, impl.viewIn, impl.viewOut)
		);
	};

	object['embed'] = function fullscreen(node, flags)
	{
		var popoutRef = { doc: undefined };
		return _elm_lang$core$Native_Platform.initialize(
			flagChecker(impl.init, flags, node),
			impl.update(scrollTask(popoutRef)),
			impl.subscriptions,
			debugRenderer(moduleName, node, popoutRef, impl.view, impl.viewIn, impl.viewOut)
		);
	};
}

function scrollTask(popoutRef)
{
	return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback)
	{
		var doc = popoutRef.doc;
		if (doc)
		{
			var msgs = doc.getElementsByClassName('debugger-sidebar-messages')[0];
			if (msgs)
			{
				msgs.scrollTop = msgs.scrollHeight;
			}
		}
		callback(_elm_lang$core$Native_Scheduler.succeed(_elm_lang$core$Native_Utils.Tuple0));
	});
}


function debugRenderer(moduleName, parentNode, popoutRef, view, viewIn, viewOut)
{
	return function(tagger, initialModel)
	{
		var appEventNode = { tagger: tagger, parent: undefined };
		var eventNode = { tagger: tagger, parent: undefined };

		// make normal stepper
		var appVirtualNode = view(initialModel);
		var appNode = render(appVirtualNode, appEventNode);
		parentNode.appendChild(appNode);
		var appStepper = makeStepper(appNode, view, appVirtualNode, appEventNode);

		// make overlay stepper
		var overVirtualNode = viewIn(initialModel)._1;
		var overNode = render(overVirtualNode, eventNode);
		parentNode.appendChild(overNode);
		var wrappedViewIn = wrapViewIn(appEventNode, overNode, viewIn);
		var overStepper = makeStepper(overNode, wrappedViewIn, overVirtualNode, eventNode);

		// make debugger stepper
		var debugStepper = makeDebugStepper(initialModel, viewOut, eventNode, parentNode, moduleName, popoutRef);

		return function stepper(model)
		{
			appStepper(model);
			overStepper(model);
			debugStepper(model);
		}
	};
}

function makeDebugStepper(initialModel, view, eventNode, parentNode, moduleName, popoutRef)
{
	var curr;
	var domNode;

	return function stepper(model)
	{
		if (!model.isDebuggerOpen)
		{
			return;
		}

		if (!popoutRef.doc)
		{
			curr = view(model);
			domNode = openDebugWindow(moduleName, popoutRef, curr, eventNode);
			return;
		}

		// switch to document of popout
		localDoc = popoutRef.doc;

		var next = view(model);
		var patches = diff(curr, next);
		domNode = applyPatches(domNode, curr, patches, eventNode);
		curr = next;

		// switch back to normal document
		localDoc = document;
	};
}

function openDebugWindow(moduleName, popoutRef, virtualNode, eventNode)
{
	var w = 900;
	var h = 360;
	var x = screen.width - w;
	var y = screen.height - h;
	var debugWindow = window.open('', '', 'width=' + w + ',height=' + h + ',left=' + x + ',top=' + y);

	// switch to window document
	localDoc = debugWindow.document;

	popoutRef.doc = localDoc;
	localDoc.title = 'Debugger - ' + moduleName;
	localDoc.body.style.margin = '0';
	localDoc.body.style.padding = '0';
	var domNode = render(virtualNode, eventNode);
	localDoc.body.appendChild(domNode);

	localDoc.addEventListener('keydown', function(event) {
		if (event.metaKey && event.which === 82)
		{
			window.location.reload();
		}
		if (event.which === 38)
		{
			eventNode.tagger({ ctor: 'Up' });
			event.preventDefault();
		}
		if (event.which === 40)
		{
			eventNode.tagger({ ctor: 'Down' });
			event.preventDefault();
		}
	});

	function close()
	{
		popoutRef.doc = undefined;
		debugWindow.close();
	}
	window.addEventListener('unload', close);
	debugWindow.addEventListener('unload', function() {
		popoutRef.doc = undefined;
		window.removeEventListener('unload', close);
		eventNode.tagger({ ctor: 'Close' });
	});

	// switch back to the normal document
	localDoc = document;

	return domNode;
}


// BLOCK EVENTS

function wrapViewIn(appEventNode, overlayNode, viewIn)
{
	var ignorer = makeIgnorer(overlayNode);
	var blocking = 'Normal';
	var overflow;

	var normalTagger = appEventNode.tagger;
	var blockTagger = function() {};

	return function(model)
	{
		var tuple = viewIn(model);
		var newBlocking = tuple._0.ctor;
		appEventNode.tagger = newBlocking === 'Normal' ? normalTagger : blockTagger;
		if (blocking !== newBlocking)
		{
			traverse('removeEventListener', ignorer, blocking);
			traverse('addEventListener', ignorer, newBlocking);

			if (blocking === 'Normal')
			{
				overflow = document.body.style.overflow;
				document.body.style.overflow = 'hidden';
			}

			if (newBlocking === 'Normal')
			{
				document.body.style.overflow = overflow;
			}

			blocking = newBlocking;
		}
		return tuple._1;
	}
}

function traverse(verbEventListener, ignorer, blocking)
{
	switch(blocking)
	{
		case 'Normal':
			return;

		case 'Pause':
			return traverseHelp(verbEventListener, ignorer, mostEvents);

		case 'Message':
			return traverseHelp(verbEventListener, ignorer, allEvents);
	}
}

function traverseHelp(verbEventListener, handler, eventNames)
{
	for (var i = 0; i < eventNames.length; i++)
	{
		document.body[verbEventListener](eventNames[i], handler, true);
	}
}

function makeIgnorer(overlayNode)
{
	return function(event)
	{
		if (event.type === 'keydown' && event.metaKey && event.which === 82)
		{
			return;
		}

		var isScroll = event.type === 'scroll' || event.type === 'wheel';

		var node = event.target;
		while (node !== null)
		{
			if (node.className === 'elm-overlay-message-details' && isScroll)
			{
				return;
			}

			if (node === overlayNode && !isScroll)
			{
				return;
			}
			node = node.parentNode;
		}

		event.stopPropagation();
		event.preventDefault();
	}
}

var mostEvents = [
	'click', 'dblclick', 'mousemove',
	'mouseup', 'mousedown', 'mouseenter', 'mouseleave',
	'touchstart', 'touchend', 'touchcancel', 'touchmove',
	'pointerdown', 'pointerup', 'pointerover', 'pointerout',
	'pointerenter', 'pointerleave', 'pointermove', 'pointercancel',
	'dragstart', 'drag', 'dragend', 'dragenter', 'dragover', 'dragleave', 'drop',
	'keyup', 'keydown', 'keypress',
	'input', 'change',
	'focus', 'blur'
];

var allEvents = mostEvents.concat('wheel', 'scroll');


return {
	node: node,
	text: text,
	custom: custom,
	map: F2(map),

	on: F3(on),
	style: style,
	property: F2(property),
	attribute: F2(attribute),
	attributeNS: F3(attributeNS),
	mapProperty: F2(mapProperty),

	lazy: F2(lazy),
	lazy2: F3(lazy2),
	lazy3: F4(lazy3),
	keyedNode: F3(keyedNode),

	program: program,
	programWithFlags: programWithFlags,
	staticProgram: staticProgram
};

}();

var _elm_lang$virtual_dom$VirtualDom$programWithFlags = function (impl) {
	return A2(_elm_lang$virtual_dom$Native_VirtualDom.programWithFlags, _elm_lang$virtual_dom$VirtualDom_Debug$wrapWithFlags, impl);
};
var _elm_lang$virtual_dom$VirtualDom$program = function (impl) {
	return A2(_elm_lang$virtual_dom$Native_VirtualDom.program, _elm_lang$virtual_dom$VirtualDom_Debug$wrap, impl);
};
var _elm_lang$virtual_dom$VirtualDom$keyedNode = _elm_lang$virtual_dom$Native_VirtualDom.keyedNode;
var _elm_lang$virtual_dom$VirtualDom$lazy3 = _elm_lang$virtual_dom$Native_VirtualDom.lazy3;
var _elm_lang$virtual_dom$VirtualDom$lazy2 = _elm_lang$virtual_dom$Native_VirtualDom.lazy2;
var _elm_lang$virtual_dom$VirtualDom$lazy = _elm_lang$virtual_dom$Native_VirtualDom.lazy;
var _elm_lang$virtual_dom$VirtualDom$defaultOptions = {stopPropagation: false, preventDefault: false};
var _elm_lang$virtual_dom$VirtualDom$onWithOptions = _elm_lang$virtual_dom$Native_VirtualDom.on;
var _elm_lang$virtual_dom$VirtualDom$on = F2(
	function (eventName, decoder) {
		return A3(_elm_lang$virtual_dom$VirtualDom$onWithOptions, eventName, _elm_lang$virtual_dom$VirtualDom$defaultOptions, decoder);
	});
var _elm_lang$virtual_dom$VirtualDom$style = _elm_lang$virtual_dom$Native_VirtualDom.style;
var _elm_lang$virtual_dom$VirtualDom$mapProperty = _elm_lang$virtual_dom$Native_VirtualDom.mapProperty;
var _elm_lang$virtual_dom$VirtualDom$attributeNS = _elm_lang$virtual_dom$Native_VirtualDom.attributeNS;
var _elm_lang$virtual_dom$VirtualDom$attribute = _elm_lang$virtual_dom$Native_VirtualDom.attribute;
var _elm_lang$virtual_dom$VirtualDom$property = _elm_lang$virtual_dom$Native_VirtualDom.property;
var _elm_lang$virtual_dom$VirtualDom$map = _elm_lang$virtual_dom$Native_VirtualDom.map;
var _elm_lang$virtual_dom$VirtualDom$text = _elm_lang$virtual_dom$Native_VirtualDom.text;
var _elm_lang$virtual_dom$VirtualDom$node = _elm_lang$virtual_dom$Native_VirtualDom.node;
var _elm_lang$virtual_dom$VirtualDom$Options = F2(
	function (a, b) {
		return {stopPropagation: a, preventDefault: b};
	});
var _elm_lang$virtual_dom$VirtualDom$Node = {ctor: 'Node'};
var _elm_lang$virtual_dom$VirtualDom$Property = {ctor: 'Property'};

var _elm_lang$html$Html$programWithFlags = _elm_lang$virtual_dom$VirtualDom$programWithFlags;
var _elm_lang$html$Html$program = _elm_lang$virtual_dom$VirtualDom$program;
var _elm_lang$html$Html$beginnerProgram = function (_p0) {
	var _p1 = _p0;
	return _elm_lang$html$Html$program(
		{
			init: A2(
				_elm_lang$core$Platform_Cmd_ops['!'],
				_p1.model,
				{ctor: '[]'}),
			update: F2(
				function (msg, model) {
					return A2(
						_elm_lang$core$Platform_Cmd_ops['!'],
						A2(_p1.update, msg, model),
						{ctor: '[]'});
				}),
			view: _p1.view,
			subscriptions: function (_p2) {
				return _elm_lang$core$Platform_Sub$none;
			}
		});
};
var _elm_lang$html$Html$map = _elm_lang$virtual_dom$VirtualDom$map;
var _elm_lang$html$Html$text = _elm_lang$virtual_dom$VirtualDom$text;
var _elm_lang$html$Html$node = _elm_lang$virtual_dom$VirtualDom$node;
var _elm_lang$html$Html$body = _elm_lang$html$Html$node('body');
var _elm_lang$html$Html$section = _elm_lang$html$Html$node('section');
var _elm_lang$html$Html$nav = _elm_lang$html$Html$node('nav');
var _elm_lang$html$Html$article = _elm_lang$html$Html$node('article');
var _elm_lang$html$Html$aside = _elm_lang$html$Html$node('aside');
var _elm_lang$html$Html$h1 = _elm_lang$html$Html$node('h1');
var _elm_lang$html$Html$h2 = _elm_lang$html$Html$node('h2');
var _elm_lang$html$Html$h3 = _elm_lang$html$Html$node('h3');
var _elm_lang$html$Html$h4 = _elm_lang$html$Html$node('h4');
var _elm_lang$html$Html$h5 = _elm_lang$html$Html$node('h5');
var _elm_lang$html$Html$h6 = _elm_lang$html$Html$node('h6');
var _elm_lang$html$Html$header = _elm_lang$html$Html$node('header');
var _elm_lang$html$Html$footer = _elm_lang$html$Html$node('footer');
var _elm_lang$html$Html$address = _elm_lang$html$Html$node('address');
var _elm_lang$html$Html$main_ = _elm_lang$html$Html$node('main');
var _elm_lang$html$Html$p = _elm_lang$html$Html$node('p');
var _elm_lang$html$Html$hr = _elm_lang$html$Html$node('hr');
var _elm_lang$html$Html$pre = _elm_lang$html$Html$node('pre');
var _elm_lang$html$Html$blockquote = _elm_lang$html$Html$node('blockquote');
var _elm_lang$html$Html$ol = _elm_lang$html$Html$node('ol');
var _elm_lang$html$Html$ul = _elm_lang$html$Html$node('ul');
var _elm_lang$html$Html$li = _elm_lang$html$Html$node('li');
var _elm_lang$html$Html$dl = _elm_lang$html$Html$node('dl');
var _elm_lang$html$Html$dt = _elm_lang$html$Html$node('dt');
var _elm_lang$html$Html$dd = _elm_lang$html$Html$node('dd');
var _elm_lang$html$Html$figure = _elm_lang$html$Html$node('figure');
var _elm_lang$html$Html$figcaption = _elm_lang$html$Html$node('figcaption');
var _elm_lang$html$Html$div = _elm_lang$html$Html$node('div');
var _elm_lang$html$Html$a = _elm_lang$html$Html$node('a');
var _elm_lang$html$Html$em = _elm_lang$html$Html$node('em');
var _elm_lang$html$Html$strong = _elm_lang$html$Html$node('strong');
var _elm_lang$html$Html$small = _elm_lang$html$Html$node('small');
var _elm_lang$html$Html$s = _elm_lang$html$Html$node('s');
var _elm_lang$html$Html$cite = _elm_lang$html$Html$node('cite');
var _elm_lang$html$Html$q = _elm_lang$html$Html$node('q');
var _elm_lang$html$Html$dfn = _elm_lang$html$Html$node('dfn');
var _elm_lang$html$Html$abbr = _elm_lang$html$Html$node('abbr');
var _elm_lang$html$Html$time = _elm_lang$html$Html$node('time');
var _elm_lang$html$Html$code = _elm_lang$html$Html$node('code');
var _elm_lang$html$Html$var = _elm_lang$html$Html$node('var');
var _elm_lang$html$Html$samp = _elm_lang$html$Html$node('samp');
var _elm_lang$html$Html$kbd = _elm_lang$html$Html$node('kbd');
var _elm_lang$html$Html$sub = _elm_lang$html$Html$node('sub');
var _elm_lang$html$Html$sup = _elm_lang$html$Html$node('sup');
var _elm_lang$html$Html$i = _elm_lang$html$Html$node('i');
var _elm_lang$html$Html$b = _elm_lang$html$Html$node('b');
var _elm_lang$html$Html$u = _elm_lang$html$Html$node('u');
var _elm_lang$html$Html$mark = _elm_lang$html$Html$node('mark');
var _elm_lang$html$Html$ruby = _elm_lang$html$Html$node('ruby');
var _elm_lang$html$Html$rt = _elm_lang$html$Html$node('rt');
var _elm_lang$html$Html$rp = _elm_lang$html$Html$node('rp');
var _elm_lang$html$Html$bdi = _elm_lang$html$Html$node('bdi');
var _elm_lang$html$Html$bdo = _elm_lang$html$Html$node('bdo');
var _elm_lang$html$Html$span = _elm_lang$html$Html$node('span');
var _elm_lang$html$Html$br = _elm_lang$html$Html$node('br');
var _elm_lang$html$Html$wbr = _elm_lang$html$Html$node('wbr');
var _elm_lang$html$Html$ins = _elm_lang$html$Html$node('ins');
var _elm_lang$html$Html$del = _elm_lang$html$Html$node('del');
var _elm_lang$html$Html$img = _elm_lang$html$Html$node('img');
var _elm_lang$html$Html$iframe = _elm_lang$html$Html$node('iframe');
var _elm_lang$html$Html$embed = _elm_lang$html$Html$node('embed');
var _elm_lang$html$Html$object = _elm_lang$html$Html$node('object');
var _elm_lang$html$Html$param = _elm_lang$html$Html$node('param');
var _elm_lang$html$Html$video = _elm_lang$html$Html$node('video');
var _elm_lang$html$Html$audio = _elm_lang$html$Html$node('audio');
var _elm_lang$html$Html$source = _elm_lang$html$Html$node('source');
var _elm_lang$html$Html$track = _elm_lang$html$Html$node('track');
var _elm_lang$html$Html$canvas = _elm_lang$html$Html$node('canvas');
var _elm_lang$html$Html$math = _elm_lang$html$Html$node('math');
var _elm_lang$html$Html$table = _elm_lang$html$Html$node('table');
var _elm_lang$html$Html$caption = _elm_lang$html$Html$node('caption');
var _elm_lang$html$Html$colgroup = _elm_lang$html$Html$node('colgroup');
var _elm_lang$html$Html$col = _elm_lang$html$Html$node('col');
var _elm_lang$html$Html$tbody = _elm_lang$html$Html$node('tbody');
var _elm_lang$html$Html$thead = _elm_lang$html$Html$node('thead');
var _elm_lang$html$Html$tfoot = _elm_lang$html$Html$node('tfoot');
var _elm_lang$html$Html$tr = _elm_lang$html$Html$node('tr');
var _elm_lang$html$Html$td = _elm_lang$html$Html$node('td');
var _elm_lang$html$Html$th = _elm_lang$html$Html$node('th');
var _elm_lang$html$Html$form = _elm_lang$html$Html$node('form');
var _elm_lang$html$Html$fieldset = _elm_lang$html$Html$node('fieldset');
var _elm_lang$html$Html$legend = _elm_lang$html$Html$node('legend');
var _elm_lang$html$Html$label = _elm_lang$html$Html$node('label');
var _elm_lang$html$Html$input = _elm_lang$html$Html$node('input');
var _elm_lang$html$Html$button = _elm_lang$html$Html$node('button');
var _elm_lang$html$Html$select = _elm_lang$html$Html$node('select');
var _elm_lang$html$Html$datalist = _elm_lang$html$Html$node('datalist');
var _elm_lang$html$Html$optgroup = _elm_lang$html$Html$node('optgroup');
var _elm_lang$html$Html$option = _elm_lang$html$Html$node('option');
var _elm_lang$html$Html$textarea = _elm_lang$html$Html$node('textarea');
var _elm_lang$html$Html$keygen = _elm_lang$html$Html$node('keygen');
var _elm_lang$html$Html$output = _elm_lang$html$Html$node('output');
var _elm_lang$html$Html$progress = _elm_lang$html$Html$node('progress');
var _elm_lang$html$Html$meter = _elm_lang$html$Html$node('meter');
var _elm_lang$html$Html$details = _elm_lang$html$Html$node('details');
var _elm_lang$html$Html$summary = _elm_lang$html$Html$node('summary');
var _elm_lang$html$Html$menuitem = _elm_lang$html$Html$node('menuitem');
var _elm_lang$html$Html$menu = _elm_lang$html$Html$node('menu');

var _elm_lang$html$Html_Attributes$map = _elm_lang$virtual_dom$VirtualDom$mapProperty;
var _elm_lang$html$Html_Attributes$attribute = _elm_lang$virtual_dom$VirtualDom$attribute;
var _elm_lang$html$Html_Attributes$contextmenu = function (value) {
	return A2(_elm_lang$html$Html_Attributes$attribute, 'contextmenu', value);
};
var _elm_lang$html$Html_Attributes$draggable = function (value) {
	return A2(_elm_lang$html$Html_Attributes$attribute, 'draggable', value);
};
var _elm_lang$html$Html_Attributes$itemprop = function (value) {
	return A2(_elm_lang$html$Html_Attributes$attribute, 'itemprop', value);
};
var _elm_lang$html$Html_Attributes$tabindex = function (n) {
	return A2(
		_elm_lang$html$Html_Attributes$attribute,
		'tabIndex',
		_elm_lang$core$Basics$toString(n));
};
var _elm_lang$html$Html_Attributes$charset = function (value) {
	return A2(_elm_lang$html$Html_Attributes$attribute, 'charset', value);
};
var _elm_lang$html$Html_Attributes$height = function (value) {
	return A2(
		_elm_lang$html$Html_Attributes$attribute,
		'height',
		_elm_lang$core$Basics$toString(value));
};
var _elm_lang$html$Html_Attributes$width = function (value) {
	return A2(
		_elm_lang$html$Html_Attributes$attribute,
		'width',
		_elm_lang$core$Basics$toString(value));
};
var _elm_lang$html$Html_Attributes$formaction = function (value) {
	return A2(_elm_lang$html$Html_Attributes$attribute, 'formAction', value);
};
var _elm_lang$html$Html_Attributes$list = function (value) {
	return A2(_elm_lang$html$Html_Attributes$attribute, 'list', value);
};
var _elm_lang$html$Html_Attributes$minlength = function (n) {
	return A2(
		_elm_lang$html$Html_Attributes$attribute,
		'minLength',
		_elm_lang$core$Basics$toString(n));
};
var _elm_lang$html$Html_Attributes$maxlength = function (n) {
	return A2(
		_elm_lang$html$Html_Attributes$attribute,
		'maxlength',
		_elm_lang$core$Basics$toString(n));
};
var _elm_lang$html$Html_Attributes$size = function (n) {
	return A2(
		_elm_lang$html$Html_Attributes$attribute,
		'size',
		_elm_lang$core$Basics$toString(n));
};
var _elm_lang$html$Html_Attributes$form = function (value) {
	return A2(_elm_lang$html$Html_Attributes$attribute, 'form', value);
};
var _elm_lang$html$Html_Attributes$cols = function (n) {
	return A2(
		_elm_lang$html$Html_Attributes$attribute,
		'cols',
		_elm_lang$core$Basics$toString(n));
};
var _elm_lang$html$Html_Attributes$rows = function (n) {
	return A2(
		_elm_lang$html$Html_Attributes$attribute,
		'rows',
		_elm_lang$core$Basics$toString(n));
};
var _elm_lang$html$Html_Attributes$challenge = function (value) {
	return A2(_elm_lang$html$Html_Attributes$attribute, 'challenge', value);
};
var _elm_lang$html$Html_Attributes$media = function (value) {
	return A2(_elm_lang$html$Html_Attributes$attribute, 'media', value);
};
var _elm_lang$html$Html_Attributes$rel = function (value) {
	return A2(_elm_lang$html$Html_Attributes$attribute, 'rel', value);
};
var _elm_lang$html$Html_Attributes$datetime = function (value) {
	return A2(_elm_lang$html$Html_Attributes$attribute, 'datetime', value);
};
var _elm_lang$html$Html_Attributes$pubdate = function (value) {
	return A2(_elm_lang$html$Html_Attributes$attribute, 'pubdate', value);
};
var _elm_lang$html$Html_Attributes$colspan = function (n) {
	return A2(
		_elm_lang$html$Html_Attributes$attribute,
		'colspan',
		_elm_lang$core$Basics$toString(n));
};
var _elm_lang$html$Html_Attributes$rowspan = function (n) {
	return A2(
		_elm_lang$html$Html_Attributes$attribute,
		'rowspan',
		_elm_lang$core$Basics$toString(n));
};
var _elm_lang$html$Html_Attributes$manifest = function (value) {
	return A2(_elm_lang$html$Html_Attributes$attribute, 'manifest', value);
};
var _elm_lang$html$Html_Attributes$property = _elm_lang$virtual_dom$VirtualDom$property;
var _elm_lang$html$Html_Attributes$stringProperty = F2(
	function (name, string) {
		return A2(
			_elm_lang$html$Html_Attributes$property,
			name,
			_elm_lang$core$Json_Encode$string(string));
	});
var _elm_lang$html$Html_Attributes$class = function (name) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'className', name);
};
var _elm_lang$html$Html_Attributes$id = function (name) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'id', name);
};
var _elm_lang$html$Html_Attributes$title = function (name) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'title', name);
};
var _elm_lang$html$Html_Attributes$accesskey = function ($char) {
	return A2(
		_elm_lang$html$Html_Attributes$stringProperty,
		'accessKey',
		_elm_lang$core$String$fromChar($char));
};
var _elm_lang$html$Html_Attributes$dir = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'dir', value);
};
var _elm_lang$html$Html_Attributes$dropzone = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'dropzone', value);
};
var _elm_lang$html$Html_Attributes$lang = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'lang', value);
};
var _elm_lang$html$Html_Attributes$content = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'content', value);
};
var _elm_lang$html$Html_Attributes$httpEquiv = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'httpEquiv', value);
};
var _elm_lang$html$Html_Attributes$language = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'language', value);
};
var _elm_lang$html$Html_Attributes$src = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'src', value);
};
var _elm_lang$html$Html_Attributes$alt = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'alt', value);
};
var _elm_lang$html$Html_Attributes$preload = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'preload', value);
};
var _elm_lang$html$Html_Attributes$poster = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'poster', value);
};
var _elm_lang$html$Html_Attributes$kind = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'kind', value);
};
var _elm_lang$html$Html_Attributes$srclang = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'srclang', value);
};
var _elm_lang$html$Html_Attributes$sandbox = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'sandbox', value);
};
var _elm_lang$html$Html_Attributes$srcdoc = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'srcdoc', value);
};
var _elm_lang$html$Html_Attributes$type_ = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'type', value);
};
var _elm_lang$html$Html_Attributes$value = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'value', value);
};
var _elm_lang$html$Html_Attributes$defaultValue = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'defaultValue', value);
};
var _elm_lang$html$Html_Attributes$placeholder = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'placeholder', value);
};
var _elm_lang$html$Html_Attributes$accept = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'accept', value);
};
var _elm_lang$html$Html_Attributes$acceptCharset = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'acceptCharset', value);
};
var _elm_lang$html$Html_Attributes$action = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'action', value);
};
var _elm_lang$html$Html_Attributes$autocomplete = function (bool) {
	return A2(
		_elm_lang$html$Html_Attributes$stringProperty,
		'autocomplete',
		bool ? 'on' : 'off');
};
var _elm_lang$html$Html_Attributes$enctype = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'enctype', value);
};
var _elm_lang$html$Html_Attributes$method = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'method', value);
};
var _elm_lang$html$Html_Attributes$name = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'name', value);
};
var _elm_lang$html$Html_Attributes$pattern = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'pattern', value);
};
var _elm_lang$html$Html_Attributes$for = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'htmlFor', value);
};
var _elm_lang$html$Html_Attributes$max = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'max', value);
};
var _elm_lang$html$Html_Attributes$min = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'min', value);
};
var _elm_lang$html$Html_Attributes$step = function (n) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'step', n);
};
var _elm_lang$html$Html_Attributes$wrap = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'wrap', value);
};
var _elm_lang$html$Html_Attributes$usemap = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'useMap', value);
};
var _elm_lang$html$Html_Attributes$shape = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'shape', value);
};
var _elm_lang$html$Html_Attributes$coords = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'coords', value);
};
var _elm_lang$html$Html_Attributes$keytype = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'keytype', value);
};
var _elm_lang$html$Html_Attributes$align = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'align', value);
};
var _elm_lang$html$Html_Attributes$cite = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'cite', value);
};
var _elm_lang$html$Html_Attributes$href = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'href', value);
};
var _elm_lang$html$Html_Attributes$target = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'target', value);
};
var _elm_lang$html$Html_Attributes$downloadAs = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'download', value);
};
var _elm_lang$html$Html_Attributes$hreflang = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'hreflang', value);
};
var _elm_lang$html$Html_Attributes$ping = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'ping', value);
};
var _elm_lang$html$Html_Attributes$start = function (n) {
	return A2(
		_elm_lang$html$Html_Attributes$stringProperty,
		'start',
		_elm_lang$core$Basics$toString(n));
};
var _elm_lang$html$Html_Attributes$headers = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'headers', value);
};
var _elm_lang$html$Html_Attributes$scope = function (value) {
	return A2(_elm_lang$html$Html_Attributes$stringProperty, 'scope', value);
};
var _elm_lang$html$Html_Attributes$boolProperty = F2(
	function (name, bool) {
		return A2(
			_elm_lang$html$Html_Attributes$property,
			name,
			_elm_lang$core$Json_Encode$bool(bool));
	});
var _elm_lang$html$Html_Attributes$hidden = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'hidden', bool);
};
var _elm_lang$html$Html_Attributes$contenteditable = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'contentEditable', bool);
};
var _elm_lang$html$Html_Attributes$spellcheck = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'spellcheck', bool);
};
var _elm_lang$html$Html_Attributes$async = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'async', bool);
};
var _elm_lang$html$Html_Attributes$defer = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'defer', bool);
};
var _elm_lang$html$Html_Attributes$scoped = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'scoped', bool);
};
var _elm_lang$html$Html_Attributes$autoplay = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'autoplay', bool);
};
var _elm_lang$html$Html_Attributes$controls = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'controls', bool);
};
var _elm_lang$html$Html_Attributes$loop = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'loop', bool);
};
var _elm_lang$html$Html_Attributes$default = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'default', bool);
};
var _elm_lang$html$Html_Attributes$seamless = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'seamless', bool);
};
var _elm_lang$html$Html_Attributes$checked = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'checked', bool);
};
var _elm_lang$html$Html_Attributes$selected = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'selected', bool);
};
var _elm_lang$html$Html_Attributes$autofocus = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'autofocus', bool);
};
var _elm_lang$html$Html_Attributes$disabled = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'disabled', bool);
};
var _elm_lang$html$Html_Attributes$multiple = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'multiple', bool);
};
var _elm_lang$html$Html_Attributes$novalidate = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'noValidate', bool);
};
var _elm_lang$html$Html_Attributes$readonly = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'readOnly', bool);
};
var _elm_lang$html$Html_Attributes$required = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'required', bool);
};
var _elm_lang$html$Html_Attributes$ismap = function (value) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'isMap', value);
};
var _elm_lang$html$Html_Attributes$download = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'download', bool);
};
var _elm_lang$html$Html_Attributes$reversed = function (bool) {
	return A2(_elm_lang$html$Html_Attributes$boolProperty, 'reversed', bool);
};
var _elm_lang$html$Html_Attributes$classList = function (list) {
	return _elm_lang$html$Html_Attributes$class(
		A2(
			_elm_lang$core$String$join,
			' ',
			A2(
				_elm_lang$core$List$map,
				_elm_lang$core$Tuple$first,
				A2(_elm_lang$core$List$filter, _elm_lang$core$Tuple$second, list))));
};
var _elm_lang$html$Html_Attributes$style = _elm_lang$virtual_dom$VirtualDom$style;

var _elm_lang$html$Html_Events$keyCode = A2(_elm_lang$core$Json_Decode$field, 'keyCode', _elm_lang$core$Json_Decode$int);
var _elm_lang$html$Html_Events$targetChecked = A2(
	_elm_lang$core$Json_Decode$at,
	{
		ctor: '::',
		_0: 'target',
		_1: {
			ctor: '::',
			_0: 'checked',
			_1: {ctor: '[]'}
		}
	},
	_elm_lang$core$Json_Decode$bool);
var _elm_lang$html$Html_Events$targetValue = A2(
	_elm_lang$core$Json_Decode$at,
	{
		ctor: '::',
		_0: 'target',
		_1: {
			ctor: '::',
			_0: 'value',
			_1: {ctor: '[]'}
		}
	},
	_elm_lang$core$Json_Decode$string);
var _elm_lang$html$Html_Events$defaultOptions = _elm_lang$virtual_dom$VirtualDom$defaultOptions;
var _elm_lang$html$Html_Events$onWithOptions = _elm_lang$virtual_dom$VirtualDom$onWithOptions;
var _elm_lang$html$Html_Events$on = _elm_lang$virtual_dom$VirtualDom$on;
var _elm_lang$html$Html_Events$onFocus = function (msg) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'focus',
		_elm_lang$core$Json_Decode$succeed(msg));
};
var _elm_lang$html$Html_Events$onBlur = function (msg) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'blur',
		_elm_lang$core$Json_Decode$succeed(msg));
};
var _elm_lang$html$Html_Events$onSubmitOptions = _elm_lang$core$Native_Utils.update(
	_elm_lang$html$Html_Events$defaultOptions,
	{preventDefault: true});
var _elm_lang$html$Html_Events$onSubmit = function (msg) {
	return A3(
		_elm_lang$html$Html_Events$onWithOptions,
		'submit',
		_elm_lang$html$Html_Events$onSubmitOptions,
		_elm_lang$core$Json_Decode$succeed(msg));
};
var _elm_lang$html$Html_Events$onCheck = function (tagger) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'change',
		A2(_elm_lang$core$Json_Decode$map, tagger, _elm_lang$html$Html_Events$targetChecked));
};
var _elm_lang$html$Html_Events$onInput = function (tagger) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'input',
		A2(_elm_lang$core$Json_Decode$map, tagger, _elm_lang$html$Html_Events$targetValue));
};
var _elm_lang$html$Html_Events$onMouseOut = function (msg) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'mouseout',
		_elm_lang$core$Json_Decode$succeed(msg));
};
var _elm_lang$html$Html_Events$onMouseOver = function (msg) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'mouseover',
		_elm_lang$core$Json_Decode$succeed(msg));
};
var _elm_lang$html$Html_Events$onMouseLeave = function (msg) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'mouseleave',
		_elm_lang$core$Json_Decode$succeed(msg));
};
var _elm_lang$html$Html_Events$onMouseEnter = function (msg) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'mouseenter',
		_elm_lang$core$Json_Decode$succeed(msg));
};
var _elm_lang$html$Html_Events$onMouseUp = function (msg) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'mouseup',
		_elm_lang$core$Json_Decode$succeed(msg));
};
var _elm_lang$html$Html_Events$onMouseDown = function (msg) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'mousedown',
		_elm_lang$core$Json_Decode$succeed(msg));
};
var _elm_lang$html$Html_Events$onDoubleClick = function (msg) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'dblclick',
		_elm_lang$core$Json_Decode$succeed(msg));
};
var _elm_lang$html$Html_Events$onClick = function (msg) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'click',
		_elm_lang$core$Json_Decode$succeed(msg));
};
var _elm_lang$html$Html_Events$Options = F2(
	function (a, b) {
		return {stopPropagation: a, preventDefault: b};
	});

var _elm_lang$mouse$Mouse_ops = _elm_lang$mouse$Mouse_ops || {};
_elm_lang$mouse$Mouse_ops['&>'] = F2(
	function (t1, t2) {
		return A2(
			_elm_lang$core$Task$andThen,
			function (_p0) {
				return t2;
			},
			t1);
	});
var _elm_lang$mouse$Mouse$onSelfMsg = F3(
	function (router, _p1, state) {
		var _p2 = _p1;
		var _p3 = A2(_elm_lang$core$Dict$get, _p2.category, state);
		if (_p3.ctor === 'Nothing') {
			return _elm_lang$core$Task$succeed(state);
		} else {
			var send = function (tagger) {
				return A2(
					_elm_lang$core$Platform$sendToApp,
					router,
					tagger(_p2.position));
			};
			return A2(
				_elm_lang$mouse$Mouse_ops['&>'],
				_elm_lang$core$Task$sequence(
					A2(_elm_lang$core$List$map, send, _p3._0.taggers)),
				_elm_lang$core$Task$succeed(state));
		}
	});
var _elm_lang$mouse$Mouse$init = _elm_lang$core$Task$succeed(_elm_lang$core$Dict$empty);
var _elm_lang$mouse$Mouse$categorizeHelpHelp = F2(
	function (value, maybeValues) {
		var _p4 = maybeValues;
		if (_p4.ctor === 'Nothing') {
			return _elm_lang$core$Maybe$Just(
				{
					ctor: '::',
					_0: value,
					_1: {ctor: '[]'}
				});
		} else {
			return _elm_lang$core$Maybe$Just(
				{ctor: '::', _0: value, _1: _p4._0});
		}
	});
var _elm_lang$mouse$Mouse$categorizeHelp = F2(
	function (subs, subDict) {
		categorizeHelp:
		while (true) {
			var _p5 = subs;
			if (_p5.ctor === '[]') {
				return subDict;
			} else {
				var _v4 = _p5._1,
					_v5 = A3(
					_elm_lang$core$Dict$update,
					_p5._0._0,
					_elm_lang$mouse$Mouse$categorizeHelpHelp(_p5._0._1),
					subDict);
				subs = _v4;
				subDict = _v5;
				continue categorizeHelp;
			}
		}
	});
var _elm_lang$mouse$Mouse$categorize = function (subs) {
	return A2(_elm_lang$mouse$Mouse$categorizeHelp, subs, _elm_lang$core$Dict$empty);
};
var _elm_lang$mouse$Mouse$subscription = _elm_lang$core$Native_Platform.leaf('Mouse');
var _elm_lang$mouse$Mouse$Position = F2(
	function (a, b) {
		return {x: a, y: b};
	});
var _elm_lang$mouse$Mouse$position = A3(
	_elm_lang$core$Json_Decode$map2,
	_elm_lang$mouse$Mouse$Position,
	A2(_elm_lang$core$Json_Decode$field, 'pageX', _elm_lang$core$Json_Decode$int),
	A2(_elm_lang$core$Json_Decode$field, 'pageY', _elm_lang$core$Json_Decode$int));
var _elm_lang$mouse$Mouse$Watcher = F2(
	function (a, b) {
		return {taggers: a, pid: b};
	});
var _elm_lang$mouse$Mouse$Msg = F2(
	function (a, b) {
		return {category: a, position: b};
	});
var _elm_lang$mouse$Mouse$onEffects = F3(
	function (router, newSubs, oldState) {
		var rightStep = F3(
			function (category, taggers, task) {
				var tracker = A3(
					_elm_lang$dom$Dom_LowLevel$onDocument,
					category,
					_elm_lang$mouse$Mouse$position,
					function (_p6) {
						return A2(
							_elm_lang$core$Platform$sendToSelf,
							router,
							A2(_elm_lang$mouse$Mouse$Msg, category, _p6));
					});
				return A2(
					_elm_lang$core$Task$andThen,
					function (state) {
						return A2(
							_elm_lang$core$Task$andThen,
							function (pid) {
								return _elm_lang$core$Task$succeed(
									A3(
										_elm_lang$core$Dict$insert,
										category,
										A2(_elm_lang$mouse$Mouse$Watcher, taggers, pid),
										state));
							},
							_elm_lang$core$Process$spawn(tracker));
					},
					task);
			});
		var bothStep = F4(
			function (category, _p7, taggers, task) {
				var _p8 = _p7;
				return A2(
					_elm_lang$core$Task$andThen,
					function (state) {
						return _elm_lang$core$Task$succeed(
							A3(
								_elm_lang$core$Dict$insert,
								category,
								A2(_elm_lang$mouse$Mouse$Watcher, taggers, _p8.pid),
								state));
					},
					task);
			});
		var leftStep = F3(
			function (category, _p9, task) {
				var _p10 = _p9;
				return A2(
					_elm_lang$mouse$Mouse_ops['&>'],
					_elm_lang$core$Process$kill(_p10.pid),
					task);
			});
		return A6(
			_elm_lang$core$Dict$merge,
			leftStep,
			bothStep,
			rightStep,
			oldState,
			_elm_lang$mouse$Mouse$categorize(newSubs),
			_elm_lang$core$Task$succeed(_elm_lang$core$Dict$empty));
	});
var _elm_lang$mouse$Mouse$MySub = F2(
	function (a, b) {
		return {ctor: 'MySub', _0: a, _1: b};
	});
var _elm_lang$mouse$Mouse$clicks = function (tagger) {
	return _elm_lang$mouse$Mouse$subscription(
		A2(_elm_lang$mouse$Mouse$MySub, 'click', tagger));
};
var _elm_lang$mouse$Mouse$moves = function (tagger) {
	return _elm_lang$mouse$Mouse$subscription(
		A2(_elm_lang$mouse$Mouse$MySub, 'mousemove', tagger));
};
var _elm_lang$mouse$Mouse$downs = function (tagger) {
	return _elm_lang$mouse$Mouse$subscription(
		A2(_elm_lang$mouse$Mouse$MySub, 'mousedown', tagger));
};
var _elm_lang$mouse$Mouse$ups = function (tagger) {
	return _elm_lang$mouse$Mouse$subscription(
		A2(_elm_lang$mouse$Mouse$MySub, 'mouseup', tagger));
};
var _elm_lang$mouse$Mouse$subMap = F2(
	function (func, _p11) {
		var _p12 = _p11;
		return A2(
			_elm_lang$mouse$Mouse$MySub,
			_p12._0,
			function (_p13) {
				return func(
					_p12._1(_p13));
			});
	});
_elm_lang$core$Native_Platform.effectManagers['Mouse'] = {pkg: 'elm-lang/mouse', init: _elm_lang$mouse$Mouse$init, onEffects: _elm_lang$mouse$Mouse$onEffects, onSelfMsg: _elm_lang$mouse$Mouse$onSelfMsg, tag: 'sub', subMap: _elm_lang$mouse$Mouse$subMap};

var _minekoa$elm_text_editor$TextEditor_Buffer$selectionClear = function (model) {
	return _elm_lang$core$Native_Utils.update(
		model,
		{selection: _elm_lang$core$Maybe$Nothing});
};
var _minekoa$elm_text_editor$TextEditor_Buffer$maxRow = function (contents) {
	return _elm_lang$core$List$length(contents) - 1;
};
var _minekoa$elm_text_editor$TextEditor_Buffer$maxColumn = function (line) {
	return _elm_lang$core$String$length(line) - 1;
};
var _minekoa$elm_text_editor$TextEditor_Buffer$line = F2(
	function (n, lines) {
		return (_elm_lang$core$Native_Utils.cmp(n, 0) < 0) ? _elm_lang$core$Maybe$Nothing : _elm_lang$core$List$head(
			A2(_elm_lang$core$List$drop, n, lines));
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$movePrevios = function (model) {
	var cur = model.cursor;
	return function (c) {
		return _elm_lang$core$Native_Utils.update(
			model,
			{cursor: c});
	}(
		A2(
			_elm_lang$core$Maybe$withDefault,
			cur,
			A2(
				_elm_lang$core$Maybe$andThen,
				function (ln) {
					var _p0 = _elm_lang$core$Native_Utils.cmp(
						cur.column,
						_minekoa$elm_text_editor$TextEditor_Buffer$maxColumn(ln) + 1) < 0;
					if (_p0 === true) {
						return _elm_lang$core$Maybe$Just(
							_elm_lang$core$Native_Utils.update(
								cur,
								{row: cur.row - 1}));
					} else {
						return _elm_lang$core$Maybe$Just(
							_elm_lang$core$Native_Utils.update(
								cur,
								{
									row: cur.row - 1,
									column: _minekoa$elm_text_editor$TextEditor_Buffer$maxColumn(ln) + 1
								}));
					}
				},
				A2(_minekoa$elm_text_editor$TextEditor_Buffer$line, cur.row - 1, model.contents))));
};
var _minekoa$elm_text_editor$TextEditor_Buffer$moveNext = function (model) {
	var cur = model.cursor;
	return function (c) {
		return _elm_lang$core$Native_Utils.update(
			model,
			{cursor: c});
	}(
		A2(
			_elm_lang$core$Maybe$withDefault,
			cur,
			A2(
				_elm_lang$core$Maybe$andThen,
				function (ln) {
					var _p1 = _elm_lang$core$Native_Utils.cmp(
						cur.column,
						_minekoa$elm_text_editor$TextEditor_Buffer$maxColumn(ln) + 1) < 0;
					if (_p1 === true) {
						return _elm_lang$core$Maybe$Just(
							_elm_lang$core$Native_Utils.update(
								cur,
								{row: cur.row + 1}));
					} else {
						return _elm_lang$core$Maybe$Just(
							_elm_lang$core$Native_Utils.update(
								cur,
								{
									row: cur.row + 1,
									column: _minekoa$elm_text_editor$TextEditor_Buffer$maxColumn(ln) + 1
								}));
					}
				},
				A2(_minekoa$elm_text_editor$TextEditor_Buffer$line, cur.row + 1, model.contents))));
};
var _minekoa$elm_text_editor$TextEditor_Buffer$isPreviosPos = F2(
	function (p, q) {
		return _elm_lang$core$Native_Utils.eq(
			_elm_lang$core$Tuple$first(p),
			_elm_lang$core$Tuple$first(q)) ? (_elm_lang$core$Native_Utils.cmp(
			_elm_lang$core$Tuple$second(p),
			_elm_lang$core$Tuple$second(q)) < 0) : (_elm_lang$core$Native_Utils.cmp(
			_elm_lang$core$Tuple$first(p),
			_elm_lang$core$Tuple$first(q)) < 0);
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$readRange = F2(
	function (sel, model) {
		var epos = A2(_minekoa$elm_text_editor$TextEditor_Buffer$isPreviosPos, sel.begin, sel.end) ? sel.end : sel.begin;
		var bpos = A2(_minekoa$elm_text_editor$TextEditor_Buffer$isPreviosPos, sel.begin, sel.end) ? sel.begin : sel.end;
		var lcnt = _elm_lang$core$Tuple$first(epos) - _elm_lang$core$Tuple$first(bpos);
		var _p2 = lcnt;
		if (_p2 === 0) {
			var l = A2(
				_elm_lang$core$Maybe$withDefault,
				'',
				A2(
					_minekoa$elm_text_editor$TextEditor_Buffer$line,
					_elm_lang$core$Tuple$first(bpos),
					model.contents));
			return A2(
				_elm_lang$core$String$left,
				_elm_lang$core$Tuple$second(epos) - _elm_lang$core$Tuple$second(bpos),
				A2(
					_elm_lang$core$String$dropLeft,
					_elm_lang$core$Tuple$second(bpos),
					l));
		} else {
			var ls = A2(
				_elm_lang$core$List$take,
				lcnt - 1,
				A2(
					_elm_lang$core$List$drop,
					_elm_lang$core$Tuple$first(bpos) + 1,
					model.contents));
			var el = A2(
				_elm_lang$core$String$left,
				_elm_lang$core$Tuple$second(epos),
				A2(
					_elm_lang$core$Maybe$withDefault,
					'',
					A2(
						_minekoa$elm_text_editor$TextEditor_Buffer$line,
						_elm_lang$core$Tuple$first(epos),
						model.contents)));
			var bl = A2(
				_elm_lang$core$String$dropLeft,
				_elm_lang$core$Tuple$second(bpos),
				A2(
					_elm_lang$core$Maybe$withDefault,
					'',
					A2(
						_minekoa$elm_text_editor$TextEditor_Buffer$line,
						_elm_lang$core$Tuple$first(bpos),
						model.contents)));
			return A2(
				_elm_lang$core$String$join,
				'\n',
				A2(
					_elm_lang$core$Basics_ops['++'],
					{ctor: '::', _0: bl, _1: ls},
					{
						ctor: '::',
						_0: el,
						_1: {ctor: '[]'}
					}));
		}
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$selectedString = function (model) {
	return A2(
		_elm_lang$core$Maybe$andThen,
		function (sel) {
			return _elm_lang$core$Maybe$Just(
				A2(_minekoa$elm_text_editor$TextEditor_Buffer$readRange, sel, model));
		},
		model.selection);
};
var _minekoa$elm_text_editor$TextEditor_Buffer$nowCursorPos = function (model) {
	return {ctor: '_Tuple2', _0: model.cursor.row, _1: model.cursor.column};
};
var _minekoa$elm_text_editor$TextEditor_Buffer$Model = F4(
	function (a, b, c, d) {
		return {cursor: a, selection: b, contents: c, history: d};
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$Cursor = F2(
	function (a, b) {
		return {row: a, column: b};
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$init = function (text) {
	return A4(
		_minekoa$elm_text_editor$TextEditor_Buffer$Model,
		A2(_minekoa$elm_text_editor$TextEditor_Buffer$Cursor, 0, 0),
		_elm_lang$core$Maybe$Nothing,
		_elm_lang$core$String$lines(text),
		{ctor: '[]'});
};
var _minekoa$elm_text_editor$TextEditor_Buffer$defaultCursor = function (contents) {
	var n = _elm_lang$core$List$length(contents);
	return A2(
		_minekoa$elm_text_editor$TextEditor_Buffer$Cursor,
		(_elm_lang$core$Native_Utils.cmp(n, 0) < 0) ? 0 : n,
		0);
};
var _minekoa$elm_text_editor$TextEditor_Buffer$moveForward = function (model) {
	var cur = model.cursor;
	return function (c) {
		return _elm_lang$core$Native_Utils.update(
			model,
			{cursor: c});
	}(
		A2(
			_elm_lang$core$Maybe$withDefault,
			_minekoa$elm_text_editor$TextEditor_Buffer$defaultCursor(model.contents),
			A2(
				_elm_lang$core$Maybe$andThen,
				function (ln) {
					var _p3 = {
						ctor: '_Tuple2',
						_0: _elm_lang$core$Native_Utils.cmp(
							cur.column,
							_minekoa$elm_text_editor$TextEditor_Buffer$maxColumn(ln) + 1) < 0,
						_1: _elm_lang$core$Native_Utils.cmp(
							cur.row,
							_minekoa$elm_text_editor$TextEditor_Buffer$maxRow(model.contents)) < 0
					};
					if (_p3._0 === true) {
						return _elm_lang$core$Maybe$Just(
							_elm_lang$core$Native_Utils.update(
								cur,
								{column: cur.column + 1}));
					} else {
						if (_p3._1 === true) {
							return _elm_lang$core$Maybe$Just(
								_elm_lang$core$Native_Utils.update(
									cur,
									{column: 0, row: cur.row + 1}));
						} else {
							return _elm_lang$core$Maybe$Just(cur);
						}
					}
				},
				A2(_minekoa$elm_text_editor$TextEditor_Buffer$line, cur.row, model.contents))));
};
var _minekoa$elm_text_editor$TextEditor_Buffer$moveBackward = function (model) {
	var cur = model.cursor;
	var pln = A2(
		_elm_lang$core$Maybe$withDefault,
		'',
		A2(_minekoa$elm_text_editor$TextEditor_Buffer$line, cur.row - 1, model.contents));
	return function (c) {
		return _elm_lang$core$Native_Utils.update(
			model,
			{cursor: c});
	}(
		A2(
			_elm_lang$core$Maybe$withDefault,
			_minekoa$elm_text_editor$TextEditor_Buffer$defaultCursor(model.contents),
			A2(
				_elm_lang$core$Maybe$andThen,
				function (ln) {
					var _p4 = {
						ctor: '_Tuple2',
						_0: _elm_lang$core$Native_Utils.cmp(cur.column, 0) > 0,
						_1: _elm_lang$core$Native_Utils.cmp(cur.row, 0) > 0
					};
					if (_p4._0 === true) {
						return _elm_lang$core$Maybe$Just(
							_elm_lang$core$Native_Utils.update(
								cur,
								{column: cur.column - 1}));
					} else {
						if (_p4._1 === true) {
							return _elm_lang$core$Maybe$Just(
								_elm_lang$core$Native_Utils.update(
									cur,
									{
										column: _elm_lang$core$String$length(pln),
										row: cur.row - 1
									}));
						} else {
							return _elm_lang$core$Maybe$Just(cur);
						}
					}
				},
				A2(_minekoa$elm_text_editor$TextEditor_Buffer$line, cur.row, model.contents))));
};
var _minekoa$elm_text_editor$TextEditor_Buffer$moveAt = F2(
	function (_p5, model) {
		var _p6 = _p5;
		return _elm_lang$core$Native_Utils.update(
			model,
			{
				cursor: A2(_minekoa$elm_text_editor$TextEditor_Buffer$Cursor, _p6._0, _p6._1)
			});
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$insert_proc = F3(
	function (_p7, text, model) {
		var _p8 = _p7;
		var _p13 = _p8._0;
		var _p12 = _p8._1;
		var car = function (_p9) {
			return A2(
				_elm_lang$core$Maybe$withDefault,
				'',
				_elm_lang$core$List$head(_p9));
		};
		var texts = _elm_lang$core$String$lines(text);
		var crow = A2(
			_elm_lang$core$Maybe$withDefault,
			'',
			A2(_minekoa$elm_text_editor$TextEditor_Buffer$line, _p13, model.contents));
		var left = A2(_elm_lang$core$String$left, _p12, crow);
		var right = A2(_elm_lang$core$String$dropLeft, _p12, crow);
		var contents = model.contents;
		var prows = A2(_elm_lang$core$List$take, _p13, contents);
		var nrows = A2(_elm_lang$core$List$drop, _p13 + 1, contents);
		var _p10 = _elm_lang$core$List$length(texts);
		switch (_p10) {
			case 0:
				return model;
			case 1:
				return _elm_lang$core$Native_Utils.update(
					model,
					{
						contents: A2(
							_elm_lang$core$Basics_ops['++'],
							prows,
							{
								ctor: '::',
								_0: A2(
									_elm_lang$core$Basics_ops['++'],
									left,
									A2(_elm_lang$core$Basics_ops['++'], text, right)),
								_1: nrows
							}),
						cursor: A2(
							_minekoa$elm_text_editor$TextEditor_Buffer$Cursor,
							_p13,
							_p12 + _elm_lang$core$String$length(text))
					});
			case 2:
				var lst_ln = car(
					A2(_elm_lang$core$List$drop, 1, texts));
				var fst_ln = car(texts);
				return _elm_lang$core$Native_Utils.update(
					model,
					{
						contents: A2(
							_elm_lang$core$Basics_ops['++'],
							prows,
							A2(
								_elm_lang$core$Basics_ops['++'],
								{
									ctor: '::',
									_0: A2(_elm_lang$core$Basics_ops['++'], left, fst_ln),
									_1: {
										ctor: '::',
										_0: A2(_elm_lang$core$Basics_ops['++'], lst_ln, right),
										_1: {ctor: '[]'}
									}
								},
								nrows)),
						cursor: A2(
							_minekoa$elm_text_editor$TextEditor_Buffer$Cursor,
							_p13 + 1,
							_elm_lang$core$String$length(lst_ln))
					});
			default:
				var _p11 = _p10;
				var lst_ln = car(
					A2(_elm_lang$core$List$drop, _p11 - 1, texts));
				var fst_ln = car(texts);
				return _elm_lang$core$Native_Utils.update(
					model,
					{
						contents: A2(
							_elm_lang$core$Basics_ops['++'],
							prows,
							A2(
								_elm_lang$core$Basics_ops['++'],
								{
									ctor: '::',
									_0: A2(_elm_lang$core$Basics_ops['++'], left, fst_ln),
									_1: {ctor: '[]'}
								},
								A2(
									_elm_lang$core$Basics_ops['++'],
									A2(
										_elm_lang$core$List$drop,
										1,
										A2(_elm_lang$core$List$take, _p11 - 1, texts)),
									A2(
										_elm_lang$core$Basics_ops['++'],
										{
											ctor: '::',
											_0: A2(_elm_lang$core$Basics_ops['++'], lst_ln, right),
											_1: {ctor: '[]'}
										},
										nrows)))),
						cursor: A2(
							_minekoa$elm_text_editor$TextEditor_Buffer$Cursor,
							(_p13 + _p11) - 1,
							_elm_lang$core$String$length(lst_ln))
					});
		}
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$undo_backspace_proc = F4(
	function (_p15, _p14, str, model) {
		var _p16 = _p15;
		var _p17 = _p14;
		return A3(
			_minekoa$elm_text_editor$TextEditor_Buffer$insert_proc,
			{ctor: '_Tuple2', _0: _p17._0, _1: _p17._1},
			str,
			model);
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$backspace_proc = F2(
	function (_p18, model) {
		var _p19 = _p18;
		var _p22 = _p19._0;
		var _p21 = _p19._1;
		var _p20 = {ctor: '_Tuple2', _0: _p22, _1: _p21};
		if (_p20._1 === 0) {
			if (_p20._0 === 0) {
				return {ctor: '_Tuple2', _0: model, _1: _elm_lang$core$Maybe$Nothing};
			} else {
				var n_col = _elm_lang$core$String$length(
					A2(
						_elm_lang$core$Maybe$withDefault,
						'',
						_elm_lang$core$List$head(
							A2(_elm_lang$core$List$drop, _p22 - 1, model.contents))));
				var nrows = A2(_elm_lang$core$List$drop, _p22 + 1, model.contents);
				var crow = _elm_lang$core$String$concat(
					A2(
						_elm_lang$core$List$take,
						2,
						A2(_elm_lang$core$List$drop, _p22 - 1, model.contents)));
				var prows = A2(_elm_lang$core$List$take, _p22 - 1, model.contents);
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{
							contents: A2(
								_elm_lang$core$Basics_ops['++'],
								prows,
								{ctor: '::', _0: crow, _1: nrows}),
							cursor: A2(_minekoa$elm_text_editor$TextEditor_Buffer$Cursor, _p22 - 1, n_col)
						}),
					_1: _elm_lang$core$Maybe$Just('\n')
				};
			}
		} else {
			var nrows = A2(_elm_lang$core$List$drop, _p22 + 1, model.contents);
			var crow = A2(
				_elm_lang$core$Maybe$withDefault,
				'',
				A2(_minekoa$elm_text_editor$TextEditor_Buffer$line, _p22, model.contents));
			var left = A2(_elm_lang$core$String$left, _p21 - 1, crow);
			var right = A2(_elm_lang$core$String$dropLeft, _p21, crow);
			var prows = A2(_elm_lang$core$List$take, _p22, model.contents);
			return {
				ctor: '_Tuple2',
				_0: _elm_lang$core$Native_Utils.update(
					model,
					{
						contents: A2(
							_elm_lang$core$Basics_ops['++'],
							prows,
							{
								ctor: '::',
								_0: A2(_elm_lang$core$Basics_ops['++'], left, right),
								_1: nrows
							}),
						cursor: A2(_minekoa$elm_text_editor$TextEditor_Buffer$Cursor, _p22, _p21 - 1)
					}),
				_1: _elm_lang$core$Maybe$Just(
					A2(
						_elm_lang$core$String$left,
						1,
						A2(_elm_lang$core$String$dropLeft, _p21 - 1, crow)))
			};
		}
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$delete_proc = F2(
	function (_p23, model) {
		var _p24 = _p23;
		var _p27 = _p24._0;
		var _p26 = _p24._1;
		var max_row = _minekoa$elm_text_editor$TextEditor_Buffer$maxRow(model.contents);
		var ln = A2(
			_elm_lang$core$Maybe$withDefault,
			'',
			A2(_minekoa$elm_text_editor$TextEditor_Buffer$line, _p27, model.contents));
		var max_col = _minekoa$elm_text_editor$TextEditor_Buffer$maxColumn(ln);
		var _p25 = {
			ctor: '_Tuple2',
			_0: _elm_lang$core$Native_Utils.eq(_p27, max_row),
			_1: _elm_lang$core$Native_Utils.cmp(_p26, max_col) > 0
		};
		if (_p25._1 === false) {
			var current = A2(
				_elm_lang$core$Basics_ops['++'],
				A2(_elm_lang$core$String$left, _p26, ln),
				A2(_elm_lang$core$String$dropLeft, _p26 + 1, ln));
			var nrows = A2(_elm_lang$core$List$drop, _p27 + 1, model.contents);
			var prows = A2(_elm_lang$core$List$take, _p27, model.contents);
			return {
				ctor: '_Tuple2',
				_0: _elm_lang$core$Native_Utils.update(
					model,
					{
						contents: A2(
							_elm_lang$core$Basics_ops['++'],
							prows,
							{ctor: '::', _0: current, _1: nrows}),
						cursor: A2(_minekoa$elm_text_editor$TextEditor_Buffer$Cursor, _p27, _p26)
					}),
				_1: _elm_lang$core$Maybe$Just(
					A2(
						_elm_lang$core$String$left,
						1,
						A2(_elm_lang$core$String$dropLeft, _p26, ln)))
			};
		} else {
			if (_p25._0 === true) {
				return {ctor: '_Tuple2', _0: model, _1: _elm_lang$core$Maybe$Nothing};
			} else {
				var nrows = A2(_elm_lang$core$List$drop, _p27 + 2, model.contents);
				var nxt = A2(
					_elm_lang$core$Maybe$withDefault,
					'',
					A2(_minekoa$elm_text_editor$TextEditor_Buffer$line, _p27 + 1, model.contents));
				var current = A2(_elm_lang$core$Basics_ops['++'], ln, nxt);
				var prows = A2(_elm_lang$core$List$take, _p27, model.contents);
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{
							contents: A2(
								_elm_lang$core$Basics_ops['++'],
								prows,
								{ctor: '::', _0: current, _1: nrows}),
							cursor: A2(_minekoa$elm_text_editor$TextEditor_Buffer$Cursor, _p27, _p26)
						}),
					_1: _elm_lang$core$Maybe$Just('\n')
				};
			}
		}
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$delete_range_proc = F2(
	function (sel, model) {
		var epos = A2(_minekoa$elm_text_editor$TextEditor_Buffer$isPreviosPos, sel.begin, sel.end) ? sel.end : sel.begin;
		var bpos = A2(_minekoa$elm_text_editor$TextEditor_Buffer$isPreviosPos, sel.begin, sel.end) ? sel.begin : sel.end;
		var lcnt = _elm_lang$core$Tuple$first(epos) - _elm_lang$core$Tuple$first(bpos);
		var _p28 = lcnt;
		if (_p28 === 0) {
			var nls = A2(
				_elm_lang$core$List$drop,
				_elm_lang$core$Tuple$first(epos) + 1,
				model.contents);
			var pls = A2(
				_elm_lang$core$List$take,
				_elm_lang$core$Tuple$first(bpos),
				model.contents);
			var ln = A2(
				_elm_lang$core$Maybe$withDefault,
				'',
				A2(
					_minekoa$elm_text_editor$TextEditor_Buffer$line,
					_elm_lang$core$Tuple$first(bpos),
					model.contents));
			var current = A2(
				_elm_lang$core$Basics_ops['++'],
				A2(
					_elm_lang$core$String$left,
					_elm_lang$core$Tuple$second(bpos),
					ln),
				A2(
					_elm_lang$core$String$dropLeft,
					_elm_lang$core$Tuple$second(epos),
					ln));
			return _elm_lang$core$Native_Utils.update(
				model,
				{
					contents: A2(
						_elm_lang$core$Basics_ops['++'],
						pls,
						{ctor: '::', _0: current, _1: nls}),
					cursor: A2(
						_minekoa$elm_text_editor$TextEditor_Buffer$Cursor,
						_elm_lang$core$Tuple$first(bpos),
						_elm_lang$core$Tuple$second(bpos))
				});
		} else {
			var nls = A2(
				_elm_lang$core$List$drop,
				_elm_lang$core$Tuple$first(epos) + 1,
				model.contents);
			var pls = A2(
				_elm_lang$core$List$take,
				_elm_lang$core$Tuple$first(bpos),
				model.contents);
			var eln = A2(
				_elm_lang$core$String$dropLeft,
				_elm_lang$core$Tuple$second(epos),
				A2(
					_elm_lang$core$Maybe$withDefault,
					'',
					A2(
						_minekoa$elm_text_editor$TextEditor_Buffer$line,
						_elm_lang$core$Tuple$first(epos),
						model.contents)));
			var bln = A2(
				_elm_lang$core$String$left,
				_elm_lang$core$Tuple$second(bpos),
				A2(
					_elm_lang$core$Maybe$withDefault,
					'',
					A2(
						_minekoa$elm_text_editor$TextEditor_Buffer$line,
						_elm_lang$core$Tuple$first(bpos),
						model.contents)));
			return _elm_lang$core$Native_Utils.update(
				model,
				{
					contents: A2(
						_elm_lang$core$Basics_ops['++'],
						pls,
						{
							ctor: '::',
							_0: A2(_elm_lang$core$Basics_ops['++'], bln, eln),
							_1: nls
						}),
					cursor: A2(
						_minekoa$elm_text_editor$TextEditor_Buffer$Cursor,
						_elm_lang$core$Tuple$first(bpos),
						_elm_lang$core$Tuple$second(bpos))
				});
		}
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$undo_insert_proc = F4(
	function (_p30, _p29, str, model) {
		var _p31 = _p30;
		var _p32 = _p29;
		var delete_n = F2(
			function (c, m) {
				delete_n:
				while (true) {
					if (_elm_lang$core$Native_Utils.cmp(c, 0) < 1) {
						return m;
					} else {
						var _v17 = c - 1,
							_v18 = _elm_lang$core$Tuple$first(
							A2(
								_minekoa$elm_text_editor$TextEditor_Buffer$backspace_proc,
								{ctor: '_Tuple2', _0: m.cursor.row, _1: m.cursor.column},
								m));
						c = _v17;
						m = _v18;
						continue delete_n;
					}
				}
			});
		return A2(
			delete_n,
			_elm_lang$core$String$length(str),
			_elm_lang$core$Native_Utils.update(
				model,
				{
					cursor: A2(_minekoa$elm_text_editor$TextEditor_Buffer$Cursor, _p32._0, _p32._1)
				}));
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$undo_delete_proc = F4(
	function (_p34, _p33, str, model) {
		var _p35 = _p34;
		var _p38 = _p35._0;
		var _p37 = _p35._1;
		var _p36 = _p33;
		return function (m) {
			return _elm_lang$core$Native_Utils.update(
				m,
				{
					cursor: A2(_minekoa$elm_text_editor$TextEditor_Buffer$Cursor, _p38, _p37)
				});
		}(
			A3(
				_minekoa$elm_text_editor$TextEditor_Buffer$insert_proc,
				{ctor: '_Tuple2', _0: _p38, _1: _p37},
				str,
				model));
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$undo = function (model) {
	var _p39 = _elm_lang$core$List$head(model.history);
	if (_p39.ctor === 'Nothing') {
		return model;
	} else {
		return function (m) {
			return _elm_lang$core$Native_Utils.update(
				m,
				{
					history: A2(_elm_lang$core$List$drop, 1, m.history)
				});
		}(
			function () {
				var _p40 = _p39._0;
				switch (_p40.ctor) {
					case 'Cmd_Insert':
						return A4(_minekoa$elm_text_editor$TextEditor_Buffer$undo_insert_proc, _p40._0, _p40._1, _p40._2, model);
					case 'Cmd_Backspace':
						return A4(_minekoa$elm_text_editor$TextEditor_Buffer$undo_backspace_proc, _p40._0, _p40._1, _p40._2, model);
					default:
						return A4(_minekoa$elm_text_editor$TextEditor_Buffer$undo_delete_proc, _p40._0, _p40._1, _p40._2, model);
				}
			}());
	}
};
var _minekoa$elm_text_editor$TextEditor_Buffer$Range = F2(
	function (a, b) {
		return {begin: a, end: b};
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$markSet = function (model) {
	var pos = _minekoa$elm_text_editor$TextEditor_Buffer$nowCursorPos(model);
	return _elm_lang$core$Native_Utils.update(
		model,
		{
			selection: _elm_lang$core$Maybe$Just(
				A2(_minekoa$elm_text_editor$TextEditor_Buffer$Range, pos, pos))
		});
};
var _minekoa$elm_text_editor$TextEditor_Buffer$selectWithMove = F2(
	function (move_f, model) {
		return function (m) {
			return function (m) {
				return _elm_lang$core$Native_Utils.update(
					m,
					{
						selection: A2(
							_elm_lang$core$Maybe$andThen,
							function (s) {
								return _elm_lang$core$Maybe$Just(
									A2(
										_minekoa$elm_text_editor$TextEditor_Buffer$Range,
										s.begin,
										_minekoa$elm_text_editor$TextEditor_Buffer$nowCursorPos(m)));
							},
							m.selection)
					});
			}(
				move_f(
					_elm_lang$core$Native_Utils.update(
						m,
						{
							selection: _elm_lang$core$Maybe$Just(
								A2(
									_elm_lang$core$Maybe$withDefault,
									A2(
										_minekoa$elm_text_editor$TextEditor_Buffer$Range,
										_minekoa$elm_text_editor$TextEditor_Buffer$nowCursorPos(m),
										_minekoa$elm_text_editor$TextEditor_Buffer$nowCursorPos(m)),
									m.selection))
						})));
		}(model);
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$selectBackward = _minekoa$elm_text_editor$TextEditor_Buffer$selectWithMove(_minekoa$elm_text_editor$TextEditor_Buffer$moveBackward);
var _minekoa$elm_text_editor$TextEditor_Buffer$selectForward = _minekoa$elm_text_editor$TextEditor_Buffer$selectWithMove(_minekoa$elm_text_editor$TextEditor_Buffer$moveForward);
var _minekoa$elm_text_editor$TextEditor_Buffer$selectPrevios = _minekoa$elm_text_editor$TextEditor_Buffer$selectWithMove(_minekoa$elm_text_editor$TextEditor_Buffer$movePrevios);
var _minekoa$elm_text_editor$TextEditor_Buffer$selectNext = _minekoa$elm_text_editor$TextEditor_Buffer$selectWithMove(_minekoa$elm_text_editor$TextEditor_Buffer$moveNext);
var _minekoa$elm_text_editor$TextEditor_Buffer$Cmd_Delete = F3(
	function (a, b, c) {
		return {ctor: 'Cmd_Delete', _0: a, _1: b, _2: c};
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$Cmd_Backspace = F3(
	function (a, b, c) {
		return {ctor: 'Cmd_Backspace', _0: a, _1: b, _2: c};
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$Cmd_Insert = F3(
	function (a, b, c) {
		return {ctor: 'Cmd_Insert', _0: a, _1: b, _2: c};
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$appendHistory = F2(
	function (cmd, model) {
		var col = _elm_lang$core$Tuple$second;
		var row = _elm_lang$core$Tuple$first;
		var _p41 = {
			ctor: '_Tuple2',
			_0: cmd,
			_1: _elm_lang$core$List$head(model.history)
		};
		_v23_3:
		do {
			if (_p41._1.ctor === 'Just') {
				switch (_p41._0.ctor) {
					case 'Cmd_Insert':
						if (_p41._1._0.ctor === 'Cmd_Insert') {
							var _p43 = _p41._1._0._0;
							var _p42 = _p41._0._0;
							return (_elm_lang$core$Native_Utils.eq(
								row(_p42),
								row(_p43)) && _elm_lang$core$Native_Utils.eq(
								col(_p42),
								col(_p41._1._0._1))) ? _elm_lang$core$Native_Utils.update(
								model,
								{
									history: {
										ctor: '::',
										_0: A3(
											_minekoa$elm_text_editor$TextEditor_Buffer$Cmd_Insert,
											_p43,
											_p41._0._1,
											A2(_elm_lang$core$Basics_ops['++'], _p41._1._0._2, _p41._0._2)),
										_1: A2(_elm_lang$core$List$drop, 1, model.history)
									}
								}) : _elm_lang$core$Native_Utils.update(
								model,
								{
									history: {ctor: '::', _0: cmd, _1: model.history}
								});
						} else {
							break _v23_3;
						}
					case 'Cmd_Backspace':
						if (_p41._1._0.ctor === 'Cmd_Backspace') {
							var _p45 = _p41._1._0._0;
							var _p44 = _p41._0._0;
							return (_elm_lang$core$Native_Utils.eq(
								row(_p44),
								row(_p45)) && _elm_lang$core$Native_Utils.eq(
								col(_p44),
								col(_p41._1._0._1))) ? _elm_lang$core$Native_Utils.update(
								model,
								{
									history: {
										ctor: '::',
										_0: A3(
											_minekoa$elm_text_editor$TextEditor_Buffer$Cmd_Backspace,
											_p45,
											_p41._0._1,
											A2(_elm_lang$core$Basics_ops['++'], _p41._0._2, _p41._1._0._2)),
										_1: A2(_elm_lang$core$List$drop, 1, model.history)
									}
								}) : _elm_lang$core$Native_Utils.update(
								model,
								{
									history: {ctor: '::', _0: cmd, _1: model.history}
								});
						} else {
							break _v23_3;
						}
					default:
						if (_p41._1._0.ctor === 'Cmd_Delete') {
							var _p47 = _p41._1._0._0;
							var _p46 = _p41._0._0;
							return (_elm_lang$core$Native_Utils.eq(
								row(_p46),
								row(_p47)) && _elm_lang$core$Native_Utils.eq(
								col(_p46),
								col(_p47))) ? _elm_lang$core$Native_Utils.update(
								model,
								{
									history: {
										ctor: '::',
										_0: A3(
											_minekoa$elm_text_editor$TextEditor_Buffer$Cmd_Delete,
											_p47,
											_p41._0._1,
											A2(_elm_lang$core$Basics_ops['++'], _p41._1._0._2, _p41._0._2)),
										_1: A2(_elm_lang$core$List$drop, 1, model.history)
									}
								}) : _elm_lang$core$Native_Utils.update(
								model,
								{
									history: {ctor: '::', _0: cmd, _1: model.history}
								});
						} else {
							break _v23_3;
						}
				}
			} else {
				break _v23_3;
			}
		} while(false);
		return _elm_lang$core$Native_Utils.update(
			model,
			{
				history: {ctor: '::', _0: cmd, _1: model.history}
			});
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$backspaceAt = F2(
	function (_p48, model) {
		var _p49 = _p48;
		var _p53 = _p49._0;
		var _p52 = _p49._1;
		var _p50 = A2(
			_minekoa$elm_text_editor$TextEditor_Buffer$backspace_proc,
			{ctor: '_Tuple2', _0: _p53, _1: _p52},
			model);
		var m = _p50._0;
		var deleted = _p50._1;
		var _p51 = deleted;
		if (_p51.ctor === 'Nothing') {
			return m;
		} else {
			return function (m) {
				return A2(
					_minekoa$elm_text_editor$TextEditor_Buffer$appendHistory,
					A3(
						_minekoa$elm_text_editor$TextEditor_Buffer$Cmd_Backspace,
						{ctor: '_Tuple2', _0: _p53, _1: _p52},
						_minekoa$elm_text_editor$TextEditor_Buffer$nowCursorPos(m),
						_p51._0),
					m);
			}(m);
		}
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$deleteAt = F2(
	function (_p54, model) {
		var _p55 = _p54;
		var _p59 = _p55._0;
		var _p58 = _p55._1;
		var _p56 = A2(
			_minekoa$elm_text_editor$TextEditor_Buffer$delete_proc,
			{ctor: '_Tuple2', _0: _p59, _1: _p58},
			model);
		var m = _p56._0;
		var deleted = _p56._1;
		var _p57 = deleted;
		if (_p57.ctor === 'Nothing') {
			return m;
		} else {
			return function (m) {
				return A2(
					_minekoa$elm_text_editor$TextEditor_Buffer$appendHistory,
					A3(
						_minekoa$elm_text_editor$TextEditor_Buffer$Cmd_Delete,
						{ctor: '_Tuple2', _0: _p59, _1: _p58},
						_minekoa$elm_text_editor$TextEditor_Buffer$nowCursorPos(m),
						_p57._0),
					m);
			}(m);
		}
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$deleteRange = F2(
	function (range, model) {
		var head_pos = A2(_minekoa$elm_text_editor$TextEditor_Buffer$isPreviosPos, range.begin, range.end) ? range.begin : range.end;
		var deleted = A2(_minekoa$elm_text_editor$TextEditor_Buffer$readRange, range, model);
		var _p60 = deleted;
		if (_p60 === '') {
			return model;
		} else {
			return function (m) {
				return A2(
					_minekoa$elm_text_editor$TextEditor_Buffer$appendHistory,
					A3(
						_minekoa$elm_text_editor$TextEditor_Buffer$Cmd_Delete,
						head_pos,
						_minekoa$elm_text_editor$TextEditor_Buffer$nowCursorPos(m),
						deleted),
					m);
			}(
				A2(_minekoa$elm_text_editor$TextEditor_Buffer$delete_range_proc, range, model));
		}
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$backspace = function (model) {
	var _p61 = model.selection;
	if (_p61.ctor === 'Nothing') {
		return A2(
			_minekoa$elm_text_editor$TextEditor_Buffer$backspaceAt,
			_minekoa$elm_text_editor$TextEditor_Buffer$nowCursorPos(model),
			model);
	} else {
		return _minekoa$elm_text_editor$TextEditor_Buffer$selectionClear(
			A2(_minekoa$elm_text_editor$TextEditor_Buffer$deleteRange, _p61._0, model));
	}
};
var _minekoa$elm_text_editor$TextEditor_Buffer$delete = function (model) {
	var _p62 = model.selection;
	if (_p62.ctor === 'Nothing') {
		return A2(
			_minekoa$elm_text_editor$TextEditor_Buffer$deleteAt,
			_minekoa$elm_text_editor$TextEditor_Buffer$nowCursorPos(model),
			model);
	} else {
		return _minekoa$elm_text_editor$TextEditor_Buffer$selectionClear(
			A2(_minekoa$elm_text_editor$TextEditor_Buffer$deleteRange, _p62._0, model));
	}
};
var _minekoa$elm_text_editor$TextEditor_Buffer$deleteSelection = function (model) {
	var _p63 = model.selection;
	if (_p63.ctor === 'Nothing') {
		return model;
	} else {
		return _minekoa$elm_text_editor$TextEditor_Buffer$selectionClear(
			A2(_minekoa$elm_text_editor$TextEditor_Buffer$deleteRange, _p63._0, model));
	}
};
var _minekoa$elm_text_editor$TextEditor_Buffer$insertAt = F3(
	function (_p64, text, model) {
		var _p65 = _p64;
		var _p67 = _p65._0;
		var _p66 = _p65._1;
		return function (m) {
			return A2(
				_minekoa$elm_text_editor$TextEditor_Buffer$appendHistory,
				A3(
					_minekoa$elm_text_editor$TextEditor_Buffer$Cmd_Insert,
					{ctor: '_Tuple2', _0: _p67, _1: _p66},
					_minekoa$elm_text_editor$TextEditor_Buffer$nowCursorPos(m),
					text),
				m);
		}(
			A3(
				_minekoa$elm_text_editor$TextEditor_Buffer$insert_proc,
				{ctor: '_Tuple2', _0: _p67, _1: _p66},
				text,
				model));
	});
var _minekoa$elm_text_editor$TextEditor_Buffer$insert = F2(
	function (text, model) {
		var _p68 = model.selection;
		if (_p68.ctor === 'Nothing') {
			return A3(
				_minekoa$elm_text_editor$TextEditor_Buffer$insertAt,
				_minekoa$elm_text_editor$TextEditor_Buffer$nowCursorPos(model),
				text,
				model);
		} else {
			return function (m) {
				return A3(
					_minekoa$elm_text_editor$TextEditor_Buffer$insertAt,
					_minekoa$elm_text_editor$TextEditor_Buffer$nowCursorPos(m),
					text,
					m);
			}(
				_minekoa$elm_text_editor$TextEditor_Buffer$selectionClear(
					A2(_minekoa$elm_text_editor$TextEditor_Buffer$deleteRange, _p68._0, model)));
		}
	});

var _minekoa$elm_text_editor$TextEditor_Core$getBoundingClientRect = function (id) {
	return _minekoa$elm_text_editor$Native_Mice.getBoundingClientRect(id);
};
var _minekoa$elm_text_editor$TextEditor_Core$ensureVisibleTask = F2(
	function (frame_id, target_id) {
		return _elm_lang$core$Task$succeed(
			A2(_minekoa$elm_text_editor$Native_Mice.ensureVisible, frame_id, target_id));
	});
var _minekoa$elm_text_editor$TextEditor_Core$elaborateInputAreaTask = function (input_area_id) {
	return _elm_lang$core$Task$succeed(
		_minekoa$elm_text_editor$Native_Mice.elaborateInputArea(input_area_id));
};
var _minekoa$elm_text_editor$TextEditor_Core$inputAreaID = function (model) {
	return A2(_elm_lang$core$Basics_ops['++'], model.id, '-editor-input');
};
var _minekoa$elm_text_editor$TextEditor_Core$cursorID = function (model) {
	return A2(_elm_lang$core$Basics_ops['++'], model.id, '-editor-cursor');
};
var _minekoa$elm_text_editor$TextEditor_Core$prototyleEmID = function (model) {
	return A2(_elm_lang$core$Basics_ops['++'], model.id, '-editor-prototypeEm');
};
var _minekoa$elm_text_editor$TextEditor_Core$rulerID = function (model) {
	return A2(_elm_lang$core$Basics_ops['++'], model.id, '-editor-ruler');
};
var _minekoa$elm_text_editor$TextEditor_Core$lineNumAreaID = function (model) {
	return A2(_elm_lang$core$Basics_ops['++'], model.id, '-editor-lineNumArea');
};
var _minekoa$elm_text_editor$TextEditor_Core$codeAreaID = function (model) {
	return A2(_elm_lang$core$Basics_ops['++'], model.id, '-editor-codeArea');
};
var _minekoa$elm_text_editor$TextEditor_Core$sceneID = function (model) {
	return A2(_elm_lang$core$Basics_ops['++'], model.id, '-editor-scene');
};
var _minekoa$elm_text_editor$TextEditor_Core$frameID = function (model) {
	return A2(_elm_lang$core$Basics_ops['++'], model.id, '-editor-frame');
};
var _minekoa$elm_text_editor$TextEditor_Core$Model = F6(
	function (a, b, c, d, e, f) {
		return {id: a, buffer: b, copyStore: c, compositionPreview: d, focus: e, blink: f};
	});
var _minekoa$elm_text_editor$TextEditor_Core$Rect = F8(
	function (a, b, c, d, e, f, g, h) {
		return {left: a, top: b, right: c, bottom: d, x: e, y: f, width: g, height: h};
	});
var _minekoa$elm_text_editor$TextEditor_Core$Tick = function (a) {
	return {ctor: 'Tick', _0: a};
};
var _minekoa$elm_text_editor$TextEditor_Core$subscriptions = function (model) {
	return _elm_lang$core$Platform_Sub$batch(
		{
			ctor: '::',
			_0: A2(_elm_lang$core$Time$every, 0.5 * _elm_lang$core$Time$second, _minekoa$elm_text_editor$TextEditor_Core$Tick),
			_1: {ctor: '[]'}
		});
};
var _minekoa$elm_text_editor$TextEditor_Core$EnsureVisible = {ctor: 'EnsureVisible'};
var _minekoa$elm_text_editor$TextEditor_Core$withEnsureVisibleCmd = function (model) {
	return {
		ctor: '_Tuple2',
		_0: model,
		_1: A2(
			_elm_lang$core$Task$perform,
			function (_p0) {
				return _minekoa$elm_text_editor$TextEditor_Core$EnsureVisible;
			},
			_elm_lang$core$Task$succeed(true))
	};
};
var _minekoa$elm_text_editor$TextEditor_Core$IgnoreResult = {ctor: 'IgnoreResult'};
var _minekoa$elm_text_editor$TextEditor_Core$doFocus = function (model) {
	return A2(
		_elm_lang$core$Task$attempt,
		function (_p1) {
			return _minekoa$elm_text_editor$TextEditor_Core$IgnoreResult;
		},
		_elm_lang$dom$Dom$focus(
			_minekoa$elm_text_editor$TextEditor_Core$inputAreaID(model)));
};
var _minekoa$elm_text_editor$TextEditor_Core$elaborateInputArea = function (model) {
	return A2(
		_elm_lang$core$Task$perform,
		function (_p2) {
			return _minekoa$elm_text_editor$TextEditor_Core$IgnoreResult;
		},
		_minekoa$elm_text_editor$TextEditor_Core$elaborateInputAreaTask(
			_minekoa$elm_text_editor$TextEditor_Core$inputAreaID(model)));
};
var _minekoa$elm_text_editor$TextEditor_Core$ensureVisible = function (model) {
	return A2(
		_elm_lang$core$Task$perform,
		function (_p3) {
			return _minekoa$elm_text_editor$TextEditor_Core$IgnoreResult;
		},
		A2(
			_minekoa$elm_text_editor$TextEditor_Core$ensureVisibleTask,
			_minekoa$elm_text_editor$TextEditor_Core$frameID(model),
			_minekoa$elm_text_editor$TextEditor_Core$cursorID(model)));
};
var _minekoa$elm_text_editor$TextEditor_Core$BlinkBlocked = {ctor: 'BlinkBlocked'};
var _minekoa$elm_text_editor$TextEditor_Core$init = F2(
	function (id, text) {
		return {
			ctor: '_Tuple2',
			_0: A6(
				_minekoa$elm_text_editor$TextEditor_Core$Model,
				id,
				_minekoa$elm_text_editor$TextEditor_Buffer$init(text),
				'',
				_elm_lang$core$Maybe$Nothing,
				false,
				_minekoa$elm_text_editor$TextEditor_Core$BlinkBlocked),
			_1: _elm_lang$core$Platform_Cmd$none
		};
	});
var _minekoa$elm_text_editor$TextEditor_Core$blinkBlock = function (model) {
	return _elm_lang$core$Native_Utils.update(
		model,
		{blink: _minekoa$elm_text_editor$TextEditor_Core$BlinkBlocked});
};
var _minekoa$elm_text_editor$TextEditor_Core$compositionStart = function (model) {
	return _minekoa$elm_text_editor$TextEditor_Core$blinkBlock(
		_elm_lang$core$Native_Utils.update(
			model,
			{
				buffer: _minekoa$elm_text_editor$TextEditor_Buffer$deleteSelection(model.buffer),
				compositionPreview: _elm_lang$core$Maybe$Just('')
			}));
};
var _minekoa$elm_text_editor$TextEditor_Core$compositionUpdate = F2(
	function (data, model) {
		return _minekoa$elm_text_editor$TextEditor_Core$blinkBlock(
			_elm_lang$core$Native_Utils.update(
				model,
				{
					compositionPreview: _elm_lang$core$Maybe$Just(data)
				}));
	});
var _minekoa$elm_text_editor$TextEditor_Core$compositionEnd = F2(
	function (data, model) {
		return _minekoa$elm_text_editor$TextEditor_Core$withEnsureVisibleCmd(
			_minekoa$elm_text_editor$TextEditor_Core$blinkBlock(
				_elm_lang$core$Native_Utils.update(
					model,
					{
						buffer: A2(_minekoa$elm_text_editor$TextEditor_Buffer$insert, data, model.buffer),
						compositionPreview: _elm_lang$core$Maybe$Nothing
					})));
	});
var _minekoa$elm_text_editor$TextEditor_Core$Blink = function (a) {
	return {ctor: 'Blink', _0: a};
};
var _minekoa$elm_text_editor$TextEditor_Core$blinkTransition = function (blnk) {
	var _p4 = blnk;
	if (_p4.ctor === 'BlinkBlocked') {
		return _minekoa$elm_text_editor$TextEditor_Core$Blink(true);
	} else {
		if (_p4._0 === true) {
			return _minekoa$elm_text_editor$TextEditor_Core$Blink(false);
		} else {
			return _minekoa$elm_text_editor$TextEditor_Core$Blink(true);
		}
	}
};
var _minekoa$elm_text_editor$TextEditor_Core$update = F2(
	function (msg, model) {
		var _p5 = msg;
		switch (_p5.ctor) {
			case 'IgnoreResult':
				return {ctor: '_Tuple2', _0: model, _1: _elm_lang$core$Platform_Cmd$none};
			case 'EnsureVisible':
				return {
					ctor: '_Tuple2',
					_0: model,
					_1: _minekoa$elm_text_editor$TextEditor_Core$ensureVisible(model)
				};
			default:
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{
							blink: _minekoa$elm_text_editor$TextEditor_Core$blinkTransition(model.blink)
						}),
					_1: _elm_lang$core$Platform_Cmd$none
				};
		}
	});

var _minekoa$elm_text_editor$TextEditor_Core_Commands$paste = F2(
	function (text, model) {
		return _minekoa$elm_text_editor$TextEditor_Core$withEnsureVisibleCmd(
			_minekoa$elm_text_editor$TextEditor_Core$blinkBlock(
				_elm_lang$core$Native_Utils.update(
					model,
					{
						buffer: _minekoa$elm_text_editor$TextEditor_Buffer$selectionClear(
							A2(_minekoa$elm_text_editor$TextEditor_Buffer$insert, text, model.buffer)),
						copyStore: text
					})));
	});
var _minekoa$elm_text_editor$TextEditor_Core_Commands$cut = function (model) {
	return _minekoa$elm_text_editor$TextEditor_Core$withEnsureVisibleCmd(
		_minekoa$elm_text_editor$TextEditor_Core$blinkBlock(
			function () {
				var _p0 = model.buffer.selection;
				if (_p0.ctor === 'Nothing') {
					return model;
				} else {
					var _p1 = _p0._0;
					return _elm_lang$core$Native_Utils.update(
						model,
						{
							copyStore: A2(_minekoa$elm_text_editor$TextEditor_Buffer$readRange, _p1, model.buffer),
							buffer: _minekoa$elm_text_editor$TextEditor_Buffer$selectionClear(
								A2(_minekoa$elm_text_editor$TextEditor_Buffer$deleteRange, _p1, model.buffer))
						});
				}
			}()));
};
var _minekoa$elm_text_editor$TextEditor_Core_Commands$copy = function (model) {
	return function (m) {
		return {ctor: '_Tuple2', _0: m, _1: _elm_lang$core$Platform_Cmd$none};
	}(
		_minekoa$elm_text_editor$TextEditor_Core$blinkBlock(
			function () {
				var _p2 = model.buffer.selection;
				if (_p2.ctor === 'Nothing') {
					return model;
				} else {
					return _elm_lang$core$Native_Utils.update(
						model,
						{
							copyStore: A2(_minekoa$elm_text_editor$TextEditor_Buffer$readRange, _p2._0, model.buffer),
							buffer: _minekoa$elm_text_editor$TextEditor_Buffer$selectionClear(model.buffer)
						});
				}
			}()));
};
var _minekoa$elm_text_editor$TextEditor_Core_Commands$undo = function (model) {
	return _minekoa$elm_text_editor$TextEditor_Core$withEnsureVisibleCmd(
		_minekoa$elm_text_editor$TextEditor_Core$blinkBlock(
			_elm_lang$core$Native_Utils.update(
				model,
				{
					buffer: function (_p3) {
						return _minekoa$elm_text_editor$TextEditor_Buffer$selectionClear(
							_minekoa$elm_text_editor$TextEditor_Buffer$undo(_p3));
					}(model.buffer)
				})));
};
var _minekoa$elm_text_editor$TextEditor_Core_Commands$editF = F2(
	function (f, model) {
		return _minekoa$elm_text_editor$TextEditor_Core$withEnsureVisibleCmd(
			_minekoa$elm_text_editor$TextEditor_Core$blinkBlock(
				_elm_lang$core$Native_Utils.update(
					model,
					{
						buffer: f(model.buffer)
					})));
	});
var _minekoa$elm_text_editor$TextEditor_Core_Commands$insert = function (text) {
	return _minekoa$elm_text_editor$TextEditor_Core_Commands$editF(
		_minekoa$elm_text_editor$TextEditor_Buffer$insert(text));
};
var _minekoa$elm_text_editor$TextEditor_Core_Commands$backspace = _minekoa$elm_text_editor$TextEditor_Core_Commands$editF(_minekoa$elm_text_editor$TextEditor_Buffer$backspace);
var _minekoa$elm_text_editor$TextEditor_Core_Commands$delete = _minekoa$elm_text_editor$TextEditor_Core_Commands$editF(_minekoa$elm_text_editor$TextEditor_Buffer$delete);
var _minekoa$elm_text_editor$TextEditor_Core_Commands$selectF = F2(
	function (f, model) {
		return _minekoa$elm_text_editor$TextEditor_Core$withEnsureVisibleCmd(
			_minekoa$elm_text_editor$TextEditor_Core$blinkBlock(
				_elm_lang$core$Native_Utils.update(
					model,
					{
						buffer: f(model.buffer)
					})));
	});
var _minekoa$elm_text_editor$TextEditor_Core_Commands$selectBackward = _minekoa$elm_text_editor$TextEditor_Core_Commands$selectF(_minekoa$elm_text_editor$TextEditor_Buffer$selectBackward);
var _minekoa$elm_text_editor$TextEditor_Core_Commands$selectForward = _minekoa$elm_text_editor$TextEditor_Core_Commands$selectF(_minekoa$elm_text_editor$TextEditor_Buffer$selectForward);
var _minekoa$elm_text_editor$TextEditor_Core_Commands$selectPrevios = _minekoa$elm_text_editor$TextEditor_Core_Commands$selectF(_minekoa$elm_text_editor$TextEditor_Buffer$selectPrevios);
var _minekoa$elm_text_editor$TextEditor_Core_Commands$selectNext = _minekoa$elm_text_editor$TextEditor_Core_Commands$selectF(_minekoa$elm_text_editor$TextEditor_Buffer$selectNext);
var _minekoa$elm_text_editor$TextEditor_Core_Commands$moveF = F2(
	function (f, model) {
		return _minekoa$elm_text_editor$TextEditor_Core$withEnsureVisibleCmd(
			_minekoa$elm_text_editor$TextEditor_Core$blinkBlock(
				_elm_lang$core$Native_Utils.update(
					model,
					{
						buffer: function (_p4) {
							return _minekoa$elm_text_editor$TextEditor_Buffer$selectionClear(
								f(_p4));
						}(model.buffer)
					})));
	});
var _minekoa$elm_text_editor$TextEditor_Core_Commands$moveForward = _minekoa$elm_text_editor$TextEditor_Core_Commands$moveF(_minekoa$elm_text_editor$TextEditor_Buffer$moveForward);
var _minekoa$elm_text_editor$TextEditor_Core_Commands$moveBackward = _minekoa$elm_text_editor$TextEditor_Core_Commands$moveF(_minekoa$elm_text_editor$TextEditor_Buffer$moveBackward);
var _minekoa$elm_text_editor$TextEditor_Core_Commands$movePrevios = _minekoa$elm_text_editor$TextEditor_Core_Commands$moveF(_minekoa$elm_text_editor$TextEditor_Buffer$movePrevios);
var _minekoa$elm_text_editor$TextEditor_Core_Commands$moveNext = _minekoa$elm_text_editor$TextEditor_Core_Commands$moveF(_minekoa$elm_text_editor$TextEditor_Buffer$moveNext);
var _minekoa$elm_text_editor$TextEditor_Core_Commands$moveBOL = _minekoa$elm_text_editor$TextEditor_Core_Commands$moveF(
	function (m) {
		return _elm_lang$core$Native_Utils.update(
			m,
			{
				cursor: A2(_minekoa$elm_text_editor$TextEditor_Buffer$Cursor, m.cursor.row, 0)
			});
	});
var _minekoa$elm_text_editor$TextEditor_Core_Commands$moveEOL = _minekoa$elm_text_editor$TextEditor_Core_Commands$moveF(
	function (m) {
		return _elm_lang$core$Native_Utils.update(
			m,
			{
				cursor: A2(
					_minekoa$elm_text_editor$TextEditor_Buffer$Cursor,
					m.cursor.row,
					_elm_lang$core$String$length(
						A2(
							_elm_lang$core$Maybe$withDefault,
							'',
							A2(_minekoa$elm_text_editor$TextEditor_Buffer$line, m.cursor.row, m.contents))))
			});
	});
var _minekoa$elm_text_editor$TextEditor_Core_Commands$moveAt = function (pos) {
	return _minekoa$elm_text_editor$TextEditor_Core_Commands$moveF(
		_minekoa$elm_text_editor$TextEditor_Buffer$moveAt(pos));
};

var _minekoa$elm_text_editor$TextEditor_KeyBind$emacsLike = {
	ctor: '::',
	_0: {ctrl: true, alt: false, shift: false, code: 70, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$moveForward},
	_1: {
		ctor: '::',
		_0: {ctrl: true, alt: false, shift: false, code: 66, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$moveBackward},
		_1: {
			ctor: '::',
			_0: {ctrl: true, alt: false, shift: false, code: 78, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$moveNext},
			_1: {
				ctor: '::',
				_0: {ctrl: true, alt: false, shift: false, code: 80, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$movePrevios},
				_1: {
					ctor: '::',
					_0: {ctrl: true, alt: false, shift: false, code: 65, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$moveBOL},
					_1: {
						ctor: '::',
						_0: {ctrl: true, alt: false, shift: false, code: 69, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$moveEOL},
						_1: {
							ctor: '::',
							_0: {ctrl: true, alt: false, shift: false, code: 72, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$backspace},
							_1: {
								ctor: '::',
								_0: {ctrl: true, alt: false, shift: false, code: 68, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$delete},
								_1: {
									ctor: '::',
									_0: {ctrl: false, alt: true, shift: false, code: 87, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$copy},
									_1: {
										ctor: '::',
										_0: {ctrl: true, alt: false, shift: false, code: 87, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$cut},
										_1: {
											ctor: '::',
											_0: {
												ctrl: true,
												alt: false,
												shift: false,
												code: 77,
												f: _minekoa$elm_text_editor$TextEditor_Core_Commands$insert('\n')
											},
											_1: {
												ctor: '::',
												_0: {
													ctrl: true,
													alt: false,
													shift: false,
													code: 89,
													f: function (m) {
														return A2(_minekoa$elm_text_editor$TextEditor_Core_Commands$paste, m.copyStore, m);
													}
												},
												_1: {ctor: '[]'}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
};
var _minekoa$elm_text_editor$TextEditor_KeyBind$gates = {
	ctor: '::',
	_0: {ctrl: false, alt: false, shift: true, code: 37, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$selectBackward},
	_1: {
		ctor: '::',
		_0: {ctrl: false, alt: false, shift: true, code: 38, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$selectPrevios},
		_1: {
			ctor: '::',
			_0: {ctrl: false, alt: false, shift: true, code: 39, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$selectForward},
			_1: {
				ctor: '::',
				_0: {ctrl: false, alt: false, shift: true, code: 40, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$selectNext},
				_1: {
					ctor: '::',
					_0: {ctrl: true, alt: false, shift: false, code: 90, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$undo},
					_1: {ctor: '[]'}
				}
			}
		}
	}
};
var _minekoa$elm_text_editor$TextEditor_KeyBind$basic = {
	ctor: '::',
	_0: {ctrl: false, alt: false, shift: false, code: 37, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$moveBackward},
	_1: {
		ctor: '::',
		_0: {ctrl: false, alt: false, shift: false, code: 38, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$movePrevios},
		_1: {
			ctor: '::',
			_0: {ctrl: false, alt: false, shift: false, code: 39, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$moveForward},
			_1: {
				ctor: '::',
				_0: {ctrl: false, alt: false, shift: false, code: 40, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$moveNext},
				_1: {
					ctor: '::',
					_0: {ctrl: false, alt: false, shift: false, code: 36, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$moveBOL},
					_1: {
						ctor: '::',
						_0: {ctrl: false, alt: false, shift: false, code: 35, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$moveEOL},
						_1: {
							ctor: '::',
							_0: {ctrl: false, alt: false, shift: false, code: 8, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$backspace},
							_1: {
								ctor: '::',
								_0: {ctrl: false, alt: false, shift: false, code: 46, f: _minekoa$elm_text_editor$TextEditor_Core_Commands$delete},
								_1: {ctor: '[]'}
							}
						}
					}
				}
			}
		}
	}
};
var _minekoa$elm_text_editor$TextEditor_KeyBind$find = F2(
	function (_p0, keymap) {
		find:
		while (true) {
			var _p1 = _p0;
			var _p7 = _p1._2;
			var _p6 = _p1._3;
			var _p5 = _p1._0;
			var _p4 = _p1._1;
			var _p2 = keymap;
			if (_p2.ctor === '[]') {
				return _elm_lang$core$Maybe$Nothing;
			} else {
				var _p3 = _p2._0;
				if (_elm_lang$core$Native_Utils.eq(_p6, _p3.code) && (_elm_lang$core$Native_Utils.eq(_p5, _p3.ctrl) && (_elm_lang$core$Native_Utils.eq(_p4, _p3.alt) && _elm_lang$core$Native_Utils.eq(_p7, _p3.shift)))) {
					return _elm_lang$core$Maybe$Just(_p3.f);
				} else {
					var _v2 = {ctor: '_Tuple4', _0: _p5, _1: _p4, _2: _p7, _3: _p6},
						_v3 = _p2._1;
					_p0 = _v2;
					keymap = _v3;
					continue find;
				}
			}
		}
	});
var _minekoa$elm_text_editor$TextEditor_KeyBind$KeyBind = F5(
	function (a, b, c, d, e) {
		return {ctrl: a, alt: b, shift: c, code: d, f: e};
	});


var _minekoa$elm_text_editor$Native_Mice = function() {

    function ensureVisible( frame_id, target_id ) {
        /*
         * TODO:
         *    * marginでごまかしているが、行番号カラムを考慮したスクロールをしないと、左移動しても行番号が出きらない問題がある
         */

        requestAnimationFrame( () => {
            /* note:
             *     requestAnimationFrame は、描画更新をまつため .. だったのだけれど
             *     効いたり効かなかったりする
             *         * 複数行のペーストのときには、これがないと正しくカーソルが見えない
             *         * フレーム外にカーソルがいる時の、タップでのカーソル移動だと、何故か上手く行かない
             *     (?? カーソルの点滅制御が悪さしてる ??)
             */

            const frame  = document.getElementById(frame_id);
            const target = document.getElementById(target_id);
            if (frame == null || target == null) {
                return false;
            }

            const frame_rect  =  frame.getBoundingClientRect();
            const target_rect =  target.getBoundingClientRect()
            const margin = target_rect.height * 2.1;

            /* dbg */
            console.log( "B: frm: top=" + frame_rect.top.toString()  + " left=" + frame_rect.left.toString()  + " bottom=" + frame_rect.bottom.toString()  + " right=" + frame_rect.right.toString()  );
            console.log( "B: tgt: top=" + target_rect.top.toString() + " left=" + target_rect.left.toString() + " bottom=" + target_rect.bottom.toString() + " right=" + target_rect.right.toString() );

            /* vertincal */
            var new_scr_top = null;
            if      ( target_rect.top    - margin < frame_rect.top    ) {
                new_scr_top = frame.scrollTop + (target_rect.top - frame_rect.top) - margin;
            }
            else if ( target_rect.bottom + margin > frame_rect.bottom ) {
                new_scr_top = frame.scrollTop + (target_rect.bottom - frame_rect.bottom) + margin;
            }

            /* horizontal */
            var new_scr_left = null;
            if      ( target_rect.left  - margin < frame_rect.left ) {
                new_scr_left = frame.scrollLeft + (target_rect.left - frame_rect.left) - margin;
            }
            else if ( target_rect.right + margin > frame_rect.right ) {
                new_scr_left = frame.scrollLeft + (target_rect.right - frame_rect.right) + margin;
            }

            /* set scroll pos */
            if (new_scr_top  != null) {
                frame.scrollTop  = new_scr_top;
            }
            if (new_scr_left != null) {
                frame.scrollLeft = new_scr_left;
            }

            return (new_scr_top != null) || (new_scr_left != null);
        } );

        return true;
    }


    function calcTextWidth(_id, txt) {
        const element = document.getElementById(_id); 
        if (element == null) {
            return 0;
        }
        element.textContent = txt;
        const w = element.offsetWidth;
        element.textContent = null;

        return w;
    }

    function getBoundingClientRect(_id) {
        const element = document.getElementById(_id); 
        if (element == null) {
            return {"left":0, "top":0, "right":0, "bottom":0, "x":0, "y":0, "width":0, "height":0};
        }
        const rect = element.getBoundingClientRect();
        return rect;
    }

    function elaborateInputArea(id_input_area) {
        const input_area = document.getElementById(id_input_area);
        if (input_area == null) {
            return false;
        }

        if (input_area.input_controll_handlers_registerd) {
            return true;
        }
        input_area.input_controll_handlers_registerd = true;
        console.log("regist inpt-ctrl event handlers");


        input_area.addEventListener( "keydown", e => {
            if (e.target.id != id_input_area) {
                return true;
            }


            if (e.ctrlKey && (e.keyCode == 86 || e.keyCode == 67 || e.keyCode == 88)) { /* C-v : pasteイベントは生かしておきたい */
                ;
            }
            else if (e.altKey || e.ctrlKey) {
                e.preventDefault();
            }
            switch (e.keyCode) {
            case 37: /* '←' .. スクロールが発生してしまうことがある */
            case 38: /* '↑' */
            case 39: /* '→' */
            case 40: /* '↓' */ 
                e.preventDefault();
                break;
            }
        });

        /* IMEを考慮した input_area のクリア制御
         *      - input
         *      - compositionstart
         *      - compositionend
         *      - keypress
         * note:
         *   一見 Elm 世界でやれそうに見えるが、
         *   TEA は、1周の処理が終えるまでの間、 以降のJSイベントを待たせてくれるわけではないので、
         *   結果、イベントが非同期となってしまい、状態遷移が上手く行かない。
         *   よって、JS 世界で行う必要がある
         */

        input_area.addEventListener( "input", e => {
            if (!input_area.enableComposer) {
                input_area.value = "";
            }
        });

        input_area.addEventListener( "compositionstart", e => {
            input_area.enableComposer = true;
        });

        input_area.addEventListener( "compositionend", e => {
            input_area.value = "";
        });

        input_area.addEventListener( "keypress", e => {

            /* IME入力中にkeypress イベントがこないことを利用して IME入力モード(inputを反映するか否かのフラグ）を解除
             *  ※ compositonEnd で解除してしまうと、firefoxとchromeの振る舞いの違いでハマる
             *        chrome  :: keydown 229 -> compositionend s
             *        firefox ::   (null)    -> compositionend s -> input s
             */

            input_area.enableComposer = false;
        });


        /* クリップボード制御
         *      - paste
         *      - copy
         *      - cut
         * note:
         *   クリップボードイベントはセキュリティのため、
         *   イベントハンドラ内でないと、クリップボードに対する操作ができない
         *   (Firefox は厳しくブロックしてくる為、paste を execCommand でTEAから叩く手段もダメ)
         */

        input_area.addEventListener( "paste", e => {
            e.preventDefault();

            const data_transfer = (e.clipboardData) || (window.clipboardData);
            const str = data_transfer.getData("text/plain");

            const evt = new CustomEvent("pasted", { "bubbles": true,
                                                    "cancelable": true,
                                                    "detail": str
                                                  }
                                       );
            input_area.dispatchEvent(evt);
        });

        input_area.addEventListener( "copy", e => {
            e.preventDefault();

            const str = input_area.selecteddata
            e.clipboardData.setData('text/plain', str);

            const evt = new CustomEvent("copied", { "bubbles": true,
                                                    "cancelable": true,
                                                    "detail": str
                                                  }
                                       );
            input_area.dispatchEvent(evt);
        });

        input_area.addEventListener( "cut", e => {
            e.preventDefault();

            const str = input_area.selecteddata
            e.clipboardData.setData('text/plain', str);

            const evt = new CustomEvent("cutted", { "bubbles": true,
                                                    "cancelable": true,
                                                    "detail": str
                                                  }
                                       );
            input_area.dispatchEvent(evt);
        });


        return true;
    }


  return {
      ensureVisible: F2(ensureVisible),
      calcTextWidth: F2(calcTextWidth),
      getBoundingClientRect: getBoundingClientRect,
      elaborateInputArea : elaborateInputArea,
  }
}();


var _minekoa$elm_text_editor$TextEditor$getBoundingClientRect = function (id) {
	return _minekoa$elm_text_editor$Native_Mice.getBoundingClientRect(id);
};
var _minekoa$elm_text_editor$TextEditor$calcTextWidth = F2(
	function (id, txt) {
		return A2(_minekoa$elm_text_editor$Native_Mice.calcTextWidth, id, txt);
	});
var _minekoa$elm_text_editor$TextEditor$toEmString = function (_p0) {
	return A3(
		_elm_lang$core$Basics$flip,
		F2(
			function (x, y) {
				return A2(_elm_lang$core$Basics_ops['++'], x, y);
			}),
		'em',
		_elm_lang$core$Basics$toString(_p0));
};
var _minekoa$elm_text_editor$TextEditor$toPxString = function (_p1) {
	return A3(
		_elm_lang$core$Basics$flip,
		F2(
			function (x, y) {
				return A2(_elm_lang$core$Basics_ops['++'], x, y);
			}),
		'px',
		_elm_lang$core$Basics$toString(_p1));
};
var _minekoa$elm_text_editor$TextEditor$emToPx = F2(
	function (model, n) {
		return A3(
			_elm_lang$core$Basics$flip,
			F2(
				function (x, y) {
					return x * y;
				}),
			n,
			function (_) {
				return _.height;
			}(
				_minekoa$elm_text_editor$TextEditor$getBoundingClientRect(
					_minekoa$elm_text_editor$TextEditor_Core$prototyleEmID(model))));
	});
var _minekoa$elm_text_editor$TextEditor$emToPxString = function (model) {
	return function (_p2) {
		return _minekoa$elm_text_editor$TextEditor$toPxString(
			A2(_minekoa$elm_text_editor$TextEditor$emToPx, model, _p2));
	};
};
var _minekoa$elm_text_editor$TextEditor$selecteddata = function (selected_str) {
	return A2(
		_elm_lang$html$Html_Attributes$property,
		'selecteddata',
		_elm_lang$core$Json_Encode$string(
			A2(_elm_lang$core$Maybe$withDefault, '', selected_str)));
};
var _minekoa$elm_text_editor$TextEditor$onCutted = function (tagger) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'cutted',
		A2(
			_elm_lang$core$Json_Decode$map,
			tagger,
			A2(_elm_lang$core$Json_Decode$field, 'detail', _elm_lang$core$Json_Decode$string)));
};
var _minekoa$elm_text_editor$TextEditor$onCopied = function (tagger) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'copied',
		A2(
			_elm_lang$core$Json_Decode$map,
			tagger,
			A2(_elm_lang$core$Json_Decode$field, 'detail', _elm_lang$core$Json_Decode$string)));
};
var _minekoa$elm_text_editor$TextEditor$onPasted = function (tagger) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'pasted',
		A2(
			_elm_lang$core$Json_Decode$map,
			tagger,
			A2(_elm_lang$core$Json_Decode$field, 'detail', _elm_lang$core$Json_Decode$string)));
};
var _minekoa$elm_text_editor$TextEditor$onMouseDown = function (tagger) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'mousedown',
		A2(_elm_lang$core$Json_Decode$map, tagger, _elm_lang$mouse$Mouse$position));
};
var _minekoa$elm_text_editor$TextEditor$onFocusOut = function (tagger) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'focusout',
		A2(
			_elm_lang$core$Json_Decode$map,
			tagger,
			A2(_elm_lang$core$Json_Decode$field, 'bubbles', _elm_lang$core$Json_Decode$bool)));
};
var _minekoa$elm_text_editor$TextEditor$onFocusIn = function (tagger) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'focusin',
		A2(
			_elm_lang$core$Json_Decode$map,
			tagger,
			A2(_elm_lang$core$Json_Decode$field, 'bubbles', _elm_lang$core$Json_Decode$bool)));
};
var _minekoa$elm_text_editor$TextEditor$onCompositionUpdate = function (tagger) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'compositionupdate',
		A2(
			_elm_lang$core$Json_Decode$map,
			tagger,
			A2(_elm_lang$core$Json_Decode$field, 'data', _elm_lang$core$Json_Decode$string)));
};
var _minekoa$elm_text_editor$TextEditor$onCompositionEnd = function (tagger) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'compositionend',
		A2(
			_elm_lang$core$Json_Decode$map,
			tagger,
			A2(_elm_lang$core$Json_Decode$field, 'data', _elm_lang$core$Json_Decode$string)));
};
var _minekoa$elm_text_editor$TextEditor$onCompositionStart = function (tagger) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'compositionstart',
		A2(
			_elm_lang$core$Json_Decode$map,
			tagger,
			A2(_elm_lang$core$Json_Decode$field, 'data', _elm_lang$core$Json_Decode$string)));
};
var _minekoa$elm_text_editor$TextEditor$onKeyUp = function (tagger) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'keyup',
		A2(_elm_lang$core$Json_Decode$map, tagger, _elm_lang$html$Html_Events$keyCode));
};
var _minekoa$elm_text_editor$TextEditor$onKeyPress = function (tagger) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'keypress',
		A2(_elm_lang$core$Json_Decode$map, tagger, _elm_lang$html$Html_Events$keyCode));
};
var _minekoa$elm_text_editor$TextEditor$keyboarEvent_toString = function (e) {
	return _elm_lang$core$String$concat(
		{
			ctor: '::',
			_0: e.ctrlKey ? 'C-' : '',
			_1: {
				ctor: '::',
				_0: e.altKey ? 'A-' : '',
				_1: {
					ctor: '::',
					_0: e.metaKey ? 'M-' : '',
					_1: {
						ctor: '::',
						_0: e.shiftKey ? 'S-' : '',
						_1: {
							ctor: '::',
							_0: _elm_lang$core$Basics$toString(e.keyCode),
							_1: {ctor: '[]'}
						}
					}
				}
			}
		});
};
var _minekoa$elm_text_editor$TextEditor$cursorView = function (model) {
	var blink_off = function (_p3) {
		return !function (blnk) {
			var _p4 = blnk;
			if (_p4.ctor === 'Blink') {
				return _p4._0;
			} else {
				return true;
			}
		}(_p3);
	};
	return A2(
		_elm_lang$html$Html$span,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$style(
				{
					ctor: '::',
					_0: {
						ctor: '_Tuple2',
						_0: 'background-color',
						_1: model.focus ? 'blue' : 'gray'
					},
					_1: {
						ctor: '::',
						_0: {
							ctor: '_Tuple2',
							_0: 'opacity',
							_1: (model.focus && blink_off(model.blink)) ? '0.0' : '0.5'
						},
						_1: {
							ctor: '::',
							_0: {
								ctor: '_Tuple2',
								_0: 'height',
								_1: A2(_minekoa$elm_text_editor$TextEditor$emToPxString, model, 1)
							},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'width', _1: '3px'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'z-index', _1: '99'},
									_1: {ctor: '[]'}
								}
							}
						}
					}
				}),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$id(
					_minekoa$elm_text_editor$TextEditor_Core$cursorID(model)),
				_1: {ctor: '[]'}
			}
		},
		{ctor: '[]'});
};
var _minekoa$elm_text_editor$TextEditor$compositionPreview = function (compositionData) {
	var _p5 = compositionData;
	if (_p5.ctor === 'Just') {
		return A2(
			_elm_lang$html$Html$span,
			{
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$class('composition_data'),
				_1: {
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$style(
						{
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'color', _1: 'blue'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'text-decoration', _1: 'underline'},
								_1: {ctor: '[]'}
							}
						}),
					_1: {ctor: '[]'}
				}
			},
			{
				ctor: '::',
				_0: _elm_lang$html$Html$text(_p5._0),
				_1: {ctor: '[]'}
			});
	} else {
		return _elm_lang$html$Html$text('');
	}
};
var _minekoa$elm_text_editor$TextEditor$ruler = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$class('ruler-layer'),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$style(
					{
						ctor: '::',
						_0: {ctor: '_Tuple2', _0: 'position', _1: 'absolute'},
						_1: {
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'overflow', _1: 'hidden'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'width', _1: '0px'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'opacity', _1: '0'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'pointer-events', _1: 'none'},
										_1: {ctor: '[]'}
									}
								}
							}
						}
					}),
				_1: {ctor: '[]'}
			}
		},
		{
			ctor: '::',
			_0: A2(
				_elm_lang$html$Html$span,
				{
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$id(
						_minekoa$elm_text_editor$TextEditor_Core$rulerID(model)),
					_1: {
						ctor: '::',
						_0: _elm_lang$html$Html_Attributes$style(
							{
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'white-space', _1: 'pre'},
								_1: {ctor: '[]'}
							}),
						_1: {ctor: '[]'}
					}
				},
				{ctor: '[]'}),
			_1: {
				ctor: '::',
				_0: A2(
					_elm_lang$html$Html$span,
					{
						ctor: '::',
						_0: _elm_lang$html$Html_Attributes$id(
							_minekoa$elm_text_editor$TextEditor_Core$prototyleEmID(model)),
						_1: {
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$style(
								{
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'white-space', _1: 'pre'},
									_1: {ctor: '[]'}
								}),
							_1: {ctor: '[]'}
						}
					},
					{
						ctor: '::',
						_0: _elm_lang$html$Html$text('箱'),
						_1: {ctor: '[]'}
					}),
				_1: {ctor: '[]'}
			}
		});
};
var _minekoa$elm_text_editor$TextEditor$padToCursor = F2(
	function (pos, model) {
		var contents = model.buffer.contents;
		return A2(
			_elm_lang$html$Html$span,
			{
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$class('pad'),
				_1: {
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$style(
						{
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'position', _1: 'relative'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'white-space', _1: 'pre'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'visibility', _1: 'hidden'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'pointer-events', _1: 'none'},
										_1: {ctor: '[]'}
									}
								}
							}
						}),
					_1: {ctor: '[]'}
				}
			},
			{
				ctor: '::',
				_0: _elm_lang$html$Html$text(
					A2(
						_elm_lang$core$String$left,
						_elm_lang$core$Tuple$second(pos),
						A2(
							_elm_lang$core$Maybe$withDefault,
							'',
							A2(
								_minekoa$elm_text_editor$TextEditor_Buffer$line,
								_elm_lang$core$Tuple$first(pos),
								contents)))),
				_1: {ctor: '[]'}
			});
	});
var _minekoa$elm_text_editor$TextEditor$pad = function (model) {
	var contents = model.buffer.contents;
	var cur = model.buffer.cursor;
	return A2(
		_elm_lang$html$Html$span,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$class('pad'),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$style(
					{
						ctor: '::',
						_0: {ctor: '_Tuple2', _0: 'position', _1: 'relative'},
						_1: {
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'white-space', _1: 'pre'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'visibility', _1: 'hidden'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'pointer-events', _1: 'none'},
									_1: {ctor: '[]'}
								}
							}
						}
					}),
				_1: {ctor: '[]'}
			}
		},
		{
			ctor: '::',
			_0: _elm_lang$html$Html$text(
				A2(
					_elm_lang$core$String$left,
					cur.column,
					A2(
						_elm_lang$core$Maybe$withDefault,
						'',
						A2(_minekoa$elm_text_editor$TextEditor_Buffer$line, cur.row, contents)))),
			_1: {ctor: '[]'}
		});
};
var _minekoa$elm_text_editor$TextEditor$markerLayer = function (model) {
	var _p6 = model.buffer.selection;
	if (_p6.ctor === 'Nothing') {
		return _elm_lang$html$Html$text('');
	} else {
		var _p7 = _p6._0;
		var calc_w = _minekoa$elm_text_editor$TextEditor$calcTextWidth(
			_minekoa$elm_text_editor$TextEditor_Core$rulerID(model));
		var rect = _minekoa$elm_text_editor$TextEditor$getBoundingClientRect(
			_minekoa$elm_text_editor$TextEditor_Core$codeAreaID(model));
		var epos = A2(_minekoa$elm_text_editor$TextEditor_Buffer$isPreviosPos, _p7.begin, _p7.end) ? _p7.end : _p7.begin;
		var epix = calc_w(
			A2(
				_elm_lang$core$String$left,
				_elm_lang$core$Tuple$second(epos),
				A2(
					_elm_lang$core$Maybe$withDefault,
					'',
					A2(
						_minekoa$elm_text_editor$TextEditor_Buffer$line,
						_elm_lang$core$Tuple$first(epos),
						model.buffer.contents))));
		var bpos = A2(_minekoa$elm_text_editor$TextEditor_Buffer$isPreviosPos, _p7.begin, _p7.end) ? _p7.begin : _p7.end;
		var bpix = calc_w(
			A2(
				_elm_lang$core$String$left,
				_elm_lang$core$Tuple$second(bpos),
				A2(
					_elm_lang$core$Maybe$withDefault,
					'',
					A2(
						_minekoa$elm_text_editor$TextEditor_Buffer$line,
						_elm_lang$core$Tuple$first(bpos),
						model.buffer.contents))));
		var ms = A2(
			_elm_lang$core$List$map,
			function (r) {
				var ce = _elm_lang$core$Native_Utils.eq(
					r,
					_elm_lang$core$Tuple$first(epos)) ? _elm_lang$core$Tuple$second(epos) : _elm_lang$core$String$length(
					A2(
						_elm_lang$core$Maybe$withDefault,
						'',
						A2(_minekoa$elm_text_editor$TextEditor_Buffer$line, r, model.buffer.contents)));
				var cb = _elm_lang$core$Native_Utils.eq(
					r,
					_elm_lang$core$Tuple$first(bpos)) ? _elm_lang$core$Tuple$second(bpos) : 0;
				var pe = _elm_lang$core$Native_Utils.eq(
					r,
					_elm_lang$core$Tuple$first(epos)) ? epix : (rect.right - rect.left);
				var pb = _elm_lang$core$Native_Utils.eq(
					r,
					_elm_lang$core$Tuple$first(bpos)) ? bpix : 0;
				return {row: r, begin_col: cb, end_col: ce, begin_px: pb, end_px: pe};
			},
			A2(
				_elm_lang$core$List$range,
				_elm_lang$core$Tuple$first(bpos),
				_elm_lang$core$Tuple$first(epos)));
		return A2(
			_elm_lang$html$Html$div,
			{
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$class('marker-layer'),
				_1: {
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$style(
						{
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'position', _1: 'absolute'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'pointer-events', _1: 'none'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'z-index', _1: '99'},
									_1: {ctor: '[]'}
								}
							}
						}),
					_1: {ctor: '[]'}
				}
			},
			A2(
				_elm_lang$core$List$map,
				function (m) {
					return A2(
						_elm_lang$html$Html$div,
						{
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$style(
								{
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'position', _1: 'absolute'},
									_1: {
										ctor: '::',
										_0: {
											ctor: '_Tuple2',
											_0: 'top',
											_1: A2(_minekoa$elm_text_editor$TextEditor$emToPxString, model, m.row)
										},
										_1: {
											ctor: '::',
											_0: {
												ctor: '_Tuple2',
												_0: 'left',
												_1: _minekoa$elm_text_editor$TextEditor$toPxString(m.begin_px)
											},
											_1: {
												ctor: '::',
												_0: {
													ctor: '_Tuple2',
													_0: 'width',
													_1: _minekoa$elm_text_editor$TextEditor$toPxString(m.end_px - m.begin_px)
												},
												_1: {
													ctor: '::',
													_0: {
														ctor: '_Tuple2',
														_0: 'height',
														_1: A2(_minekoa$elm_text_editor$TextEditor$emToPxString, model, 1)
													},
													_1: {
														ctor: '::',
														_0: {ctor: '_Tuple2', _0: 'background-color', _1: 'blue'},
														_1: {
															ctor: '::',
															_0: {ctor: '_Tuple2', _0: 'color', _1: 'white'},
															_1: {
																ctor: '::',
																_0: {ctor: '_Tuple2', _0: 'white-space', _1: 'pre'},
																_1: {
																	ctor: '::',
																	_0: {ctor: '_Tuple2', _0: 'pointer-events', _1: 'auto'},
																	_1: {ctor: '[]'}
																}
															}
														}
													}
												}
											}
										}
									}
								}),
							_1: {
								ctor: '::',
								_0: _elm_lang$html$Html_Attributes$contenteditable(true),
								_1: {ctor: '[]'}
							}
						},
						{
							ctor: '::',
							_0: _elm_lang$html$Html$text(
								function (l) {
									return _elm_lang$core$Native_Utils.eq(l, '') ? ' ' : l;
								}(
									A2(
										_elm_lang$core$String$left,
										m.end_col - m.begin_col,
										A2(
											_elm_lang$core$String$dropLeft,
											m.begin_col,
											A2(
												_elm_lang$core$Maybe$withDefault,
												'',
												A2(_minekoa$elm_text_editor$TextEditor_Buffer$line, m.row, model.buffer.contents)))))),
							_1: {ctor: '[]'}
						});
				},
				ms));
	}
};
var _minekoa$elm_text_editor$TextEditor$lineNumArea = function (model) {
	var contents = model.buffer.contents;
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$id(
				_minekoa$elm_text_editor$TextEditor_Core$lineNumAreaID(model)),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$class('line-num-area'),
				_1: {
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$style(
						{
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'text-align', _1: 'right'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'padding-right', _1: '0.8em'},
								_1: {ctor: '[]'}
							}
						}),
					_1: {ctor: '[]'}
				}
			}
		},
		A2(
			_elm_lang$core$List$map,
			function (n) {
				return A2(
					_elm_lang$html$Html$div,
					{
						ctor: '::',
						_0: _elm_lang$html$Html_Attributes$class('line-num'),
						_1: {
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$style(
								{
									ctor: '::',
									_0: {
										ctor: '_Tuple2',
										_0: 'height',
										_1: A2(_minekoa$elm_text_editor$TextEditor$emToPxString, model, 1)
									},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'text-wrap', _1: 'none'},
										_1: {ctor: '[]'}
									}
								}),
							_1: {ctor: '[]'}
						}
					},
					{
						ctor: '::',
						_0: _elm_lang$html$Html$text(
							_elm_lang$core$Basics$toString(n)),
						_1: {ctor: '[]'}
					});
			},
			A2(
				_elm_lang$core$List$range,
				1,
				_elm_lang$core$List$length(contents))));
};
var _minekoa$elm_text_editor$TextEditor$selectionClear = function (model) {
	var coremodel = model.core;
	return _elm_lang$core$Native_Utils.update(
		model,
		{
			core: _elm_lang$core$Native_Utils.update(
				coremodel,
				{
					buffer: _minekoa$elm_text_editor$TextEditor_Buffer$selectionClear(coremodel.buffer)
				})
		});
};
var _minekoa$elm_text_editor$TextEditor$composerDisable = function (model) {
	return _elm_lang$core$Native_Utils.update(
		model,
		{enableComposer: false});
};
var _minekoa$elm_text_editor$TextEditor$composerEnable = function (model) {
	return _elm_lang$core$Native_Utils.update(
		model,
		{enableComposer: true});
};
var _minekoa$elm_text_editor$TextEditor$blinkBlock = function (model) {
	return _elm_lang$core$Native_Utils.update(
		model,
		{
			core: _minekoa$elm_text_editor$TextEditor_Core$blinkBlock(model.core)
		});
};
var _minekoa$elm_text_editor$TextEditor$eventLog = F3(
	function (ev, data, model) {
		var s = A2(
			_elm_lang$core$Basics_ops['++'],
			'(',
			A2(
				_elm_lang$core$Basics_ops['++'],
				ev,
				A2(
					_elm_lang$core$Basics_ops['++'],
					':',
					A2(_elm_lang$core$Basics_ops['++'], data, ') '))));
		return _elm_lang$core$Native_Utils.update(
			model,
			{
				event_log: A2(
					_elm_lang$core$Maybe$andThen,
					function (logs) {
						return _elm_lang$core$Maybe$Just(
							{ctor: '::', _0: s, _1: logs});
					},
					model.event_log)
			});
	});
var _minekoa$elm_text_editor$TextEditor$compositionUpdate = F2(
	function (data, model) {
		return {
			ctor: '_Tuple2',
			_0: A3(
				_minekoa$elm_text_editor$TextEditor$eventLog,
				'compositionupdate',
				data,
				_elm_lang$core$Native_Utils.update(
					model,
					{
						core: A2(_minekoa$elm_text_editor$TextEditor_Core$compositionUpdate, data, model.core)
					})),
			_1: _elm_lang$core$Platform_Cmd$none
		};
	});
var _minekoa$elm_text_editor$TextEditor$compositionStart = F2(
	function (data, model) {
		return {
			ctor: '_Tuple2',
			_0: A3(
				_minekoa$elm_text_editor$TextEditor$eventLog,
				'compositoinstart',
				data,
				_minekoa$elm_text_editor$TextEditor$composerEnable(
					_elm_lang$core$Native_Utils.update(
						model,
						{
							core: _minekoa$elm_text_editor$TextEditor_Core$compositionStart(model.core)
						}))),
			_1: _elm_lang$core$Platform_Cmd$none
		};
	});
var _minekoa$elm_text_editor$TextEditor$keyPress = F2(
	function (code, model) {
		return {
			ctor: '_Tuple2',
			_0: A3(
				_minekoa$elm_text_editor$TextEditor$eventLog,
				'keypress',
				_elm_lang$core$Basics$toString(code),
				_minekoa$elm_text_editor$TextEditor$composerDisable(model)),
			_1: _elm_lang$core$Platform_Cmd$none
		};
	});
var _minekoa$elm_text_editor$TextEditor$setBuffer = F2(
	function (newbuf, model) {
		var cm = model.core;
		return _elm_lang$core$Native_Utils.update(
			model,
			{
				core: _elm_lang$core$Native_Utils.update(
					cm,
					{buffer: newbuf})
			});
	});
var _minekoa$elm_text_editor$TextEditor$buffer = function (model) {
	return model.core.buffer;
};
var _minekoa$elm_text_editor$TextEditor$Model = F4(
	function (a, b, c, d) {
		return {core: a, enableComposer: b, keymap: c, event_log: d};
	});
var _minekoa$elm_text_editor$TextEditor$KeyboardEvent = F6(
	function (a, b, c, d, e, f) {
		return {altKey: a, ctrlKey: b, keyCode: c, metaKey: d, repeat: e, shiftKey: f};
	});
var _minekoa$elm_text_editor$TextEditor$decodeKeyboardEvent = A7(
	_elm_lang$core$Json_Decode$map6,
	_minekoa$elm_text_editor$TextEditor$KeyboardEvent,
	A2(_elm_lang$core$Json_Decode$field, 'altKey', _elm_lang$core$Json_Decode$bool),
	A2(_elm_lang$core$Json_Decode$field, 'ctrlKey', _elm_lang$core$Json_Decode$bool),
	A2(_elm_lang$core$Json_Decode$field, 'keyCode', _elm_lang$core$Json_Decode$int),
	A2(_elm_lang$core$Json_Decode$field, 'metaKey', _elm_lang$core$Json_Decode$bool),
	A2(_elm_lang$core$Json_Decode$field, 'repeat', _elm_lang$core$Json_Decode$bool),
	A2(_elm_lang$core$Json_Decode$field, 'shiftKey', _elm_lang$core$Json_Decode$bool));
var _minekoa$elm_text_editor$TextEditor$onKeyDown = function (tagger) {
	return A2(
		_elm_lang$html$Html_Events$on,
		'keydown',
		A2(_elm_lang$core$Json_Decode$map, tagger, _minekoa$elm_text_editor$TextEditor$decodeKeyboardEvent));
};
var _minekoa$elm_text_editor$TextEditor$Rect = F8(
	function (a, b, c, d, e, f, g, h) {
		return {left: a, top: b, right: c, bottom: d, x: e, y: f, width: g, height: h};
	});
var _minekoa$elm_text_editor$TextEditor$DragStart = F2(
	function (a, b) {
		return {ctor: 'DragStart', _0: a, _1: b};
	});
var _minekoa$elm_text_editor$TextEditor$codeLayer = function (model) {
	var cursor = model.buffer.cursor;
	var contents = model.buffer.contents;
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$class('code-layer'),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$style(
					{
						ctor: '::',
						_0: {ctor: '_Tuple2', _0: 'margin', _1: '0'},
						_1: {
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'padding', _1: '0'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'border', _1: 'none'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'width', _1: '100%'},
									_1: {ctor: '[]'}
								}
							}
						}
					}),
				_1: {ctor: '[]'}
			}
		},
		A2(
			_elm_lang$core$List$indexedMap,
			F2(
				function (n, ln) {
					return A2(
						_elm_lang$html$Html$div,
						{
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$class('line'),
							_1: {
								ctor: '::',
								_0: _elm_lang$html$Html_Attributes$style(
									{
										ctor: '::',
										_0: {
											ctor: '_Tuple2',
											_0: 'height',
											_1: A2(_minekoa$elm_text_editor$TextEditor$emToPxString, model, 1)
										},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'width', _1: '100%'},
											_1: {
												ctor: '::',
												_0: {ctor: '_Tuple2', _0: 'text-wrap', _1: 'none'},
												_1: {
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'white-space', _1: 'pre'},
													_1: {
														ctor: '::',
														_0: {ctor: '_Tuple2', _0: 'pointer-events', _1: 'auto'},
														_1: {ctor: '[]'}
													}
												}
											}
										}
									}),
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$TextEditor$onMouseDown(
										_minekoa$elm_text_editor$TextEditor$DragStart(n)),
									_1: {ctor: '[]'}
								}
							}
						},
						(_elm_lang$core$Native_Utils.eq(n, cursor.row) && (!_elm_lang$core$Native_Utils.eq(model.compositionPreview, _elm_lang$core$Maybe$Nothing))) ? {
							ctor: '::',
							_0: A2(
								_elm_lang$html$Html$span,
								{
									ctor: '::',
									_0: _elm_lang$html$Html_Attributes$style(
										{
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'position', _1: 'relative'},
											_1: {
												ctor: '::',
												_0: {ctor: '_Tuple2', _0: 'white-space', _1: 'pre'},
												_1: {
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'pointer-events', _1: 'none'},
													_1: {ctor: '[]'}
												}
											}
										}),
									_1: {ctor: '[]'}
								},
								{
									ctor: '::',
									_0: _elm_lang$html$Html$text(
										A2(_elm_lang$core$String$left, cursor.column, ln)),
									_1: {ctor: '[]'}
								}),
							_1: {
								ctor: '::',
								_0: _minekoa$elm_text_editor$TextEditor$compositionPreview(model.compositionPreview),
								_1: {
									ctor: '::',
									_0: A2(
										_elm_lang$html$Html$span,
										{
											ctor: '::',
											_0: _elm_lang$html$Html_Attributes$style(
												{
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'position', _1: 'relative'},
													_1: {
														ctor: '::',
														_0: {ctor: '_Tuple2', _0: 'white-space', _1: 'pre'},
														_1: {
															ctor: '::',
															_0: {ctor: '_Tuple2', _0: 'pointer-events', _1: 'none'},
															_1: {ctor: '[]'}
														}
													}
												}),
											_1: {ctor: '[]'}
										},
										{
											ctor: '::',
											_0: _elm_lang$html$Html$text(
												A2(_elm_lang$core$String$dropLeft, cursor.column, ln)),
											_1: {ctor: '[]'}
										}),
									_1: {ctor: '[]'}
								}
							}
						} : {
							ctor: '::',
							_0: _elm_lang$html$Html$text(ln),
							_1: {ctor: '[]'}
						});
				}),
			contents));
};
var _minekoa$elm_text_editor$TextEditor$ClickScreen = {ctor: 'ClickScreen'};
var _minekoa$elm_text_editor$TextEditor$FocusOut = function (a) {
	return {ctor: 'FocusOut', _0: a};
};
var _minekoa$elm_text_editor$TextEditor$FocusIn = function (a) {
	return {ctor: 'FocusIn', _0: a};
};
var _minekoa$elm_text_editor$TextEditor$CompositionEnd = function (a) {
	return {ctor: 'CompositionEnd', _0: a};
};
var _minekoa$elm_text_editor$TextEditor$CompositionUpdate = function (a) {
	return {ctor: 'CompositionUpdate', _0: a};
};
var _minekoa$elm_text_editor$TextEditor$CompositionStart = function (a) {
	return {ctor: 'CompositionStart', _0: a};
};
var _minekoa$elm_text_editor$TextEditor$KeyPress = function (a) {
	return {ctor: 'KeyPress', _0: a};
};
var _minekoa$elm_text_editor$TextEditor$KeyDown = function (a) {
	return {ctor: 'KeyDown', _0: a};
};
var _minekoa$elm_text_editor$TextEditor$Input = function (a) {
	return {ctor: 'Input', _0: a};
};
var _minekoa$elm_text_editor$TextEditor$Cutted = function (a) {
	return {ctor: 'Cutted', _0: a};
};
var _minekoa$elm_text_editor$TextEditor$Copied = function (a) {
	return {ctor: 'Copied', _0: a};
};
var _minekoa$elm_text_editor$TextEditor$Pasted = function (a) {
	return {ctor: 'Pasted', _0: a};
};
var _minekoa$elm_text_editor$TextEditor$cursorLayer = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$class('cursor-layer'),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$style(
					{
						ctor: '::',
						_0: {ctor: '_Tuple2', _0: 'position', _1: 'absolute'},
						_1: {
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'pointer-events', _1: 'none'},
							_1: {ctor: '[]'}
						}
					}),
				_1: {ctor: '[]'}
			}
		},
		{
			ctor: '::',
			_0: A2(
				_elm_lang$html$Html$div,
				{
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$style(
						{
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'position', _1: 'relative'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'display', _1: 'inline-flex'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'flex-direction', _1: 'row'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'flex-wrap', _1: 'nowrap'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'justify-content', _1: 'flex-start'},
											_1: {
												ctor: '::',
												_0: {
													ctor: '_Tuple2',
													_0: 'height',
													_1: A2(_minekoa$elm_text_editor$TextEditor$emToPxString, model, 1)
												},
												_1: {
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'align-items', _1: 'baseline'},
													_1: {
														ctor: '::',
														_0: {
															ctor: '_Tuple2',
															_0: 'top',
															_1: A2(_minekoa$elm_text_editor$TextEditor$emToPxString, model, model.buffer.cursor.row)
														},
														_1: {
															ctor: '::',
															_0: {ctor: '_Tuple2', _0: 'left', _1: '0'},
															_1: {ctor: '[]'}
														}
													}
												}
											}
										}
									}
								}
							}
						}),
					_1: {ctor: '[]'}
				},
				{
					ctor: '::',
					_0: _minekoa$elm_text_editor$TextEditor$pad(model),
					_1: {
						ctor: '::',
						_0: A2(
							_elm_lang$html$Html$div,
							{
								ctor: '::',
								_0: _elm_lang$html$Html_Attributes$style(
									{
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'position', _1: 'relative'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'display', _1: 'inline-flex'},
											_1: {ctor: '[]'}
										}
									}),
								_1: {ctor: '[]'}
							},
							{
								ctor: '::',
								_0: A2(
									_elm_lang$html$Html$textarea,
									{
										ctor: '::',
										_0: _elm_lang$html$Html_Attributes$id(
											_minekoa$elm_text_editor$TextEditor_Core$inputAreaID(model)),
										_1: {
											ctor: '::',
											_0: _elm_lang$html$Html_Events$onInput(_minekoa$elm_text_editor$TextEditor$Input),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$TextEditor$onKeyDown(_minekoa$elm_text_editor$TextEditor$KeyDown),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$TextEditor$onKeyPress(_minekoa$elm_text_editor$TextEditor$KeyPress),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$TextEditor$onCompositionStart(_minekoa$elm_text_editor$TextEditor$CompositionStart),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$TextEditor$onCompositionUpdate(_minekoa$elm_text_editor$TextEditor$CompositionUpdate),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$TextEditor$onCompositionEnd(_minekoa$elm_text_editor$TextEditor$CompositionEnd),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$TextEditor$onPasted(_minekoa$elm_text_editor$TextEditor$Pasted),
																	_1: {
																		ctor: '::',
																		_0: _minekoa$elm_text_editor$TextEditor$onCopied(_minekoa$elm_text_editor$TextEditor$Copied),
																		_1: {
																			ctor: '::',
																			_0: _minekoa$elm_text_editor$TextEditor$onCutted(_minekoa$elm_text_editor$TextEditor$Cutted),
																			_1: {
																				ctor: '::',
																				_0: _minekoa$elm_text_editor$TextEditor$selecteddata(
																					_minekoa$elm_text_editor$TextEditor_Buffer$selectedString(model.buffer)),
																				_1: {
																					ctor: '::',
																					_0: _elm_lang$html$Html_Attributes$spellcheck(false),
																					_1: {
																						ctor: '::',
																						_0: _elm_lang$html$Html_Attributes$wrap('off'),
																						_1: {
																							ctor: '::',
																							_0: _elm_lang$html$Html_Attributes$style(
																								{
																									ctor: '::',
																									_0: {ctor: '_Tuple2', _0: 'border', _1: 'none'},
																									_1: {
																										ctor: '::',
																										_0: {ctor: '_Tuple2', _0: 'padding', _1: '0'},
																										_1: {
																											ctor: '::',
																											_0: {ctor: '_Tuple2', _0: 'margin', _1: '0'},
																											_1: {
																												ctor: '::',
																												_0: {ctor: '_Tuple2', _0: 'outline', _1: 'none'},
																												_1: {
																													ctor: '::',
																													_0: {ctor: '_Tuple2', _0: 'overflow', _1: 'hidden'},
																													_1: {
																														ctor: '::',
																														_0: {ctor: '_Tuple2', _0: 'opacity', _1: '0'},
																														_1: {
																															ctor: '::',
																															_0: {
																																ctor: '_Tuple2',
																																_0: 'width',
																																_1: _minekoa$elm_text_editor$TextEditor$toEmString(
																																	A3(
																																		_elm_lang$core$Basics$flip,
																																		F2(
																																			function (x, y) {
																																				return x + y;
																																			}),
																																		1,
																																		_elm_lang$core$String$length(
																																			A2(_elm_lang$core$Maybe$withDefault, '', model.compositionPreview))))
																															},
																															_1: {
																																ctor: '::',
																																_0: {ctor: '_Tuple2', _0: 'resize', _1: 'none'},
																																_1: {
																																	ctor: '::',
																																	_0: {
																																		ctor: '_Tuple2',
																																		_0: 'height',
																																		_1: A2(_minekoa$elm_text_editor$TextEditor$emToPxString, model, 1)
																																	},
																																	_1: {
																																		ctor: '::',
																																		_0: {ctor: '_Tuple2', _0: 'font-size', _1: '1em'},
																																		_1: {
																																			ctor: '::',
																																			_0: {ctor: '_Tuple2', _0: 'font-family', _1: 'inherit'},
																																			_1: {
																																				ctor: '::',
																																				_0: {ctor: '_Tuple2', _0: 'position', _1: 'absolute'},
																																				_1: {ctor: '[]'}
																																			}
																																		}
																																	}
																																}
																															}
																														}
																													}
																												}
																											}
																										}
																									}
																								}),
																							_1: {ctor: '[]'}
																						}
																					}
																				}
																			}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									},
									{ctor: '[]'}),
								_1: {
									ctor: '::',
									_0: A2(
										_elm_lang$html$Html$span,
										{
											ctor: '::',
											_0: _elm_lang$html$Html_Attributes$class('pad-composition-preview'),
											_1: {
												ctor: '::',
												_0: _elm_lang$html$Html_Attributes$style(
													{
														ctor: '::',
														_0: {ctor: '_Tuple2', _0: 'visibility', _1: 'hidden'},
														_1: {
															ctor: '::',
															_0: {ctor: '_Tuple2', _0: 'white-space', _1: 'nowrap'},
															_1: {ctor: '[]'}
														}
													}),
												_1: {ctor: '[]'}
											}
										},
										{
											ctor: '::',
											_0: _minekoa$elm_text_editor$TextEditor$compositionPreview(model.compositionPreview),
											_1: {ctor: '[]'}
										}),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$TextEditor$cursorView(model),
										_1: {ctor: '[]'}
									}
								}
							}),
						_1: {ctor: '[]'}
					}
				}),
			_1: {ctor: '[]'}
		});
};
var _minekoa$elm_text_editor$TextEditor$codeArea = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$id(
				_minekoa$elm_text_editor$TextEditor_Core$codeAreaID(model)),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$class('code-area'),
				_1: {
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$style(
						{
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'margin', _1: '0'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'padding', _1: '0'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'border', _1: 'none'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'flex-grow', _1: '1'},
										_1: {ctor: '[]'}
									}
								}
							}
						}),
					_1: {ctor: '[]'}
				}
			}
		},
		{
			ctor: '::',
			_0: _minekoa$elm_text_editor$TextEditor$ruler(model),
			_1: {
				ctor: '::',
				_0: _minekoa$elm_text_editor$TextEditor$cursorLayer(model),
				_1: {
					ctor: '::',
					_0: _minekoa$elm_text_editor$TextEditor$markerLayer(model),
					_1: {
						ctor: '::',
						_0: _minekoa$elm_text_editor$TextEditor$codeLayer(model),
						_1: {ctor: '[]'}
					}
				}
			}
		});
};
var _minekoa$elm_text_editor$TextEditor$presentation = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$style(
				{
					ctor: '::',
					_0: {ctor: '_Tuple2', _0: 'display', _1: 'flex'},
					_1: {
						ctor: '::',
						_0: {ctor: '_Tuple2', _0: 'flex-direction', _1: 'row'},
						_1: {
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'flex-wrap', _1: 'nowrap'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'margin', _1: '0'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'padding', _1: '0'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'width', _1: '100%'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'height', _1: '100%'},
											_1: {
												ctor: '::',
												_0: {ctor: '_Tuple2', _0: 'position', _1: 'relative'},
												_1: {ctor: '[]'}
											}
										}
									}
								}
							}
						}
					}
				}),
			_1: {
				ctor: '::',
				_0: _minekoa$elm_text_editor$TextEditor$onFocusIn(_minekoa$elm_text_editor$TextEditor$FocusIn),
				_1: {
					ctor: '::',
					_0: _minekoa$elm_text_editor$TextEditor$onFocusOut(_minekoa$elm_text_editor$TextEditor$FocusOut),
					_1: {ctor: '[]'}
				}
			}
		},
		{
			ctor: '::',
			_0: _minekoa$elm_text_editor$TextEditor$lineNumArea(model),
			_1: {
				ctor: '::',
				_0: _minekoa$elm_text_editor$TextEditor$codeArea(model),
				_1: {ctor: '[]'}
			}
		});
};
var _minekoa$elm_text_editor$TextEditor$view = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$id(
				_minekoa$elm_text_editor$TextEditor_Core$frameID(model.core)),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$style(
					{
						ctor: '::',
						_0: {ctor: '_Tuple2', _0: 'margin', _1: '0'},
						_1: {
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'padding', _1: '0'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'width', _1: '100%'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'height', _1: '100%'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'overflow', _1: 'auto'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'position', _1: 'relative'},
											_1: {
												ctor: '::',
												_0: {ctor: '_Tuple2', _0: 'user-select', _1: 'none'},
												_1: {
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: '-webkit-user-select', _1: 'none'},
													_1: {
														ctor: '::',
														_0: {ctor: '_Tuple2', _0: '-moz-user-select', _1: 'none'},
														_1: {ctor: '[]'}
													}
												}
											}
										}
									}
								}
							}
						}
					}),
				_1: {
					ctor: '::',
					_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$TextEditor$ClickScreen),
					_1: {ctor: '[]'}
				}
			}
		},
		{
			ctor: '::',
			_0: A2(
				_elm_lang$html$Html$div,
				{
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$id(
						_minekoa$elm_text_editor$TextEditor_Core$sceneID(model.core)),
					_1: {
						ctor: '::',
						_0: _elm_lang$html$Html_Attributes$class('editor-scene'),
						_1: {
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$style(
								{
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'position', _1: 'relative'},
									_1: {ctor: '[]'}
								}),
							_1: {ctor: '[]'}
						}
					}
				},
				{
					ctor: '::',
					_0: _minekoa$elm_text_editor$TextEditor$presentation(model.core),
					_1: {ctor: '[]'}
				}),
			_1: {ctor: '[]'}
		});
};
var _minekoa$elm_text_editor$TextEditor$CoreMsg = function (a) {
	return {ctor: 'CoreMsg', _0: a};
};
var _minekoa$elm_text_editor$TextEditor$init = F3(
	function (id, keymap, text) {
		var _p8 = A2(_minekoa$elm_text_editor$TextEditor_Core$init, id, text);
		var coreM = _p8._0;
		var coreC = _p8._1;
		return {
			ctor: '_Tuple2',
			_0: A4(_minekoa$elm_text_editor$TextEditor$Model, coreM, false, keymap, _elm_lang$core$Maybe$Nothing),
			_1: A2(_elm_lang$core$Platform_Cmd$map, _minekoa$elm_text_editor$TextEditor$CoreMsg, coreC)
		};
	});
var _minekoa$elm_text_editor$TextEditor$compositionEnd = F2(
	function (data, model) {
		var _p9 = A2(_minekoa$elm_text_editor$TextEditor_Core$compositionEnd, data, model.core);
		var m = _p9._0;
		var c = _p9._1;
		return {
			ctor: '_Tuple2',
			_0: A3(
				_minekoa$elm_text_editor$TextEditor$eventLog,
				'compositionend',
				data,
				_elm_lang$core$Native_Utils.update(
					model,
					{core: m})),
			_1: A2(_elm_lang$core$Platform_Cmd$map, _minekoa$elm_text_editor$TextEditor$CoreMsg, c)
		};
	});
var _minekoa$elm_text_editor$TextEditor$updateMap = F2(
	function (model, _p10) {
		var _p11 = _p10;
		return {
			ctor: '_Tuple2',
			_0: _elm_lang$core$Native_Utils.update(
				model,
				{core: _p11._0}),
			_1: A2(_elm_lang$core$Platform_Cmd$map, _minekoa$elm_text_editor$TextEditor$CoreMsg, _p11._1)
		};
	});
var _minekoa$elm_text_editor$TextEditor$input = F2(
	function (s, model) {
		var _p12 = model.enableComposer;
		if (_p12 === true) {
			return {
				ctor: '_Tuple2',
				_0: A3(_minekoa$elm_text_editor$TextEditor$eventLog, 'input (ignored)', s, model),
				_1: _elm_lang$core$Platform_Cmd$none
			};
		} else {
			return A2(
				_elm_lang$core$Tuple$mapFirst,
				A2(
					_minekoa$elm_text_editor$TextEditor$eventLog,
					'input',
					A2(_elm_lang$core$String$right, 1, s)),
				A2(
					_minekoa$elm_text_editor$TextEditor$updateMap,
					model,
					A2(
						_minekoa$elm_text_editor$TextEditor_Core_Commands$insert,
						A2(_elm_lang$core$String$right, 1, s),
						model.core)));
		}
	});
var _minekoa$elm_text_editor$TextEditor$keyDown = F2(
	function (e, model) {
		var _p13 = A2(
			_minekoa$elm_text_editor$TextEditor_KeyBind$find,
			{ctor: '_Tuple4', _0: e.ctrlKey, _1: e.altKey, _2: e.shiftKey, _3: e.keyCode},
			model.keymap);
		if (_p13.ctor === 'Just') {
			return A2(
				_elm_lang$core$Tuple$mapFirst,
				A2(
					_minekoa$elm_text_editor$TextEditor$eventLog,
					'keydown',
					_minekoa$elm_text_editor$TextEditor$keyboarEvent_toString(e)),
				A2(
					_minekoa$elm_text_editor$TextEditor$updateMap,
					model,
					_p13._0(model.core)));
		} else {
			return {
				ctor: '_Tuple2',
				_0: A3(
					_minekoa$elm_text_editor$TextEditor$eventLog,
					'keydown',
					_minekoa$elm_text_editor$TextEditor$keyboarEvent_toString(e),
					model),
				_1: _elm_lang$core$Platform_Cmd$none
			};
		}
	});
var _minekoa$elm_text_editor$TextEditor$update = F2(
	function (msg, model) {
		var _p14 = msg;
		switch (_p14.ctor) {
			case 'CoreMsg':
				return A2(
					_elm_lang$core$Tuple$mapSecond,
					_elm_lang$core$Platform_Cmd$map(_minekoa$elm_text_editor$TextEditor$CoreMsg),
					A2(
						_elm_lang$core$Tuple$mapFirst,
						function (cm) {
							return _elm_lang$core$Native_Utils.update(
								model,
								{core: cm});
						},
						A2(_minekoa$elm_text_editor$TextEditor_Core$update, _p14._0, model.core)));
			case 'Pasted':
				var _p15 = _p14._0;
				return A2(
					_elm_lang$core$Tuple$mapFirst,
					A2(_minekoa$elm_text_editor$TextEditor$eventLog, 'pasted', _p15),
					A2(
						_minekoa$elm_text_editor$TextEditor$updateMap,
						model,
						A2(_minekoa$elm_text_editor$TextEditor_Core_Commands$paste, _p15, model.core)));
			case 'Copied':
				return A2(
					_elm_lang$core$Tuple$mapFirst,
					A2(_minekoa$elm_text_editor$TextEditor$eventLog, 'copied', _p14._0),
					A2(
						_minekoa$elm_text_editor$TextEditor$updateMap,
						model,
						_minekoa$elm_text_editor$TextEditor_Core_Commands$copy(model.core)));
			case 'Cutted':
				return A2(
					_elm_lang$core$Tuple$mapFirst,
					A2(_minekoa$elm_text_editor$TextEditor$eventLog, 'cutted', _p14._0),
					A2(
						_minekoa$elm_text_editor$TextEditor$updateMap,
						model,
						_minekoa$elm_text_editor$TextEditor_Core_Commands$cut(model.core)));
			case 'Input':
				return A2(_minekoa$elm_text_editor$TextEditor$input, _p14._0, model);
			case 'KeyDown':
				return A2(_minekoa$elm_text_editor$TextEditor$keyDown, _p14._0, model);
			case 'KeyPress':
				return A2(_minekoa$elm_text_editor$TextEditor$keyPress, _p14._0, model);
			case 'CompositionStart':
				return A2(_minekoa$elm_text_editor$TextEditor$compositionStart, _p14._0, model);
			case 'CompositionUpdate':
				return A2(_minekoa$elm_text_editor$TextEditor$compositionUpdate, _p14._0, model);
			case 'CompositionEnd':
				return A2(_minekoa$elm_text_editor$TextEditor$compositionEnd, _p14._0, model);
			case 'FocusIn':
				var cm = model.core;
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{
							core: _elm_lang$core$Native_Utils.update(
								cm,
								{focus: true})
						}),
					_1: A2(
						_elm_lang$core$Platform_Cmd$map,
						_minekoa$elm_text_editor$TextEditor$CoreMsg,
						_minekoa$elm_text_editor$TextEditor_Core$elaborateInputArea(model.core))
				};
			case 'FocusOut':
				var cm = model.core;
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{
							core: _elm_lang$core$Native_Utils.update(
								cm,
								{focus: false})
						}),
					_1: _elm_lang$core$Platform_Cmd$none
				};
			case 'ClickScreen':
				return {
					ctor: '_Tuple2',
					_0: A3(_minekoa$elm_text_editor$TextEditor$eventLog, 'setfocus', '', model),
					_1: A2(
						_elm_lang$core$Platform_Cmd$map,
						_minekoa$elm_text_editor$TextEditor$CoreMsg,
						_minekoa$elm_text_editor$TextEditor_Core$doFocus(model.core))
				};
			default:
				var _p18 = _p14._1;
				var _p17 = _p14._0;
				var rect = _minekoa$elm_text_editor$TextEditor$getBoundingClientRect(
					_minekoa$elm_text_editor$TextEditor_Core$codeAreaID(model.core));
				var ln = A2(
					_elm_lang$core$Maybe$withDefault,
					'',
					A2(_minekoa$elm_text_editor$TextEditor_Buffer$line, _p17, model.core.buffer.contents));
				var calc_w = _minekoa$elm_text_editor$TextEditor$calcTextWidth(
					_minekoa$elm_text_editor$TextEditor_Core$rulerID(model.core));
				var calc_col = F3(
					function (ln, c, x) {
						calc_col:
						while (true) {
							if ((_elm_lang$core$Native_Utils.cmp(
								calc_w(
									A2(_elm_lang$core$String$left, c, ln)),
								x) > 0) || (_elm_lang$core$Native_Utils.cmp(
								_elm_lang$core$String$length(ln),
								c) < 0)) {
								return c - 1;
							} else {
								var _v7 = ln,
									_v8 = c + 1,
									_v9 = x;
								ln = _v7;
								c = _v8;
								x = _v9;
								continue calc_col;
							}
						}
					});
				var col = A3(calc_col, ln, 0, _p18.x - rect.left);
				var _p16 = A2(
					_minekoa$elm_text_editor$TextEditor_Core_Commands$moveAt,
					{ctor: '_Tuple2', _0: _p17, _1: col},
					model.core);
				var cm = _p16._0;
				var cc = _p16._1;
				return {
					ctor: '_Tuple2',
					_0: _minekoa$elm_text_editor$TextEditor$blinkBlock(
						A3(
							_minekoa$elm_text_editor$TextEditor$eventLog,
							'dragstart',
							A2(
								_elm_lang$core$Basics_ops['++'],
								'pos=',
								A2(
									_elm_lang$core$Basics_ops['++'],
									_elm_lang$core$Basics$toString(_p18.x),
									A2(
										_elm_lang$core$Basics_ops['++'],
										',',
										A2(
											_elm_lang$core$Basics_ops['++'],
											_elm_lang$core$Basics$toString(_p18.y),
											A2(
												_elm_lang$core$Basics_ops['++'],
												'; offsetx=',
												A2(
													_elm_lang$core$Basics_ops['++'],
													_elm_lang$core$Basics$toString(_p18.x - rect.left),
													A2(
														_elm_lang$core$Basics_ops['++'],
														'; row=',
														A2(
															_elm_lang$core$Basics_ops['++'],
															_elm_lang$core$Basics$toString(_p17),
															A2(
																_elm_lang$core$Basics_ops['++'],
																'; calced_col=',
																_elm_lang$core$Basics$toString(col)))))))))),
							_elm_lang$core$Native_Utils.update(
								model,
								{core: cm}))),
					_1: _elm_lang$core$Platform_Cmd$batch(
						{
							ctor: '::',
							_0: A2(_elm_lang$core$Platform_Cmd$map, _minekoa$elm_text_editor$TextEditor$CoreMsg, cc),
							_1: {ctor: '[]'}
						})
				};
		}
	});
var _minekoa$elm_text_editor$TextEditor$subscriptions = function (model) {
	return _elm_lang$core$Platform_Sub$batch(
		{
			ctor: '::',
			_0: A2(
				_elm_lang$core$Platform_Sub$map,
				_minekoa$elm_text_editor$TextEditor$CoreMsg,
				_minekoa$elm_text_editor$TextEditor_Core$subscriptions(model.core)),
			_1: {ctor: '[]'}
		});
};

var _minekoa$elm_text_editor$EditorDebugger$update = F2(
	function (msg, model) {
		var _p0 = msg;
		if (_p0._0 === true) {
			return {
				ctor: '_Tuple2',
				_0: _elm_lang$core$Native_Utils.update(
					model,
					{
						event_log: _elm_lang$core$Maybe$Just(
							{ctor: '[]'})
					}),
				_1: _elm_lang$core$Platform_Cmd$none
			};
		} else {
			return {
				ctor: '_Tuple2',
				_0: _elm_lang$core$Native_Utils.update(
					model,
					{event_log: _elm_lang$core$Maybe$Nothing}),
				_1: _elm_lang$core$Platform_Cmd$none
			};
		}
	});
var _minekoa$elm_text_editor$EditorDebugger$SetEventlogEnable = function (a) {
	return {ctor: 'SetEventlogEnable', _0: a};
};
var _minekoa$elm_text_editor$EditorDebugger$view = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$id('debug-pane'),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$class('hbox'),
				_1: {
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$style(
						{
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'display', _1: 'flex'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'flex-direction', _1: 'row'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'width', _1: '100%'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'height', _1: '100%'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'flex-grow', _1: '3'},
											_1: {
												ctor: '::',
												_0: {ctor: '_Tuple2', _0: 'min-height', _1: '7em'},
												_1: {
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'max-height', _1: '14em'},
													_1: {ctor: '[]'}
												}
											}
										}
									}
								}
							}
						}),
					_1: {ctor: '[]'}
				}
			}
		},
		{
			ctor: '::',
			_0: A2(
				_elm_lang$html$Html$div,
				{
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$id('debug-pane-history'),
					_1: {
						ctor: '::',
						_0: _elm_lang$html$Html_Attributes$style(
							{
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'min-width', _1: '8em'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'flex-grow', _1: '2'},
									_1: {ctor: '[]'}
								}
							}),
						_1: {ctor: '[]'}
					}
				},
				{
					ctor: '::',
					_0: A2(
						_elm_lang$html$Html$div,
						{
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$style(
								{
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'background-color', _1: 'whitesmoke'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'color', _1: 'gray'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'height', _1: '1em'},
											_1: {ctor: '[]'}
										}
									}
								}),
							_1: {ctor: '[]'}
						},
						{
							ctor: '::',
							_0: _elm_lang$html$Html$text('history:'),
							_1: {ctor: '[]'}
						}),
					_1: {
						ctor: '::',
						_0: A2(
							_elm_lang$html$Html$div,
							{
								ctor: '::',
								_0: _elm_lang$html$Html_Attributes$style(
									{
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'overflow', _1: 'scroll'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'height', _1: 'calc( 100% - 1em )'},
											_1: {ctor: '[]'}
										}
									}),
								_1: {ctor: '[]'}
							},
							A2(
								_elm_lang$core$List$map,
								function (c) {
									var celstyle = _elm_lang$html$Html_Attributes$style(
										{
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'text-wrap', _1: 'none'},
											_1: {
												ctor: '::',
												_0: {ctor: '_Tuple2', _0: 'white-space', _1: 'nowrap'},
												_1: {
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'color', _1: 'gray'},
													_1: {ctor: '[]'}
												}
											}
										});
									var pos2str = F2(
										function (row, col) {
											return A2(
												_elm_lang$core$Basics_ops['++'],
												'(',
												A2(
													_elm_lang$core$Basics_ops['++'],
													_elm_lang$core$Basics$toString(row),
													A2(
														_elm_lang$core$Basics_ops['++'],
														', ',
														A2(
															_elm_lang$core$Basics_ops['++'],
															_elm_lang$core$Basics$toString(col),
															')'))));
										});
									var _p1 = c;
									switch (_p1.ctor) {
										case 'Cmd_Insert':
											return A2(
												_elm_lang$html$Html$div,
												{
													ctor: '::',
													_0: celstyle,
													_1: {ctor: '[]'}
												},
												{
													ctor: '::',
													_0: _elm_lang$html$Html$text(
														A2(
															_elm_lang$core$Basics_ops['++'],
															'Ins',
															A2(
																_elm_lang$core$Basics_ops['++'],
																A2(pos2str, _p1._0._0, _p1._0._1),
																A2(
																	_elm_lang$core$Basics_ops['++'],
																	' -> ',
																	A2(
																		_elm_lang$core$Basics_ops['++'],
																		A2(pos2str, _p1._1._0, _p1._1._1),
																		A2(
																			_elm_lang$core$Basics_ops['++'],
																			'{',
																			A2(_elm_lang$core$Basics_ops['++'], _p1._2, '}'))))))),
													_1: {ctor: '[]'}
												});
										case 'Cmd_Backspace':
											return A2(
												_elm_lang$html$Html$div,
												{
													ctor: '::',
													_0: celstyle,
													_1: {ctor: '[]'}
												},
												{
													ctor: '::',
													_0: _elm_lang$html$Html$text(
														A2(
															_elm_lang$core$Basics_ops['++'],
															'Bs_',
															A2(
																_elm_lang$core$Basics_ops['++'],
																A2(pos2str, _p1._0._0, _p1._0._1),
																A2(
																	_elm_lang$core$Basics_ops['++'],
																	' -> ',
																	A2(
																		_elm_lang$core$Basics_ops['++'],
																		A2(pos2str, _p1._1._0, _p1._1._1),
																		A2(
																			_elm_lang$core$Basics_ops['++'],
																			'{',
																			A2(_elm_lang$core$Basics_ops['++'], _p1._2, '}'))))))),
													_1: {ctor: '[]'}
												});
										default:
											return A2(
												_elm_lang$html$Html$div,
												{
													ctor: '::',
													_0: celstyle,
													_1: {ctor: '[]'}
												},
												{
													ctor: '::',
													_0: _elm_lang$html$Html$text(
														A2(
															_elm_lang$core$Basics_ops['++'],
															'Del',
															A2(
																_elm_lang$core$Basics_ops['++'],
																A2(pos2str, _p1._0._0, _p1._0._1),
																A2(
																	_elm_lang$core$Basics_ops['++'],
																	' -> ',
																	A2(
																		_elm_lang$core$Basics_ops['++'],
																		A2(pos2str, _p1._1._0, _p1._1._1),
																		A2(
																			_elm_lang$core$Basics_ops['++'],
																			'{',
																			A2(_elm_lang$core$Basics_ops['++'], _p1._2, '}'))))))),
													_1: {ctor: '[]'}
												});
									}
								},
								model.core.buffer.history)),
						_1: {ctor: '[]'}
					}
				}),
			_1: {
				ctor: '::',
				_0: A2(
					_elm_lang$html$Html$div,
					{
						ctor: '::',
						_0: _elm_lang$html$Html_Attributes$class('vbox'),
						_1: {
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$style(
								{
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'flex-grow', _1: '8'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'display', _1: 'flex'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'flex-direction', _1: 'column'},
											_1: {ctor: '[]'}
										}
									}
								}),
							_1: {ctor: '[]'}
						}
					},
					{
						ctor: '::',
						_0: A2(
							_elm_lang$html$Html$div,
							{
								ctor: '::',
								_0: _elm_lang$html$Html_Attributes$id('debug-pane-clipboard'),
								_1: {
									ctor: '::',
									_0: _elm_lang$html$Html_Attributes$class('hbox'),
									_1: {
										ctor: '::',
										_0: _elm_lang$html$Html_Attributes$style(
											{
												ctor: '::',
												_0: {ctor: '_Tuple2', _0: 'flex-grow', _1: '2'},
												_1: {
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'width', _1: '100%'},
													_1: {
														ctor: '::',
														_0: {ctor: '_Tuple2', _0: 'min-height', _1: '2em'},
														_1: {
															ctor: '::',
															_0: {ctor: '_Tuple2', _0: 'display', _1: 'flex'},
															_1: {
																ctor: '::',
																_0: {ctor: '_Tuple2', _0: 'flex-direction', _1: 'row'},
																_1: {ctor: '[]'}
															}
														}
													}
												}
											}),
										_1: {ctor: '[]'}
									}
								}
							},
							{
								ctor: '::',
								_0: A2(
									_elm_lang$html$Html$div,
									{
										ctor: '::',
										_0: _elm_lang$html$Html_Attributes$style(
											{
												ctor: '::',
												_0: {ctor: '_Tuple2', _0: 'background-color', _1: 'whitesmoke'},
												_1: {
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'color', _1: 'gray'},
													_1: {
														ctor: '::',
														_0: {ctor: '_Tuple2', _0: 'width', _1: '10ex'},
														_1: {ctor: '[]'}
													}
												}
											}),
										_1: {ctor: '[]'}
									},
									{
										ctor: '::',
										_0: _elm_lang$html$Html$text('clipboard:'),
										_1: {ctor: '[]'}
									}),
								_1: {
									ctor: '::',
									_0: A2(
										_elm_lang$html$Html$div,
										{
											ctor: '::',
											_0: _elm_lang$html$Html_Attributes$style(
												{
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'overflow', _1: 'auto'},
													_1: {
														ctor: '::',
														_0: {ctor: '_Tuple2', _0: 'width', _1: '100%'},
														_1: {
															ctor: '::',
															_0: {ctor: '_Tuple2', _0: 'color', _1: 'gray'},
															_1: {ctor: '[]'}
														}
													}
												}),
											_1: {ctor: '[]'}
										},
										A2(
											_elm_lang$core$List$map,
											function (ln) {
												return A2(
													_elm_lang$html$Html$div,
													{
														ctor: '::',
														_0: _elm_lang$html$Html_Attributes$style(
															{
																ctor: '::',
																_0: {ctor: '_Tuple2', _0: 'border-bottom', _1: '1px dotted gainsboro'},
																_1: {
																	ctor: '::',
																	_0: {ctor: '_Tuple2', _0: 'height', _1: '1em'},
																	_1: {ctor: '[]'}
																}
															}),
														_1: {ctor: '[]'}
													},
													{
														ctor: '::',
														_0: _elm_lang$html$Html$text(ln),
														_1: {ctor: '[]'}
													});
											},
											_elm_lang$core$String$lines(model.core.copyStore))),
									_1: {ctor: '[]'}
								}
							}),
						_1: {
							ctor: '::',
							_0: A2(
								_elm_lang$html$Html$div,
								{
									ctor: '::',
									_0: _elm_lang$html$Html_Attributes$id('debug-pane-eventlog'),
									_1: {
										ctor: '::',
										_0: _elm_lang$html$Html_Attributes$class('hbox'),
										_1: {
											ctor: '::',
											_0: _elm_lang$html$Html_Attributes$style(
												{
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'flex-grow', _1: '8'},
													_1: {
														ctor: '::',
														_0: {ctor: '_Tuple2', _0: 'width', _1: '100%'},
														_1: {
															ctor: '::',
															_0: {ctor: '_Tuple2', _0: 'min-height', _1: '2em'},
															_1: {
																ctor: '::',
																_0: {ctor: '_Tuple2', _0: 'display', _1: 'flex'},
																_1: {
																	ctor: '::',
																	_0: {ctor: '_Tuple2', _0: 'flex-direction', _1: 'row'},
																	_1: {ctor: '[]'}
																}
															}
														}
													}
												}),
											_1: {ctor: '[]'}
										}
									}
								},
								{
									ctor: '::',
									_0: A2(
										_elm_lang$html$Html$div,
										{
											ctor: '::',
											_0: _elm_lang$html$Html_Attributes$style(
												{
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'background-color', _1: 'whitesmoke'},
													_1: {
														ctor: '::',
														_0: {ctor: '_Tuple2', _0: 'color', _1: 'gray'},
														_1: {
															ctor: '::',
															_0: {ctor: '_Tuple2', _0: 'width', _1: '10ex'},
															_1: {ctor: '[]'}
														}
													}
												}),
											_1: {ctor: '[]'}
										},
										{
											ctor: '::',
											_0: A2(
												_elm_lang$html$Html$div,
												{ctor: '[]'},
												{
													ctor: '::',
													_0: _elm_lang$html$Html$text('eventlog:'),
													_1: {ctor: '[]'}
												}),
											_1: {
												ctor: '::',
												_0: A2(
													_elm_lang$html$Html$div,
													{
														ctor: '::',
														_0: _elm_lang$html$Html_Events$onClick(
															_minekoa$elm_text_editor$EditorDebugger$SetEventlogEnable(
																_elm_lang$core$Native_Utils.eq(model.event_log, _elm_lang$core$Maybe$Nothing))),
														_1: {
															ctor: '::',
															_0: _elm_lang$html$Html_Attributes$style(
																{
																	ctor: '::',
																	_0: {ctor: '_Tuple2', _0: 'border', _1: '1px solid gray'},
																	_1: {
																		ctor: '::',
																		_0: {
																			ctor: '_Tuple2',
																			_0: 'opacity',
																			_1: _elm_lang$core$Native_Utils.eq(model.event_log, _elm_lang$core$Maybe$Nothing) ? '0.5' : '1.0'
																		},
																		_1: {
																			ctor: '::',
																			_0: {ctor: '_Tuple2', _0: 'margin', _1: '1ex'},
																			_1: {
																				ctor: '::',
																				_0: {ctor: '_Tuple2', _0: 'text-align', _1: 'center'},
																				_1: {ctor: '[]'}
																			}
																		}
																	}
																}),
															_1: {ctor: '[]'}
														}
													},
													{
														ctor: '::',
														_0: _elm_lang$html$Html$text(
															_elm_lang$core$Native_Utils.eq(model.event_log, _elm_lang$core$Maybe$Nothing) ? 'OFF' : 'ON'),
														_1: {ctor: '[]'}
													}),
												_1: {ctor: '[]'}
											}
										}),
									_1: {
										ctor: '::',
										_0: A2(
											_elm_lang$html$Html$div,
											{
												ctor: '::',
												_0: _elm_lang$html$Html_Attributes$style(
													{
														ctor: '::',
														_0: {ctor: '_Tuple2', _0: 'overflow', _1: 'scroll'},
														_1: {
															ctor: '::',
															_0: {ctor: '_Tuple2', _0: 'width', _1: 'calc( 100% - 3px )'},
															_1: {
																ctor: '::',
																_0: {ctor: '_Tuple2', _0: 'border-top', _1: '3px solid whitesmoke'},
																_1: {
																	ctor: '::',
																	_0: {ctor: '_Tuple2', _0: 'flex-grow', _1: '8'},
																	_1: {
																		ctor: '::',
																		_0: {ctor: '_Tuple2', _0: 'color', _1: 'gray'},
																		_1: {ctor: '[]'}
																	}
																}
															}
														}
													}),
												_1: {ctor: '[]'}
											},
											A2(
												_elm_lang$core$List$map,
												function (ln) {
													return A2(
														_elm_lang$html$Html$span,
														{
															ctor: '::',
															_0: _elm_lang$html$Html_Attributes$style(
																{
																	ctor: '::',
																	_0: {ctor: '_Tuple2', _0: 'margin-right', _1: '0.2em'},
																	_1: {ctor: '[]'}
																}),
															_1: {ctor: '[]'}
														},
														{
															ctor: '::',
															_0: _elm_lang$html$Html$text(ln),
															_1: {ctor: '[]'}
														});
												},
												A2(
													_elm_lang$core$Maybe$withDefault,
													{ctor: '[]'},
													model.event_log))),
										_1: {ctor: '[]'}
									}
								}),
							_1: {ctor: '[]'}
						}
					}),
				_1: {ctor: '[]'}
			}
		});
};

var _norpan$elm_file_reader$FileReader$handleFiles = '\n    var fileObjects = [];\n    var index = 0;\n    var reader = new FileReader();\n    var dataFormat = event.target.dataset.format;\n    var encoding = event.target.dataset.encoding;\n    reader.onload = function() {\n        var data;\n        switch(dataFormat) {\n            case \'DataURL\':\n            case \'Text\':\n                data = reader.result;\n                break;\n            case \'Base64\':\n                data = reader.result.split(\',\')[1];\n                break;\n        }\n        var lastModified = files[index].lastModified;\n        if (!lastModified) {\n          lastModified = files[index].lastModifiedDate.getTime();\n        }\n        var result =\n            { lastModified: lastModified\n            , name: files[index].name\n            , size: files[index].size\n            , mimeType: files[index].type\n            , dataFormat: dataFormat\n            , encoding: encoding\n            , data: data\n            };\n        fileObjects.push(result);\n        index++;\n        readOne();\n    }\n    reader.onerror = function () {\n        var lastModified = files[index].lastModified;\n        if (!lastModified) {\n          lastModified = files[index].lastModifiedDate.getTime();\n        }\n        var result =\n            { lastModified: lastModified\n            , name: files[index].name\n            , size: files[index].size\n            , mimeType: files[index].type\n            , dataFormat: dataFormat\n            , encoding: encoding\n            , errorCode: reader.error.code\n            , errorName: reader.error.name\n            , errorMessage: reader.error.message\n            };\n        fileObjects.push(result);\n        index++;\n        readOne();\n    }\n    function readOne() {\n        var file = files[index];\n        if (file) {\n            switch(dataFormat) {\n                case \'DataURL\':\n                case \'Base64\':\n                    reader.readAsDataURL(file);\n                    break;\n                case \'Text\':\n                    reader.readAsText(file, encoding);\n                    break;\n            }\n        } else {\n            if (fileObjects.length > 0) {\n                var filesEvent;\n                try {\n                  filesEvent = new CustomEvent(\"files\", { detail: fileObjects });\n                } catch(e) {\n                  filesEvent = document.createEvent(\"CustomEvent\");\n                  filesEvent.initCustomEvent(\"files\", false, false, fileObjects);\n                }\n                event.target.dispatchEvent(filesEvent);\n            }\n        }\n      }\n    readOne();\n';
var _norpan$elm_file_reader$FileReader$onChangeHandler = A2(_elm_lang$core$Basics_ops['++'], '\n    event.preventDefault();\n    event.stopPropagation();\n    var files = event.target.files;\n    ', _norpan$elm_file_reader$FileReader$handleFiles);
var _norpan$elm_file_reader$FileReader$onDropHandler = A2(_elm_lang$core$Basics_ops['++'], '\n    event.preventDefault();\n    event.stopPropagation();\n    var files = event.dataTransfer.files;\n    ', _norpan$elm_file_reader$FileReader$handleFiles);
var _norpan$elm_file_reader$FileReader$dataFormatAttributes = function (dataFormat) {
	var _p0 = dataFormat;
	switch (_p0.ctor) {
		case 'DataURL':
			return {
				ctor: '::',
				_0: A2(_elm_lang$html$Html_Attributes$attribute, 'data-format', 'DataURL'),
				_1: {ctor: '[]'}
			};
		case 'Base64':
			return {
				ctor: '::',
				_0: A2(_elm_lang$html$Html_Attributes$attribute, 'data-format', 'Base64'),
				_1: {ctor: '[]'}
			};
		default:
			return {
				ctor: '::',
				_0: A2(_elm_lang$html$Html_Attributes$attribute, 'data-format', 'Text'),
				_1: {
					ctor: '::',
					_0: A2(_elm_lang$html$Html_Attributes$attribute, 'data-encoding', _p0._0),
					_1: {ctor: '[]'}
				}
			};
	}
};
var _norpan$elm_file_reader$FileReader$default = F2(
	function (a, decoder) {
		return _elm_lang$core$Json_Decode$oneOf(
			{
				ctor: '::',
				_0: decoder,
				_1: {
					ctor: '::',
					_0: _elm_lang$core$Json_Decode$succeed(a),
					_1: {ctor: '[]'}
				}
			});
	});
var _norpan$elm_file_reader$FileReader$File = F6(
	function (a, b, c, d, e, f) {
		return {lastModified: a, name: b, size: c, mimeType: d, dataFormat: e, data: f};
	});
var _norpan$elm_file_reader$FileReader$Error = F3(
	function (a, b, c) {
		return {code: a, name: b, message: c};
	});
var _norpan$elm_file_reader$FileReader$errorDecoder = A4(
	_elm_lang$core$Json_Decode$map3,
	_norpan$elm_file_reader$FileReader$Error,
	A2(
		_norpan$elm_file_reader$FileReader$default,
		0,
		A2(_elm_lang$core$Json_Decode$field, 'errorCode', _elm_lang$core$Json_Decode$int)),
	A2(
		_norpan$elm_file_reader$FileReader$default,
		'',
		A2(_elm_lang$core$Json_Decode$field, 'errorName', _elm_lang$core$Json_Decode$string)),
	A2(
		_norpan$elm_file_reader$FileReader$default,
		'',
		A2(_elm_lang$core$Json_Decode$field, 'errorMessage', _elm_lang$core$Json_Decode$string)));
var _norpan$elm_file_reader$FileReader$Text = function (a) {
	return {ctor: 'Text', _0: a};
};
var _norpan$elm_file_reader$FileReader$Base64 = {ctor: 'Base64'};
var _norpan$elm_file_reader$FileReader$DataURL = {ctor: 'DataURL'};
var _norpan$elm_file_reader$FileReader$dataFormatDecoder = A2(
	_elm_lang$core$Json_Decode$andThen,
	function (dataFormat) {
		var _p1 = dataFormat;
		switch (_p1) {
			case 'DataURL':
				return _elm_lang$core$Json_Decode$succeed(_norpan$elm_file_reader$FileReader$DataURL);
			case 'Base64':
				return _elm_lang$core$Json_Decode$succeed(_norpan$elm_file_reader$FileReader$Base64);
			case 'Text':
				return A2(
					_elm_lang$core$Json_Decode$map,
					_norpan$elm_file_reader$FileReader$Text,
					A2(_elm_lang$core$Json_Decode$field, 'encoding', _elm_lang$core$Json_Decode$string));
			default:
				return _elm_lang$core$Json_Decode$fail(
					A2(_elm_lang$core$Basics_ops['++'], 'Unknown data format: ', dataFormat));
		}
	},
	A2(_elm_lang$core$Json_Decode$field, 'dataFormat', _elm_lang$core$Json_Decode$string));
var _norpan$elm_file_reader$FileReader$fileDecoder = A7(
	_elm_lang$core$Json_Decode$map6,
	_norpan$elm_file_reader$FileReader$File,
	A2(_elm_lang$core$Json_Decode$field, 'lastModified', _elm_lang$core$Json_Decode$float),
	A2(_elm_lang$core$Json_Decode$field, 'name', _elm_lang$core$Json_Decode$string),
	A2(_elm_lang$core$Json_Decode$field, 'size', _elm_lang$core$Json_Decode$int),
	A2(_elm_lang$core$Json_Decode$field, 'mimeType', _elm_lang$core$Json_Decode$string),
	_norpan$elm_file_reader$FileReader$dataFormatDecoder,
	_elm_lang$core$Json_Decode$oneOf(
		{
			ctor: '::',
			_0: A2(
				_elm_lang$core$Json_Decode$map,
				_elm_lang$core$Result$Ok,
				A2(_elm_lang$core$Json_Decode$field, 'data', _elm_lang$core$Json_Decode$string)),
			_1: {
				ctor: '::',
				_0: A2(_elm_lang$core$Json_Decode$map, _elm_lang$core$Result$Err, _norpan$elm_file_reader$FileReader$errorDecoder),
				_1: {ctor: '[]'}
			}
		}));
var _norpan$elm_file_reader$FileReader$fileInput = F2(
	function (dataFormat, fileMsg) {
		return A2(
			_elm_lang$core$Basics_ops['++'],
			{
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$type_('file'),
				_1: {
					ctor: '::',
					_0: A2(_elm_lang$html$Html_Attributes$attribute, 'onchange', _norpan$elm_file_reader$FileReader$onChangeHandler),
					_1: {
						ctor: '::',
						_0: A2(
							_elm_lang$html$Html_Events$on,
							'files',
							A2(
								_elm_lang$core$Json_Decode$map,
								fileMsg,
								A2(
									_elm_lang$core$Json_Decode$field,
									'detail',
									A2(_elm_lang$core$Json_Decode$index, 0, _norpan$elm_file_reader$FileReader$fileDecoder)))),
						_1: {ctor: '[]'}
					}
				}
			},
			_norpan$elm_file_reader$FileReader$dataFormatAttributes(dataFormat));
	});
var _norpan$elm_file_reader$FileReader$filesInput = F2(
	function (dataFormat, filesMsg) {
		return A2(
			_elm_lang$core$Basics_ops['++'],
			{
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$type_('file'),
				_1: {
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$multiple(true),
					_1: {
						ctor: '::',
						_0: A2(_elm_lang$html$Html_Attributes$attribute, 'onchange', _norpan$elm_file_reader$FileReader$onChangeHandler),
						_1: {
							ctor: '::',
							_0: A2(
								_elm_lang$html$Html_Events$on,
								'files',
								A2(
									_elm_lang$core$Json_Decode$map,
									filesMsg,
									A2(
										_elm_lang$core$Json_Decode$field,
										'detail',
										_elm_lang$core$Json_Decode$list(_norpan$elm_file_reader$FileReader$fileDecoder)))),
							_1: {ctor: '[]'}
						}
					}
				}
			},
			_norpan$elm_file_reader$FileReader$dataFormatAttributes(dataFormat));
	});
var _norpan$elm_file_reader$FileReader$dropZone = function (_p2) {
	var _p3 = _p2;
	return A2(
		_elm_lang$core$Basics_ops['++'],
		{
			ctor: '::',
			_0: A3(
				_elm_lang$html$Html_Events$onWithOptions,
				'dragenter',
				{preventDefault: true, stopPropagation: true},
				_elm_lang$core$Json_Decode$succeed(_p3.enterMsg)),
			_1: {
				ctor: '::',
				_0: A3(
					_elm_lang$html$Html_Events$onWithOptions,
					'dragleave',
					{preventDefault: true, stopPropagation: true},
					_elm_lang$core$Json_Decode$succeed(_p3.leaveMsg)),
				_1: {
					ctor: '::',
					_0: A2(_elm_lang$html$Html_Attributes$attribute, 'ondragover', 'event.preventDefault(); event.stopPropagation();'),
					_1: {
						ctor: '::',
						_0: A2(_elm_lang$html$Html_Attributes$attribute, 'ondrop', _norpan$elm_file_reader$FileReader$onDropHandler),
						_1: {
							ctor: '::',
							_0: A2(
								_elm_lang$html$Html_Events$on,
								'files',
								A2(
									_elm_lang$core$Json_Decode$map,
									_p3.filesMsg,
									A2(
										_elm_lang$core$Json_Decode$field,
										'detail',
										_elm_lang$core$Json_Decode$list(_norpan$elm_file_reader$FileReader$fileDecoder)))),
							_1: {ctor: '[]'}
						}
					}
				}
			}
		},
		_norpan$elm_file_reader$FileReader$dataFormatAttributes(_p3.dataFormat));
};

var _minekoa$elm_text_editor$Filer$Model = F2(
	function (a, b) {
		return {selectedSubMenu: a, inDropZone: b};
	});
var _minekoa$elm_text_editor$Filer$Save = {ctor: 'Save'};
var _minekoa$elm_text_editor$Filer$Load = {ctor: 'Load'};
var _minekoa$elm_text_editor$Filer$init = {selectedSubMenu: _minekoa$elm_text_editor$Filer$Load, inDropZone: false};
var _minekoa$elm_text_editor$Filer$ReadFile = function (a) {
	return {ctor: 'ReadFile', _0: a};
};
var _minekoa$elm_text_editor$Filer$update = F2(
	function (msg, model) {
		var _p0 = msg;
		switch (_p0.ctor) {
			case 'TouchSaveSubMenu':
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{selectedSubMenu: _minekoa$elm_text_editor$Filer$Save}),
					_1: _elm_lang$core$Platform_Cmd$none
				};
			case 'TouchLoadSubMenu':
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{selectedSubMenu: _minekoa$elm_text_editor$Filer$Load}),
					_1: _elm_lang$core$Platform_Cmd$none
				};
			case 'DropZoneEntered':
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{inDropZone: true}),
					_1: _elm_lang$core$Platform_Cmd$none
				};
			case 'DropZoneLeaved':
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{inDropZone: false}),
					_1: _elm_lang$core$Platform_Cmd$none
				};
			case 'FilesDropped':
				var _p1 = _elm_lang$core$List$head(_p0._0);
				if (_p1.ctor === 'Just') {
					return {
						ctor: '_Tuple2',
						_0: _elm_lang$core$Native_Utils.update(
							model,
							{inDropZone: false}),
						_1: A2(
							_elm_lang$core$Task$perform,
							_minekoa$elm_text_editor$Filer$ReadFile,
							_elm_lang$core$Task$succeed(_p1._0))
					};
				} else {
					return {ctor: '_Tuple2', _0: model, _1: _elm_lang$core$Platform_Cmd$none};
				}
			default:
				return {ctor: '_Tuple2', _0: model, _1: _elm_lang$core$Platform_Cmd$none};
		}
	});
var _minekoa$elm_text_editor$Filer$FilesDropped = function (a) {
	return {ctor: 'FilesDropped', _0: a};
};
var _minekoa$elm_text_editor$Filer$DropZoneLeaved = {ctor: 'DropZoneLeaved'};
var _minekoa$elm_text_editor$Filer$DropZoneEntered = {ctor: 'DropZoneEntered'};
var _minekoa$elm_text_editor$Filer$fileLoadView = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		A2(
			_elm_lang$core$Basics_ops['++'],
			{
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$class('filer-dropzone'),
				_1: {
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$style(
						model.inDropZone ? {
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'background', _1: 'lightblue'},
							_1: {ctor: '[]'}
						} : {ctor: '[]'}),
					_1: {ctor: '[]'}
				}
			},
			_norpan$elm_file_reader$FileReader$dropZone(
				{
					dataFormat: _norpan$elm_file_reader$FileReader$Text('utf-8'),
					enterMsg: _minekoa$elm_text_editor$Filer$DropZoneEntered,
					leaveMsg: _minekoa$elm_text_editor$Filer$DropZoneLeaved,
					filesMsg: _minekoa$elm_text_editor$Filer$FilesDropped
				})),
		{
			ctor: '::',
			_0: A2(
				_elm_lang$html$Html$div,
				{
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$class('filer-inner'),
					_1: {ctor: '[]'}
				},
				{
					ctor: '::',
					_0: _elm_lang$html$Html$text('Drop a file here'),
					_1: {
						ctor: '::',
						_0: A2(
							_elm_lang$html$Html$br,
							{ctor: '[]'},
							{ctor: '[]'}),
						_1: {
							ctor: '::',
							_0: _elm_lang$html$Html$text('or..'),
							_1: {
								ctor: '::',
								_0: A2(
									_elm_lang$html$Html$br,
									{ctor: '[]'},
									{ctor: '[]'}),
								_1: {
									ctor: '::',
									_0: A2(
										_elm_lang$html$Html$label,
										{
											ctor: '::',
											_0: _elm_lang$html$Html_Attributes$class('file_input_label'),
											_1: {ctor: '[]'}
										},
										{
											ctor: '::',
											_0: _elm_lang$html$Html$text('Select a file from PC'),
											_1: {
												ctor: '::',
												_0: A2(
													_elm_lang$html$Html$input,
													A2(
														_norpan$elm_file_reader$FileReader$fileInput,
														_norpan$elm_file_reader$FileReader$Text('utf-8'),
														_minekoa$elm_text_editor$Filer$ReadFile),
													{ctor: '[]'}),
												_1: {ctor: '[]'}
											}
										}),
									_1: {ctor: '[]'}
								}
							}
						}
					}
				}),
			_1: {ctor: '[]'}
		});
};
var _minekoa$elm_text_editor$Filer$menuPalette = function (model) {
	var _p2 = model.selectedSubMenu;
	if (_p2.ctor === 'Load') {
		return A2(
			_elm_lang$html$Html$div,
			{
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$class('menu-palette'),
				_1: {ctor: '[]'}
			},
			{
				ctor: '::',
				_0: _minekoa$elm_text_editor$Filer$fileLoadView(model),
				_1: {ctor: '[]'}
			});
	} else {
		return A2(
			_elm_lang$html$Html$div,
			{
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$class('menu-palette'),
				_1: {ctor: '[]'}
			},
			{
				ctor: '::',
				_0: _elm_lang$html$Html$text('save'),
				_1: {ctor: '[]'}
			});
	}
};
var _minekoa$elm_text_editor$Filer$TouchSaveSubMenu = {ctor: 'TouchSaveSubMenu'};
var _minekoa$elm_text_editor$Filer$TouchLoadSubMenu = {ctor: 'TouchLoadSubMenu'};
var _minekoa$elm_text_editor$Filer$menuItemsView = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$class('menu-itemlist'),
			_1: {ctor: '[]'}
		},
		{
			ctor: '::',
			_0: A2(
				_elm_lang$html$Html$div,
				{
					ctor: '::',
					_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$Filer$TouchLoadSubMenu),
					_1: {
						ctor: '::',
						_0: _elm_lang$html$Html_Attributes$class(
							_elm_lang$core$Native_Utils.eq(model.selectedSubMenu, _minekoa$elm_text_editor$Filer$Load) ? 'menu-item-active' : 'menu-item'),
						_1: {ctor: '[]'}
					}
				},
				{
					ctor: '::',
					_0: A2(
						_elm_lang$html$Html$span,
						{ctor: '[]'},
						{
							ctor: '::',
							_0: _elm_lang$html$Html$text('Load'),
							_1: {ctor: '[]'}
						}),
					_1: {ctor: '[]'}
				}),
			_1: {
				ctor: '::',
				_0: A2(
					_elm_lang$html$Html$div,
					{
						ctor: '::',
						_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$Filer$TouchSaveSubMenu),
						_1: {
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$class(
								_elm_lang$core$Native_Utils.eq(model.selectedSubMenu, _minekoa$elm_text_editor$Filer$Save) ? 'menu-item-active' : 'menu-item'),
							_1: {ctor: '[]'}
						}
					},
					{
						ctor: '::',
						_0: A2(
							_elm_lang$html$Html$span,
							{ctor: '[]'},
							{
								ctor: '::',
								_0: _elm_lang$html$Html$text('Save '),
								_1: {ctor: '[]'}
							}),
						_1: {ctor: '[]'}
					}),
				_1: {ctor: '[]'}
			}
		});
};
var _minekoa$elm_text_editor$Filer$view = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$class('filer-menu'),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$class('menu-root'),
				_1: {
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$style(
						{
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'flex-grow', _1: '2'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'min-height', _1: '17em'},
								_1: {ctor: '[]'}
							}
						}),
					_1: {ctor: '[]'}
				}
			}
		},
		{
			ctor: '::',
			_0: _minekoa$elm_text_editor$Filer$menuItemsView(model),
			_1: {
				ctor: '::',
				_0: _minekoa$elm_text_editor$Filer$menuPalette(model),
				_1: {ctor: '[]'}
			}
		});
};

var _minekoa$elm_text_editor$TextEditor_Commands$updateMap = F2(
	function (model, _p0) {
		var _p1 = _p0;
		return {
			ctor: '_Tuple2',
			_0: _elm_lang$core$Native_Utils.update(
				model,
				{core: _p1._0}),
			_1: A2(_elm_lang$core$Platform_Cmd$map, _minekoa$elm_text_editor$TextEditor$CoreMsg, _p1._1)
		};
	});
var _minekoa$elm_text_editor$TextEditor_Commands$moveForward = function (model) {
	return A2(
		_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
		model,
		_minekoa$elm_text_editor$TextEditor_Core_Commands$moveForward(model.core));
};
var _minekoa$elm_text_editor$TextEditor_Commands$moveBackward = function (model) {
	return A2(
		_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
		model,
		_minekoa$elm_text_editor$TextEditor_Core_Commands$moveBackward(model.core));
};
var _minekoa$elm_text_editor$TextEditor_Commands$movePrevios = function (model) {
	return A2(
		_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
		model,
		_minekoa$elm_text_editor$TextEditor_Core_Commands$movePrevios(model.core));
};
var _minekoa$elm_text_editor$TextEditor_Commands$moveNext = function (model) {
	return A2(
		_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
		model,
		_minekoa$elm_text_editor$TextEditor_Core_Commands$moveNext(model.core));
};
var _minekoa$elm_text_editor$TextEditor_Commands$moveBOL = function (model) {
	return A2(
		_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
		model,
		_minekoa$elm_text_editor$TextEditor_Core_Commands$moveBOL(model.core));
};
var _minekoa$elm_text_editor$TextEditor_Commands$moveEOL = function (model) {
	return A2(
		_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
		model,
		_minekoa$elm_text_editor$TextEditor_Core_Commands$moveEOL(model.core));
};
var _minekoa$elm_text_editor$TextEditor_Commands$moveAt = F2(
	function (pos, model) {
		return A2(
			_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
			model,
			A2(_minekoa$elm_text_editor$TextEditor_Core_Commands$moveAt, pos, model.core));
	});
var _minekoa$elm_text_editor$TextEditor_Commands$selectBackward = function (model) {
	return A2(
		_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
		model,
		_minekoa$elm_text_editor$TextEditor_Core_Commands$selectBackward(model.core));
};
var _minekoa$elm_text_editor$TextEditor_Commands$selectForward = function (model) {
	return A2(
		_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
		model,
		_minekoa$elm_text_editor$TextEditor_Core_Commands$selectForward(model.core));
};
var _minekoa$elm_text_editor$TextEditor_Commands$selectPrevios = function (model) {
	return A2(
		_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
		model,
		_minekoa$elm_text_editor$TextEditor_Core_Commands$selectPrevios(model.core));
};
var _minekoa$elm_text_editor$TextEditor_Commands$selectNext = function (model) {
	return A2(
		_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
		model,
		_minekoa$elm_text_editor$TextEditor_Core_Commands$selectNext(model.core));
};
var _minekoa$elm_text_editor$TextEditor_Commands$insert = F2(
	function (text, model) {
		return A2(
			_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
			model,
			A2(_minekoa$elm_text_editor$TextEditor_Core_Commands$insert, text, model.core));
	});
var _minekoa$elm_text_editor$TextEditor_Commands$backspace = function (model) {
	return A2(
		_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
		model,
		_minekoa$elm_text_editor$TextEditor_Core_Commands$backspace(model.core));
};
var _minekoa$elm_text_editor$TextEditor_Commands$delete = function (model) {
	return A2(
		_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
		model,
		_minekoa$elm_text_editor$TextEditor_Core_Commands$delete(model.core));
};
var _minekoa$elm_text_editor$TextEditor_Commands$undo = function (model) {
	return A2(
		_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
		model,
		_minekoa$elm_text_editor$TextEditor_Core_Commands$undo(model.core));
};
var _minekoa$elm_text_editor$TextEditor_Commands$copy = function (model) {
	return A2(
		_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
		model,
		_minekoa$elm_text_editor$TextEditor_Core_Commands$copy(model.core));
};
var _minekoa$elm_text_editor$TextEditor_Commands$cut = function (model) {
	return A2(
		_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
		model,
		_minekoa$elm_text_editor$TextEditor_Core_Commands$cut(model.core));
};
var _minekoa$elm_text_editor$TextEditor_Commands$paste = function (model) {
	return A2(
		_minekoa$elm_text_editor$TextEditor_Commands$updateMap,
		model,
		A2(_minekoa$elm_text_editor$TextEditor_Core_Commands$paste, model.core.copyStore, model.core));
};

var _minekoa$elm_text_editor$SoftwareKeyboard$pad = function (n) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$class('kbd_pad'),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$style(
					{
						ctor: '::',
						_0: {
							ctor: '_Tuple2',
							_0: 'width',
							_1: A3(
								_elm_lang$core$Basics$flip,
								F2(
									function (x, y) {
										return A2(_elm_lang$core$Basics_ops['++'], x, y);
									}),
								'em',
								_elm_lang$core$Basics$toString((n * 0.5) * 1.5))
						},
						_1: {ctor: '[]'}
					}),
				_1: {ctor: '[]'}
			}
		},
		{ctor: '[]'});
};
var _minekoa$elm_text_editor$SoftwareKeyboard$update = F3(
	function (msg, model, editor) {
		var _p0 = msg;
		switch (_p0.ctor) {
			case 'ChangeMode':
				return {
					ctor: '_Tuple2',
					_0: {
						ctor: '_Tuple2',
						_0: _elm_lang$core$Native_Utils.update(
							model,
							{mode: _p0._0}),
						_1: _elm_lang$core$Platform_Cmd$none
					},
					_1: {ctor: '_Tuple2', _0: editor, _1: _elm_lang$core$Platform_Cmd$none}
				};
			case 'MoveForward':
				return {
					ctor: '_Tuple2',
					_0: {ctor: '_Tuple2', _0: model, _1: _elm_lang$core$Platform_Cmd$none},
					_1: _minekoa$elm_text_editor$TextEditor_Commands$moveForward(editor)
				};
			case 'MoveBackword':
				return {
					ctor: '_Tuple2',
					_0: {ctor: '_Tuple2', _0: model, _1: _elm_lang$core$Platform_Cmd$none},
					_1: _minekoa$elm_text_editor$TextEditor_Commands$moveBackward(editor)
				};
			case 'MovePrevios':
				return {
					ctor: '_Tuple2',
					_0: {ctor: '_Tuple2', _0: model, _1: _elm_lang$core$Platform_Cmd$none},
					_1: _minekoa$elm_text_editor$TextEditor_Commands$movePrevios(editor)
				};
			case 'MoveNext':
				return {
					ctor: '_Tuple2',
					_0: {ctor: '_Tuple2', _0: model, _1: _elm_lang$core$Platform_Cmd$none},
					_1: _minekoa$elm_text_editor$TextEditor_Commands$moveNext(editor)
				};
			case 'Insert':
				return {
					ctor: '_Tuple2',
					_0: {ctor: '_Tuple2', _0: model, _1: _elm_lang$core$Platform_Cmd$none},
					_1: A2(_minekoa$elm_text_editor$TextEditor_Commands$insert, _p0._0, editor)
				};
			case 'Backspace':
				return {
					ctor: '_Tuple2',
					_0: {ctor: '_Tuple2', _0: model, _1: _elm_lang$core$Platform_Cmd$none},
					_1: _minekoa$elm_text_editor$TextEditor_Commands$backspace(editor)
				};
			case 'Delete':
				return {
					ctor: '_Tuple2',
					_0: {ctor: '_Tuple2', _0: model, _1: _elm_lang$core$Platform_Cmd$none},
					_1: _minekoa$elm_text_editor$TextEditor_Commands$delete(editor)
				};
			case 'Copy':
				return {
					ctor: '_Tuple2',
					_0: {ctor: '_Tuple2', _0: model, _1: _elm_lang$core$Platform_Cmd$none},
					_1: _minekoa$elm_text_editor$TextEditor_Commands$copy(editor)
				};
			case 'Cut':
				return {
					ctor: '_Tuple2',
					_0: {ctor: '_Tuple2', _0: model, _1: _elm_lang$core$Platform_Cmd$none},
					_1: _minekoa$elm_text_editor$TextEditor_Commands$cut(editor)
				};
			case 'Paste':
				return {
					ctor: '_Tuple2',
					_0: {ctor: '_Tuple2', _0: model, _1: _elm_lang$core$Platform_Cmd$none},
					_1: _minekoa$elm_text_editor$TextEditor_Commands$paste(editor)
				};
			default:
				return {
					ctor: '_Tuple2',
					_0: {ctor: '_Tuple2', _0: model, _1: _elm_lang$core$Platform_Cmd$none},
					_1: _minekoa$elm_text_editor$TextEditor_Commands$undo(editor)
				};
		}
	});
var _minekoa$elm_text_editor$SoftwareKeyboard$Model = function (a) {
	return {mode: a};
};
var _minekoa$elm_text_editor$SoftwareKeyboard$Katakana = {ctor: 'Katakana'};
var _minekoa$elm_text_editor$SoftwareKeyboard$Hiragana = {ctor: 'Hiragana'};
var _minekoa$elm_text_editor$SoftwareKeyboard$SmallLetter = {ctor: 'SmallLetter'};
var _minekoa$elm_text_editor$SoftwareKeyboard$init = _minekoa$elm_text_editor$SoftwareKeyboard$Model(_minekoa$elm_text_editor$SoftwareKeyboard$SmallLetter);
var _minekoa$elm_text_editor$SoftwareKeyboard$CapitalLetter = {ctor: 'CapitalLetter'};
var _minekoa$elm_text_editor$SoftwareKeyboard$Undo = {ctor: 'Undo'};
var _minekoa$elm_text_editor$SoftwareKeyboard$Paste = {ctor: 'Paste'};
var _minekoa$elm_text_editor$SoftwareKeyboard$Cut = {ctor: 'Cut'};
var _minekoa$elm_text_editor$SoftwareKeyboard$Copy = {ctor: 'Copy'};
var _minekoa$elm_text_editor$SoftwareKeyboard$Delete = {ctor: 'Delete'};
var _minekoa$elm_text_editor$SoftwareKeyboard$editcmdkey = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$class('kbd_editcmd'),
			_1: {ctor: '[]'}
		},
		{
			ctor: '::',
			_0: A2(
				_elm_lang$html$Html$div,
				{
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$class('kbd_button'),
					_1: {
						ctor: '::',
						_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$Undo),
						_1: {ctor: '[]'}
					}
				},
				{
					ctor: '::',
					_0: _elm_lang$html$Html$text('undo'),
					_1: {ctor: '[]'}
				}),
			_1: {
				ctor: '::',
				_0: A2(
					_elm_lang$html$Html$div,
					{
						ctor: '::',
						_0: _elm_lang$html$Html_Attributes$class('kbd_button'),
						_1: {
							ctor: '::',
							_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$Delete),
							_1: {ctor: '[]'}
						}
					},
					{
						ctor: '::',
						_0: _elm_lang$html$Html$text('Del'),
						_1: {ctor: '[]'}
					}),
				_1: {
					ctor: '::',
					_0: A2(
						_elm_lang$html$Html$div,
						{
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$class('kbd_button'),
							_1: {
								ctor: '::',
								_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$Cut),
								_1: {ctor: '[]'}
							}
						},
						{
							ctor: '::',
							_0: _elm_lang$html$Html$text('cut'),
							_1: {ctor: '[]'}
						}),
					_1: {
						ctor: '::',
						_0: A2(
							_elm_lang$html$Html$div,
							{
								ctor: '::',
								_0: _elm_lang$html$Html_Attributes$class('kbd_button'),
								_1: {
									ctor: '::',
									_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$Copy),
									_1: {ctor: '[]'}
								}
							},
							{
								ctor: '::',
								_0: _elm_lang$html$Html$text('copy'),
								_1: {ctor: '[]'}
							}),
						_1: {
							ctor: '::',
							_0: A2(
								_elm_lang$html$Html$div,
								{
									ctor: '::',
									_0: _elm_lang$html$Html_Attributes$class('kbd_button'),
									_1: {
										ctor: '::',
										_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$Paste),
										_1: {ctor: '[]'}
									}
								},
								{
									ctor: '::',
									_0: _elm_lang$html$Html$text('paste'),
									_1: {ctor: '[]'}
								}),
							_1: {ctor: '[]'}
						}
					}
				}
			}
		});
};
var _minekoa$elm_text_editor$SoftwareKeyboard$Backspace = {ctor: 'Backspace'};
var _minekoa$elm_text_editor$SoftwareKeyboard$backspaceKey = A2(
	_elm_lang$html$Html$div,
	{
		ctor: '::',
		_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
		_1: {
			ctor: '::',
			_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$Backspace),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$style(
					{
						ctor: '::',
						_0: {
							ctor: '_Tuple2',
							_0: 'width',
							_1: A3(
								_elm_lang$core$Basics$flip,
								F2(
									function (x, y) {
										return A2(_elm_lang$core$Basics_ops['++'], x, y);
									}),
								'em',
								_elm_lang$core$Basics$toString(1.5 * 1.5))
						},
						_1: {ctor: '[]'}
					}),
				_1: {ctor: '[]'}
			}
		}
	},
	{
		ctor: '::',
		_0: _elm_lang$html$Html$text('BS'),
		_1: {ctor: '[]'}
	});
var _minekoa$elm_text_editor$SoftwareKeyboard$Insert = function (a) {
	return {ctor: 'Insert', _0: a};
};
var _minekoa$elm_text_editor$SoftwareKeyboard$key = function (s) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Events$onClick(
					_minekoa$elm_text_editor$SoftwareKeyboard$Insert(s)),
				_1: {
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$style(
						{
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
							_1: {ctor: '[]'}
						}),
					_1: {ctor: '[]'}
				}
			}
		},
		{
			ctor: '::',
			_0: _elm_lang$html$Html$text(s),
			_1: {ctor: '[]'}
		});
};
var _minekoa$elm_text_editor$SoftwareKeyboard$enterKey = A2(
	_elm_lang$html$Html$div,
	{
		ctor: '::',
		_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
		_1: {
			ctor: '::',
			_0: _elm_lang$html$Html_Events$onClick(
				_minekoa$elm_text_editor$SoftwareKeyboard$Insert('\n')),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$style(
					{
						ctor: '::',
						_0: {
							ctor: '_Tuple2',
							_0: 'width',
							_1: A3(
								_elm_lang$core$Basics$flip,
								F2(
									function (x, y) {
										return A2(_elm_lang$core$Basics_ops['++'], x, y);
									}),
								'em',
								_elm_lang$core$Basics$toString(1.5 * 1.5))
						},
						_1: {ctor: '[]'}
					}),
				_1: {ctor: '[]'}
			}
		}
	},
	{
		ctor: '::',
		_0: _elm_lang$html$Html$text('⏎'),
		_1: {ctor: '[]'}
	});
var _minekoa$elm_text_editor$SoftwareKeyboard$tabKey = A2(
	_elm_lang$html$Html$div,
	{
		ctor: '::',
		_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
		_1: {
			ctor: '::',
			_0: _elm_lang$html$Html_Events$onClick(
				_minekoa$elm_text_editor$SoftwareKeyboard$Insert('\t')),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$style(
					{
						ctor: '::',
						_0: {
							ctor: '_Tuple2',
							_0: 'width',
							_1: A3(
								_elm_lang$core$Basics$flip,
								F2(
									function (x, y) {
										return A2(_elm_lang$core$Basics_ops['++'], x, y);
									}),
								'em',
								_elm_lang$core$Basics$toString(1.5 * 1.5))
						},
						_1: {ctor: '[]'}
					}),
				_1: {ctor: '[]'}
			}
		}
	},
	{
		ctor: '::',
		_0: _elm_lang$html$Html$text('tab'),
		_1: {ctor: '[]'}
	});
var _minekoa$elm_text_editor$SoftwareKeyboard$spaceKey = A2(
	_elm_lang$html$Html$div,
	{
		ctor: '::',
		_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
		_1: {
			ctor: '::',
			_0: _elm_lang$html$Html_Events$onClick(
				_minekoa$elm_text_editor$SoftwareKeyboard$Insert(' ')),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$style(
					{
						ctor: '::',
						_0: {ctor: '_Tuple2', _0: 'width', _1: '6em'},
						_1: {ctor: '[]'}
					}),
				_1: {ctor: '[]'}
			}
		}
	},
	{
		ctor: '::',
		_0: _elm_lang$html$Html$text('space'),
		_1: {ctor: '[]'}
	});
var _minekoa$elm_text_editor$SoftwareKeyboard$zenkakuSpaceKey = A2(
	_elm_lang$html$Html$div,
	{
		ctor: '::',
		_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
		_1: {
			ctor: '::',
			_0: _elm_lang$html$Html_Events$onClick(
				_minekoa$elm_text_editor$SoftwareKeyboard$Insert('　')),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$style(
					{
						ctor: '::',
						_0: {ctor: '_Tuple2', _0: 'width', _1: '6em'},
						_1: {ctor: '[]'}
					}),
				_1: {ctor: '[]'}
			}
		}
	},
	{
		ctor: '::',
		_0: _elm_lang$html$Html$text('スペース'),
		_1: {ctor: '[]'}
	});
var _minekoa$elm_text_editor$SoftwareKeyboard$MoveNext = {ctor: 'MoveNext'};
var _minekoa$elm_text_editor$SoftwareKeyboard$MovePrevios = {ctor: 'MovePrevios'};
var _minekoa$elm_text_editor$SoftwareKeyboard$MoveBackword = {ctor: 'MoveBackword'};
var _minekoa$elm_text_editor$SoftwareKeyboard$MoveForward = {ctor: 'MoveForward'};
var _minekoa$elm_text_editor$SoftwareKeyboard$capitalKeys = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey'),
			_1: {ctor: '[]'}
		},
		{
			ctor: '::',
			_0: A2(
				_elm_lang$html$Html$div,
				{
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
					_1: {ctor: '[]'}
				},
				{
					ctor: '::',
					_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('!'),
					_1: {
						ctor: '::',
						_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('@'),
						_1: {
							ctor: '::',
							_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('#'),
							_1: {
								ctor: '::',
								_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('$'),
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('%'),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('^'),
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('&'),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('*'),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('('),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$SoftwareKeyboard$key(')'),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('_'),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('+'),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$SoftwareKeyboard$backspaceKey,
																	_1: {ctor: '[]'}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}),
			_1: {
				ctor: '::',
				_0: A2(
					_elm_lang$html$Html$div,
					{
						ctor: '::',
						_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
						_1: {ctor: '[]'}
					},
					{
						ctor: '::',
						_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(1),
						_1: {
							ctor: '::',
							_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('Q'),
							_1: {
								ctor: '::',
								_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('W'),
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('E'),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('R'),
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('T'),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('Y'),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('U'),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('I'),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('O'),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('P'),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('{'),
																	_1: {
																		ctor: '::',
																		_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('}'),
																		_1: {
																			ctor: '::',
																			_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('|'),
																			_1: {ctor: '[]'}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}),
				_1: {
					ctor: '::',
					_0: A2(
						_elm_lang$html$Html$div,
						{
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
							_1: {ctor: '[]'}
						},
						{
							ctor: '::',
							_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(2),
							_1: {
								ctor: '::',
								_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('A'),
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('S'),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('D'),
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('F'),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('G'),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('H'),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('J'),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('K'),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('L'),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$SoftwareKeyboard$key(':'),
																	_1: {
																		ctor: '::',
																		_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('\"'),
																		_1: {
																			ctor: '::',
																			_0: _minekoa$elm_text_editor$SoftwareKeyboard$enterKey,
																			_1: {ctor: '[]'}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}),
					_1: {
						ctor: '::',
						_0: A2(
							_elm_lang$html$Html$div,
							{
								ctor: '::',
								_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
								_1: {ctor: '[]'}
							},
							{
								ctor: '::',
								_0: _minekoa$elm_text_editor$SoftwareKeyboard$tabKey,
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('Z'),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('X'),
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('C'),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('V'),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('B'),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('N'),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('M'),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('<'),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('>'),
																	_1: {
																		ctor: '::',
																		_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('?'),
																		_1: {
																			ctor: '::',
																			_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('~'),
																			_1: {ctor: '[]'}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}),
						_1: {
							ctor: '::',
							_0: A2(
								_elm_lang$html$Html$div,
								{
									ctor: '::',
									_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
									_1: {ctor: '[]'}
								},
								{
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(8),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$spaceKey,
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(2),
											_1: {
												ctor: '::',
												_0: A2(
													_elm_lang$html$Html$div,
													{
														ctor: '::',
														_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
														_1: {
															ctor: '::',
															_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$MoveBackword),
															_1: {
																ctor: '::',
																_0: _elm_lang$html$Html_Attributes$style(
																	{
																		ctor: '::',
																		_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
																		_1: {ctor: '[]'}
																	}),
																_1: {ctor: '[]'}
															}
														}
													},
													{
														ctor: '::',
														_0: _elm_lang$html$Html$text('←'),
														_1: {ctor: '[]'}
													}),
												_1: {
													ctor: '::',
													_0: A2(
														_elm_lang$html$Html$div,
														{
															ctor: '::',
															_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
															_1: {
																ctor: '::',
																_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$MovePrevios),
																_1: {
																	ctor: '::',
																	_0: _elm_lang$html$Html_Attributes$style(
																		{
																			ctor: '::',
																			_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
																			_1: {ctor: '[]'}
																		}),
																	_1: {ctor: '[]'}
																}
															}
														},
														{
															ctor: '::',
															_0: _elm_lang$html$Html$text('↑'),
															_1: {ctor: '[]'}
														}),
													_1: {
														ctor: '::',
														_0: A2(
															_elm_lang$html$Html$div,
															{
																ctor: '::',
																_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
																_1: {
																	ctor: '::',
																	_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$MoveNext),
																	_1: {
																		ctor: '::',
																		_0: _elm_lang$html$Html_Attributes$style(
																			{
																				ctor: '::',
																				_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
																				_1: {ctor: '[]'}
																			}),
																		_1: {ctor: '[]'}
																	}
																}
															},
															{
																ctor: '::',
																_0: _elm_lang$html$Html$text('↓'),
																_1: {ctor: '[]'}
															}),
														_1: {
															ctor: '::',
															_0: A2(
																_elm_lang$html$Html$div,
																{
																	ctor: '::',
																	_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
																	_1: {
																		ctor: '::',
																		_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$MoveForward),
																		_1: {
																			ctor: '::',
																			_0: _elm_lang$html$Html_Attributes$style(
																				{
																					ctor: '::',
																					_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
																					_1: {ctor: '[]'}
																				}),
																			_1: {ctor: '[]'}
																		}
																	}
																},
																{
																	ctor: '::',
																	_0: _elm_lang$html$Html$text('→'),
																	_1: {ctor: '[]'}
																}),
															_1: {ctor: '[]'}
														}
													}
												}
											}
										}
									}
								}),
							_1: {ctor: '[]'}
						}
					}
				}
			}
		});
};
var _minekoa$elm_text_editor$SoftwareKeyboard$smallKeys = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey'),
			_1: {ctor: '[]'}
		},
		{
			ctor: '::',
			_0: A2(
				_elm_lang$html$Html$div,
				{
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
					_1: {ctor: '[]'}
				},
				{
					ctor: '::',
					_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('1'),
					_1: {
						ctor: '::',
						_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('2'),
						_1: {
							ctor: '::',
							_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('3'),
							_1: {
								ctor: '::',
								_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('4'),
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('5'),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('6'),
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('7'),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('8'),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('9'),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('0'),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('-'),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('='),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$SoftwareKeyboard$backspaceKey,
																	_1: {ctor: '[]'}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}),
			_1: {
				ctor: '::',
				_0: A2(
					_elm_lang$html$Html$div,
					{
						ctor: '::',
						_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
						_1: {ctor: '[]'}
					},
					{
						ctor: '::',
						_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(1),
						_1: {
							ctor: '::',
							_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('q'),
							_1: {
								ctor: '::',
								_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('w'),
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('e'),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('r'),
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('t'),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('y'),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('u'),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('i'),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('o'),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('p'),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('['),
																	_1: {
																		ctor: '::',
																		_0: _minekoa$elm_text_editor$SoftwareKeyboard$key(']'),
																		_1: {
																			ctor: '::',
																			_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('\\'),
																			_1: {ctor: '[]'}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}),
				_1: {
					ctor: '::',
					_0: A2(
						_elm_lang$html$Html$div,
						{
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
							_1: {ctor: '[]'}
						},
						{
							ctor: '::',
							_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(2),
							_1: {
								ctor: '::',
								_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('a'),
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('s'),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('d'),
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('f'),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('g'),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('h'),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('j'),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('k'),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('l'),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$SoftwareKeyboard$key(';'),
																	_1: {
																		ctor: '::',
																		_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('\''),
																		_1: {
																			ctor: '::',
																			_0: _minekoa$elm_text_editor$SoftwareKeyboard$enterKey,
																			_1: {ctor: '[]'}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}),
					_1: {
						ctor: '::',
						_0: A2(
							_elm_lang$html$Html$div,
							{
								ctor: '::',
								_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
								_1: {ctor: '[]'}
							},
							{
								ctor: '::',
								_0: _minekoa$elm_text_editor$SoftwareKeyboard$tabKey,
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('z'),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('x'),
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('c'),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('v'),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('b'),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('n'),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('m'),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$SoftwareKeyboard$key(','),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('.'),
																	_1: {
																		ctor: '::',
																		_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('/'),
																		_1: {
																			ctor: '::',
																			_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('`'),
																			_1: {ctor: '[]'}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}),
						_1: {
							ctor: '::',
							_0: A2(
								_elm_lang$html$Html$div,
								{
									ctor: '::',
									_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
									_1: {ctor: '[]'}
								},
								{
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(8),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$spaceKey,
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(2),
											_1: {
												ctor: '::',
												_0: A2(
													_elm_lang$html$Html$div,
													{
														ctor: '::',
														_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
														_1: {
															ctor: '::',
															_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$MoveBackword),
															_1: {
																ctor: '::',
																_0: _elm_lang$html$Html_Attributes$style(
																	{
																		ctor: '::',
																		_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
																		_1: {ctor: '[]'}
																	}),
																_1: {ctor: '[]'}
															}
														}
													},
													{
														ctor: '::',
														_0: _elm_lang$html$Html$text('←'),
														_1: {ctor: '[]'}
													}),
												_1: {
													ctor: '::',
													_0: A2(
														_elm_lang$html$Html$div,
														{
															ctor: '::',
															_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
															_1: {
																ctor: '::',
																_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$MovePrevios),
																_1: {
																	ctor: '::',
																	_0: _elm_lang$html$Html_Attributes$style(
																		{
																			ctor: '::',
																			_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
																			_1: {ctor: '[]'}
																		}),
																	_1: {ctor: '[]'}
																}
															}
														},
														{
															ctor: '::',
															_0: _elm_lang$html$Html$text('↑'),
															_1: {ctor: '[]'}
														}),
													_1: {
														ctor: '::',
														_0: A2(
															_elm_lang$html$Html$div,
															{
																ctor: '::',
																_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
																_1: {
																	ctor: '::',
																	_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$MoveNext),
																	_1: {
																		ctor: '::',
																		_0: _elm_lang$html$Html_Attributes$style(
																			{
																				ctor: '::',
																				_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
																				_1: {ctor: '[]'}
																			}),
																		_1: {ctor: '[]'}
																	}
																}
															},
															{
																ctor: '::',
																_0: _elm_lang$html$Html$text('↓'),
																_1: {ctor: '[]'}
															}),
														_1: {
															ctor: '::',
															_0: A2(
																_elm_lang$html$Html$div,
																{
																	ctor: '::',
																	_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
																	_1: {
																		ctor: '::',
																		_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$MoveForward),
																		_1: {
																			ctor: '::',
																			_0: _elm_lang$html$Html_Attributes$style(
																				{
																					ctor: '::',
																					_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
																					_1: {ctor: '[]'}
																				}),
																			_1: {ctor: '[]'}
																		}
																	}
																},
																{
																	ctor: '::',
																	_0: _elm_lang$html$Html$text('→'),
																	_1: {ctor: '[]'}
																}),
															_1: {ctor: '[]'}
														}
													}
												}
											}
										}
									}
								}),
							_1: {ctor: '[]'}
						}
					}
				}
			}
		});
};
var _minekoa$elm_text_editor$SoftwareKeyboard$hiraganaKeys = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey'),
			_1: {ctor: '[]'}
		},
		{
			ctor: '::',
			_0: A2(
				_elm_lang$html$Html$div,
				{
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
					_1: {ctor: '[]'}
				},
				{
					ctor: '::',
					_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('あ'),
					_1: {
						ctor: '::',
						_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('い'),
						_1: {
							ctor: '::',
							_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('う'),
							_1: {
								ctor: '::',
								_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('え'),
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('お'),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('な'),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('に'),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ぬ'),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ね'),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('の'),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('や'),
																	_1: {
																		ctor: '::',
																		_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ゆ'),
																		_1: {
																			ctor: '::',
																			_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('よ'),
																			_1: {ctor: '[]'}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}),
			_1: {
				ctor: '::',
				_0: A2(
					_elm_lang$html$Html$div,
					{
						ctor: '::',
						_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
						_1: {ctor: '[]'}
					},
					{
						ctor: '::',
						_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('か'),
						_1: {
							ctor: '::',
							_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('き'),
							_1: {
								ctor: '::',
								_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('く'),
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('け'),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('こ'),
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('は'),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ひ'),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ふ'),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('へ'),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ほ'),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
																	_1: {
																		ctor: '::',
																		_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('わ'),
																		_1: {
																			ctor: '::',
																			_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ん'),
																			_1: {
																				ctor: '::',
																				_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ー'),
																				_1: {ctor: '[]'}
																			}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}),
				_1: {
					ctor: '::',
					_0: A2(
						_elm_lang$html$Html$div,
						{
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
							_1: {ctor: '[]'}
						},
						{
							ctor: '::',
							_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('さ'),
							_1: {
								ctor: '::',
								_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('し'),
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('す'),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('せ'),
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('そ'),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ま'),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('み'),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('む'),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('め'),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('も'),
																	_1: {
																		ctor: '::',
																		_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
																		_1: {
																			ctor: '::',
																			_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('、'),
																			_1: {
																				ctor: '::',
																				_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
																				_1: {
																					ctor: '::',
																					_0: _minekoa$elm_text_editor$SoftwareKeyboard$backspaceKey,
																					_1: {ctor: '[]'}
																				}
																			}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}),
					_1: {
						ctor: '::',
						_0: A2(
							_elm_lang$html$Html$div,
							{
								ctor: '::',
								_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
								_1: {ctor: '[]'}
							},
							{
								ctor: '::',
								_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('た'),
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ち'),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('つ'),
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('て'),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('と'),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ら'),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('り'),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('る'),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('れ'),
																	_1: {
																		ctor: '::',
																		_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ろ'),
																		_1: {
																			ctor: '::',
																			_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
																			_1: {
																				ctor: '::',
																				_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('。'),
																				_1: {
																					ctor: '::',
																					_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
																					_1: {
																						ctor: '::',
																						_0: _minekoa$elm_text_editor$SoftwareKeyboard$enterKey,
																						_1: {ctor: '[]'}
																					}
																				}
																			}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}),
						_1: {
							ctor: '::',
							_0: A2(
								_elm_lang$html$Html$div,
								{
									ctor: '::',
									_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
									_1: {ctor: '[]'}
								},
								{
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(8),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$zenkakuSpaceKey,
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(2),
											_1: {
												ctor: '::',
												_0: A2(
													_elm_lang$html$Html$div,
													{
														ctor: '::',
														_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
														_1: {
															ctor: '::',
															_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$MoveBackword),
															_1: {
																ctor: '::',
																_0: _elm_lang$html$Html_Attributes$style(
																	{
																		ctor: '::',
																		_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
																		_1: {ctor: '[]'}
																	}),
																_1: {ctor: '[]'}
															}
														}
													},
													{
														ctor: '::',
														_0: _elm_lang$html$Html$text('←'),
														_1: {ctor: '[]'}
													}),
												_1: {
													ctor: '::',
													_0: A2(
														_elm_lang$html$Html$div,
														{
															ctor: '::',
															_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
															_1: {
																ctor: '::',
																_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$MovePrevios),
																_1: {
																	ctor: '::',
																	_0: _elm_lang$html$Html_Attributes$style(
																		{
																			ctor: '::',
																			_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
																			_1: {ctor: '[]'}
																		}),
																	_1: {ctor: '[]'}
																}
															}
														},
														{
															ctor: '::',
															_0: _elm_lang$html$Html$text('↑'),
															_1: {ctor: '[]'}
														}),
													_1: {
														ctor: '::',
														_0: A2(
															_elm_lang$html$Html$div,
															{
																ctor: '::',
																_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
																_1: {
																	ctor: '::',
																	_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$MoveNext),
																	_1: {
																		ctor: '::',
																		_0: _elm_lang$html$Html_Attributes$style(
																			{
																				ctor: '::',
																				_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
																				_1: {ctor: '[]'}
																			}),
																		_1: {ctor: '[]'}
																	}
																}
															},
															{
																ctor: '::',
																_0: _elm_lang$html$Html$text('↓'),
																_1: {ctor: '[]'}
															}),
														_1: {
															ctor: '::',
															_0: A2(
																_elm_lang$html$Html$div,
																{
																	ctor: '::',
																	_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
																	_1: {
																		ctor: '::',
																		_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$MoveForward),
																		_1: {
																			ctor: '::',
																			_0: _elm_lang$html$Html_Attributes$style(
																				{
																					ctor: '::',
																					_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
																					_1: {ctor: '[]'}
																				}),
																			_1: {ctor: '[]'}
																		}
																	}
																},
																{
																	ctor: '::',
																	_0: _elm_lang$html$Html$text('→'),
																	_1: {ctor: '[]'}
																}),
															_1: {ctor: '[]'}
														}
													}
												}
											}
										}
									}
								}),
							_1: {ctor: '[]'}
						}
					}
				}
			}
		});
};
var _minekoa$elm_text_editor$SoftwareKeyboard$katakanaKeys = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey'),
			_1: {ctor: '[]'}
		},
		{
			ctor: '::',
			_0: A2(
				_elm_lang$html$Html$div,
				{
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
					_1: {ctor: '[]'}
				},
				{
					ctor: '::',
					_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ア'),
					_1: {
						ctor: '::',
						_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('イ'),
						_1: {
							ctor: '::',
							_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ウ'),
							_1: {
								ctor: '::',
								_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('エ'),
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('オ'),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ナ'),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ニ'),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ヌ'),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ネ'),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ノ'),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ヤ'),
																	_1: {
																		ctor: '::',
																		_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ユ'),
																		_1: {
																			ctor: '::',
																			_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ヨ'),
																			_1: {ctor: '[]'}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}),
			_1: {
				ctor: '::',
				_0: A2(
					_elm_lang$html$Html$div,
					{
						ctor: '::',
						_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
						_1: {ctor: '[]'}
					},
					{
						ctor: '::',
						_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('カ'),
						_1: {
							ctor: '::',
							_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('キ'),
							_1: {
								ctor: '::',
								_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ク'),
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ケ'),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('コ'),
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ハ'),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ヒ'),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('フ'),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ヘ'),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ホ'),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
																	_1: {
																		ctor: '::',
																		_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ワ'),
																		_1: {
																			ctor: '::',
																			_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ン'),
																			_1: {
																				ctor: '::',
																				_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ー'),
																				_1: {ctor: '[]'}
																			}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}),
				_1: {
					ctor: '::',
					_0: A2(
						_elm_lang$html$Html$div,
						{
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
							_1: {ctor: '[]'}
						},
						{
							ctor: '::',
							_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('サ'),
							_1: {
								ctor: '::',
								_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('シ'),
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ス'),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('セ'),
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ソ'),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('マ'),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ミ'),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ム'),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('メ'),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('モ'),
																	_1: {
																		ctor: '::',
																		_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
																		_1: {
																			ctor: '::',
																			_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('、'),
																			_1: {
																				ctor: '::',
																				_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
																				_1: {
																					ctor: '::',
																					_0: _minekoa$elm_text_editor$SoftwareKeyboard$backspaceKey,
																					_1: {ctor: '[]'}
																				}
																			}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}),
					_1: {
						ctor: '::',
						_0: A2(
							_elm_lang$html$Html$div,
							{
								ctor: '::',
								_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
								_1: {ctor: '[]'}
							},
							{
								ctor: '::',
								_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('タ'),
								_1: {
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('チ'),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ツ'),
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('テ'),
											_1: {
												ctor: '::',
												_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ト'),
												_1: {
													ctor: '::',
													_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
													_1: {
														ctor: '::',
														_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ラ'),
														_1: {
															ctor: '::',
															_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('リ'),
															_1: {
																ctor: '::',
																_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ル'),
																_1: {
																	ctor: '::',
																	_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('レ'),
																	_1: {
																		ctor: '::',
																		_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('ロ'),
																		_1: {
																			ctor: '::',
																			_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
																			_1: {
																				ctor: '::',
																				_0: _minekoa$elm_text_editor$SoftwareKeyboard$key('。'),
																				_1: {
																					ctor: '::',
																					_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(0.5),
																					_1: {
																						ctor: '::',
																						_0: _minekoa$elm_text_editor$SoftwareKeyboard$enterKey,
																						_1: {ctor: '[]'}
																					}
																				}
																			}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}),
						_1: {
							ctor: '::',
							_0: A2(
								_elm_lang$html$Html$div,
								{
									ctor: '::',
									_0: _elm_lang$html$Html_Attributes$class('kbd_mainkey_row'),
									_1: {ctor: '[]'}
								},
								{
									ctor: '::',
									_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(8),
									_1: {
										ctor: '::',
										_0: _minekoa$elm_text_editor$SoftwareKeyboard$zenkakuSpaceKey,
										_1: {
											ctor: '::',
											_0: _minekoa$elm_text_editor$SoftwareKeyboard$pad(2),
											_1: {
												ctor: '::',
												_0: A2(
													_elm_lang$html$Html$div,
													{
														ctor: '::',
														_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
														_1: {
															ctor: '::',
															_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$MoveBackword),
															_1: {
																ctor: '::',
																_0: _elm_lang$html$Html_Attributes$style(
																	{
																		ctor: '::',
																		_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
																		_1: {ctor: '[]'}
																	}),
																_1: {ctor: '[]'}
															}
														}
													},
													{
														ctor: '::',
														_0: _elm_lang$html$Html$text('←'),
														_1: {ctor: '[]'}
													}),
												_1: {
													ctor: '::',
													_0: A2(
														_elm_lang$html$Html$div,
														{
															ctor: '::',
															_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
															_1: {
																ctor: '::',
																_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$MovePrevios),
																_1: {
																	ctor: '::',
																	_0: _elm_lang$html$Html_Attributes$style(
																		{
																			ctor: '::',
																			_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
																			_1: {ctor: '[]'}
																		}),
																	_1: {ctor: '[]'}
																}
															}
														},
														{
															ctor: '::',
															_0: _elm_lang$html$Html$text('↑'),
															_1: {ctor: '[]'}
														}),
													_1: {
														ctor: '::',
														_0: A2(
															_elm_lang$html$Html$div,
															{
																ctor: '::',
																_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
																_1: {
																	ctor: '::',
																	_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$MoveNext),
																	_1: {
																		ctor: '::',
																		_0: _elm_lang$html$Html_Attributes$style(
																			{
																				ctor: '::',
																				_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
																				_1: {ctor: '[]'}
																			}),
																		_1: {ctor: '[]'}
																	}
																}
															},
															{
																ctor: '::',
																_0: _elm_lang$html$Html$text('↓'),
																_1: {ctor: '[]'}
															}),
														_1: {
															ctor: '::',
															_0: A2(
																_elm_lang$html$Html$div,
																{
																	ctor: '::',
																	_0: _elm_lang$html$Html_Attributes$class('kbd_key'),
																	_1: {
																		ctor: '::',
																		_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$SoftwareKeyboard$MoveForward),
																		_1: {
																			ctor: '::',
																			_0: _elm_lang$html$Html_Attributes$style(
																				{
																					ctor: '::',
																					_0: {ctor: '_Tuple2', _0: 'width', _1: '1.5em'},
																					_1: {ctor: '[]'}
																				}),
																			_1: {ctor: '[]'}
																		}
																	}
																},
																{
																	ctor: '::',
																	_0: _elm_lang$html$Html$text('→'),
																	_1: {ctor: '[]'}
																}),
															_1: {ctor: '[]'}
														}
													}
												}
											}
										}
									}
								}),
							_1: {ctor: '[]'}
						}
					}
				}
			}
		});
};
var _minekoa$elm_text_editor$SoftwareKeyboard$mainkey = function (model) {
	var _p1 = model.mode;
	switch (_p1.ctor) {
		case 'CapitalLetter':
			return _minekoa$elm_text_editor$SoftwareKeyboard$capitalKeys(model);
		case 'SmallLetter':
			return _minekoa$elm_text_editor$SoftwareKeyboard$smallKeys(model);
		case 'Hiragana':
			return _minekoa$elm_text_editor$SoftwareKeyboard$hiraganaKeys(model);
		default:
			return _minekoa$elm_text_editor$SoftwareKeyboard$katakanaKeys(model);
	}
};
var _minekoa$elm_text_editor$SoftwareKeyboard$ChangeMode = function (a) {
	return {ctor: 'ChangeMode', _0: a};
};
var _minekoa$elm_text_editor$SoftwareKeyboard$keyboardSwitcher = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$class('kbd_switcher'),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$style(
					{ctor: '[]'}),
				_1: {ctor: '[]'}
			}
		},
		{
			ctor: '::',
			_0: A2(
				_elm_lang$html$Html$div,
				{
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$class(
						_elm_lang$core$Native_Utils.eq(model.mode, _minekoa$elm_text_editor$SoftwareKeyboard$CapitalLetter) ? 'kbd_button_active' : 'kbd_button'),
					_1: {
						ctor: '::',
						_0: _elm_lang$html$Html_Events$onClick(
							_minekoa$elm_text_editor$SoftwareKeyboard$ChangeMode(_minekoa$elm_text_editor$SoftwareKeyboard$CapitalLetter)),
						_1: {ctor: '[]'}
					}
				},
				{
					ctor: '::',
					_0: _elm_lang$html$Html$text('A'),
					_1: {ctor: '[]'}
				}),
			_1: {
				ctor: '::',
				_0: A2(
					_elm_lang$html$Html$div,
					{
						ctor: '::',
						_0: _elm_lang$html$Html_Attributes$class(
							_elm_lang$core$Native_Utils.eq(model.mode, _minekoa$elm_text_editor$SoftwareKeyboard$SmallLetter) ? 'kbd_button_active' : 'kbd_button'),
						_1: {
							ctor: '::',
							_0: _elm_lang$html$Html_Events$onClick(
								_minekoa$elm_text_editor$SoftwareKeyboard$ChangeMode(_minekoa$elm_text_editor$SoftwareKeyboard$SmallLetter)),
							_1: {ctor: '[]'}
						}
					},
					{
						ctor: '::',
						_0: _elm_lang$html$Html$text('a'),
						_1: {ctor: '[]'}
					}),
				_1: {
					ctor: '::',
					_0: A2(
						_elm_lang$html$Html$div,
						{
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$class(
								_elm_lang$core$Native_Utils.eq(model.mode, _minekoa$elm_text_editor$SoftwareKeyboard$Hiragana) ? 'kbd_button_active' : 'kbd_button'),
							_1: {
								ctor: '::',
								_0: _elm_lang$html$Html_Events$onClick(
									_minekoa$elm_text_editor$SoftwareKeyboard$ChangeMode(_minekoa$elm_text_editor$SoftwareKeyboard$Hiragana)),
								_1: {ctor: '[]'}
							}
						},
						{
							ctor: '::',
							_0: _elm_lang$html$Html$text('あ'),
							_1: {ctor: '[]'}
						}),
					_1: {
						ctor: '::',
						_0: A2(
							_elm_lang$html$Html$div,
							{
								ctor: '::',
								_0: _elm_lang$html$Html_Attributes$class(
									_elm_lang$core$Native_Utils.eq(model.mode, _minekoa$elm_text_editor$SoftwareKeyboard$Katakana) ? 'kbd_button_active' : 'kbd_button'),
								_1: {
									ctor: '::',
									_0: _elm_lang$html$Html_Events$onClick(
										_minekoa$elm_text_editor$SoftwareKeyboard$ChangeMode(_minekoa$elm_text_editor$SoftwareKeyboard$Katakana)),
									_1: {ctor: '[]'}
								}
							},
							{
								ctor: '::',
								_0: _elm_lang$html$Html$text('ア'),
								_1: {ctor: '[]'}
							}),
						_1: {ctor: '[]'}
					}
				}
			}
		});
};
var _minekoa$elm_text_editor$SoftwareKeyboard$view = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$class('software_keyboard'),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$style(
					{ctor: '[]'}),
				_1: {ctor: '[]'}
			}
		},
		{
			ctor: '::',
			_0: _minekoa$elm_text_editor$SoftwareKeyboard$keyboardSwitcher(model),
			_1: {
				ctor: '::',
				_0: _minekoa$elm_text_editor$SoftwareKeyboard$mainkey(model),
				_1: {
					ctor: '::',
					_0: _minekoa$elm_text_editor$SoftwareKeyboard$editcmdkey(model),
					_1: {ctor: '[]'}
				}
			}
		});
};

var _minekoa$elm_text_editor$StyleSetter$selectList = F3(
	function (idx, values, tagger) {
		return A2(
			_elm_lang$html$Html$select,
			{
				ctor: '::',
				_0: A2(
					_elm_lang$html$Html_Events$on,
					'change',
					A2(
						_elm_lang$core$Json_Decode$map,
						tagger,
						A2(
							_elm_lang$core$Json_Decode$at,
							{
								ctor: '::',
								_0: 'target',
								_1: {
									ctor: '::',
									_0: 'value',
									_1: {ctor: '[]'}
								}
							},
							_elm_lang$core$Json_Decode$string))),
				_1: {ctor: '[]'}
			},
			A2(
				_elm_lang$core$List$map,
				function (v) {
					return A2(
						_elm_lang$html$Html$option,
						{
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$value(v),
							_1: {
								ctor: '::',
								_0: _elm_lang$html$Html_Attributes$selected(
									_elm_lang$core$Native_Utils.eq(idx, v)),
								_1: {ctor: '[]'}
							}
						},
						{
							ctor: '::',
							_0: _elm_lang$html$Html$text(v),
							_1: {ctor: '[]'}
						});
				},
				values));
	});
var _minekoa$elm_text_editor$StyleSetter$fontSizeSelector = F2(
	function (tagger, fontsizeList) {
		return A2(
			_elm_lang$html$Html$div,
			{
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$class('menu-palette'),
				_1: {
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$style(
						{
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'flex-grow', _1: '1'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'display', _1: 'flex'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'flex-direction', _1: 'row'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'flex-wrap', _1: 'no-wrap'},
										_1: {ctor: '[]'}
									}
								}
							}
						}),
					_1: {ctor: '[]'}
				}
			},
			A2(
				_elm_lang$core$List$map,
				function (fontsize) {
					return A2(
						_elm_lang$html$Html$div,
						{
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$class(
								_elm_lang$core$Native_Utils.eq(fontsize, fontsizeList.value) ? 'font-palette-item-active' : 'font-palette-item'),
							_1: {
								ctor: '::',
								_0: _elm_lang$html$Html_Attributes$style(
									{
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'font-size', _1: fontsize},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'width', _1: '100%'},
											_1: {ctor: '[]'}
										}
									}),
								_1: {
									ctor: '::',
									_0: _elm_lang$html$Html_Events$onClick(
										tagger(fontsize)),
									_1: {ctor: '[]'}
								}
							}
						},
						{
							ctor: '::',
							_0: _elm_lang$html$Html$text(fontsize),
							_1: {ctor: '[]'}
						});
				},
				fontsizeList.list));
	});
var _minekoa$elm_text_editor$StyleSetter$fontFamilySelector = F2(
	function (tagger, fontList) {
		return A2(
			_elm_lang$html$Html$div,
			{
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$class('menu-palette'),
				_1: {
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$style(
						{
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'flex-grow', _1: '1'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'display', _1: 'flex'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'flex-direction', _1: 'row'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'flex-wrap', _1: 'no-wrap'},
										_1: {ctor: '[]'}
									}
								}
							}
						}),
					_1: {ctor: '[]'}
				}
			},
			A2(
				_elm_lang$core$List$map,
				function (font) {
					return A2(
						_elm_lang$html$Html$div,
						{
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$class(
								_elm_lang$core$Native_Utils.eq(font, fontList.value) ? 'font-palette-item-active' : 'font-palette-item'),
							_1: {
								ctor: '::',
								_0: _elm_lang$html$Html_Attributes$style(
									{
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'height', _1: '2em'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'size', _1: '2em'},
											_1: {
												ctor: '::',
												_0: {ctor: '_Tuple2', _0: 'font-family', _1: font},
												_1: {
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'width', _1: '100%'},
													_1: {ctor: '[]'}
												}
											}
										}
									}),
								_1: {
									ctor: '::',
									_0: _elm_lang$html$Html_Events$onClick(
										tagger(font)),
									_1: {ctor: '[]'}
								}
							}
						},
						{
							ctor: '::',
							_0: _elm_lang$html$Html$text(font),
							_1: {ctor: '[]'}
						});
				},
				fontList.list));
	});
var _minekoa$elm_text_editor$StyleSetter$colorPalette = F2(
	function (tagger, colorList) {
		return A2(
			_elm_lang$html$Html$div,
			{
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$class('menu-palette'),
				_1: {
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$style(
						{
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'flex-grow', _1: '1'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'display', _1: 'flex'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'align-content', _1: 'flex-start'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'flex-wrap', _1: 'wrap'},
										_1: {ctor: '[]'}
									}
								}
							}
						}),
					_1: {ctor: '[]'}
				}
			},
			A2(
				_elm_lang$core$List$map,
				function (color) {
					return A2(
						_elm_lang$html$Html$div,
						{
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$class(
								_elm_lang$core$Native_Utils.eq(color, colorList.value) ? 'color-palette-item-active' : 'color-palette-item'),
							_1: {
								ctor: '::',
								_0: _elm_lang$html$Html_Attributes$style(
									{
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'display', _1: 'flex'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'flex-directipn', _1: 'column'},
											_1: {ctor: '[]'}
										}
									}),
								_1: {
									ctor: '::',
									_0: _elm_lang$html$Html_Events$onClick(
										tagger(color)),
									_1: {ctor: '[]'}
								}
							}
						},
						{
							ctor: '::',
							_0: A2(
								_elm_lang$html$Html$div,
								{
									ctor: '::',
									_0: _elm_lang$html$Html_Attributes$style(
										{
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'width', _1: '1em'},
											_1: {
												ctor: '::',
												_0: {ctor: '_Tuple2', _0: 'height', _1: '1em'},
												_1: {
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'background-color', _1: color},
													_1: {
														ctor: '::',
														_0: {ctor: '_Tuple2', _0: 'border', _1: '1px solid black'},
														_1: {ctor: '[]'}
													}
												}
											}
										}),
									_1: {ctor: '[]'}
								},
								{ctor: '[]'}),
							_1: {
								ctor: '::',
								_0: A2(
									_elm_lang$html$Html$div,
									{
										ctor: '::',
										_0: _elm_lang$html$Html_Attributes$style(
											{
												ctor: '::',
												_0: {ctor: '_Tuple2', _0: 'padding-left', _1: '0.5em'},
												_1: {ctor: '[]'}
											}),
										_1: {ctor: '[]'}
									},
									{
										ctor: '::',
										_0: _elm_lang$html$Html$text(color),
										_1: {ctor: '[]'}
									}),
								_1: {ctor: '[]'}
							}
						});
				},
				colorList.list));
	});
var _minekoa$elm_text_editor$StyleSetter$initFontColor = {
	value: 'inherit',
	list: {
		ctor: '::',
		_0: 'inherit',
		_1: {
			ctor: '::',
			_0: '0.5em',
			_1: {
				ctor: '::',
				_0: '1em',
				_1: {
					ctor: '::',
					_0: '1.2em',
					_1: {
						ctor: '::',
						_0: '1.5em',
						_1: {
							ctor: '::',
							_0: '2em',
							_1: {
								ctor: '::',
								_0: '3em',
								_1: {
									ctor: '::',
									_0: '5em',
									_1: {
										ctor: '::',
										_0: '7em',
										_1: {
											ctor: '::',
											_0: '10em',
											_1: {ctor: '[]'}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
};
var _minekoa$elm_text_editor$StyleSetter$initFontFamily = {
	value: 'inherit',
	list: {
		ctor: '::',
		_0: 'inherit',
		_1: {
			ctor: '::',
			_0: 'cursive',
			_1: {
				ctor: '::',
				_0: 'fantasy',
				_1: {
					ctor: '::',
					_0: 'monospace',
					_1: {
						ctor: '::',
						_0: 'sans-serif',
						_1: {
							ctor: '::',
							_0: 'serif',
							_1: {ctor: '[]'}
						}
					}
				}
			}
		}
	}
};
var _minekoa$elm_text_editor$StyleSetter$initFgColor = {
	value: 'inherit',
	list: {
		ctor: '::',
		_0: 'inherit',
		_1: {
			ctor: '::',
			_0: 'black',
			_1: {
				ctor: '::',
				_0: 'white',
				_1: {
					ctor: '::',
					_0: 'aqua',
					_1: {
						ctor: '::',
						_0: 'coral',
						_1: {
							ctor: '::',
							_0: 'midnightblue',
							_1: {
								ctor: '::',
								_0: 'darkslategray',
								_1: {
									ctor: '::',
									_0: 'ghostwhite',
									_1: {
										ctor: '::',
										_0: 'lavender',
										_1: {
											ctor: '::',
											_0: 'palevioletred',
											_1: {
												ctor: '::',
												_0: 'darkmagenta',
												_1: {
													ctor: '::',
													_0: 'moccasin',
													_1: {
														ctor: '::',
														_0: 'rosybrown',
														_1: {ctor: '[]'}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
};
var _minekoa$elm_text_editor$StyleSetter$initBgColor = {
	value: 'inherit',
	list: {
		ctor: '::',
		_0: 'inherit',
		_1: {
			ctor: '::',
			_0: 'black',
			_1: {
				ctor: '::',
				_0: 'white',
				_1: {
					ctor: '::',
					_0: 'linen',
					_1: {
						ctor: '::',
						_0: 'dimgray',
						_1: {
							ctor: '::',
							_0: 'whitesmoke',
							_1: {
								ctor: '::',
								_0: 'midnightblue',
								_1: {
									ctor: '::',
									_0: 'darkolivegreen',
									_1: {
										ctor: '::',
										_0: 'aquamarine',
										_1: {
											ctor: '::',
											_0: 'beige',
											_1: {
												ctor: '::',
												_0: 'mediumvioletred',
												_1: {
													ctor: '::',
													_0: 'darkslategray',
													_1: {
														ctor: '::',
														_0: 'lavender',
														_1: {ctor: '[]'}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
};
var _minekoa$elm_text_editor$StyleSetter$targetName = function (target) {
	var _p0 = target;
	switch (_p0.ctor) {
		case 'EditColor':
			return _p0._0;
		case 'EditFontFamily':
			return _p0._0;
		default:
			return _p0._0;
	}
};
var _minekoa$elm_text_editor$StyleSetter$Model = F5(
	function (a, b, c, d, e) {
		return {bgColor: a, fgColor: b, fontFamily: c, fontSize: d, editTarget: e};
	});
var _minekoa$elm_text_editor$StyleSetter$SelectableList = F2(
	function (a, b) {
		return {value: a, list: b};
	});
var _minekoa$elm_text_editor$StyleSetter$EditFontSize = F3(
	function (a, b, c) {
		return {ctor: 'EditFontSize', _0: a, _1: b, _2: c};
	});
var _minekoa$elm_text_editor$StyleSetter$EditFontFamily = F3(
	function (a, b, c) {
		return {ctor: 'EditFontFamily', _0: a, _1: b, _2: c};
	});
var _minekoa$elm_text_editor$StyleSetter$EditColor = F3(
	function (a, b, c) {
		return {ctor: 'EditColor', _0: a, _1: b, _2: c};
	});
var _minekoa$elm_text_editor$StyleSetter$TouchFontFalily = {ctor: 'TouchFontFalily'};
var _minekoa$elm_text_editor$StyleSetter$TouchFontSize = {ctor: 'TouchFontSize'};
var _minekoa$elm_text_editor$StyleSetter$TouchForegroundColor = {ctor: 'TouchForegroundColor'};
var _minekoa$elm_text_editor$StyleSetter$TouchBackgroundColor = {ctor: 'TouchBackgroundColor'};
var _minekoa$elm_text_editor$StyleSetter$view = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$class('style-setter'),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$class('menu-root'),
				_1: {
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$style(
						{
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'flex-grow', _1: '2'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'min-height', _1: '17em'},
								_1: {ctor: '[]'}
							}
						}),
					_1: {ctor: '[]'}
				}
			}
		},
		{
			ctor: '::',
			_0: A2(
				_elm_lang$html$Html$div,
				{
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$class('menu-itemlist'),
					_1: {ctor: '[]'}
				},
				{
					ctor: '::',
					_0: A2(
						_elm_lang$html$Html$div,
						{
							ctor: '::',
							_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$StyleSetter$TouchBackgroundColor),
							_1: {
								ctor: '::',
								_0: _elm_lang$html$Html_Attributes$class(
									_elm_lang$core$Native_Utils.eq(
										_minekoa$elm_text_editor$StyleSetter$targetName(model.editTarget),
										'bg-color') ? 'menu-item-active' : 'menu-item'),
								_1: {ctor: '[]'}
							}
						},
						{
							ctor: '::',
							_0: A2(
								_elm_lang$html$Html$span,
								{ctor: '[]'},
								{
									ctor: '::',
									_0: _elm_lang$html$Html$text('background-color: '),
									_1: {ctor: '[]'}
								}),
							_1: {
								ctor: '::',
								_0: A2(
									_elm_lang$html$Html$span,
									{ctor: '[]'},
									{
										ctor: '::',
										_0: _elm_lang$html$Html$text(model.bgColor.value),
										_1: {ctor: '[]'}
									}),
								_1: {ctor: '[]'}
							}
						}),
					_1: {
						ctor: '::',
						_0: A2(
							_elm_lang$html$Html$div,
							{
								ctor: '::',
								_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$StyleSetter$TouchForegroundColor),
								_1: {
									ctor: '::',
									_0: _elm_lang$html$Html_Attributes$class(
										_elm_lang$core$Native_Utils.eq(
											_minekoa$elm_text_editor$StyleSetter$targetName(model.editTarget),
											'fg-color') ? 'menu-item-active' : 'menu-item'),
									_1: {ctor: '[]'}
								}
							},
							{
								ctor: '::',
								_0: A2(
									_elm_lang$html$Html$span,
									{ctor: '[]'},
									{
										ctor: '::',
										_0: _elm_lang$html$Html$text('color: '),
										_1: {ctor: '[]'}
									}),
								_1: {
									ctor: '::',
									_0: A2(
										_elm_lang$html$Html$span,
										{ctor: '[]'},
										{
											ctor: '::',
											_0: _elm_lang$html$Html$text(model.fgColor.value),
											_1: {ctor: '[]'}
										}),
									_1: {ctor: '[]'}
								}
							}),
						_1: {
							ctor: '::',
							_0: A2(
								_elm_lang$html$Html$div,
								{
									ctor: '::',
									_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$StyleSetter$TouchFontFalily),
									_1: {
										ctor: '::',
										_0: _elm_lang$html$Html_Attributes$class(
											_elm_lang$core$Native_Utils.eq(
												_minekoa$elm_text_editor$StyleSetter$targetName(model.editTarget),
												'font-family') ? 'menu-item-active' : 'menu-item'),
										_1: {ctor: '[]'}
									}
								},
								{
									ctor: '::',
									_0: A2(
										_elm_lang$html$Html$span,
										{ctor: '[]'},
										{
											ctor: '::',
											_0: _elm_lang$html$Html$text('font-family: '),
											_1: {ctor: '[]'}
										}),
									_1: {
										ctor: '::',
										_0: A2(
											_elm_lang$html$Html$span,
											{ctor: '[]'},
											{
												ctor: '::',
												_0: _elm_lang$html$Html$text(model.fontFamily.value),
												_1: {ctor: '[]'}
											}),
										_1: {ctor: '[]'}
									}
								}),
							_1: {
								ctor: '::',
								_0: A2(
									_elm_lang$html$Html$div,
									{
										ctor: '::',
										_0: _elm_lang$html$Html_Events$onClick(_minekoa$elm_text_editor$StyleSetter$TouchFontSize),
										_1: {
											ctor: '::',
											_0: _elm_lang$html$Html_Attributes$class(
												_elm_lang$core$Native_Utils.eq(
													_minekoa$elm_text_editor$StyleSetter$targetName(model.editTarget),
													'font-size') ? 'menu-item-active' : 'menu-item'),
											_1: {ctor: '[]'}
										}
									},
									{
										ctor: '::',
										_0: A2(
											_elm_lang$html$Html$span,
											{ctor: '[]'},
											{
												ctor: '::',
												_0: _elm_lang$html$Html$text('font-size: '),
												_1: {ctor: '[]'}
											}),
										_1: {
											ctor: '::',
											_0: A2(
												_elm_lang$html$Html$span,
												{ctor: '[]'},
												{
													ctor: '::',
													_0: _elm_lang$html$Html$text(model.fontSize.value),
													_1: {ctor: '[]'}
												}),
											_1: {ctor: '[]'}
										}
									}),
								_1: {ctor: '[]'}
							}
						}
					}
				}),
			_1: {
				ctor: '::',
				_0: function () {
					var _p1 = model.editTarget;
					switch (_p1.ctor) {
						case 'EditColor':
							return A2(_minekoa$elm_text_editor$StyleSetter$colorPalette, _p1._1, _p1._2);
						case 'EditFontFamily':
							return A2(_minekoa$elm_text_editor$StyleSetter$fontFamilySelector, _p1._1, _p1._2);
						default:
							return A2(_minekoa$elm_text_editor$StyleSetter$fontSizeSelector, _p1._1, _p1._2);
					}
				}(),
				_1: {ctor: '[]'}
			}
		});
};
var _minekoa$elm_text_editor$StyleSetter$ChangeFontSize = function (a) {
	return {ctor: 'ChangeFontSize', _0: a};
};
var _minekoa$elm_text_editor$StyleSetter$ChangeFontFamily = function (a) {
	return {ctor: 'ChangeFontFamily', _0: a};
};
var _minekoa$elm_text_editor$StyleSetter$ChangeFGColor = function (a) {
	return {ctor: 'ChangeFGColor', _0: a};
};
var _minekoa$elm_text_editor$StyleSetter$ChangeBGColor = function (a) {
	return {ctor: 'ChangeBGColor', _0: a};
};
var _minekoa$elm_text_editor$StyleSetter$init = A5(
	_minekoa$elm_text_editor$StyleSetter$Model,
	_minekoa$elm_text_editor$StyleSetter$initBgColor,
	_minekoa$elm_text_editor$StyleSetter$initFgColor,
	_minekoa$elm_text_editor$StyleSetter$initFontFamily,
	_minekoa$elm_text_editor$StyleSetter$initFontColor,
	A3(_minekoa$elm_text_editor$StyleSetter$EditColor, 'bg-color', _minekoa$elm_text_editor$StyleSetter$ChangeBGColor, _minekoa$elm_text_editor$StyleSetter$initBgColor));
var _minekoa$elm_text_editor$StyleSetter$update = F2(
	function (msg, model) {
		var _p2 = msg;
		switch (_p2.ctor) {
			case 'ChangeBGColor':
				var _p3 = _p2._0;
				var bgColor = model.bgColor;
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{
							bgColor: _elm_lang$core$Native_Utils.update(
								bgColor,
								{value: _p3}),
							editTarget: A3(
								_minekoa$elm_text_editor$StyleSetter$EditColor,
								'bg-color',
								_minekoa$elm_text_editor$StyleSetter$ChangeBGColor,
								_elm_lang$core$Native_Utils.update(
									bgColor,
									{value: _p3}))
						}),
					_1: _elm_lang$core$Platform_Cmd$none
				};
			case 'ChangeFGColor':
				var _p4 = _p2._0;
				var fgColor = model.fgColor;
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{
							fgColor: _elm_lang$core$Native_Utils.update(
								fgColor,
								{value: _p4}),
							editTarget: A3(
								_minekoa$elm_text_editor$StyleSetter$EditColor,
								'fg-color',
								_minekoa$elm_text_editor$StyleSetter$ChangeFGColor,
								_elm_lang$core$Native_Utils.update(
									fgColor,
									{value: _p4}))
						}),
					_1: _elm_lang$core$Platform_Cmd$none
				};
			case 'ChangeFontFamily':
				var _p5 = _p2._0;
				var fontFamily = model.fontFamily;
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{
							fontFamily: _elm_lang$core$Native_Utils.update(
								fontFamily,
								{value: _p5}),
							editTarget: A3(
								_minekoa$elm_text_editor$StyleSetter$EditFontFamily,
								'font-family',
								_minekoa$elm_text_editor$StyleSetter$ChangeFontFamily,
								_elm_lang$core$Native_Utils.update(
									fontFamily,
									{value: _p5}))
						}),
					_1: _elm_lang$core$Platform_Cmd$none
				};
			case 'ChangeFontSize':
				var _p6 = _p2._0;
				var fontSize = model.fontSize;
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{
							fontSize: _elm_lang$core$Native_Utils.update(
								fontSize,
								{value: _p6}),
							editTarget: A3(
								_minekoa$elm_text_editor$StyleSetter$EditFontSize,
								'font-size',
								_minekoa$elm_text_editor$StyleSetter$ChangeFontSize,
								_elm_lang$core$Native_Utils.update(
									fontSize,
									{value: _p6}))
						}),
					_1: _elm_lang$core$Platform_Cmd$none
				};
			case 'TouchBackgroundColor':
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{
							editTarget: A3(_minekoa$elm_text_editor$StyleSetter$EditColor, 'bg-color', _minekoa$elm_text_editor$StyleSetter$ChangeBGColor, model.bgColor)
						}),
					_1: _elm_lang$core$Platform_Cmd$none
				};
			case 'TouchForegroundColor':
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{
							editTarget: A3(_minekoa$elm_text_editor$StyleSetter$EditColor, 'fg-color', _minekoa$elm_text_editor$StyleSetter$ChangeFGColor, model.fgColor)
						}),
					_1: _elm_lang$core$Platform_Cmd$none
				};
			case 'TouchFontFalily':
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{
							editTarget: A3(_minekoa$elm_text_editor$StyleSetter$EditFontFamily, 'font-family', _minekoa$elm_text_editor$StyleSetter$ChangeFontFamily, model.fontFamily)
						}),
					_1: _elm_lang$core$Platform_Cmd$none
				};
			default:
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{
							editTarget: A3(_minekoa$elm_text_editor$StyleSetter$EditFontSize, 'font-size', _minekoa$elm_text_editor$StyleSetter$ChangeFontSize, model.fontSize)
						}),
					_1: _elm_lang$core$Platform_Cmd$none
				};
		}
	});

var _minekoa$elm_text_editor$Main$modeline = function (model) {
	var toSelectionString = function (selection) {
		return A2(
			_elm_lang$core$Maybe$withDefault,
			'',
			A2(
				_elm_lang$core$Maybe$andThen,
				function (s) {
					return _elm_lang$core$Maybe$Just(
						A2(
							_elm_lang$core$Basics_ops['++'],
							' select:(',
							A2(
								_elm_lang$core$Basics_ops['++'],
								_elm_lang$core$Basics$toString(
									_elm_lang$core$Tuple$first(s.begin)),
								A2(
									_elm_lang$core$Basics_ops['++'],
									',',
									A2(
										_elm_lang$core$Basics_ops['++'],
										_elm_lang$core$Basics$toString(
											_elm_lang$core$Tuple$second(s.begin)),
										A2(
											_elm_lang$core$Basics_ops['++'],
											')-(',
											A2(
												_elm_lang$core$Basics_ops['++'],
												_elm_lang$core$Basics$toString(
													_elm_lang$core$Tuple$first(s.end)),
												A2(
													_elm_lang$core$Basics_ops['++'],
													',',
													A2(
														_elm_lang$core$Basics_ops['++'],
														_elm_lang$core$Basics$toString(
															_elm_lang$core$Tuple$second(s.end)),
														')')))))))));
				},
				selection));
	};
	var toIMEString = function (compositionData) {
		return A2(
			_elm_lang$core$Maybe$withDefault,
			'',
			A2(
				_elm_lang$core$Maybe$andThen,
				function (d) {
					return _elm_lang$core$Maybe$Just(
						A2(_elm_lang$core$Basics_ops['++'], '[IME] ', d));
				},
				compositionData));
	};
	var toCursorString = function (c) {
		return A2(
			_elm_lang$core$Basics_ops['++'],
			'(',
			A2(
				_elm_lang$core$Basics_ops['++'],
				_elm_lang$core$Basics$toString(c.row),
				A2(
					_elm_lang$core$Basics_ops['++'],
					', ',
					A2(
						_elm_lang$core$Basics_ops['++'],
						_elm_lang$core$Basics$toString(c.column),
						')'))));
	};
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$id('modeline'),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html_Attributes$style(
					{
						ctor: '::',
						_0: {ctor: '_Tuple2', _0: 'background-color', _1: 'black'},
						_1: {
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'color', _1: 'white'},
							_1: {ctor: '[]'}
						}
					}),
				_1: {ctor: '[]'}
			}
		},
		{
			ctor: '::',
			_0: _elm_lang$html$Html$text(
				toCursorString(model.editor.core.buffer.cursor)),
			_1: {
				ctor: '::',
				_0: _elm_lang$html$Html$text(
					toIMEString(model.editor.core.compositionPreview)),
				_1: {
					ctor: '::',
					_0: _elm_lang$html$Html$text(
						toSelectionString(model.editor.core.buffer.selection)),
					_1: {ctor: '[]'}
				}
			}
		});
};
var _minekoa$elm_text_editor$Main$appendBuffer = F2(
	function (buffer, model) {
		return _elm_lang$core$Native_Utils.update(
			model,
			{
				buffers: {ctor: '::', _0: buffer, _1: model.buffers}
			});
	});
var _minekoa$elm_text_editor$Main$makeBuffer = F2(
	function (name, content) {
		return {
			name: name,
			buffer: _minekoa$elm_text_editor$TextEditor_Buffer$init(content)
		};
	});
var _minekoa$elm_text_editor$Main$Model = F7(
	function (a, b, c, d, e, f, g) {
		return {editor: a, buffers: b, currentBufferName: c, pane: d, swkeyboard: e, style: f, filer: g};
	});
var _minekoa$elm_text_editor$Main$Buffer = F2(
	function (a, b) {
		return {name: a, buffer: b};
	});
var _minekoa$elm_text_editor$Main$FilerPane = {ctor: 'FilerPane'};
var _minekoa$elm_text_editor$Main$StyleEditorPane = {ctor: 'StyleEditorPane'};
var _minekoa$elm_text_editor$Main$KeyboardPane = {ctor: 'KeyboardPane'};
var _minekoa$elm_text_editor$Main$DebugPane = {ctor: 'DebugPane'};
var _minekoa$elm_text_editor$Main$NoPane = {ctor: 'NoPane'};
var _minekoa$elm_text_editor$Main$FilerMsg = function (a) {
	return {ctor: 'FilerMsg', _0: a};
};
var _minekoa$elm_text_editor$Main$StyleSetterMsg = function (a) {
	return {ctor: 'StyleSetterMsg', _0: a};
};
var _minekoa$elm_text_editor$Main$SWKeyboardMsg = function (a) {
	return {ctor: 'SWKeyboardMsg', _0: a};
};
var _minekoa$elm_text_editor$Main$DebuggerMsg = function (a) {
	return {ctor: 'DebuggerMsg', _0: a};
};
var _minekoa$elm_text_editor$Main$ChangePane = function (a) {
	return {ctor: 'ChangePane', _0: a};
};
var _minekoa$elm_text_editor$Main$paneChanger = function (model) {
	var tab = F2(
		function (tgtPane, s) {
			return A2(
				_elm_lang$html$Html$div,
				{
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$style(
						_elm_lang$core$Native_Utils.eq(model.pane, tgtPane) ? {
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'margin', _1: '2px 5px 0 2px'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'padding', _1: '0 1em'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'border-width', _1: '1px 1px 0px 1px'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'border-color', _1: 'gray'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'background-color', _1: 'whitesmoke'},
											_1: {
												ctor: '::',
												_0: {ctor: '_Tuple2', _0: 'color', _1: 'gray'},
												_1: {ctor: '[]'}
											}
										}
									}
								}
							}
						} : {
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'margin', _1: '2px 5px 0 2px'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'padding', _1: '0 1em'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'border', _1: 'none'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'background-color', _1: 'darkgray'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'color', _1: 'whitesmoke'},
											_1: {ctor: '[]'}
										}
									}
								}
							}
						}),
					_1: {
						ctor: '::',
						_0: _elm_lang$html$Html_Events$onClick(
							_minekoa$elm_text_editor$Main$ChangePane(tgtPane)),
						_1: {ctor: '[]'}
					}
				},
				{
					ctor: '::',
					_0: _elm_lang$html$Html$text(s),
					_1: {ctor: '[]'}
				});
		});
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$style(
				{
					ctor: '::',
					_0: {ctor: '_Tuple2', _0: 'display', _1: 'flex'},
					_1: {
						ctor: '::',
						_0: {ctor: '_Tuple2', _0: 'flex-direction', _1: 'row'},
						_1: {
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'align-items', _1: 'flex-end'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'background-color', _1: 'darkgray'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'min-height', _1: '1.5em'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: '-moz-user-select', _1: '-moz-none'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: '-khtml-user-select', _1: 'none'},
											_1: {
												ctor: '::',
												_0: {ctor: '_Tuple2', _0: '-webkit-user-select', _1: 'none'},
												_1: {
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'user-select', _1: 'none'},
													_1: {ctor: '[]'}
												}
											}
										}
									}
								}
							}
						}
					}
				}),
			_1: {ctor: '[]'}
		},
		{
			ctor: '::',
			_0: A2(
				_elm_lang$html$Html$div,
				{
					ctor: '::',
					_0: _elm_lang$html$Html_Attributes$style(
						{
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'border', _1: '1px solid gray'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'color', _1: 'gray'},
								_1: {
									ctor: '::',
									_0: _elm_lang$core$Native_Utils.eq(model.pane, _minekoa$elm_text_editor$Main$NoPane) ? {ctor: '_Tuple2', _0: 'background-color', _1: 'inherit'} : {ctor: '_Tuple2', _0: 'background-color', _1: 'silver'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'height', _1: '1em'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'width', _1: '1em'},
											_1: {
												ctor: '::',
												_0: {ctor: '_Tuple2', _0: 'margin', _1: '3px 1.5em 3px 0.5em'},
												_1: {
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'text-align', _1: 'center'},
													_1: {ctor: '[]'}
												}
											}
										}
									}
								}
							}
						}),
					_1: {
						ctor: '::',
						_0: _elm_lang$html$Html_Events$onClick(
							_minekoa$elm_text_editor$Main$ChangePane(_minekoa$elm_text_editor$Main$NoPane)),
						_1: {ctor: '[]'}
					}
				},
				{
					ctor: '::',
					_0: _elm_lang$html$Html$text('x'),
					_1: {ctor: '[]'}
				}),
			_1: {
				ctor: '::',
				_0: A2(tab, _minekoa$elm_text_editor$Main$DebugPane, 'debug'),
				_1: {
					ctor: '::',
					_0: A2(tab, _minekoa$elm_text_editor$Main$KeyboardPane, 'keyboard'),
					_1: {
						ctor: '::',
						_0: A2(tab, _minekoa$elm_text_editor$Main$StyleEditorPane, 'style'),
						_1: {
							ctor: '::',
							_0: A2(tab, _minekoa$elm_text_editor$Main$FilerPane, 'filer'),
							_1: {ctor: '[]'}
						}
					}
				}
			}
		});
};
var _minekoa$elm_text_editor$Main$ChangeBuffer = function (a) {
	return {ctor: 'ChangeBuffer', _0: a};
};
var _minekoa$elm_text_editor$Main$bufferTab = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$style(
				{
					ctor: '::',
					_0: {ctor: '_Tuple2', _0: 'display', _1: 'flex'},
					_1: {
						ctor: '::',
						_0: {ctor: '_Tuple2', _0: 'flex-direction', _1: 'row'},
						_1: {
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'align-items', _1: 'flex-end'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'background-color', _1: 'snow'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'color', _1: 'dimgray'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'padding-left', _1: '3px'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'border-top', _1: '3px solid snow'},
											_1: {
												ctor: '::',
												_0: {ctor: '_Tuple2', _0: 'border-bottom', _1: '3px solid dimgray'},
												_1: {
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'min-height', _1: '1.2em'},
													_1: {
														ctor: '::',
														_0: {ctor: '_Tuple2', _0: '-moz-user-select', _1: '-moz-none'},
														_1: {
															ctor: '::',
															_0: {ctor: '_Tuple2', _0: '-khtml-user-select', _1: 'none'},
															_1: {
																ctor: '::',
																_0: {ctor: '_Tuple2', _0: '-webkit-user-select', _1: 'none'},
																_1: {
																	ctor: '::',
																	_0: {ctor: '_Tuple2', _0: 'user-select', _1: 'none'},
																	_1: {ctor: '[]'}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}),
			_1: {ctor: '[]'}
		},
		A2(
			_elm_lang$core$List$map,
			function (buf) {
				return A2(
					_elm_lang$html$Html$div,
					{
						ctor: '::',
						_0: _elm_lang$html$Html_Attributes$style(
							_elm_lang$core$Native_Utils.eq(model.currentBufferName, buf.name) ? {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'background-color', _1: 'dimgray'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'color', _1: 'snow'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'padding', _1: '1px 0.8em'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'height', _1: '100%'},
											_1: {ctor: '[]'}
										}
									}
								}
							} : {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'background-color', _1: 'snow'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'color', _1: 'dimgray'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'padding', _1: '1px 0.8em'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'height', _1: '100%'},
											_1: {ctor: '[]'}
										}
									}
								}
							}),
						_1: {
							ctor: '::',
							_0: _elm_lang$html$Html_Events$onClick(
								_minekoa$elm_text_editor$Main$ChangeBuffer(buf.name)),
							_1: {ctor: '[]'}
						}
					},
					{
						ctor: '::',
						_0: _elm_lang$html$Html$text(buf.name),
						_1: {ctor: '[]'}
					});
			},
			model.buffers));
};
var _minekoa$elm_text_editor$Main$EditorMsg = function (a) {
	return {ctor: 'EditorMsg', _0: a};
};
var _minekoa$elm_text_editor$Main$init = function () {
	var content = '';
	var buf = A2(_minekoa$elm_text_editor$Main$makeBuffer, '*scratch*', content);
	var _p0 = A3(
		_minekoa$elm_text_editor$TextEditor$init,
		'editor-sample1',
		A2(
			_elm_lang$core$Basics_ops['++'],
			_minekoa$elm_text_editor$TextEditor_KeyBind$basic,
			A2(_elm_lang$core$Basics_ops['++'], _minekoa$elm_text_editor$TextEditor_KeyBind$gates, _minekoa$elm_text_editor$TextEditor_KeyBind$emacsLike)),
		content);
	var bm = _p0._0;
	var bc = _p0._1;
	return {
		ctor: '_Tuple2',
		_0: A7(
			_minekoa$elm_text_editor$Main$Model,
			bm,
			{
				ctor: '::',
				_0: buf,
				_1: {ctor: '[]'}
			},
			buf.name,
			_minekoa$elm_text_editor$Main$NoPane,
			_minekoa$elm_text_editor$SoftwareKeyboard$init,
			_minekoa$elm_text_editor$StyleSetter$init,
			_minekoa$elm_text_editor$Filer$init),
		_1: A2(_elm_lang$core$Platform_Cmd$map, _minekoa$elm_text_editor$Main$EditorMsg, bc)
	};
}();
var _minekoa$elm_text_editor$Main$updateMap = F2(
	function (model, _p1) {
		var _p2 = _p1;
		return {
			ctor: '_Tuple2',
			_0: _elm_lang$core$Native_Utils.update(
				model,
				{editor: _p2._0}),
			_1: A2(_elm_lang$core$Platform_Cmd$map, _minekoa$elm_text_editor$Main$EditorMsg, _p2._1)
		};
	});
var _minekoa$elm_text_editor$Main$update = F2(
	function (msg, model) {
		var _p3 = msg;
		switch (_p3.ctor) {
			case 'ChangeBuffer':
				return {
					ctor: '_Tuple2',
					_0: A2(
						_elm_lang$core$Maybe$withDefault,
						model,
						A2(
							_elm_lang$core$Maybe$andThen,
							function (buf) {
								return _elm_lang$core$Maybe$Just(
									_elm_lang$core$Native_Utils.update(
										model,
										{
											editor: A2(_minekoa$elm_text_editor$TextEditor$setBuffer, buf.buffer, model.editor),
											currentBufferName: buf.name
										}));
							},
							_elm_lang$core$List$head(
								A2(
									_elm_lang$core$List$filter,
									function (m) {
										return _elm_lang$core$Native_Utils.eq(m.name, _p3._0);
									},
									model.buffers)))),
					_1: _elm_lang$core$Platform_Cmd$none
				};
			case 'ChangePane':
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{pane: _p3._0}),
					_1: _elm_lang$core$Platform_Cmd$none
				};
			case 'EditorMsg':
				var _p4 = A2(_minekoa$elm_text_editor$TextEditor$update, _p3._0, model.editor);
				var m = _p4._0;
				var c = _p4._1;
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{editor: m}),
					_1: A2(_elm_lang$core$Platform_Cmd$map, _minekoa$elm_text_editor$Main$EditorMsg, c)
				};
			case 'DebuggerMsg':
				var _p5 = A2(_minekoa$elm_text_editor$EditorDebugger$update, _p3._0, model.editor);
				var em = _p5._0;
				var dc = _p5._1;
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{editor: em}),
					_1: A2(_elm_lang$core$Platform_Cmd$map, _minekoa$elm_text_editor$Main$DebuggerMsg, dc)
				};
			case 'SWKeyboardMsg':
				var _p6 = A3(_minekoa$elm_text_editor$SoftwareKeyboard$update, _p3._0, model.swkeyboard, model.editor);
				var kbd = _p6._0;
				var edt = _p6._1;
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{
							editor: _elm_lang$core$Tuple$first(edt),
							swkeyboard: _elm_lang$core$Tuple$first(kbd)
						}),
					_1: _elm_lang$core$Platform_Cmd$batch(
						{
							ctor: '::',
							_0: A2(
								_elm_lang$core$Platform_Cmd$map,
								_minekoa$elm_text_editor$Main$EditorMsg,
								_elm_lang$core$Tuple$second(edt)),
							_1: {
								ctor: '::',
								_0: A2(
									_elm_lang$core$Platform_Cmd$map,
									_minekoa$elm_text_editor$Main$SWKeyboardMsg,
									_elm_lang$core$Tuple$second(kbd)),
								_1: {ctor: '[]'}
							}
						})
				};
			case 'StyleSetterMsg':
				var _p7 = A2(_minekoa$elm_text_editor$StyleSetter$update, _p3._0, model.style);
				var m = _p7._0;
				var c = _p7._1;
				return {
					ctor: '_Tuple2',
					_0: _elm_lang$core$Native_Utils.update(
						model,
						{style: m}),
					_1: A2(_elm_lang$core$Platform_Cmd$map, _minekoa$elm_text_editor$Main$StyleSetterMsg, c)
				};
			default:
				var _p12 = _p3._0;
				var _p8 = A2(_minekoa$elm_text_editor$Filer$update, _p12, model.filer);
				var m = _p8._0;
				var c = _p8._1;
				var _p9 = _p12;
				if (_p9.ctor === 'ReadFile') {
					var _p11 = _p9._0;
					var _p10 = _p11.data;
					if (_p10.ctor === 'Ok') {
						var newbuf = A2(_minekoa$elm_text_editor$Main$makeBuffer, _p11.name, _p10._0);
						return {
							ctor: '_Tuple2',
							_0: _elm_lang$core$Native_Utils.update(
								model,
								{
									buffers: _elm_lang$core$List$reverse(
										{
											ctor: '::',
											_0: newbuf,
											_1: _elm_lang$core$List$reverse(model.buffers)
										}),
									currentBufferName: newbuf.name,
									editor: A2(_minekoa$elm_text_editor$TextEditor$setBuffer, newbuf.buffer, model.editor),
									filer: m
								}),
							_1: A2(_elm_lang$core$Platform_Cmd$map, _minekoa$elm_text_editor$Main$FilerMsg, c)
						};
					} else {
						return {
							ctor: '_Tuple2',
							_0: _elm_lang$core$Native_Utils.update(
								model,
								{filer: m}),
							_1: A2(_elm_lang$core$Platform_Cmd$map, _minekoa$elm_text_editor$Main$FilerMsg, c)
						};
					}
				} else {
					return {
						ctor: '_Tuple2',
						_0: _elm_lang$core$Native_Utils.update(
							model,
							{filer: m}),
						_1: A2(_elm_lang$core$Platform_Cmd$map, _minekoa$elm_text_editor$Main$FilerMsg, c)
					};
				}
		}
	});
var _minekoa$elm_text_editor$Main$subscriptions = function (model) {
	return _elm_lang$core$Platform_Sub$batch(
		{
			ctor: '::',
			_0: A2(
				_elm_lang$core$Platform_Sub$map,
				_minekoa$elm_text_editor$Main$EditorMsg,
				_minekoa$elm_text_editor$TextEditor$subscriptions(model.editor)),
			_1: {ctor: '[]'}
		});
};
var _minekoa$elm_text_editor$Main$view = function (model) {
	return A2(
		_elm_lang$html$Html$div,
		{
			ctor: '::',
			_0: _elm_lang$html$Html_Attributes$style(
				{
					ctor: '::',
					_0: {ctor: '_Tuple2', _0: 'margin', _1: '0'},
					_1: {
						ctor: '::',
						_0: {ctor: '_Tuple2', _0: 'padding', _1: '0'},
						_1: {
							ctor: '::',
							_0: {ctor: '_Tuple2', _0: 'width', _1: '100%'},
							_1: {
								ctor: '::',
								_0: {ctor: '_Tuple2', _0: 'height', _1: '100%'},
								_1: {
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'display', _1: 'flex'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'flex-direction', _1: 'column'},
										_1: {ctor: '[]'}
									}
								}
							}
						}
					}
				}),
			_1: {ctor: '[]'}
		},
		{
			ctor: '::',
			_0: A2(
				_elm_lang$html$Html$h1,
				{ctor: '[]'},
				{
					ctor: '::',
					_0: _elm_lang$html$Html$text('TextEditor Sample'),
					_1: {ctor: '[]'}
				}),
			_1: {
				ctor: '::',
				_0: _minekoa$elm_text_editor$Main$bufferTab(model),
				_1: {
					ctor: '::',
					_0: A2(
						_elm_lang$html$Html$div,
						{
							ctor: '::',
							_0: _elm_lang$html$Html_Attributes$style(
								{
									ctor: '::',
									_0: {ctor: '_Tuple2', _0: 'margin', _1: '0'},
									_1: {
										ctor: '::',
										_0: {ctor: '_Tuple2', _0: 'padding', _1: '0'},
										_1: {
											ctor: '::',
											_0: {ctor: '_Tuple2', _0: 'width', _1: '100%'},
											_1: {
												ctor: '::',
												_0: {ctor: '_Tuple2', _0: 'height', _1: '100%'},
												_1: {
													ctor: '::',
													_0: {ctor: '_Tuple2', _0: 'overflow', _1: 'hidden'},
													_1: {
														ctor: '::',
														_0: {ctor: '_Tuple2', _0: 'flex-grow', _1: '8'},
														_1: {
															ctor: '::',
															_0: {ctor: '_Tuple2', _0: 'color', _1: model.style.fgColor.value},
															_1: {
																ctor: '::',
																_0: {ctor: '_Tuple2', _0: 'background-color', _1: model.style.bgColor.value},
																_1: {
																	ctor: '::',
																	_0: {ctor: '_Tuple2', _0: 'font-family', _1: model.style.fontFamily.value},
																	_1: {
																		ctor: '::',
																		_0: {ctor: '_Tuple2', _0: 'font-size', _1: model.style.fontSize.value},
																		_1: {ctor: '[]'}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}),
							_1: {ctor: '[]'}
						},
						{
							ctor: '::',
							_0: A2(
								_elm_lang$html$Html$map,
								_minekoa$elm_text_editor$Main$EditorMsg,
								_minekoa$elm_text_editor$TextEditor$view(model.editor)),
							_1: {ctor: '[]'}
						}),
					_1: {
						ctor: '::',
						_0: _minekoa$elm_text_editor$Main$modeline(model),
						_1: {
							ctor: '::',
							_0: _minekoa$elm_text_editor$Main$paneChanger(model),
							_1: {
								ctor: '::',
								_0: function () {
									var _p13 = model.pane;
									switch (_p13.ctor) {
										case 'NoPane':
											return _elm_lang$html$Html$text('');
										case 'DebugPane':
											return A2(
												_elm_lang$html$Html$map,
												_minekoa$elm_text_editor$Main$DebuggerMsg,
												_minekoa$elm_text_editor$EditorDebugger$view(model.editor));
										case 'KeyboardPane':
											return A2(
												_elm_lang$html$Html$map,
												_minekoa$elm_text_editor$Main$SWKeyboardMsg,
												_minekoa$elm_text_editor$SoftwareKeyboard$view(model.swkeyboard));
										case 'StyleEditorPane':
											return A2(
												_elm_lang$html$Html$map,
												_minekoa$elm_text_editor$Main$StyleSetterMsg,
												_minekoa$elm_text_editor$StyleSetter$view(model.style));
										default:
											return A2(
												_elm_lang$html$Html$map,
												_minekoa$elm_text_editor$Main$FilerMsg,
												_minekoa$elm_text_editor$Filer$view(model.filer));
									}
								}(),
								_1: {ctor: '[]'}
							}
						}
					}
				}
			}
		});
};
var _minekoa$elm_text_editor$Main$main = _elm_lang$html$Html$program(
	{init: _minekoa$elm_text_editor$Main$init, view: _minekoa$elm_text_editor$Main$view, subscriptions: _minekoa$elm_text_editor$Main$subscriptions, update: _minekoa$elm_text_editor$Main$update})();

var Elm = {};
Elm['Main'] = Elm['Main'] || {};
if (typeof _minekoa$elm_text_editor$Main$main !== 'undefined') {
    _minekoa$elm_text_editor$Main$main(Elm['Main'], 'Main', undefined);
}

if (typeof define === "function" && define['amd'])
{
  define([], function() { return Elm; });
  return;
}

if (typeof module === "object")
{
  module['exports'] = Elm;
  return;
}

var globalElm = this['Elm'];
if (typeof globalElm === "undefined")
{
  this['Elm'] = Elm;
  return;
}

for (var publicModule in Elm)
{
  if (publicModule in globalElm)
  {
    throw new Error('There are two Elm modules called `' + publicModule + '` on this page! Rename one of them.');
  }
  globalElm[publicModule] = Elm[publicModule];
}

}).call(this);

