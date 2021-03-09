--region UIPet.lua
--Date
--此文件由[HS]创建生成
require("UI/UICell/UICellSkillUnlock")
require("UI/UIPet/UIPetActive")
require("UI/UIPet/UIPetProperty")
require("UI/UIPet/UIPetSkill")
-- require("UI/UIPet/UIPetDevourView")
require("UI/UIPet/UIPetJingpoView")

UIPet = Super:New{Name ="UIPet"}

local M = UIPet
local pMgr = PetMgr
local sMgr = SystemMgr
--M.EffectName = "UI_CW_TuZi_UI_DengLv"
local Sound = 118
local pStorId = 50002 --伙伴进阶丹绑元商城id

function M:Init(root)
	local name = "UIPet"
	local trans = root
	self.go = root.gameObject
	local C = ComTool.Get
	local T = TransTool.FindChild
	
	self.ModRoot = self.rCntr.modRoot
	self.skill = self.rCntr.skill
	self.StepView = self.rCntr.Step
	self.prop = self.cntr.prop
	--伙伴吞噬移到背包
	-- self.ExeView = UIPetDevourView.New(T(trans, "DevourView"))
	-- self.ExeView.CloseCB = function () self:CloseExeView() end
	-- self.ExeView:Init()

	self.NameLabel = C(UILabel, trans, "nameBg/name", name, false)
	self.Fight = C(UILabel, trans, "ft", name, false)
	self.LeftBtn = C(UIButton, trans, "base/lefBtn", name, false)
	self.RightBtn = C(UIButton, trans, "base/rigBtn", name, false)
	self.Step = C(UILabel, trans, "stepBg/step", name, false)
	self.ExpSlider = C(UISprite, trans, "ExpSlider", name, false)
	self.Exp = C(UILabel, trans, "ExpSlider/Label", name, false)
	self.ExpEff = T(trans, "FX_UI_DevourView")
	self.Lv = C(UILabel, trans, "Lv", name, false)
	--伙伴等级信息不显示
	self.Lv.gameObject:SetActive(false)
	self.StepRoot = T(trans,"step")
	self.UpLvBtn = C(UIButton, trans, "step/aKeyBtn", name, false)
	self.UpLvBtnRed = T(trans,"step/aKeyBtn/red")
	self.UpStepBtn = C(UIButton, trans, "step/advBtn", name, false)
	self.upBtnRed = T(trans,"step/advBtn/red")
	local advLab = C(UILabel, trans, "step/advBtn/lbl", name)
  	advLab.text = "一键升级"
	self.EquipBtn = C(UIButton, trans, "skinBtn", name, false)
	self.EquipLab = C(UILabel, trans, "skinBtn/lbl", name, false)
	self.changeBox = C(BoxCollider, trans, "skinBtn", name,false)
	self.alFlag = C(UISprite,trans,"alFlag",name,false)
	self.SkinsBtn = C(UIButton, trans, "skinsBtn", name, false)
	self.skinRed = T(trans,"skinsBtn/red")
	-- self.SkinsBtn.gameObject:SetActive(false)
	self.ItemTabGbj = {}
	self.ItemTabObj = {}

	self.icon1 = T(trans, "step/propIcons/icon1",self.Name)
	self.icon2 = T(trans, "step/propIcons/icon2",self.Name)
	self.ItemTabGbj = {self.icon1,self.icon2}

	self.UpStepExeEff = T(trans, "step/FX_Immortals_Succeed")
	self.UpStepEff = T(trans, "step/FX_Immortals_Levelup")
	--self:ShowView()

	self.tog = C(UIToggle, trans,"step/coin/tog", name)
	self.togLab = C(UILabel, trans,"step/coin/tog/des", name)
	self.togLab.text = "不足时自动消耗绑元(绑元不足消耗元宝)"
	self.togLabSp = C(UISprite, trans,"step/coin/const/sp", name)
	self.togLabSp.spriteName = "money_03"
	self.costNumLab = C(UILabel,trans,"step/coin/const/num",name)
end

