--region UICopyRect.lua
--Date
--此文件由[HS]创建生成

UICopyRect = Super:New{Name = "UICopyRect"}

require("UI/UICopy/UICopyGetWayItem")
require("UI/UICopy/UICopyCell")
require("UI/UICopy/UICopyQuickBuy")
require("UI/UICopy/CopyExpBuyView")
require("UI/UICopy/CopyBuyView")
require("UI/UICopy/CopyTool")
require("UI/UICopy/UICopySweep")

local M = UICopyRect
local tMgr = TeamMgr
local cMgr = CopyMgr
local vMgr = VIPMgr

function M:Ctor()
	self.Cells = {}
	self.cellList = {}
	self.GetWayItemList = {}
	self.texList = {}
end

function M:Init(go)
	local name = self.Name
	self.GO = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	local F = TransTool.Find

	self.NameL = C(UILabel, trans, "Name", name, false)
	self.BG = C(UITexture, trans, "BG")
	self.CostCell = ObjPool.Get(UIItemCell)
	self.CostCell:InitLoadPool(F(trans, "ItemRoot"))
	self.Cost = C(UILabel, trans, "Cost", name, false)
	self.Num = C(UILabel, trans, "Num", name, false)
	self.BtnItem = T(trans, "Cost/BtnItem")

	self.NumBtn = T(trans, "NumBtn", name, false)
	self.mBtnNumName = C(UILabel, trans, "NumBtn/Name")
	self.mFxBtn = T(trans, "NumBtn/FX_UI_Button")
	self.Btn1 = T(trans, "Button1", name, false)
	self.Btn2 = T(trans, "Button2", name, false)
	self.Btn2Lab = C(UILabel, trans, "Button2/Label", name, false)
	self.Grid = C(UIGrid, trans, "Grid", name, false)

	self.StarRoot = T(trans, "StarRoot")
	self.Des = C(UILabel, self.StarRoot.transform, "Des")
	self.CopySView = C(UIScrollView, self.StarRoot.transform, "ScrollView")
	self.CopyGrid = C(UIGrid, self.CopySView.transform, "Grid")
	self.CopyCell = T(self.CopyGrid.transform, "Cell")
	self.CopyCell:SetActive(false)
	self.sViewPanel = C(UIPanel, self.StarRoot.transform, "ScrollView")

	self.sViewPos = self.CopySView.transform.localPosition
	self.sViewPosY = self.sViewPos.y

	self.mBuyView = ObjPool.Get(CopyBuyView)
	self.mBuyView:Init(T(trans, "BuyView"))

	self.mExpBuyView = ObjPool.Get(CopyExpBuyView)
	self.mExpBuyView:Init(T(trans, "BuyViewExp"))

	self.mCopySweep = ObjPool.Get(UICopySweep)
	self.mCopySweep:Init(T(trans, "SweepView"))

	self.Instruction = C(UILabel, trans, "Instruction")
	self.Instruction.spacingY = 5

	self.XHRoot = T(trans, "XHRoot")
	self.GuardGrid = C(UIGrid, trans, "XHRoot/Grid")
	self.GuardCell = T(trans, "XHRoot/Grid/Cell")

	self.GuardView = T(trans, "GuardView")
	self.GuardIcon = C(UITexture, trans, "GuardView/BG/Icon1")
	self.GuardName = C(UILabel, trans, "GuardView/BG/Name")
	self.GuradDes = C(UILabel, trans, "GuardView/BG/Des")

	self.SkillGrid = C(UIGrid, trans, "XHRoot/SGrid")
	self.SkillCell = T(trans, "XHRoot/SGrid/Cell")
	self.SkillIcon = C(UISprite, trans, "GuardView/BG/Icon2")

	self.GetWay = T(trans, "GetWay")
	self.GetWayGrid = C(UIGrid, self.GetWay.transform, "ScrollView/Grid")
	self.GetWayItem = T(self.GetWayGrid.transform, "Cell")

	self.cd = C(UILabel, trans, "CD")
	self.btnClear = T(self.cd.transform, "BtnClear")

	self.quickBuy = ObjPool.Get(UICopyQuickBuy)
	self.quickBuy:Init(T(trans, "QuickBuy"))


	self.mBtnMerge = T(trans, "BtnMerge")
	self.mBtnMergeName = C(UILabel, self.mBtnMerge.transform, "Name")
	self.mMergeTick = T(self.mBtnMerge.transform, "Tick")

	self.IsNeedCost = false

	self.isInit = false
	self.isInitSkill = false
	self:Clean()
	self:AddEvent()
	self:SetLsnr("Add")
