require("UI/UIArena/UIPVPanel/PVPBtn")
require("UI/UIArena/UIPVPanel/SinRewardIt")
require("UI/UIArena/UIPVPanel/SinRankIt")
require("UI/UIArena/UIPVPanel/MulTargetIt")
require("UI/UIArena/UIPVPanel/MulRewardIt")
require("UI/UIArena/UIPVPanel/MulRankIt")
require("UI/UIArena/UIPVPanel/MulRankP")
require("UI/UIArena/UIPVPanel/MulRewardP")
require("UI/UIArena/UIPVPanel/MulTargetP")
require("UI/UIArena/UIPVPanel/SinRankP")
require("UI/UIArena/UIPVPanel/SinRewardP")

UIPVPanel = Super:New{Name = "UIPVPanel"}
local My = UIPVPanel

function My:Init(obj)
    local root = obj.transform
    self.Gbj = root
    local name = root.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local US = UITool.SetLsnrSelf
    local TFC = TransTool.FindChild
    self.closeBtn = TFC(root,"CloseBtn",name)
    self.btnGrid = CG(UIGrid,root,"btnGrid",name)
    self.btnItem = TF(root,"btnGrid/btn",name)
    self.btnItem.gameObject:SetActive(false)
    self.singleGbj = TFC(root,"single",name)
    self.mulGbj = TFC(root,"mul",name)
    self.sinRewardV = TFC(root,"single/rewardV",name)
    self.sinReLab = TFC(root,"single/reLab",name)
    self.sinRankV = TFC(root,"single/rankV",name)
    self.sinRankLab = TFC(root,"single/rankLab",name)
    self.sinRankDes = TFC(root,"single/desLabR",name)
    local rankTrans = self.sinRankLab.transform
    self.myRankLab = CG(UILabel,rankTrans,"my/rankLab",name)
    self.myNameLab = CG(UILabel,rankTrans,"my/nameLab",name)
    self.myOccLab = CG(UILabel,rankTrans,"my/occLab",name)
    self.myWarLab = CG(UILabel,rankTrans,"my/warLab",name)
    self.myScoreLab = CG(UILabel,rankTrans,"my/scoreLab",name)

    local mul = self.mulGbj.transform
    self.curSeasonLab = CG(UILabel,mul,"desLab/curSeason",name)
    self.seasonTime = CG(UILabel,mul,"desLab/seasonTime",name)
    self.myLvMLab = CG(UILabel,mul,"desLab/myLv",name)
    self.lvMLab = CG(UILabel,mul,"desLab/myLv/lv",name)
    self.myRankMlab = CG(UILabel,mul,"desLab/myRank",name)
    self.rankMLab = CG(UILabel,mul,"desLab/myRank/rank",name)
    self.myScoreMLab = CG(UILabel,mul,"desLab/myScore",name)
    self.scoreMLab = CG(UILabel,mul,"desLab/myScore/score",name)
    self.scrollVRewd = CG(UIScrollView,mul,"rewardV",name)

    self.mulRewardV = TFC(mul,"rewardV",name)
    self.mulReLab = TFC(mul,"reLab",name)
    self.mulRankV = TFC(mul,"rankV",name)
    self.mulRankLab = TFC(mul,"rankLab",name)
    self.mulRankDes = TFC(mul,"desLabR",name)

    self.sinRewardP = ObjPool.Get(SinRewardP)
    self.sinRankP = ObjPool.Get(SinRankP)
    self.mulRewardP = ObjPool.Get(MulRewardP)
    self.mulTargetP = ObjPool.Get(MulTargetP)
    self.mulRankP = ObjPool.Get(MulRankP)

    self.sinRewardP:Init(self.sinRewardV)
    self.sinRankP:Init(self.sinRankV)
    self.mulRewardP:Init(self.mulRewardV)
    self.mulTargetP:Init(self.mulRewardV)
    self.mulRankP:Init(self.mulRankV)

    US(self.closeBtn,self.CloseC,self,name)
    self.btnTab = {}
