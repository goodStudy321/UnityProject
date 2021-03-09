UISoulBearst = UIBase:New{Name = "UISoulBearst"}

require("UI/UISoulBearst/UISBMainView")
require("UI/UISoulBearst/MvBearstCell")
require("UI/UISoulBearst/MvSBCell")
require("UI/UISoulBearst/SBCell")
require("UI/UISoulBearst/UISBAdvView")

local M = UISoulBearst

--1:mainview
--2:advView
--3:compView

M.ToggleList = {}

M.TuJian = 1  --图鉴
M.ShenShou = 2  --神兽页


function M:InitCustom()
    local trans = self.root 
    local FC = TransTool.FindChild
    local SC = UITool.SetLsnrClick
    local G = ComTool.Get

    self.mainView = ObjPool.Get(UISBMainView)
    self.mainView:Init(FC(trans, "MainView"))

    self.advView = ObjPool.Get(UISBAdvView)
    self.advView:Init(FC(trans, "AdvView"))

    self.btnAdv = ObjPool.Get(BaseToggle)
    self.btnAdv:Init( FC(trans, "BtnAdv"))
    self.btnAdv.eClick:Add(self.OnAdv, self)


    self.btnComp = ObjPool.Get(BaseToggle)
    self.btnComp:Init( FC(trans, "BtnComp"))
    self.btnComp.eClick:Add(self.OnComp, self)

    self.grid = G(UIGrid,trans,  "ToggleGroup")
    self.prefab = FC(self.grid.transform, "Toggle")

    
    self:AddToggle("图鉴", self.TuJian)
    self:AddToggle("兽魂", self.ShenShou)

    SC(trans, "BtnClose", self.Name, self.OnClose, self)
    self:OnTgClick(self.page or self.ShenShou)
    self:UpdateRedPoint()
    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    local mgr = SoulBearstMgr
    mgr.eUpdateSBInfo[key](mgr.eUpdateSBInfo, self.UpdateSBInfo, self)
    mgr.eUpdateBagInfo[key](mgr.eUpdateBagInfo, self.UpdateBagInfo, self)
    mgr.eUpdateSBNum[key](mgr.eUpdateSBNum, self.UpdateSBNum, self)
    mgr.eUpdateSBList[key](mgr.eUpdateSBList, self.UpdateSBList, self)
    mgr.eUpdateSBAct[key](mgr.eUpdateSBAct, self.UpdateSBAct, self)
    mgr.eChangeDoubleAdv[key](mgr.eChangeDoubleAdv, self.ChangeDoubleAdv, self)
    mgr.eUpdateUnLockSB[key](mgr.eUpdateUnLockSB, self.UpdateUnLockSB, self)
    mgr.ePlayFx[key](mgr.ePlayFx, self.PlayFx, self)
    mgr.eUpdateRedPoint[key](mgr.eUpdateRedPoint, self.UpdateRedPoint, self)
    UISBEquipTip.eOpenAdvView[key](UISBEquipTip.eOpenAdvView, self.OpenAdvView1, self)
    UISBMainView.eOpenAdvView[key](UISBMainView.eOpenAdvView, self.OpenAdvView2, self)
    PicCollectMgr.ePicRed[key](PicCollectMgr.ePicRed, self.UpdateRedPoint, self)
end

function M:UpdateRedPoint()
    local list = self.ToggleList
    if #list < 2 then return end
    list[self.ShenShou]:SetRedPoint(SystemMgr:GetSystemIndex(4, 2))
    list[self.TuJian]:SetRedPoint(SystemMgr:GetSystemIndex(4, 1))
end

function M:AddToggle(name, index)
    local go = Instantiate(self.prefab)
    go.name = index
    TransTool.AddChild(self.grid.transform, go.transform)
    local bt = ObjPool.Get(BaseToggle)
    bt.eClick:Add(self.OnTgClick, self)
    bt:Init(go)
    bt:SetName(name)
    bt:SetActive(true)
    table.insert(self.ToggleList, bt)