end

function M:SetLsnr(key)
	CopyMgr.eUpdateCopyExpMergeTimes[key](CopyMgr.eUpdateCopyExpMergeTimes, self.UpdateMerge, self)
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.NumBtn then
		E(self.NumBtn, self.OnClickNumBtn, self)
	end
	if self.Btn1 then
		E(self.Btn1, self.OnClickBtn1, self)
	end
	if self.Btn2 then
		E(self.Btn2, self.OnClickBtn2, self)
	end

	E(self.GuardView, self.OnClickGuardView, self)
	E(self.BtnItem, self.OnBtnItem, self)
	E(self.GetWay, self.OnGetWay, self)
	E(self.btnClear, self.OnClear, self)
	E(self.mBtnMerge, self.OnMerge, self, "", false)
end

function M:OnMerge()
	local data = CopyMgr.Copy[CopyMgr.Exp]
	local num = data.MergeTimes
	if num > 1 then
		CopyMgr:ReqCopyExpMergeTimes(1)
		return
	end
	local vipLv = VIPMgr.GetVIPLv()
    local VipInfo =soonTool.GetVipInfo(vipLv)
    local expCopyMerge= VipInfo.ExpCopyMerge
    local nextTimes,vextvp = soonTool.FindNextNum("ExpCopyMerge",vipLv)
    self.vipLv=vipLv
    self.expCopyMerge=expCopyMerge
    self.vextvp=vextvp
    self.nextTimes=nextTimes
    if expCopyMerge<2 then
        if nextTimes==0 then
          return
        end
        UITip.Log(string.format( "达到VIP%s才可以合并挑战",vextvp ))
        return
    end
	UIMgr.Open(MergeTip.Name, self.OpenMergeTipCb, self)
end

function M:OpenMergeTipCb()
	local temp = self.Temp 
	if not temp then return end
	local copyData = cMgr.Copy[tostring(temp.type)]
	local curTimes = temp.num + copyData.Buy + copyData.itemAdd - copyData.Num
	MergeTip:SetInfo(self.vipLv, self.expCopyMerge, curTimes, self.expCopyMerge, self.vextvp, self.nextTimes, self.SendMg, self)
end

function M:SendMg(num)
    CopyMgr:ReqCopyExpMergeTimes(num)
end

function M:OnClear()
	local temp = self.Temp 
	if not temp then return end
	local costSV = temp.costSV
	if not costSV then return end
	local copyData = cMgr.Copy[tostring(temp.type)]
	if not copyData then return end
	local sec = copyData.Timer
	if not sec then return end
	local now = TimeTool.GetServerTimeNow()*0.001;
	local past = now - sec + temp.cd
	local s = costSV[1]
	local v = costSV[2]
	local t = costSV[3]
	local value = t - math.floor(past/s)*v
	MsgBox.ShowYesNo(string.format("是否消耗%s绑元，清除冷却时间？\n（绑元不足消耗元宝）", value), self.YesCb, self)
end

function M:YesCb()
	if not self.Temp then return end
	CopyMgr:ReqCopyCdRemove(self.Temp.id)
end


function M:OnBtnItem()
	self:UpdateGetWay()
	self.GetWay:SetActive(true)
end

function M:OnGetWay()
	self.GetWay:SetActive(false)
end


function M:OnClickGuardView()
	self.GuardView:SetActive(false)
end

--更新副本信息
function M:UpdateData(info, temp)
	self:Clean()
	self.Info = info
	self.Temp = temp
	self:UpdateView()
end

function M:UpdateView()
	self:UpdateName()
	self:UpdateCost()
	self:UpdateNum()
	self:UpdateBtn()
	self:UpdateBG()
	self:UpdateRoot()
	self:UpdateReward()
	self:UpdateGuard()
	self:UpdateSkill()
	self:UpdateInst()
	self:UpdateDes()
	self:UpdateCD()
	self:UpdateBuyView()
	self:UpdateSweepView()
	self:UpdateBtnNum()
	self:UpdateCopyExpGuideTimes()
	self:UpdateMerge()
