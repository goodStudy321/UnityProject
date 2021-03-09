--[[
 	authors 	:Liu
 	date    	:2018-12-15 14:05:00
 	descrition 	:邀请宾客弹窗
--]]

UIInvitePop = Super:New{Name = "UIInvitePop"}

local My = UIInvitePop

local strs = "UI/UIMarry/UIProposePop/"
require(strs.."UIInviteIt")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild
    local str = "bg/bg1/Scroll View/"
    local str1 = "bg/bg2/Scroll View/"
    local str2 = "bg/bg1/tog1"
    local str3 = "bg/bg1/tog2"

    self.spr1 = FindC(root, str2.."/spr", des)
    self.spr2 = FindC(root, str3.."/spr", des)
    self.item1 = FindC(root, str.."Grid1/item", des)
    self.item3 = FindC(root, str1.."Grid/item", des)
    self.grid1 = Find(root, str.."Grid1", des)
    self.grid2 = Find(root, str.."Grid2", des)
    self.grid3 = Find(root, str1.."Grid", des)
    self.panel = Find(root, "bg/Panel", des)
    self.countLab = CG(UILabel, root, "bg/countBg/lab")
    self.go = root.gameObject
    self.fList = {}
    self.ffList = {}
    self.invList = {}
    SetB(root, str2, des, self.OnTog1, self)
    SetB(root, str3, des, self.OnTog2, self)
    SetB(root, "bg/countBg/plusBtn", des, self.OnPlus, self)
    SetB(root, "bg/close", des, self.OnClose, self)
    self:UpLab()
    self:InitFriendList()
    self:InitFamilyFList()
    self:InitInviteList()
    -- self:InitModule()
    self:OnTog1()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    MarryMgr.eInviteGuest[func](MarryMgr.eInviteGuest, self.RespInviteGuest, self)
    MarryMgr.eAddGuest[func](MarryMgr.eAddGuest, self.RespAddGuest, self)
    MarryMgr.ePopClick[func](MarryMgr.ePopClick, self.RespPopClick, self)
end

--响应弹窗点击
function My:RespPopClick(isAllShow)
	if not isAllShow and self.go.activeSelf then
        VIPMgr.OpenVIP(1)
    end
end

--响应增加宾客
function My:RespAddGuest()
    local it = UIProposePop
    it.pop:UpLab()
    it.pop:UpOfSteps()
    it.pop:OnClose()
    self:UpLab()
end

--响应邀请宾客
function My:RespInviteGuest()
    self:UpData()
end

--更新宾客数据
function My:UpData()
    self:UpFriendList()
    self:UpFamilyFList()
    self:UpInviteList()
    self:UpLab()
end

--点击增加次数
function My:OnPlus()
    UIProposePop:ShowPopMenu()
end

--更新邀请人数文本
function My:UpLab()
    local cfg = GlobalTemp["61"]
    if cfg then
        local info = MarryInfo.feastData
        local len = #info.guestList
        local count = cfg.Value2[1] + info.guestNum
        local str = string.format("%s/%s", len, count)
        self.countLab.text = str
    end
end

--初始化好友
function My:InitFriendList()
    local list = {}
    for i,v in ipairs(FriendMgr.FriendList) do
        if tonumber(v.ID) ~= tonumber(MarryInfo.data.coupleid) and v.Level >= 100 then--过滤掉不满足条件的
            local isContain = self:IsContain(v.ID)
            if not isContain then table.insert(list, v) end
        end
    end
    self:SetList(self.grid1, self.item1, list, self.fList, 1)
end

--更新好友
function My:UpFriendList()
    local list = MarryInfo.feastData.guestList
    for i,v in ipairs(self.fList) do
        for i1,v1 in ipairs(list) do
            if tonumber(v1.id) == tonumber(v.cfg.ID) then
                v.go:SetActive(false)
                table.remove(self.fList, i)
            end
        end
    end
    self.grid1:GetComponent(typeof(UIGrid)):Reposition()
end

--初始化道庭好友
function My:InitFamilyFList()
    if not FamilyMgr:JoinFamily() then return end
    local bInd = 1
	local eInd = FamilyMgr:GetFamilyMemberNum()
    local dataList = FamilyMgr:GetFamilyMembersRange(bInd, eInd)
    local list = {}
    for i,v in ipairs(dataList) do
        if tonumber(v.roleId) == tonumber(User.MapData.UIDStr) or tonumber(v.roleId) == tonumber(MarryInfo.data.coupleid) then
            --过滤掉自己和仙侣
        elseif v.roleLv < 100 then
            --过滤掉等级不足的
        else
            local isContain = self:IsContain(v.roleId)
            if not isContain then table.insert(list, v) end
        end
    end
    self:SetList(self.grid2, self.item1, list, self.ffList, 2)
end

--更新道庭好友
function My:UpFamilyFList()
    local list = MarryInfo.feastData.guestList
    for i,v in ipairs(self.ffList) do
        for i1,v1 in ipairs(list) do
            if tonumber(v1.id) == tonumber(v.cfg.roleId) then
                v.go:SetActive(false)
                table.remove(self.ffList, i)
            end
        end
    end
    self.grid2:GetComponent(typeof(UIGrid)):Reposition()
end

--初始化已邀请的宾客列表
function My:InitInviteList()
    local list = MarryInfo.feastData.guestList
    self:SetList(self.grid3, self.item3, list, self.invList, 3)
end

--更新宾客列表
function My:UpInviteList()
    local list = {}
    local guestList = MarryInfo.feastData.guestList
    for i,v in ipairs(guestList) do
        if self.invList[i] == nil then
            table.insert(list, v)
        end
    end
    self:SetList(self.grid3, self.item3, list, self.invList, 3)
    self.grid3:GetComponent(typeof(UIGrid)):Reposition()
end

--判断是否包含已邀请的宾客
function My:IsContain(id)
    local isContain = false
    local guestList = MarryInfo.feastData.guestList
    for i,v in ipairs(guestList) do
        if tonumber(v.id) == tonumber(id) then
            isContain = true
            break
        end
    end
    return isContain
end

--设置好友/道庭列表
function My:SetList(grid, item, list, saveList, index)
    local Add = TransTool.AddChild
    for i,v in ipairs(list) do
        local go = Instantiate(item)
        go:SetActive(true)
        local tran = go.transform
        Add(grid, tran)
        local it = ObjPool.Get(UIInviteIt)
        it:Init(tran, v, index)
        table.insert(saveList, it)
    end
end

--点击Tog1
function My:OnTog1()
    self:SetTogState(true)
end

--点击Tog2
function My:OnTog2()
    self:SetTogState(false)
end

--设置Tog状态
function My:SetTogState(state)
    self.spr1:SetActive(state)
    self.grid1.gameObject:SetActive(state)
    self.spr2:SetActive(not state)
    self.grid2.gameObject:SetActive(not state)
end

--点击关闭
function My:OnClose()
    local it = UIProposePop
    it:Close()
    it:ResetState()
end

--清理缓存
function My:Clear()

end

--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
    ObjPool.Add(self.invitePop)
    self.invitePop = nil
    ListTool.ClearToPool(self.fList)
    ListTool.ClearToPool(self.ffList)
    ListTool.ClearToPool(self.invList)
end

return My