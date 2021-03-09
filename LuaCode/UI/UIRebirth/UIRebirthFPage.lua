--region UIRebirthFPage.lua
--Date
--此文件由[HS]创建生成


UIRebirthFPage = {}
local M = UIRebirthFPage

local DelayActive = Loong.Game.DelayActive
local RMgr = RebirthMsg

M.Name = "转生四转分页"
--注册的事件回调函数
M.petGetWay = {
	"商城","经验副本", "未开启"
}

M.Items = {}
M.Pros = {}
M.Select = nil
M.SelectTemp = nil
M.IsNeedItem = false
M.IsNeedExd = false

function M:New()
	return self
end

function M:Init(go)
	self.Root = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	local name = self.Name
	self.IsComplete = T(trans, "IsComplete")
	self.FristName = C(UILabel, trans, "Name", name, false)
	self.NextName = C(UILabel, trans, "NName", name, false)
	self.DName = C(UILabel, trans, "Tip/DName", name, false)
	self.Destiny = C(UILabel, trans, "Destiny", name, false)
	self.Lv = C(UILabel, trans, "Lv", name, false)
	self.LvDes = C(UILabel, trans, "Lv/Label", name, false)
	self.Tip = T(trans, "Tip")
	self.NeedExp = C(UILabel, trans, "Tip/ExpValue", name, false)
	self.Need = C(UILabel, trans, "Tip/Need", name, false)
	self.Btn = C(UIButton, trans, "Button", name, false)
	self.UpBtn = C(UIButton, trans, "UpBtn", name, false)
	self.Cell = ObjPool.Get(UIItemCell)
	self.Cell:InitLoadPool(T(trans, "Tip/ItemRoot").transform)
	for i=1,12 do
		local data = {}
		data.BG = C(UISprite, trans, string.format("Container/%s",i))
		data.Name = C(UILabel, trans, string.format("Container/%s/Label",i))
		data.Select = T(trans, string.format("Container/%s/Label/ui_ts_x",i))
		data.Boom = T(trans, string.format("Container/%s/Label/ui_ts_b",i))
		--data.Show = T( trans, string.format("Container/%s/Label/ui_ts_x",i))
		table.insert(self.Items, data)
	end
	for i=1,3 do
		local data = {}
		data.Label = C(UILabel, trans, string.format("Tip/Pro%s/Label",i))
		data.Value = C(UILabel, trans, string.format("Tip/Pro%s",i))
		table.insert(self.Pros, data)
	end

end

function M:InitData()
	self.LimitDestiny = #RebirthFTemp
	self.RebirthTemp = Rebirth[4]
	if self.Items then 
		for i=1,self.LimitDestiny do
			local data = self.Items[i]
			if data then
				data.Name.text = RebirthFTemp[i].name
			end
		end
	end
	if UserMgr.RoleLv then
		if self.LvDes then
			self.LvDes.text = string.format( "达到%s级 ", UserMgr.RoleLv.Value3)
		end
	end
end

function M:AddEvent()
	local M = EventMgr.Add
	self:UpdateEvent(M)
	self:SetEvent("Add")
	local US = UITool.SetLsnrSelf
	if self.Items then
		for i=1,#self.Items do
			local item = self.Items[i].BG
			US(item, self.OnClickItem, self, nil, false)
		end
	end
	US(self.Btn, self.OnClickBtn, self)
	US(self.UpBtn, self.OnClickUpBtn, self)
end

function M:RemoveEvent()
	local M = EventMgr.Remove
	self:UpdateEvent(M)
	self:SetEvent("Remove")
end

function M:UpdateEvent(M)
   	local EH = EventHandler
end

function M:SetEvent(fn)
	UserMgr.eLvEvent[fn](UserMgr.eLvEvent, self.UpdateLv, self)
	UserMgr.eLvUpdate[fn](UserMgr.eLvUpdate, self.UpdateLv, self)
	RMgr.eDestinyUp[fn](RMgr.eDestinyUp, self.UpdateData, self)
	RMgr.eRefresh[fn](RMgr.eRefresh, self.UpdateRefresh, self)
	PropMgr.eUpdate[fn](PropMgr.eUpdate, self.UpdateCell, self)
end