--设置皮肤按钮红点
function M:SetSkinRed()
	local isShowRed = PetAppMgr.isTransRed
	self.skinRed:SetActive(isShowRed)
  end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
   	local EH = EventHandler
	if self.LeftBtn then
		E(self.LeftBtn, self.OnClickDirBtn, self)
	end
	if self.RightBtn then
		E(self.RightBtn, self.OnClickDirBtn, self)
	end
	if self.UpLvBtn then
		E(self.UpLvBtn, self.OnUpLvBtn, self)
	end
	if self.UpStepBtn then
		E(self.UpStepBtn, self.OnUpStepBtn, self)
		-- UIEvent.Get(self.UpStepBtn.gameObject).onPress= UIEventListener.BoolDelegate(self.OnPressCell, self)
	end
	if self.EquipBtn then
		E(self.EquipBtn, self.OnEquipBtn, self)
	end

	if self.SkinsBtn then
		E(self.SkinsBtn, self.OnSkinsBtn, self)
	end

	if self.ItemTabGbj[1] then
		local cell = self.ItemTabGbj[1]
		UIEvent.Get(cell.gameObject).onClick = function (gameObject) self:Switch(gameObject); end
	end
	if self.ItemTabGbj[2] then
		local cell = self.ItemTabGbj[2]
		UIEvent.Get(cell.gameObject).onClick = function (gameObject) self:Switch(gameObject); end
	end

	if self.tog then
		E(self.tog.gameObject,self.AutoCost,self)
	end
	self.isAutoCost = false
	self.costPNum = 0
	-- for i = 1,#self.ItemTabGbj do
	-- 	local cell = self.ItemTabGbj[i]
	-- 	UIEvent.Get(cell.gameObject).onClick = function (gameObject) self:Switch(gameObject); end
	-- end

	-- if self.Cell then
	-- 	UIEvent.Get(self.Cell.trans.gameObject).onPress= UIEventListener.BoolDelegate(self.OnPressCell, self)
	-- end
	FightVal.eChgFv:Add(self.UpdateFight, self);
	self:SetEvent("Add")
	self:UpdateEvent(EventMgr.Add)
end

function M:RemoveEvent()
	FightVal.eChgFv:Remove(self.UpdateFight, self);
	self:SetEvent("Remove")
	self:UpdateEvent(EventMgr.Remove)
end

function M:SetEvent(fn)
	pMgr.eUpdatePetStepExp[fn](pMgr.eUpdatePetStepExp, self.UpdateChildStepExp, self)
	pMgr.eUpdatePetStep[fn](pMgr.eUpdatePetStep, self.UpdateFx, self)
	pMgr.eUpdatePetUseJingpoItem[fn](pMgr.eUpdatePetUseJingpoItem, self.UpdateJingpo, self)
	pMgr.eUpdatePetStep[fn](pMgr.eUpdatePetStep, self.UpdatePetStep, self)
	pMgr.eUpdatePetStepChange[fn](pMgr.eUpdatePetStepChange, self.UpdatePetStepChange, self)
	pMgr.eUpdatePetExp[fn](pMgr.eUpdatePetExp, self.UpdateLvExp, self)
	pMgr.ePetChangeEquip[fn](pMgr.ePetChangeEquip, self.UpdateEquip , self)
	pMgr.flag.eChange[fn](pMgr.flag.eChange, self.SetBtnFlag, self)
	pMgr.eUpdatePetDev[fn](pMgr.eUpdatePetDev, self.PetDevRed, self)
	PropMgr.eUpdate[fn](PropMgr.eUpdate, self.UpdateItemList, self)
	sMgr.eShowActivity[fn](sMgr.eShowActivity, self.SetFlag, self)
	sMgr.eHideActivity[fn](sMgr.eHideActivity, self.SetFlag, self)
	PetAppMgr.eRespRed[fn](PetAppMgr.eRespRed, self.SetSkinRed, self)
end

function M:PetDevRed()
	-- local ac = pMgr.PetDevRed
	-- self.UpLvBtnRed:SetActive(ac)
end

--是否勾选自动消耗
function M:AutoCost()
	local val = self.tog.value
	local index = 0
	if val == true then
        index = 1
    else
        index = 0
    end
	PlayerPrefs.SetInt("PetAutoCost", index)
	self.isAutoCost = val
	self:ShowCostNum()