end

function M:UpdateMerge()
	local temp = self.Temp 
	if not temp then return end
	if temp.type ~= CopyType.Exp then 
		self.mBtnMerge:SetActive(false)
		return 
	end
	local data = CopyMgr.Copy[CopyMgr.Exp]
	local value = GlobalTemp["133"].Value3
	local finishTimes = data.FinishTimes or 0
	self.mBtnMerge:SetActive(finishTimes >= value)
	local num = data.MergeTimes
	local state = num ~= 1
	self.mBtnMergeName.text = state and string.format("合并%s次", num) or "合并次数"
	self.mMergeTick:SetActive(state)
end

function M:BuyResp(typeId)
	if self.mCopySweep and self.mCopySweep:IsActive() then
		self.mCopySweep:BuyResp(typeId)
	end
end

function M:UpdateCD()
	local temp = self.Temp 
	if not temp then return end
	self.cd.gameObject:SetActive(temp.type == CopyType.Exp)
	local copyData = cMgr.Copy[tostring(temp.type)]
	if not copyData then return end
	local sec = copyData.Timer
	sec = sec or 0
	local now = TimeTool.GetServerTimeNow()*0.001
	local second = sec - now
	if second <= 0 then 
		if self.timer then
			self.timer:Stop()
		end
		self:CompleteCb()
		return 
	end
	if not self.timer then
		self.timer = ObjPool.Get(DateTimer)
		self.timer.invlCb:Add(self.InvlCb, self)
		self.timer.complete:Add(self.CompleteCb, self)
		self.timer.fmtOp = 3
		self.timer.apdOp = 1
	end
	self.timer.seconds = second
	self.timer:Start()
	self:InvlCb()
end

function M:InvlCb()
	if self.timer then
		self.cd.text = string.format("[F4DDBDFF]冷却时间：[00FF00]%s", self.timer.remain)
	end
end


function M:CompleteCb()
	self.cd.gameObject:SetActive(false)
end


function M:UpdateGetWay()
	local temp = self.Temp 
	if not temp then return end
	if temp.type ~= CopyType.Exp then return end
	local data = ExpGeyWayCfg
	local list = self.GetWayItemList
	local count = #list
	local len = #data
	local max = count >= len and count or len
	local min = count + len - max

	for i=1, max do
		if i <= min then
			list[i]:SetActive(true)
			list[i]:UpdateData(data[i])
		elseif i <= count then
			list[i]:SetActive(false)
		else
			local go = Instantiate(self.GetWayItem)
			TransTool.AddChild(self.GetWayItem.transform.parent, go.transform)
			go:SetActive(true)
			local item = ObjPool.Get(UICopyGetWayItem)
			item:Init(go, self.quickBuy, self.GetWay)
			item:UpdateData(data[i])	
			table.insert(list, item)
		end
	end
	self.GetWayGrid:Reposition()
end

function M:UpdateInst()
	local temp = self.Temp
	if temp.type == CopyType.Exp or temp.type == CopyType.XH then
		self.Instruction.gameObject:SetActive(true)
		local str = string.format("[f39800]进入等级：[-][00FF00FF]%d级或以上[-]",temp.lv)
		self.Instruction.text = string.format("%s\n%s", str, temp.des)
	else
		self.Instruction.gameObject:SetActive(false)
	end
end

function M:UpdateDes()
	self.Des.text = self.Temp.des or "提升副本评分，获得翻倍奖励!"
end

function M:UpdateSkill()
	local temp = self.Temp
	if not temp then return end
	if temp.type == CopyType.XH then
		if self.isInitSkill then return end
		local list = TableTool.DicToList(XHSkillCfg, function(a,b) return a.id < b.id end)
		local prefab = self.SkillCell
		for i=1,#list do
			local go = Instantiate(prefab)
			local trans = go.transform
			trans:SetParent(self.SkillGrid.transform)
			go:SetActive(true)
			trans.localScale = Vector3.one
			trans.localPosition = Vector3.zero
			go.name = list[i].id
			local sp = go:GetComponent(typeof(UISprite))
			sp.spriteName = list[i].sprite
			UITool.SetLsnrSelf(go, self.OnClickSkill, self, nil, false)
		end
		self.isInitSkill = true
		self.SkillGrid:Reposition()
	end
