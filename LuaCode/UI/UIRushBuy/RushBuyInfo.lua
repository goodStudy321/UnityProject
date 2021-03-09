RushBuyInfo = {Name = "RushBuyInfo"}

local My = RushBuyInfo

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

function My:Init(root)
    self.root = root
    local des = self.Name
    local TF = TransTool.Find
    local CG = ComTool.Get
    local U = UITool.SetLsnrSelf
    local info = TF(root,"Info",des)
    self.nameLab = CG(UILabel,info,"NameLab",des)
    self.numLab = CG(UILabel,info,"NumLab",des)
    self.priceLab = CG(UILabel,info,"BuyBtn/priceLab",des)
    self.desTimeLab = CG(UILabel,info,"Sp/desTimeLab",des)
    self.coinLab = CG(UILabel,info,"Sp/coinLab",des)
    self.coinSp1 = CG(UISprite,info,"Sp/coinSp",des)
    self.coinSp = CG(UISprite,info,"BuyBtn/coinSp",des)
    self.gotSp = CG(UISprite,info,"GotSp",des)
    self.gotSp.gameObject:SetActive(false)
    self.modelRoot = TF(info,"Root",des)
    self.buyBtn = CG(UIButton,info,"BuyBtn",des,false)
    self.box = CG(BoxCollider, info, "Root", des, false)
    U(self.buyBtn,self.BuyClick,self)
    UITool.SetLsnrSelf(self.box,self.ShowPropTip,self)
end

function My:BuyClick(go)
    local parent = go.transform.parent.parent
    local parentName = parent.gameObject.name
    self.propId = nil
    local showStr = nil
    local price,coinType,propName,returnDay,coinStr = nil,nil,nil,nil,nil
    local propCfg,itemCfg = nil,nil
    local isGot = self.gotSp.gameObject.activeSelf
    if isGot then
        UITip.Error("已购买此道具")
        return
    end
    if parentName == "prop1" then
        self:GetShowInfo(1)
        -- RushBuyMgr:ReqRushBuy(propId)
    elseif parentName == "prop2" then
        self:GetShowInfo(2)
        -- self.propId = RushBuyCfg[2].id
        -- RushBuyMgr:ReqRushBuy(propId)
    elseif parentName == "prop3" then
        self:GetShowInfo(3)
        -- self.propId = RushBuyCfg[3].id
        -- RushBuyMgr:ReqRushBuy(propId)
    end
end

function My:GetShowInfo(index)
    local propCfg = RushBuyCfg[index]
    self.propId = propCfg.id
    self.ownCoinNum,self.needPrice = nil
    local coinStr = nil
    local idStr = tostring(self.propId)
    local itemDate = ItemData[idStr]
    local price = propCfg.price
    self.needPrice = price
    self.coinType = propCfg.coinType
    local propName = itemDate.name
    local returnDay = propCfg.returnDay
    coinStr,self.ownCoinNum = self:GetCoinStr(self.coinType)
    self.goldNum = RoleAssets.Gold
    local showStr = nil
    if self.coinType == 2 then
        showStr = string.format("是否花费%s%s购买[e83030]%s[-]，购买%s天后可返还%s%s",price,coinStr,propName,returnDay,price,coinStr)
    elseif self.coinType == 3 then
        showStr = string.format("是否花费%s%s购买[e83030]%s[-]，购买%s天后可返还%s%s [e83030](若绑元不足则使用元宝购买)[-]",price,coinStr,propName,returnDay,price,coinStr)
    end
    self:ShowMsgBox(showStr)
end

function My:ShowMsgBox(showStr)
    MsgBox.ShowYesNo(showStr,self.BuyCb,self)
end

function My:BuyCb()
    if self.coinType == 3 and self.needPrice > self.ownCoinNum and self.needPrice > self.goldNum then
        UITip.Error("元宝不足")
        VIPMgr.OpenVIP(1)
        return
    end
    if self.coinType == 2 and self.needPrice > self.goldNum then
        UITip.Error("元宝不足")
        VIPMgr.OpenVIP(1)
        return
    end
    RushBuyMgr:ReqRushBuy(self.propId)
end

function My:GetCoinStr(type)
    if type == 2 then
        return "元宝",RoleAssets.Gold
    elseif type == 3 then
        return "绑元",RoleAssets.BindGold
    end
end

function My:RefreshData(tabData)
    self.propId = tabData.id
    local itemID = tostring(self.propId)
    local itemDate = ItemData[itemID]
    local modelPath = tabData.modelPath
    self.nameLab.text = itemDate.name
    local coinType = tabData.coinType
    local returnDay = tabData.returnDay
    local price = tabData.price
    local coinDes,iconPath = nil,nil
    if coinType == 2 then
        coinDes = "元宝"
        iconPath = "money_02"
    elseif coinType == 3 then
        coinDes = "绑元"
        iconPath = "money_03"
    end
    self.numLab.text = tabData.fightVal
    local desTimeStr = string.format("%s天返还%s %s",returnDay,price,coinDes)
    self.desTimeLab.text = returnDay
    self.coinLab.text = price
    self.coinSp1.spriteName = iconPath
    self.priceLab.text = price
    self.coinSp.spriteName = iconPath
    UITool.SetLsnrSelf(self.box,self.ShowPropTip,self)
    -- self:LoadMod(modelPath)
end

function My:ShowPropTip()
    if self.propId == nil then return end
    UIMgr.Open(PropTip.Name,self.PropCb,self)
end

function My:PropCb(name)
	local ui=UIMgr.Get(name)
	if ui then
		ui:UpData(self.propId)
	end
end

--加载模型
function My:LoadMod(modelPath)
    local modelPath = modelPath
    if modelPath == nil then
        iTrace.eError("GS","模型配置ID为空")
        return
    end
    Loong.Game.AssetMgr.LoadPrefab(modelPath, GbjHandler(self.LoadDone,self))
end
  
--加载模型回调
function My:LoadDone(gbj)
    local parent = self.modelRoot.transform.parent.parent
    local parentName = parent.gameObject.name
    self.modelName = gbj.gameObject.name
    self.mod = gbj.transform
    if self.mod == nil then
        iTrace.eError("GS","请检查模型配置ID")
        return
    end
    self.mod.parent = self.modelRoot
    LayerTool.Set(gbj.transform,19)
    if parentName == "prop1" then
        self:SetModel(1)
    elseif parentName == "prop2" then
        self:SetModel(2)
    elseif parentName == "prop3" then
        self:SetModel(3)
    end
end

function My:SetModel(index)
    local model = self.mod
    if index == 1 then
        model.localPosition = Vector3.New(381,-796.2,-536)
        model.localRotation = Quaternion.Euler(44.8,159.7,48.49995)
        model.localScale = Vector3(370,370,370)
    elseif index == 2 then
        model.localPosition = Vector3.New(-5.9,-50,0)
        model.localRotation = Quaternion.Euler(0,180,0)
        model.localScale = Vector3(200,200,200)
    elseif index == 3 then
        model.localPosition = Vector3.New(-5.9,-50,0)
        model.localRotation = Quaternion.Euler(0,180,0)
        model.localScale = Vector3(200,200,200)
    end
end

function My:Clear()
    if self.modelName then
        AssetMgr:Unload(self.modelName,".prefab",false)
        self.modelName = nil
    end
    self.mod = nil
    self.root = nil
    self.nameLab = nil
    self.numLab = nil
    self.priceLab = nil
    self.desTimeLab = nil
    self.coinLab.text = nil
    self.coinSp1 = nil
    self.modelRoot = nil
    self.coinSp = nil
    self.buyBtn = nil
    self.propId = nil
end