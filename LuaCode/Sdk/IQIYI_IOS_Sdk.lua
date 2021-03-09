--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019/7/20 上午12:45:16
-- 1.爱奇艺存在游客绑定功能:最重要体现在游戏内账号UID会发生改变,
--      改变时通过事件eChangedUID触发
--=============================================================================


Sdk = Super:New{ Name = "IQIYI_IOS_Sdk" }

local My = Sdk

----BEG PUBLIC

function My:Init()
    self:AddLsnr()
    self.payData = {}
    self.bindData = {}

    --账号UID改变事件
    self.eChangedUID = Event()
    self.url = App.BSUrl .. "/index/Iqiyi/"
end

function My:Login()
    CS_Sdk.Login()
end

function My:Logout()
    CS_Sdk.Logout()
end

----END PUBLIC

function My:AddLsnr()
    local Add = EventMgr.Add
    local EH = EventHandler
    Add("SdkSuc", EH(self.SdkSuc, self))
    Add("SDK_DidBindMsg", EH(self.DidBindSuc, self))

    Add("RoleLogin", EH(self.RoleLogin, self))
    SceneMgr.eOpenScene:Add(self.UpdataOnSceneEnter, self)
end

function My:SdkSuc(msg)
    local loginArg = json.decode(msg)
    self.loginArg = loginArg
    local uid = loginArg.uid
    User.UID  = uid
    self.uid = uid
    iTrace.Log("Loong", "Lua LoginSuc:", msg, ", uid:", uid)
end

function My:DidBindSuc(msg)
    local arg = json.decode(msg)
    self.bindArg = arg
    local sb = ObjPool.Get(StrBuffer)
    local url = self:GetUrl("guest")
    local gcid = User.GameChannelId or "0"
    sb:Apd(url):Apd("?guest_uid="):Apd(arg.guest_uid)
    sb:Apd("&phone_uid="):Apd(arg.phone_uid)
    sb:Apd("&game_channel_id="):Apd(gcid)
    local fullPath = sb:ToStr()
    ObjPool.Add(sb)
    iTrace.Log("Loong", "Lua  DidBindSuc receive:", msg, ", url:", fullPath)
    WWWTool.LoadText(fullPath, self.NotifyBind, self)
end

--待完成
function My:NotifyBind(text, err)
    iTrace.Log("Loong", "Lua DidBind result, text:", text, ", err:", err)
    local dt = self.bindData
    if(StrTool.IsNullOrEmpty(err)) then
        local res = json.decode(text)
        local status = res.status
        dt.code = status.code
        dt.msg = status.msg
        if (dt.code == 100) then
            local old = self.uid
            self.uid = self.bindArg.phone_uid
            self.eChangedUID(old, self.uid)
        end
    else
        dt.code = 105
        dt.msg = "网络异常"
    end
    local result = json.encode(dt)
    CS_Sdk.NotifyBind(result)
end

function My:RoleLogin()
    if AccMgr.IsCreate == true then
        AccMgr.IsCreate = false
        self:UpdataOnRoleCreate()
    end
end

--支付
--money(number) 单位元
--appleProID(string) 商品ID(apple)
--ordID(string) 订单ID
function My:Pay(money, appleProID, ordID, proID)
    local dt = self.payData
    local data = User.MapData
    dt.svrID = User.ServerID or "1"
    dt.roleID = data.UIDStr or "0"
    dt.money = money
    dt.proID = appleProID
    dt.ordID = ordID
    dt.devInfo = proID
    local str = json.encode(dt)
    iTrace.Log("Loong", "Lua pay data:", str)
    CS_Sdk.Pay(str)
end


function My:UpdataOnRoleCreate()
    local svrID = User.ServerID or "1"
    CS_Sdk.UpdataOnRoleCreate(svrID)
end

function My:UpdataOnSceneEnter()
    local svrID = User.ServerID or "1"
    CS_Sdk.UpdataOnSceneEnter(svrID)
end


function My:GetUrl(path)
    local full = self.url .. path
    return full
end


function My:Clear()

end


return My