end

--t1 == 1:排行     2：奖励
--t2:选中第几个按钮
function My:Open(t1, t2, t3)
    self.cur = nil
    self.Gbj.gameObject:SetActive(true)
    local singleBtn = {"排行奖励","排行榜"}
    local mulBtn = {"巅峰奖励","赛季目标","跨服排名"}
    local seasonTimes = Peak.RoleInfo.season
    if seasonTimes == nil then
        seasonTimes = 0
    end
    local btntemp = mulBtn
    local isSingle = false
    if seasonTimes == 0 then
        isSingle = true
        btntemp = singleBtn
    end

    if isSingle then
        if t1 == 1 then
            t2 = 2
        elseif t1 == 2 then
            t2 = 1
        end
    else
        if t1 == 1 then
            t2 = 3
        elseif t1 == 2 then
            t2 = 1
        end
    end
    self.isSingle = isSingle
    self.difOpen = t1
    self.selectBtn = t2
    self:RefreshBtn(btntemp)
    self:Switch()
end

--显示单服或跨服按钮
function My:RefreshBtn(btntemp)
    local len = #btntemp
    local btnT = self.btnTab
    local count = #btnT
    local max = count >= len and count or len
    local min = count + len - max
    for i = 1,max do
        if i <= min then
            btnT[i]:UpdateData(btntemp[i])
            btnT[i]:BtnAct(true)
        elseif i <= count then
            btnT[i]:BtnAct(false)
        else
            local go = Instantiate(self.btnItem)
            TransTool.AddChild(self.btnGrid.transform,go.transform)
            local item = ObjPool.Get(PVPBtn)
            item:Init(go)
            item.Gbj.name = i
            -- local box = go.transform:GetComponent("BoxCollider")
            UITool.SetLsnrSelf(go,self.Switch,self,"btn",false)
            item:BtnAct(true)
            item:UpdateData(btntemp[i])
            table.insert(self.btnTab, item)
        end
    end
    self.btnGrid:Reposition()
end

function My:Switch(obj)
    local seIndex = 1
    if obj == nil then
        seIndex = self.selectBtn
    else
        seIndex = tonumber(obj.name)
    end
    self.selectBtn = seIndex
    local it = self.btnTab[seIndex]
    local cur = self.cur
    if cur == it then return end
    if cur then
        cur:SelectAct(false)
    end
    self.cur = it
    it:SelectAct(true)
    self:ShowDifPanel()
end

function My:ShowDifPanel()
    local isSingle = self.isSingle
    local difOpen = self.difOpen
    local selectIndex = self.selectBtn
    self.singleGbj:SetActive(isSingle)
    self.mulGbj:SetActive(not isSingle)
    if isSingle then
        self.sinRewardV:SetActive(selectIndex == 1)
        self.sinReLab:SetActive(selectIndex == 1)
        self.sinRankV:SetActive(selectIndex == 2)
        self.sinRankLab:SetActive(selectIndex == 2)
        self:SetMySinRank()
    else
        self.mulRewardV:SetActive(selectIndex == 1 or selectIndex == 2)
        self.mulReLab:SetActive(selectIndex == 1)
        self.mulRankV:SetActive(selectIndex == 3)
        self.mulRankLab:SetActive(selectIndex == 3)
        self:SetMyMulRank()
    end
    self:ShowDifData(isSingle,selectIndex)
    self.scrollVRewd:ResetPosition()
end

