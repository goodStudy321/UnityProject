--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 9/23/2018, 12:17:43 AM
--=============================================================================

AppStoreUtil = {Name="AppStoreUtil"}

local My = AppStoreUtil


function My.GetURL(id)
    local sb = ObjPool.Get(StrBuffer)
    sb:Apd("itms-apps://itunes.apple.com/cn/app/id")
    sb:Apd(id):Apd("?mt=8")
    local url = sb:ToStr()
    ObjPool.Add(sb)
    do return url end
end

function My.Main(id)
    local url = My.GetURL(id)
    UApp.OpenURL(url)
end


function My:Evaluate(id)
    local url = My.GetURL(id)
    local full = url .. "?&action=write-review"
    UApp.OpenURL(full)
end

return My