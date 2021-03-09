--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-05-24 16:13:18
-- BOSS副本玩家首次受伤
--=========================================================================

GuideBossCopyFirstHit = GuideCond:New{ Name = "GuideBossCopyFirstHit" }

local My = GuideBossCopyFirstHit


function My:Init()
	UIWBAtkList.ePlayerBeHarm:Add(self.BossFirstHit, self)
end


function My:SetCfg(cfg)
	if cfg == nil then return end
	if self.cfg then
		if (self.cfg.id ~= cfg.id) then
			--iTrace.Error("Loong","世界BOSS玩家首次受击配置多次,请检查配置:",self.cfg.id, "和",cfg.id)
		end
	else
		self.cfg = cfg
	end
end

function My:BossFirstHit()
	UIWBAtkList.ePlayerBeHarm:Remove(self.BossFirstHit, self)
	self.success(self, self.cfg)
end

function My:TriggerByCfg(cfg)
  self.success(self, cfg)
end


function My:Dispose()
	UIWBAtkList.ePlayerBeHarm:Remove(self.BossFirstHit, self)
end


return My