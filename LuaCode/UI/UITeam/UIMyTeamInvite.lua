UIMyTeamInvite = {}
local My = UIMyTeamInvite

My.OpenIndex = 1
My.RoleUID = User.instance.MapData.UID

require("UI/UITeam/UIMyTeamInviteItem")
local InviteItem = UIMyTeamInviteItem

--初始化控件
function My:New(go)
	self.Name = "UIMyTeamInvite"
	self.GO = go
	self.trans = self.GO.transform
	local C = ComTool.Get
    local T = TransTool.FindChild
    local UC = UITool.SetLsnrClick
	self.Grid = C(UIGrid, self.trans, "scrollV/Grid", self.Name, false)
    self.Prefab = T(self.trans, "scrollV/Grid/Item")
    self.Prefab:SetActive(false)
	self.itDic = {}

    -- 1:好友列表  2：道庭好友列表  3：附近好友列表
    self.FriendType = 0

    self.friendBtn = C(UIToggle, self.trans, "friendBtn", self.Name)
    self.fairyBtn = C(UIToggle, self.trans, "fairyBtn", self.Name)
    self.areaBtn = C(UIToggle, self.trans, "areaBtn", self.Name)

	UC(self.trans, "friendBtn", self.Name,self.FriendBtn,self)
	UC(self.trans, "fairyBtn", self.Name,self.FairyBtn,self)
    UC(self.trans, "areaBtn", self.Name,self.AreaBtn,self)

    self:AddEvent()
    -- self:OpenTab()
    
    self:GetFriendDate()
    self:ShowMemberData()
    
    return My
end

function My:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.GO then
		E(self.GO, self.OnClose, self, nil, false)
    end
    self:SetLsnr("Add")

    EventMgr.Add("NewFamilyMemberData", EventHandler(self.ShowMemberData, self))
end

function My:SetLsnr(fn)
    FriendMgr.eUpdateFriend[fn](FriendMgr.eUpdateFriend, self.GetFriendDate, self)
end

--好友列表
function My:FriendBtn()
    self.FriendType = 1
    self.friendBtn.value = true
    local teamPlayTab = self:GetTeamPTab()
    -- if teamPlayTab == nil or #teamPlayTab == 0 then
    --     return
    -- end
    local needFriend = {}
    local copyMinLv = TeamMgr.TeamInfo.MinLv
    if self.friendList ~= nil then
        local frdList = self.friendList
        local len  = #frdList
        for i = 1,len do
            local info = frdList[i]
            local Name = info.Name
            local ID = info.ID
            local lv = info.Level
            local isOnline = info.Online
            if teamPlayTab[ID] == nil and lv >= copyMinLv and isOnline then
                -- iTrace.Error("GS","Friend  name=",Name," ID=",ID," Lv=",lv)
                table.insert(needFriend,info)
            end
        end
    end
    self:UpdateData(1,needFriend)
end

--道庭列表
function My:FairyBtn()
    self.FriendType = 2
    local teamPlayTab = self:GetTeamPTab()
    local needFriend = {}
    local copyMinLv = TeamMgr.TeamInfo.MinLv
    local roleUID = User.instance.MapData.UID
    if self.fairyList ~= nil then
        local fairyTab = self.fairyList
        local len = #fairyTab
        for i = 1,len do
            local info = fairyTab[i]
            local roleName = info.roleName
            local roleId = info.roleId
            local lv = info.roleLv
            local category = info.category
            local isOnline = info.isOnline
            if teamPlayTab[roleId] == nil and lv >= copyMinLv and isOnline and tostring(roleUID) ~= tostring(roleId) then
                -- iTrace.Error("GS"," FairyBtn infoid=",info.roleId," name=",info.roleName," lv=",info.roleLv," cate=",info.category)
                -- iTrace.Error("GS","roleUID  roleUID=",roleUID)
                table.insert(needFriend,info)
            end
        end
    end
    self:UpdateData(2,needFriend)
