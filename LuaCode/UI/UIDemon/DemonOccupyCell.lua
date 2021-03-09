DemonOccupyCell = Super:New{Name = "DemonOccupyCell"}

local M  = DemonOccupyCell

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local S = UITool.SetLsnrSelf

    self.mGo = go
    self.mIcon = G(UISprite, trans, "Icon")
    self.mCurHp = G(UISprite, trans, "CurHp")
    self.mBtnAttack = FC(trans, "BtnAttack")
    self.mRank = G(UILabel, trans, "Rank")
    self.mName = G(UILabel, trans, "Name")
    self.mTime = G(UILabel, trans, "Time")
    self.mFxFj = FC(trans, "UI_fj")
    self.mFxSj = FC(trans, "UI_sJ")

    self:LoadFxSj()
    self:LoadFxFj()

    S(self.mBtnAttack, self.OnAttack, self)
    S(self.mFxFj, self.OnFangji, self)
end

function M:LoadFxSj()
    Loong.Game.AssetMgr.LoadPrefab("UI_sJ", GbjHandler(self.LoadSjCb,self))
end

function M:LoadSjCb(go)
    if self.mFxSj then
        self.mSj = go
        go.transform:SetParent(self.mFxSj.transform)
        go.transform.localPosition = Vector3.zero
        go.transform.localScale = Vector3.one
        go:SetActive(true)
    else
        self:UnloadFx(go)
    end
end

function M:LoadFxFj()
    Loong.Game.AssetMgr.LoadPrefab("UI_fj", GbjHandler(self.LoadFjCb,self))
end

function M:LoadFjCb(go)
    if self.mFxFj then
        self.mFj = go
        go.transform:SetParent(self.mFxFj.transform)
        go.transform.localPosition = Vector3.zero
        go.transform.localScale = Vector3.one
        go:SetActive(true)
    else
        self:UnloadFx(go)
    end
end

function M:OnAttack()
    if not self.data then return end
    if User.MapData.FightType ~= FightStatus.AllMode and DemonMgr:IsTeamOrFamily(self.data.RoleId) then
        MsgBox.ShowYesNo("是否对你的盟友进行攻击，确认后将自动切换至全体模式！", self.YesCb, self)
    else
        self:FightTarget()
    end
end

function M:YesCb()
    NetFightInfo.RequestChangeFightMode(FightStatus.AllMode)
    User.MapData.FightType = FightStatus.AllMode
    self:FightTarget()
end

function M:FightTarget()
    SelectRoleMgr.instance:StartNavPath(self.data.RoleId, 1)
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:IsActive()
    return self.mGo.activeSelf
end

function M:UpdateData(data)
    if not data then return end
    self.data = data
    self:UpdateName()
    self:UpdateIcon()
    self:UpdateHp()
    self:UpdateRank()
    self:UpdateTime()
    self:UpdateCellState()
end


function M:OnFangji()
    self:OnAttack()
end


function M:UpdateCellState()
    local atk = AtkInfoMgr.atkList[tostring(self.data.RoleId)]
    if UIDemonInfo.FTtarget == self.data.RoleId and atk then  --我和该玩家互撸
        self:SelectBtn(true, false, false)
        self:UpdateName(true)
        -- 名字变红
    elseif UIDemonInfo.FTtarget == self.data.RoleId then  --我在攻击他
        self:SelectBtn(true, false, false)
        self:UpdateName(false)
    elseif atk then  --该玩家正在攻击我
        self:SelectBtn(false, true, false)
         -- 名字变红
         self:UpdateName(true)
    else   --和平
        self:SelectBtn(false, false, true)
        self:UpdateName(false)
        --名字 绿或 白
    end
end

function M:SelectBtn(b1, b2, b3) 
    self.mFxSj:SetActive(b1)
    self.mFxFj:SetActive(b2)
    self:UpdateBtn(b3)  --显示攻击按钮
end


function M:UnloadFx(go)
    AssetMgr:Unload(go.name, ".prefab", false)
    GameObject.DestroyImmediate(go)
end


function M:UpdateBtn(bool)
    if bool then
        local curHp = DemonMgr:GetUnitHp(self.data.RoleId)
        local state = curHp<=0 or self.data.RoleId == UIMisc.LongToNum(User.MapData.UID)
        self.mBtnAttack:SetActive(not state)
    else
        self.mBtnAttack:SetActive(false)
    end
end

--state:true 被攻击
function M:UpdateName(state)
    local color = "[C8D0E3FF]"
    if state then
        color = "[F21919FF]"
    else
        if AtkInfoMgr.atkList[tostring(self.data.RoleId)] then 
            color = "[F21919FF]"
        else
            if DemonMgr:IsTeamOrFamily(self.data.RoleId)
            or (UIDemonInfo.Belonger == self.data.RoleId and self.data.RoleId == UIMisc.LongToNum(User.MapData.UID))
            then
                color = "[00FF00FF]"
            end
        end
    end 
    self.mName.text = string.format("%s%s", color, self.data.Name)
end

function M:UpdateIcon()
    self.mIcon.spriteName = self.data.Sex == 1 and "TX_02" or "TX_01"
end

function M:UpdateHp()
    local curHp, maxHp = DemonMgr:GetUnitHp(self.data.RoleId)  
    if curHp == 0 then
        self.mCurHp.fillAmountValue = 0
        self.mBtnAttack:SetActive(false)
        self.mFxSj:SetActive(false)
        self.mFxFj:SetActive(false)
    else
        self.mCurHp.fillAmountValue = curHp/maxHp
        self:UpdateCellState()
    end
end

function M:UpdateRank()
    self.mRank.text = self.data.Rank
end

function M:UpdateTime()  
    self.mTime.text = DateTool.FmtSec(self.data.OccupyTime, 0, 1)
end

function M:Dispose()
    self.data = nil
    if self.mFj then
        self:UnloadFx(self.mFj)
        self.mFj = nil
    end
    if self.mSj then
        self:UnloadFx(self.mSj)
        self.mSj = nil
    end
    TableTool.ClearUserData(self)
end

return M