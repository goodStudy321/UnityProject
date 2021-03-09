--region UIFlyItem.lua
--Date
--此文件由[HS]创建生成


UIFlyItem = {}
local E = UIFlyItem
local UE = UIFly.EndDelegate
E.Name = "飘道具"
E.Timing = 0
E.Interval = 0.1
E.IsFly = false
E.Target = nil
E.IdleList = {}
E.ActiveList = {}

--过滤类型
E.FiltedTypes = {};
local ftTp = E.FiltedTypes;
ftTp[7] = true; -- 天机印类型

--注册的事件回调函数

function E:New()
	return self
end

function E:Init(go)
	self.Root = go
	local trans = go.transform
	local T = TransTool.FindChild
	self.Prefab = T(trans, "ItemCell")
	for i=1,20 do
		table.insert(self.IdleList, self:GetItem())
	end
	self:AddEvent()
end

function E:GetItem()
	local go = GameObject.Instantiate(self.Prefab)
	go.transform.parent = self.Prefab.transform.parent
	go.transform.localPosition = Vector3.New(-100,0,0)
	go.transform.localScale = Vector3.one
	self:AddFlyEff(go)
	local cell = ObjPool.Get(UIItemCell)
	cell:Init(go)
	return cell
end

function E:AddEvent()
	self:SetEvent("Add")
end

function E:RemoveEvent()
	self:SetEvent("Remove")
end

function E:SetEvent(fn)
	local pMgr = PropMgr
	pMgr.eAdd[fn](pMgr.eAdd, self.OnUpNumItem, self)
	pMgr.eUpNum[fn](pMgr.eUpNum, self.OnUpdateItem, self)
	--pMgr.eAddNum[fn](pMgr.eAddNum, self.OnAddItem, self)
end

function E:Open()
	local ui = UIMgr.Dic[UIMainMenu.Name]
	if ui then
		local target = ui.BagBtn
		if target then
			self.Target = target.gameObject
		end
	end

end

function E:OnAddItem(id, num)
	if id == 0 or num == 0 then return end
	local idle = self.IdleList
	if #idle == 0 then return end
	local cell = idle[1] 
	table.remove(idle, 1)
	table.insert(self.ActiveList, cell)
	cell:UpData(id, num)
	local uifly = UIFly.AddGo("Item",  cell.trans.gameObject)
	if uifly then uifly.target = self.Target end
	self.IsFly = true
end

function E:OnUpNumItem(tb,action,tp)
	self:OnUpdateItem(tb,tp, 1)
end

function E:OnUpdateItem(tb,t, num)
	if self:FiltedType(tb) == true then return end
	if self:IsHideEff() then return end
	if not tb then return end
	if not num or num <= 0 then return end
	local idle = self.IdleList
	if #idle == 0 then return end
	local cell = idle[1] 
	table.remove(idle, 1)
	table.insert(self.ActiveList, cell)
	cell:TipData(tb)
	local uifly = UIFly.AddGo("Item", cell.trans.gameObject)
	if uifly then uifly.target = self.Target end
	self.IsFly = true
end

--是否是过滤类型
function E:FiltedType(tb)
	if tb == nil then
		return true;
	end
	local id = tostring(tb.type_id);
	local cfg = ItemData[id];
	if cfg == nil then
		return true;
	end
	local result = E.FiltedTypes[cfg.type];
	if result ~= nil then
		return true;
	end
	return false;
end

--是否过滤特效
function E:IsHideEff()
	local ui1 = UIMgr.Get(UITreasure.Name)
	local ui2 = UIMgr.Get(UIFestivalAct.Name)
	local ui3 = UIMgr.Get(UIAlchemy.Name)
	local ui4 = UIMgr.Get(UITongTianTower.Name);
	local list = {ui1, ui2, ui3, ui4}
	for i,v in pairs(list) do
		if v and v.active == 1 then
			return true
		end
	end
	return false
end

function E:AddFlyEff(go)
	local flyScale = ComTool.Add(go, UIFlyScale)
	if flyScale then
		flyScale.anchors1 = Vector3.New(300,200,0)
		flyScale.anchors2 = Vector3.New(400,-20,0)
		flyScale.targetPos = Vector3.New(0,0,0)
		flyScale.time = 0.8
		flyScale.isScale = true
		flyScale.scaleIn = 0.1
		flyScale.scaleOut = 0.4
		flyScale.isDestroy = false
		flyScale.onEndEvent = UE(self.FlyEnd, self)
	end
end

function E:FlyEnd(go)
	if LuaTool.IsNull(go) == true then return end
	go:SetActive(false)
	local active = self.ActiveList
	if #active == 0 then return end
	local cell = active[1]
	table.remove(active, 1)
	table.insert(self.IdleList, cell)
end

function E:Update()
	if not self.IsFly then return end
	if self.Timing and self.Timing == 0 then
		local list = UIFly.GetList("Item")
		if not list then self.IsFly = false return end
		if list.Count > 0 then
			local fly = list[0]
			fly:Play()
			UIFly.Remove("Item", fly)
			self.Timing = Time.realtimeSinceStartup
		elseif list.Count == 0 then
			self.IsFly = false
		end
	else
		if Time.realtimeSinceStartup - self.Timing  > self.Interval then
			self.Timing = 0
		end
	end
end

function E:Dispose()
	self:RemoveEvent()
	UIFly:Dispose("Item")
end
--endregion
