MulTargetIt = Super:New{Name = "MulTargetIt"}
local My = MulTargetIt

function My:Init(obj,pa)
    self.Gbj = obj.gameObject
    self.paData = pa
    local trans = obj.transform
    local name = trans.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local US = UITool.SetLsnrSelf
    self.rankLab = CG(UILabel,trans,"rankLab",name)
    self.rewardGrid = CG(UIGrid,trans,"reGrid",name)
    self.slidLab = CG(UILabel,trans,"slidLab",name)
    self.flag = CG(UISprite,trans,"flag",name)
    self.btn = TFC(trans,"btn",name)
    US(self.btn,self.ClickBtn,self)
    self.danId = 0
    self.needScore = 0
    self.rewardTab = {}
end

function My:ClickBtn()
    if self.danId == 0 then
        iTrace.eError("GS","段位奖励id==0")
        return
    end
    Peak.ReqSoloDanRwd(self.danId)
end

function My:SetActive(ac)
    self.Gbj:SetActive(ac)
end

function My:UpdateData(data)
    self.danId = data.danId
    self.needScore = data.score
    local reward = data.rwdItems
    local rankStr = string.format("达到 %s",data.danName)
    self:RefreshReward(reward)
    self.rankLab.text = rankStr
    self:RefreshGet()
end

--I:道具id  B:数量   N:是否绑定
function My:RefreshReward(reward)
    local data = reward
    local len = #data
    if len == 0 then
        self:SetActive(false)
        return
    end
    local itemTab = self.rewardTab
    local count = #itemTab
    local max = count >= len and count or len
    local min = count + len - max
    for i = 1,max do
        if i <= min then
            itemTab[i]:UpData(data[i].k,data[i].v)
            itemTab[i]:SetActive(true)
        elseif i <= count then
            itemTab[i]:SetActive(false)
        else
            local item = ObjPool.Get(UIItemCell)
            item:InitLoadPool(self.rewardGrid.transform)
            item:UpData(data[i].k,data[i].v)
            table.insert(self.rewardTab,item)
        end
    end
    self.rewardGrid:Reposition()
end

--刷新领取奖励
function My:RefreshGet()
    local flagTab = {"ty_done","ty_undone"}
    local colorTab = {"[00FF00FF]","[CC2500FF]"}
    local rcv = Peak.DanRwdLst[self.danId]
    local ownScore = Peak.RoleInfo.score
    local needScore = self.needScore
    local isShowBtn = ownScore >= needScore
    if isShowBtn and rcv == nil then
        self.btn:SetActive(true)
        self.flag.gameObject:SetActive(false)
    elseif isShowBtn and rcv ~= nil then
        self.btn:SetActive(false)
        self.flag.gameObject:SetActive(true)
        self.flag.spriteName = flagTab[1]
        -- local gbj = self.Gbj
        -- local name = tonumber(gbj.name)
        -- name = name + 100
        self.Gbj.name = 99
        -- self.Gbj.transform:SetAsLastSibling()
    elseif isShowBtn == false then
        self.btn:SetActive(false)
        self.flag.gameObject:SetActive(true)
        self.flag.spriteName = flagTab[2]
    end
    local colorStr = ""
    if isShowBtn then
        colorStr = colorTab[1]
    else
        colorStr = colorTab[2]
    end
    local str = string.format("(%s/%s)",ownScore,needScore)
    self.slidLab.text = str
    self.paData.grid:Reposition()
end

function My:Dispose()
    self.needScore = 0
    self.danId = 0
    self.paData = nil
    TableTool.ClearListToPool(self.rewardTab)
    TableTool.ClearUserData(self)
end