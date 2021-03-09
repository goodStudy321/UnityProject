--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-06-12 21:07:30
--=========================================================================

SceneTool = Super:New{ Name = "SceneTool" }

local My = SceneTool


function My:Init()
	--参数场景名称
	self.eSceneLoaded = Event()
	EventMgr.Add("OnSceneLoaded", EventHandler(self.OnSceneLoaded,self))
end

function My:OnSceneLoaded(name)
	self.eSceneLoaded(name)
end

function My:Switch(name)
	local len = SceneManager.sceneCount - 1
	for i=0,len do
		local scene = SceneManager.GetSceneAt(i)
		if scene.name == name then
			SceneManager.SetActiveScene(scene)
			self:SetActive(scene, true)
		else
			self:SetActive(scene, false)
		end
	end
end

function My:SetActive(scene, active)
	if (not scene:IsValid()) then return end
	local gos = scene:GetRootGameObjects()
	local len = gos.Length - 1
	for i=0,len do
		gos[i]:SetActive(active)
	end
end

function My:SetActiveByName(name,active)
	local scene = SceneManager.GetSceneByName(name)
	self:SetActive(scene,active)
end


return My