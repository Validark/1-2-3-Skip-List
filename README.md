# 1-2-3-Skip-List
A deterministic 1-2-3 Skip List that supports Θ(lg n) searches and insertions and Θ(1) amortized min-extractions [based upon this 1992 paper by Munro, Papadakis, Sedgewick](https://www.ic.unicamp.br/~celio/peer2peer/skip-net-graph/deterministic-skip-lists-munro.pdf). This particular implementation of the Skip List is intended to be used as a Priority Queue. My hope is that this code is so simple, it can be easily transferred to a highly efficient implementation in a low-level language with a bunch of allocator tricks that tree data structures usually benefit from.

###### For now, the Delete operation is not included, as it necessitates either nodes exchanging data or doing two searches (e.g. in the case of the tallest element being deleted). For this reason, I've left it out of the initial version until someone requests it. I have a WIP version, but I'm not sure which way to implement it is preferable. The Delete operation is better suited to an Alternating Skip List, but an Alternating Skip List couldn't support Θ(1) amortized min-extractions.

Here's what a 1-2-3 Skip List looks like, using the included visualizer:

	  H→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→15→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→→E
	  H→→→→→→→→→→→5→→→→→→→→→10→→→→→→→→→→→→→15→→→→→→→→→→→→→→→→→→→→→→23→→→→→→→→→→→→→→→→→→→→→→E
	  H→→→→→→→3→→→5→→→→→8→→→10→→→→12→→→→→→→15→→→→→→→→→→19→→→→21→→→→23→→→→25→→→→→→→→→→29→→→→E
	  H→0→1→2→3→4→5→6→7→8→9→10→11→12→13→14→15→16→17→18→19→20→21→22→23→24→25→26→27→28→29→30→E

The bottommost row is a plain linked list, which is the foundation of the data structure.
The rows above the bottom are "express lanes" that *basically* allow you to perform a binary search on your Linked List!
The invariant maintained in this structure is that only 1, 2, or 3 elements are allowed between
each express stop on the layer underneath. As a special case, we allow 0 elements to be between the Head and the first node so we don't have to do rebalancing during Pop() operations. This particular invariant has the nice property that we don't need to keep track of the position in each layer where we descend in order to promote express stops to higher lanes. Instead, we always promote the middle element when we see a set of 3 elements between express lanes as we descend to lower lanes. (tldr, no stack needed, promote the middle of 3 as we descend). This is an "array implementation", meaning each node is a dynamic array of pointers and a value.

## Demo
#### Basic usage
```lua
-- make a SkipList
local skipList = SkipList.new()
local t = {}
-- This uses two-digit numbers so you can visually judge where the bi/trisecting points are
for i = 10, 65 do table.insert(t, i) end
for i = 1, #t do
	local num = table.remove(t, math.random(#t)) -- Θ(n²) in the average case, only use this for small tests
	
	-- skipLists will work with numbers and strings by default
	skipList:Add(num) -- Θ(lg n)
end

print(skipList)

while skipList:Top() do -- Θ(1)
	local top = skipList:Pop() -- Θ(1) amortized
	table.insert(t, top)
end
print()
print("[ " .. table.concat(t, ",") .. " ]")
```

#### Usage with metatables
```lua
local Node = {
	__lt = function(a, b) return a.n > b.n end; -- sort in ascending order
	__tostring = function(a) return "" .. a.n end;
}
function Node.new(n)
	return setmetatable({ n = n }, Node)
end
local skipList = SkipList.new()
skipList:Add(Node.new(25))
skipList:Add(Node.new(42))
skipList:Add(Node.new(17))
skipList:Add(Node.new(95))
skipList:Add(Node.new(11))
print(skipList)
```


## Complexity analysis
- Θ(1) amortized extract-min operations, Θ(lg n) in the worst case
	- To extract the minimum element, we simply advance the head pointer(s) by 1 without rebalancing.
	- The height of the Skip List is bounded by Θ(lg n), so a Pop() operation could advance Θ(lg n) pointers in the worst case, but above ~80% of nodes are height 1 or 2, so intuitively the vast majority of nodes are of a constant size.
	- 1-2-3 skips lists have ~1.5n pointers on average, so over the course of n extract-min operations we'll average ~1.5 pointers per operation. That's Θ(1) on average.
	
		[![image](https://user-images.githubusercontent.com/15217173/131717626-2a1980af-990f-4897-966e-c0d2c1f2541f.png)
](https://www.wolframalpha.com/input/?i=Summation+%E2%80%8Bh%3D0%2C+%E2%80%8Blog_3%28n%29+of%E2%80%8B%E2%80%8B+%28n%2F+%E2%80%8B3%5E%28+%E2%80%8Bh+%29%29%E2%80%8B+) [![image](https://user-images.githubusercontent.com/15217173/131729634-725fd2db-dc17-48e2-9eeb-c38e10418525.png)
](https://www.wolframalpha.com/input/?i=T%28n%29+%3D+T%28n+%2F3%29+%2B+n)
	
- Θ(lg n) insertions (all cases)
	- comparisons: According to the paper, 3lg n + Θ(1) for worst case, ~1.2 lg n + Θ(1) for average case
	- pointer modifications/promotions: Θ(lg n) worst case, Θ(1) amortized
		- Figure there are about ~0.5n promoted express points for n elements, each taking amortized Θ(1) time to promote, so we'd expect the average to take Θ(1) time. See below for a more in-depth analysis

	- array resizing: Θ(lg lg n) resizes in the worst case, totalling Θ(lg n) time
		- In Lua, arrays use a doubling strategy, starting at size 4. Imagine ⌊lg(n + 1)⌋ = 9
			If we promote an element in every layer, then we will do ⌊lg₂9⌋ - 1 array resizes.
			In this case, a capacity-8 array gets resized to capacity-16 when we append a 9th element
			and a capacity-4 array gets resized to 8 when we append a 5th element. Note that promoting a 2 to a 3
			doesn't require a resize because our default capacity is 4. That means the amount of doubling necessary is
			⌊lg₂(⌊lg₃(n + 1)⌋)⌋ - 1, and the doubling takes Θ(height) time, where the doubling heights are ~lg₃(n)/2^h from
			h = 0 up to the above equation. Here's a visual representation:
			
				H→→→→→→→→→→→→→→→→LAYER_9→→→→→→→→→→→→→→→→E
				H→→→→→→→→→→→→→→→→LAYER_8→→→→→→→→→→→→→→→→E + 8 capacity when we promote a node from this layer
				H→→→→→→→→→→→→→→→→LAYER_7→→→→→→→→→→→→→→→→E
				H→→→→→→→→→→→→→→→→LAYER_6→→→→→→→→→→→→→→→→E
				H→→→→→→→→→→→→→→→→LAYER_5→→→→→→→→→→→→→→→→E
				H→→→→→→→→→→→→→→→→LAYER_4→→→→→→→→→→→→→→→→E + 4 capacity when we promote a node from this layer
				H→→→→→→→→→→→→→→→→LAYER_3→→→→→→→→→→→→→→→→E
				H→→→→→→→→→→→→→→→→LAYER_2→→→→→→→→→→→→→→→→E
				H→→→→→→→→→→→→→→→→LAYER_1→→→→→→→→→→→→→→→→E
			
			The number of layers is bounded by Θ(lg n) and the number of resizes we have to do in the worst case is bounded by Θ(lg (NUMBER OF LAYERS)). Put that together and you get Θ(lg lg n) array resizes. Each successive array being resized is half the size of the previous one, meaning our total size is Θ(lg n + lg n / 2 + lg n / 4 + lg n / 8 + ...) which converges to Θ(lg n). Here's another way to arrive upon the same conclusion:
			
			[![image](https://user-images.githubusercontent.com/15217173/131708614-a545e5c5-daaa-45ed-9201-ee7a561e2cd6.png)](https://www.wolframalpha.com/input/?i=Summation+%E2%80%8Bh%3D0%2C+log_2%28%E2%80%8Blog_3%28n%29%29-1+of%E2%80%8B%E2%80%8B+%28log_3%28n%29%2F2%5Eh%29%E2%80%8B++)
			###### (In the expression above I'm estimating the amount of copy operations, but the asymptotic complexity would be the same if I counted the space for the full allocation. Either way, these numbers are just stand-ins for constants that have different weights depending on your machine and thus this is only meant to demonstrate one way we could determine what our complexity is bounded by. I also removed a `- 1` from this calculation to make the result simpler. You could alternatively write this as a sum of lg lg n heights of 2^h, and get the same results)
			

- You could augment this data structure with width information to achieve Θ(lg n) indexing at any index, at the cost of space.
	[![image](https://user-images.githubusercontent.com/15217173/131717969-7b3f18ff-a360-4d73-9c4a-6532244b689a.png)
](https://en.wikipedia.org/wiki/Skip_list#Indexable_skiplist)

## Advantages over the alternatives
- Θ(lg n) complexity for insertions beats the Θ(n) average case complexity of flat linked lists and array implementations
- Θ(1) amortized complexity for extract-min operations beats the Θ(lg n) complexity of array-based Heaps. They usually do have faster insertions though due to low constant factors.
	- On my machine, Heap extract-min reaches 0.01's of a second on (extremely) large data sets, which adds up when we intend to pop every single element out of the queue (at some point). With a dataset of 2^24 (16777216) elements, removal from a 1-2-3 Skip list took only 2e-6 seconds for the (worst case) highest node (height is Θ(lg n)) and random insertion took ~9e-6 seconds. I could not observe any performance degradation before running out of RAM. (In LuaJIT, the smallest amount of time I can measure (above 0) is 1e-06, so these numbers are very impressive!)
- These bounds are all achieved with simple code that works great in practice!
- AVL/red-black/2-3-4 trees are more complicated to implement, and take up more space (see the paper for a comparative analysis)

Maybe this scheme deserves a mention as being competitive with the other Priority Queues. It could be the first (competitive) data structure (on Wikipedia) that achieves Θ(1) amortized complexity for the delete-min operation.
https://en.wikipedia.org/wiki/Priority_queue#Summary_of_running_times

## Related art
https://github.com/yfismine/1-2-3-DeterminSkipList
https://www.drdobbs.com/web-development/alternating-skip-lists/184404217
