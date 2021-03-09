--[[
 	authors 	:Liu
 	date    	:2018-8-17 12:00:00
 	descrition 	:充值界面
--]]

UIRecharge = Super:New{Name="UIRecharge"}

local My = UIRecharge
--特效字典
My.EffectDic = {}

require("UI/UIRecharge/UIRechargeIt")
require("UI/UIRecharge/UIRechargeGift")

function My:Init(go)
    local root = go.transform
    local FindC, des = TransTool.FindChild, self.Name
    local str = "Scroll View/Grid"
    local gift = FindC(root, str.."/gift", des)
    local item = FindC(root, str.."/item", des)
    local gridTran = TransTool.Find(root, str, des)
    self.go = go
    self.giftList = {}
    self.itList = {}
    self:InitEffDic(root)
    self:InitItem(gift, item, gridTran)
    self:SetLnsr("Add")
end

--初始化特效
function My:InitEffDic(root)
    local str = "Scroll View/Effects/FX_VIP0";
    local TFC = TransTool.FindChild;
    for i = 1,8 do
        local path = str .. i;
        local effect = TFC(root,path,self.Name);
        effect:SetActive(false);
        local name = effect.name;
        My.EffectDic[name] = effect;
    end
end

--获取特效
function My.GetEffect(name)
    local effect = My.EffectDic[name];
    if effect == nil then
        effect = My.EffectDic["FX_VIP08"];
    end
    if effect == nil then
        return;
    end
    local go = Instantiate(effect);
    return go;
end

--设置监听
function My:SetLnsr(func)
    RechargeMgr.eRecharge[func](RechargeMgr.eRecharge, self.RespRecharge, self)
end

--响应充值
function My:RespRecharge(orderId, url, proID,msg)
    RechargeMgr:StartRecharge(orderId, url, proID, msg)
end

--初始化充值项
function My:InitItem(gift, item, gridTran)
    local Add = TransTool.AddChild
    for i,v in ipairs(RechargeCfg) do
        self:SelectItem(v, gift, item, Add, gridTran)
    end
    gift:SetActive(false)
    item:SetActive(false)
end

--选择生成充值项
function My:SelectItem(cfg, gift, item, Add, gridTran)
    if cfg.giftType == 0 then
        local canCreate = self:CanCreate(cfg);
        if canCreate == true then
            self:SetItem(item, Add, gridTran, UIRechargeIt, cfg, self.itList)
        end
    else
        -- self:SetItem(gift, Add, gridTran, UIRechargeGift, cfg, self.giftList)
    end
end

--是否可创建
function My:CanCreate(cfg)
    local gmChnlIds = cfg.gmChnlIds;
    local len = #gmChnlIds;
    if len == 0 then
        return true;
    end
    local channelID = User.GameChannelId
    channelID = tonumber(channelID);
    for i = 1, len do
        if channelID == gmChnlIds[i] then
            return true;
        end
    end
    return false;
end

--设置充值项
function My:SetItem(item, Add, gridTran, obj, cfg, list)
    self:AddItem(item, Add, gridTran, cfg)
    local it = ObjPool.Get(obj)
    it:Init(tran, cfg)
    table.insert(list, it)

end

--添加充值项
function My:AddItem(item, Add, gridTran, cfg)
    local go = Instantiate(item)
    go.name = cfg.gold + 10000
    tran = go.transform
    Add(gridTran, tran)
end

--打开面板
function My:Open()
	self.go:SetActive(true)
end

--关闭面板
function My:Close()
	self.go:SetActive(false)
end

--清理缓存
function My:Clear()
    self.go = nil
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
    ListTool.ClearToPool(self.giftList)
    ListTool.ClearToPool(self.itList)
    TableTool.ClearDic(My.EffectDic)
    -- AssetTool.UnloadByCfg(RechargeCfg, "icon")
end

return My