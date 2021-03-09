--设备信息扩展
DeviceEx = {Name = "DeviceEx"}

local My = DeviceEx

--刘海宽带
My.liuHaiWd = 58

function My:Init()
  --true:刘海屏
  self.isLiuHai = false
  self:SetLiuhai()
end

function My:GetLiuHaiIos()
  local ht = User.oriScreenHt --Screen.height
  local wd = User.oriScreenWd --Screen.width
  if wd == 2436 and ht == 1125 then return true end
  if wd == 2688 and ht == 1242 then return true end
  if wd == 1792 and ht == 828 then return true end
  if wd == 1792 and ht == 827 then return true end
  do return false end
end

function My:SetLiuhai()
  local pt = App.platform
  if pt == Platform.iOS then
    self.isLiuHai = self:GetLiuHaiIos()
    Device.IsLiuHai = self.isLiuHai
  elseif pt == Platform.Android then
    self.isLiuHai = Device.IsLiuHai
  end
  -- if App.isEditor == true then
  --    self.isLiuHai = true
  --    Device.IsLiuHai = self.isLiuHai
  -- end
  if App.IsDebug then
    iTrace.Log("Loong", "isLiuHai:", self.isLiuHai, " , ", Screen.height, "*", Screen.width)
  end
end

function My:GetIMEI()
  return Device.Instance.IMEI
end

function My:Clear()

end

return My
