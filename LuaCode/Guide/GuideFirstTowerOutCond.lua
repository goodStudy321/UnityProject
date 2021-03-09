--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-04-10 12:01:57
--=========================================================================

GuideFirstTowerOutCond = GuideCond:New{ Name = "GuideFirstTowerOutCond" }

local My = GuideFirstTowerOutCond


function My:Init()
	CopyMgr.eFirstPassCopy:Add(self.TowerFirstOut, self)
end

function My:TowerFirstOut(id)
	self:TriggerArg(id)
end



function My:Dispose()
	CopyMgr.eFirstPassCopy:Remove(self.Success, self)
end


return My