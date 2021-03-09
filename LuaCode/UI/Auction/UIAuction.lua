--[[
    拍卖行
]]

require("UI/Auction/UIAuctionR11")
require("UI/Auction/UIAuctionR12")
require("UI/Auction/UIAuctionR21")
require("UI/Auction/UIAuctionR22")
require("UI/Auction/UIAuctionR3")
require("UI/Auction/RGridItem")
require("UI/Auction/UIAuctionR4")

UIAuction = UIBase:New{Name = "UIAuction"}
local M = UIAuction

local C = ComTool.Get
local T = TransTool.FindChild
local US = UITool.SetLsnrClick
local USS = UITool.SetLsnrSelf
local Add = TransTool.AddChild
local tip = "拍卖行主界面"

local togList = {}
local leftTogList = {}
local leftTogObj = {}
local curId = 0   -- 二级按钮Id

function M:InitCustom()
    local trans = self.root

    self.leftWdg = T(trans,"leftBtn").transform
    self.R11 = T(trans,"R11")
    self.R12 = T(trans,"R12")
    self.R21 = T(trans,"R21")
    self.R22 = T(trans,"R22")
    self.R3 = T(trans,"R3")
    self.R4 = T(trans, "R4")

    -- 左边按钮
    US(trans, "desBtn", tip, self.OnDes, self)
    US(trans, "closeBtn", tip, self.OnClose, self)

    -- 一级分类按钮
    for i=1,4 do
        local tg = C(UIToggle,trans,"top/Tog"..i,self.Name,false)
        togList[i] = tg
        US(trans,"top/Tog"..i,self.Name,self.OnClick,self)
    end

    -- 左侧按钮
    self.grid = C(UIGrid,self.leftWdg,"grid",tip,false)
    self.gridObj = T(self.leftWdg,"grid").transform
    self.tog = T(self.gridObj,"tog")
    self.tog:SetActive(false)

    -- 下方筛选以及搜索
    local screen = T(trans,"screen").transform
    self.filterGrid = C(UIGrid,screen,"grid")
    self.pjObj = T(screen,"grid/PopMenu1")
    self.pzObj = T(screen,"grid/PopMenu2")
    self.findCont = T(trans,"findCont")
    self.des = T(trans,"desBtn")

    self.input = C(UIInput,trans, "findCont/InputBg", tip, false)
    US(trans, "findCont/FindBtn", tip, self.OnSearch, self)
    self:InitPage()
    self:InitFilterBtns()

    EventMgr.Add("DataClear",self.OnClose)
end

function M:LateUpdate()
    UIAuctionR22:LateUpdate()
    UIAuctionR4:LateUpdate()
end

function M:OnClose()
    AuctionMgr:RepClose()
    self:Close()
end

-- 初始化
function M:InitPage()
    UIAuctionR11:Init(self.R11)
    UIAuctionR12:Init(self.R12)
    UIAuctionR21:Init(self.R21)
    UIAuctionR22:Init(self.R22)
    UIAuctionR3:Init(self.R3)
    UIAuctionR4:Init(self.R4)
end

-- 还原筛选框状态
function M:ResetFilterBtns()
    AuctionMgr:SetPJIndex(0)
    AuctionMgr:SetPZIndex(0)
end

-- 初始化筛选框
function M:InitFilterBtns()
    if not self.pj then
        self.pj= ObjPool.Get(UIPopDownMenu)
    end
    local btns = {"所有", "一阶", "二阶", "三阶", "四阶", "五阶", "六阶", "七阶", "八阶", "九阶","十阶","十一阶"}
    self.pj:Init(self.pjObj,"品阶筛选", btns, 46, function(fIndex) self:ChPJFilter(fIndex) end,true)
    self.pj:ChgPopPartY()

    if not self.pz then
        self.pz= ObjPool.Get(UIPopDownMenu)
    end
    local btns = {"所有", "白色", "蓝色","紫色", "橙色", "红色", "粉色"}
    self.pz:Init(self.pzObj,"品质筛选", btns, 46, function(fIndex) self:ChPZFilter(fIndex) end,true)
    self.pz:ChgPopPartY()
end


