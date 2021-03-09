--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-07-17 14:58:45
--=========================================================================

LoadingMgr = {Name = "LoadingMgr"}

require("Lib/DelLoadTex")

local My = LoadingMgr

function My:Init()
	--k:name,v:tex,为0时:Loading
	if self.dic == nil then self.dic = {} end
	--:场景ID字符串,v:名称
	self.sDic = {}
	
	self:SetDic()
	
	self:SetCfg()
	
	if self.eLoad==nil then self.eLoad = Event() end
end



--设置场景字典
function My:SetDic()
	local sDic, sIDS, idStr = self.sDic, nil, nil
	for i, v in ipairs(LoadingBgCfg) do
		sIDS = v.sIDS
		if sIDS then
			for _, id in ipairs(sIDS) do
				idStr = tostring(id)
				if sDic[idStr] == nil then
					sDic[idStr] = v
				end
			end
		end
	end
end

--在配置条目中添加最大权重
function My:SetCfg()
	self.totalWt = 0
	local totalWt, wt = 0
	for i, v in ipairs(LoadingBgCfg) do
		totalWt = totalWt + v.wt
		v.maxWt = totalWt
	end
	self.totalWt = totalWt
end

function My:SetFirst(name)
	self.firstName = name
end

function My:GetFirst()
	do return self.dic[self.firstName] end
end

--加载回调
function My:LoadCb(tex)
	local name = tex and tex.name
	name = self:GetName(name)
	self.dic[name] = tex
	--tex.name = "lua_" .. name
	self.eLoad(tex)
	self:SetFirst(name)
	AssetMgr:SetPersist(name, true)
end

function My:GetName(name)
	if string.find(name,".jpg") then return name end
	do return name .. ".jpg" end
end

function My:Load(name,func,obj)
	local dic = self.dic
	if dic == nil then 
		dic = {}
		self.dic = dic
	end
	local tex = dic[name]
	if tex then
		if obj then 
			func(obj,tex) 
		else
			func(tex)
		end
		self:SetFirst(name)
	else
		if self.eLoad ==nil then self.eLoad = Event() end
		self.eLoad:Add(func, obj)
		AssetMgr:Load(name, ObjHandler(self.LoadCb, self))
	end
end


--加载场景背景图,
--return(bool):加载成功返回true
function My:LoadOnScene(sceneID, func, obj)
	local cfg = self.sDic[tostring(sceneID)]

	if cfg then 
		self:Load(cfg.name, func, obj)
		return true
	else
		return false
	end
end

--通过权重加载
function My:LoadByWeight(func, obj)
	local cfg = self:GetByWeight() 
	local sdkIndex = 0
	if Sdk then
		sdkIndex = Sdk:GetSdkIndex()
		-- if sdkIndex == 4 then
		-- 	cfg = LoadingBgCfg[8]
		-- elseif sdkIndex == 5 then
		-- 	cfg = LoadingBgCfg[9]
		-- elseif sdkIndex == 6 then
		-- 	cfg = LoadingBgCfg[10]
		-- elseif sdkIndex == 7 then
		-- 	cfg = LoadingBgCfg[11]
		-- elseif sdkIndex == 10 then
		-- 	cfg = LoadingBgCfg[12]
		-- elseif sdkIndex == 11 then
		-- 	cfg = LoadingBgCfg[13]
		-- end
	end
	self:Load(cfg.name, func, obj)
end

function My:Add(name,tex)
	if self.dic == nil then self.dic = {} end
	self.dic[name] = tex
end


--通过权重获取图片配置
function My:GetByWeight()
	if self.totalWt then
		local wt = math.random(1, self.totalWt)
		for i, v in ipairs(LoadingBgCfg) do
			if wt < v.maxWt then
				return v
			end
		end
	end
	do return self:GetByRandom() end
end

--获取随机配置
function My:GetByRandom()
	local idx = math.random(1, #LoadingBgCfg)
	idx = math.floor(idx)
	return LoadingBgCfg[idx]
end


--清理图片
function My:ClearTex()
	local dic = self.dic
	for k,v in pairs(dic) do
		if k ~= self.firstName then
			if v then 
				--DestroyImmediate(v)
				AssetMgr:Unload(k, false)
			end
			dic[k] = nil
		end
	end
end

function My:Preload()
	for i,v in ipairs(LoadingBgCfg) do
		AssetMgr:Add(v.name, nil)
	end
end

function My:Clear()

end

return My
