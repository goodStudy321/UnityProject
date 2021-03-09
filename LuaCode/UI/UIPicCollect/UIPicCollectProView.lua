--region UIPicCollectProView.lua
--Date
--此文件由[HS]创建生成


UIPicCollectProView = Super:New{Name="UIPicCollectProView"}
local M = UIPicCollectProView

local PCMgr = PicCollectMgr

local Status = {}
Status.NotActive = 0 
Status.UpLv = 1
Status.UpStep = 2

function M:Init(go, parent)
	local name = "图鉴ProsView"
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Parent = parent

	self.AFight = C(UILabel, trans, "AllFight", name, false)
	self.Name = C(UILabel, trans, "Name", name, false)
	self.CFight = C(UILabel, trans, "Fight", name, false)
	self.CLv = C(UILabel, trans, "CurLv", name, false)
	self.NLV = C(UILabel, trans, "NextLv", name, false)

	self.Stars = ObjPool.Get(UIPicCollectStars)
	self.Stars:Init(T(trans, "Stars"))
	self.Pros = ObjPool.Get(UIPicCollectPros)
	self.Pros:Init(T(trans, "Pros"))

	self.Grid = C(UIGrid, trans, "ItemRoot", name, false)

	self.SBtn = T(trans, "SplitBtn")
	self.UBtn = C(UIButton, trans, "UpBtn", name, false)
	self.UpBtnLab = C(UILabel, trans, "UpBtn/Label", name, false)
	self.SAction = T(trans, "SplitBtn/Action")
	self.UAction = T(trans, "UpBtn/Action")

	self.Reward = {}

	self.CurStatus = 0

	local E = UITool.SetLsnrSelf
	if parent then
		E(self.SBtn, parent.ShowDevourView, parent)
	end
	E(self.UBtn, self.OnClickUBtn, self)
end

function M:ShowData(data)
	self:Clear()
	local key = tostring(data.Temp.id)
	local temp = PicCollectTemp[key]
	if not temp then return end
	self.Temp = temp
	self:UpdateName(temp.name)
	self:UpdateStar(temp.star)
	self:UpdateAllFight()
	self:UpdateFight(temp)
	local nTemp = self:UpdateLv(temp)
	self:UpdatePros(temp, nTemp)
	self:UpdateReward(temp)
	self:UpdteUBtnStatus(temp, nTemp)
	self:UpdateUAction()
	self:UpdateRAction()
end

function M:UpdateName(name)
	local nLab = self.Name
	if nLab then nLab.text = name end
end

function M:UpdateStar(s)
	local star = self.Stars
	if star then
		star:ShowStar(s)
	end
end

function M:UpdateAllFight()
	local aFight = self.AFight
		if aFight then
		local value = User.MapData:GetFightValue(35)
		if StrTool.IsNullOrEmpty(value) then value = "0" end
		aFight.text = value
	end
end

function M:UpdateFight(temp)
	local list = {}
	if temp.pro1 then
		table.insert(list, temp.pro1)
	end
	if temp.pro2 then
		table.insert(list, temp.pro2)
	end
	if temp.pro3 then
		table.insert(list, temp.pro3)
	end
	if temp.pro4 then
		table.insert(list, temp.pro4)
	end
	local fight = self.CFight
	if fight then
		fight.text = PropTool.GetFightByList(list)
	end
end

function M:UpdateLv(temp)
	local cStar = temp.star
	local cLv = temp.lv
	local cLvLab = self.CLv
	if cLvLab then
		cLvLab.text = string.format("%s星%s级",cStar,cLv)
	end
	local nLv = "已满星"
	local nTemp = nil
	if temp.upLvCost or temp.cost then
		local nid = temp.id + 1
		nTemp = PicCollectTemp[tostring(nid)]
		if nTemp then
			nLv = string.format("%s星%s级",nTemp.star , nTemp.lv)
		end
	end
	local nLvLab = self.NLV
	if nLvLab then
		self.NLV.text = nLv
	end
	return nTemp
end

function M:UpdatePros(temp, nTemp)
	if self.Pros then
		self.Pros:UpdatyeTemp(temp, nTemp)
	end
end

function M:UpdateReward(temp)
	self:AddUpLvCost(temp.upLvCost)
	self:AddCost(temp.cost)
	self.Grid:Reposition()
end

