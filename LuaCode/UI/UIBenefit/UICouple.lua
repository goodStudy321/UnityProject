require("UI/UIBenefit/UICoupleRankItem")

UICouple = Super:New{Name = "UICouple"}
local M = UICouple

local gList = {}

local AC = TransTool.AddChild

local isOpenRank = true
local GI = GameObject.Instantiate

function M:Init(obj)
    self.obj = obj
    local trans = self.obj.transform
    local US = UITool.SetBtnClick

    local T = TransTool.FindChild
    local C = ComTool.Get
    self.time = C(UILabel,trans,"tip/lb1",self.Name)
    self.tip = C(UILabel,trans,"tip/lb2",self.Name)

    self.w1 = T(trans,"cont/w1")
    self.btnLb = C(UILabel,trans,"cont/w1/btn/lb")
    self.btn = T(trans,"cont/w1/btn")
    US(trans,"cont/w1/btn",self.Name,self.ClickGet,self)
    for i=1,3 do
        local g = {}
        g.lb = T(trans,"cont/w1/Grid/g"..i)
        g.no = T(g.lb.transform,"no")
        g.yes = T(g.lb.transform,"yes")
        gList[i] = g
    end

    self.w2= T(trans,"cont/w2")
    self.grid = C(UIGrid,trans,"cont/w2/sv/grid")
    self.item = T(trans,"cont/w2/sv/grid/rank")
    self.items = {}
    US(trans,"tip/rankBtn",self.Name,self.ClickRank,self)
    self.rankBtn = T(trans,"tip/rankBtn")
    self.rankBtn:SetActive(false)

    self:UpInfo()
    self:ShowLb()
    self:SetLsner("Add")
end

-- 打开面板
function M:Open()
    self.obj:SetActive(true)
    self:IsOpenRank(false)
end

-- 关闭面板
function M:Close()
    self.obj:SetActive(false)
end

-- 显示时间以及活动介绍
function M:ShowLb()
    self.tip.text = XsActiveCfg["1022"].detail
    local info = LivenessInfo:GetActInfoById(1022)
    if info == false then return end
    local DateTime = System.DateTime
    local sTime = (DateTool.GetDate(info.sTime)):ToString("yyyy年MM月dd日 HH:mm")
    local eTime = ""
    if info.eTime > 0 then
        eTime = DateTool.GetDate(info.eTime):ToString("yyyy年MM月dd日 HH:mm")
    else
        eTime = "永久"
    end
    self.time.text = string.format( "%s - %s", sTime, eTime)
    
end

function M:SetLsner(key)
    UserMgr.eLvEvent[key](UserMgr.eLvEvent, self.UpInfo, self)
	UserMgr.eLvUpdate[key](UserMgr.eLvUpdate, self.UpInfo, self)
    BenefitMgr.eUpdateCp[key](BenefitMgr.eUpdateCp,self.UpInfo,self)
    BenefitMgr.eSet[key](BenefitMgr.eSet,self.SetText,self)
    BenefitMgr.eCoupleRank[key](BenefitMgr.eCoupleRank,self.ShowRankData,self)
end

function M:ClickRank()
    self:IsOpenRank(isOpenRank)
end

function M:IsOpenRank(value)
    self.w1:SetActive(not value)
    self.w2:SetActive(value)
    if value then
        isOpenRank = false
        BenefitMgr:ReqCouplrRank()
    else
        isOpenRank = true
    end
end

function M:ShowRankData()
    local data = BenefitMgr:GetRankList()
    local num = #data
    if not data or num < 0 then return end
    self:ReNewItemNum(num)
    for i=1,num do
        self.items[i]:ShowItem(data[i])
    end
end

function M:CloneItem()
    local clone = GI(self.item)
    local parent = self.grid.transform
    local trans = clone.transform
    local strans = self.item.transform
    AC(parent,trans)
    trans.localPosition = strans.localPosition
	trans.localRotation = strans.localRotation
    trans.localScale = strans.localScale
    clone:SetActive(true)

    local cell = ObjPool.Get(UICoupleRankItem)
    cell:Init(clone)
    self.items[#self.items + 1] = cell
end

function M:ReNewItemNum(num)
    local len = #self.items
    for i=1,len do
        self.items[i]:Show(false)
    end
    if num <= len then
        for i=1,num do
            self.items[i]:Show(true)
        end
    else
        for i=1,len do
            self.items[i]:Show(true)
        end
        local needNum = num - len
        for i=1,needNum do
            self:CloneItem()
        end
    end
    self.grid:Reposition()
end


-- 更新按钮状态
function M:UpInfo()
    local lv = User.MapData.Level
    local cfg = GlobalTemp["52"]
    self.info = BenefitMgr.spokenList
    if not self.info then return end
    for i=1,3 do
        gList[i].yes:SetActive(false)
        gList[i].no:SetActive(true)
    end
    for i,v in ipairs(self.info) do
        gList[v].yes:SetActive(true)
        gList[v].no:SetActive(false)
    end
    if lv < cfg.Value3 then
        self.btnLb.text = string.format("%s级开启", cfg.Value3)
        UITool.SetGray(self.btn)
        return
    end
    local type = BenefitMgr.type
    if type == 0 then
        self.btnLb.text = "前往结婚"
        UITool.SetNormal(self.btn)
    elseif type == 1 then
        self.btnLb.text = "领取"
        UITool.SetNormal(self.btn)
    elseif type == 2 then
        self.btnLb.text = "已领取"
        BenefitMgr:SetRedPointState(BenefitMgr.Couple,false)
        UITool.SetGray(self.btn)
    end
end

function M:SetText()
    self.btnLb.text = "已领取"
    BenefitMgr:SetRedPointState(BenefitMgr.Couple,false)
    UITool.SetGray(self.btn)
end

-- 按钮事件
function M:ClickGet()
    local num = #self.info
    if num == 3 then
        BenefitMgr:ReqCouple()
        BenefitMgr.CoupleAction = false
        local type = BenefitMgr.Couple
        BenefitMgr:UpdateRedPoint(type)
    else
        JumpMgr:InitJump(UIBenefit.Name,BenefitMgr.Couple)
        UIMarry:OpenTab(1)
    end
end

function M:Dispose()
    isOpenRank = true
    TableTool.ClearDicToPool(self.items)
    self.items = nil
    self:SetLsner("Remove")
end

return M