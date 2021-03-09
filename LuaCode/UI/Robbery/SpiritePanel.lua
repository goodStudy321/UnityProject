require("UI/Robbery/UIListSpModItem")
require("UI/Robbery/UISpSkill")

SpiritePanel = UILoadBase:New{Name = "SpiritePanel"}
local My = SpiritePanel
local robberMgr = RobberyMgr

local SMIT = UIListSpModItem
local PId = 30402
local pStorId = 50007

function My:Init()
    local root = self.GbjRoot.transform
    self.Gbj = root
    local name = root.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local USBC = UITool.SetBtnClick
    local TFC = TransTool.FindChild

    self.gridItem = CG(UIGrid,root,"mods/Grid",name)

    self.healthLab = CG(UILabel,root,"prop/oneProp",name)
    self.next1=CG(UILabel,root,"prop/oneProp/next",name)
    self.attLab = CG(UILabel,root,"prop/twoProp",name)
    self.next2=CG(UILabel,root,"prop/twoProp/next",name)
    self.defLab = CG(UILabel,root,"prop/threeProp",name)
    self.next3=CG(UILabel,root,"prop/threeProp/next",name)
    self.breakLab = CG(UILabel,root,"prop/fourProp",name)
    self.next4=CG(UILabel,root,"prop/fourProp/next",name)
    self.attAddLab = CG(UILabel,root,"prop/fiveProp",name)
    self.next5=CG(UILabel,root,"prop/fiveProp/next",name)

    -- local skillTip = CG(BoxCollider, root,"skilTip", name)
    -- self.skilTipG = TFC(root,"skilTip",des)
    -- self.skilTipLab = CG(UILabel, root,"skilTip/Label", name)

    self.slider = CG(UISprite,root,"sliderSp/slid",name)
    self.sliderLab = CG(UILabel,root,"sliderSp/slidLab",name)
    self.getStateLab = CG(UILabel,root,"sliderSp/getStateLab",name)
    self.lvLab = CG(UILabel,root,"curName/lvLab",name)

    self.desBtn = CG(BoxCollider, root,"desBtn", name)

    local skill = TF(root,"skill",name)
    self.spSkills = UISpSkill:New()
    self.spSkills:Init(skill)
    self.feedSpBtn = CG(UIButton, root, "feedBtn", name)
    self.lockDesLab = CG(UILabel,root,"LockDes",name)

    self.modelRoot = TF(root,"modelRoot",name)
    self.item = TF(root,"mods/Grid/item",name)
    self.item.gameObject:SetActive(false)
    self.items = {}

    self.itemProp = TF(root,"item",name)
    self.itemProp.gameObject:SetActive(false)

    self.itemPropObj = nil
    self.itemPropObj = ObjPool.Get(Cell)
    self.itemPropObj:InitLoadPool(root,0.9,nil,nil,nil,Vector3.New(412,-77,0))
    UITool.SetLsnrSelf(self.itemPropObj.trans, self.OnClick, self, des, false)
    

    self.isCurSp = false
    self.isNeedState = 1
    self.equipLab = CG(UILabel,root,"equipBtn/lab",name)

    self.curNameLab = CG(UILabel,root,"curName/lab",name)

    self.tog = CG(UIToggle, root,"coin/tog", name)
    self.costNumLab = CG(UILabel,root,"coin/const/num",name)
    self.togLab = CG(UILabel, root,"coin/tog/des", name)
    self.togLab.text = "不足时自动消耗绑元(绑元不足消耗元宝)"
    self.togLabSp = CG(UISprite, root,"coin/const/sp", name)
    self.togLabSp.spriteName = "money_03"
    
    UITool.SetLsnrSelf(self.tog.gameObject, self.AutoCost, self, des, false)

    USBC(root,"feedBtn", name, self.ClickFeedBtn, self)
    USBC(root,"equipBtn", name, self.ClickEquipBtn, self)
    -- USBC(root,"skill/icon/icon", name, self.ClickSkillBtn, self)
    -- UITool.SetLsnrSelf(skillTip, self.OnClickTipBtn, self, nil, false)
    UITool.SetLsnrSelf(self.desBtn, self.OnClickSpDBtn, self)

    self:SetEvent("Add")
    --计时器
    self.Timer = ObjPool.Get(DateTimer);
    self.Timer.complete:Add(self.timeOver, self);
    self.CanPoint=true;
    self:InitSpiriteItem()