end

function M:ShowAutoCost()
	local isVal = false
	if PlayerPrefs.HasKey("PetAutoCost") then
        local val = PlayerPrefs.GetInt("PetAutoCost")
        if val == 1 then
            isVal = true
        else
            isVal = false
		end
	end
	self.tog.value = isVal
	self.isAutoCost = isVal
	self:ShowCostNum()
end

--显示消耗元宝数量
function M:ShowCostNum()
	local isAuto = self.isAutoCost
	local total, ids = 0, ItemsCfg[4].ids
	local GetNum = ItemTool.GetNum
	local propExp = 0
	for i, v in ipairs(ids) do
		local num = GetNum(v)
		total = total + num
		local cfg = ItemData[tostring(v)]
		local getExp = cfg.uFxArg[1]
		propExp = (num * getExp) + propExp
	end
	-- if total > 0 then
	-- 	isAuto = false
	-- end
	local num = 0
	local needProp = 0
	if isAuto == true then
		local cfg = ItemData["30361"]
		local getExp = cfg.uFxArg[1]
		local id = pMgr.StepID
		if not id then return end
		local temp, index = BinTool.Find(PetStepTemp, id, "id")
		if not temp then return end
		local curExp = pMgr.StepExp
		if curExp == nil then
			curExp = 0
		end
		local limit = temp.costSoul
		local needExp = limit - (curExp + propExp)
		if needExp > 0 then
			needProp = math.ceil(needExp/getExp)
			local needCost = StoreData[tostring(pStorId)].curPrice --伙伴进阶丹价格
			num = needCost * needProp
		else
			num = 0
		end
	else
		num = 0
	end
	self.costPNum = needProp
	self.costNumLab.text = num
end

function M:UpdateFx()
	self.StepView.proSpFx1:SetActive(true)
end

function M:SetFlag(red)
	-- local value = SystemMgr:GetSystemIndex(6, pMgr.SysID)
	local value = SystemMgr:GetActivityPage(ActivityMgr.YC,pMgr.SysID)
  	self.rCntr:SetFlag(pMgr.SysID, value)
end

function M:SetBtnFlag(red,index)
	if index == 1 then
		self.upBtnRed.gameObject:SetActive(red)
	end
end

function M:UpdateEvent(E)
	
end

--改变大等阶
function M:UpdatePetStepChange()
	self:ShowView()
	local index = pMgr:GetCurIndex()
	local modelId = PetTemp[index].uMod
	UIShowGetCPM.OpenCPM(modelId)
end

--更新等阶
function M:UpdatePetStep(value)
	self:UpdateStep()
	self:UpdateChildStep(value)
	self:UpdateChildStepExp()
	self:UpdateSkill()
	self:UpdatePro()
	self:UpdateEquip()
end

--道具更新
function M:UpdateItemList()
	self:UpdateItems()
	self:UpdateJingpo()
	self:ShowCostNum()
end
---------------------------------------------------

--初始化数据
function M:ShowView()
	local index = pMgr:GetCurIndex()
	self:UpdateIndex(index)
end

--获得翻页数据
function M:UpdateIndex(index)
	local len = pMgr.Len
	if len == 0 or index < 1 or index > len then 
		return
	end
	if self.Index == index then
		return
	end
	local temp  = PetTemp[index]
	if not temp then return end
	-- if pMgr:IsLimitPage(temp) == true then
	-- 	UITip.Error("该阶伙伴还未解锁")
	-- 	return
	-- end
	self.Index = index
	self.Temp = temp
	self:NameLab()
	self:UpdateStep()
	self:UpdateEquip()
	self:UpdateModel()
end

--宠物数据更新
function M:UpdateData()
	self:UpdateFight()
	self:NameLab()
	self:UpdateStep()
	self:UpdateChildStep()
	self:UpdateChildStepExp()
	self:UpdateSkill()
	self:UpdatePro()
	self:UpdateItems()
	self:UpdateJingpo()
	--self:UpdateModel()
	self:UpdateEquip()
	self:UpdateLvExp()