function My:ShowDifData(isSingle,selectIndex)
    local sinRedP = self.sinRewardP
    local sinRankP = self.sinRankP
    local mulReP = self.mulRewardP
    local mulTarP = self.mulTargetP
    local mulReTab = mulReP.itemTab
    local mulTarTab = mulTarP.itemTab
    local mulRankP = self.mulRankP
    self.sinRankDes:SetActive(false)
    self.mulRankDes:SetActive(false)
    if isSingle then
        if selectIndex == 1 then
            sinRedP:RefreshData()
        elseif selectIndex == 2 then
            local data = Peak.PlayerRanks
            local len = #data
            self.sinRankDes:SetActive(len <= 0)
            self.sinRankLab:SetActive(len > 0)
            sinRankP:RefreshData()
        end
    else
        if selectIndex == 1 then
            mulReP:RefreshData()
            if mulTarTab and #mulTarTab > 0 then
                mulTarP:ActiveItems(false)
            end
        elseif selectIndex == 2 then
            mulTarP:RefreshData()
            if mulReTab and #mulReTab > 0 then
                mulReP:ActiveItems(false)
            end
        elseif selectIndex == 3 then
            local data = Peak.PlayerRanks
            local len = #data
            self.mulRankDes:SetActive(len <= 0)
            self.mulRankLab:SetActive(len > 0)
            mulRankP:RefreshData()
        end
    end
end

--设置自己的排行
function My:SetMySinRank()
    local info = Peak.MyRank
    local power = info.rolePower
    local rank = info.rank
    power = math.NumToStrCtr(power)
    if rank == 0 then
        rank = "未上榜"
    end
    self.myRankLab.text = rank
    self.myNameLab.text = info.roleName
    self.myOccLab.text = UIMisc.GetWork(info.roleCate)
    self.myWarLab.text = power
    self.myScoreLab.text = info.roleScore
end

--设置跨服排名信息
function My:SetMyMulRank()
    local info = Peak.MyRank
    local serverTime = TimeTool.GetServerTimeNow()*0.001
    local seasonStart = Peak.RoleInfo.seasonStartTimes
    local seasonEnd = Peak.RoleInfo.seasonStopTimes
    local seasonTimes = Peak.RoleInfo.season
    local myRank = info.rank
    if myRank > 0 then
        myRank = myRank .. "名"
    elseif myRank == 0 then
        myRank = "未上榜"
    end
    local data = Peak:GetDanInfoByScr(info.roleScore)
    local myDanName = data.danName
    serverTime = os.date("%Y", serverTime)
    seasonStart = os.date("%Y-%m-%d", seasonStart)
    seasonEnd = os.date("%Y-%m-%d %H:%M", seasonEnd)
    self.curSeasonLab.text = string.format("当前赛季：%s年第%s赛季",serverTime,seasonTimes)
    self.seasonTime.text = string.format("%s - %s",seasonStart,seasonEnd)
    self.myLvMLab.text = "我的段位："
    self.lvMLab.text = myDanName
    self.myRankMlab.text = "我的排名："
    self.rankMLab.text = myRank
    self.myScoreMLab.text = "论剑积分："
    self.scoreMLab.text = info.roleScore
end

function My:CloseC()
    if self.cur then
        self.cur:SelectAct(false)
        self.cur = nil
    end
    self.Gbj.gameObject:SetActive(false)
end

function My:AddPool()
    self:TabToPool(self.btnTab)
    if self.sinRewardP then
        ObjPool.Add(self.sinRewardP)
        self.sinRewardP = nil
    end
    if self.sinRankP then
        ObjPool.Add(self.sinRankP)
        self.sinRankP = nil
    end
    if self.mulRewardP then
        ObjPool.Add(self.mulRewardP)
        self.mulRewardP = nil
    end
    if self.mulTargetP then
        ObjPool.Add(self.mulTargetP)
        self.mulTargetP = nil
    end
    if self.mulRankP then
        ObjPool.Add(self.mulRankP)
        self.mulRankP = nil
    end
end

function My:TabToPool(tab)
    for k,v in pairs(tab) do
        ObjPool.Add(v)
        tab[k] = nil
    end
end

function My:Dispose()
    self:AddPool()
    TableTool.ClearUserData(self)
end