end

--是否勾选自动消耗
function My:AutoCost()
	local val = self.tog.value
	local index = 0
	if val == true then
        index = 1
    else
        index = 0
    end
	PlayerPrefs.SetInt("SpiritAutoCost", index)
	self.isAutoCost = val
	self:ShowCostNum()
end

function My:ShowAutoCost()
	local isVal = false
	if PlayerPrefs.HasKey("SpiritAutoCost") then
        local val = PlayerPrefs.GetInt("SpiritAutoCost")
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
function My:ShowCostNum()
	local isAuto = self.isAutoCost
	local total, ids = 0, PId
	local GetNum = ItemTool.GetNum
    total = total + GetNum(ids)
	-- if total > 0 then
	-- 	isAuto = false
	-- end
	local num = 0
    local needProp = 0
    local spiriteInfo = RobberyMgr.SpiriteInfoTab
	if isAuto == true then
		local cfg = ItemData[tostring(ids)]
		local getExp = cfg.uFxArg[1]
        local curExp,limit = self:GetCoExp()
        local propExp = total * getExp
        local needExp = limit - (curExp + propExp)
        if needExp > 0 then
            needProp = math.ceil(needExp/getExp)
            local needCost = StoreData[tostring(pStorId)].curPrice --战魂丹价格
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

function My:OnClickSpDBtn(go)
    local desInfo = InvestDesCfg["1022"]
    local str = desInfo.des
     UIComTips:Show(str, Vector3(130,185,0),nil,nil,nil,nil,UIWidget.Pivot.TopLeft)
end

function My:OnClick()
    UIMgr.Open(PropTip.Name, self.ShowTip, self)
end

function My:ShowTip(name)
    local ui = UIMgr.Get(name)
    local id = PId
    ui:UpData(tostring(id))
  end

function My:SetTime()
	if self.Timer == nil then
		return;
	end
	self.Timer.seconds =11;
    self.Timer:Start();
    self.CanPoint=false;
end
function My:timeOver( )
    self.CanPoint=true;
end

function My:SetEvent(fn)
	RobberyMgr.eUpdateSpiInfo[fn](RobberyMgr.eUpdateSpiInfo, self.RefreshSpirState, self)
    RobberyMgr.eUpdateSpiRefInfo[fn](RobberyMgr.eUpdateSpiRefInfo, self.SetSpProp, self)
    
    if self.feedSpBtn then
		-- UIEvent.Get(self.feedSpBtn.gameObject).onPress= UIEventListener.BoolDelegate(self.OnPressCell, self)
    end
end

function My:OnPressCell(go,isPress)
	if not go then
		return
	end
	if isPress == true then
		self.IsAutoClick = Time.realtimeSinceStartup
	else
		self.IsAutoClick = nil
	end
end

function My:Update()
	-- local num = PropMgr.TypeIdByNum(PId)
	-- if num <= 0 then
	-- 	return
    -- end
	-- if self.IsAutoClick then
	-- 	if Time.realtimeSinceStartup - self.IsAutoClick > 0.05 then
    --         self.IsAutoClick = Time.realtimeSinceStartup
	-- 		self:ClickFeedBtn()
	-- 	end
	-- end
end

function My:OnClickTipBtn(go)
    -- if go then
    --     go.gameObject:SetActive(false)
    -- end
end

