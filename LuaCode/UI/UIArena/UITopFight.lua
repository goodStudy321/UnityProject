UITopFight = UIBase:New{Name="UITopFight"}
local My = UITopFight;

function My:InitCustom()
    local root = self.root;
    local name = "青云之巅";
    local CG = ComTool.Get;
    local TF = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;
    local SetB = UITool.SetBtnClick
    local str = "Info/award/title"

    self.helpTip = TF(root,"Info/HelpPanel",name);
    self.exitBtn = TF(root, "exitBtn", name);
    self.curLayer = CG(UILabel,root,"Info/lab",name);
    self.actTime = CG(UILabel,root,"Info/timeCount/lab",name);
    self.curLayerKill = CG(UILabel,root,str,name);
    self.curKill = CG(UILabel,root,str.."/lab",name);
    self.exitTime = CG(UILabel,root,"ExitTip/timeCount",name);
    self.grid = CG(UIGrid,root,"Info/award/Scroll View/Grid",name)
    self.rank = CG(UILabel, root, "Info/award/rank", name)
    self.Label = CG(UILabel, root, "Info/award/Label", name)

    if ScreenMgr.orient == ScreenOrient.Left then
        UITool.SetLiuHaiAnchor(root, "Info", name, true)
    end

    UC(root,"Info/helpSpr",name,self.OnHelp,self);
    UC(root,"exitBtn",name,self.OnExit,self);
    SetB(self.helpTip.transform, "boxCol", name, self.OnTip, self)
    self.cellList = {}
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	local mgr = TopFightMgr
    mgr.eUpTimer[func](mgr.eUpTimer, self.RespUpTimer, self)
    mgr.eEndTimer[func](mgr.eEndTimer, self.RespEndTimer, self)
    mgr.eTopInfo[func](mgr.eTopInfo, self.RespTopInfo, self)
    mgr.eUpTopInfo[func](mgr.eUpTopInfo, self.RespUpTopInfo, self)
    UIMainMenu.eHide[func](UIMainMenu.eHide, self.RespBtnHide, self)
    ScreenMgr.eChange[func](ScreenMgr.eChange, self.ScrChg, self)
end

--屏幕发生旋转
function My:ScrChg(orient)
	if orient == ScreenOrient.Left then
		UITool.SetLiuHaiAnchor(self.root, "Info", nil, true)
	elseif orient == ScreenOrient.Right then
		UITool.SetLiuHaiAnchor(self.root, "Info", nil, true, true)
	end
end

--响应更新计时器
function My:RespUpTimer(remain, time)
    self.actTime.text = remain
    self:ShowExitTime(time)
end

--响应结束计时器
function My:RespEndTimer()
    self.actTime.text = "00:00"
end

--响应青云之巅信息
function My:RespTopInfo(score, rank)
    self:SetCurLayer()
    self:SetCurKill(score)
    self:SetRankInfo(rank)
    self:SetAwards()
end

--响应更新青云之巅信息
function My:RespUpTopInfo(score, rank)
    self:SetCurLayer()
    self:SetCurKill(score)
    self:SetRankInfo(rank)
end

--响应隐藏退出按钮
function My:RespBtnHide(value)
    self.exitBtn:SetActive(value)
end

--点击帮助按钮
function My:OnHelp(go)
    self.helpTip:SetActive(true)
end

--点击提示面板
function My:OnTip()
    self.helpTip:SetActive(false)
end

--点击退出
function My:OnExit(go)
    MsgBox.ShowYesNo("是否退出场景？", self.YesCb, self)
end

--点击确定按钮
function My:YesCb()
    SceneMgr:QuitScene()
end

--设置自身排行信息
function My:SetRankInfo(rank)
    local str = (rank==0) and "未上榜" or "第"..rank.."名"
    self.rank.text = string.format("[F39800FF]当前排行：[66C34EFF]%s", str)
end

--设置当前击败
function My:SetCurKill(score)
    local layer = self:GetCurLayer()
    if layer == nil then return end
    local info = TopFightInfo
    info.max = self:GetMaxLayer()
    if info.max == 0 then
        iTrace.Error("SJ", "请检查配置表！")
        return
    else
        if layer >= info.max then
            self.curLayerKill.text = "通过条件：击败数"
        end
        local key = tostring(layer)
        local cfg = TopFScoreCfg[key]
        if cfg == nil then iTrace.Error("SJ", "该层的配置为空！") return end
        self.curKill.text = string.format("[66C34EFF]%s[F4DDBDFF]/%s", score, cfg.score)
    end
end

--活动结束时，设置奖励文本
function My:SetAwardLab(str)
    self.Label.text = str
end

--设置当前层
function My:SetCurLayer()
    local layer = self:GetCurLayer()
    if layer == nil then return end
    self.curLayer.text = string.format("[F4DDBDFF]当前：[F39800FF]第%s层", layer)
end

--获取当前层数
function My:GetCurLayer()
    local layer = User.SceneId
    for k,v in pairs(TopFScoreCfg) do
        if v.mapId == layer then
            return v.id
        end
    end
    -- iTrace.Error("SJ", "获取的层数为空！")
    return nil
end

--获取最大层数
function My:GetMaxLayer()
    local index = 0
    for k,v in pairs(TopFScoreCfg) do
        index = index + 1
    end
    return index
end

--显示退出时间
function My:ShowExitTime(time)
    if time <= 30 then
        local et = self.exitTime
        local parent = et.transform.parent
        parent.gameObject:SetActive(true)
        et.text = DateTool.FmtSec(time, 3, 2)
    end
end

--设置奖励
function My:SetAwards()
    TableTool.ClearListToPool(self.cellList)
    local layer = self:GetCurLayer()
    if layer == nil then return end
    local key = tostring(layer)
    local cfg = TopFScoreCfg[key]
    if cfg == nil then return end
    local exp = PropTool.GetExp(cfg.expRate) / 10000
    local dic = {k = 100, v = exp}
    local list = {}
    table.insert(list, dic)
    for i,v in pairs(cfg.award) do
        table.insert(list, v)
    end
    for i,v in ipairs(list) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.grid.transform, 0.7)
        cell:UpData(v.k, v.v)
        cell.Lab.text = "[00FF00FF]"..cell.Lab.text
        table.insert(self.cellList, cell)
    end
    self.grid:Reposition()
end

--重写UIBase方法，持续显示
function My:ConDisplay()
    do return true end
end

--清理缓存
function My:Clear()
    
end

--重写释放资源
function My:DisposeCustom()
    self:Clear()
    self:SetLnsr("Remove")
    TableTool.ClearListToPool(self.cellList)
end

return My