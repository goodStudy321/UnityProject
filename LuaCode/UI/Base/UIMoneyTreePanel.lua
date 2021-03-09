--region UIMoneyTreePanel.lua
--Date
--此文件由[HS]创建生成

UIMoneyTreePanel = UILoadBase:New{Name ="UIMoneyTreePanel"}

local M = UIMoneyTreePanel

local MTMgr = MoneyTreeMgr

function M:Init()
	local name = "摇钱树"
	local trans = self.GbjRoot.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	-- self.Mask = T(trans,"Sprite/Mask")
	self.CloseBtn = T(trans, "Close")
	self.LuckTog = C(UIToggle, trans, "LuckTog", name, false)
	self.RecordTog = C(UIToggle, trans, "RecordTog", name, false)
	self.Btn = T(trans, "Button")
	self.Action = T(trans, "Button/Action")
	self.Tex = C(UITexture, trans, "Tex", name, false)
	self.DesLab = C(UILabel, trans, "Des", name, false)
	self.NumLab = C(UILabel, trans, "Num", name, false)
	self.TipLab = C(UILabel, trans, "Tip", name, false)
	self.CostLab = C(UILabel, trans, "Cost", name, false)
	self.CostIcon = C(UISprite, trans, "Cost/Sprite", name, false)

	self.GlodLab = C(UILabel, trans, "Glod", name, false)
	self.SliverLab = C(UILabel, trans, "Silver", name, false)
	
	self.GetEff = T(trans, "Effect/UI_jb01")
	self.GetEff_Crit = T(trans, "Effect/UI_jb01_bj")

	self.SV = C(UIScrollView, trans, "ScrollView", name, false)
	self.Panel = C(UIPanel, trans, "ScrollView", name, false)
	self.Rect = C(UIWidget, trans, "ScrollView/Root", name, false)
	self.Labs = {}
	for i=1,30 do
		table.insert(self.Labs, C(UILabel, trans, string.format("ScrollView/Root/%s", i)))
	end

	self.OffsetPos = self.Panel.transform.localPosition
	self.SVLimit = self.Panel.height

	self:BtnEvent()
	self:Event(EventDelegate.Add)

	self:SetEvent(EventMgr.Add)
	self:SetLuaEvent("Add")
end

--==============================--
--注册/移除 事件侦听
--==============================--
function M:BtnEvent()
	local E = UITool.SetLsnrSelf
	-- local mask = self.Mask
	local close = self.CloseBtn
	local luck = self.LuckTog
	local record = self.RecordTog
	local btn = self.Btn
	-- if mask then E(mask, self.Close, self) end
	-- if close then E(close, self.Close, self) end
	if luck then 
		E(luck, self.OnClickTogBtn, self, nil, false)
	end
	if record then 
		E(record, self.OnClickTogBtn, self, nil, false) 
	end
	if btn then 
		E(btn, self.OnClickBtn, self, nil, false) 
	end
end

function M:Event(e)
	local luck = self.LuckTog
	local record = self.RecordTog
	local CB = EventDelegate.Callback
	if luck then 
		e(luck.onChange, CB(self.SelectToggle, self))
	end
	if record then 
		e(record.onChange, CB(self.SelectToggle, self))
	end
end

function M:SetEvent(e)
end

function M:SetLuaEvent(fn)
    MTMgr.eRed[fn](MTMgr.eRed, self.UpdateMRed, self)
	MTMgr.eNum[fn](MTMgr.eNum, self.UpdateData, self)
	MTMgr.eUserLog[fn](MTMgr.eUserLog, self.UpdateUserLog, self)
	MTMgr.ePlayerLog[fn](MTMgr.ePlayerLog, self.UpdatePlayLog, self)
	--MTMgr.eGetMoney[fn](MTMgr.eGetMoney, self.UpdatePlayLog, self)
	VIPMgr.eVIPLv[fn](VIPMgr.eVIPLv, self.UpdateData, self)
	RoleAssets.eUpAsset[fn](RoleAssets.eUpAsset, self.UpdateRoleAssets, self)
end

function M:UpdateMRed(value)
	self.Action:SetActive(value)
end

function M:UpdateData()
	local lv,limit,nextlv,nextLimit = MTMgr:GetLimitForVip()
	self.DesLab.text = MTMgr:GetDes()
	self:UpdateCost()
	self:UpdateNum(limit)
	self:UpdateTip(nextlv, nextLimit)
	self:UpdateRoleAssets()
end

