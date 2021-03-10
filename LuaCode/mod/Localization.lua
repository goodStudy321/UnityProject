--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019/11/7 下午4:07:42
-- 本地化
--=============================================================================


Localization = { Name = "Localization" }

local My = Localization
local LCfg = LocalCfg

--本地化发生改变事件
My.changed = Event()


----BEG PUBLIC

--获取内容
function My.GetDes(id)
    local cfg = BinTool.Find(LCfg, id)
    if cfg then
        --return cfg.lDes
        return cfg.des
    end
    return "No cfg for " .. tostring(id)
end

--获取格式化内容
function My.FmtDes(id, ...)
    local fmt = My.GetDes(id)
    return string.format(fmt , ...)
end

function My.GetCfg(id)
    local cfg = BinTool.Find(LCfg, id)
    return cfg
end

--获取后台语言参数
--post(bool):true:代表post方式
function My.GetWebLang(post)
    post = post or false
    do return (post and "kr" or "&lang=kr") end
end


--全局获取内容方法
Local_GetDes = My.GetDes
--全局获取格式化内容
Local_FmtDes = My.FmtDes
--全局获取配置方法
Local_GetCfg = My.GetCfg
--全局获取后台语言参数
Local_GetLangCfg = My.GetWebLang

----END PUBLIC



return My