function My:Open()
    local curSp = RobberyMgr.curSpiId
    if curSp == nil or curSp == 0 then
        curSp = SpiriteCfg["10101"].spiriteId
    end
    curSp = tostring(curSp)
    -- self:OnClickItem(self.items["10101"].root) 
    self:OnClickItem(self.items[curSp].root) 
    self:InitPropCell()
    self:SetItemNum()
    self:ShowAutoCost()
    PropMgr.eUpdate:Add(self.SetItemNum, self)
    -- self.Gbj.gameObject:SetActive(true)
end

function My:ClickFeedBtn()
    if self.isNeedState == 2 then
        UITip.Error("请提升境界")
        return
    end
    if self.isNeedState == 3 then
        UITip.Error("已经达到最高等级")
        return
    end
    
    local spiriteInfo = RobberyMgr.SpiriteInfoTab
    if spiriteInfo.spiriteTab == nil then
        UITip.Error("战灵未解锁")
        return
    end
    local spInfo = spiriteInfo.spiriteTab[self.curSpId]
    if spInfo == nil then
        UITip.Error("战灵未解锁")
        return
    end
    
    local itemid = tostring(PId)
    local propNum = PropMgr.TypeIdByNum(itemid)
    local isAutoC = self.isAutoCost
	local pNum = self.costPNum
    if propNum <= 0 or self.isCanLv == false then
        if isAutoC == false then
            -- UITip.Error("请获取道具")
            if propNum > 0 then
                RobberyMgr:ReqUpLvSp(self.curSpId,propNum)
                return
            end
            UIMgr.Open(UIGetWay.Name, self.OpenGetWayCb ,self)
            return
        elseif isAutoC == true then
            local isEnough = StoreMgr.QuickBuy(pStorId,pNum,false)
            if isEnough then
                local num = PropMgr.TypeIdByNum(itemid)
                num = num + pNum
                RobberyMgr:ReqUpLvSp(self.curSpId,num)
            end
            return
        end
    end
    RobberyMgr:ReqUpLvSp(self.curSpId,propNum)
end

--获取途径界面回调
function My:OpenGetWayCb(name)
	local ui = UIMgr.Get(name)
	ui:SetPos(Vector3(192,-165,0))
    ui:CreateCell("商城", self.OnClickGetWayItem, self)
end

function My:OnClickGetWayItem(name)
    if name == "商城" then
        JumpMgr:InitJump(UIRobbery.Name,2)
		StoreMgr.OpenStoreId(PId)
	end
end

function My:ClickEquipBtn()

    if self.isCurSp == true then
        UITip.Error("当前战灵已装备")
        return
    end
    local isLock = self:IsLockCurSp()
    if isLock == true then
        UITip.Error("战灵未解锁")
        return
    end
    if self.CanPoint~=true then
        UITip.Error("“切换战灵需要消耗很大的精神力，请10秒后再切换")
        return
    end
    RobberyMgr:ReqChangeSp(self.curSpId)
    self:SetTime();
  
end

--判断当前战灵是否解锁
--true:未解锁    false:已经解锁
function My:IsLockCurSp()
    local spiriteInfo = RobberyMgr.SpiriteInfoTab
    if spiriteInfo.spiriteTab == nil then
        return true
    elseif spiriteInfo.spiriteTab ~= nil and spiriteInfo.spiriteTab[self.curSpId] == nil then
        return true
    end
    return false
end

function My:ClickSkillBtn()
    if self.curSkillCfg ~= nil then
        local cfg = self.curSkillCfg
        -- local str = string.format("当前技能id:%s,  技能名称：%s",cfg.id,cfg.name)
        -- UITip.Error(str)
      
        self.skilTipG:SetActive(true)
        local skillId = tostring(cfg.id)
        local skillInfo = SkillLvTemp[skillId]
        self.skilTipLab.text = skillInfo.desc
    end
end

