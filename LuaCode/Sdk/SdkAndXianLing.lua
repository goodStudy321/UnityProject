Sdk = Super:New{Name = "SdkAndXianLing"}

local My = Sdk

--实名更新事件
My.eRealName = Event()
--实名更新失败事件
My.eRealNameFail = Event()
--切换账号成功事件
My.eSwitchSuc = Event()
--切换账号失败事件
My.eSwitchFail = Event()

--防沉迷成功回调,参数是sdk返回的数据,已生成luatable
My.eAntiAddtictSuc = Event()
--防沉迷失败回调
My.eAntiAddtictFail = Event()

My.eUrlSucc = Event()
My.eSdkIsCanEnter = Event()

function My:Init()
    self:AddLsnr()
    self.payData = {}
    --实名制信息
    self.realNameInfo = nil
    
    self.url = App.BSUrl .. "index/Xiangling/auth"
end

function My:AddLsnr()
    local Add = EventMgr.Add
    local EH = EventHandler
    Add("SdkSuc", EH(self.SdkSuc, self))
    Add("LogoutSuc", EH(self.LogoutSuc, self))
    Add("RoleLogin", EH(self.RoleLogin, self))
    Add("SdkCanEnter", EH(self.SdkResultCanEnter, self))
    Add("SdkStorGM", EH(self.OpenRecharge, self))
    UserMgr.eLvEvent:Add(self.ChangeLvHandler, self)
end

function My:Login()
    CS_Sdk:Login()
end

function My:Logout()
    CS_Sdk:Logout()
end

function My:SdkSuc(msg)
    local loginArg = json.decode(msg)
    self.loginArg = loginArg
    local uid = loginArg.super_user_id
    local token = loginArg.token
    local auth = loginArg.auth -- 0未实名 1已实名 2未接入实名
    local birth = loginArg.birthday --出生日期，默认格式为 年-月-日，比如1990-1-1。如未实名或者没有实名信息可能为null或者空字符串
    User.UID = uid
    self.uid = uid
    self:SendUrl(uid,token)
    iTrace.Log("lgs", "Lua LoginSuc:", msg, ", uid:", uid)
end

function My:SendUrl(uid,token)
    local url = self.url
    local sb = ObjPool.Get(StrBuffer)
    sb:Apd(url):Apd("?super_user_id="):Apd(uid)
    sb:Apd("&token="):Apd(token)
    local fullPath = sb:ToStr()
    ObjPool.Add(sb)
    iTrace.Log("lgs","Lua  sdk登陆成功，向后台发送  url: ",fullPath)
    WWWTool.LoadText(fullPath, self.NotifyUrl, self)
end

function My:NotifyUrl(text,err)
    iTrace.Log("lgs","sdk登陆成功，后台返回 result, text: ",text,", err: ",err)
    if(StrTool.IsNullOrEmpty(err)) then
        local res = json.decode(text)
        local status = res.status
        local code = status.code
        local msg = status.msg
        if code == 10200 then --校验成功
            iTrace.Log("lgs","sdk登陆成功，后台校验成功")
            self.eUrlSucc()
        else
            UITip.Error(msg)
        end
    end
end

--是否允许新增
function My:IsCanEnter(svrID,svrName)
    CS_Sdk:CanEnter(svrID,svrName)
end

function My:RoleLogin()
    if AccMgr.IsCreate == true then
        AccMgr.IsCreate = false
        self:UpdataOnRoleData(1)
    end
    self:UpdataOnRoleData(2)
end

function My:ChangeLvHandler()
    self:UpdataOnRoleData(3)
end

function My:SdkResultCanEnter(isCan)
    local isCan = CS_Sdk.IsCanEnterResult
    if not StrTool.IsNullOrEmpty(isCan) then
        if isCan == "true" then
            self.eSdkIsCanEnter(true)
        elseif isCan == "false" then
            self.eSdkIsCanEnter(false)
        end
    end
end

--上传数据
--option(number):1创角,2进入服务器,3等級改变
function My:UpdataOnRoleData(option)
    local data = self:GetRoldData()

    local svrID = data.svrID
    local svrName = data.svrName
    local roleID = data.roleID
    local roleName = data.roleName
    local roleDes = data.roleDes
    local roleLv = data.roleLv
    local roleVip = data.roleVip
    local totalCoin = data.totalCoin
    local familyName = data.familyName
    local roleExp = data.roleExp
    local curTime = data.curTime
    if option == 1 then
        CS_Sdk:uploadOnCreateRole(svrID,svrName,roleID,roleName,roleDes,roleLv,roleVip,totalCoin,familyName,roleExp,curTime)
    elseif option == 2 then
        CS_Sdk:uploadOnEnterSvr(svrID,svrName,roleID,roleName,roleDes,roleLv,roleVip,totalCoin,familyName,roleExp,curTime)
    elseif option == 3 then
        CS_Sdk:uploadOnRoleUpgLv(svrID,svrName,roleID,roleName,roleDes,roleLv,roleVip,totalCoin,familyName,roleExp,curTime)
    end
end

function My:Pay(ordID, url, cfg, msg)
    local data = self:GetRoldData()
    local oId = ordID
    local svrID = data.svrID
    local svrName = data.svrName
    local roleID = data.gameRoleID
    local roleName = data.roleName
    local roleDes = data.roleDes
    local roleLv = data.roleLv
    local roleVip = data.roleVip
    local totalCoin = data.totalCoin
    local familyName = data.familyName
    local curTime = data.curTime

    local proName = cfg.name
    local proID = tostring(cfg.id)
    local getGold = cfg.getGold 
    if getGold < 1 then getGold = 1 end
    local cnt = getGold
    local money = cfg.gold
    CS_Sdk:Pay(oId,roleID,roleName,svrID, proName,proID,svrName,cnt,money,curTime,proID,roleLv) 
end

--打开充值界面
function My:OpenRecharge()
    VIPMgr.OpenVIP(1)
end

--判断是否支持防沉迷
function My:SupportAntiAddict()
    return false
end

--设置防沉迷开始时间
function My:SetAntiAddictBeg()
    -- CS_Sdk:SetAntiAddictBeg()
end

function My:SupportRealName()
    -- do return CS_Sdk:SupportRealName() end
end

function My:HasUC()
    do return false end
end

function My:GetRoldData()
    local tab = {}
    local user = User.instance
    local data = user.MapData
    local ra = RoleAssets
    local no = "0"
    tab.svrID = user.ServerID or no
    tab.svrName = user.ServerName or no
    tab.roleID = user.UID or no
    tab.gameRoleID = data.UIDStr or no
    tab.roleName = data.Name or no
    tab.roleDes = ""
    tab.roleLv = data.Level or 0
    tab.roleVip = VIPMgr.GetVIPLv() or 1
    tab.totalCoin = ra.Gold or 0
    tab.familyName = data.FamlilyName or "unknown"
    tab.roleExp = data.ExpStr or "1"
    tab.curTime = user.ServerTime
    return tab
end

function My:LogoutSuc()
    iTrace.Log("lgs", "lua  SDK登出成功:")
end