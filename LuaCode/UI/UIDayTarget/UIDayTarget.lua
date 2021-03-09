UIDayTarget = Super:New{Name = "UIDayTarget"}

require("UI/UIDayTarget/UIDTItemView")
require("UI/UIDayTarget/UIDTProgress")
require("UI/UIDayTarget/UIDTModel")

local M = UIDayTarget

M.mToggleDic = {}

M.mTogglesName = {"经验", "坐骑", "套装", "伙伴", "天机印", "战力"}

function M:Init(go)
    local FC = TransTool.FindChild
    local G = ComTool.Get
    local trans = go.transform

    self.mGo = go
    self.mCountDown = G(UILabel, trans, "CountDown")
    self.mGrid = G(UIGrid, trans, "ToggleGroup")
    self.mPrefab = FC(self.mGrid.transform, "Tg")
    self.mPrefab:SetActive(false)
    self.mTips = G(UILabel, trans, "Tips")

    UIDTItemView:Init(FC(trans, "ItemView"))
    UIDTProgress:Init(FC(trans, "TotalProgress"))
    UIDTModel:Init(FC(trans, "Model"))

    self:InitToggle()
    self:InitRedPointState()
    self:InitView()
    self:CreateTimer()
    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    DayTargetMgr.eUpdateDTInfo[key](DayTargetMgr.eUpdateDTInfo, self.UpdateDTInfo, self)
    DayTargetMgr.eUpdateDTPro[key](DayTargetMgr.eUpdateDTPro, self.UpdateDTPro, self)
    DayTargetMgr.eUpdateDTProReward[key](DayTargetMgr.eUpdateDTProReward, self.UpdateDTProReward, self)
    DayTargetMgr.eUpdateRedPoint[key](DayTargetMgr.eUpdateRedPoint, self.UpdateRedPoint, self)
    PropMgr.eGetAdd[key](PropMgr.eGetAdd, self.OnAdd, self)
end

function M:OnAdd(action,dic)
    if action == 10350 or action == 10351 then
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

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:Open()
    self:SetActive(true)
end

function M:Close()
    self:SetActive(false)
end

function M:InitToggle()
    local data = self.mTogglesName
    for i=1,#data do
        local key = tostring(i+1)
        local go = Instantiate(self.mPrefab)
        go.name = key
        TransTool.AddChild(self.mGrid.transform, go.transform)
        local bt = ObjPool.Get(BaseToggle)
        bt.eClick:Add(self.OnTgClick, self)
        bt:Init(go)
        bt:SetName(data[i])
        bt:SetActive(true)
        self.mToggleDic[key] = bt
    end
    self.mGrid:Reposition()
end

function M:InitRedPointState()
    local dic = self.mToggleDic
    for k,v in pairs(dic) do
        local state = DayTargetMgr:GetRedPointStateByDay(k)
        self:UpdateRedPoint(state,k)
    end
end

function M:InitView()
    local day = DayTargetMgr:GetCurDay()
    if day <= 1 then
        self.mTips.gameObject:SetActive(true)
    else
        self.mTips.gameObject:SetActive(false)
        self:OnTgClick(tostring(day))
    end
end

function M:OnTgClick(name)
    local index = name
    local state, day = DayTargetMgr:IsOpen(index)
    if not state then 
        if day then
            UITip.Log(string.format("第%s天开启", day))
        end
        return 
    end
    if self.mIndex then
        if self.mIndex == index then return end
        self.mToggleDic[self.mIndex]:SetHighlight(false)
    end
    self.mIndex = index
    self.mToggleDic[self.mIndex]:SetHighlight(true)
    self:UpdateDTInfo() 
end

function M:UpdateRedPoint(state, day)
    if not day then return end
    local b = DayTargetMgr:IsOpen(day)
    if b then
        self.mToggleDic[day]:SetRedPoint(state)
    end
end

function M:UpdateDTInfo()
    self.mIndex = self.mIndex or "2"
    local data = DayTargetMgr:GetDTDataByDay(self.mIndex)
    UIDTItemView:UpdateData(data)
end

function M:UpdateDTPro()
    UIDTProgress:UpdateSlider()
    UIDTProgress:UpdateCells()
    UIDTModel:UpdateData()
end

function M:UpdateDTProReward()
    UIDTProgress:UpdateCells()
    UIDTModel:UpdateData()
end

function M:CreateTimer()
    local eTime = DayTargetMgr:GetEndTime()
    local seconds = eTime-TimeTool.GetServerTimeNow()*0.001
    if seconds>0 then
        if not self.mTimer then 
            self.mTimer = ObjPool.Get(DateTimer)
            self.mTimer.apdOp = 3
            self.mTimer.seconds = seconds
            self.mTimer.invlCb:Add(self.InvlCb, self)
            self.mTimer.complete:Add(self.CompleteCb, self)
            self.mTimer:Start()
            self:InvlCb()
        end
    end
end

function M:InvlCb()
    self.mCountDown.text = string.format("[F4DDBDFF]活动倒计时：[F39800FF]%s", self.mTimer.remain)
    local day = DayTargetMgr:GetCurDay()
    if day == 1 then
        local sec = TimeTool.GetSeverTimeRemain()
        self.mTips.text = DateTool.FmtSec(sec, 0, 2, true)
    else
        if self.mTips.gameObject.activeSelf then
            self.mTips.gameObject:SetActive(false)
            self:OnTgClick(tostring(day))
        end
    end
end

function M:CompleteCb()
    self.mCountDown.text = "[F39800FF]活动结束"
end


function M:Dispose()
    self.mIndex = nil
    self:SetLsnr("Remove")
    if self.mTimer then
        self.mTimer:AutoToPool()
        self.mTimer = nil
    end
    UIDTItemView:Dispose()
    UIDTProgress:Dispose()
    UIDTModel:Dispose()
    TableTool.ClearDicToPool(self.mToggleDic)
    TableTool.ClearUserData(self)
end

return M