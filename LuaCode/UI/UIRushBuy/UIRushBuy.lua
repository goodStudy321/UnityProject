
UIRushBuy = UIBase:New{Name="UIRushBuy"}

require("UI/UIRushBuy/RushBuyInfo")
local My = UIRushBuy

function My:InitCustom(go)
    local root = self.root
    local des = self.Name
    local TF = TransTool.Find
    local CG = ComTool.Get
    local U = UITool.SetBtnClick
    self.userSex = User.MapData.Sex
    
    self.desLab = CG(UILabel,root,"TitleLab/DesLab",des)
    self.restLab = CG(UILabel,root,"TitleLab/RestLab",des)
    self.PropTab = {}
    
    U(root, "CloseBtn", des, self.CloseClick, self)
    
    -- local RushBuyAcInfo = LivenessInfo.xsActivInfo["1016"]
    
    -- self:InitData()
    -- self:AddE()
end

function My:AddE()
    -- RushBuyMgr.eRushBuyInfo:Add(self.RushBuyInfo,self)
    RushBuyMgr.eRushBuy:Add(self.RushBuy,self)
    PropMgr.eGetAdd:Add(self.OpenRwdBoxTip,self)
end

function My:RemoveE()
    -- RushBuyMgr.eRushBuyInfo:Remove(self.RushBuyInfo,self)
    RushBuyMgr.eRushBuy:Remove(self.RushBuy,self)
    PropMgr.eGetAdd:Remove(self.OpenRwdBoxTip,self)
end

function My:OpenCustom()
    self:InitData()
    self:RushBuyInfo()
    self:AddE()
end

function My:OpenRwdBoxTip(action,getList)
    self.dic = {}
    if action == 10316 and #getList>0 then
        self.dic = getList;
        UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self);
    end
end

function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(My.dic)
	end
end

function My:RushBuyInfo()
    local gotList = RushBuyDateInfo.RushBuyList
    if gotList == nil or #gotList < 1 then
        return
    end
    local len = #gotList
    for i = 1,len do
        local id = gotList[i]
        local dataObj = self.PropTab[id]
        if dataObj ~= nil then
            dataObj.gotSp.gameObject:SetActive(true)
        end
    end
end

function My:RushBuy(buyId)
    -- iTrace.Error("GS","buyid====",buyId)
    if buyId == nil then
        iTrace.eError("GS","服务器返回道具id为空")
        return
    end
    local dataObj = self.PropTab[buyId]
    dataObj.gotSp.gameObject:SetActive(true)
end

function My:InitData()
    local strRest = string.format("剩余活动时间：%s天",RushBuyDateInfo.RushBuyTime)
    self.restLab.text = strRest

    local len = #RushBuyCfg
    local sex = tonumber(self.userSex)
    for i=1,len do
        -- local index = i <= 3 and i or 3
		local prop = TransTool.Find(self.root, string.format("prop%s",i))
        local cfgId = i
        local tempCfg,dataObj = RushBuyCfg[cfgId],nil
        local modelPath = tempCfg.modelPath
        if FashionCfg[modelPath] ~= nil then
            local fashionData = FashionCfg[modelPath]
            local mId = nil
            if sex == 1 then  --男性
                mId = fashionData.mMod
                modelPath = RoleBaseTemp[mId].uipath
            elseif sex == 0 then  --女性
                mId = fashionData.wMod
                modelPath = RoleBaseTemp[mId].uipath
            end
        end
        if prop ~= nil and tempCfg ~= nil then 
            local dataGbj = ObjPool.Get(RushBuyInfo)
            local propid = tempCfg.id
            dataGbj:Init(prop)
            dataGbj:RefreshData(tempCfg)
            dataGbj:LoadMod(modelPath)
            self.PropTab[propid] = dataGbj
		end
    end
end

function My:CloseClick(go)
    self:Close()
    JumpMgr.eOpenJump()
end

function My:CloseCustom()

end

function My:DisposeCustom()
    self:RemoveE()
    for k,v in pairs(self.PropTab) do
        v:Clear()
	end
end

return My
