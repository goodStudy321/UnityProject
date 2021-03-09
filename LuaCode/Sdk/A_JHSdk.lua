--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-05-22 20:49:33
-- Android JHSDK
--=========================================================================

Sdk = {Name = "A_JHSdk"}

local My = Sdk

function My:Init()
  self:Reset()
  self:SetChl()
  self:AddLsnr()
  self.eRealName = Event()
  iTrace.Log("Loong", "LUA JHSDK INIT")
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
  Add("readyExit", EH(self.ReadyExit, self))
  Add("LogoutSuc", EH(self.LogoutSuc, self))
  Add("GetRealNameInfo", EH(self.GetRealNameInfo, self))
  Add("RoleLogin", EH(self.RoleLogin, self))
  UserMgr.eLvEvent:Add(self.ChangeLvHandler, self)
end

function My:Login()
  CS_Sdk:Login()
end

function My:SdkSuc(arg)
  self.uid = arg
  User.UID = arg
  --iTrace.sLog("Loong", "SDK登陆成功,arg:", arg, ", uid:", self.uid,"  sdk.uid: ",Sdk.uid)
end

function My:Logout()
  CS_Sdk:Logout()
end


--主动调用SDK获取实名制接口
function My:GetPlayerInfo()
  CS_Sdk:GetPlayerInfo()
end

--充值
--oid(string):订单号
--roleId(string):角色ID
--roleName(string):角色名
--svrID(string):区服ID
--proName(string):商品名,名称前请不要添加任何量词.如钻石,月卡即可
--proID(string):商品ID
--des(string):商品描述信息
--cnt(number):购买的商品数量
--money(number):支付金额 单位为分
--url(string):支付结果回调地址
function My:Buy(oid, roleId, roleName, svrID, proName, proID, des, cnt, money, url)
  CS_Sdk:Buy(oid, roleId, roleName, svrID, proName, proID, des, cnt, money, url)
end

--上传购买道具统计数据
--con(number):购买道具所花费的游戏币
--conBind(number):购买道具所花费的绑定游戏币
--remain(number):剩余多少游戏币
--remainBind(number):剩余多少绑定游戏币
--cnt(number):购买道具的数量
--name(string):道具名称
--des(string):道具描述,可以传空串
function My:UploadBuyData(con, conBind, remain, remainBind, cnt, name, des)
  des = des or ""
  --CS_Sdk:uploadBuyData(con, conBind, remain, remainBind, cnt, name, des)
end


function My:LogoutSuc()
  iTrace.Log("Loong", "SDK登出成功:")
end

function My:LogoutFail()
  EventMgr.Trigger("LogoutSuc")
  --UITip.Log("退出账号失败")
end

--获取实名制信息
function My:GetRealNameInfo(args)
  local str = CS_Sdk.RealNameInfo
  local info = json.decode(str)
  self.realNameInfo = info
  self.eRealName(info)
end

function My:RoleLogin()
  local user = User.instance
  local data = user.MapData
  local ra = RoleAssets
  local vip = VIPMgr.GetVIPLv()
  if AccMgr.IsCreate == true then
    AccMgr.IsCreate = false
    self:Upload(1)
  end
  self:Upload(2)
end

--等级改变
function My:ChangeLvHandler()
  self:Upload(3)
end

function My:ReadyExit()
  iTrace.Log("Loong", self.Name, " LUA ReadyExit")
  self:Upload(4)
end
--上传数据
--option(number):1创角,2进入服务器,3等级改变,4准备退出
function My:Upload(option)
  local user = User.instance
  local data = user.MapData
  local ra = RoleAssets
  local vip = VIPMgr.GetVIPLv() or 0
  local no = "0"
  local svrID = user.ServerID or no
  local svrName = user.ServerName or no
  local UIDStr = data.UIDStr or no
  local roleName = data.Name or no
  local familyName = user.FamilyName or "unknown"
  if option == 1 then
    CS_Sdk:uploadOnCreateRole(svrID, svrName, UIDStr, roleName, data.Level, vip, ra.Gold, familyName, RebirthMsg.RbLev, data.LstCreateTime, user.ServerTime)
  elseif option == 2 then
    CS_Sdk:uploadOnEnterSvr(svrID, svrName, UIDStr, roleName, data.Level, vip, ra.Gold, familyName, RebirthMsg.RbLev, data.LstCreateTime, user.ServerTime)
  elseif option == 3 then
    CS_Sdk:uploadOnRoleUpgLv(svrID, svrName, UIDStr, roleName, data.Level, vip, ra.Gold, familyName, RebirthMsg.RbLev, data.LstCreateTime, user.ServerTime)
  elseif option == 4 then
    CS_Sdk:uploadExit(svrID, svrName, UIDStr, roleName, data.Level, vip, ra.Gold, familyName, RebirthMsg.RbLev, data.LstCreateTime, user.ServerTime)
  end
end

--是否有用户中心
function My:HasUC()
  return CS_Sdk.HasUC
end

--打开用户中心
function My:OpenUserCenter()
  CS_Sdk:OpenUserCenter()
end

function My:Clear()
  --self:Reset()
end

function My:Dispose()

end


return My
