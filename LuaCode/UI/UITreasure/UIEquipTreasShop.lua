--[[
 	authors 	:Liu
 	date    	:2018-7-4 17:00:00
 	descrition 	:装备寻宝商城
--]]

UIEquipTreasShop = Super:New{Name="UIEquipTreasShop"}

local My = UIEquipTreasShop

require("UI/UITreasure/UIEquipTreasShopIt")

function My:Init(root, index)
    local des = self.Name
    local item = TransTool.FindChild(root, "Scroll View/Grid/sotreItem")
    self.go = root.gameObject
    self.isOpen = false
    self.itDic = {}
    self.index = index
    self.scoreLab = ComTool.Get(UILabel, root, "scoreLab/lab")
    UITool.SetBtnClick(root, "close", des, self.Hide, self)
    self:InitShopItem(item)
end

--初始化商城项
function My:InitShopItem(item)
    local Add = TransTool.AddChild
    local parent = item.transform.parent
    for k,v in pairs(StoreData) do
        local index = (self.index == TreasureInfo.equip) and 7 or 12
        if v.storeTp == index then
            local go = Instantiate(item)
            local tran = go.transform
            go.name = 100000 + v.curPrice
            Add(parent, tran)
            local it = ObjPool.Get(UIEquipTreasShopIt)
            it:Init(tran, v)
            self.itDic[v.PropId] = it
        end
    end
    item:SetActive(false)
end

--更新积分
function My:UpScoreLab(score)
    self.scoreLab.text = score
end

--显示界面
function My:Show()
    self:SetState(true, true)
    self:UpScoreLab(RoleAssets.HontInteg)
end

--隐藏界面
function My:Hide()
    self:SetState(false, false)
    local it = UITreasure
    if it.equip then
        it.equip:UpModelShow(true)
    end
    if it.top then
        it.top:UpModelShow(true)
    end
end

--设置面板状态
function My:SetState(state1, state2)
    self.go:SetActive(state1)
    self.isOpen = state2
end

--清理缓存
function My:Clear()
    self.isOpen = false
    TableTool.ClearUserData(self)
end
    
--释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearDicToPool(self.itDic)
end

return My