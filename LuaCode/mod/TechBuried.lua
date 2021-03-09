--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-07-17 19:46:41
-- Technical Analysis
--=========================================================================

TechBuried = {Name = "TechBuried"}

local My = TechBuried

function My:Init()
  AccMgr.eBack:Add(self.Logout, self)
  AccMgr.eLogoutSuc:Add(self.Logout, self)
  AccMgr.eLoginCreate:Add(self.Login, self)
  UserMgr.eCreateAccount:Add(self.Rig, self)
  self.url = App.BSUrl .. "buried/logs/"
end

function My:Clear()

end

--注册机型
--注册账号
--账号登陆
--在SDK登录返回时触发
function My:Rig()
  self:RegModel()
  self:RegAcc(true)
  self:AccLogin(true)
end

--选角进入游戏时触发
function My:Login(create)
  --在创角成功
  if create == true then
    self:SvrRegAcc(true)
    self:RegRole()
  end
  self:SvrAccLogin(true)
end

--在账号退出时触发
function My:Logout()
  self:SvrAccLogout()
  self:AccLogout()
end

function My:GetIP()
  do return self.url end
end

function My:Check()
  if App.isEditor == true then return false end
  do return true end
end

function My:Test()
  self:RegModel()
  self:RegAcc(true)
  self:AccLogin(true)
  self:AccLogout()
  self:SvrRegAcc(true)
  self:SvrAccLogin(true)
  self:SvrAccLogout()
  self:RegRole()
end

--首次打开
function My:First()
  --if CSApp.FirstInstall == false then return end
  coroutine.start(self.Upload, self, "SetAll", "firstOpen")
end

--机型注册
function My:RegModel()
  if self:Check() == false then return end
  coroutine.start(self.Upload, self, "SetAll", "modelRegister")
end

--账号注册
function My:RegAcc(suc)
  if self:Check() == false then return end
  local fn = ((suc == true) and "SetRegAccSuc" or "SetRegAccFail")
  coroutine.start(self.Upload, self, fn, "accountRegister")
end

--账号登录
function My:AccLogin(suc)
  if self:Check() == false then return end
  local fn = ((suc == true) and "SetAccLoginSuc" or "SetAccLoginFail")
  coroutine.start(self.Upload, self, fn, "accountLoginLogout")
end

--账号登出成功
function My:AccLogout()
  if self:Check() == false then return end
  coroutine.start(self.Upload, self, "SetAccLogout", "accountLoginLogout")
end

--区账号注册
function My:SvrRegAcc(suc)
  if self:Check() == false then return end
  local fn = ((suc == true) and "SetSvrRegAccSuc" or "SetSvrRegAccFail")
  coroutine.start(self.Upload, self, fn, "serveridRegister")
end

--区账号登录
function My:SvrAccLogin(suc)
  if self:Check() == false then return end
  local fn = ((suc == true) and "SetSvrAccLoginSuc" or "SetSvrAccLoginFail")
  coroutine.start(self.Upload, self, fn, "serveridLoginLogout")
end

--区账号登出成功
function My:SvrAccLogout()
  if self:Check() == false then return end
  coroutine.start(self.Upload, self, "SetSvrAccLogout", "serveridLoginLogout")
end

--角色注册
function My:RegRole()
  if self:Check() == false then return end
  coroutine.start(self.Upload, self, "SetRegRole", "roleRegister")
end

function My:SetRegRole(fm)
  self:SetForm(fm)
  local data = User.MapData
  fm:AddField("vip_level", User.VIPLV)
  fm:AddField("role_level", data.Level)
  fm:AddField("power", data.AllFightValue)
  fm:AddField("career", data.Category)
  local rLv = RebirthMsg.RbLev or 0
  fm:AddField("career_level", rLv)
  fm:AddField("action_code", "role_reg")

  local di = Device
  fm:AddField("imei", di.IMEI)
end

--设置区账号登录成功字段
function My:SetSvrAccLoginSuc(fm)
  self:SetAccLoginLogout(fm, 1, "gamesvr_login", "SetForm2")
end

--设置区账号登录失败字段
function My:SetSvrAccLoginFail(fm)
  self:SetAccLoginLogout(fm, 0, "gamesvr_login", "SetForm2")
end

--设置区账号登出字段
function My:SetSvrAccLogout(fm)
  self:SetAccLoginLogout(fm, 1, "gamesvr_logout", "SetForm2")
end

--设置区账号注册成功字段
function My:SetSvrRegAccSuc(fm)
  self:SetSvrRegAcc(fm, 1)
end

--设置区账号注册成功字段
function My:SetSvrRegAccFail(fm)
  self:SetSvrRegAcc(fm, 0)
end

function My:SetSvrRegAcc(fm, res)
  self:SetForm1(fm)
  fm:AddField("action_code", "gamesvr_reg")
  fm:AddField("action_result", res)
  fm:AddField("vip_level", User.VIPLV)
end

--设置账号登录成功字段
function My:SetAccLoginSuc(fm)
  self:SetAccLoginLogout(fm, 1, "account_login", "SetForm1")
end

--设置账号登录失败字段
function My:SetAccLoginFail(fm)
  self:SetAccLoginLogout(fm, 0, "account_login", "SetForm1")
end

--设置账号登出字段
function My:SetAccLogout(fm)
  self:SetAccLoginLogout(fm, 1, "account_logout", "SetForm1")
end

