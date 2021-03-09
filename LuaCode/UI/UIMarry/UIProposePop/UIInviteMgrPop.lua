--[[
 	authors 	:Liu
 	date    	:2018-12-17 19:26:00
 	descrition 	:宾客管理弹窗
--]]

UIInviteMgrPop = Super:New{Name = "UIInviteMgrPop"}

local My = UIInviteMgrPop

require("UI/UIMarry/UIProposePop/UIInviteGuestIt")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local Find = TransTool.Find
    local FindC = TransTool.FindChild
    local str = "bg1/Scroll View/Grid"

    self.lab = CG(UILabel, root, "inviteLab")
    self.btnSpr = FindC(root, "btn3/spr", des)
    self.item = FindC(root, str.."/item", des)
    self.grid = Find(root, str, des)
    self.go = root.gameObject
    self.itList = {}

    SetB(root, "btn1", des, self.OnAllNo, self)
    SetB(root, "btn2", des, self.OnAllYes, self)
    SetB(root, "btn3", des, self.OnSetBuy, self)
    SetB(root, "plus", des, self.OnPlus, self)
    SetB(root, "close", des, self.OnClose, self)

    self:UpLab()
    self:UptBtn3()
    self:InitInviteList()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    MarryMgr.eReplyGuest[func](MarryMgr.eReplyGuest, self.RespReplyGuest, self)
    MarryMgr.eBuyJoin[func](MarryMgr.eBuyJoin, self.RespBuyJoin, self)
    MarryMgr.eAddGuest[func](MarryMgr.eAddGuest, self.RespAddGuest, self)
end

--响应增加宾客
function My:RespAddGuest()
    self:UpLab()
end

--响应点击设置购买按钮
function My:RespBuyJoin()
	self:UptBtn3()
end

--响应婚宴请帖答复
function My:RespReplyGuest(type)
    local dic = MarryInfo:GetApplyGuestDic()
    local list = self.itList
    for i,v in ipairs(list) do
        local key = tostring(v.cfg.id)
        if dic[key] == nil then
            v.go:SetActive(false)
            table.remove(list, i)
        end
    end
    self.grid:GetComponent(typeof(UIGrid)):Reposition()
    UIProposePop.modList[3]:UpData()
    self:UpLab()
end

--初始化宾客列表
function My:InitInviteList()
    local list = MarryInfo.feastData.applyGuestList
    self:SetList(list, self.itList)
end

--增加宾客列表
function My:AddInviteList()
    local list = MarryInfo.feastData.applyGuestList
    local list1 = {}
    table.insert(list1, list[#list])
    self:SetList(list1, self.itList)
    self.grid:GetComponent(typeof(UIGrid)):Reposition()
end

--设置好友/道庭列表
function My:SetList(list, saveDic)
    local Add = TransTool.AddChild
    for i,v in ipairs(list) do
        local go = Instantiate(self.item)
        go:SetActive(true)
        local tran = go.transform
        Add(self.grid, tran)
        local it = ObjPool.Get(UIInviteGuestIt)
        it:Init(tran, v)
        table.insert(self.itList, it)
    end
end

--初始化文本
function My:UpLab()
    local count = MarryInfo:GetInviteCount()
    local str = string.format("[FFE9BDFF]免费邀请剩余人数: [88F8FFFF]%s", count)
    self.lab.text = str
end

--点击全部拒绝
function My:OnAllNo()
    if self:IsMax(true) then return end
    self:ReplyAllGuest(0)
end

--点击全部同意
function My:OnAllYes()
    if self:IsMax(true) then return end
    self:ReplyAllGuest(1)
end

--设置购买请帖
function My:OnSetBuy()
	local state = self.btnSpr.activeSelf
	-- spr:SetActive(not state)
    MarryMgr:ReqSetBuy(not state)
end

--更新设置购买状态
function My:UptBtn3()
	local state = MarryInfo.feastData.isBuyJoin
	self.btnSpr:SetActive(state)
end

--判断可邀请人数是否达到上限
function My:IsMax(isAll)
    local count = MarryInfo:GetInviteCount()
    if isAll then
        local len = #self.itList
        if count < len then
            UITip.Log("剩余邀请人数不足")
            return true
        end
    else
        if count == 0 then
            UITip.Log("剩余邀请人数不足")
            return true
        end
    end
    return false
end

--回复宾客请求
function My:ReplyAllGuest(type)
    local tempList = {}
    local list = self.itList
    for i,v in ipairs(list) do
        table.insert(tempList, v.cfg.id)
    end
    if #tempList == 0 then UITip.Log("没有申请的玩家") return end
    MarryMgr:ReqReplyGuest(type, tempList)
end

--点击增加可邀请人数
function My:OnPlus()
    UIProposePop:ShowPopMenu()
end

--点击关闭
function My:OnClose()
    local it = UIProposePop
    if it.isBack then
        it:Close()
        it:ClearState()
    else
        it:SetMenuState(5)
    end
end

--清理缓存
function My:Clear()

end

--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
    TableTool.ClearDicToPool(self.itList)
end

return My