end

function M:UpdateFight()
	local lb = self.Fight
	if lb then
		local fight = User.MapData:GetFightValue(10)
		if not fight then fight = 0 end
		lb.text = tostring(fight)
	end
end

function M:NameLab()
	local temp = self.Temp
	if not temp then return end
	local lb = self.NameLabel
	if lb then
		local curid = math.floor(pMgr.CurID / 100 )
		local str = ""
		if curid == temp.id then 
			--str = "︵当前︶"
		end
		lb.text = temp.name..str
	end
end

function M:UpdateStep()
	local index = self.Index
	if not index or index == 0 then index = 1 end
	local strStep = self:ChangeStepShow(index)
	if self.Step then
		self.Step.text = tostring(strStep)
	end
end

function M:ChangeStepShow(step)
	if step == 1 then
		return "一"
	elseif step == 2 then
		return "二"
	elseif step == 3 then
		return "三"
	elseif step == 4 then
		return "四"
	elseif step == 5 then
		return "五"
	elseif step == 6 then
		return "六"
	elseif step == 7 then
		return "七"
	elseif step == 8 then
		return "八"
	elseif step == 9 then
		return "九"
	elseif step == 10 then
		return "十"
	end
end

--子等阶
function M:UpdateChildStep(isEffect)
	if isEffect == true then
	end
	local id = pMgr.StepID
	if not id then return end
	local stemp, index =  BinTool.Find(PetStepTemp, id, "id")
	if not stemp then return end
	local value = self.STemp and self.STemp.id ~= stemp.id
	self:UpdateChildStepEffect(stemp, value)
end

--子等阶经验
function M:UpdateChildStepExp(isEffect)
	self:UpdateChildStepExpEff(isEffect)
	local id = pMgr.StepID
	if not id then return end
	local temp, index =  BinTool.Find(PetStepTemp, id, "id")
	if not temp then return end
	self.STemp = temp
	local exp = pMgr.StepExp
	local limit = temp.costSoul

	self.StepView:SetSlider(exp, limit)
	-- self:ShowCostNum()
end

function M:UpdateChildStepExpEff(isEffect)
	if isEffect == true then
		if self.UpStepExeEff then 
			self.UpStepExeEff:SetActive(false)
			self.UpStepExeEff:SetActive(true)
			Audio:PlayByID(Sound, 1)
		end
		if self.UpStepEff then 
			self.UpStepEff:SetActive(false)
			self.UpStepEff:SetActive(true)
		end
		local cfg = ItemsCfg[4]
		if cfg then
			local id = cfg.ids[1]
			 local item = ItemData[tostring(id)]
			if item then
				UITip.Error(string.format("进阶值已提升%s点", item.uFxArg[1]))
			end
		end
	end
end

--子等阶特效
function M:UpdateChildStepEffect(temp, value)
	if not temp then return end
	if not self.StepView then return end
	--self.StepView:SetStar(temp.step, value)

	local step = (temp.id / 100) % 10
	step = math.modf(step)
	if step == pMgr.Len and temp.step == 10 then
		pMgr.flag.isFullStep = true
		pMgr.flag:Update()
	end
	
	self.StepView:SetNewStart(temp.step,value)
end

--更新技能
function M:UpdateSkill()
	local list = pMgr.Skills
	if not list then return end
	self.skill:Refresh(list, self.GetLvSkiLock, self)
	self.skill:Open()
end

--判断等级技能是否解锁
function M:GetLvSkiLock(skiID)
	local stepid = pMgr.StepID
	if not stepid then return false end
	local dic = pMgr.OpenSkills
	if not dic then return false end
  	local k = tostring(skiID)
  	local step = dic[k]
 	 if not step then return false end
  	return stepid < step
end

function M:UpdatePro()
	local prop = self.prop
	prop:Open()
	prop.srcObj = self
	prop.GetCfg = self.GetPropCfg
	prop.quaDic = pMgr.UserDataDic
	prop.quaCfg = PetJingPoTemp
	prop:SetNames(pMgr.ProStr)
	prop:Refresh()
end

