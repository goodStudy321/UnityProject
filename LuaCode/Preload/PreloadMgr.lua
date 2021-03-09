--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-10-23 12:19:45
-- 预加载管理
--=========================================================================

require("Preload/PreloadPrefab")
require("Preload/PreloadEntry")
require("Preload/PreloadSceneEntry")

PreloadMgr = {Name = "PreloadMgr"}


local My = PreloadMgr
My.eExecute = Event()

function My.Init()
	PreloadEntry:Init()
	SceneMgr.ePreload:Add(My.PreloadLv)
  	EventMgr.Add("ExePreload", My.Execute)
end

function My.Execute()
	My.eExecute()
  	PreloadPrefab.Execute()
end

function My.PreloadLv()
	local lv = UserMgr:GetRealLv()
	local IsPrefab = PreloadPrefab.IsPrefab
	local cb = PreloadPrefab.AddPool
	for k,v in pairs(PreloadLvCfg) do
		if lv <= v.lv then
			if IsPrefab(k) then
				AssetMgr:Add(k, ObjHandler(cb))
			else
				AssetMgr:Add(k, nil)
			end
		end
	end
end

function My.Clear()

end

function My.Dispose()

end
