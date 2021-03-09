--[[
 	authors 	:Liu
 	date    	:2018-11-2 14:10:00
 	descrition 	:仙魂合成界面（合成列表）
--]]

UIImmSoulCompMod2 = Super:New{Name = "UIImmSoulCompMod2"}

local My = UIImmSoulCompMod2

local strs = "UI/UIImmortalSoul/UIImmSoulComp/"
require(strs.."UIImmSoulCompTogs")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local FindC = TransTool.FindChild
    
    local item = FindC(root, "Scroll View/Table/item", des)
    self.panel = CG(UIPanel, root, "Scroll View")
    self.yPos = self.panel.transform.localPosition.y
    self.itList = {}
    self:InitTogs(item)
end

--初始化所有Tog
function My:InitTogs(item)
    local Add = TransTool.AddChild
    local parent = item.transform.parent
    local info = ImmortalSoulInfo
    for i,v in ipairs(info.compList) do
        local go = Instantiate(item)
        local tran = go.transform
        go.name = "tog"..i
        go:SetActive(true)
        Add(parent, tran)
        local it = ObjPool.Get(UIImmSoulCompTogs)
        it:Init(tran, v, i)
        table.insert(self.itList, it)
    end
    item:SetActive(false)
end

--设置分页
function My:SetTab(num1, num2)
    local it = self.itList[num1]
    if it then
        it:OpenTab(num2)
    end
end

--重置Panel偏移
function My:ResetOffset()
    local tran = self.panel.transform
    tran.localPosition = Vector3.New(tran.localPosition.x, self.yPos, 0)
    self.panel.clipOffset = Vector2.zero
end

--清理缓存
function My:Clear()
	
end

--释放资源
function My:Dispose()
    self:Clear()
    ListTool.ClearToPool(self.itList)
    self:ResetOffset()
end

return My