UIFashionPanel = UIBase:New{Name = "UIFashionPanel"}

require("UI/UIFashion/FashionList")
require("UI/UIFashion/FashionType")
require("UI/UIFashion/FashionAttr")
require("UI/UIFashion/FashionModel")
require("UI/UIFashion/FashionEssence")
require("UI/UIFashion/FashionSuit")
require("UI/UIFashion/SuitPart")
require("UI/UIFashion/CoupleSuitPart")
require("UI/UIFashion/SuitSkillTip")

local M = UIFashionPanel

function M:InitCustom()
    local F = TransTool.Find
    local FC = TransTool.FindChild
    local SC = UITool.SetLsnrClick
    local root = self.root

    self.fashionList = ObjPool.Get(FashionList)
    self.fashionType = ObjPool.Get(FashionType)
    self.fashionAttr = ObjPool.Get(FashionAttr)
    self.fashionModel = ObjPool.Get(FashionModel)
    self.fashionEssence = ObjPool.Get(FashionEssence)
    self.fashionSuit = ObjPool.Get(FashionSuit)
    self.suitPart = ObjPool.Get(SuitPart)
    self.coupleSuitPart = ObjPool.Get(CoupleSuitPart);
    self.skillTip = SuitSkillTip;

    self.fashionList:Init(F(root, "FashionList"))
    self.fashionType:Init(F(root, "FashionType"))
    self.fashionAttr:Init(F(root, "FashionAttr"))
    self.fashionModel:Init(F(root, "Model"))
    self.fashionEssence:Init(F(root, "FashionEssence"))
    self.fashionSuit:Init(F(root, "SuitList"))
    self.suitPart:Init(F(root, "PartList"))
    self.coupleSuitPart:Init(F(root, "CoupleSuit"))
    self.skillTip:Init(F(root,"skiTip"))


    self.essenceRedPoint = FC(root, "BtnEssence/RedPoint")
    self.suitRedPoint = FC(root, "FashionAttr/BtnSuit/RedPoint")

    SC(root, "BtnEssence", "", self.OnEssence, self)
    SC(root, "BtnBack", "", self.Close, self)
    SC(root, "FashionAttr/BtnSuit", "", self.OnSuit, self)
    SC(root,"SuitList/BtnBackFashion",root.name,self.BackFashion,self)


    UITool.SetLiuHaiAnchor(root, "FashionType", root.name, true)
    UITool.SetLiuHaiAnchor(root, "SuitList", root.name, true)

    self:SetLsnr("Add")
    if not self._type or self._type ~= 0 then
        self:ClickToggle(self._type or 1)
    else
        self:OnSuit()
    end
    self:UpdateSuitRedPoint()
end

function M:SetLsnr(key)
    local m = FashionMgr
    m.eUpdateInfo[key](m.eUpdateInfo, self.UpdateInfo, self)
    m.eChgFashion[key](m.eChgFashion, self.ChgFashion, self)
    m.eDecompose[key](m.eDecompose, self.Decompose, self)
    m.eUpdateRedPoint[key](m.eUpdateRedPoint, self.UpdateRedPoint, self)
    m.eUpdateSuit[key](m.eUpdateSuit, self.UpdateSuit, self)
    FashionType.eClickToggle[key](FashionType.eClickToggle, self.ClickToggle, self)
    FashionList.eClickFashion[key](FashionList.eClickFashion, self.ClickFashion, self)
    SuitCell.eClick[key](SuitCell.eClick, self.OnClickSuit, self)
    SuitPart.eClickCouple[key](SuitPart.eClickCouple,self.OnClickCouple,self)
    CoupleSuitPart.eBackMySuit[key](CoupleSuitPart.eBackMySuit,self.OnBackMySuit,self)
    ScreenMgr.eChange[key](ScreenMgr.eChange, self.ScrChg, self)
end

--屏幕发生旋转
function M:ScrChg(orient)
	if orient == ScreenOrient.Left then
        UITool.SetLiuHaiAnchor(self.root, "SuitList", nil, true)
        UITool.SetLiuHaiAnchor(self.root, "FashionType", nil, true)
	elseif orient == ScreenOrient.Right then
        UITool.SetLiuHaiAnchor(self.root, "SuitList", nil, true, true)
        UITool.SetLiuHaiAnchor(self.root, "FashionType", nil, true, true)
	end
end

function M:UpdateSuitRedPoint()
    local state = FashionMgr:GetTogRedPointState(0)
    self.suitRedPoint:SetActive(state)
end

function M:UpdateSuit()
    local isAct = self.fashionSuit:IsActive()
    if isAct ~= true then
        return
    end
    self.fashionSuit:Refresh()
    self.suitPart:Refresh()