function M:ChPZFilter(fIndex)
    local lastIndex = AuctionMgr:GetPZIndex()
        if lastIndex ~= fIndex then
            AuctionMgr:SetPZIndex(fIndex)
        end
    if self.tp == 1 then
        AuctionMgr:ReqSecType()
    elseif self.tp == 3 then
        local secId = AuctionMgr:GetFirId()
        local data = nil
        if secId == "1000" then
            data = AuctionMgr:GetAllDecItem(tostring(secId))
        else
            data = AuctionMgr:GetFirstItemDic(tostring(secId))
        end
        local list = AuctionMgr:GetByPZorPJ(data)
        UIAuctionR3:ShowData(list)
    end
end

function M:ChPJFilter(fIndex)
    local lastIndex = AuctionMgr:GetPJIndex()
    if lastIndex ~= fIndex then
        AuctionMgr:SetPJIndex(fIndex)
    end
    if self.tp == 1 then
        AuctionMgr:ReqSecType()
    elseif self.tp == 3 then
        local secId = AuctionMgr:GetFirId()
        local data = nil
        if secId == "1000" then
            data = AuctionMgr:GetAllDecItem(tostring(secId))
        else
            data = AuctionMgr:GetFirstItemDic(tostring(secId))
        end
        local list = AuctionMgr:GetByPZorPJ(data)
        UIAuctionR3:ShowData(list)
    end
end

