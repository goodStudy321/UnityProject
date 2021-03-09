--region UISkyMysterySealWarehouse.lua
--Date
--此文件由[HS]创建生成



UISkyMysterySealWarehouse = UISVRepeatBase:New{Name = "UISkyMysterySealWarehouse"}

local M = UISkyMysterySealWarehouse

local bNs = {"全","天机","乾","坎","艮","震","巽","离","坤","兑"}

function M:CustomInit(go)
	local name = "天机印仓库"	
	local C = ComTool.Get
	local T = TransTool.FindChild
	local trans = self.trans
	self.SizeItemH = 90
	self.QMenu = ObjPool.Get(UIPopDownMenu)
	self.QMenu.MAX_SHOW_BTN_NUM = #bNs
	self.QMenu:Init(T(trans, "SelectMenu"),bNs[1], bNs, 46, function(fIndex) self:Change(fIndex) end,true)
	self.Eff = T(trans,"SelectMenu/Eff/Fx_kuang_01")
	self.GoToBtn = T(trans,"GoToGetBtn")
	self.DecomposeBtn = T(trans, "DecomposeBtn")	
	self:InitEvent()
end

function M:InitEvent()
	self.QMenu:SynBtnIndexShow(0)
	local E = UITool.SetLsnrSelf
	if self.GoToBtn then
		E(self.GoToBtn, self.OnClickBtn, self)
	end
	if self.DecomposeBtn then
		E(self.DecomposeBtn, self.OnClickBtn, self)
	end
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	self:SetEvent("Add")
end

function M:SetEvent(fn)
end

function M:RemoveEvent()
	self:SetEvent("Remove")
end

function M:UpdateData(index)
	if not index then index = -1 end
	ListTool.Clear(self.Infos)
	local list = self.Infos
	SMSMgr:GetItemsForIndex(list, index)
	if #list > 1 then
		table.sort(list,function(a, b) return SMSMgr:DSort(a,b) end)
	end
	self:CleanCells()
	if list == nil or #list==0 then return end
	if not list then 
		return 
	end 
	self:UpdateMaxVertical(#list)
	self:UpdateCells()
end

function M:SetMenu(index)
	if self.QMenu.curClickIndex - 1 ~= index then
		self.Eff:SetActive(true)
	end
	self.QMenu:SynBtnIndexShow(index + 1)
	self:UpdateData(index)
end

function M:Change()
	self.Eff:SetActive(true)
	self:UpdateSelect()
end

function M:UpdateSelect()
	local qMenu = self.QMenu.curClickIndex - 1
	local limit = self.LimitNum
	if self.Infos == nil or limit == nil or limit == 0 then return end
	self:UpdateData(qMenu)
	SMSControl:SetShowViewSelect(qMenu)
end

function M:CustomCellInfo(temp, cell)
    local sms = SMSProTemp[tostring(temp.id)]
    if sms and sms.index ~= 999 then
        local status = SMSMgr:GetScoreCompare(temp.id)
		cell:UpdateIconArr(status == 1)
    end
end

function M:UpdateCellArr(index)
	local places = self.Places
	if places then
		for k,v in pairs(places) do
			local i = tonumber(k)
			if i ~= nil then
				local pro = self.Infos[i]
				if pro then
					local temp = SMSProTemp[tostring(pro.type_id)]
					if temp then
						if temp.index == index then
							local status = SMSMgr:GetScoreCompare(temp.id)
							v:UpdateIconArr(status == 1)
						else
							v:IconUp(false)
							v:IconDown(false)
						end
					else
						v:IconUp(false)
						v:IconDown(false)
					end
				end
			end
		end
	end
	local infos = self.Infos
end

--[[#################################################################################################################]]--

function M:OnClickItem(go, value, change)
	if not self.Infos then return end
	local str = go.name
	if str == nil then
		return
	end
	local index = tonumber(str)
	if index == nil then
		return
	end
	index = index
	local item = self.Infos[index]
	if not item then
		SMSControl:HideTipView()
		return
	end
	local pro = SMSProTemp[tostring(item.type_id)]
	if pro then
		if pro.index == 999 then
			SMSControl:ShowItemTip(item)
			return
		end
	end
	SMSControl:ShowTipView(item, true)
end

function M:OnClickBtn(go)
	local name = go.name
	if name == self.GoToBtn.name then
		SMSControl:OpenCopyUI()
	elseif name == self.DecomposeBtn.name then
		SMSControl:ShowDecomposeView()
	end
end

--[[#################################################################################################################]]--

--[[#################################################################################################################]]--

--[[#################################################################################################################]]--

function M:Open()
end

function M:Close()
end

function M:CustomDispose(isDestory)
	if self.QMenu then
		ObjPool.Add(self.QMenu);
		self.QMenu = nil;
	end
end
--endregion