end

function M:UpdateRedPoint()
    self.fashionAttr:UpdateData(self.baseId)
    self.fashionType:UpdateRedPoint()
    if self._type and self._type ~= 0 then
        self.fashionList:UpdateData(self._type)      
    end
    self.fashionSuit:UpdateRedPoint()
    self:UpdateEssenceRedPoint()
    self:UpdateSuitRedPoint()
end

function M:UpdateEssenceRedPoint()
    local state = FashionMgr:GetEssRedPointState(self._type)
    self.essenceRedPoint:SetActive(state)
end

--更新时装信息
function M:UpdateInfo()
    self.fashionList:UpdateData(self._type)
    self.fashionAttr:UpdateData(self.baseId)
end

--更换时装
function M:ChgFashion()
    self.fashionModel:UpdateModel(self._type, self.baseId)
end

--分解精华
function M:Decompose()
    self.fashionEssence:UpdateData(self._type, self.baseId)
    self.fashionAttr:UpdateData(self.baseId)
end

function M:ClickToggle(_type)
    self._type = _type
    self:UpdateEssenceRedPoint()
    self.fashionList:SetActive(true)
    self.fashionAttr:SetActive(true)
    self.fashionSuit:SetActive(false)
    self.suitPart:SetActive(false)
    self.coupleSuitPart:SetActive(false)
    self.skillTip:SetActive(false)
    self.fashionList:UpdateData(_type)
    self.fashionList:SetShow(self.baseId)
    -- self.fashionList:ResetScrollView() 
end

function M:ClickFashion(baseId)
    self.baseId = baseId
    self.fashionAttr:UpdateData(baseId)
end

function M:OnEssence()
    local data = FashionMgr:GetFashionData(self.baseId);
    if data == nil then
        return;
    end
    self.fashionEssence:Open(self._type, self.baseId)
end

function M:OnSuit()
    local state = self.fashionSuit:IsActive()
    if state then return end
    self.fashionSuit:SetActive(not state)
    self.fashionList:SetActive(state)
    self.fashionAttr:SetActive(state)
    self.fashionType:SetActive(state)
    --self.suitPart:SetActive(false)
end

function M:BackFashion()
    local type = self._type;
    if type == nil or type == 0 then
        type = 1;
    end
    self:ClickToggle(self._type);
    self.fashionType:SetActive(true)
end

function M:OnClickSuit(data)
    --self.fashionSuit:SetActive(false)
    self.coupleSuitPart:Close();
    self.suitPart:Open(data)
    self.fashionModel:SetSuitModel(data.fashionList)
end

function M:OnClickCouple(data)
    self.suitPart:Close();
    self.coupleSuitPart:Open(data);
end

function M:OnBackMySuit()
    self.coupleSuitPart:Close();
    self.suitPart:SetActive(true);
end

--打开时装类型
function M:Show(_type, uid)
    if self.active == 1 then
        return
    end
    self._type = _type  
    if _type ~= 0 then
        if uid then
            self.baseId = math.modf(uid/100) 
        else
            local data = FashionMgr:GetFashionInfo(_type)
            for i=1,#data do
                if data[i].isUse then
                    self.baseId = data[i].baseId
                    break
                end
            end
        end 
    end
    UIMgr.Open(self.Name)
end

function M:ShowRPFashion()
    local len = #FashionMgr.FashionType
    for i=1,len do
        local list = FashionMgr:GetFashionInfo(i)
        if list then
            for j=1, #list do
                local unit = list[j]
                local state = FashionMgr:GetRedPointState(unit.type, unit.baseId)
                if state then
                    self:Show(unit.type, unit.uid)
                    return 
                end
            end
            local state = FashionMgr:GetRedPointState(i, 1)
            if state then
                self:Show(i)
                return
            end
        end
    end
    self:Show(0)
end

function M:DisposeCustom()
    self:SetLsnr("Remove")
    ObjPool.Add(self.fashionList)
    ObjPool.Add(self.fashionType)
    ObjPool.Add(self.fashionAttr)
    ObjPool.Add(self.fashionModel)
    ObjPool.Add(self.fashionEssence)
    ObjPool.Add(self.fashionSuit)
    ObjPool.Add(self.suitPart)
    ObjPool.Add(self.coupleSuitPart)
    self.fashionList = nil
    self.fashionType = nil
    self.fashionAttr = nil
    self.fashionModel = nil
    self.fashionEssence = nil
    self.fashionSuit = nil
    self.suitPart = nil
    self.coupleSuitPart = nil
    self.skillTip = nil;
    self.baseId = nil
    self._type = nil
end

return M