function M:UpdateData()
	local index = RMgr.DestinyId + 1
	local temp = RebirthFTemp[index]
	self:UpdateName()
	self:UpdateDestiny()
	self:UpdateLv()
	self:UpdateItemDes(temp)
	self:UpdateItems()
	self:UpdateRefresh()
end

--更新名字
function M:UpdateName()
    local rbLev = RebirthMsg.RbLev;
	if self.FristName then
		self.FristName.text = UIMisc.GetRBPN(User.MapData.Category, rbLev)
	end
	if self.NextName then
		self.NextName.text = UIMisc.GetRBPN(User.MapData.Category, rbLev + 1)
	end
end

--更新觉醒要求
function M:UpdateDestiny()
	if not self.Destiny then return end
	self.Destiny.text = self:GetConditionText(RMgr.DestinyId, self.LimitDestiny)
end

--更新等级要求
function M:UpdateLv()
	if not self.Lv then return end
	if not UserMgr.RoleLv then return end
	self.Lv.text = self:GetConditionText(UserMgr:GetRealLv(), UserMgr.RoleLv.Value3)
end

function M:UpdateItems()
	local index = RMgr.DestinyId
	for i=1, self.LimitDestiny do
		self:DestinyStatus(i, i <= index)
	end
end

function M:UpdateRefresh()
	local index = RMgr.DestinyId
	local lvState = RMgr.RbLev >= 4
	local active = index + 1 <= self.LimitDestiny
	if self.Tip then self.Tip:SetActive(active) end
	if self.UpBtn then
		self.UpBtn.gameObject:SetActive( not lvState and not active)
	end
	if self.IsComplete then
		self.IsComplete:SetActive(index >= self.LimitDestiny and lvState)
	end
end

--按钮状态
function M:DestinyStatus(index, status)
	local items = self.Items
	if not items then return end
	local data = items[index]
	if not data then return end
	local sName = "jc_icon_01"
	local color = "926c46"
	if status == true then
		sName = "jc_icon_0121"
		color = "FCF5F5"
		if data.BG.spriteName ~= sName then
			data.Boom:SetActive(true)
			--data.Show:SetActive(true)
		end
	end
	local temp = RebirthFTemp[index]
	data.BG.spriteName = sName
	if temp then
		data.Name.text = string.format("[%s]%s[-]", color, temp.name)
	end
end

--更新命格描述
function M:UpdateItemDes(temp)
	self.SelectTemp = temp
	self:Reset()
	self:UpdateSelect()
	self:UpdateCell()
	self:UpdateExp()
	self:UpdatePros()
	self:UpdateNeed()
	self:UpdateBtn()
end

function M:UpdateSelect()
	local temp = self.SelectTemp
	if self.Select then self.Select:SetActive(false) end
	local name = ""
	if temp then
		if self.Items then
			local data = self.Items[temp.index]
			if data then 
				data.Select:SetActive(true)
				self.Select = data.Select
			end
		end
		name = temp.name
	end
	if self.DName then
		self.DName.text = name
	end
end

function M:UpdateCell()
	if not self.Cell then return end
	local temp = self.SelectTemp
	if not temp then 
		self.Cell:Clean()
		return 
	end
	local itemData = temp.Items[1]
	local k = itemData.k
	local v = itemData.v
	local count = PropMgr.TypeIdByNum(k)
	local color = "ff0000"
	if count >= v then
		color = "00ff00"
		self.IsNeedItem = true
	end
	self.Cell:UpData(k, v)
	self.Cell:UpLab(string.format( "[%s]%s/%s[-]",color, count, v))
end

function M:UpdateExp()
	if self.NeedExp then
		local temp = self.SelectTemp
		local exp = 0
		if temp then exp = temp.exp end
		local uExp = tonumber(User.MapData.ExpStr)
		local need = math.NumToStrCtr(exp, 1)
		local cur = math.NumToStrCtr(uExp, 1)
		local color = "ff0000"
		if uExp >= exp then
			color = "00FF00"
			self.IsNeedExd = true
		end
		self.NeedExp.text = string.format( "[%s]%s/%s[-]", color, cur, need)
	end
end

function M:UpdatePros()
	local temp = self.SelectTemp
	local list = self.Pros
	if list then
		for i=1,#list do
			local txt = "0"
			local lab = ""
			if  temp and temp.get and temp.get[i] then
				lab = PropName[temp.get[i].k]
				txt = temp.get[i].v
			end
			list[i].Value.text = txt
		end
	end