function My:InitSpiriteItem()
    local item = self.item
    local Inst = GameObject.Instantiate
    local robSevInfo = RobberyMgr.SpiriteInfoTab
    local tabTemp = {}
    for k,v in pairs(SpiriteCfg) do
        table.insert(tabTemp,v)
    end
    table.sort(tabTemp,function(a,b) return a.spiriteId < b.spiriteId end)
    local len = #tabTemp
    for i = 1,len do
        local go = Inst(item)
        local date = tabTemp[i]
        self:AddItem(date,go,robSevInfo)
    end
    self.gridItem:Reposition()
end

function My:AddItem(info,go,robSevInfo)
    if go == nil then return end
    local trans = go.transform
    local it = ObjPool.Get(SMIT)
    it:Init(go)
    it.root.name = info.spiriteId
    go.gameObject:SetActive(true)
    local modId = tostring(info.spiriteId)
    self.items[modId] = it
    TransTool.AddChild(self.gridItem.transform,trans)
    UITool.SetLsnrSelf(trans, self.OnClickItem, self, nil, false)
    it:InitData(info)
    if robSevInfo.spiriteTab ~= nil and robSevInfo.spiriteTab[info.spiriteId] ~= nil then
        it:SetLock(false)
    end
end

function My:OnClickItem(go)
    local key = go.name
	local item = self.items[key]
	if not item then return end
	if self.SelectItem then
        self.SelectItem:IsSelect(false)
        self.SelectItem:SetActive(false,self.curClickSpCfg.uiMod,self.modelRoot)
	end
    self.curSpId = tonumber(key)
    self.curClickSpCfg = SpiriteCfg[key]
    self:SetSpProp()
	self.SelectItem = item
    self.SelectItem:IsSelect(true)
	local data = SpiriteCfg[key]
    self.curNameLab.text = data.name
	if not data then return end
    item:SetActive(true,data.uiMod,self.modelRoot)
    self:ShowCostNum()
    -- item:LoadMod(data.uiMod,self.modelRoot)
end

--获取经验
function My:GetCoExp()
    local curSpId = self.curSpId
    local spiriteInfo = RobberyMgr.SpiriteInfoTab
    local lv,curExp,limitExp = 1,0,0
    if spiriteInfo.spiriteTab == nil or spiriteInfo.spiriteTab[curSpId] == nil then
        curLvData = RobberyMgr:GetCurSpiriteCfg(curSpId,1)
        lv = 1
        curExp = 0
        limitExp = curLvData.exp
    else
        local id = spiriteInfo.spiriteTab[curSpId].id
        lv = spiriteInfo.spiriteTab[curSpId].lv
        curLvData = RobberyMgr:GetCurSpiriteCfg(id,lv)
        curExp = spiriteInfo.spiriteTab[curSpId].exp
        limitExp = curLvData.exp
    end
    return curExp,limitExp
end

function My:SetSpProp()
    local curSpId = self.curSpId
    local spiriteInfo = RobberyMgr.SpiriteInfoTab
    local curBigStateId = RobberyMgr.StateInfoTab.bigState
    local health,define,dodge,tough,skill = 0,0,0,0,0
    local curLvData = nil
    local nxtLvData = nil;
    local lv = 1
    local curExp = 0
    if spiriteInfo.spiriteTab == nil or spiriteInfo.spiriteTab[curSpId] == nil then
        curLvData = RobberyMgr:GetCurSpiriteCfg(curSpId,1)
        nxtLvData= RobberyMgr:GetCurSpiriteCfg(curSpId,2)
        lv = 1
        curExp = 0
        self:RefreshSpiInfo(curLvData,lv,curExp,nxtLvData)
    else
        local id = spiriteInfo.spiriteTab[curSpId].id
        lv = spiriteInfo.spiriteTab[curSpId].lv
        curLvData = RobberyMgr:GetCurSpiriteCfg(id,lv)
        nxtLvData= RobberyMgr:GetCurSpiriteCfg(curSpId,lv+1)
        curExp = spiriteInfo.spiriteTab[curSpId].exp
       self:RefreshSpiInfo(curLvData,lv,curExp,nxtLvData)
    end
    self:RefreshSpirState()
    self:ShowCostNum()
    self:IsCanLv()
