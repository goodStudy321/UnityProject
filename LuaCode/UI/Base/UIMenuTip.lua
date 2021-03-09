--region UIMenuTip.lua
--Date
--此文件由[HS]创建生成

UIMenuTip = UIBase:New{Name ="UIMenuTip"}
local M = UIMenuTip

--注册的事件回调函数

function M:InitCustom()
	self.Persitent = true;
	local name = "结算信息面板"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Panel = self.gbj:GetComponent("UIPanel")

	self.Container = T(trans, "Container")

	self.Background = C(UISprite, trans, "Tip", name, false)
	self.Tip = self.Background.transform

	self.Grid = C(UIGrid, trans, "Tip/Grid", name, false)
	self.Prafab = T(trans, "Tip/Grid/Item")

	self.Items = {}

	local factor = UnityEngine.Screen.height / UIMgr.uiRoot.activeHeight
	self.screenw = (UnityEngine.Screen.width / factor) / 2
	self.screenh = UIMgr.uiRoot.activeHeight / 2
	self.offsetH = self.Background.width
	self.offsetV = 0
	self:AddEvent()
end

function M:stopDelayClose()
    if self.delayCloseTimer == nil then return end

    self.canCloseByClickContainer = true
    self.delayCloseTimer:Stop()
    ObjPool.Add(self.delayCloseTimer)
    self.delayCloseTimer = nil
end

function M:startDelayClose()
    if self.delayCloseTimer == nil then
        self.delayCloseTimer = ObjPool.Get(iTimer)
    end
    self.delayCloseTimer:Stop()
    self.delayCloseTimer:Start(0.3)

    self.canCloseByClickContainer = false
    self.delayCloseTimer.complete:Add(function()
        self.canCloseByClickContainer = true
    end)
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.Container then
		E(self.Container,self.OnClickContainer, self, nil, false)
	end

	local EH = EventHandler
	self.OnUpdteaMenuTip = EH(self.UpdteaMenuTip, self)
	self.OnGridReposition = EH(self.GridReposition, self)
	EventMgr.Add("UpdteaMenuTip",self.OnUpdteaMenuTip)
	EventMgr.Add("MenuTipReposition",self.OnGridReposition)
	
end

function M:RemoveEvent()
	EventMgr.Remove("UpdteaMenuTip",self.OnUpdteaMenuTip)
	EventMgr.Remove("MenuTipReposition",self.OnGridReposition)
end

function M:UpdateUI(menu, icon, action)
	self.Menu = menu
	local len = menu.Count - 1
	local llen = LuaTool.Length(self.Items)
	if llen < menu.Count then
		for i=llen,len do
			self:AddItem(i)
		end
	elseif llen > menu.Count then
		for i=len + 1,llen - 1 do
			self:RemoveItem(i)
		end
	end
	self:UpdateUIData(menu,icon,action)
	local height = (menu.Count * self.Grid.cellHeight) + math.abs(self.Grid.transform.localPosition.y) / 2 - 10
	self.Background.height = height
	self.offsetV = height
	self:GridReposition()
end

function M:GridReposition()
	if self.Grid then
		self.Grid:Reposition()
	end
end

function M:UpdateUIData(menu, icon, action)
	local len = menu.Count - 1
	for i=0, len do
		local key = tostring(i)
		local item = self.Items[key]
		if item then 
			if item.Menu then
				item.Menu.text = menu[i]
			end
			if item.Action then
				if action.Count  > i then
					item.Action:SetActive(action[i])
				end
			end
			local n = "rank_1"
			if icon ~= nil then
				if i==0 then
					n = "rank_1"
				else
					if menu[i]=="开始聊天" then
						n = "rank_3"
					else
						n = "rank_4"
					end				
				end
			end
			if item.Icon then
				--item.Icon.spriteName = n
			end
			item.Root.gameObject:SetActive(true)
		end 
	end
end

