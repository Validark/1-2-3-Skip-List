-- 1-2-3 Skip List
-- @author Validark
-- @url https://github.com/Validark/1-2-3-Skip-List

local SkipList = {}
SkipList.__index = SkipList

function SkipList.new(nodeToString)
	return setmetatable({}, SkipList)
end

function SkipList.__index:Add(value)
	local right, left = self:Search(value)
	left[1] = { value = value, [1] = right }
end

-- 1-2-3 skip list search Θ(lg n)
-- This is a very simple algorithm, slightly simpler than the paper :)
-- The algorithm operates on the set of nodes between `left` and `right`
-- We iterate from the top express lane to the bottom
-- 	at each step, we advance 3 nodes, stopping when we find `right`
-- 	determine which set of nodes we're between, set those to `left` and `right` accordingly
function SkipList.__index:Search(value)
	local left = self
	-- The paper authors make self-referential infinity nodes on the far right, but we can just use `nil`
	local right = nil

	-- case 0: |left| -> |right| (this case happens because we don't do demotions when we extract-min)
	-- case 1: |left| -> |e1| -> |e2=right|
	-- case 2: |left| -> |e1| -> |e2| -> |e3=right|
	-- case 3: |left| -> |e1| -> |e2| -> |e3| -> |e4=right (no need to check)| (promote e2!)
	for lane = #self, 1, -1 do
		local e1 = left[lane]
		if e1 ~= right then -- do nothing for case 0
			local e2 = e1[lane]
			if e2 == right then -- case 1
				if value < e1.value then
					right = e1
				else
					left = e1
				end
			else
				local e3 = e2[lane]
				if e3 == right then -- case 2
					if value < e1.value then
						right = e1
					elseif value < e2.value then
						left = e1
						right = e2
					else
						left = e2
					end
				else -- case 3, `e4` is guarenteed to be `right`
					-- promote e2 to the next level
					e2[lane + 1] = left[lane + 1]
					left[lane + 1] = e2

					-- the nested conditions above could be combined with this one if we want to check eN == right again,
					-- just make sure to do the promotion before modifying `left`
					if value < e1.value then
						right = e1
					elseif value < e2.value then
						left = e1
						right = e2
					elseif value < e3.value then
						left = e2
						right = e3
					else
						left = e3
					end
				end
			end
		end
	end

	return right, left
end

-- This simply advances the head pointers by 1, so Θ(1) on average, but Θ(log n) with tiny constants in the worst case
-- We don't do any balancing, which means there might be a tall node in front that our insertion algorithm has to deal with.
-- That means our insertion algorithm might check the very first node before actually "binary searching",
-- giving us Θ(1) extra work, so the overall complexity isn't affected
function SkipList.__index:Pop()
	local top = self[1]
	for h = 1, #self do
		if self[h] ~= top then break end
		self[h] = top[h]
	end
	return top.value
end

function SkipList.__index:Top()
	return self[1]
end

-- The code block below is exclusively for pretty printing the Skip List, and not meant to be clean at all
do
	local function visualizer(l, layers, h, current, target)
		local layer = layers[l]
		local n = 0 -- keeps count of how many characters we are adding to this layer so we can fill upper layers
		local next = current[h]
		while next and next ~= target do
			local k = h == 1 and 1 or visualizer(l + 1, layers, h - 1, current, next)
			local value = tostring(next.value)
			table.insert(layer, string.rep("→", k) .. value)
			n = n + k + string.len(value)
			current = next
			next = next[h]
		end
		local k = h == 1 and (next and 1 or 0) or visualizer(l + 1, layers, h - 1, current, next)
		table.insert(layer, string.rep("→", k) .. (next and tostring(next.value) or ""))
		return n + k
	end

	function SkipList:__tostring()
		if #self == 0 then return "H→E" end
		local layers = {}
		for i = 1, #self do layers[i] = { "H" } end
		visualizer(1, layers, #self, self)
		for i = 1, #self do layers[i] = table.concat(layers[i]) .. "→E" end
		return table.concat(layers, "\n")
	end
end

return SkipList