--返回属性配置
function M:GetPropCfg()
	local sTemp = self.STemp
	if not sTemp then return nil, nil end
	local temp = PetStepTemp
	local key = "id"
	local id = sTemp.id
	local BF = BinTool.Find
	local cCfg = BF(temp, id, key)
	local nId = id + 1
	local nCfg = BF(temp, nId, str)
	if not nCfg then
		local baseid = math.floor(id / 100)
		nId = (baseid + 1) * 100 + 1
		nCfg = BF(temp, nId, str)
	end
	  if nCfg == nil then nCfg = cCfg end
  	return cCfg, nCfg
end

--进阶经验道具
function M:UpdateItems()
	local cfg = ItemsCfg[4]
	if not cfg then return end
	local items, it = self.ItemTabObj, nil
	local GetNum = ItemTool.GetNum
	local num = 0
	if #items <= 0 then
		for i = 1,#cfg.ids do
			local cellGbj = self.ItemTabGbj[i]
			local it = ObjPool.Get(UIItem)
			local id = cfg.ids[i]
			it:Init(cellGbj.transform)
			it.root.name = id
			it:RefreshByID(id)
			self.ItemTabObj[id] = it
		end
	else
		for i = 1,#cfg.ids do
			local id = cfg.ids[i]
			it = items[i]
			it:RefreshByID(id)
		end
	end

	local isFullStep = pMgr.flag.isFullStep
	local firstId = cfg.ids[1]
	local secondId = cfg.ids[2]
	local firstNum = GetNum(firstId)
	local secondNum = GetNum(secondId)

	local totalExp = 0
	local isCanLv = false
	local needExp = 0
	local curExp = pMgr.StepExp
	for i,v in pairs(cfg.ids) do
		local num1 = GetNum(v)
		num1 = num1 or 0
		if num1 > 0 then
		  local cfg = ItemData[tostring(v)]
		  local exp = cfg.uFxArg[1] * num1
		  totalExp = totalExp + exp
		end
	end

	local id = pMgr.StepID
	if not id then return end
	local temp =  BinTool.Find(PetStepTemp, id, "id")
	local costExp = temp.costSoul
	needExp = costExp - curExp

	if needExp and totalExp >= needExp then
		isCanLv = true
	end
	self.isCanLv = isCanLv
	if (firstNum > 0 or secondNum > 0) and (isFullStep == nil or isFullStep == false) and isCanLv == true then
		self:SetBtnFlag(true,1)
	end
	for i = 1,#cfg.ids do
		local id = cfg.ids[i]
		num = GetNum(id)
		if self.selectId == secondId and secondNum > 0 then
			cell = self.ItemTabObj[secondId]
			self:Switch(cell.root)
			self.selectId = secondId
			return
		elseif --[[self.curCell == nil and--]] num > 0 then
			cell = self.ItemTabObj[id]
			self:Switch(cell.root)
			self.selectId = id
			return
		elseif self.curCell == nil then
			cell = self.ItemTabObj[firstId]
			self:Switch(cell.root)
			self.selectId = firstId
		elseif secondNum == 0 then
			self.ItemTabObj[secondId]:SetSelect(false)
		end
	end
end

function M:Switch(it)
	local id = tonumber(it.name)
	self.selectId = id
	local cellSelf = self.ItemTabObj[id]
	if self.curCell == cellSelf then
		PropTip.pos = self.curCell.root.transform.position
		PropTip.width = self.curCell.qtSp.width
		UIMgr.Open("PropTip", self.ShowTip, self)
		return
	end
	if self.curCell then
		self.curCell:SetSelect(false)
	end
	cellSelf:SetSelect(true)
	self.curCell = cellSelf
end

function M:ShowTip(name)
	local ui = UIMgr.Get(name)
	local id = self.curCell.cfg.id
	ui:UpData(id)
end

--精魄道具
function M:UpdateJingpo()
	local temp = PetJingPoTemp
	if not temp then return end
	local dic = pMgr.UserDataDic
	if not dic then return end
	local qual = self.rCntr.qual
	qual:Open()
	qual:Refresh(temp, dic,pMgr.flag)
end