end

--刷新战灵信息
function My:RefreshSpiInfo(curLvData,curLv,curExp,nxtLvData)
    local stateInfo = RobberyMgr.StateInfoTab
    local smallState = stateInfo.smallState
    local bigState = stateInfo.bigState
    if smallState == nil or bigState == nil then
        return
    end
    local curAmbData = RobberyMgr.AmbitInfo[bigState][smallState]
    local curStateId = curAmbData.id

    local health,att,def,breakVal,attAdVal = 0,0,0,0,0
    health = curLvData.health
    att = curLvData.attVal
    def = curLvData.defVal
    breakVal = curLvData.breakVal
    attAdVal = curLvData.attAddVal
    self.healthLab.text = string.format("[F4DDBDFF]生命:[-]       [F39800FF]%s[-]",health)
    self.attLab.text = string.format("[F4DDBDFF]攻击:[-]       [F39800FF]%s[-]",att)
    self.defLab.text = string.format("[F4DDBDFF]防御:[-]       [F39800FF]%s[-]",def)
    self.breakLab.text = string.format("[F4DDBDFF]破甲:[-]       [F39800FF]%s[-]",breakVal)
    self.attAddLab.text = string.format("[F4DDBDFF]攻击加成:[-] [F39800FF]%s%s[-]",attAdVal/100,"%")
    local isShow = nxtLvData == nil and false or true
    if nxtLvData==nil then
        self.next1.gameObject:SetActive(isShow);
        self.next2.gameObject:SetActive(isShow);
        self.next3.gameObject:SetActive(isShow);
        self.next4.gameObject:SetActive(isShow);
        self.next5.gameObject:SetActive(isShow);
    else
        -- self.next1.gameObject:SetActive(true);
        -- self.next2.gameObject:SetActive(true);
        -- self.next3.gameObject:SetActive(true);
        -- self.next4.gameObject:SetActive(true);
        -- self.next5.gameObject:SetActive(true);
        if isShow == true then
            self.next1.text=nxtLvData.health-health;
            self.next2.text=nxtLvData.attVal-att
            self.next3.text=nxtLvData.defVal-def
            self.next4.text=nxtLvData.breakVal-breakVal
            self.next5.text=nxtLvData.attAddVal/100-attAdVal/100
        end
    end
   
    local getState = curLvData.getState
    -- getState = math.floor(getState/100)
    -- getState = getState - 10 + 1
    local needExp = curLvData.exp
    local maxLv = 1000
    if nxtLvData == nil then
        maxLv = curLvData.lv
    end

    local expSlid = 1
    local lvLa = string.format("Lv.%s",curLv)
    local expLab = ""
    local getStateLb = ""
    if getState > curStateId and curExp >= needExp then
        -- local ambId = getState - 10 + 1
        local bigId = RobberyMgr:GetBigState(getState)
        local smallId = RobberyMgr:GetSmallState(getState)
        local ambInfo = RobberyMgr.AmbitInfo[bigId][smallId]
        local ambName = ambInfo.nameOnly
        getStateLb = string.format("达到%s突破上限",ambName)
        self.sliderLab.gameObject:SetActive(false)
        self.isNeedState = 2
        expSlid = 1
    elseif curLv == maxLv and curExp >= needExp then
        getStateLb = "已经达到最高等级"
        self.sliderLab.gameObject:SetActive(false)
        self.isNeedState = 3
        expSlid = 1
    elseif curExp < needExp then
        expLab = string.format("%s/%s",curExp,needExp) 
        self.sliderLab.gameObject:SetActive(true)
        self.isNeedState = 1
        expSlid = curExp/needExp
    end

    self.slider.fillAmountValue = expSlid
    self.sliderLab.text = expLab
    self.getStateLab.text = getStateLb
    self.lvLab.text = lvLa
