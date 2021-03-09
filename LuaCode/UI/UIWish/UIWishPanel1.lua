--[[
 	authors 	:Liu
 	date    	:2019-1-14 17:00:00
 	descrition 	:许愿仓库
--]]

UIWishPanel1 = Super:New{Name="UIWishPanel1"}

local My = UIWishPanel1

function My:Init(root)
    local des = self.Name
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick

    self.go = root.gameObject
    self.bagTran = Find(root, "bg3", des)

    SetB(root, "CloseBtn", des, self.OnClose, self)
    
    self:InitBag()
end

--初始化寻宝背包
function My:InitBag()
    self.bag = ObjPool.Get(CellUpdate)
    self.bag:Init(self.bagTran)
    self.bag:InitData(4)
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

--点击关闭
function My:OnClose()
    self:UpShow(false)
    UIWish:UpBagAction()
end

--清理缓存
function My:Clear()
    TableTool.ClearUserData(self)
end
    
--释放资源
function My:Dispose()
    self:Clear()
    ObjPool.Add(self.bag)
    self.bag = nil
end

return My