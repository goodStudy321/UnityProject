--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-04-11 20:06:42
-- 进入时处理预加载
--=========================================================================

PreloadEntry = Super:New{ Name = "PreloadEntry" }

local My = PreloadEntry


function My:Init()
	PreloadMgr.eExecute:Add(self.Start, self)
end

function My:Start()
	PreloadMgr.eExecute:Remove(self.Start, self)
	AssetTool.eComplete:Add(self.Complete,self)
	LoadingMgr:Preload()
	local IsPrefab = PreloadPrefab.IsPrefab
	local IsScene = PreloadSceneEntry.IsScene
	for k, v in pairs(PreloadEntryCfg) do
		if IsPrefab(k) then
			AssetMgr:Add(k, ObjHandler(My.PrefabCb))
		elseif IsScene(k) then
			local sn = PreloadSceneEntry:New()
			sn:Add(k)
		else
			AssetMgr:Add(k, nil)
		end
	end

	--加载第一个场景
	local sceneCfg = SceneTemp["10000"]
	if sceneCfg then
		AssetMgr:Add(sceneCfg.res, ".unity", nil)
		AssetMgr.LoadSceneCount = 1
	end
end

function My.PrefabCb(obj)
	local fullName = obj.name .. ".prefab"
	local cfg = PreloadEntryCfg[fullName]
	local num = (cfg and cfg.num or 1)
	for i = 1, num do
		PreloadPrefab.AddPool(obj)
	end
	
	local pst = (cfg and cfg.pst or 0)
	if pst > 0 then GbjPool:SetPersist(obj.name, true) end
end


function My:Complete()
	AssetTool.eComplete:Remove(self.Complete,self)
	local pst ,IsPrefab= PreloadPrefab.IsPrefab 
	for k, v in pairs(PreloadEntryCfg) do
		pst = v.pst or 0
		if pst > 0 then
			AssetMgr:SetPersist(k, true)
		end
	end
end



return My