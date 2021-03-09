SpiritStrengthInfo = Super:New{Name = "SpiritStrengthInfo"}

local My = SpiritStrengthInfo

function My:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC= TransTool.FindChild
    local F = TransTool.Find
    local S = UITool.SetLsnrSelf


    self.itemRoot = F(trans, "ItemRoot")
    -- self.curLv = G(UILabel, trans, "CurLevel")
    -- self.nextLv = G(UILabel, trans, "NextLevel")
    self.curPro = G(UISprite, trans, "Progress/Cur")
    -- self.nextPro = G(UISprite, trans, "Progress/Next")
    self.proNum = G(UILabel, trans, "Progress/Num")
    self.desLab = G(UILabel, trans, "streng/desLab")
    self.attr = G(UILabel, trans, "streng/Attr")
    self.attr1 = G(UILabel, trans, "streng/Attr1")
    self.attr11 = G(UILabel, trans, "streng/Attr1/lab")
    self.attr2 = G(UILabel, trans, "streng/Attr2")
    self.attr22 = G(UILabel, trans, "streng/Attr2/lab")
    self.needNum = G(UILabel, trans, "streng/need/num")
    self.advItemRoot = F(trans,"adv/item")
    self.advPropNum = G(UILabel, trans, "adv/advNum")
    
    self.strengthInfo = FC(trans,"streng")
    self.advInfo = FC(trans,"adv")
    self.progressG = FC(trans, "Progress")
    self.advInfo:SetActive(false)

    self.strenBtn = FC(trans,"streng/Btn")
    self.keyStrenBtn = FC(trans,"streng/keyBtn")
    self.advBtn = FC(trans,"adv/Btn")
    -- self.tick = G(UIToggle, trans, "Tick")
    -- self.cost = G(UILabel, trans, "Cost")
    self.isCanAdv = false

    S(self.strenBtn,self.OnStrength,self)
    S(self.keyStrenBtn,self.OnKeyStrength,self)
    S(self.advBtn,self.OnAdv,self)
end

function My:UpdateData(data)
    self.data = data
    self:Refresh()
end

function My:Refresh()
    -- self:UpdateCurLv()
    -- self:UpdateNextLv()
    self:UpdateCell()
    self:UpdatePro()
    self:UpdateAttr()
    -- self:UpdateCost()
end

function My:UpdateCurLv()
    self.curLv.text = string.format( "+%s", self.data.level)
end

function My:UpdateNextLv(lv)
    lv = lv or self.data.level+1
    self.nextLv.text = string.format( "+%s", lv)
end

function My:UpdateCell()
    if not self.cell then
        self.cell = ObjPool.Get(SPCell)
        self.cell:InitLoadPool(self.itemRoot)
    end
    self.cell:UpdateData(self.data)
end

function My:UpdatePro(exp)
    exp = exp or 0
    local nextExp,sExp,add = SpiritGMgr:GetNextLvAdvExp(self.data.level)
    local curStrVal = SpiritGMgr.strengthExpVal
    curStrVal = tonumber(curStrVal)
    local equipData = self:GetEquipCurCfg()
    local isAdv = equipData.sLimit <= self.data.level
    local advExp = self.data.advExp
    local desStr = string.format("强化达到[F39800FF]%d[-]级,可以进行进阶", equipData.sLimit)
    self.desLab.text = desStr
    self.advInfo.gameObject:SetActive(isAdv)
    self.progressG.gameObject:SetActive(not isAdv)
    self.strengthInfo.gameObject:SetActive(not isAdv)

    if sExp then
        local curExp = 0
        if self.data.level > 0 then
            curExp = advExp
        end
        self.isCanAdv = true
        self.curPro.fillAmount = curExp/sExp
        self.proNum.text = string.format("[F4DDBDFF]%s [F4DDBDFF]/ %s", curExp,sExp)
        self.needNum.text = string.format("%s / %s", curStrVal,nextExp)
        self.advBtn:SetActive(true)
    else
        self.isCanAdv = false
        self.curPro.fillAmount = 1
        self.advBtn:SetActive(false)
        self.proNum.text = "[F4DDBDFF]已满级"
    end
end

function My:GetEquipCurCfg()
    local equipId = self.data.typeId
    equipId = tostring(equipId)
    local equipData = SpiritEquipCfg[equipId]
    return equipData
end

function My:UpdateAttr()
    local level = self.data.level
    local curProp,nextProp = SpiritGMgr:GetEquipTotalBaseAttr(self.data) 
    if curProp == nil then
        return
    end
    -- local len = #curProp
    -- if not self.sb then
    --     self.sb = ObjPool.Get(StrBuffer)
    -- end
    -- self.sb:Dispose()
    -- local sb = self.sb
    self.attr1.text = string.format("%s:  %d", PropName[curProp[1].type].name, curProp[1].all)
    self.attr11.text = string.format("%d", nextProp[1].all)
    self.attr2.text = string.format("%s:  %d", PropName[curProp[2].type].name, curProp[2].all)
    self.attr22.text = string.format("%d", nextProp[2].all)
    -- for i=1, len do
        -- local arg = string.format("[F4DDBDFF]%s:  %d     [00FF00FF]  %d", PropName[curProp[i].type].name, curProp[i].all, nextProp[i].all)
        -- sb:Apd(arg)
        -- if i<len then
        --     sb:Line()
        -- end
    -- end
    -- local str = sb:ToStr()
    -- self.attr.text = str
end

function My:UpdateCost(cost)
    cost = cost or 0
    local state = SoulBearstMgr:GetGoldState()
    local color = state and "[F39800FF]" or "[F21919FF]"
    self.cost.text = string.format("%s%s", color, cost)
end

--强化按钮
function My:OnStrength()
    if not self.cell then
        UITip.Error("当前没有装备！")
        return
    end
    local info = self.data
    local curExp = SpiritGMgr.strengthExpVal
    curExp = tonumber(curExp)
    local nextExp = SpiritGMgr:GetNextLvAdvExp(self.data.level)
    if nextExp == nil then
        UITip.Error("已升到最大级")
        return
    end
    if curExp <= 0 or curExp < nextExp then
        UITip.Error("经验不足！")
        return
    end
    local Id = info.id --服务端生成的唯一id
    SpiritGMgr:ReqSpiritEquipStr(Id)
end

--一键强化
function My:OnKeyStrength()

end

--进阶按钮
function My:OnAdv()
    JumpMgr:InitJump(UISpiritStrength.Name)
    UISpiritAdv:Show(self.data)
end

function My:Dispose()
    self.data = nil
    if self.advCell then
        self.advCell:DestroyGo()
        ObjPool.Add(self.advCell)
    end

    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
    end
    if self.sb then
        ObjPool.Add(self.sb)
    end
    self.sb = nil
    self.cell = nil
    self.advCell = nil
    self.conPropInfo = nil
    self.isCanAdv = nil
    TableTool.ClearUserData(self)
end

return My