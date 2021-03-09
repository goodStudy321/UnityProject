BestAlchemy = Super:New {Name = "BestAlchemy"}

require("UI/UIAlchemy/AlchemyTempBag")

local M = BestAlchemy

M.mImmortalCells = {}
M.mBestCells = {}
M.mCommonCells = {}

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local F = TransTool.Find
    local FC = TransTool.FindChild
    local S = UITool.SetLsnrSelf

    self.mGo = go

    self.mGold = G(UILabel, trans, "Gold")
    self.mMaterial = G(UILabel, trans, "Material")
    self.mbtnAdd = FC(self.mMaterial.transform, "BtnAdd")

    self.mBtnBag = F(trans, "BtnBag")
    self.mBagRedPoint = FC(self.mBtnBag, "RedPoint")

    self.mBtnOne = F(trans, "BtnOne")
    self.mBtnOneName = G(UILabel, self.mBtnOne, "Name")
    self.mBtnOnePrice = G(UILabel, self.mBtnOne, "Price")
    self.mOneRedPoint = FC(self.mBtnOne, "RedPoint")

    self.mBtnTen = F(trans, "BtnTen")
    self.mBtnTenName = G(UILabel, self.mBtnTen, "Name")
    self.mBtnTenPrice = G(UILabel, self.mBtnTen, "Price")
    self.mTenRedPoint = FC(self.mBtnTen, "RedPoint")

    self.mImmortalGrid = G(UIGrid, trans, "Immortal/ScrollView/Grid")
    self.mCommonGrid = G(UIGrid, trans, "Common/ScrollView/Grid")
    self.mBestGrid = G(UIGrid, trans, "Best/ScrollView/Grid")

    self.mRemainTime = G(UILabel, trans, "RemainTime")
    self.mTips = G(UILabel, trans, "Tips")

    self.mFxJiHuo = FC(trans, "Group_jihuo")

    AlchemyTempBag:Init(FC(trans, "TempBag"))

    S(self.mBtnBag, self.OnBag, self)
    S(self.mBtnOne, self.OnOne, self)
    S(self.mBtnTen, self.OnTen, self)
    S(self.mbtnAdd, self.OnAdd, self)

    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    PropMgr.eGetAdd[key](PropMgr.eGetAdd, self.GetAdd, self)
    AlchemyMgr.eAlchemySuccess[key](AlchemyMgr.eAlchemySuccess, self.AlchemySuccess, self)
    AlchemyMgr.eUpdateRedPoint[key](AlchemyMgr.eUpdateRedPoint, self.UpdateRedPoint, self)
    RoleAssets.eUpAsset[key](RoleAssets.eUpAsset, self.UpdateGold, self)
    AlchemyMgr.eUpdateBestTempBag[key](AlchemyMgr.eUpdateBestTempBag, self.UpdateBestTempBag, self)
end

function M:UpdateBestTempBag()
    if AlchemyTempBag:IsActive() then
        AlchemyTempBag:UpdateData()
    end
end

function M:UpdateRedPoint(type, state)
    if type ~= FestivalActMgr.BestAlchemy then return end
    self:UpdateBagRedPoint()
    self:UpdateOneRedPoint()
    self:UpdateTenRedPoint()
    self:UpdateMaterial()
end

function M:AlchemySuccess(type)
    if type ~= 1 then return end    
    self:PlayFx()
end

function M:GetAdd(action, list)
    if action == 40415 then
        if not self.mList then
            self.mList = {}
        else
            TableTool.ClearDic(self.mList)
        end
        for i=1,#list do
            local temp = {}
            temp.k = list[i].k
            temp.v = list[i].v
            temp.b = list[i].b
            table.insert(self.mList, temp)
        end
        self:OpenGetReward()
    end
end

function M:OpenGetReward()
    self.mIsOpenningReward = true
    if not self.mDelayTimer then
        self.mDelayTimer = ObjPool.Get(iTimer)
        self.mDelayTimer.seconds = 0.8
        self.mDelayTimer.complete:Add(self.DelayComplete, self)
    end
    self.mDelayTimer:Stop()
    self.mDelayTimer:Start()
end

function M:DelayComplete()
    UIMgr.Open(UIGetRewardPanel.Name, self.OpenGetRewardCb, self)
end

function M:OpenGetRewardCb(name)
    self.mIsOpenningReward = false
    local ui = UIMgr.Get(name)
    if ui then
		ui:UpdateData(self.mList)
	end
end

function M:OnAdd()
    if not self.mbtnAdd then return end
    PropTip.pos = self.mbtnAdd.transform.position
    UIMgr.Open(PropTip.Name, self.OpenPropTipCb, self)
end

function M:OpenPropTipCb(name)
    if not self.mData then return end
    local ui = UIMgr.Get(name)
    if ui then 
        ui:UpData(self.mData.MaterialId)	
        ui:ShowBtn({"GetWay"})	
    end
end

function M:OnBag()
    AlchemyTempBag:Open()
end

function M:PlayFx()
    self.mFxJiHuo:SetActive(false)
    self.mFxJiHuo:SetActive(true)
end

