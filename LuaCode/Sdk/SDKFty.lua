--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-05-22 20:53:45
--=========================================================================

SDKFty = {Name = "SDKFty"}

SdkType = {Name = "SdkType", None = 0, JH = 3, IQIYI = 2, DinTuo=17, XianLing=20,HanGuo=25,ZhangChuang = 33}


local My = SDKFty
function My:Init()
  self:Create()
end

function My:Create()
  local plat = App.platform
  if plat == 0 then
   return 
  end
  if CS_Sdk == nil then return end
  local id = CS_Sdk.ID
  if plat == Platform.Android then
    if id == SdkType.JH then
      require("Sdk/A_JHSdk")
    elseif id == SdkType.DinTuo then
      require("Sdk/SdkAndDinTuo")
    elseif id == SdkType.XianLing then
      require("Sdk/SdkAndXianLing")
    elseif id == SdkType.ZhangChuang then
      require("Sdk/SdkAndZhangChuang")
    end
  elseif plat == Platform.iOS then
    if id == SdkType.JH then
      require("Sdk/JH_IOS_Sdk")
    elseif id == SdkType.IQIYI then
      require("Sdk/IQIYI_IOS_Sdk")
    end
  end
  if Sdk then
    Sdk.ID = id
    Sdk:Init()
    iTrace.Log("Loong", "Sdk.ID:", Sdk.ID)
  end
end


function My:Clear()
  if Sdk then Sdk:Clear() end
end


return My
