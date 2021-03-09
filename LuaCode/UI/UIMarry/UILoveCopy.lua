UILoveCopy = Super:New{Name = "UILoveCopy"}
require("UI/UIMarry/UIFriendView")

local M = UILoveCopy

function M:Ctor() 
    self.cellList = {}
    self.temp = CopyTemp["30018"]
end

function M:Init(trans)
    local SC = UITool.SetLsnrClick
    local S = UITool.SetLsnrSelf
    local FC= TransTool.FindChild
    local G = ComTool.Get

    self.go = trans.gameObject

    self.remainCount = G(UILabel, trans, "RemainCount")
    self.remainBuyCount = G(UILabel, trans, "RemainBuyCount")
    self.cost = G(UILabel, trans, "Cost")
    self.des = G(UILabel, trans, "Des")
    self.grid = G(UIGrid, trans, "RewardList/Grid")

    local desName = self.Name
    local BtnBuy = FC(trans,"BtnBuy",desName)
    local BtnEnter = FC(trans,"BtnEnter",desName)
    local BtnRequest = FC(trans,"BtnRequest",desName)
    local BtnInvite = FC(trans,"BtnInvite",desName)
    local BtnPeri = FC(trans,"BtnPeri",desName)
    S(BtnBuy,self.OnClickBuy,self,desName,false)
    S(BtnEnter,self.OnClickEnter,self,desName,false)
    S(BtnRequest,self.OnClickRequest,self,desName,false)
    S(BtnInvite,self.OnClickInvite,self,desName,false)
    S(BtnPeri,self.OnClickPeri,self,desName,false)
    -- SC(trans, "BtnBuy", self.Name, self.OnClickBuy, self)
    -- SC(trans, "BtnEnter", self.Name, self.OnClickEnter, self)  
    -- SC(trans, "BtnRequest", self.Name, self.OnClickRequest, self)  
    -- SC(trans, "BtnInvite", self.Name, self.OnClickInvite, self)
    -- SC(trans, "BtnPeri", self.Name, self.OnClickPeri, self)  
    
    self.friendView = ObjPool.Get(UIFriendView)
    self.friendView:Init(FC(trans, "FriendView"))
 
    self:UpdateReward()
    self:UpdateCost()
    self:UpdateRemainCount()
    self:UpdateDes()


    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    CopyMgr.eUpdateCopyData[key](CopyMgr.eUpdateCopyData, self.UpdateCopyData, self)
    TeamMgr.eRespInviteSuccess[key](TeamMgr.eRespInviteSuccess, self.RespInviteSuccess, self)
end

function M:RespInviteSuccess(id) 
    if self.friendView:ActiveSelf() then
        self.friendView:UpdateCellList(id)
    else
        local coupleid = MarryInfo.data.coupleid 
        if coupleid and tostring(coupleid)==id then
            UITip.Log("已向您的仙侣发起组队邀请")
        end
    end 
end

function M:UpdateCopyData(type)
    if type == CopyType.Loves then
        self:UpdateRemainCount()
    end
end

function M:UpdateCost()
    local temp = self.temp
    local copyData = CopyMgr.Copy[CopyMgr.Loves]
	local buy = copyData.Buy
	local cost = temp.bCost[buy+1] or temp.bCost[#temp.bCost]
    self.cost.text = cost
end

function M:UpdateRemainCount()
    local data = CopyMgr.Copy[CopyMgr.Loves]
    local total = data.Buy + data.itemAdd + self.temp.num
    local buy = self.temp.buy - data.Buy
    self.remainCount.text = string.format("[F4DDBDFF]今日剩余副本次数：[88f8ff]%d[-]", total - data.Num)
    self.remainBuyCount.text = string.format("[F4DDBDFF]今日剩余购买次数：[88f8ff]%d[-]", buy)
end

function M:UpdateDes()
    self.des.text = self.temp.des
end

function M:UpdateReward()
    local data = self.temp.sItems

    for i=1,#data do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.grid.transform)
        cell:UpData(data[i].k, data[i].v)
        table.insert(self.cellList, cell)
    end

    self.grid:Reposition()
end

function M:OnClickBuy()   
    local id = MarryInfo.data.coupleid
    if id and id>0 then
        CopyMgr:ReqCopyBuyTimes(self.temp.id)
    else
        UITip.Log("结婚后才可以购买副本次数")
    end
end

function M:OnClickEnter()
    local teamInfo = TeamMgr.TeamInfo
    if not teamInfo.TeamId then
        UITip.Log("您还没有队伍")
        return 
    end
    local players = teamInfo.Player
    if #players ~= 2  or not self:IsDiffSex(players) then
        UITip.Log("异性二人组队方可进入")
        return 
    end
    
    if teamInfo.CaptId ~= tostring(User.MapData.UID) then
        UITip.Log("队长才可以发起申请")
        return
    end

    TeamMgr:ReqStartCopyTeam(self.temp.id)
end

function M:IsDiffSex(players)
    for i=1,#players do
        if players[i].ID ~= tostring(User.MapData.UID) and players[i].Sex ~= User.MapData.Sex then
            return true
        end
    end
    return false
end

function M:OnClickRequest()
    -- local id = MarryInfo.data.coupleid
    local id = MarryInfo.data.coupleidStr
    if id and id ~= "" then
        local data = FriendMgr:GetFriendByIDStr(id) 
        if data and data.Online then
            CopyMgr:ReqMarryCopyRequest()
        else
            UITip.Log("您的仙侣不在线")
        end
    else
        UITip.Log("您还没有仙侣")
    end
end

function M:OnClickInvite()
    local id = MarryInfo.data.coupleid
    local idStr = MarryInfo.data.coupleidStr
    if id and id > 0 then
        local data = FriendMgr:GetFriendByIDStr(idStr) 
        if not data then return end
        if data.Online then       
            TeamMgr:ReqInviteTeam(id)
            TeamMgr:ReqSetCopyTeam(self.temp.id, self.temp.lv, 1000)
        else
            UITip.Log("您的仙侣不在线")
        end
    else
        UITip.Log("您还没有仙侣")
    end
end

function M:OnClickPeri()
    self.friendView:Refresh()
end

function M:Dispose()
    self:SetLsnr("Remove")
    ObjPool.Add(self.friendView)
    self.friendView = nil
    TableTool.ClearListToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return M