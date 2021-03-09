Sdk = Super:New{Name = "SdkAndZhangChuang"}

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

function My:Init()
    self:AddLsnr()
    self.payData = {}
    --实名制信息
    self.realNameInfo = nil
end

function My:AddLsnr()
    local Add = EventMgr.Add
    local EH = EventHandler
    Add("SdkSuc", EH(self.SdkSuc, self))
    Add("LogoutSuc", EH(self.LogoutSuc, self))
    Add("RoleLogin", EH(self.RoleLogin, self))
    Add("SdkExitSuc", EH(self.SdkExit, self))
    UserMgr.eLvEvent:Add(self.ChangeLvHandler, self)
end

function My:Login()
    CS_Sdk:Login()
end

function My:Logout()
    CS_Sdk:Logout()
end

function My:SdkExit()
    App.Quit()
end

function My:SdkSuc(msg)
    self.url = App.BSUrl .. "index/Xinji/auth?package=android"

    local loginArg = json.decode(msg)
    self.loginArg = loginArg
    local uid = loginArg.userId
    local token = loginArg.token
    User.UID = uid
    self.uid = uid
    self:SendUrl(uid,token)
    iTrace.Log("lgs", "Lua LoginSuc:", msg, ",  uid: ", uid)
end

function My:SendUrl(uid,token)
    local url = self.url
    local sb = ObjPool.Get(StrBuffer)
    sb:Apd(url):Apd("&token="):Apd(token)
    sb:Apd("&uid="):Apd(uid)
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

function My:RoleLogin()
    if AccMgr.IsCreate == true then
        AccMgr.IsCreate = false
        self:UpdataOnRoleData(0)
    end
    self:UpdataOnRoleData(1)
end

function My:ChangeLvHandler()
    self:UpdataOnRoleData(2)
end

--上传数据
--option(number):0:创建角色   1：进入游戏     2：角色升级
function My:UpdataOnRoleData(option)
    if option == 0 then
        iTrace.Error("GS","创建角色   上传数据 ")
    elseif option == 1 then
        iTrace.Error("GS","进入游戏   上传数据 ")
    elseif option == 2 then
        iTrace.Error("GS","角色升级   上传数据 ")
    end
    local data = self:GetRoldData()
    local serverID = data.svrID
    local serverName = data.svrName
    local gameRoleName = data.roleName 
    local gameRoleID = data.gameRoleID
    local gameRoleBalance = data.totalCoin
    local vipLevel = data.roleVip
    local gameRoleLevel = data.roleLv
    local partyName = data.familyName
    local roleCreateTime = data.roleCreateTime
    local partyId = data.partyId
    local gameRoleGender = data.gameRoleGender
    local gameRolePower = data.gameRolePower
    local partyRoleId = data.partyRoleId
    local partyRoleName = data.partyRoleName
    local professionId = data.professionId
    local profession = data.profession
    local friendlist = data.friendList

    local jsonTab = {}
    jsonTab.RoleId = gameRoleID
    jsonTab.RoleName = gameRoleName
    jsonTab.RoleLevel = gameRoleLevel
    jsonTab.ServceId = serverID
    jsonTab.ServceName = serverName

    local str = json.encode(jsonTab)
    CS_Sdk:UpdateUserInfo(str)
end

function My:Pay(ordID, url, cfg, msg)
    local oId = ordID
    local data = self:GetRoldData()
    local serverID = data.svrID
    local serverName = data.svrName
    local gameRoleName = data.roleName 
    local gameRoleID = data.gameRoleID
    local gameRoleBalance = data.totalCoin
    local vipLevel = data.roleVip
    local gameRoleLevel = data.roleLv
    local partyName = data.familyName
    local roleCreateTime = data.roleCreateTime

    local goodsID = cfg.id
    goodsID = tostring(goodsID)
    local goodsName = cfg.name
    local cpOrderID = oId
    local getGold = cfg.getGold
    if getGold < 1 then
        getGold = 1
    end
    local count = getGold
    local amount = cfg.gold
    amount = tostring(amount)
    local goodsdesc = cfg.des
    local extrasParams = "no"

    local jsonTab = {}

    extrasParams = string.format("%s,%s",gameRoleID,goodsID)
    jsonTab.cp_order_id = cpOrderID
    jsonTab.role_id = gameRoleID
    jsonTab.role_name = gameRoleName
    jsonTab.role_level = gameRoleLevel
    jsonTab.server_id = serverID
    jsonTab.server_name = serverName
    jsonTab.money = amount
    jsonTab.goodsid = goodsID
    -- jsonTab.goods_name = goodsName
    jsonTab.goods_name = goodsdesc --商品名称改商品描述
    jsonTab.extra = extrasParams
    jsonTab.test_pay = "100"  --测试支付状态(100：是；    101：否）
    -- jsonTab.test_pay = "101"  --测试支付状态(100：是；     101：否）

    local str = json.encode(jsonTab)

    CS_Sdk:Pay(str)
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

function My:GetSdkIndex()
    local gid = UserMgr:GetGameChannelID()
    local index = 1
    -- if gid == "500013" or gid == "600001" or gid == "500202" then
    --     index = 1
    -- end
    return index
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
    tab.totalCoin = tostring(ra.Gold) or no
    tab.roleVip = tostring(VIPMgr.GetVIPLv()) or "1"
    tab.roleLv = tostring(data.Level) or no
    tab.familyName = data.FamlilyName or "unknown"
    tab.roleCreateTime = tostring(data.LstCreateTime)
    tab.roleExp = data.ExpStr or "1"
    tab.curTime = user.ServerTime
    tab.partyId = no
    tab.gameRoleGender = tostring(data.Sex)
    tab.gameRolePower = tostring(data.AllFightValue)
    tab.partyRoleId = no
    tab.partyRoleName = no
    tab.professionId = no
    tab.profession = no
    tab.friendList = "无"
    return tab
end

function My:LogoutSuc()
    iTrace.Log("lgs", "lua  SDK登出成功:")
end

function My:Clear()

end