function M:OnOne()
    if self.mIsOpenningReward then return end   
    if self.mData.MaterialCount > 0 or RoleAssets.IsEnoughAsset(2, self.mData.OnceGold) then
        AlchemyMgr:ReqRoleBgAlchemyDraw(1, 1)
    else
        self:ShowMsgBox()
    end
end

function M:ShowMsgBox()
    MsgBox.ShowYesNo("元宝不足，是否充值？", self.YesCb, self)
end

function M:YesCb()
    VIPMgr.OpenVIP(1)
end

function M:OnTen()
    if self.mIsOpenningReward then return end
    local need = 10 - self.mData.MaterialCount
    local cost = need * self.mData.TenGold * 0.1
    if RoleAssets.IsEnoughAsset(2, cost) then
        AlchemyMgr:ReqRoleBgAlchemyDraw(10, 1)
    else
        self:ShowMsgBox()
    end
end

function M:InitData()
    local data = AlchemyMgr:GetBestAlchemyData()
    if not data then return end
    self.mData = data
    self:InitImmortalCells()
    self:InitBestCells()
    self:InitCommonCells()
    self:InitBtnOneName()
    self:InitBtnOnePrice()
    self:InitBtnTenName()
    self:InitBtnTenPrice()
    self:InitRemainTime()
    self:InitTips()
end

function M:InitTips()
    local typeId = self.mData.MaterialId
    local cfg = ItemData[tostring(typeId)]
    if not cfg then return end
    self.mTips.text = string.format("仙品炼丹优先使用【%s】", cfg.name)
end

function M:InitCells(list, data, grid)
    for i=1,#data do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(grid.transform)
        cell:UpData(data[i].ID, data[i].Num)
        table.insert(list, cell)
    end
    grid:Reposition()
end

function M:InitImmortalCells()
    self:InitCells(self.mImmortalCells, self.mData.ImmortalList, self.mImmortalGrid)
end

function M:InitBestCells()
    self:InitCells(self.mBestCells, self.mData.BestList, self.mBestGrid)
end

function M:InitCommonCells()
    self:InitCells(self.mCommonCells, self.mData.CommonList, self.mCommonGrid)
end


function M:InitBtnOneName()
    self.mBtnOneName.text = self.mData.BtnOneName
end

function M:InitBtnOnePrice()
    self.mBtnOnePrice.text = self.mData.OnceGold
end

function M:InitBtnTenName()
    self.mBtnTenName.text = self.mData.BtnTenName
end

function M:InitBtnTenPrice()
    self.mBtnTenPrice.text = self.mData.TenGold
end

function M:InitRemainTime()
    local eDate = FestivalActMgr:GetActEndTime(FestivalActMgr.BestAlchemy)
    local seconds =  eDate-TimeTool.GetServerTimeNow()*0.001
    if seconds <= 0 then
        self:CompleteCb()
    else
        if not self.mTimer then
            self.mTimer = ObjPool.Get(DateTimer)
            self.mTimer.invlCb:Add(self.InvlCb, self)
            self.mTimer.complete:Add(self.CompleteCb, self)
            self.mTimer.apdOp = 3
        end
        self.mTimer.seconds = seconds
        self.mTimer:Start()
        self:InvlCb()
    end
end

function M:InvlCb()
    self.mRemainTime.text = string.format("剩余时间：%s", self.mTimer.remain) 
end

function M:CompleteCb()
    self.mRemainTime.text = ""
end

function M:UpdateGold()
    self.mGold.text = RoleAssets.Gold
end

function M:UpdateMaterial()
    self.mMaterial.text = self.mData.MaterialCount
end

function M:UpdateBagRedPoint()
    self.mBagRedPoint:SetActive(#self.mData.TempBagList > 0)
end

function M:UpdateOneRedPoint()
    self.mOneRedPoint:SetActive(self.mData.MaterialCount > 0)
end

function M:UpdateTenRedPoint()
    self.mTenRedPoint:SetActive(self.mData.MaterialCount >= 10)
end


function M:UpdateData()
    if not self.mData then return end
    self:UpdateBagRedPoint()
    self:UpdateOneRedPoint()
    self:UpdateTenRedPoint()
    self:UpdateGold()
    self:UpdateMaterial()
end


function M:Open()
    self.mFxJiHuo:SetActive(false)
    self:SetActive(true)
    if not self.mHasInit then
        self.mHasInit = true
        self:InitData()
    end
    self:UpdateData()
end

function M:Close()
    self:SetActive(false)
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:Dispose()
    self:SetLsnr("Remove")
    self.mData = nil
    self.mHasInit = false
    self.mIsOpenningReward = false
    if self.mTimer then
        self.mTimer:AutoToPool()
        self.mTimer = nil
    end
    if self.mDelayTimer then
        self.mDelayTimer:AutoToPool()
        self.mDelayTimer = nil
    end
    TableTool.ClearListToPool(self.mImmortalCells)
    TableTool.ClearListToPool(self.mBestCells)
    TableTool.ClearListToPool(self.mCommonCells)
    TableTool.ClearUserData(self)
    AlchemyTempBag:Dispose()
end

return M