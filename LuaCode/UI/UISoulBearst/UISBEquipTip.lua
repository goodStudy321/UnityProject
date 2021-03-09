UISBEquipTip = UIBase:New{Name = "UISBEquipTip"}

require("UI/UISoulBearst/SBEquipTip")

local M = UISBEquipTip

M.eChange = Event()
M.eOpenAdvView = Event()

function M:InitCustom()
    local trans = self.root
    local FC = TransTool.FindChild
    local S = UITool.SetLsnrSelf

    self.putOnTip = ObjPool.Get(SBEquipTip)
    self.putOnTip:Init(FC(trans, "PutOnTip"))

    self.selectTip = ObjPool.Get(SBEquipTip)
    self.selectTip:Init(FC(trans, "SelectTip"))

    self.btnClose = FC(trans, "BtnClose")
    self.btnChange = FC(trans, "BtnChange")
    self.btnTakeOff = FC(trans, "BtnTakeOff")
    self.btnAdv = FC(trans, "BtnAdv")
    self.btnPutOn = FC(trans, "BtnPutOn")

    S(self.btnClose, self.Close, self)
    S(self.btnChange, self.OnChange, self)
    S(self.btnTakeOff, self.OnTakeOff, self)
    S(self.btnAdv, self.OnAdv, self)
    S(self.btnPutOn, self.OnPutOn, self)
end

function M:UpdateData()
    self:UpdateSelectTip()
    if self.showBtn then
        if self.compare then
            self:UpdateBtn(false)
            self:UpdatePutOnTip()
        else
            self:UpdateBtn(true)
            self.putOnTip:Close()     
        end
    else
        self:UpdateBtnsState(false)
    end
end

function M:UpdateBtnsState()
    self.btnPutOn:SetActive(state)
    self.btnChange:SetActive(state)
    self.btnTakeOff:SetActive(state)
    self.btnAdv:SetActive(state)
end

function M:UpdateBtn(state)
    self.btnPutOn:SetActive(not state)
    self.btnChange:SetActive(state)
    self.btnTakeOff:SetActive(state)
    self.btnAdv:SetActive(state)
end

function M:UpdatePutOnTip()
    local data = SoulBearstMgr:GetEquipCompInfo(self.data.part)
    if not data then
        self.putOnTip:Close()
    else
        self.putOnTip:Open(data)
    end
end


function M:UpdateSelectTip()
    self.selectTip:Open(self.data)
end


function M:Show(data, showBtn , compare)
    self.data = data
    self.showBtn = showBtn
    self.compare = compare
    UIMgr.Open(self.Name, self.OpenCb, self)
end

function M:OpenCb()
    self:UpdateData()
end

--替换
function M:OnChange()
    if self.data then
        self.eChange(self.data.part, self.data.quality)
    end
    self:Close()
end

--卸下
function M:OnTakeOff()
    if self.data then
        SoulBearstMgr:ReqMythicalEquipUnload(self.data.user, self.data.id)
    end
    self:Close()
end

--强化
function M:OnAdv()
    SoulBearstMgr:SetEquipId(self.data.id)
    self.eOpenAdvView()
    self:Close()
end

--装备
function M:OnPutOn()
    SoulBearstMgr:ReqMythicalEquipLoad(self.data.id)
    self:Close()
end

function M:DisposeCustom()
    self.data = nil
    self.showBtn = nil
    self.compare = nil
    ObjPool.Add(self.putOnTip)
    ObjPool.Add(self.selectTip)
    self.putOnTip = nil
    self.selectTip = nil
end

return M