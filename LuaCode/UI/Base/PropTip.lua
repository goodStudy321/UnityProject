--[[
道具Tip
]]
require("UI/Base/PropTipBase")
require("UI/UIBackpack/Deal")
PropTip=UIBase:New{Name="PropTip"}
local My=PropTip
My.pos=nil
My.isInWarehouse = false

function My:InitCustom()
	if not self.list then self.list={} end
	
	self.C=TransTool.FindChild(self.root,"C")
	self.panel=self.root:GetComponent(typeof(UIPanel))
end

--传入参数为tb或者type_id
function My:UpData(obj)
	local go =GameObject.Instantiate(self.C)
	go.transform.parent=self.root
	go.transform.localPosition=Vector3.zero
	go.transform.localScale=Vector3.one
	local tg = ObjPool.Get(PropTipBase)
	tg:InitCustom(go,My.pos)
	tg:UpData(obj)
	table.insert(self.list,tg)
	local depth = self.panel.depth+#self.list*3
	--tg.panel.depth=depth
	UITool.Sort(go,depth,1)
	tg.eClose:Add(self.OnClose,self)
end

function My:ShowBtn(btnList)
	local tg=self.list[#self.list]
	if tg then tg:ShowBtn(btnList) end
end

function My:OnClose()
	if #self.list==0 then return end
	local max = self.list[#self.list]
	max:Dispose()
	self.list[#self.list]=nil
	if #self.list==0 then self:Close() end
end

function My:DisposeCustom()
	My.isInWarehouse = false
	ListTool.ClearToPool(self.list)
end

return My