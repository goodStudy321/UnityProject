UISpiritEquipTip = UIBase:New{Name = "UISpiritEquipTip"}

require("UI/Robbery/SpiritG/SPEquipTip")

local My = UISpiritEquipTip

My.eChange = Event()
My.eOpenAdvView = Event()

function My:InitCustom()
    local trans = self.root
    local FC = TransTool.FindChild
    local S = UITool.SetLsnrSelf

    self.putOnTip = ObjPool.Get(SPEquipTip)
    self.putOnTip:Init(FC(trans, "PutOnTip"))

    self.selectTip = ObjPool.Get(SPEquipTip)
    self.selectTip:Init(FC(trans, "SelectTip"))

    self.btnClose = FC(trans, "BtnClose")
    self.btnTakeOff = FC(trans, "BtnTakeOff")  --卸下
    self.btnAdv = FC(trans, "BtnAdv")  --进阶
    self.btnDecom = FC(trans, "BtnDecompose")  --分解
    self.btnPutOn = FC(trans, "BtnPutOn")  --穿戴
    self.btnStrength = FC(trans, "BtnStrength")  --强化

    S(self.btnClose, self.Close, self)
    S(self.btnStrength, self.OnStrength, self)
    S(self.btnTakeOff, self.OnTakeOff, self)
    S(self.btnAdv, self.OnAdv, self)
    S(self.btnDecom, self.OnDec, self)
    S(self.btnPutOn, self.OnPutOn, self)
end

function My:UpdateData()
    self:UpdateSelectTip()
    if self.showBtn then
        if self.compare then
            self:UpdateBtn(false)
            self:UpdatePutOnTip()
        else
            self:UpdateBtn(true)
            self:UpdateBtnAdv()
            self.putOnTip:Close()     
        end
    end
end

function My:UpdateBtn(state)
    self.btnPutOn:SetActive(not state)
    self.btnDecom:SetActive(not state)
    self.btnTakeOff:SetActive(state)
end

function My:UpdateBtnAdv()
    local equipData = self.data
    local advLv = equipData.level
    local equipCfg = self:GetEquipCurCfg()
    local isAdv = equipCfg.sLimit <= advLv
    self.btnAdv:SetActive(isAdv)
    self.btnStrength:SetActive(not isAdv)
end

function My:GetEquipCurCfg()
    local equipId = self.data.typeId
    equipId = tostring(equipId)
    local equipData = SpiritEquipCfg[equipId]
    return equipData
end

function My:UpdatePutOnTip()
    local data = SpiritGMgr:GetEquipCompInfo(self.data.part)
    if not data then
        self.putOnTip:Close()
    else
        self.putOnTip:Open(data)
    end
end


function My:UpdateSelectTip()
    self.selectTip:Open(self.data)
end


function My:Show(data, showBtn , compare)
    self.data = data
    self.showBtn = showBtn
    self.compare = compare
    UIMgr.Open(self.Name, self.OpenCb, self)
end

function My:OpenCb()
    self:UpdateData()
end

--强化
function My:OnStrength()
    JumpMgr:InitJump(UIRobbery.Name,3)
    local equipId = self.data.id--服务端生成的唯一id
    local spId = SpiritGMgr:GetCurSPId()
    SpiritGMgr:SetEquipId(equipId)
    UISpiritStrength.OpenUIByData()
    -- UIMgr.Open(UISpiritStrength.Name)
    self:Close()
end

--卸下
function My:OnTakeOff()
    if self.data then
        SpiritGMgr:ReqSpiritEquipUnLoad(self.data.id)
    end
    self:Close()
end

--进阶
function My:OnAdv()
    JumpMgr:InitJump(UIRobbery.Name,3)
    UISpiritAdv:Show(self.data)
    self:Close()
end

--装备
function My:OnPutOn()
    local equipId = self.data.id
    SpiritGMgr:ReqSpiritEquipLoad(equipId)
    self:Close()
end

--分解
function My:OnDec()
    self:Close()
    UIMgr.Open(UISpiritCompose.Name)
end

function My:CloseCustom()

end

function My:DisposeCustom()
    self.data = nil
    self.showBtn = nil
    self.compare = nil
    ObjPool.Add(self.putOnTip)
    ObjPool.Add(self.selectTip)
    self.putOnTip = nil
    self.selectTip = nil
end

return My