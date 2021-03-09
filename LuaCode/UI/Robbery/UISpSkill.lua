require("UI/Robbery/UISpSkillItem")

UISpSkill = Super:New {Name = "UISpSkill"}

local My = UISpSkill
local USI = UISpSkillItem

--技能条目列表
My.items = {}

function My:Ctor()
	--技能条目列表
	--self.items = {}
end

function My:Init(root)
	self.root = root
	self.gbj = root.gameObject
	local des = self.Name
	--icon模板
	self.mod = TransTool.FindChild(root, "icon", des)
	--ui表(UITable)
	self.uiTbl = ComTool.Get(UITable, root, "Table", des)
	self.mod:SetActive(false)
end

--清理Icon
function My:Clear()
	ListTool.ClearToPool(self.items)
end

--设置技能条目
function My:SetItems()
	-- self:Clear()
	local mod = self.mod
	local ids = self.ids
	local items = self.items
	local tblTran = self.uiTbl.transform
	TransTool.RenameChildren(tblTran)
	local Inst = GameObject.Instantiate
	local TA = TransTool.AddChild
	local GL, obj = self.GetLock, self.srcObj
	for i = 1, #ids do
		local id = ids[i]
		local it = ObjPool.Get(USI)
		local go = nil
		local goTran = tblTran:Find("none")
		if goTran then
			go = goTran.gameObject
		else
			go = Inst(mod)
			goTran = go.transform
		end
		TA(tblTran, goTran)
		items[#items + 1] = it
		go:SetActive(true)
		it:Init(goTran, id, self)
		local lt = nil
		if obj == nil then
			lt = GL(id)
		else
			lt = GL(obj, id)
		end
		it:Lock(lt)
	end
	self.uiTbl.repositionNow = true
end

--刷新
--ids:如果新的ID列表和当前列表数量不同 就重新设置技能条目
--GetLock(获取锁定的方法)
function My:Refresh(ids, GetLock, obj)
	if ids == nil then return end
	if GetLock == nil then return end
	self.srcObj = obj
	self.GetLock = GetLock
	local sids = self.ids
	-- TableTool.ClearDicToPool(self.items)
	if (sids == nil) or (#ids ~= #sids) then
		self.ids = ids
		self:SetItems()
	else
		for i, v in ipairs(self.items) do
			local id, lt = ids[i], nil
			if obj == nil then
				lt = GetLock(id)
			else
				lt = GetLock(obj, id)
            end
			v:Refresh(lt, id)
		end
	end
end

--显示提示
function My:Switch(it)
	if not it then return end
	UIRobbery.skiTip:Show(it)
end

--清除技能texture
function My:ClearIcon()
	if self.items then
	  for k,v in pairs(self.items) do
		v:ClearIcon()
	  end
	end
end

--将item放入对象池
function My:ItemToPool()
	for k,v in pairs(self.items) do
		local item = v
		GameObject.Destroy(item.root.gameObject)
		ObjPool.Add(item)
		self.items[k] = nil
	end
	-- local len = #self.items
	-- while len > 0 do
	-- 	local item = self.items[len]
	-- 	if item then
	-- 		table.remove(self.items, len)
	-- 		ObjPool.Add(item)
	-- 	end
	-- 	len = #self.items
	-- end
end

function My:Open()
	self.gbj:SetActive(true)
end

function My:Close()
	self.gbj:SetActive(false)
	self:ClearIcon()
end

function My:Dispose()
	self.ids = nil
	self.srcObj = nil
	self.GetLock = nil
	self:ClearIcon()
	self:ItemToPool()
end

return My