--幻化
function M:UpdateEquip()
	local index = self.Index
	if not index then return end
	local temp  = PetTemp[index]
	if not temp then return end
	local equipid = math.floor(pMgr.CurID / 100 )
	local curid = math.floor(pMgr.StepID / 100)
	if self.EquipBtn then
		local equip = equipid ~= temp.id
		local value = curid >= temp.id
		-- self.EquipBtn.Enabled = equip and value
	end
	if self.StepRoot then
		self.StepRoot:SetActive(curid >= temp.id)
		if curid < temp.id then
			self:HideStepExpEff()
		end
	end
	if self.EquipLab then
		local str = "幻化"
		self:IsShowAlFlag(false)
		if equipid == temp.id then 
			str = "已幻化"
			self:IsShowAlFlag(true)
		elseif curid < temp.id then
			str = "未解锁"
		end
		self.EquipLab.text = str
	end
end

--是否显示
function M:IsShowAlFlag(isShow)
	self.alFlag.gameObject:SetActive(isShow)
	self.EquipBtn.gameObject:SetActive(not isShow)
end

--等级经验
function M:UpdateLvExp()
	local lv = pMgr.Level
	if not lv then lv = 1 end
	if self.Lv then self.Lv.text = tostring(lv) end
	local exp = pMgr.Exp
	local limit = pMgr.LimitExp
	if limit == 0 then limit = 1 end
	if self.Exp then
		self.Exp.text = string.format("%s/%s", exp, limit)
	end
	local value = exp / limit
	if self.ExpSlider then
		self.ExpSlider.fillAmountValue = value
	end
end
--===============================按钮事件====================================---
--翻页
function M:OnClickDirBtn(go)
	local index = self.Index
	if not index then index = pMgr:GetCurIndex() end
	if go.name == self.LeftBtn.name then
		index = index - 1
	elseif go.name == self.RightBtn.name then
		index = index + 1
	end
	local len = pMgr.Len
	if index < 1 then 
		UITip.Log("已是最低阶")
		index = 1  
	elseif index > len then
		UITip.Log("敬请期待")
		index = len
	end
	self:UpdateIndex(index)
end

--等级提升
function M:OnUpLvBtn(go)
	local total, ids = 0, ItemsCfg[4].ids
  	local GetNum = ItemTool.GetNum
  	for i, v in ipairs(ids) do
    	total = total + GetNum(v)
  	end
  	if total < 1 then
    	UITip.Error("无可使用道具")
  	else
    	for i, v in ipairs(ids) do
      		local num = GetNum(v)
      		if num > 0 then
        		PropMgr.ReqUse(v, num, 1)
      		end
    	end
  	end
end

--进阶
function M:OnUpStepBtn(go)
	local total, ids = 0, ItemsCfg[4].ids
	local GetNum = ItemTool.GetNum
  	for i, v in ipairs(ids) do
    	total = total + GetNum(v)
  	end
	local id = 30361
	local isAutoC = self.isAutoCost
	local pNum = self.costPNum
	-- local uid = PropMgr.TypeIdById(id)
	if PetMgr.flag.isFullStep == true then
		MsgBox.ShowYes("不能再继续升级")
    	return
	end
	if total < 1 or self.isCanLv == false then
		if isAutoC == false then
			if total >= 1 then
				for i, v in ipairs(ids) do
					local num = GetNum(v)
					if num > 0 then
						PropMgr.ReqUse(v, num, 1)
					end
				end
				return
			end
			-- local itID = id
			local itID = self.selectId
			local isSkin = false
			local sysId = 3
			GetWayFunc.AdvGetWay(UIAdv.Name,sysId,itID,isSkin)

			-- UIMgr.Open(UIGetWay.Name, self.OpenGetWayCb ,self)
			return 
		elseif isAutoC == true then
			-- if not uid then
			-- 	iTrace.eError("GS",string.format("招不到id%s的uid",id))
			-- 	return 
			-- end
			-- StoreMgr.QuickBuy(pStorId,pNum,true)
			local isEnough=StoreMgr.QuickBuy(pStorId,pNum,false)
			if isEnough then
				for i, v in ipairs(ids) do
					local num = GetNum(v)
					if v == id then
						num = num + pNum
					end
					if num > 0 then
						PropMgr.ReqUse(v, num, 1)
					end
				  end
				-- PropMgr.ReqUse(id, pNum,1)
			end
			return
		end
	end
	for i, v in ipairs(ids) do
		local num = GetNum(v)
		if num > 0 then
			PropMgr.ReqUse(v, num, 1)
		end
  	end
