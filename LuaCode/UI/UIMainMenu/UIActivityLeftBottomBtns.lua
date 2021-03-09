--region UIActivityLeftBottomBtns.lua
--Date
--此文件由[HS]创建生成

UIActivityLeftBottomBtns = UIActivityBaseBtns:New{Name="UIActivityLeftBottomBtns"}
local M = UIActivityLeftBottomBtns

local aMgr = ActivityMgr
local sMgr = SurverMgr
local oMgr = OpenMgr

M.ePlayTweenEnd = Event()

function M:CustomInit(trans)
	local name = "左下角按钮区"

	self.LeftCenter = TransTool.FindChild(trans, "Bottom/LeftButtom", name, false)
	self.ItemRoot = TransTool.FindChild(trans, "Bottom/LeftButtom/Root", name, false)

	self.PlayTween = self.ItemRoot:GetComponent("UIPlayTween")
	self.TweenPos = self.ItemRoot:GetComponent("TweenPosition")
	self.Items = {}

	self.OnPlayTweenCallback = EventDelegate.Callback(self.OnTweenFinished, self)
	EventDelegate.Add(self.PlayTween.onFinished, self.OnPlayTweenCallback)
end

function M:UpdateBottomStatus(value)
	local tweenPos = self.TweenPos
	local playTween = self.PlayTween
	if tweenPos then
		local delay = 0
		if value == false then
			delay = 0.2
		end
		tweenPos.delay = delay
	end
	if playTween then
		playTween:Play(value)
	end
end

--更新数据
function M:InitData()
	local dic = aMgr.Info
	local temps = dic["7"]
	if temps then
		local len = #temps
		for j=1,len do
			local temp = temps[j]
			if temp then
				if temp.id ~= aMgr.CDGN then
					if temp.layer ~= aMgr.CDGN then
						self:AddItem(temp, true)
					else
						if self.Menus then self.Menus:AddItem(temp) end
					end
				end
			end
		end
	end
	self:RenovatePos()
end

--自定义增加item
function M:CustomAddItem(layer, item, change)
	local root = self.ItemRoot
	if LuaTool.IsNull(root) then return end
	self:CheckLayer(layer)
	local k = tostring(layer)
	item.Root.parent = root.transform
	item.CurLayer = layer
	table.insert(self.Items[k],item)
end

--自定义移除item
function M:CustomRemoveItem(layer, index)
	local k = tostring(layer)
	local items = self.Items
	if items[k] and items[k][index] then
		local btn = items[k][index]
		btn:Reset()
		btn.GO:SetActive(false)
		btn.Root.parent = self.ItemRoot.transform
		self:SetItem(btn)
		table.remove(items[k], index)
	end
end

--获取按钮目标位置
function M:GetTargetPos(layer, index)
	local startX = 0
	local xp,yp = 0,0
	local offsetX = 87.6
	xp = startX + (offsetX * (index - 1))
	return Vector3.New(xp , yp, 0)
end

function M:GetTarPos(temp)
	local pos = nil
	local root = nil
	local parent = self.Parent
	if parent then
		if parent.IsBottomStatus == true then
			root = parent.gameObject.transform
			pos = parent.LB.transform.localPosition
			pos.x = pos.x + 36
			pos.y = pos.y + 40
			self.OpenData = parent.LB
		else
			root = self.ItemRoot
			local layer = temp.layer
			local index = temp.index
			if temp.layer == 0 then
				pos = self:GetTargetPos(index, layer)
				local key = tostring(layer)
				if self.Items[key] then
					if #self.Items[key] >= index then
						self.OpenData = self.Items[key][index]
					end
				end
			else
				pos = self:AddSystem(temp, false)
			end
		end
	end
	return root, pos
end

--状态  true 按钮隐藏  false 按钮弹出
function M:PlayTweenStatus()
	local playTween = self.PlayTween
	if playTween then
		return playTween.isPlayStatus
	end
	return true
end

--状态  true 按钮隐藏  false 按钮弹出
function M:OnTweenFinished()
	if self.PlayTween then 
		local value = self.PlayTween.isPlayStatus
		if value == true then
			self.ePlayTweenEnd(true)
		else
			self.ePlayTweenEnd(false)
		end
	end
	local parent = self.Parent
	if parent then
		parent.IsPlayBottomBtn = false
	end
end

function M:Dispose()
	EventDelegate.Remove(self.PlayTween.onFinished, self.OnPlayTweenCallback)
end
--endregion
