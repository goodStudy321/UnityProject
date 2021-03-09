--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 9/22/2018, 10:31:58 PM
--=============================================================================

require("Upg/UpgPkgCtrl")

UpgPkg = {Name = "UpgPkg"}
local My = UpgPkg

function My:Init()
  self:Reset()
  self:SetUrl()
  self.complete = Event()
  UpgPkgCtrl:Init()
end

function My:Reset()
  self.svrVer = 0
  self.force = 0
end

function My:SetUrl()
  local sb = ObjPool.Get(StrBuffer)
  --sb:Apd("http://127.0.0.1:8080/Loong/")
  sb:Apd("http://ynxf-cdn.ijunhai.com/ol_v1/")
  local isDebug = App.IsDebug
  local cid = (Sdk and 1 or 0)
  local db = (isDebug == true and "Debug" or "Release")
  sb:Apd(cid):Apd("/"):Apd(db):Apd("/")
  local pt = App.platform
  local plat = ((pt == Platform.Android or pt == Platform.PC) and "Android" or "iOS")
  sb:Apd(plat):Apd("/Package"):Apd("/AppVer.txt")
  self.url = sb:ToStr()
  ObjPool.Add(sb)
  iTrace.Log("Loong", self.Name, " url:", self.url)
end

function My:Start()
  UpgPkgCtrl:Open()
  coroutine.start(self.LoadVer, self)
end

function My:LoadVer()
  local url = self.url
  local www = UnityWebRequest.Get(url)
  www:SendWebRequest()
  coroutine.www(www)
  local err = www.error
  local text = www.text
  local Split = StrTool.Split
  local IsNull = StrTool.IsNullOrEmpty
  if not IsNull(err) then
    self:Failure()
  elseif (IsNull(text)) then
    iTrace.Error("Loong", "lua upgPkg no ver: ", url)
  else
    text = StrTool.Trim(text)
    local arr = Split(text, ",")
    local length = #arr
    if length > 2 then
      local str = arr[3]
      local op = tonumber(str)
      if (op == nil) then
        iTrace.Error("Loong", "lu upgPkg verText,force not can parse:", str)
      else
        iTrace.Log("Loong", "upgPkg verText,force:", op, ", ", text)
      end
      self.force = op or 0
    end

    if length > 1 then
      verName = arr[2]
      self.VerName = verName or "未知"
    end
    local verStr = arr[1]
    local verLen = string.len(verStr)
    if verLen > 3 then
      verStr = string.sub(verStr, 4, verLen)
    end
    local ver = tonumber(verStr)
    if ver == nil then
      iTrace.Error("Loong", "upgPkg verText, ver not can parse:", verStr);
    end
    ver = ver or 0
    self.svrVer = ver
    local localVer = App.VerCode
    iTrace.Log("Loong", "localVer:", localVer, ", svrVer:", ver)
    UpgPkgCtrl:Close()
    if IsNull(err) then
      if ver > localVer then
        self:Begin()
      else
        self.complete()
      end
    else
      self:Failure()
    end
  end
end

function My:Begin()
  local tip = ((self.force == 1) and "强制" or "可选")
  local sb = ObjPool.Get(StrBuffer)
  sb:Apd("获取到新版本"):Apd(self.VerName):Apd('('):Apd(tip):Apd(')')
  sb:Apd(",请前往前应用商店进行更新")
  local msg = sb:ToStr()
  ObjPool.Add(sb)

  MsgBox.ShowYesNo(msg, self.OpenMain, self, "前往", self.Cancel, self, "取消")
end

function My:OpenMain()
  if App.platform == Platform.iOS then
    AppStoreUtil.Main("1392207083")
  else
    iTrace.Log("Loong", "upgPkg android")
  end
  self:Quit()
end

function My:Failure()
  local msg = "获取版本信息失败"
  MsgBox.ShowYesNo(msg, self.Start, self, "重试", self.Quit, self, "取消")
end

function My:Cancel()
  if self.force == 0 then
    self.complete()
    iTrace.Log("Loong", "not force upgPkg")
  else
    self:Quit()
  end
end

function My:Quit()
  App.Quit()
end

function My:Clear()
  self:Reset()
end

return My
