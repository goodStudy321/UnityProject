UIFamilyEscort = UIBase:New{Name = "UIFamilyEscort"}

local mModelView = require("UI/UIFamilyEscort/UIEscortModelView")
local mQualityView = require("UI/UIFamilyEscort/UIEscortQualityView")
local mRewardView = require("UI/UIFamilyEscort/UIEscortRewardView")
local mRecordView = require("UI/UIFamilyEscort/UIEscortRecordView")
local mRobView = require("UI/UIFamilyEscort/UIEscortRobView")


local M = UIFamilyEscort

M.Escort = 1
M.Rob = 2

function M:InitCustom()
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local F = TransTool.Find
    local S = UITool.SetLsnrSelf
    local trans = self.root

    mModelView:Init(FC(trans, "ModelView"))
    mQualityView:Init(FC(trans, "QualityView"))
    mRewardView:Init(FC(trans, "RewardView"))
    mRecordView:Init(FC(trans, "RecordView"))
    mRobView:Init(FC(trans, "RobView"))

    local btnEscort = F(trans, "BtnEscort")
    local btnRob = F(trans, "BtnRob")
    local btnClose = F(trans, "BtnClose")

    self.mEscortRedPoint = FC(btnEscort, "RedPoint")
    self.mEscortSelect = FC(btnEscort, "Select")
    self.mRobRedPoint = FC(btnRob, "RedPoint")
    self.mRobSelect = FC(btnRob, "Select")


    S(btnEscort, self.OnEscort, self)
    S(btnRob, self.OnRob, self)
    S(btnClose, self.OnClose, self)

    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    mQualityView.eSelectEscort[key](mQualityView.eSelectEscort, self.SelectEscort, self)
    FamilyEscortMgr.eUpdateEscort[key](FamilyEscortMgr.eUpdateEscort, self.UpdateEscort, self)
    FamilyEscortMgr.eUpdateEscortStatus[key](FamilyEscortMgr.eUpdateEscortStatus, self.UpdateEscortStatus, self)
    FamilyEscortMgr.eUpdateEscortLog[key](FamilyEscortMgr.eUpdateEscortLog, self.UpdateEscortLog, self)
    FamilyEscortMgr.eUpdateRobList[key](FamilyEscortMgr.eUpdateRobList, self.UpdateRobList, self)
    FamilyEscortMgr.eRefreshRobsData[key](FamilyEscortMgr.eRefreshRobsData, self.RefreshRobsData, self)
    FamilyEscortMgr.eRefreshEscortRed[key](FamilyEscortMgr.eRefreshEscortRed, self.UpdateEscortRedPoint, self)
    StoreMgr.eBuyResp[key](StoreMgr.eBuyResp, self.BuyResp, self)
    PropMgr.eGetAdd[key](PropMgr.eGetAdd, self.OnAdd, self)
end

function M:OnAdd(action,dic)
    if action == 10399 then
        self.mDic = dic
        UIMgr.Open(UIGetRewardPanel.Name, self.OpenGetRewardCb, self)
    end
end

function M:OpenGetRewardCb(name)
    local ui = UIMgr.Get(name)
	if ui then
		ui:UpdateData(self.mDic)
	end
end


function M:BuyResp(typeId)
    mQualityView:BuyResp(typeId)
end

function M:RefreshRobsData()
    if not mRobView:IsActive() then return end
    mRobView:RefreshRobsData()
end

function M:UpdateRobList(needUpdateData)
    mRobView:UpdateWrapContentIndex()
    if needUpdateData then
        mRobView:UpdateData()
    end
end

function M:UpdateEscortLog(text)
    if mRecordView:IsActive() then
        mRecordView:CreateLog(text)
        mRecordView:UpdateScrollbars()
    end
end

function M:UpdateEscortStatus(id, val)
    if id == 1 then
        mRewardView:UpdateRemainCount()
        self:UpdateEscortRedPoint()
    elseif id == 2 then
        -- self:UpdateRobRemainTime(val)
        mRobView:UpdateRemianCount()
        --self:UpdateRobRedPoint()
    elseif id == 3 then
        mModelView:UpdateProrgress()  
        if mRobView:IsActive() then return end     
        mRewardView:UpdateBtnStatus()   
    elseif id == 4 then
        if mRobView:IsActive() then return end    
        local hasReward = FamilyEscortMgr:GetHasRewardStatus()
        if hasReward == 1 then return end
        mQualityView:Refresh()
    elseif id == 5 then
        if mRobView:IsActive() then return end     
        mRewardView:UpdateTips()
        mRewardView:UpdateCells()
    elseif id == 6 then
        self:UpdateEscortRedPoint()
        mModelView:UpdateProrgress()  
        if mRobView:IsActive() then return end 
        if val == 0 then      
            mQualityView:Open()
            mRecordView:Close()
        end
        mRewardView:UpdateBtnStatus()
    end 
