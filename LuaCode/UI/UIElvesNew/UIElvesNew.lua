--[[
    新增精灵
]]

UIElvesNew = UIBase:New{Name = "UIElvesNew"}
local My = UIElvesNew

function My:InitCustom()
    local trans = self.root
    local TF = TransTool.FindChild
    local T = TransTool.Find
    local CG = ComTool.Get
    local des = self.Name
    local UC = UITool.SetLsnrSelf

    self.nameLab = CG(UILabel,trans,"name",des)
    self.desLab = CG(UILabel,trans,"des",des)
    self.priceLab = CG(UILabel,trans,"price",des)
    self.modRoot = T(trans,"modRoot",des)
    self.payBtn = CG(BoxCollider,trans,"btn",des)
    self.closeBtn = CG(BoxCollider,trans,"CloseBtn",des)
    self.headBtn = CG(BoxCollider,trans,"com/17",des)
    self.btnSp = CG(UISprite,trans,"btn/Sprite",des)
    self.btnRed = TF(trans,"btn/red",des)
    UC(self.headBtn,self.OnHead,self,des,false)
    UC(self.closeBtn,self.OnClose,self,des)
end

function My:OnHead()
    local cfg = ItemData["40009"]
    if cfg == nil then
        iTrace.eError("GS","道具表不存在新版精灵id：40009  的配置")
        return
    end
    if cfg.uFx ~= 28 then
        return
    end
    UIMgr.Open(GuardTip.Name,self.OpenCb,self)
end

function My:OpenCb(name)
    local ui =UIMgr.Get(name)
    if ui then
        ui:UpData(40009)
    end
end

function My:SetInfo()
    local serverPrice = ElvesNewMgr.buyMoney
    local pCfg = ItemData["40009"]
    local globalCfg = GlobalTemp["146"]
    local decoraCfg = Decoration["40009"]
    if pCfg == nil then
        iTrace.eError("GS","道具表不存在新版精灵id：40009  的配置")
        return
    end
    if globalCfg == nil then
        iTrace.eError("GS","全局表不存在新版精灵id：146  的配置")
        return
    end
    if decoraCfg == nil then
        iTrace.eError("GS","饰品表不存在新版精灵id：40009  的配置")
        return
    end
    if serverPrice == nil then
        iTrace.eError("GS","服务端传的价格为空")
        return
    end
    local name = pCfg.name
    local praceNum = 0
    if serverPrice == 0 then
        praceNum = globalCfg.Value3
    else
        praceNum = serverPrice
    end
    local comColor = "[E9A88BFF]"
    local greenColor = "[54FF68FF]"
    local attVal1 = decoraCfg.att[1].val
    local attVal2 = decoraCfg.att[2].val
    local attId1 = decoraCfg.att[1].id
    local attId2 = decoraCfg.att[2].id
    local attName1 = PropName[attId1].name
    local attName2 = PropName[attId2].name
    local num1 = string.format("%s%s",attVal1/100,"%")
    local num2 = string.format("%s%s",attVal2/100,"%")
    local des = string.format("%s%s[-]%s+%s[-]%s和%s[-]%s+%s[-]%s,助你等级战力飞升[-]",comColor,attName1,greenColor,num1,comColor,attName2,greenColor,num2,comColor)
    local price = string.format( "[FFECD0FF]仅售[-] [54FF68FF]￥%s[-]",praceNum)
    self.nameLab.text = name
    self.desLab.text = des
    self.priceLab.text = price
end

--点击充值项
function My:PayFunc()
    RechargeMgr:BuyGold("Func1", "Func2", "Func3", "Func4", self)
end

--编辑器
function My:Func1()
    
end

--Android
function My:Func2()
    local payId = self:GetPayId()
    RechargeMgr:ReqRecharge(payId)
end

--IOS
function My:Func3()
    local payId = self:GetPayId()
    RechargeMgr:ReqRecharge(payId)
end

--其他
function My:Func4()
    
end

--领取
function My:GetFunc()
    ElvesNewMgr:ReqGetElves()
end

--以领取
function My:ReturnFunc()
    UITip.Error("已领取")
end

function My:GetPayId()
    local globalCfg = GlobalTemp["146"]
    if globalCfg == nil then
        iTrace.eError("GS","全局表不存在新版精灵id：146  的配置")
        return
    end
    local praceNum = globalCfg.Value3
    if praceNum == nil then
        iTrace.eError("GS","全局表不存在新版精灵id：146  的配置")
        return
    end
    local payId = nil
    for i,v in ipairs(RechargeCfg) do
        if v.gold == praceNum then
            payId = v.id
            break
        end
    end
    if payId == nil then
        iTrace.eError("GS","RechargeCfg  GlobalTemp  充值数据不匹配")
        return
    end
    return payId
