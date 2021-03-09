--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-11-13 16:48:22
--=========================================================================

DBCenter = {Name = "DBCenter"}

local My = DBCenter

function My:Init()
  self:SetUrl()
  if App.FirstInstall then
    self:Active()
  end
end

function My:SetUrl()
  self.url = "http://cp-data.ijunhai.com/"
end

function My:Active()
  local data = {}
  data.event = "active"
  local tm = TimeTool.GetServerTimeNow() * 0.001
  data.server_ts = math.floor(tm)
  local device = Device
  data.client_ip = device.IP
  data.is_test = App.IsDebug and "test" or "regular"

  local game = {}
  game.game_id = 175
  game.game_ver = CSApp.VerCode
  data.game = game

  local agent = {}
  agent.channel_id = User.ChannelID
  agent.game_channel_id = User.GameChannelId
  data.agent = agent

  local dv = {}
  dv.device_name = device.Model
  if App.IsAndroid() then
    dv.os_type = "android"
    dv.android_imei = device.IMEI
    dv.ios_idfa = ""
  else
    dv.os_type = "ios"
    dv.ios_idfa = device.IMEI
    dv.android_imei=""
  end
  dv.net_type = device.NetType
  dv.os_ver = device.SysVer
  dv.package_name = UApp.identifier
  dv.screen_width = Screen.width
  dv.screen_height = Screen.height
  dv["user-agent"] = ""
  data.device = dv
  local str = json.encode(data)
  coroutine.start(self.Upload, self, str)
  --Loong.Game.WwwTool.Upload(self.url, str)
end

function My:Upload(data)
  local www = Loong.Game.WwwTool.Create(self.url, data)
  coroutine.www(www)
  local err = www.error
  if StrTool.IsNullOrEmpty(err) then
    iTrace.sLog("Loong", self.Name, " upload suc, data:", data)
  else
    iTrace.Warning("Loong", self.Name, " upload fail, data:", data, ", err:", err)
  end
  www:Dispose()
end

function My:Clear()

end

return My