function M:OnSearch()
    local tStr = self.input.value
    if tStr == nil or tStr == "" or self.searchStr == tStr then
		return
    end
    local firstId = AuctionMgr:GetFirId()
    local secId = AuctionMgr:GetSecId()
    local data = {}
    if firstId == "1000" then
        data = AuctionMgr:GetAllDecItem(firstId)
    else
        data = AuctionMgr:GetFirstItemDic(firstId)
        if secId ~= 0 then
            data = AuctionMgr:GetSecItemDic(secId,data)
        end
    end
    if self.tp == 1 then
        AuctionMgr:SetGoodsDataByStr(tStr)
        UIAuctionR12:ShowData()
    elseif self.tp == 3 then
        local list = AuctionMgr:GetByPZorPJ(data)
        local searchIds = AuctionMgr:GetSearchItemIdLocal(tStr,list)
        local findList = {}
        for i,v in ipairs(data) do
            for i=1,#searchIds do
                if v == searchIds[i] then
                    findList[#findList + 1] = v
                end
            end
        end
        UIAuctionR3:ShowData(findList)
    end
end

-- 显示左侧按钮
function M:ShowLeftBtn()
    if self.tp == 4 then
        self.leftWdg.gameObject:SetActive(false)
        self:CloseAll()
        UIAuctionR4:Open()
        return
    end
    self.leftWdg.gameObject:SetActive(true)
    local list = nil
    if self.tp == 1 or self.tp == 3 then
        self.list = AuctionMgr:GetFirstData()
    else
        self.list = AuctionMgr.leftBtnSelf
    end
    local list = self.list
    local num = #list
    self:ReLeftBtnNum(num)
    TableTool.ClearDic(leftTogList)
    for i=1,num do
        local go = leftTogObj[i]
        go.name = list[i].id
        local tran = go.transform
        local lb = C(UILabel,tran,"Lb")
        local tg = ComTool.GetSelf(UIToggle,go,self.Name)
        lb.text = list[i].name
        USS(tran, self.OnTog, self)
        leftTogList[go.name] = tg
    end
    local index = self.index and list[self.index] and tostring(list[self.index].id) or tostring(list[1].id)
    self:SwitchMemu(index)
end


function M:OpenTabByIdx(t1, t2, t3, t4)
--none
end

function M:OpenTabByIdxBeforOpen(t1, t2, t3, t4)
    self.tp = tonumber(t1)
    self.index= tonumber(t2)
end


function M:CloneBtn()
    local go = Instantiate(self.tog)
    go:SetActive(true)
    local tran = go.transform
    Add(self.gridObj, tran)
    leftTogObj[#leftTogObj + 1] = go
end

-- 重置左边按钮数量
function M:ReLeftBtnNum(num)
    local len = #leftTogObj
    for i=1,len do
        leftTogObj[i]:SetActive(false)
    end
    if num <= len then
        for i=1,num do
            leftTogObj[i]:SetActive(true)
		end
    else
        for i=1,len do
            leftTogObj[i]:SetActive(true)
        end

		local needNum = num - len
        for i=1,needNum do
            self:CloneBtn()
        end
    end
    self.grid:Reposition()
end

-- 二级菜单按钮事件
function M:OnTog(go)
    self:SwitchMemu(go.name)
end

-- 切换二级分页
function M:SwitchMemu(firId)
    self.firId = firId
    leftTogList[firId].value = true
    for i,v in ipairs(self.list) do
        local name = tostring(self.list[i].id)
        if name ~= firId then
            --leftTogList[name].value = false
            leftTogList[name]:CustomAction(false)
        end
    end
    AuctionMgr:SetFirId(firId)
    self:CloseAll()
    self:ResetFilterBtns()
    if self.tp == 1 then
        if firId == "1000" then
            AuctionMgr:ReqSecType(tonumber(firId),0,0)
            UIAuctionR12:Open()
        else
            AuctionMgr:ReqFirstType(firId)
            UIAuctionR11:Open()
        end
    elseif self.tp == 2 then
        if firId == "1" then
            UIAuctionR21:Open()
        else
            UIAuctionR22:Open()
        end
    elseif self.tp == 3 then
        UIAuctionR3:Open()
    elseif self.tp == 4 then
        UIAuctionR4:Open()
    end
end

function M:CloseAll()
    UIAuctionR11:Close()
    UIAuctionR12:Close()
    UIAuctionR21:Close()
    UIAuctionR22:Close()
    UIAuctionR3:Close()
    UIAuctionR4:Close()
    self:OpenFilterCout(false,false)
    self:OpenSearch(false)
    self.pj:SynBtnIndexShow(0)
    self.pz:SynBtnIndexShow(0)
    self:ClearSearchStr()
end

-- 一级菜单分类
function M:OnClick(go)
    self.index = nil
    local tp = tonumber(string.sub( go.name, 4))
    self:SwitchTg(tp) 
end

-- 切换一级分页
function M:SwitchTg(tp)
    togList[tp].value=true
    self.tp = tp
    self:ShowLeftBtn()
    self:ClearSearchStr()
    if self.tp == 3 or self.tp == 4 then
        self.des:SetActive(false)
    else
        self.des:SetActive(true)
    end
end

-- 打开界面
function M:OpenCustom()
    self:SetDefTp(self.tp)
end

function M:SetDefTp(tp)
    if tp and togList[tp] and togList[tp].gameObject.activeSelf then
        self:SwitchTg(tp)
    else
        for i=1,#togList do
            if togList[i].gameObject.activeSelf then
                self:SwitchTg(i)
                break
            end
        end
    end
end

-- 打开筛选框
function M:OpenFilterCout(openPJ,openPZ)
	self.pjObj:SetActive(openPJ)
	self.pzObj:SetActive(openPZ)
    self.filterGrid:Reposition()
end

-- 打开搜索框
function M:OpenSearch(open)
    self.findCont:SetActive(open)
end

function M:OnDes()
    local cfg = InvestDesCfg["1031"]
    if cfg == nil then return end
    UIComTips:Show(cfg.des, Vector3.New(0, -170, 0))
end

function M:ClearSearchStr()
	self.searchStr = ""
	self.input.value = ""
end

function M:DisposeCustom()
    EventMgr.Remove("DataClear",self.OnClose)
    TableTool.ClearDic(leftTogObj)
    self.tp = 1
    self.firId = nil
    self.index = nil
    TableTool.ClearDic(togList)
    UIAuctionR11:Dispose()
    UIAuctionR12:Dispose()
    UIAuctionR21:Dispose()
    UIAuctionR22:Dispose()
    UIAuctionR3:Dispose()
    UIAuctionR4:Dispose()
    if self.pj then
        ObjPool.Add(self.pj)
        self.pj = nil
    end
    if self.pz then
        ObjPool.Add(self.pz)
        self.pz = nil
    end
end

return M