UITitle = UIBase:New{Name = "UITitle"}

require("UI/UITitle/TitleList")
require("UI/UITitle/TitleType")
require("UI/UITitle/TitleDes")
require("UI/UITitle/TitleModel")

local M = UITitle

function M:InitCustom()
    local F = TransTool.Find
    local root = self.root

    UITool.SetLsnrClick(root, "BtnClose", "", self.Close, self)

    self.tlMgr = ObjPool.Get(TitleList)
    self.ttMgr = ObjPool.Get(TitleType)
    self.tdMgr = ObjPool.Get(TitleDes)
    self.modelMgr = ObjPool.Get(TitleModel)
    
    self.tlMgr:Init(F(root,"TitleList"))
    self.tdMgr:Init(F(root,"TitleDes"))
    self.ttMgr:Init(F(root,"TitleType"))
    self.modelMgr:Init(F(root, "Model"))
    -- UITool.SetLiuHaiAnchor(root, "TitleType", root.name)

    self:SetLsnr("Add")

    self:InitView()
end

function M:SetLsnr(key)
    TitleMgr.eUpdate[key](TitleMgr.eUpdate, self.UpdateData, self)
    self.ttMgr.eClickToggle[key](self.ttMgr.eClickToggle, self.ClickToggle, self)
    self.tlMgr.eClickTitle[key](self.tlMgr.eClickTitle, self.ClickTitle, self)
end

function M:InitView()
    -- UITop:SetTitle("称号")
    self.ttMgr:CreateCell(TitleMgr.ToggleGroup)
    self.ttMgr:Open(TitleMgr.Type.Had)
    self.tlMgr:UpdateOwnAttr(TitleMgr.TitleInfo[TitleMgr.Type.Had])
end

function M:ClickToggle(id)
    self.curToggle = id
    local data = TitleMgr.TitleInfo[id]
    self.tlMgr:UpdateCellData(data)
    self.tlMgr:SetShowByIndex(1)
end

function M:ClickTitle(id)
    self.curTitle = id
    local data = TitleMgr:GetTitleInfo(id)
    self.tdMgr:UpdateDes(data)
    self.modelMgr:UpdateModel(data)
end

function M:UpdateData()
    local data = TitleMgr.TitleInfo[self.curToggle]
    self.tlMgr:UpdateCellData(data)
    self.tlMgr:SetShowById(self.curTitle)
    self.tlMgr:UpdateOwnAttr(TitleMgr.TitleInfo[TitleMgr.Type.Had])
end

function M:DisposeCustom()
    self:SetLsnr("Remove")
    ObjPool.Add(self.tlMgr)
    ObjPool.Add(self.ttMgr)
    ObjPool.Add(self.tdMgr)
    ObjPool.Add(self.modelMgr)
    self.tlMgr = nil
    self.ttMgr = nil
    self.tdMgr = nil
    self.modelMgr = nil
    self.curToggle = nil
end

return M