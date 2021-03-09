--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-04-09 00:55:21
-- 推送通知设置
--=========================================================================

UISettingPush = Super:New{ Name = "UISettingPush" }
local Item = require("UI/Setting/UISettingPushItem")

local My = UISettingPush


--UISettingPushItem列表
My.items = {}

function My:Init(root)
	self.root = root
	local des = self.Name
	local CG = ComTool.Get
	local TFC = TransTool.FindChild
	self.uiTbl = CG(UITable, root, "Scroll/tbl", des)
	self.itMod = TFC(root, "Scroll/item", des)
	self.itMod:SetActive(false)
	self:SetItems()
end

--设置条目列表
function My:SetItems()
	local uiTbl,mod = self.uiTbl, self.itMod
	local tblTran = uiTbl.transform
	local AddChild = TransTool.AddChild
	local items = self.items
	for i,v in ipairs(PushCfg) do
		--if v.at == 1 then
			local go = Instantiate(mod)
			local tran = go.transform
			AddChild(tblTran, tran)
			local it = ObjPool.Get(Item)
			go:SetActive(true)
			it.cntr = self
			it:Init(tran, v)
			go.name = tostring(v.id)
			items[#items + 1] = it
		--end
	end
end

function My:OnTogChange(cfg, value)
	local str = ((value == true) and "成功开启" or "成功关闭")
	PushMgr:Save(cfg, value)
	UITip.Log(str)
end


--设置条目
function My:SetItem(tran, cfg)
	
end


function My:Update()

end


function My:Dispose()
	ListTool.ClearToPool(self.items)
end


return My