end

function My:OnClose()
    self:Close()
    -- JumpMgr.eOpenJump()
end

--model
function My:LoadModel()
    self:UnloadMod()
    local cfg = Decoration["40009"]
    if cfg == nil then
        iTrace.eError("GS","检查配置  守护表   新增精灵Id:40009   不存在")
        return
    end
    local path = cfg.model
    LoadPrefab(path, GbjHandler(self.LoadModCb, self))
end

function My:LoadModCb(go)
    self.modelName = go
    go.transform.parent = self.modRoot
    self:SetPos(go)   
end

function My:SetPos(go)
    go.transform.localScale=Vector3.one
	go.transform.localRotation=Quaternion.New(0,180,0,0)
	go.transform.localPosition=Vector3.zero
    LayerTool.Set(go, 19)
end

function My:UnloadMod()
    if LuaTool.IsNull(self.modelName) then return end
    if self.modelName then
        AssetMgr:Unload(self.modelName.name,".prefab",false)
        GameObject.DestroyImmediate(self.modelName)
        self.modelName = nil
    end
end

--icon
function My:UpIcon()
	self:UnloadTex()
	self.iconName = "elvesn_bg.png"
	AssetMgr:Load(self.iconName,ObjHandler(self.LoadIcon,self))
end

function My:LoadIcon(obj)
	self.bgTex.mainTexture=obj
end

function My:UnloadTex()
	if self.iconName then 
		AssetMgr:Unload(self.iconName,".png",false)
	end
	self.iconName=nil
end

--响应充值
function My:RespRecharge(orderId, url, proID,msg)
    RechargeMgr:StartRecharge(orderId, url, proID, msg)
end

function My:SetLnsr(func)
    RechargeMgr.eRecharge[func](RechargeMgr.eRecharge, self.RespRecharge, self)
    ElvesNewMgr.eElvesBtnState[func](ElvesNewMgr.eElvesBtnState, self.ShowDifBtn, self)
    -- PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

function My:OnAdd(action, dic)
    if action==10308 then
        self.dic = dic
        UIMgr.Open(UIGetRewardPanel.Name, self.RewardCb, self)
    end
end

function My:RewardCb(name)
    local ui = UIMgr.Get(name)
    if ui then
        ui:UpdateData(self.dic)
    end
end

--按钮状态
-- 0 未买  1 已买  2 已领
function My:ShowDifBtn()
    local UC = UITool.SetLsnrSelf
    local spTab = {"Spirit_text_liji","Spirit_text_lingqu"}
    local index = ElvesNewMgr.PayState
    UITool.SetAllNormal(self.payBtn.transform,true)
    self.btnRed:SetActive(false)
    if index == 0 then
        UC(self.payBtn,self.PayFunc,self)
        self.btnSp.spriteName = spTab[1]
    elseif index == 1 then
        UC(self.payBtn,self.GetFunc,self)
        self.btnSp.spriteName = spTab[2]
        self.btnRed:SetActive(true)
    else
        UITool.SetAllGray(self.payBtn.transform,true)
        self.btnSp.spriteName = spTab[2]
        UC(self.payBtn,self.ReturnFunc,self)
    end
end

--打开分页(邮件专用)
function My:OpenTabByIdx(t1,t2,t3,t4)
    local isOpen = LivenessInfo:GetActInfoById(1030)
    local payState = ElvesNewMgr.PayState
    local btnState = ElvesNewMgr.State
    if btnState == false or isOpen == false then
        UITip.Error("活动已过期")
        self:Close()
        return
    end
    if payState == nil or payState >= 1 then
        UITip.Error("您已经购买了该商品")
        self:Close()
        return
    end
    -- UIMgr.Open(UIElvesNew.Name)
end

function My:OpenCustom()
    self:SetLnsr("Add")
    self:SetInfo()
    -- self:UpIcon()
    self:LoadModel()
    self:ShowDifBtn()
end


function My:CloseCustom()

end

function  My:Clean()
    self.nameLab = nil
    self.desLab = nil
    self.priceLab = nil
    self.modRoot = nil
    self.payBtn = nil
    self.closeBtn = nil
end

function My:DisposeCustom()
    -- self:UnloadTex()
    self:UnloadMod()
    self:SetLnsr("Remove")
    self:Clean()
end

return My