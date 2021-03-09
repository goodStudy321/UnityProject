--[[
 	authors 	:Liu
 	date    	:2018-7-25 09:45:00
 	descrition 	:开服活动界面
--]]

UIRankMenu = Super:New{Name = "UIRankMenu"}

local My = UIRankMenu

local strs = "UI/UIRankActiv/"
require(strs.."UIRankMenuIt1")
require(strs.."UIRankMenuIt2")

function My:Init(root)
    local des, Find = self.Name, TransTool.Find
    local mod1Tran = Find(root, "module1", des)
    local mod2Tran = Find(root, "module2", des)
    self:InitModule(mod1Tran, mod2Tran)
end

--初始化模块
function My:InitModule(mod1Tran, mod2Tran)
    self.module1 = ObjPool.Get(UIRankMenuIt1)
    self.module1:Init(mod1Tran)
    self.module2 = ObjPool.Get(UIRankMenuIt2)
    self.module2:Init(mod2Tran)
end

--清理缓存
function My:Clear()
	
end
    
--释放资源
function My:Dispose()
    self:Clear()
    ObjPool.Add(self.module1)
    self.module1 = nil
    ObjPool.Add(self.module2)
    self.module2 = nil
end

return My