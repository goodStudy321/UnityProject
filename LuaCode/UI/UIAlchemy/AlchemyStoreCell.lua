AlchemyStoreCell = Super:New{Name = "AlchemyStoreCell"}

local M = AlchemyStoreCell

M.mTexList = {}

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local GS = ComTool.GetSelf
    local S = UITool.SetLsnrSelf

    self.mGo = go
    self.mBG = GS(UISprite, go)
    self.mIcon = G(UITexture, trans, "Icon")
    self.mIsBest = FC(trans, "IsBest")
    self.mItemBG = G(UISprite, trans, "ItemBg")
    self.mName = G(UILabel, trans, "Name")
    self.mRemainCount = G(UILabel, trans, "RemainCount")
    self.mPrice = G(UILabel, trans, "Price")
    self.mRemainTime = G(UILabel, trans, "CountDown")
    self.mBtnBuy = FC(trans, "BtnBuy")
    self.mBtnBuySprite =  GS(UISprite, self.mBtnBuy)
    self.mBtnBox = GS(BoxCollider, self.mBtnBuy)
    self.mNone = FC(trans, "None")
    self.mMask = FC(trans, "Mask")
    self.mFxRoot = FC(trans, "FxRoot")

    S(self.mBtnBuy, self.OnBuy, self)
    S(self.mIcon, self.OnClickItem, self)
end

function M:OnClickItem()
    if not self.mData then return end
    local id = tostring(self.mData.rewardList[1].id);
    if ItemData[id].uFx == 89 then
        UIMgr.Open(UIElixirTip.Name,self.OpenPropTipCb,self);
    else
        PropTip.pos=self.mIcon.transform.position
        UIMgr.Open(PropTip.Name,self.OpenPropTipCb,self)
    end
end

function M:OpenPropTipCb(name)
    if not self.mData then return end
    local rewardList = self.mData.rewardList
    if not rewardList then return end
    local data = rewardList[1]
    if not data then return end
    local ui = UIMgr.Get(name)
    if ui then
        local id = tostring(rewardList[1].id);
        if ItemData[id].uFx == 89 then
            ui:UpData(id);
        else
            ui:UpData(data.id)
        end
    end
end

function M:OnBuy()
    if not self.mData then return end 
    if RoleAssets.IsEnoughAsset(2, self.mData.schedule) then
        FestivalActMgr:ReqBgActReward(self.mData.type, self.mData.id)
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

function M:UpdateBG()
    local state = self.mData.remainCount < 0
    local spriteName1 = state and "liandan_xiantu_bg1" or "liandan_xiantu_bg"
    local spriteName2 = state and "liandan_wupin_bg" or "liandan_wupin_bg1"
    self.mBG.spriteName = spriteName1
    self.mItemBG.spriteName = spriteName2
end

function M:UpdateItem()
    local rewardList = self.mData.rewardList
    if not rewardList then return end
    local data = rewardList[1]
    if not data then return end
    local typeId = data.id
    local itemData = ItemData[tostring(typeId)]
    if not itemData then return end
    self:UpdateIcon(itemData.icon)
    self:UpdateName(itemData.name)
    self:UpdateIsBest(data.effNum)
    self:UpdateFx(data.effNum)
end

function M:UpdateIcon(texture)
    AssetMgr:Load(texture, ObjHandler(self.SetIcon, self))
end

function M:SetIcon(tex)
    if self.mData then
        self.mIcon.mainTexture = tex
        table.insert(self.mTexList, tex.name)
    else
        AssetTool.UnloadTex(tex.name)
    end
end

function M:UpdateFx(effNum)
    local state = effNum == 1
    self.mFxRoot:SetActive(state)
    if not self.mFx then
        if state then
            Loong.Game.AssetMgr.LoadPrefab("FX_Equip_Feng", GbjHandler(self.SetFx,self))
        end
    end
end

function M:SetFx(go)
    if self.mFxRoot then
        self.mFx = go
        go.transform:SetParent(self.mFxRoot.transform)
        go.transform.localPosition = Vector3(0,0,0)
        go.transform.localScale = Vector3(1.9, 1.9, 1.9)
    else
        self:Unload(go)
    end
end

function M:UpdateIsBest(isBest)
    self.mIsBest:SetActive(isBest == 1)
end


function M:UpdateName(name)
    self.mName.text = name
end

function M:UpdateRemainCount()
    local num = self.mData.remainCount
    local str = num < 0 and "[F4DDBDFF]剩余数量：不限次数" or string.format("[642D1EFF]剩余数量：%s", num)
    self.mRemainCount.text = str
    self:UpdateMask()
    self:UpdateNone()
    self:UpdateBtnStatus()
end

function M:UpdatePrice()
    local color = self.mData.remainCount < 0 and "[F4DDBDFF]" or "[642D1EFF]"
    self.mPrice.text = string.format("%s售价：    %s", color, self.mData.schedule)
end

function M:UpdateCountDown()
    local seconds = self.mData.target - TimeTool.GetServerTimeNow()*0.001
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
        self.mTimer:Stop()
        self.mTimer:Start()
        self:InvlCb()
    end
end

function M:InvlCb()
    self.mRemainTime.text = string.format("%s后开始", self.mTimer.remain) 
end

function M:CompleteCb()
    self.mRemainTime.text = ""
    self:UpdateBtnBuy()
end

function M:UpdateBtnBuy()
    local seconds =  self.mData.target - TimeTool.GetServerTimeNow()*0.001
    local state = seconds <= 0
    local spriteName = state and "liandan_btn_goumai" or "liandan_btn_goumai2"
    self.mBtnBox.enabled = state
    self.mBtnBuySprite.spriteName = spriteName
    self:UpdateBtnStatus()
end

function M:UpdateNone()
    self.mNone:SetActive(self.mData.remainCount == 0)
end

function M:UpdateMask()
    self.mMask:SetActive(self.mData.remainCount == 0)
end

function M:UpdateBtnStatus()
    self.mBtnBuy:SetActive(self.mData.remainCount ~= 0)
end

function M:UpdateData(data)
    if not data then return end
    self.mData = data
    self:UpdateBG()
    self:UpdateItem()
    self:UpdateRemainCount()
    self:UpdatePrice()
    self:UpdateCountDown()
    self:UpdateBtnBuy()
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:IsActive()
    return self.mGo.activeSelf
end

function M:Unload(go)
    if LuaTool.IsNull(go) then return end
    AssetMgr:Unload(go.name,".prefab", false)
    GameObject.DestroyImmediate(go)
end

function M:Dispose()
    self.mData = nil
    if self.mTimer then
        self.mTimer:AutoToPool()
        self.mTimer = nil
    end
    if self.mFx then
        self:Unload(self.mFx)
        self.mFx = nil
    end
    AssetTool.UnloadTex(self.mTexList)
    TableTool.ClearUserData(self)
end

return M