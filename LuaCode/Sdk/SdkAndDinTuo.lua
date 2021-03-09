--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-05-22 20:49:33
-- Android 顶拓SDK
-- 1实名制
-- ①,先通过SupportRealName判断是否支持实名制，若支持再主动调用获取实名制接口:
-- GetPlayerInfo并且只能在登录成功之后调用
-- ②,实名制信息获取回调事件分别是eRealName和eRealNameFail
-- ③,获取成功后数据会返回到realNameInfo中，其数据结构包含3个字段
--  age:年龄， isRealName：1已实名,0未实名, msg:暂不清楚结构
--=========================================================================

Sdk = {Name = "SdkAndDinTuo"}

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


function My:Init()
  self:Reset()
  self:SetChl()
  self:AddLsnr()
  self.firstLogin = true
  --上传数据
  self.upData = {}
  --支付数据
  self.payData = {}
  
end

function My:Reset()
  self.uid = "0"
  --实名制信息
  self.realNameInfo = nil
end
--
function My:SetChl()
  self.channel_id = User.ChannelID
  self.game_channel_id = User.GameChannelId
end


function My:AddLsnr()
  local Add = EventMgr.Add
  local EH = EventHandler
  Add("SdkSuc", EH(self.SdkSuc, self))
  Add("SdkSwitchSuc", EH(self.SwitchSuc, self))
  Add("SdkSwitchFail", EH(self.SwitchFail, self))
  Add("LogoutSuc", EH(self.LogoutSuc, self))
  Add("RoleLogin", EH(self.RoleLogin, self))
  Add("SdkRealNameSuc", EH(self.RealNameSuc, self))
  Add("SdkRealNameFail", EH(self.RealNameFail, self))
  Add("SdkAntiAddictSuc", EH(self.AntiAddictSuc, self))
  Add("SdkAntiAddictFail", EH(self.AntiAddictFail, self))
  UserMgr.eLvEvent:Add(self.ChangeLvHandler, self)
end

function My:Login()
  if CS_Sdk == nil then return end
  if self.firstLogin then
    self:RealLogin()
    self.firstLogin = false
  else
    self:SwitchAccount()
  end
end

function My:RealLogin()
  CS_Sdk:Login()
end

function My:Logout()
  EventMgr.Trigger("LogoutSuc");
end

--切换账号
function My:SwitchAccount()
  CS_Sdk:SwitchAccount()
end

--BEG 监听
function My:SdkSuc(arg)
  self.uid = arg
  User.UID = arg
end

--切换成功
function My:SwitchSuc()
  --self:RealLogin()
  self.eSwitchSuc()
end

function My:SwitchFail()
  --EventMgr.Trigger("SdkFail")
  self.eSwitchFail()
  self:RealLogin()
end


--END 监听
--判断是否支持实名制
function My:SupportRealName()
  do return CS_Sdk:SupportRealName() end
end

--主动调用SDK获取实名制接口
--在调用之前先判断SDK是否支持实名制
function My:GetPlayerInfo()
  CS_Sdk:VerifyRealName(User.UID)
end



function My:Pay(ordID, url, cfg, msg)
  local user = User.instance
  local data = user.MapData
  local ra = RoleAssets
  local vip = VIPMgr.GetVIPLv() or 0
  local no = "0"
  local dt = self.payData
  dt.gameName = "天道问情"
  dt.proID = cfg.id
  dt.proName = cfg.name
  dt.proDes = cfg.des
  dt.amount = cfg.gold * 100
  local ratio = math.floor(cfg.getGold/cfg.gold)
  if ratio < 1 then ratio = 1 end
  dt.ratio = ratio
  local getGold = cfg.getGold 
  if getGold < 1 then getGold = 1 end
  dt.count = getGold
  dt.coin = cfg.gold or 1
  dt.svrID =  user.ServerID or no
  dt.svrName = user.ServerName or no
  
  dt.uid = user.UID
  dt.roleID = data.UIDStr or no
  dt.roleName = data.Name or no
  dt.lv = data.Level
  dt.giftID = "0" 
  dt.ext = ordID
  
  local str = json.encode(dt)
  if CS_Sdk then CS_Sdk:Pay(str) end
end

--上传数据
function My:Upload(data)
  if CS_Sdk then CS_Sdk:Upload(data) end
end


function My:LogoutSuc()
  iTrace.Log("Loong", "SDK登出成功:")
end

function My:LogoutFail()
  EventMgr.Trigger("LogoutSuc")
  --UITip.Log("退出账号失败")
end

--获取实名制信息
function My:RealNameSuc(args)
  local str = CS_Sdk.RealNameArg
  local info = json.decode(str)
  self.realNameInfo = info
  self.eRealName(info)
end

function My:RealNameFail(args)
  self.eRealNameFail()
end

function My:RoleLogin()
  self:Upload(1)
  if AccMgr.IsCreate == true then
    AccMgr.IsCreate = false
    self:Upload(2)
  end
end

--等级改变
function My:ChangeLvHandler()
  self:Upload(3)
end

--!TODO
function My:Exit()
  self:Upload(4)
end
--上传数据
--option(number):1：进入游戏；2：创建角色；3：角色升级；4：游戏退出
function My:Upload(option)
  local user = User.instance
  local data = user.MapData
  local ra = RoleAssets
  local vip = VIPMgr.GetVIPLv() or 0
  local no = "0"
  local dt = self.upData
  dt.uid = user.UID
  dt.roleID = data.UIDStr or no
  dt.roleName = data.Name or no
  dt.createTm = data.LstCreateTime
  dt.LstLvUpTm = data.LstLevUpTime
  dt.lv = data.Level 
  dt.svrID =  user.ServerID or no
  dt.svrName = user.ServerName or no
  dt.dataType = option
  local str = json.encode(dt)
  CS_Sdk:Upload(str)
end

function My:ShowToolBar()
  CS_Sdk:ShowToolBar()
end

function My:HideToolBar()
  CS_Sdk:HideToolBar()
end

--是否有用户中心
function My:HasUC()
do return false end
end

--打开用户中心
function My:OpenUserCenter()
  UITip.Error("No UserCenter")
end

function My:Clear()
  --self:Reset()
end

function My:Dispose()

end

function My:AntiAddictSuc()
  local str = CS_Sdk.AntiAddictArg
  local info = json.decode(str)
  self.AntiAddictInfo = info
  self.eAntiAddtictSuc(info)
end

function My:AntiAddictFail()
  self.eAntiAddtictFail()
end


--判断是否支持防沉迷
function My:SupportAntiAddict()
  do return CS_Sdk:SupportAntiAddict() end
end

--设置防沉迷开始时间
function My:SetAntiAddictBeg()
  CS_Sdk:SetAntiAddictBeg()
end

--设置防沉迷结束时间
function My:SetAntiAddictEnd()
  CS_Sdk:SetAntiAddictEnd()
end


return My