end

function M:OnClickSkill(go)
	local key = go.name
	local m = XHSkillCfg[key]
	self.GuardName.text = m.name
	self:SwitchIconState(false)
	self.SkillIcon.spriteName = m.sprite
	self.GuradDes.text = m.des
	self.GuardView:SetActive(true)
end

function M:UpdateGuard()
	local temp = self.Temp
	if not temp then return end
	if temp.type == CopyType.XH then
		if self.isInit then return end
		local t = GlobalTemp["48"].Value1
		local prefab = self.GuardCell
		for i=1,#t do
			local mId = tostring(t[i].id)
			local m = MonsterTemp[mId]
			local go = Instantiate(prefab)
			local trans = go.transform
			trans:SetParent(self.GuardGrid.transform)
			go:SetActive(true)
			trans.localScale = Vector3.one
			trans.localPosition = Vector3.zero
			go.name = mId
			local tex = go:GetComponent(typeof(UITexture))
			self:SetTexture(tex, m.icon)
			UITool.SetLsnrSelf(go, self.OnClickGuard, self, nil, false)
		end
		self.isInit = true
		self.GuardGrid:Reposition()
	end
end

function M:OnClickGuard(go)
	local mId = go.name
	local m = MonsterTemp[mId]
	self.GuardName.text = m.name
	self:SwitchIconState(true)
	self:SetTexture(self.GuardIcon, m.icon)
	self.GuradDes.text = m.des
	self.GuardView:SetActive(true)
end

function M:SwitchIconState(state)
	self.GuardIcon.gameObject:SetActive(state)
	self.SkillIcon.gameObject:SetActive(not state)
end


function M:SetTexture(tex, texName)
	AssetMgr:Load(texName, ObjHandler(function(go) 
		if not LuaTool.IsNull(self.GO) then
			table.insert(self.texList, go.name)
			tex.mainTexture = go
		else
			AssetTool.UnloadTex(go.name)
		end
	end))
end

function M:UpdateName()
	if self.Temp and self.NameL then
		self.NameL.text = CopyMgr:GSub(self.Temp.name)
	end
end

function M:BagUpdate()
	self:UpdateCost()
	self:UpdateSweepView()
end


--消耗道具
function M:UpdateCost()
	self.IsNeedCost = false
	local item = nil
	local name = ""
	local count = 0
	local limit = 0
	local temp = self.Temp
	if not temp then return end
	local ic = temp.inputCost
	if temp and ic then
		item = ItemData[tostring(ic.id)]
		if item then
			name = item.name
			count = PropMgr.TypeIdByNum(item.id)
		end
		limit = ic.value
	end
	local isShow = ic ~= nil
	if self.CostCell then
		if item then
			self.CostCell:UpData(item)
		end
		self.CostCell:SetActive(isShow)
	end
	if self.Cost then
		local value = string.format("%s/%s", count, limit)
		if count < limit then
			self.IsNeedCost = true
			value = string.format("[99886BFF]消耗数量：[F21919FF]%s[-]", value)
		else
			value = string.format("[99886BFF]消耗数量：[00FF00FF]%s[-]", value)
		end

		self.Cost.text = value
		self.Cost.gameObject:SetActive(isShow)
	end
	self:UpdateBtnNum()
end

function M:UpdateCopyExpGuideTimes()
	local temp = self.Temp
	if not temp then return end
	if temp.type == CopyType.Exp then
		local info = CopyMgr.Copy[CopyMgr.Exp]
		local value = GlobalTemp["133"].Value3
		local finishTimes = info.FinishTimes or 0
		self.NumBtn:SetActive(finishTimes >= value)
		if finishTimes < value then
			self.Num.text = string.format("[99886BFF]剩余次数：[00FF00FF]%s/%s[-]", info.EnterTimes or 0, value)
		end
	else
		self.NumBtn:SetActive(true)
	end
end

