--[[
 	authors 	:Liu
 	date    	:2018-8-31 10:25:00
 	descrition 	:成就界面
--]]

UISuccess = UIBase:New{Name = "UISuccess"}

local My = UISuccess

local strs = "UI/UISuccess/"
require(strs.."UISuccessTable")
require(strs.."UISuccessMod1")
require(strs.."UISuccessMod2")
require(strs.."UISuccessMod3")

-- 重写基类的初始化方法
function My:InitCustom()
    local root, des = self.root, self.Name
    local Find, str = TransTool.Find, "Scroll View"
    local table = Find(root, str.."/Table", des)
    local module1 = Find(root, "Module1", des)
    local module2 = Find(root, "Module2", des)
    local module3 = Find(root, "Module3", des)
    UITool.SetBtnClick(root, "close", des, self.Close, self)

    self:InitModule(table, module1, module2, module3)
end

--初始化模块
function My:InitModule(table, module1, module2, module3)
    self.mod1 = ObjPool.Get(UISuccessMod1)
    self.mod1:Init(module1)
    self.mod2 = ObjPool.Get(UISuccessMod2)
    self.mod2:Init(module2)
    self.mod3 = ObjPool.Get(UISuccessMod3)
    self.mod3:Init(module3)
    self.tab = ObjPool.Get(UISuccessTable)
    self.tab:Init(table)
end

--打开分页
function My:OpenTabByIdx(t1,t2,t3,t4)
    
end

--清理缓存
function My:Clear()
    
end

--重写释放资源
function My:DisposeCustom()
    self:Clear()
    ObjPool.Add(self.tab)
    self.tab = nil
    ObjPool.Add(self.mod1)
    self.mod1 = nil
    ObjPool.Add(self.mod2)
    self.mod2 = nil
    ObjPool.Add(self.mod3)
    self.mod3 = nil
end

return My