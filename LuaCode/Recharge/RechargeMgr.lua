--[[
    authors     :Liu
    date        :2018-8-20 10:00:00
    descrition  :充值管理
--]]

RechargeMgr = {Name = "RechargeMgr"}

local My = RechargeMgr

--首充字典
My.firstDic = {}
--剩余天数
My.rDays = nil
--今天充值的元宝
My.todayGold = 0
--总充值的元宝
My.totalGold = 0
--默认显示红点
My.isShow = true

function My:Init()
    self:SetLnsr(ProtoLsnr.Add)
    self.eRechargeInfo = Event()
    self.eRecharge = Event()
    UserMgr.eLvEvent:Add(self.LvChange, self)
end

--设置监听
function My:SetLnsr(func)
    func(22500,self.RespRechargeInfo, self)
    func(22502,self.RespRecharge, self)
    func(22504,self.RespRechargeSucc, self)
end

--响应充值信息
function My:RespRechargeInfo(msg)
    local list = msg.first_pay_list
    My.rDays = msg.package_days
    My.todayGold = msg.today_pay_gold
    My.totalGold = msg.total_pay_gold
    for i,v in ipairs(list) do
        local key = tostring(v)
        My.firstDic[key] = true
    end
    self.eRechargeInfo()
    self:UpRedDot()
end

--请求充值
function My:ReqRecharge(id)
    local msg = ProtoPool.GetByID(22501)
    msg.product_id = id
    ProtoMgr.Send(msg)
end

--响应充值
function My:RespRecharge(msg)
    local err = msg.err_code
    if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
        return
    end
    self.eRecharge(msg.order_id, msg.notify_url, msg.product_id, msg)
end

--拉起支付
--ordid(订单ID)
--url(回调地址)
--proID(产品ID)
--msg(协议消息)
--multi(倍数)
function My:StartRecharge(orderId, url, proID, msg, multi)
    multi = multi or 1
    local platform = App.platform
    local ord = tostring(orderId)
    local roleId = tostring(User.MapData.UIDStr)
    local roleName = User.MapData.Name
    local serverId = tostring(User.ServerID)
    local serverName = User.ServerName
    -- local cfg = RechargeCfg[proID]
    local cfg = RechargeMgr:GetPriceCfg(proID);
    local name = cfg.name
    local id = tostring(proID)
    local des = cfg.des
    local getGold = (cfg.getGold==0) and 1 or (cfg.getGold* multi)
    local gold = cfg.gold * 100
    local rate = (cfg.getGold==0) and 1 or math.floor((cfg.getGold/cfg.gold)*multi)

    Sdk:Pay(ord, url,cfg, msg)
end

--响应充值成功
function My:RespRechargeSucc(msg)
    local proId = msg.product_id
    -- local cfg = RechargeCfg[proId]
    local cfg = My:GetPriceCfg(proId);
    if cfg == nil then return end
    UITip.Log("您成功购买了"..cfg.des)
end

--购买元宝
function My:BuyGold(func1, func2, func3, func4, obj)
    local platform = App.platform
    if platform == nil then
        iTrace.Error("SJ", "并未检测到任何平台")
        return
    elseif platform == 0 then--编辑器
        obj[func1](obj)
    elseif platform == 1 then--Android
        if self:IsSdk() then obj[func2](obj) end
    elseif platform == 2 then--IOS
        if self:IsSdk() then obj[func3](obj) end
    elseif platform == 3 then--其他
        obj[func4](obj)
    end
end

--判断是否存在Sdk
function My:IsSdk()
    if Sdk then
        return true
    else
        iTrace.Error("SJ", "未检测到Sdk")
        return false
    end
end

--响应等级变化
function My:LvChange()
    self:UpRedDot()
end

--初始化红点
function My:UpRedDot()
    local actId = ActivityMgr.CZ
    local state = ActivityMgr:CheckOpenForLvId(actId)
    if self.isShow and state then
        SystemMgr:ShowActivity(actId)
    end
end

--删除红点
function My:DelRedDot()
    self.isShow = false
    local actId = ActivityMgr.CZ
    SystemMgr:HideActivity(actId)
end

--清理缓存
function My:Clear()
    My.firstDic = {}
    My.rDays = nil
end
    
--释放资源
function My:Dispose()
    self:SetLnsr(ProtoLsnr.Remove)
    TableTool.ClearFieldsByName(self,"Event")
    UserMgr.eLvEvent:Remove(self.LvChange, self)
end

function My:GetPriceCfg(productId)
    local cfg = nil;
    for i,v in ipairs(RechargeCfg) do
        if v.id == productId then
            cfg = v
        end
    end
    return cfg;
end
    
return My