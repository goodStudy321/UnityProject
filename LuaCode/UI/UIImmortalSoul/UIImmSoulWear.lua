--[[
 	authors 	:Liu
 	date    	:2018-11-1 14:10:00
 	descrition 	:仙魂佩戴界面
--]]

UIImmSoulWear = Super:New{Name = "UIImmSoulWear"}

local My = UIImmSoulWear

local strs = "UI/UIImmortalSoul/UIImmSoulWear/"
require(strs.."UIImmSoulWearMod1")
require(strs.."UIImmSoulWearMod2")

function My:Init(root)
	local des = self.Name
	local Find = TransTool.Find
	local mod1Tran = Find(root, "bag", des)
	local mod2Tran = Find(root, "wear", des)

	self.go = root.gameObject
	self:InitModule(mod1Tran, mod2Tran)
end

--初始化模块
function My:InitModule(mod1Tran, mod2Tran)
	self.bag = ObjPool.Get(UIImmSoulWearMod1)
	self.bag:Init(mod1Tran)
	self.wear = ObjPool.Get(UIImmSoulWearMod2)
	self.wear:Init(mod2Tran)
end

--清理缓存
function My:Clear()

end

--释放资源
function My:Dispose()
	self:Clear()
	ObjPool.Add(self.bag)
	self.bag = nil
	ObjPool.Add(self.wear)
	self.wear = nil
end

return My