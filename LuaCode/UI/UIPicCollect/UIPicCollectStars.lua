--region UIPicCollectStars.lua
--Date
--此文件由[HS]创建生成


UIPicCollectStars = Super:New{Name="UIPicCollectStars"}
local M = UIPicCollectStars


function M:Init(go)
	self.Root = go
	local name = "图鉴Stars"
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Stars = {}
	for i=1,5 do
		table.insert(self.Stars, C(UISprite, trans, "Star"..i, name, false))
	end
end

function M:ShowStar(star)
	star = star or 0
	self:Clear()
	local stars = self.Stars
	if star < 1 then return end
	if not star then return end
	if #stars < star then return end
	for i=1,star do
		stars[i].spriteName = "star_light"
	end
end

function M:SetActive(value)
	if self.Root then self.Root:SetActive(value) end
end

function M:Clear()
	local list = self.Stars
	if list then
		for i,v in ipairs(list) do
			v.spriteName = "star_dark"
		end
	end
end

function M:Dispose()
	local list = self.Stars
	if list then
		local len = #list
		while len > 0 do
			local sp = list[len]
			if sp then
				Destroy(sp)
			end
			sp = nil
			table.remove(self.Stars, len)
			len = #list
		end
	end
	list = nil
end
--endregion