end

function M:UpdateNeed()
	if self.Need then
		local temp = self.SelectTemp
		if temp then
			local frist = RebirthFTemp[temp.index - 1]
			self.Need.gameObject:SetActive(frist ~= nil)
			if frist then
				local color = "00FF00"
				if RMgr.DestinyId < frist.index then
					color = "ff0000"
				end
				self.Need.text = string.format("[%s]%s[-]", color, frist.name)
			end
		end
	end
end

function M:UpdateBtn()
	if self.Btn then
		local temp = self.SelectTemp
		local active = false
		local enabled = false
		local destinyIndex = RMgr.DestinyId + 1
		local curIndex = RMgr.DestinyId + 1
		if temp then curIndex = temp.index end
		if destinyIndex <= self.LimitDestiny then
			if destinyIndex <= curIndex then
				active = true
				if destinyIndex == curIndex then
					enabled = true
				end
			end
		end
		self.Btn.gameObject:SetActive(active)
		self.Btn.Enabled = enabled
	end
end

--点击命格
function M:OnClickItem(go)
	local index = tonumber(go.name)
	local temp = RebirthFTemp[index]
	if not temp then return end
	self:UpdateItemDes(temp)
end

--点击激活命格
function M:OnClickBtn()
	if self.IsNeedItem == false and self.IsNeedExd == false then
		UIMgr.Open(UIGetWay.Name, self.OpenGetWayCb ,self)
		return
	elseif self.IsNeedItem == false and self.IsNeedExd == true then
		local temp = self.SelectTemp
		local exp = 0
		if temp then exp =  math.NumToStrCtr(temp.exp) end
		MsgBox.ShowYesNo(string.format("道具不足，是否消耗[00ff00]%s经验[-]进行激活？",exp),RMgr.ReqReDestinyUp,RMgr,nil, nil ,self)
		return
	end
	RMgr:ReqReDestinyUp()
end


--获取途径界面回调
function M:OpenGetWayCb(name)
	local ui = UIMgr.Get(name)
	if self.Btn then
		local pos = self.Btn.transform.localPosition
		pos.y = pos.y + 100
		ui:SetPos(pos)
	end
	local getWay = self.petGetWay
	local len = #getWay
	for i = 1,len do
		ui:CreateCell(getWay[i], self.OnClickGetWayItem, self)
	end
end

function M:OnClickGetWayItem(name)
	if name == "商城" then
		local temp = self.SelectTemp
		if temp then 
			local itemData = temp.Items[1]
			if itemData then
				StoreMgr.OpenStoreId(itemData.k)	
			end
		end	
	elseif name == "经验副本" then
		UIMgr.Open(UICopy.Name, self.OpenCopyUI, self)
	elseif name == "未开启" then
		UITip.Error("敬请期待")
	end
end

function M:OpenCopyUI(name)
	local ui = UIMgr.Dic[UICopy.Name]
	if ui then
		ui:SetPage(CopyType.Exp)
	end
end

function M:OnClickUpBtn(go)
	local temp = UserMgr.RoleLv
	if temp then
		local lv = temp.Value3
		if UserMgr:GetRealLv() >= lv then
			RebirthMsg:SendRbDone()
		else
			UITip.Error(string.format("等级不到%s级，不能进行转生",lv))
		end
	end
end

--获取条件文本
function M:GetConditionText(cur, max)
	if not cur then cur = 0 end
	if not max then max = 0 end
	local color = "FF0000"
	if cur >= max then 
		color = "F39800"
	end
	return string.format("[%s](%s/%s)[-]", color, cur, max)
end

function M:Reset()
	self.IsNeedItem = false
	self.IsNeedExd = false
end

function M:Open()
	self:InitData()
	self:AddEvent()
	self:UpdateData()
end

function M:Close()
	self:RemoveEvent()
	self:Reset()
	self.Select = nil 
	self.SelectTemp = nil
	if self.Items then
		while #self.Items > 0 do
			table.remove(self.Items)
		end
	end
	if self.Pros then
		while #self.Pros > 0 do
			table.remove(self.Pros)
		end
	end
	if self.Cell then
		ObjPool.Add(self.Cell)
	end
end
--endregion
