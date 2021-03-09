UITopFightEnd = UIBase:New{Name="UITopFightEnd"}
local My = UITopFightEnd;

require("UI/UIArena/UITopFightEndIt")

function My:InitCustom()
    local root = self.root;
    local name = "青云之巅结算面板";
    local CG = ComTool.Get;
    local TF = TransTool.FindChild;
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local str = "InfoList/Myitem"

    self.rank = CG(UILabel, root, str.."/Rank", name)
    self.roleName = CG(UILabel, root, str.."/Name", name)
    self.useTime = CG(UILabel, root, str.."/Score", name)
    self.myGrid = Find(root, str.."/Grid", name)
    self.endLab = TF(root, str.."/Label", name)

    self.timeLab = CG(UILabel, root, "Time", name)
    self.item = TF(root, "InfoList/ScrollView/Grid/item", name)
    self.item:SetActive(false)
    self.grid = self.item.transform.parent
    self.Add = TransTool.AddChild
    self.cellList = {}

    SetB(root, "BtnOk", name, self.OnSure, self)
    SetB(root, "Close", name, self.OnSure, self)

    UITopFight.root.gameObject:SetActive(false)

    self:CreateTimer()
    self:UpTimer(30)
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    local mgr = TopFightMgr
    mgr.UpRank[func](mgr.UpRank, self.RespUpRank, self)
    mgr.UpSelfRank[func](mgr.UpSelfRank, self.RespUpSelfRank, self)
end

--响应更新排行榜
function My:RespUpRank(rank, name, time, roleId, isRank, floor, score)
    local item = Instantiate(self.item)
    local tran = item.transform
    item:SetActive(true)
    self.Add(self.grid, tran)
    local it = ObjPool.Get(UITopFightEndIt)
    it:Init(tran)
    local isSelf = roleId == User.MapData.UIDStr
    it:SetData(rank, name, time, floor, score, isSelf)
    --在排行内
    if isRank and isSelf then self:SetMyItem(floor, score, rank, name, time) end
end

--响应自身排行(不在排行内)
function My:RespUpSelfRank(useTime)
    self:InitMyItem(useTime)
end

--设置自身的结算项
function My:SetMyItem(floor, score, rank, roleName, useTime)
    local isPass = self:IsPass(floor, score)
    if isPass then
        self.rank.text = rank
        self.roleName.text = roleName
        local timeStr = CustomInfo:ConvertSec(useTime)
        self.useTime.text = timeStr
        self.endLab:SetActive(false)
        self:UpCell(rank)
        if UITopFight then
            UITopFight:SetAwardLab("奖励已全部领取")
        end
    else
        self:InitMyItem()
    end
end

--判断是否通关
function My:IsPass(floor, score)
    local info = TopFightInfo
    local key = tostring(floor)
    local cfg = TopFScoreCfg[key]
    if cfg == nil then return end
    if info.max == floor and score >= cfg.score then
        return true
    end
    return false
end

--初始化自身的结算项
function My:InitMyItem(useTime)
    self.rank.text = "未上榜"
    self.roleName.text = User.MapData.Name
    self.useTime.text = "未通关"
end

--更新Cell
function My:UpCell(rank)
    local key = tostring(rank)
    local cfg = TopFRankCfg[key]
    if cfg == nil then return end
    local list = {}
    for i,v in ipairs(cfg.award) do
        table.insert(list, v)
    end
    for i,v in ipairs(list) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.myGrid, 0.65)
        cell:UpData(v.k, v.v)
        table.insert(self.cellList, cell)
    end
end

--点击确定按钮
function My:OnSure()
    self:Close()
    SceneMgr:QuitScene()
end

--初始化计时器文本
function My:UpTimerLab(time)
    if self.timeLab then
        self.timeLab.text = time.."s后关闭比赛"
    end
end

--更新计时器
function My:UpTimer(time)
    if self.timer == nil then iTrace.Error("SJ", "没有发现计时器") return end
    local timer = self.timer
    timer.seconds = time
	timer:Start()
end

--创建计时器
function My:CreateTimer()
    if self.timer then return end
	self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
end

--间隔倒计时
function My:InvCountDown()
    local times = self.timer:GetRestTime()
    local time = math.floor(times)
    self:UpTimerLab(time)
end

--结束倒计时
function My:EndCountDown()
	self:OnSure()
end

--清理缓存
function My:Clear()

end

--重写释放资源
function My:DisposeCustom()
    self:Clear()
    self:SetLnsr("Remove")
    if self.timer then
		self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
    end
    TableTool.ClearListToPool(self.cellList)
end

return My