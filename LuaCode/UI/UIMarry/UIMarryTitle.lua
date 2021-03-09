--[[
 	authors 	:Liu
 	date    	:2018-12-24 16:30:00
 	descrition 	:结婚称号界面
--]]

UIMarryTitle = Super:New{Name = "UIMarryTitle"}

local My = UIMarryTitle

require("UI/UIMarry/UIMarryTitleIt")

function My:Init(root)
    local des = self.Name
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    local item = FindC(root, "Scroll View/Grid/item", des)

    self.itList = {}

    SetB(root, "close", des, self.OnClose, self)

    self:InitItem(item)
end

--初始化称号项
function My:InitItem(item)
    local Add = TransTool.AddChild
    local parent = item.transform.parent
    for i,v in ipairs(MarryTitleCfg) do
        local go = Instantiate(item)
        local tran = go.transform
        Add(parent, tran)
        local it = ObjPool.Get(UIMarryTitleIt)
        it:Init(tran, v)
        table.insert(self.itList, it)
    end
    item:SetActive(false)
end

--获取称号进度
function My:GetTitleProg()
    local isCfg = false
    -- local tId = MarryInfo.data.titleId
    for i,v in ipairs(self.itList) do
        if v.progVal < 100 then
            return v
        end
    end
    if not isCfg then
        return self.itList[#self.itList]
    end
end

--点击关闭
function My:OnClose()
    UIMarry:SetMenuState(1)
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