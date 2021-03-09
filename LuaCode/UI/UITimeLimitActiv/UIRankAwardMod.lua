--[[
 	authors 	:Liu
 	date    	:2019-3-19 11:00:00
 	descrition 	:限时活动界面1(左)
--]]

UIRankAwardMod = Super:New{Name="UIRankAwardMod"}

local My = UIRankAwardMod

require("UI/UITimeLimitActiv/UIRankAwardModIt")

function My:Init(root)
    local des = self.Name
    local FindC = TransTool.FindChild

    self.itList = {}

    self.item = FindC(root, "Scroll View/Grid/awardItem", des)

    self:InitAItem()
end

--初始化奖励项
function My:InitAItem()
    local Add = TransTool.AddChild
    local info = TimeLimitActivInfo
    local list = info:GetCfgList(TimeLimitRankCfg)
    local parent = self.item.transform.parent
    for i,v in ipairs(list) do
        local item = Instantiate(self.item)
        local tran = item.transform
        Add(parent, tran)
        local it = ObjPool.Get(UIRankAwardModIt)
        it:Init(tran, v)
        table.insert(self.itList, it)
    end
    self.item:SetActive(false)
    self:UpBtns()
end

--更新按钮
function My:UpBtns()
    local info = TimeLimitActivInfo
    local dic = info:GetBtnState(1)
    for i,v in ipairs(self.itList) do
        local key = tostring(v.cfg.id)
        local state = (dic) and dic[key] or nil
        v:UpBtnState(state)
    end
end

--清理缓存
function My:Clear()
    ListTool.ClearToPool(self.itList)
end
    
--释放资源
function My:Dispose()
    self:Clear()
end

return My