function M:UpdateBtnNum()
	local temp = self.Temp
	if not temp then return end
	local num = PropMgr.TypeIdByNum(31025)
	if temp.type == CopyType.Exp and num > 0 then
		self.mFxBtn:SetActive(true)
		self.mBtnNumName.text = "增加次数"
	else
		self.mFxBtn:SetActive(false)
		self.mBtnNumName.text = "购买次数"
	end

	if temp.type == CopyType.Exp then
		self.mExpBuyView:UpdateData()
	end
end

--副本剩余次数
function M:UpdateNum()
	local value = ""

	local temp = self.Temp
	if not temp then return end
	local copyData = cMgr.Copy[tostring(temp.type)]
	local max = temp.num
	if copyData then
		local cNum = copyData.Num
		max = max + copyData.Buy + copyData.itemAdd
		local rato = string.format("%s/%s", max-cNum, max)
		if cNum < max then
			value = string.format("[99886BFF]剩余次数：[00FF00FF]%s[-]", rato)
		else
			value = string.format("[99886BFF]剩余次数：[F21919FF]%s[-]", rato)
		end
	end
	if self.Num then
		self.Num.text = value
	end
end

--更新奖励
function M:UpdateReward()
	local temp = self.Temp
	if not temp then return end
	local data = temp.sItems
	if not data then return end

	local len = #data
    local list = self.Cells
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
    for i=1, max do
		if i <= min then
			list[i]:UpData(data[i].k, data[i].v)
			list[i]:SetActive(true)
        elseif i <= count then
			list[i]:SetActive(false)
		else
			local item = ObjPool.Get(UIItemCell)
			item:InitLoadPool(self.Grid.transform)
			item:UpData(data[i].k, data[i].v)
			table.insert(self.Cells, item)
        end
    end
	self.Grid:Reposition()
end

function M:UpdateRoot()
	local temp = self.Temp
	if not temp then return end
	if self.GO then
		if not self.GO.activeSelf then
			self:SetActive(true)
		end
	end

	local t = temp.type
	self.StarRoot:SetActive(t==CopyType.Glod or t==CopyType.SingleTD or t==CopyType.ZLT)
	self.XHRoot:SetActive(t==CopyType.XH)
	if t==CopyType.Glod or t==CopyType.SingleTD or t==CopyType.ZLT then
		if self.mCopySweep:IsActive() then return end  
		self.selectCopyCell = nil
		self:UpdateCopyCell()
		self:SelectCopyCell()
		self:SetCopyCellPos()
	end
end

function M:UpdateCopyCell()
	local info = cMgr.Copy[tostring(self.Temp.type)]
	local data = info.IndexOf
    local len = #data
    local list = self.cellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
  
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.CopyCell)
            TransTool.AddChild(self.CopyGrid.transform, go.transform)
            local item = ObjPool.Get(UICopyCell)
            item:Init(go)
            item.eClick:Add(self.OnCopyCell, self)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
	end
	self.CopySView:ResetPosition()
    self.CopyGrid:Reposition()
end

function M:SelectCopyCell()
	local copy = cMgr:GetCurCopy(self.Temp.type)
	if copy then
		self:OnCopyCell(copy.Temp)
	end
end

function M:OnCopyCell(temp)
	self.Temp = temp
	local list = self.cellList
	local index = nil
	for i=1,#list do
		if list[i]:IsActive() then
			if list[i].temp.id == temp.id then
				index = i
				list[i]:SetScale(Vector3(1.2, 1.2, 1.2))
				list[i]:UpdateFx(true)
			else
				list[i]:SetScale(Vector3.one)
				list[i]:UpdateFx(false)
			end
		end
	end
	if not index then return end
	if self.selectCopyCell and self.selectCopyCell == index then return end
	self.selectCopyCell = index
	self:UpdateReward()
end

function M:SetCopyCellPos()
	local index = self.selectCopyCell
	if not index then return end
	local list = self.cellList
	local eIndex = index + 1
	if index >= 3 and list[eIndex] and list[eIndex]:IsActive() then
		local y = -50+(index-3)*160
		self.CopySView.transform.localPosition = Vector3(self.sViewPos.x, y, self.sViewPos,z)
		self.sViewPanel.clipOffset = Vector2(0, self.sViewPosY+4-y)
	end
end


