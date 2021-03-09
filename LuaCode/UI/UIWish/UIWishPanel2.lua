--[[
 	authors 	:Liu
 	date    	:2019-1-14 12:00:00
 	descrition 	:积分兑换
--]]

UIWishPanel2 = Super:New{Name = "UIWishPanel2"}

local My = UIWishPanel2

require("UI/UIWish/UIWishScoreIt")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild
    local str = "Scroll View/Grid"

    self.itList = {}
    self.go = root.gameObject
    self.lab1 = CG(UILabel, root, "lab1")
    self.grid = CG(UIGrid, root, str)
    self.item = FindC(root, str.."/item", des)

    SetB(root, "close", des, self.OnClose, self)
end

--更新数据
function My:UpdateData(data, isOpen)
    self.data = data
    self.isOpen = isOpen
    self:UpScoreLab()
    self:InitItems()
end

--初始化积分奖励项
function My:InitItems()
    local itemData = (self.isOpen) and self.data or self.data.itemList
    if itemData == nil then return end
    local Add = TransTool.AddChild
    local parent = self.item.transform.parent
    for i,v in ipairs(itemData) do
        local go = Instantiate(self.item)
        local tran = go.transform
        Add(parent, tran)
        local it = ObjPool.Get(UIWishScoreIt)
        self:InitBtnState(it, v)
        it:Init(tran, v, self.isOpen)
        table.insert(self.itList, it)
    end
    self.item:SetActive(false)
    self:Reposition()
end

--初始化按钮状态
function My:InitBtnState(it, v)
    if not self.isOpen then return end
    local info = TimeLimitActivInfo
    local dic = info:GetBtnData(info.wishType)
    local key = tostring(v.id)
    local state = (dic) and dic[key] or 1
    it:UpState(state)
end

--更新按钮状态
function My:UpBtnState()
    if not self.isOpen then return end
    local info = TimeLimitActivInfo
    local dic = info:GetBtnData(info.wishType)
    if dic == nil then return end
    for i,v in ipairs(self.itList) do
        if v.state ~= 2 and v.state ~= 3 then
            if info.score >= v.cfg.score then
                local key = tostring(v.cfg.id)
                dic[key] = 2
                v:UpState(dic[key])
                v:UpBtnState()
            end
        end
    end
end

--刷新排序
function My:Reposition()
    self.grid:Reposition()
end

--初始化积分文本
function My:UpScoreLab()
    local val = (self.isOpen) and TimeLimitActivInfo.score or UIWish.data.integral
    self.lab1.text = val
end

--点击关闭
function My:OnClose()
    self:UpShow(false)
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

--清理缓存
function My:Clear()
    
end
    
--释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearDicToPool(self.itList)
    self.itList = nil
end
    
return My