end

function M:OpenShop()
	local storeId = StoreMgr.GetStoreId(4,M.selectId)
	StoreMgr.selectId = storeId
	StoreMgr.OpenStore(4)
end

--获取途径界面回调
function M:OpenGetWayCb(name)
	local ui = UIMgr.Get(name)
	ui:SetPos(Vector3(85,-110,0))
	local petGetWay = AdvGetWayCfg[3].wayDic
	local len = #petGetWay
	for i = 1,len do
		local wayName = petGetWay[i].v
		ui:CreateCell(wayName, self.OnClickGetWayItem, self)
	end
end

function M:OnClickGetWayItem(name)
	if name == "伙伴副本" then
		AdvMgr:JumpPetCopy()
	elseif name == "商城" then
		AdvMgr:JumpPetStore()
	end
end

--幻化
function M:OnEquipBtn(go)
	local temp = self.Temp
	if not temp then
		UITip.Error("没有宠物数据")
		return 
	end
	local id = temp.id
	local curId = math.floor(pMgr.CurID / 100 )
	local stepId = math.floor(pMgr.StepID / 100 )
	if id > stepId then
		UITip.Error("未解锁")
	elseif id == curId then
		UITip.Log("已经幻化")
	else
		pMgr:ReqPetChange(temp.id)
	end
	-- pMgr:ReqPetChange(temp.id)
end

--皮肤
function M:OnSkinsBtn()
	JumpMgr:InitJump(UIAdv.Name,3)
	UITransApp.OpenTransApp(2)
end

function M:CloseExeView()
	if self.ExpEff then
		self.ExpEff:SetActive(true)
	end
end
--===============================按钮事件====================================---


function M:UpdateModel()
	local temp = self.Temp
	if not temp then return end
	local modRoot = self.ModRoot
	if not modRoot then return end
	local modelID = temp.uMod
	local scModeId = temp.mod
	local key = tostring(modelID)
	local scKey = tostring(scModeId)
	if self.Model ~= nil and self.Model.name == key then return end
	self:CleanModel()
	local roleInfo = RoleBaseTemp[key]
	local scRoleInfo = RoleBaseTemp[scKey]
  	if roleInfo == nil then
    	iTrace.eError("hs", string.format("没有发现ID为:%s的模型配置", modelID))
    	return
  	end
	local modelPath = roleInfo.path
	local scPath = scRoleInfo.path
  	if StrTool.IsNullOrEmpty(modelPath) then
    	iTrace.eError("hs", string.format("ID为:%s的模型配置没有模型路径", modelID))
  	end
	self.rCntr:Lock(true)

	local isExist = AssetTool.IsExistAss(modelPath)
    local isScExist = AssetTool.IsExistAss(scPath)
    if isExist == false or isScExist == false then
      self.rCntr:IsShowAssTip(true)
	  return
	elseif isExist == true and isScExist == true then
		self.rCntr:IsShowAssTip(false)
	end
  	local del = ObjPool.Get(DelGbj)
  	del:Add(modelID)
  	del:SetFunc(self.LoadModCb,self)
	Loong.Game.AssetMgr.LoadPrefab(modelPath, GbjHandler(del.Execute,del))
end

function M:LoadModCb(go,modelID)
	if LuaTool.IsNull(self.ModRoot) then
		Destroy(go)
		return
	end
	self.rCntr:Lock(false)
	self.Model = go
	-- self.Model.name = tostring(modelID)
	self:SetMod(go)
end

function M:LoadEffectCb(go,modelID)
	-- go.name = tostring(modelID)
	self:SetMod(go)
end