--更新按钮
function M:UpdateBtn()
	local temp = self.Temp
	if not temp then return end
	if self.Btn1 then
		local value = temp and temp.sweep == 1
		-- value = false  --暂时屏蔽扫荡按钮
		self.Btn1:SetActive(value)
	end
	if self.Btn2Lab then
		local value = temp.isTeam == 1
		local text = "开始挑战"
		if value == true then
			text = "组队进入"
		end
		self.Btn2Lab.text = text
	end
end

--更新背景图
function M:UpdateBG()
	local temp = self.Temp
	if temp then
		if self.BG then
			local pic = temp.pic
			if StrTool.IsNullOrEmpty(pic) then return end
			AssetMgr:Load(pic, ObjHandler(self.SetPicTex, self))
		end
	end
end

function M:SetPicTex(tex)	
	if not LuaTool.IsNull(self.GO) then
		self.BG.mainTexture = tex
		table.insert(self.texList, tex.name)
	else
		AssetTool.UnloadTex(tex.name)
	end
end

function M:ShowSweepView(value)
	self.mCopySweep:SetActive(value)
	if value then
		self.mCopySweep:UpdateData(self.Temp)
	end
end

function M:UpdateSweepView()
	if self.mCopySweep:IsActive() then
		self.mCopySweep:UpdateData(self.Temp)
	end
end

function M:UpdateBuyView()
	if not self.Temp then return end
	if self.Temp.type ~= CopyType.Exp then
		self.mBuyView:UpdateData()
	else
		self.mExpBuyView:UpdateData()
	end
end

function M:OnClickNumBtn(go)
	if not self.Temp then return end
	if self.Temp.type ~= CopyType.Exp then
		self.mBuyView:Open(self.Temp)
	else
		self.mExpBuyView:Open(self.Temp)
	end
end


--点击按钮1
function M:OnClickBtn1(go)
	if not self:IsSelectCopy() then return end
	local temp = self.Temp
	if not temp then return end
	local isSweep = temp.sweep
	if isSweep == 0 then
		UITip.Log("该副本不能扫荡！")
		return
	end
	local Copy = cMgr.Copy[tostring(temp.type)]
	local curStar = 0
	if Copy then
		local dic = Copy.Dic
		if dic then
			local info = dic[tostring(temp.id)]
			if info then
				if not info.Star  then
					curStar = 0
					UITip.Log("请先通关副本")
					return
				else
					curStar = info.Star
				end
			end
		end
	end
	local starTab = {"丙","乙","甲"}
	local sweepCond = temp.sweepCond
	if sweepCond then
		local lv, vipLv,star = nil, nil,nil
		for i=1,#sweepCond do
			local cond = sweepCond[i]
			if cond.k == 1 and User.MapData.Level < cond.v then
				lv = cond.v
			elseif cond.k == 2 and VIPMgr.vipLv < cond.v then
				vipLv = cond.v
			elseif cond.k == 3 and curStar < cond.v then
				star = cond.v
			end
		end
		if lv and vipLv and star then
			UITip.Log(string.format("角色达到%s级，达到VIP%s，%s级通关副本开启扫荡", lv, vipLv,starTab[star]))
			return
		elseif lv and star then
			UITip.Log(string.format("角色达到%s级，%s级通关副本开启扫荡", lv ,starTab[star]))
			return
		elseif lv and vipLv then
			UITip.Log(string.format("角色达到%s级，且达到VIP%s开启扫荡", lv, vipLv))
			return
		elseif lv then
			UITip.Log(string.format("角色达到%s级开启扫荡", lv))
			return
		elseif vipLv then
			UITip.Log(string.format("VIP%s开启扫荡", vipLv))
			return
		elseif star then
			UITip.Log(string.format("%s级通关副本开启扫荡", starTab[star]))
			return
		end
	end

	if Copy then
		local max = temp.num	
		local cNum = Copy.Num
		max = max + Copy.Buy + Copy.itemAdd
		if cNum >= max then
			UITip.Log("副本次数已用完")
			return
		end
	end
	self:ShowSweepView(true)
end

function M:UpdateCleanCopy()
	local temp = self.Temp
	if not temp then return end
	local Copy = cMgr.Copy[tostring(temp.type)]
	if not Copy then return end
	local max = temp.num	
	local cNum = Copy.Num
	max = max + Copy.Buy + Copy.itemAdd
	if cNum >= max then
		self:ShowSweepView(false)
	end
end

