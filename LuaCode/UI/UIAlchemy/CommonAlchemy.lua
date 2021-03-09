CommonAlchemy = UILoadBase:New {Name = "CommonAlchemy"}

require("UI/UIAlchemy/AlchemyMaterialBag")

local M = CommonAlchemy

M.mCells = {}

function M:Init()
    local trans = self.GbjRoot.transform
    local G = ComTool.Get
    local F = TransTool.Find
    local FC = TransTool.FindChild
    local S = UITool.SetLsnrSelf

    self.mGo = trans.gameObject

    self.mCount = G(UILabel, trans, "Count")
    self.mPro = G(UILabel, trans, "Progress")

    self.mBtnGive = F(trans, "BtnGive")
    self.mGiveRedPoint = FC(self.mBtnGive, "RedPoint")

    self.mBtnHelp = FC(trans, "BtnHelp")

    self.mBtnMake = F(trans, "BtnMake")
    self.mMakeRedPoint = FC(self.mBtnMake, "RedPoint")

    self.mFxJD =  FC(trans, "Group_jd")
    self.mOrbAnimator = G(guiraffe.SubstanceOrb.OrbAnimator, self.mFxJD.transform, "Group_jd/FX_SubstancePlane")

    self.mGird = G(UIGrid, trans, "Container/ScrollView/Grid")

   

    S(self.mBtnGive, self.OnGive, self)
    S(self.mBtnMake, self.OnMake, self)
    S(self.mBtnHelp, self.OnHelp, self)

    AlchemyMaterialBag:Init(FC(trans, "MaterialBag"))

    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    AlchemyMgr.eUpdateTimes[key](AlchemyMgr.eUpdateTimes, self.UpdateTimes, self)
    AlchemyMgr.eUpdatePro[key](AlchemyMgr.eUpdatePro, self.UpdatePro, self)
    AlchemyMgr.eUpdateRedPoint[key](AlchemyMgr.eUpdateRedPoint, self.UpdateRedPoint, self)
    AlchemyMgr.eUpdateCommonMaterialBag[key](AlchemyMgr.eUpdateCommonMaterialBag, self.UpdateCommonMaterialBag, self)
    PropMgr.eGetAdd[key](PropMgr.eGetAdd, self.GetAdd, self)
end

function M:OnHelp()
    local cfg = InvestDesCfg["1905"]
    if not cfg then return end
    UIComTips:Show(cfg.des, Vector3(-294, 220, 0))
end


function M:UpdateCommonMaterialBag()
    if AlchemyMaterialBag:IsActive() then
        AlchemyMaterialBag:UpdateData()
    end
end

function M:UpdateRedPoint(type, state)
    if type ~= FestivalActMgr.CommonAlchemy then return end
    self:UpdateGiveRedPoint()
end

function M:GetAdd(action, list)
    if action == 40416 then
        self.mList = list
        UIMgr.Open(UIGetRewardPanel.Name, self.OpenGetRewardCb, self)
    end
end

function M:OpenGetRewardCb(name)
    local ui = UIMgr.Get(name)
    if ui then
		ui:UpdateData(self.mList)
	end
end

function M:OnGive()
    AlchemyMaterialBag:Open()
end

function M:OnMake()
    AlchemyMgr:ReqRoleBgAlchemyDraw(1, 2)
end

function M:InitData()
    local data = AlchemyMgr:GetCommonAlchemyData()
    if not data then return end
    self.mData = data
    self:InitCells()
end

function M:InitCells()
    local data = self.mData.CommonList
    local list = self.mCells
    for i=1,#data do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.mGird.transform)
        cell:UpData(data[i].ID, data[i].Num)
        table.insert(list, cell)
    end
end

function M:UpdateData()
    if not self.mData then return end
    self:UpdateGiveRedPoint()
    self:UpdateMakeRedPoint()
    self:UpdateCount()
    self:UpdatePro()
end

function M:UpdateTimes()
    self:UpdateCount()
    self:UpdateMakeRedPoint()
end

function M:UpdatePro()
    self.mOrbAnimator.FillRate = self.mData.CurProgress/AlchemyMgr.OnceNeed
    self.mPro.text = string.format("%s/%s", self.mData.CurProgress, AlchemyMgr.OnceNeed)
end

function M:UpdateCount()
    self.mCount.text = string.format("当前可炼丹:%s", self.mData.RemainCount)
end

function M:UpdateGiveRedPoint()
    local state = AlchemyMgr:GetCommonAlchemyMaterialStatus()
    self.mGiveRedPoint:SetActive(state)
end

function M:UpdateMakeRedPoint()
    self.mMakeRedPoint:SetActive(self.mData.RemainCount > 0)
end

function M:Open()
    -- self:SetActive(true)
    if not self.mHasInit then
        self.mHasInit = true
        self:InitData()
    end
    self:UpdateData()
end

function M:CloseC()
    -- self:SetActive(false)
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:IsActive()
    return self.mGo.activeSelf
end

function M:Dispose()
    self:SetLsnr("Remove")
    self.mData = nil
    self.mHasInit = false
    TableTool.ClearListToPool(self.mCells)
    -- TableTool.ClearUserData(self)
    AlchemyMaterialBag:Dispose()
end

return M