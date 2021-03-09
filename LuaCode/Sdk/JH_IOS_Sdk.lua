--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-09-10 06:47:50
--=========================================================================

Sdk = {Name = "JH_IOS_Sdk"}

local My = Sdk

function My:Init()
  self:AddLsnr()
  --购买结构
  self.payTbl = {}
  --上传数据结构
  self.updataTbl = {}
  self:SetChl()
  iTrace.Log("Loong", "LUA IOS JHSDK INIT ", self.game_channel_id)
end

function My:AddLsnr()
  local Add = EventMgr.Add
  local EH = EventHandler
  Add("SdkSuc", EH(self.SdkSuc, self))
  Add("RoleLogin", EH(self.UpdataOnEnterSvr, self))
  UserMgr.eLvEvent:Add(self.UpdataOnRoleUpg, self)
end

function My:SetChl()
  self.game_channel_id = User.GameChannelId 
end

function My:SdkSuc(arg)
  self.uid = arg
  User.UID = arg
  iTrace.Log("Loong", "SDK登陆成功,arg:", arg, ", uid:", self.uid)
end

-- 登录
function My:Login()
  CS_Sdk.login()
end

-- 登出 如果不掉用,下次调用登录将不会弹出界面
function My:Logout()
  CS_Sdk.logout()
end

--支付
-- ordID:订单号(string)
-- money:总金额(number),单位为分
-- cnt:商品数量(number)
-- proID:商品ID(string)
-- proName:商品名称(string)
-- rate:兑换比率(number),即1元可以买多少商品
-- desc:订单详细信息(string)
-- url:充值回调地址(string)
-- roleID:角色id(string)
-- svrName:区服名称(string)
-- svrID:区服ID(number)
-- roleName:角色名(string)
-- appleID:苹果后台申请到的商品编码(string)
function My:Pay(ordID, money, cnt, proID, proName, rate, des, url, roleID, svrName, svrID, roleName, appleID)
  local dt = self.payTbl
  dt.ordID = ordID
  dt.money = money
  dt.count = cnt
  dt.proID = proID
  dt.proName = proName
  dt.rate = rate
  dt.desc = des
  dt.url = url
  dt.roleID = roleID
  dt.svrName = svrName
  dt.svrID = svrID
  dt.roleName = roleName
  dt.appleProID = appleID
  local str = json.encode(dt)
  iTrace.Log("Loong", "Lua pay data:", str)
  CS_Sdk.pay(str)
end

-- 当进入服务器时上传数据

function My:UpdataOnEnterSvr()
  self:GetData()
  local str = json.encode(self.updataTbl)
  iTrace.Log("Loong", "Lua UpdataOnEnterSvr data:", str)
  CS_Sdk.updataOnEnterSvr(str)
end

-- 当角色升级时上传数据
function My:UpdataOnRoleUpg()
  self:GetData(roleID, svrID, svrName, roleName, vipLv, coinCnt, coinName, roleLv)
  local str = json.encode(self.updataTbl)
  iTrace.Log("Loong", "Lua UpdataOnRoleUpg data:", str)
  CS_Sdk.updataOnRoleUpg(str)
end

-- 设置上传数据
function My:GetData()
  local data = User.MapData
  local ra = RoleAssets
  local dt = self.updataTbl

  dt.roleID = data.UIDStr
  dt.svrID = User.ServerID
  dt.svrName = User.ServerName
  dt.roleName = data.Name
  dt.vipLv = User.VIPLV or 0
  dt.coinCount = ra.Gold 
  dt.coinName = ra:GetTypeName(2)
  dt.roleLv = data.Level
end

function My:Clear()

end

return My