end

function M:UpdateEscort(type)
    if type == 1 or type == 2 then
        mQualityView:Refresh()
        mQualityView:SetAdvFx()
    elseif type == 3 then
        self:QuaSwitchToRecord()
    end
end

function M:QuaSwitchToRecord()
    mQualityView:Close()
    mRecordView:Open()
    local data = FamilyEscortMgr:GetCurEscortData()
    self:SelectEscort(data)
end

function M:SelectEscort(data)
    mModelView:UpdateData(data)
    mRewardView:UpdateData(data)
end


function M:OnEscort()
    self:OpenEscortView()
end

function M:OnRob()
    self:OpenRobView()
end

function M:OnClose()
    self:Close()
    JumpMgr.eOpenJump()
end

function M:UpdateSelect(bool)
    self.mEscortSelect:SetActive(bool)
    self.mRobSelect:SetActive(not bool)
end

--打开护送界面
function M:OpenEscortView()
    if self.mIndex and self.mIndex == M.Escort then return end
    self.mIndex = M.Escort
    self:UpdateSelect(true)
    mRobView:Close()
    mRewardView:Open()
    local isEscorting = FamilyEscortMgr:IsEscorting()
    local hasReward = FamilyEscortMgr:GetHasRewardStatus()
    if isEscorting or hasReward == 1 then
        self:QuaSwitchToRecord()
    else
        mQualityView:Open()
        mRecordView:Close()
    end
end

--打开拦截界面
function M:OpenRobView()
    if self.mIndex and self.mIndex == M.Rob then return end
    self.mIndex = M.Rob
    self:UpdateSelect(false)
    mRecordView:Close()
    mRewardView:Close()
    mQualityView:Close()
    mRobView:Open()
end

function M:UpdateView()
    local escortTime = FamilyEscortMgr:GetEscortRemainTime()
    local robTime = FamilyEscortMgr:GetRobRemainTime()
    local canGetReward = FamilyEscortMgr:GetHasRewardStatus()
    if escortTime > 0 or canGetReward==1 or robTime == 0 then
        self:OpenEscortView()
    else
        self:OpenRobView()
        local data = FamilyEscortMgr:GetCurEscortData()
        mModelView:UpdateData(data)
    end
    self:UpdateEscortRedPoint()
    --self:UpdateRobRedPoint()
end

function M:UpdateEscortRedPoint()
    local escortTime = FamilyEscortMgr:GetEscortRemainTime()
    local canGetReward = FamilyEscortMgr:GetHasRewardStatus()
    local isEscorting = FamilyEscortMgr:IsEscorting()
    if isEscorting then
        self.mEscortRedPoint:SetActive(false)
        FamilyMgr.eRed(false, 1, 3)
    else
        self.mEscortRedPoint:SetActive(escortTime > 0 or canGetReward==1)
        FamilyMgr.eRed(escortTime > 0 or canGetReward==1, 1, 3)
    end
end

function M:UpdateRobRedPoint()
    local robTime = FamilyEscortMgr:GetRobRemainTime()
    self.mRobRedPoint:SetActive(robTime > 0)
end

function M:OpenCustom()
    FamilyEscortMgr:ClearRobsData()
    self:UpdateView()
end

--特殊的打开方式
function M:GetSpecial(t1)
    if CustomInfo:IsJoinFamily() == false then return false end
    if FamilyEscortMgr:GetOpenStatus() == false then UITip.Log("系统未开启") return false end
    return true
end

--打开分页
function M:OpenTabByIdx(t1,t2,t3,t4)
    
end

function M:DisposeCustom()
    self:SetLsnr("Remove")
    mModelView:Dispose()
    mQualityView:Dispose()
    mRewardView:Dispose()
    mRecordView:Dispose()
    mRobView:Dispose()
    self.mIndex = nil
    self.mDic = nil
end

return M