function M:AddItem(index)
	local key = tostring(index)
	local go = GameObject.Instantiate(self.Prafab)
	go.name = key
	local trans = go.transform
	trans.parent = self.Grid.transform
	trans.localPosition = Vector3.zero
	trans.localScale = Vector3.one
	go:SetActive(true)

	
	UITool.SetLsnrSelf(go,self.ClickMenu, self, nil, false)
	self.Items[key] = {}
	local C = ComTool.Get
	local T = TransTool.FindChild
	local n = "UIMenuTip:AddItem"
	local item = self.Items[key]
	item.Root = go
	item.Menu = C(UILabel, trans, "Label", n, false)
	item.Bg = C(UISprite, trans, "Background", n, false)
	item.Icon = C(UISprite, trans, "Icon", n, false)
	item.Action = T(trans, "Action")
end

function M:RemoveItem(index)
	local key = tostring(index)
	if self.Items[key] then self.Items[key].Root.gameObject:SetActive(false) end
end

function M:UpdateAction(index, action)
	local data = self.Items[index]
	if not data then return end
	data.Action:SetActive(action)
end

function M:UpdteaMenuTip(trans, tt, pos, items, icons, actions, posType)
	self.trans = trans
	self.TargetType = tt
	self:UpdateUI(items, icons, actions)
	local tip = self.Tip
	if tip == nil then return end
	tip.position = pos
	tip.localPosition = self:TipReposition(tip.localPosition, false, posType)
	--self.Container.transform.localPosition = self.Background.transform.localPosition
end

function M:TipReposition(pos, isbool, posType)
	if posType == 0 then
		pos = self:AutoReposition(pos, isbool)
	elseif posType == 1 then
		pos = self:HReposition(pos, true)
	elseif posType == 2 then
		pos = self:HReposition(pos, false)
	elseif posType == 3 then
		pos = self:TReposition(pos, isbool)
	end

	return Vector3.New(pos.x,pos.y,0)
end

function M:AutoReposition(pos, isbool)
	if pos.x + self.offsetH > self.screenw then --右边超出画面
		pos.x = pos.x - self.offsetH / 2
		pos = self:TipReposition(pos, true)
	elseif pos.x - self.offsetH < - self.screenw then --左边超出屏幕
		pos.x = pos.x + self.offsetH / 2
		pos = self:TipReposition(pos, true)
	elseif not isbool then
		pos.x = pos.x + self.offsetH / 2
	end

	if pos.y - self.offsetV < -self.screenh then --下面超出画面
		pos.y = pos.y + self.offsetV
		pos = self:TipReposition(pos, true)
	end
	return pos
end

function M:HReposition(pos, isLeft)
	if isLeft == true then
		pos.x = pos.x - self.offsetH / 2
	else
		pos.x = pos.x + self.offsetH / 2
	end
	return pos
end

function M:TReposition(pos, isbool)
	pos.y = pos.y + self.offsetV
	return pos
end

function M:ClickMenu(go, isPressed)
	local y = self.Grid.transform.localPosition.y + go.transform.localPosition.y
	if isPressed == true then return end
	local key =  string.gsub(go.name, "Item_", "")
	local index = tonumber(key)
	if self.Items[key] and self.Items[key].Menu then
		EventMgr.Trigger("ClickMenuTipAction",self.trans.name, self.TargetType, self.Items[key].Menu.text, index)
	end
	self:Close()
end

function M:OnClickContainer(go)
    if not self.canCloseByClickContainer then return end
	self:Close()
end

function M:Show()
	if self.gbj then self.gbj:SetActive(true) end
	self:GridReposition()
end

function M:Hide()
	if self.gbj then self.gbj:SetActive(false) end
	if self.HightLight then self.HightLight:SetActive(false) end
end

function M:OpenCustom()
    self:startDelayClose()
	if self.Panel then self.Panel.depth = 8880 end
	self:Show()
end

function M:CloseCustom()
    self:stopDelayClose()
	self:Hide()
	self.TargetType = nil
end

--是否能被记录
function M:CanRecords()
	do return false end
end

function M:DisposeCustom()
	self:RemoveEvent()
end

return M
--endregion
