--[[
 	authors 	:Liu
 	date    	:2018-11-7 17:10:00
 	descrition 	:仙魂合成界面（选择弹窗）
--]]

UIImmSoulCompPop = Super:New{Name = "UIImmSoulCompPop"}

local My = UIImmSoulCompPop

local strs = "UI/UIImmortalSoul/UIImmSoulComp/"
require(strs.."UIImmSoulCompPopIt")

function My:Init(root)
    local des = self.Name
    local Find = TransTool.Find
    local FindC = TransTool.FindChild
    local SetB = UITool.SetBtnClick
    local str = "Pop/cellBg/Scroll View/Grid"

    local grid = Find(root, str, des)
    local item = FindC(root, str.."/item", des)
    SetB(root, "Pop/close", des, self.OnClose, self)
    SetB(root, "Pop/selectBtn", des, self.OnSelect, self)
    self.go = root.gameObject
    self.cellNum = 100
    self.itList = {}
    self:InitCell(grid, item)
end

--点击关闭按钮
function My:OnClose()
    self:UpShow(false)
end

--点击选择按钮
function My:OnSelect()
    for i,v in ipairs(self.itList) do
        if v.cfg and v.tog.value then
            local num1 = (self.index == 1) and v.cellId or 0
            local num2 = (self.index == 3) and v.cellId or 0
            UIImmortalSoul.mod2.compShow:SetCompIndex(num1, num2)
            self:UpShow(false)
            break
        end
    end
end

--更新弹窗背包
function My:SetPopBag()
    self:ResetPopBag()
    local info = ImmortalSoulInfo
    local list = info:GetIdList(self.id)
	for i,v in ipairs(list) do
        self:UpPopBag(v)
        if i == 1 then
            self.itList[i]:SetTog()
        end
    end
    local equipCfg = info:GetId(self.id)
    if equipCfg ~= nil then
        self:UpPopBag(equipCfg)
    end
end

--更新弹窗背包
function My:UpPopBag(v)
    local baseCfg = ImmSoulCfg
    local key1 = tostring(v.soulId)
    local lvCfg, temp = BinTool.Find(ImmSoulLvCfg, v.lvId)
    if baseCfg[key1] and lvCfg then
        local index = self:IsCell()
        if index == nil then return end
        self.itList[index]:SetData(lvCfg, baseCfg[key1].icon, v.index)
    end
end

--判断是否是空格子
function My:IsCell()
	for i,v in ipairs(self.itList) do
		if v.cfg == nil then
			return i
		end
	end
	return nil
end

--刷新弹窗背包
function My:ResetPopBag()
	for i,v in ipairs(self.itList) do
		v:UpIcon(false)
		v:ClearCfg()
    end
end

--初始化格子
function My:InitCell(grid, item)
    local Add = TransTool.AddChild
    for i=1, self.cellNum do
        local go = Instantiate(item)
        local tran = go.transform
        go:SetActive(true)
        Add(grid, tran)
        local it = ObjPool.Get(UIImmSoulCompPopIt)
        it:Init(tran)
        it:ChangeName(i)
        table.insert(self.itList, it)
    end
    item:SetActive(false)
    grid:GetComponent(typeof(UIGrid)):Reposition()
end

--更新显示
function My:UpShow(state, id, index)
    if id ~= nil then
        self.id = id
        self.index = index
    end
    self.go:SetActive(state)
    if state then
        self:SetPopBag()
    end
end

--清理缓存
function My:Clear()

end

--释放资源
function My:Dispose()
    self:Clear()
    ListTool.ClearToPool(self.itList)
end

return My