--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-06-12 16:04:37
--=========================================================================

PreloadSceneEntry = Super:New{ Name = "PreloadSceneEntry" }

local My = PreloadSceneEntry


function My:Init()

end


function My:Add(sceneName)
	self.sceneName = self:GetValidName(sceneName)
	AssetMgr:Add(sceneName, ObjHandler(self.LoadCb, self))
	AssetMgr.LoadSceneCount = AssetMgr.LoadSceneCount + 1
end

function My:LoadCb(o)
	SceneTool.eSceneLoaded:Add(self.OnSceneLoaded, self)
	SceneManager.LoadScene(self.sceneName, LoadSceneMode.Additive)
end

function My:OnSceneLoaded(name)
	if name ~= self.sceneName then return end
	SceneTool.eSceneLoaded:Remove(self.OnSceneLoaded, self)
	SceneTool:SetActiveByName(name, false)
end


function My:GetValidName(sceneName)
	local beg = string.find(sceneName, ".unity")
	local sn = string.sub(sceneName, 1, beg - 1)
	do return sn end
end

function My.IsScene(name)
	local beg = string.find(name, ".unity")
	do return beg end
end


return My