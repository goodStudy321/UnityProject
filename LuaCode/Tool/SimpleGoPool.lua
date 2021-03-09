--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-09-11 10:37:54
--=========================================================================

SimpleGoPool = Super:New{ Name = "SimpleGoPool" }

local My = SimpleGoPool

----BEG PUBLIC

function My:Init(root)
	self.root = root
end

function My:Add(go)
	local c = go.transform
	c.parent = self.root
	go:SetActive(false)
end

function My:Get(name)
	local c = self.root:Find(name)
	return (c and c.gameObject or nil)
end

----END PUBLIC



function My:Dispose()
	local p, c= self.root
	local count = root.childCount - 1
	for i=0, count do
		c = p:GetChild(i)
		AssetMgr:Unload(c.name, ".prefab", false)
	end
end


return My