function M:AddUpLvCost(data)
	if not data then return end
	if not item then return end
	if not self.Grid then return end
	local item = ItemData[tostring(data.k)]
	if not item then return end
	local cell = ObjPool.Get(UIItemCell)
	cell:InitLoadPool(self.Grid.transform)
	table.insert(self.Reward, cell)
	cell:UpData(item)
	local txt = ""
	local value, cur = PCMgr:IsCostMaterial(data.k, data.v)
	if value == true then
		txt = string.format("[size=22][04E002FF]%s/%s[-][/size]",cur, data.v)
	else
		txt = string.format("[size=22][D12B2BFF]%s/%s[-][/size]",cur, data.v)
	end
	cell:UpLab(txt, true)
	if cell.trans then
		cell.trans.gameObject:SetActive(data.v ~= 0)
	end
end

function M:AddCost(cost)
	if not cost then return end
	if not self.Grid then return end
	local item = ItemData["17"]
	if not item then return end
	local cell = ObjPool.Get(UIItemCell)
	cell:InitLoadPool(self.Grid.transform)
	table.insert(self.Reward, cell)
	cell:UpData(item)
	local txt = ""
	local value, cur = PCMgr:IsCostMaterial(0, cost)
	if value == true then
		txt = string.format("[04E002FF]%s/%s[-]",cur,cost)
	else
		txt = string.format("[D12B2BFF]%s/%s[-]",cur,cost)
	end
	cell:UpLab(txt, true)
end

function M:UpdteUBtnStatus(temp, nTemp)
	local active = false
	local dic = PCMgr.TypeDic
	local type = dic[temp.type]
	if type then
		local group = type[temp.group]
		if group then
			local pic = group[temp.picId]
			if pic then
				active = pic.Active
			end
		end
	end
	local name = "激活"
	self.CurStatus = Status.NotActive
	if active == true then
		name = "升级"
		if nTemp and temp and nTemp.star > temp.star then
			name = "进阶"
			self.CurStatus = Status.UpStep
		else
			self.CurStatus = Status.UpLv
		end
	end
	if self.UpBtnLab then self.UpBtnLab.text = name end
	if self.Stars then self.Stars:SetActive(true) end
end

function M:UpdateEssence()
	local temp = self.Temp
	if not temp then return end
	self:ClearReward()
	self:UpdateReward(temp)
end

function M:OnClickUBtn()
	local temp = self.Temp
	if not temp then 
		UITip.Error("请选择卡片")
		return 
	end
	local isCost1 = nil 
	if temp.cost then
		isCost1 = PCMgr:IsCostMaterial(0, temp.cost)
	end
	local isCost2 = nil
	if temp.upLvCost then
		isCost2 = PCMgr:IsCostMaterial(temp.upLvCost.k, temp.upLvCost.v)
	end
	local status = self.CurStatus
	if isCost1 == false or isCost2 == false then
		if status == Status.NotActive then
			UITip.Error("材料不足，不能解锁激活")
		elseif status == Status.UpLv then
			UITip.Error("材料不足，不能进行升级")
		elseif status == Status.UpStep then
			UITip.Error("材料不足，不能进行进阶")
		end
		return
	end
	if status == Status.NotActive then
		PCMgr:ReqActivePic(temp.id)
	elseif status == Status.UpLv then
		PCMgr:ReqUpPic(temp.id)
	elseif status == Status.UpStep then
		PCMgr:ReqUpPic(temp.id)
	end
end

function M:ClickSCloseBtn()
	self:ShowStepView(false)
end

function M:ShowStepView(value)
	if self.SView then
		self.SView:SetActive(value)
	end
end

function M:UpdateUAction()
	local temp = self.Temp
	if not temp then return end
	local action = self.UAction
	if action then
		action:SetActive(PCMgr:GetPicToRed(temp.picId))
	end
end

function M:UpdateRAction()
	local action = self.SAction
	if action then
		action:SetActive(PCMgr:GetResolveToRed())
	end
end

function M:Clear()
	self.Temp = nil
	local pros = self.Pros
	if pros then
		pros:Clear()
	end
	local star = self.Stars
	if star then
		star:Clear()
	end
	self:ClearReward()
end

function M:ClearReward()
	local list = self.Reward
	if list then
		local len = #list
		while len > 0 do
			local cell = list[len]
			if cell then
				cell:DestroyGo()
				ObjPool.Add(cell)
			end
			table.remove(self.Reward, len)
			len = #list
		end
	end
end

function M:Dispose()

	if self.Cell1 then
		self.Cell1:DestroyGo()
		ObjPool.Add(self.Cell1)
	end
	if self.Cell2 then
		self.Cell2:DestroyGo()
		ObjPool.Add(self.Cell2)
	end

	if self.Pros then
		self.Pros:Dispose()
		ObjPool.Add(self.Pros)
	end
	if self.Stars then
		self.Stars:Dispose()
		ObjPool.Add(self.Stars)
	end

	self.NLV = nil
	self.CLv = nil
	self.CFight = nil
	self.Name = nil
	self.AFight = nil
end
--endregion
