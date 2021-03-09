MScoreIt=Super:New{Name="MScoreIt"}
local My = MScoreIt

function My:Init(obj)
    self.Gbj = obj.gameObject
    local trans = obj.transform
    local name = trans.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local US = UITool.SetLsnrSelf
    self.des1 = CG(UILabel,trans,"des1",name)
    self.des2 = CG(UILabel,trans,"des2",name)
    self.rewardGrid = CG(UIGrid,trans,"Grid",name)
    self.flag = CG(UISprite,trans,"flag",name)
    self.btnSp = CG(UISprite,trans,"btn",name)
    self.btn = TFC(trans,"btn",name)
    self.btnLab = CG(UILabel,trans,"btn/lab",name)
    self.red = TFC(trans,"red",name)
    US(self.btn,self.ClickBtn,self)
    self.needScore = 0
    self.rewardTab = {}
end

function My:ClickBtn()
    local score = self.needScore
    if score == 0 then
        return
    end
    MoonLoveMgr:ReqMoonExchange(score)
end

function My:SetActive(ac)
    self.Gbj:SetActive(ac)
end

function My:UpdateData(data)
    self.needScore = data.needScore
    local reward = data.rewTab
    local des2 = string.format("情缘积分%s可领",data.needScore)
    self:RefreshReward(reward)
    self.des2.text = des2
    self:RefreshGet()
end

--I:道具id  B:数量   N:是否绑定
function My:RefreshReward(reward)
    local data = reward
    local len = #data
    local itemTab = self.rewardTab
    local count = #itemTab
    local max = count >= len and count or len
    local min = count + len - max
    local name = ""
    for i = 1,max do
        if i <= min then
            name = ItemData[tostring(data[i].I)].name
            itemTab[i]:UpData(data[i].I,data[i].B)
            itemTab[i]:SetActive(true)
        elseif i <= count then
            itemTab[i]:SetActive(false)
        else
            name = ItemData[tostring(data[i].I)].name
            local item = ObjPool.Get(UIItemCell)
            item:InitLoadPool(self.rewardGrid.transform)
            item:UpData(data[i].I,data[i].B)
            table.insert(self.rewardTab,item)
        end
    end
    local name = string.format("%s礼包",name)
    self.des1.text = name
    self.rewardGrid:Reposition()
end

--刷新领取奖励
function My:RefreshGet()
    local spTab = {"btn_task_none","btn_task_2","btn_task_2"}
    local labTab = {"兑 换","已兑换","已兑换"}
    local score = self.needScore
    local index = MoonLoveMgr:IsExChange(score)
    self.red:SetActive(index == 1)
    self.btnSp.spriteName = spTab[index]
    self.btnLab.text = labTab[index]
    self.flag.gameObject:SetActive(index == 3)
    self.btn.gameObject:SetActive(index ~= 3)
end

function My:Dispose()
    self.needScore = 0
    TableTool.ClearListToPool(self.rewardTab)
    TableTool.ClearUserData(self)
end