--解锁说明
    local isLock = self:IsLockCurSp()
    local lockDesStr = ""
    if isLock == true then
        -- local unLockId = spCfg.lockState
        -- local ambId = unLockId - 10 + 1
        -- local ambInfo = AmbitCfg[ambId]
        lockDesStr = self.curClickSpCfg.tip
    end
    self.lockDesLab.text = lockDesStr

    self.curSpCfgInfo = curLvData
    local skillsList = RobberyMgr:GetCurSpSkillTab(curLvData.spiriteId)
    self.getSkillList = self:GetHaveSkill()

    self.spSkills:Refresh(skillsList,self.GetLvSkiLock,self)
    self.spSkills:Open()
    -- self:SetSkillDate(curLvData)
end

--判断技能是否解锁
--true :未解锁  false:解锁
function My:GetLvSkiLock(skillId)
    local spLockState = self:IsLockCurSp()
    if spLockState then
        return true
    end
    if self.getSkillList[skillId] == nil then
        return true
    else
        return false
    end
end

function My:GetHaveSkill()
    local skillTab = {}
    local curSkills = self.curSpCfgInfo.skills
    for i = 1,#curSkills do
        local skillId = curSkills[i]
        skillTab[skillId] = skillId
    end
    return skillTab
end

--刷新战灵状态
function My:RefreshSpirState()
    local spiriteInfo = RobberyMgr.SpiriteInfoTab
    if spiriteInfo.curId ~= nil and spiriteInfo.curId == self.curSpId then
        self.isCurSp = true
        self.equipLab.text = "已装备"
    else
        self.isCurSp = false
        self.equipLab.text = "装备"
    end
   
end

function My:InitPropCell()
    local itemid = tostring(PId)
    local propNum = PropMgr.TypeIdByNum(itemid)

    propNum = UIMisc.ToString(propNum,false)
    -- propNum = tostring(propNum)
    self.itemPropObj:UpData(itemid)
    self.itemPropObj:UpLab(propNum)
end

function My:SetItemNum()
    local itemid = tostring(PId)
    local propNum = PropMgr.TypeIdByNum(itemid)
    propNum = UIMisc.ToString(propNum,false)
    -- propNum = tostring(propNum)
    self.itemPropObj:UpLab(propNum)
    self:ShowCostNum()
    self:IsCanLv()
end

--是否可以升级
function My:IsCanLv()
    local totalExp = 0
	local isCanLv = false
    local needExp = 0
    local GetNum = ItemTool.GetNum
    local num1 = GetNum(PId)
    num1 = num1 or 0
    if num1 > 0 then
        local cfg = ItemData[tostring(PId)]
        local exp = cfg.uFxArg[1] * num1
        totalExp = totalExp + exp
    end
    local curExp,costExp = self:GetCoExp()
	needExp = costExp - curExp
	if needExp and totalExp >= needExp then
		isCanLv = true
	end
	self.isCanLv = isCanLv
end

function My:ClearSkilIcon()
    if self.texName then
        AssetMgr:Unload(self.texName,".png",false)
        self.texName = nil
    end
end

function My:CloseC()
    PropMgr.eUpdate:Remove(self.SetItemNum, self)
    -- if not LuaTool.IsNull(self.Gbj) then
    --     self.Gbj.gameObject:SetActive(false)
    -- end
    self.IsAutoClick = nil
end


function My:Clear()
    if self.itemPropObj then
        self.itemPropObj:DestroyGo()
        ObjPool.Add(self.itemPropObj)
        self.itemPropObj = nil
    end
    if self.items then
        for k,v in pairs(self.items) do
            v:Dispose()
            ObjPool.Add(v)
            self.items[k] = nil
        end
    end
end

function My:Dispose()
    self.SelectItem = nil
    self.IsAutoClick = nil
    self:SetEvent("Remove")
    self:Clear()
    self:CloseC()
    self.spSkills:Dispose()
    AssetTool.Unload(self.modelRoot.transform)
    if self.Timer==nil then
        return
    end
	self.Timer:AutoToPool();
	self.Timer = nil;
    -- TableTool.ClearUserData(self)
end