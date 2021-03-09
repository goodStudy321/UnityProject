--[[
 	authors 	:Liu
 	date    	:2018-11-1 14:10:00
 	descrition 	:仙魂合成界面
--]]

UIImmSoulComp = Super:New{Name = "UIImmSoulComp"}

local My = UIImmSoulComp

local strs = "UI/UIImmortalSoul/UIImmSoulComp/"
require(strs.."UIImmSoulCompMod1")
require(strs.."UIImmSoulCompMod2")
require(strs.."UIImmSoulCompPop")

function My:Init(root)
	local des = self.Name
	local Find = TransTool.Find
	local SetB = UITool.SetBtnClick
	
	local mod1Tran = Find(root, "bg1", des)
	local mod2Tran = Find(root, "bg2", des)
	local PopPanel = Find(root, "PopPanel", des)
	SetB(root, "btn", des, self.OnComp, self)
	self.go = root.gameObject
	self:InitModule(mod1Tran, mod2Tran, PopPanel)
end

--点击合成按钮
function My:OnComp()
	local info = ImmortalSoulInfo
	local mgr = ImmortalSoulMgr
	local it = self.compShow
	local list = {}
	if it.index1 == 0 and it.index2 == 0 then
		if info.stone < it.count then
			UITip.Log("材料不足")
			return
		end
		-- iTrace.Error("i1 = "..it.index1.." i2 = "..it.index2.." compId = "..it.compId)
		mgr:ReqSoulComp(it.compId, list)
	elseif it.index1 ~= 0 and it.index2 ~= 0 then
		local id1 = self:GetCompIndex(it.index1)
		local id2 = self:GetCompIndex(it.index2)
		if id1 == 0 or id2 == 0 or info.stone < it.count then
			UITip.Log("材料不足")
			return
		end
		table.insert(list, id1)
		table.insert(list, id2)
		-- iTrace.Error("i111 = "..id1.." i222 = "..id2.." compIdIDID = "..it.compId)
		mgr:ReqSoulComp(it.compId, list)
	end
end

--获取合成所需的道具索引
function My:GetCompIndex(index)
	local info = ImmortalSoulInfo
	local list = info:GetIdList(index)
	if #list > 0 then
		for i,v in ipairs(list) do
			return v.index
		end
	end
	local it = info:GetId(index)
	if it then
		return it.index
	end
	if index > 999 then return 0 end
	return index
end

--初始化模块
function My:InitModule(mod1Tran, mod2Tran, PopPanel)
	self.compList = ObjPool.Get(UIImmSoulCompMod2)
	self.compList:Init(mod2Tran)
	self.pop = ObjPool.Get(UIImmSoulCompPop)
	self.pop:Init(PopPanel)
	self.compShow = ObjPool.Get(UIImmSoulCompMod1)
	self.compShow:Init(mod1Tran)
end

--清理缓存
function My:Clear()

end

--释放资源
function My:Dispose()
	self:Clear()
	ObjPool.Add(self.compShow)
	self.compShow = nil
	ObjPool.Add(self.compList)
	self.compList = nil
	ObjPool.Add(self.pop)
	self.pop = nil
end

return My