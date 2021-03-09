--[[
 	authors 	:Liu
 	date    	:2018-11-1 16:10:00
 	descrition 	:仙魂属性加成界面
--]]

UIImmSouProPanel = Super:New{Name = "UIImmSouProPanel"}

local My = UIImmSouProPanel

local strs = "UI/UIImmortalSoul/UIImmSoulWear/"
require(strs.."UIImmSouProIt")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local FindC = TransTool.FindChild
    local SetB = UITool.SetBtnClick
    local str = "Scroll View/Grid"

    SetB(root, "bg/box", des, self.OnBoxClick, self)
    local grid = CG(UIGrid, root, str)
    local item = FindC(root, str.."/item", des)
    self.go = root.gameObject
    self.labList = {}
    self:InitLab(grid, item)
end

--初始化属性文本
function My:InitLab(grid, item)
    local Add = TransTool.AddChild
    local info = ImmortalSoulInfo
    local list = info:GetAllPro(info.useList)
    local gridTran = grid.transform
    for i,v in ipairs(list) do
        local go = Instantiate(item)
        local tran = go.transform
        Add(gridTran, tran)
        local it = ObjPool.Get(UIImmSouProIt)
        it:Init(tran)
        local cfg = PropName[v.type]
		if cfg == nil then return end
        local value = (cfg.show==1) and string.format("%.2f", v.val/10000*100).."%" or v.val
        it:UpLab(v.name, value)
        table.insert(self.labList, it)
    end
    item:SetActive(false)
    grid:Reposition()
end

--点击碰撞器
function My:OnBoxClick()
    self:UpShow(false)
    local it = UIImmortalSoul.mod1.wear
    it:ClearProPanel()
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

--清理缓存
function My:Clear()
    self.go = nil
end

--释放资源
function My:Dispose()
    self:Clear()
    ListTool.ClearToPool(self.labList)
end

return My