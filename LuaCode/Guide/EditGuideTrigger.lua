--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-07-29 19:42:44
-- 编辑器下触发
--=========================================================================

EditGuideTrigger = Super:New{ Name = "EditGuideTrigger" }

local My = EditGuideTrigger

----BEG PUBLIC

function My:Init()
	EventMgr.Add("E_GUIDE_TRIGGER", EventHandler(self.EditTrigger, self))
end

----END PUBLIC

function My:EditTrigger(id)
	local cfg = BinTool.Find(GuideCfg, id)
	if cfg then
		local k = tostring(cfg.ty)
		local cond = GuideCondFty.dic[k]
		cond:TriggerByCfg(cfg)
		UITip.Log("触发ID为:" .. id .. "的引导")
	else
		UITip.Error("未发现ID为:" .. id .. "的引导配置")
	end
end

My:Init()

return My