end

function M:OnTgClick(name)
    local index = tonumber(name)
    if self.curIndex and self.curIndex == index then return end
    self.curIndex = index
    if index == self.ShenShou then
        self:OpenMainView()
    elseif index == self.TuJian then
        --UITip.Log("打开图鉴系统")
        UIMgr.Open(UIPicCollect.Name)
    end
    self:UpdateTgState(index)
end

--UISoulBearst:Show()  直接打开对应的标签页
function M:Show(page)
    self.page = page
    UIMgr.Open(self.Name)
end

function M:OpenTabByIdx()
end


function M:UpdateTgState(index)
    local list = self.ToggleList
    for i=1,#list do
        list[i]:SetHighlight(i==index)
    end
end

function M:PlayFx()
    self.mainView:PlayFx()
end

function M:UpdateUnLockSB()
    self.mainView:UpdateUnLockSB()
end

function M:ChangeDoubleAdv()
    self.advView:ChangeDoubleAdv()
end

function M:OpenAdvView2()
    local data = SoulBearstMgr:GetActiveSBinfo()
    if #data > 0 then
        self:SetBtnState(true)
        self:SetBtnHL(true)
        self:OpenView(2)
    else
        UITip.Log("已激活神兽的装备才可以强化")
    end
end

function M:OpenAdvView1()
    local state = SoulBearstMgr:CanOpenAdv()
    if state then
        self:SetBtnState(true)
        self:SetBtnHL(true)
        self:OpenView(2)
    else
        UITip.Log("已激活神兽的装备才可以强化")
    end
end

function M:UpdateSBAct()
    self.mainView:UpdateSBAct()
end

function M:UpdateSBList()
    self.mainView:RefreshBearst()
end

function M:UpdateSBInfo()
    if self.mainView:IsActive() then
        self.mainView:Refresh()
    end
    if self.advView:IsActive() then
        self.advView:Refresh()
    end
end

function M:UpdateBagInfo()
    if self.mainView:IsActive() then
        self.mainView:RefreshBag()
    end
    if self.advView:IsActive() then
        self.advView:RefreshBag()
    end
end

function M:UpdateSBNum()
    self.mainView:UpdateSBNum()
end


function M:OpenMainView()
    self:SetBtnState(false)
    self:OpenView(1)
end

function M:OpenView(index)
    if self.index and self.index == index then return end
    self.index = index
    if self.curView then
        self.curView:Close()
    end
    self.curView = nil
    if index == 1 then
        self.curView = self.mainView
    elseif index == 2 then
        self.curView = self.advView
    elseif index == 3 then
        --todo
    end

    if self.curView then
        self.curView:Open()
    end
end

function M:SetBtnState(state)
    self.btnAdv:SetActive(state)
    self.btnComp:SetActive(state)
    self.grid.gameObject:SetActive(not state)
end

function M:SetBtnHL(state)
    self.btnAdv:SetHighlight(state)
    self.btnComp:SetHighlight(not state)
end

function M:OnAdv()
    self:OpenAdvView2()
end

function M:OnComp()
    UITip.Log("暂未开放！")
    return
  --  self:SetBtnState(true)
   -- self:SetBtnHL(false)
    --self:OpenView(3)
end

function M:OnClose()
    if self.mainView:IsActive() then
        self:Close()    
    else
        self:OpenMainView()
    end
end

function M:Clear()
    SoulBearstMgr:ClearData()
end

function M:OpenTabByIdx(t1,t2,t3,t4)

end

function M:DisposeCustom()
    self:SetLsnr("Remove")
    ObjPool.Add(self.mainView)
    ObjPool.Add(self.btnAdv)
    ObjPool.Add(self.btnComp)
    ObjPool.Add(self.advView)
    TableTool.ClearDicToPool(self.ToggleList)
    self.mainView = nil
    self.btnAdv = nil
    self.btnComp = nil
    self.advView = nil
    self.curView = nil
    self.index = nil
    self.curIndex = nil
    self.page = nil
end

return M