
UIEvrPayBtn = Super:New{Name = "UIEvrPayBtn"}
local My = UIEvrPayBtn

local Info = require("Data/OpenService/EvrDayInfo")

function  My:Init(root)
    self.red = ComTool.Get(UISprite, root, "Action")
    UITool.SetBtnSelf(root, self.OnClick, self, self.Name)
    self:SetLnsr("Add")
    self:InitRedState()
end

function My:SetLnsr(func)
    EvrDayMgr.eDayInfo[func](EvrDayMgr.eDayInfo, self.RespDayInfo, self)
    EvrDayMgr.eGetReward[func](EvrDayMgr.eGetReward, self.RespGetAward, self)
    EvrDayMgr.eGetCountReward[func](EvrDayMgr.eGetCountReward, self.RespGetCount, self)
end

function My:RespDayInfo()
    self:InitRedState()
end

function My:RespGetAward()
    self:InitRedState()
end

function My:RespGetCount()
    self:InitRedState()
end

function My:InitRedState()
    local isGet = self:IsGetAward()
    local color = self.red.color
    if isGet then
        color.a = 1
        self.red.color = color
        self.red.gameObject:SetActive(true)        
    else
        self.red.gameObject:SetActive(false)        
    end
end

function My:IsGetAward()
    local isGet = false
    for i,j in pairs(Info.PayAdDic) do
        if j==2 then
            isGet = true
        end
    end
    for k,v in pairs(Info.CountAdDic) do
        if v==2 then
            isGet = true
        end
    end
    return isGet
end

function My:OnClick()
    UIMgr.Open(UIEvrDayPay.Name)
end

function My:Clear()
    
end

function My:Dispose()
    self:Clear()  
    self:SetLnsr("Remove") 
end

return My