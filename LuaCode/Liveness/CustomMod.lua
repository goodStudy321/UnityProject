--[[
 	authors 	:Liu
 	date    	:2019-6-26 11:30:00
 	descrition 	:自定义模块
--]]

CustomMod = Super:New{Name = "CustomMod"}

local My = CustomMod

--设置Tog
function My:SetTog(item, strDic, actionDic, togDic)
	if item == nil or strDic == nil then return end
	if actionDic == nil or togDic == nil then return end
    local CG = ComTool.Get
    local CGS = ComTool.GetSelf
    local Add = TransTool.AddChild
    local FindC = TransTool.FindChild
    local parent = item.transform.parent
    for k,v in pairs(strDic) do
        local go = Instantiate(item)
		local tran = go.transform
		go:SetActive(true)
        go.name = k
        local red = FindC(tran, "Action", self.Name)
        local lab1 = CG(UILabel, tran, "Background/Label")
        local lab2 = CG(UILabel, tran, "Checkmark/Label")
        local tog = CGS(UIToggle, tran, self.Name)
        lab1.text = v
        lab2.text = v
        Add(parent, tran)
        actionDic[k] = red
        togDic[k] = tog
    end
end

--设置Tog方法
function My:SetTogFunc(togDic, func, obj)
	if togDic == nil then return end
	local SetS = UITool.SetLsnrSelf
	for k,v in pairs(togDic) do
		SetS(v.transform, obj[func], obj, obj.Name)
	end
end

--更新显示模块
function My:UpShowMod(key, modDic)
	if modDic == nil then return end
	for k,v in pairs(modDic) do
		if tostring(key) == k then
			v:UpShow(true)
		else
			v:UpShow(false)
		end
	end
end

--是否能打开界面
function My:GetOpenIndex(index, togDic)
	if togDic == nil then return nil end
	local key = tostring(index)
	local num = (togDic[key]) and key or -1
	return num
end

--初始化Tog状态
function My:InitTogState(index, togDic, modInfoDic, val)
	if togDic == nil then return end
	local key = tostring(index)
	local tabId = val or self:GetModIndex(modInfoDic)
	local num = (index and togDic[key]) and key or tabId
	if togDic[num] then
		togDic[num].value = true
	end
end

--获取开启的模块索引
function My:GetModIndex(modInfoDic)
	local list = {}
	for k,v in pairs(modInfoDic) do
		table.insert(list, tonumber(k))
	end
	table.sort(list, function(a,b) return a < b end)
	return tostring(list[1]) or nil
end

--初始化模块信息
function My:InitModInfo(key, modDic, modInfoDic)
	if modDic == nil or modInfoDic == nil then return end
	if modDic[tostring(key)] == nil then
		local info = modInfoDic[tostring(key)]
		if info == nil then return end
		self:SetModInfo(info.tran, info.obj, key, modDic)
	end
end

--设置模块信息
function My:SetModInfo(tran, class, key, modDic)
	if modDic == nil then return end
	local mod = ObjPool.Get(class)
	mod:Init(tran)
	modDic[tostring(key)] = mod
end

--获取模块信息
function My:GetModInfo(tran, class)
    local info = {}
    info.tran = tran
    info.obj = class
    return info
end

----------------------------------------------------------------

--初始化模块项
function My:InitItems(cfgList, item, grid, saveList, class)
	if cfgList == nil or saveList == nil or class == nil then return end
	local Add = TransTool.AddChild

	if type(cfgList) == "number" then
		for i=1, cfgList do
			self:SetItems(item, grid, saveList, class, Add, nil)
		end
	else
		for i,v in ipairs(cfgList) do
			self:SetItems(item, grid, saveList, class, Add, v)
		end
	end
    -- grid:Reposition()
end

--设置模块项
function My:SetItems(item, grid, saveList, class, Add, v)
	local go = Instantiate(item)
	local tran = go.transform
	go:SetActive(true)
	Add(grid.transform, tran)
	local it = ObjPool.Get(class)
	it:Init(tran, v)
	table.insert(saveList, it)
end

return My