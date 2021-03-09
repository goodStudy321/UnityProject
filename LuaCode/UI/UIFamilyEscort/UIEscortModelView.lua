UIEscortModelView = Super:New{Name = "UIEscortModelView"}

local M = UIEscortModelView

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local F = TransTool.Find
    local FC = TransTool.FindChild

    self.mGo = go
    self.mModelRoot = F(trans, "ModelRoot")
    self.mTips = FC(trans, "Tips")
    self.mCurQuality = G(UILabel, trans, "CurQuality")
    self.mName = G(UILabel, trans, "Name")
    self.mIcon = G(UISprite, trans, "Name/Icon")
    self.mProgress = F(trans, "Progress")
    self.mFill = G(UISprite, self.mProgress, "Fill")
    self.mFx = F(self.mFill.transform, "UI_jdlizi")
    self.mTime = G(UILabel, self.mProgress, "Time")
    self.mFinish = FC(self.mProgress, "Finsh")

    self.mWidth = self.mFill.width

    self.mGbjPool = ObjPool.Get(MyGbjPool)
end

function M:UpdateData(mData)
    if not mData then return end
    self.mData = mData
    self:UpdateName()
    self:UpdateProrgress()
    self:UpdateTips()
    self:UpdateModel()
    self:UpdateQuality()
    self:UpdateIcon()
end

function M:UpdateIcon()
    self.mIcon.spriteName = self.mData.Quality
end

function M:UpdateFill(value)
    self.mFill.fillAmountValue = value
    self.mFx.gameObject:SetActive(value < 1)
    self.mFx.localPosition = Vector3(self.mWidth*value, 0, 0)
end

function M:UpdateName()
    self.mName.text = self.mData.Name
end

function M:UpdateProrgress()
    local isEscorting = FamilyEscortMgr:IsEscorting()
    local hasReward = FamilyEscortMgr:GetHasRewardStatus()
    self.mProgress.gameObject:SetActive(isEscorting or hasReward == 1)
    if isEscorting then
        self.mTime.gameObject:SetActive(true)
        self.mFinish:SetActive(false)
        if not self.mTimer then 
            self.mTimer = ObjPool.Get(DateTimer)
            self.mTimer.fmtOp = 3
            self.mTimer.apdOp = 2
            self.mTimer.invlCb:Add(self.InvlCb, self)
            self.mTimer.complete:Add(self.CompleteCb, self)
        end
        self.mTimer.seconds = FamilyEscortMgr:GetEscortEndTime()
        self.mTimer:Stop()
        self.mTimer:Start()
        self:InvlCb()
    elseif hasReward == 1 then
         self:CompleteCb()
    else
        if self.mTimer then
            self.mTimer:Stop()
        end
    end
end

function M:InvlCb()
    if self.mTime then
        self.mTime.text = self.mTimer.remain
    end
    local sec = self.mTimer:GetRestTime()
    self:UpdateFill(1 - sec/self.mData.Seconds)
end

function M:CompleteCb()
    if self.mTime then
        self.mTime.gameObject:SetActive(false)
        self.mFinish:SetActive(true)
    end
    self:UpdateFill(1)
end

function M:UpdateTips()
    local maxQua = FamilyEscortMgr:GetEscortMaxQua()
    self.mTips:SetActive(self.mData.Quality == maxQua)
end

function M:UpdateModel()
    if self.mCurModel and self.mCurModel.name == self.mData.Prefab then return end
    local go = self.mGbjPool:Get(self.mData.Prefab)
    if go then
        self:LoadModelCb(go)
    else
        Loong.Game.AssetMgr.LoadPrefab(self.mData.Prefab, GbjHandler(self.LoadModelCb,self))
    end
end

function M:LoadModelCb(go)
    if not LuaTool.IsNull(self.mModelRoot) then
        self.mGbjPool:Add(self.mCurModel)
        self.mCurModel = go
        go.transform:SetParent(self.mModelRoot)
        go.transform.localPosition = Vector3(0,0,0)
        go.transform.localScale = Vector3(360, 360, 360)
        go.transform.localRotation = Quaternion.Euler(0,130,0)
    else
        self:Unload(go)
    end
end

function M:Unload(go)
    if LuaTool.IsNull(go) then return end
    AssetMgr:Unload(go.name,".prefab", false)
    GameObject.DestroyImmediate(go)
end


function M:UpdateQuality()
    local curEscortId = FamilyEscortMgr:GetCurEscortId()
    self.mCurQuality.gameObject:SetActive(self.mData.Id == curEscortId)
end

function M:Dispose()
    self.mData = nil
    self.mCurModel = nil
    ObjPool.Add(self.mGbjPool)
    self.mGbjPool = nil
    if self.mTimer then
        self.mTimer:AutoToPool()
        self.mTimer = nil
    end
    TableTool.ClearUserData(self)
end

return M