--点击按钮2
function M:OnClickBtn2(go)
	if not self:IsSelectCopy() then return end
	local temp = self.Temp
	if not temp then return end
	if User.MapData.Level < temp.lv then
		UITip.Log("等级不足，副本未开启")
		return
	end
	local copy, isOpen = cMgr:GetCurCopy(temp.type)
	if not isOpen or temp.id > copy.Temp.id then
		UITip.Log("需先甲级通关上一个副本")
		return
	end
	local k = tostring(temp.type)
	local d = cMgr.Copy[k]
	local num = d.Num
	local max = (d.Buy + temp.num + d.itemAdd)
	if d.Num >= max then
		if temp.buy == d.Buy then
			UITip.Log("挑战次数已用完，不能进入")
			return
		end
		local offset = max > num
		if offset == false then
			MsgBox.ShowYes("剩余挑战次数不足,VIP可购买挑战次数")
		end
		return
	end
	if self.IsNeedCost == true then
		if temp.id == 20001 then
			local isExitGift = DiscountGiftMgr:IsExitGift(364)
			if isExitGift then
				self:ShowBuyBox()
			else
				SceneMgr:ReqPreEnter(temp.id, true, true)
			end
		else
			UITip.Log("进入副本所需道具不足")
		end
		return
	end

	local sec = d.Timer	

	if sec and sec > 0 then
		local now = TimeTool.GetServerTimeNow()*0.001;
		local second = now - sec
		if second < 0 then
			UITip.Log("正处在冷却时间，无法挑战")
			return
		end
	end
	
	if temp.isTeam == 1 then
		local info = tMgr.TeamInfo
		if not info.TeamId then
			MsgBox.ShowYes("需要队伍才能进入")
			return
		end
		local len = LuaTool.Length(info.Player)
		if len > 0 then
			tMgr:ReqStartCopyTeam(temp.id, true)
		end
	else
		SceneMgr:ReqPreEnter(temp.id, true, true)
	end
	UIMgr.Close(UICopy.Name)
end

function M:ShowBuyBox()
	local temp = self.Temp
	if not temp then return end
	local ic = temp.inputCost
	if temp and ic then
		item = ItemData[tostring(ic.id)]
		local limit = ic.value
		if item then
			name = item.name
			local tp = 5
			local pId = item.id
			-- local curOwn = PropMgr.TypeIdByNum(pId)
			local data = CopyMgr.Copy[CopyMgr.Exp]
			local merTimes = data.MergeTimes
			local buyNum = 1
			buyNum = merTimes ~= 1 and merTimes or buyNum
			local price = StoreMgr.GetTotalPriceByShopType(tp,pId,buyNum)
			local msg = string.format("青竹密令不足，是否花费%s绑元购买",price)
			MsgBox.ShowYesNo(msg,
			function() 
				StoreMgr.TypeIdTpBuy(tp,pId,buyNum,false)
			end,
			self)
		end
	end
end

function M:IsSelectCopy()
	if not self.Temp then
		UITip.Log("没有副本信息！！")
		return false
	end
	return true
end

function M:SetActive(value)
	if self.GO then
		self.GO:SetActive(value)
	end
end

function M:Clean()
	if self.NameL then self.NameL.text = "" end
	if self.Lv then self.Lv.text = "" end
	if self.Cost then self.Cost.text = "" end
	if self.Num then self.Num.text = "" end
end

function M:Dispose()
	self:SetLsnr("Remove")
	if self.timer then
		self.timer:AutoToPool()
		self.timer = nil
	end
	self.CostCell:DestroyGo()
	ObjPool.Add(self.CostCell)	
	TableTool.ClearDicToPool(self.GetWayItemList)
	TableTool.ClearDicToPool(self.cellList)
	TableTool.ClearListToPool(self.Cells)
	AssetTool.UnloadTex(self.texList)
	self.CostCell = nil
	self.selectCopyCell = nil
	TableTool.ClearUserData(self)
	ObjPool.Add(self.quickBuy)
	self.quickBuy = nil
	ObjPool.Add(self.mExpBuyView)
	self.mExpBuyView = nil
	ObjPool.Add(self.mBuyView)
	self.mBuyView = nil
	ObjPool.Add(self.mCopySweep)
	self.mCopySweep = nil
end