--设置登录登出字段
function My:SetAccLoginLogout(fm, res, action, fn)
  local func = self[fn]
  func(self, fm)
  local sb = ObjPool.Get(StrBuffer)
  local tm = OnlineAwardInfo.onlineTime or 0
  local ra = RoleAssets
  sb:Apd("online_time:"):Apd(tm);
  sb:Apd("#main_coin:"):Apd(ra.Gold);
  sb:Apd("#gift_coin:"):Apd(ra.BindGold);
  sb:Apd("#sub_coin:"):Apd(ra.Silver);
  fm:AddField("statistics_field", sb:ToStr())
  ObjPool.Add(sb)
  fm:AddField("action_code", action)
  fm:AddField("action_result", res)
end

--设置账号注册成功
function My:SetRegAccSuc(fm)
  self:SetRegAcc(fm, 1)
end

--设置账号注册失败
function My:SetRegAccFail(fm)
  self:SetRegAcc(fm, 0)
end

--设置账号注册
function My:SetRegAcc(fm, res)
  self:SetForm1(fm)
  fm:AddField("action_code", "account_reg")
  fm:AddField("action_result", res)
end


--所有共有的字段
function My:SetForm(fm)
  local tm = TimeTool.GetServerTimeNow()
  tm = tm * 0.001
  tm = math.floor(tm)
  fm:AddField("time", tm)
  local svrID = (User.ServerID or "0")
  fm:AddField("server_id", svrID)
  fm:AddField("log_time", tm)
  local uid = self:GetUID()
  local cid = self:GetChannelID()
  local accUID = cid .. "_" .. uid
  fm:AddField("account_id", accUID)
  fm:AddField("uid", 10101)
  local gcid = self:GetGameChannelID()
  fm:AddField("user_register_channel_id", gcid)
  fm:AddField("user_login_channel_id", cid)
  local plat = self:GetPlat()
  fm:AddField("mobile_os_type", plat)

  local data = User.MapData
  fm:AddField("user_add_time", 0)
  fm:AddField("game_version", App.Ver)
end

--区/非 账号注册/登录/登出共有的字段
function My:SetForm1(fm)
  local di = Device
  self:SetForm0(fm)
  fm:AddField("sdk_version", di.SysSDKVer)
end

function My:SetForm2(fm)
  local di = Device
  self:SetForm0(fm)
  fm:AddField("vip_level", User.VIPLV)
end

--区账号注册/登录/登出共有的字段
function My:SetForm0(fm)
  self:SetForm(fm)
  local di = Device
  fm:AddField("mobile_operator", di.SIMName)
  fm:AddField("network_type", di.NetType)
  fm:AddField("client_type", di.Brand)
  fm:AddField("client_version", di.Model)
  fm:AddField("ip", di.IP)
  fm:AddField("imei", di.IMEI)
  fm:AddField("mac", di.Mac)
end

--设置全部字段
function My:SetAll(fm)
  self:SetForm1(fm)
  local di = Device
  fm:AddField("os_version", di.SysVer)
  fm:AddField("os_type", di.OS)
  fm:AddField("cpu_name", di.CpuName)
  fm:AddField("cpu_frequency", di.CpuFreq)
  fm:AddField("cpu_core_number", di.CpuCount)
  fm:AddField("gpu_name", di.GpuName)
  fm:AddField("memory", di.TotalMem)
  local avaiMem = di.AvaiMem
  fm:AddField("now_memory_free", avaiMem)
  local memIsEnough = self:MemIsEnough(avaiMem)
  fm:AddField("memory_isFull", memIsEnough)
  fm:AddField("disk_size", di.TotalRom)
  fm:AddField("now_disk_size_free", di.AvaiRom)
  fm:AddField("sd_max_size", di.TotalSD)
  fm:AddField("now_sd_free", di.AvaiSD)
  local rs = self:GetResolution()
  fm:AddField("resolution", rs)
  fm:AddField("baseband_version", di.BBVer)
  fm:AddField("core_version", di.BBVer)
  fm:AddField("OpenGL_VENDOR", di.GpuVerdor)
  fm:AddField("OpenGL_VERSION", di.GpuVer)
end


--fn(string):设置WWWForm的方法名
--path(string):接口路径
--tip(string):提示
function My:Upload(fn, path, tip)
  if self:Check() == false then return end
  local func = self[fn]
  if(type(func) ~= "function") then
    iTrace.Error("Loong", self.Name, " no function name:", fn)
    return
  end
  local fm = WWWForm.New()
  local ip = self:GetIP() .. path
  --iTrace.sLog("Loong", "upload beg ", path)
  func(self, fm)
  local www = UnityWebRequest.Post(ip, fm)
  www:SendWebRequest();
  coroutine.www(www)
  local err = www.error
  if not StrTool.IsNullOrEmpty(err) then
    iTrace.Warning("Loong", "upload ", path, ", err:", err)
  end
  --iTrace.Log("Loong", "upload end ", path, ": ", www.text)
  www:Dispose()
end

--判断内存是否足够
function My:MemIsEnough(val)
  if val > 300 then return 0 end
  do return 1 end
end

--获取平台
function My:GetPlat()
  local plat = App.platform
  if plat == 1 then return 4 end
  if plat == 2 then return 5 end
  do return 7 end
end

--获取分辨率
function My:GetResolution()
  local rs = tostring(Screen.width) .. "X" .. tostring(Screen.height)
  do return rs end
end

--获取UID
function My:GetUID()
  local id = (Sdk and Sdk.uid or 0)
  do return id end
end

function My:GetChannelID()
  local plat = App.platform
  if plat == 2 then
    return "ios"
  else
    return (User.ChannelID or "0")
  end
end


function My:GetGameChannelID()
  local plat = App.platform
  if plat == 2 then
    return "ios"
  else
    return (User.GameChannelId or "0")
  end
end


return My