end

--附近列表
function My:AreaBtn()
    self.FriendType = 3
    local teamPlayTab = self:GetTeamPTab()
    local copyMinLv = TeamMgr.TeamInfo.MinLv
    local needFriend = {}
    local areaDate = User.instance:GetActorData()
    local roleServeId = User.instance.MapData.ServerID
    local len = areaDate.Count
    if len > 0 then
        for i = 0,len - 1 do
            local v = areaDate[i]
            local roleName = v.Name
            local roleId = v.UID
            local lv = v.Level
            local category = v.Category
            local serverId = v.ServerID
            if teamPlayTab[roleId] == nil and lv >= copyMinLv and roleServeId == serverId then
                -- iTrace.Error("GS","Friend  name=",Name," ID=",ID," Lv=",lv,"roleServeId==",roleServeId)
                table.insert(needFriend,v)
            end
        end
    end
    self:UpdateData(3,needFriend)
end

function My:GetTeamPTab()
    local teamPlayTab = {}
    local teamPlayerTab = TeamMgr.TeamInfo.Player
    if teamPlayerTab == nil then
        return
    end
    for i = 1,#teamPlayerTab do
        local info = teamPlayerTab[i]
        local ID = info.ID
        teamPlayTab[ID] = info
    end
    return teamPlayTab
end

--获取好友数据
function My:GetFriendDate()
    self.friendList = FriendMgr.FriendList
end

--获取道庭好友数据
function My:ShowMemberData()
    local bInd = 1;
	local eInd = FamilyMgr:GetFamilyMemberNum();
    local dataList = FamilyMgr:GetFamilyMembersRange(bInd, eInd);
    self.fairyList = dataList
end

function My:UpdateData(friendType,list)
	local uiTbl = self.Grid
	local uiTblTran = uiTbl.transform
	local mod = self.Prefab
    local itDic = self.itDic
    if itDic then
        for k,v in pairs(itDic) do
            self.itDic[k] = nil
        end
    end
    TransTool.RenameChildren(uiTblTran)
    if list == nil or #list <= 0 then 
        return
    end
	local Inst = GameObject.Instantiate
	local TA = TransTool.AddChild
    local Get = ObjPool.Get
    for i = 1,#list do
        local v = list[i]
        local id = nil
        if friendType == 1 then
            id = v.ID
        elseif friendType == 2 then
            id = v.roleId
        elseif friendType == 3 then
            id = v.UID
        end
		local k = tostring(id)
		local tran = uiTblTran:Find("none")
		local it = nil
		if tran == nil then
			it = Inst(mod)
			tran = it.transform
		else
			it = tran.gameObject
		end
		it.name = k
		it.gameObject:SetActive(true)
		TA(uiTblTran, tran)
		local it = Get(InviteItem)
        itDic[k] = it
        it:Init(tran)
        it:UpdateData(friendType,v)
        UITool.SetLsnrSelf(it.InvitBtn, self.OnInvitBtn, self)
    end
    uiTbl:Reposition()
end

function My:OnInvitBtn(go)
    local roleId = go.transform.parent.name
    local it = self.itDic[roleId]
    if it ~= nil then
        it.Root.gameObject:SetActive(false)
        it.Root.name = "none"
        roleId = tonumber(roleId)
        TeamMgr:ReqInviteTeam(roleId)
    end
    self.Grid:Reposition()
end



function My:OnClose()
	self.GO:SetActive(false)
end

--清除数据
function My:ItemToPool()
    for k,v in pairs(self.itDic) do
        v:Dispose()
        ObjPool.Add(v)
        self.itDic[k] = nil
    end
end
--释放或销毁
function My:Dispose(isDestory)
    EventMgr.Remove("NewFamilyMemberData", EventHandler(self.ShowMemberData, self))
    self:SetLsnr(FriendMgr,"Remove")
	self:ItemToPool()
	self.Grid = nil
	self.Prefab = nil
end