function M:SetMod(go)
	local trans = self.Model.transform
	if trans == nil then
		iTrace.eError("GS","模型为空")
		return
	end
	trans.parent = self.ModRoot
	trans.localEulerAngles = Vector3.zero
	trans.localPosition = Vector3.zero
	LayerTool.Set(trans,19)
end

function M:OnPressCell(go, isPress)
	if not go then
		return
	end
	self.clickName = go.name
	if isPress== true then
		self.IsAutoClick = Time.realtimeSinceStartup
	else
		self.IsAutoClick = nil
	end
end


--=======================================================

-- 幻化
function M:UpdateChange()
	if not self.Button1 then return end
	if not self.Data then return end
	local isEnabled = false
	if self.Data and self.Data.IsActive and pMgr.CurEquipID ~= nil and pMgr.CurID ~= self.Data.ID then
		isEnabled = true
	end
	self.Button1.Enabled = isEnabled
end

function M:CleanModel()
	if self.Model then 
		GameObject.Destroy(self.Model)
		self.Model = nil
	end
end

function M:ModSetActive(value)
	local mod = self.Model
	if mod then 
		mod.transform.localEulerAngles = Vector3.zero
		mod.gameObject:SetActive(value) 
	end
end

function M:Update()
	-- local num = ItemTool.GetNum(self.selectId)
	-- if num <= 0 then
	-- 	return
	-- end
	-- if self.IsAutoClick then
	-- 	if Time.realtimeSinceStartup - self.IsAutoClick > 0.05 then
	-- 		self.IsAutoClick = Time.realtimeSinceStartup
	-- 		self:OnUpStepBtn()
	-- 	end
	-- end
end

--清除宠物升级消耗texture
function M:ClearIcon()
	if self.ItemTabObj then
	  for k,v in pairs(self.ItemTabObj) do
		v:ClearIcon()
	  end
	end
end

function M:ItemToPool()
	local len = #self.ItemTabObj
	while len > 0 do
	  local item = self.ItemTabObj[len]
	  if item then
		table.remove(self.ItemTabObj, len)
		ObjPool.Add(item)
	  end
	  len = #self.ItemTabObj
	end
end

function M:ItemGbjD()
	local len = #self.ItemTabGbj
	while len > 0 do
	  local item = self.ItemTabGbj[len]
	  if item then
		table.remove(self.ItemTabGbj, len)
	  end
	  len = #self.ItemTabGbj
	end
end

function M:Open()
	self:AddEvent()
	self.go:SetActive(true)
	if self.StepView then
		self.StepView:Open()
	end
	self:ShowView()
	self:UpdateData()
	self:ModSetActive(true)
	-- if self.ExeView then
	-- 	self.ExeView:Open()
	-- end
	self:SetSkinRed()
	self:PetDevRed()
	self:ShowAutoCost()
end

function M:Close()
	self:RemoveEvent()
	if self.StepView then
		self.StepView:Close()
	end
	self.go:SetActive(false)
	self.IsAutoClick = nil
	if self.STip then 
		self.STip:SetActive(false)
	end
	self:ModSetActive(false)
	if self.skill then
		self.skill:Close()
	end
	self:HideStepExpEff()
	self.Index = nil
	-- if self.ExeView then
	-- 	self.ExeView:Close()
	-- end

	-- self:ClearIcon()
	--self:CleanModel()
end

function M:HideStepExpEff()
	if self.UpStepExeEff then 
		self.UpStepExeEff:SetActive(false)
	end
	if self.UpStepEff then 
		self.UpStepEff:SetActive(false)
	end
end

function M:Dispose()
	self:RemoveEvent()
	self:CleanModel()
	self:ClearIcon()
	self:ItemToPool()
	self:ItemGbjD()
	self.Index = nil
	self.ModRoot = nil
	-- self.go = nil
	if self.prop then
		self.prop:Dispose()
	end
	self.selectId = nil
	self.curCell = nil
	self.NameLabel = nil
	self.Fight = nil
	self.LeftBtn = nil
	self.RightBtn = nil
	self.Step = nil
	self.UpLvBtn = nil
	self.UpStepBtn = nil
	self.IsAutoClick = nil
end
--endregion