function M:UpdateNum(limit)
	local cur = limit-MTMgr.UseNum
	self.NumLab.text = string.format("%s/%s", cur, limit)
end

function M:UpdateTip(lv, limit)
	local lab = self.TipLab
	lab.gameObject:SetActive(lv ~= 0)
	if lv and limit then
		lab.text = string.format(MTMgr:GetTip(),lv, limit)
	end
end

function M:UpdateCost()
	local cost = MTMgr:GetCostForVip()
	local icon = nil
	local num = ""
	local value = false
	if cost then
		icon = string.format("money_0%s",cost.k)
		if cost.v > 0 then 
			num = UIMisc.ToString(cost.v) 
		else
			num = "免费"
			value = true
		end
	end
	self.Action:SetActive(value)
	self.CostIcon.spriteName = icon
	self.CostLab.text =  num
	self.CostLab.gameObject:SetActive(cost ~= nil)
end

function M:UpdateLogs()
	self:UpdateUserLog()
	self:UpdatePlayLog()
end

function M:UpdateUserLog(value, status)
	if value == true then
		self:UpdateEff(status)
	end
	local record = self.RecordTog
	if record and record.value == false then return end
	self:UpdateLogList(MTMgr.UserRecord)
end

function M:UpdateRoleAssets()
	local ra = RoleAssets
    local mathToStr = math.NumToStrCtr
	self.GlodLab.text = mathToStr(ra.Gold)
	self.SliverLab.text = mathToStr(ra.Silver)
end

function M:UpdateEff(status)
	if status == false then
		self.GetEff:SetActive(true)
	elseif status == true then
		self.GetEff_Crit:SetActive(true)
	end
end

function M:ResetEff()
	self.GetEff:SetActive(false)
	self.GetEff_Crit:SetActive(false)
end

function M:UpdatePlayLog()
	local luck = self.LuckTog
	if luck and luck.value == false then return end
	self:UpdateLogList(MTMgr.PlayerLuck)
end

function M:UpdateLogList(list)
	self:RestLogs()
	local len = #list
	local height = 0
	for i=1,len do
		local h = self:SetLab(i, list[i], height)
		if h > 0 then
			height = height + h
		end
	end
	self.Rect.height = height
	local panel = self.Panel
	local b = height > self.SVLimit
	if b == true then
		local offset = height - self.SVLimit
		panel.transform.localPosition = Vector3.New(self.OffsetPos.x, self.OffsetPos.y + offset ,0)
		panel.clipOffset = Vector2.New(0, -offset)
	else
		panel.transform.localPosition = self.OffsetPos
		panel.clipOffset = Vector2.zero
	end
	local sv = self.SV
	sv:DisableSpring()
	sv:RestrictWithinBounds(true,false,true)
	sv.isDrag = b
end

function M:SetLab(index, str, h)
	local labs = self.Labs
	local len = #labs
	if index <= len then
		local lab = labs[index]
		if lab then
			lab.text = str
			lab.transform.localPosition = Vector3.up * h * -1
			lab.gameObject:SetActive(true)
			return lab.height + 5
		end
	end
	return 0
end
--==============================--
--调用
--==============================--

--==============================--
--打开UI
--==============================--

--==============================--
--事件
--==============================--
function M:SelectToggle()
	local name = UIToggle.current.name
	if name == self.LuckTog.name and self.LuckTog.value == true then
		self:UpdatePlayLog()
	elseif name == self.RecordTog.name and self.RecordTog.value == true then
		self:UpdateUserLog()
	end
end

function M:OnClickTogBtn(go)
	--[[
	local name = go.name
	if name == self.LuckTog.name then
	elseif name == self.RecordTog.name then
	end
	]]--
end

function M:OnClickBtn(go)
	MTMgr:Use()
end

--==============================--
--父类调用
--==============================--

function M:Open(t1, t2, t3)
	-- self:SetEvent(EventMgr.Add)
	-- self:SetLuaEvent("Add")
	self:UpdateData()
	self:UpdateLogs()
end

--自定义关闭
function M:CloseC()
	-- self:SetEvent(EventMgr.Remove)
	-- self:SetLuaEvent("Remove")
end

function M:RestLogs()
	local labs = self.Labs
	if labs then
		local len = #labs
		if len > 0 then
			for i=1,len do
				labs[i].gameObject:SetActive(false)
			end
		end
	end
	local rect = self.Rect
	rect.height = 1;
end

function M:Dispose()
	self:SetEvent(EventMgr.Remove)
	self:SetLuaEvent("Remove")
	self:RestLogs()
end

return M