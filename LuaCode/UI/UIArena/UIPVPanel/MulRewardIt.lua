MulRewardIt = Super:New{Name = "MulRewardIt"}
local My = MulRewardIt

function My:Init(obj)
    self.Gbj = obj.gameObject
    local trans = obj.transform
    local name = trans.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local US = UITool.SetLsnrSelf
    self.rankLab = CG(UILabel,trans,"rankLab",name)
    self.rewardGrid = CG(UIGrid,trans,"reGrid",name)
    self.rewardTab = {}
end

function My:SetActive(ac)
    self.Gbj:SetActive(ac)
end

function My:UpdateData(data)
    local reward = data.reward
    local one = data.rankSec.k
    local two = data.rankSec.v
    local rankStr = ""
    if one == two then
        rankStr = string.format("排名 %s",one)
    else
        rankStr = string.format("排名%s-%s",one,two)
    end
    self:RefreshReward(reward)
    self.rankLab.text = rankStr
end

--I:道具id  B:数量   N:是否绑定
function My:RefreshReward(reward)
    local data = reward
    local len = #data
    local itemTab = self.rewardTab
    local count = #itemTab
    local max = count >= len and count or len
    local min = count + len - max
    for i = 1,max do
        if i <= min then
            itemTab[i]:UpData(data[i].I,data[i].B)
            itemTab[i]:UpBind(data[i].N)
            itemTab[i]:SetActive(true)
        elseif i <= count then
            itemTab[i]:SetActive(false)
        else
            local item = ObjPool.Get(UIItemCell)
            item:InitLoadPool(self.rewardGrid.transform)
            item:UpData(data[i].I,data[i].B)
            item:UpBind(data[i].N)
            table.insert(self.rewardTab,item)
        end
    end
    self.rewardGrid:Reposition()
end

function My:Dispose()
    TableTool.ClearListToPool(self.rewardTab)
    TableTool.ClearUserData(self)
end