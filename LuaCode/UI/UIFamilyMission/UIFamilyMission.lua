--[[
 	authors 	:Liu
 	date    	:2019-6-15 16:00:00
 	descrition 	:帮派任务界面
--]]

UIFamilyMission = UIBase:New{Name = "UIFamilyMission"}

local My = UIFamilyMission

require("UI/UIFamilyMission/UIFamilyMissionIt")

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.itList = {}
    self.curIt = nil--当前操作的任务项
    self.curIndex = nil
    self.NorRefresh = false

    self.btnLab1 = CG(UILabel, root, "btn1/lab1")
    self.btnLab2 = CG(UILabel, root, "btn2/lab1")
    self.btnLab1Lab = CG(UILabel, root, "btn1/lab")
    self.btnLab1LabSp = CG(UISprite, root, "btn1/spr1")
    self.btnLab1Lab.text = "绑元刷新"
    self.btnLab1LabSp.spriteName = "money_03"
    -- self.tipLab = CG(UILabel, root, "tipSpr/lab")
    self.grid = CG(UIGrid, root, "Scroll View/Grid")
    self.btn2 = FindC(root, "btn2", des)
    self.action = FindC(root, "btn2/action", des)
    self.item = FindC(root, "Scroll View/Grid/item", des)
    self.item:SetActive(false)

    SetB(root, "CloseBtn", des, self.OnClose, self)
    SetB(root, "btn1", des, self.OnBtn1, self)
    SetB(root, "btn2", des, self.OnBtn2, self)
    SetB(root, "tipSpr", des, self.OnTips, self)

    self:SetLnsr("Add")

    FamilyMissionMgr:ReqInfo()
end

--设置监听
function My:SetLnsr(func)
    local mgr = FamilyMissionMgr
    mgr.eUpMenu[func](mgr.eUpMenu, self.RespUpMenu, self)
    mgr.eUpMission[func](mgr.eUpMission, self.RespUpMission, self)
    mgr.eUpMissionInfo[func](mgr.eUpMissionInfo, self.RespUpMissionInfo, self)
    mgr.eRefresh[func](mgr.eRefresh, self.RespRefresh, self)
    mgr.eNorRefresh[func](mgr.eNorRefresh, self.RespNorRefresh, self)
    -- mgr.eClickSpeed[func](mgr.eClickSpeed, self.RespClickSpeed, self)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
function My:OnAdd(action,dic)
	if action==10395 then
		self.dic=dic
		UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
	end
end

--显示奖励的回调方法
function My:RewardCb(name)
	local ui = UIMgr.Get(name)
    if(ui)then
        ui:UpdateData(self.dic)
	end
end

--响应更新界面
function My:RespUpMenu()
    self:UpLab()
    self:UpItem()
    self:RefreshBtn()
    if self.NorRefresh == true then
        for i,v in ipairs(self.itList) do
            v:UpBg()
            v:SetEff()
        end
        self.NorRefresh = false
    end
end

--响应更新任务
function My:RespUpMission(missionId, state)
    for i,v in ipairs(self.itList) do
        if v.id and v.id == missionId then
            self.curIt = v
        end
    end
    local str = ""
    if state == 0 then
        str = "已接受任务"
    elseif state == 1 then
        str = "已向其他道庭成员发送求助信息"
    elseif state == 2 then
        str = "已放弃任务"
    end
    if StrTool.IsNullOrEmpty(str) then return end
    UITip.Log(str)
end

--响应更新界面信息
function My:RespUpMissionInfo(missionId, state, count, startTime, endTime)
    if self.curIt then--有可能是新的任务替换旧的任务
        self.curIt:UpData(missionId, state, count, startTime, endTime)
        self.curIt = nil
    else
        for i,v in ipairs(self.itList) do
            if v.id and v.id == missionId then
                v:UpData(missionId, state, count, startTime, endTime)
            end
        end
    end
    self:UpLab()
end

--响应极品刷新
function My:RespRefresh(missionId)
    for i,v in ipairs(self.itList) do
        if v.id and v.id == missionId then
            self.curIt = v
            self.curIt:UpBg()
            self.curIt:SetEff()
        end
    end
    self:RefreshBtn()
    UITip.Log("任务已刷新")
end

--响应元宝刷星
function My:RespNorRefresh()
    self.NorRefresh = true
end

-- --点击加速
-- function My:RespClickSpeed()
--     self:UpItem()
-- end

--更新任务项
function My:UpItem()
    local Add = TransTool.AddChild
    local list = self.itList
    local mList = FamilyMissionInfo.missionList
    local gridTran = self.grid.transform
    local num = #mList - #list

    if num > 0 then
        for i=1, num do
            local go = Instantiate(self.item)
            local tran = go.transform
            go:SetActive(true)
            Add(gridTran, tran)
            local it = ObjPool.Get(UIFamilyMissionIt)
            it:Init(tran)
            it:SetBg()
            table.insert(self.itList, it)
        end
    end
    self:RefreshItem(mList, list)
    self.grid:Reposition()
end

--刷新任务项
function My:RefreshItem(mList, list)
    table.sort(mList, function(a,b) return a.missionId < b.missionId end)
    for i,v in ipairs(mList) do
        list[i]:UpData(v.missionId, v.state, v.count, v.startTime, v.endTime)
    end
end

--初始化文本
function My:UpLab()
    local info = FamilyMissionInfo
    local num = info:GetRefreshWeight()
    self.btnLab1.text = info:GetRefreshGold() or "??"
    -- self.tipLab.text = string.format("达到Vip4以上玩家必出%s星以上任务", info:GetVipWeight() or "??")
    if FamilyMissionInfo.isRefresh then
        self.btnLab2.text = string.format("必出%s星以上任务", num or "??")
    else
        local cfg = GlobalTemp["142"]
        if cfg then
            local val1 = cfg.Value2[1]
            local val2 = cfg.Value2[2]
            local hour = SignInfo:GetTime("HH")
            local time = (hour>=val1 and hour<val2 ) and val2 or val1
            self.btnLab2.text = string.format("%s点重置", time)
        end
    end
end

--刷新极品刷新按钮状态
function My:RefreshBtn()
    local isRefresh = FamilyMissionInfo.isRefresh
    if isRefresh then
        UITool.SetNormal(self.btn2)
    else
        UITool.SetGray(self.btn2)
    end
    self.action:SetActive(isRefresh)
end

--点击元宝刷星
function My:OnBtn1()
    local gold = FamilyMissionInfo:GetRefreshGold()
    if gold == nil then return end
    if CustomInfo:IsBuySucc(gold) then
        if self:IsRefresh() then
            self.curIndex = 0
            local str = string.format("是否消耗%s绑元进行刷新(绑元不足消耗元宝)", gold)
            MsgBox.ShowYesNo(str, self.OnYes, self)
        end
    else
        StoreMgr.JumpRechange()
    end
end

--点击极品刷新
function My:OnBtn2()
    local info = FamilyMissionInfo
    if info.isRefresh then
        if self:IsRefresh() then
            self.curIndex = 1
            local num = info:GetRefreshWeight()
            local str = string.format("使用极品刷新后必出一个%s星任务，每天12点和18重置功能", num or "??")
            MsgBox.ShowYesNo(str, self.OnYes, self)
        end
    else
        UITip.Log("刷新次数不足")
    end
end

--点击提示
function My:OnTips()
    local cfg = InvestDesCfg["1902"]
    if cfg == nil then return end
    UIComTips:Show(cfg.des, Vector3(-30, -150, 0))
end

--点击确定
function My:OnYes()
    if self.curIndex then
        FamilyMissionMgr:ReqMissionRefresh(self.curIndex)
        self.curIndex = nil
    end
end

--是否能刷新
function My:IsRefresh()
    local maxStar = FamilyMissionInfo.maxStar
    for i,v in ipairs(self.itList) do
        if v.state and v.state == 0 and v.lv < maxStar then
            return true
        end
    end
    UITip.Log("执行中的任务和最高星级任务无法刷新！")
    return false
end

--打开（关闭时返回道庭界面）
function My:OpenTab(isRecord)
	self.isRecord = isRecord
	UIMgr.Open(UIFamilyMission.Name)
end

--点击关闭按钮
function My:OnClose()
	if self.isRecord == true then
        self:Close()
		UIMgr.Open(UIFamilyMainWnd.Name, self.OpenFamilyCb, self)
	else
		self:Close()
		JumpMgr.eOpenJump()
	end
end

--打开仙盟回调
function My:OpenFamilyCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:ChangePanel(1)
	end
end

--特殊的打开方式
function My:GetSpecial(t1)
    if CustomInfo:IsJoinFamily() == false then return false end
    if OpenMgr:IsOpen(33) == false then UITip.Log("系统未开启") return false end
    return true
end

--打开分页
function My:OpenTabByIdx(t1,t2,t3,t4)
    
end

--清理缓存
function My:Clear()
    self.isRecord = nil
    self.curIndex = nil
    self.curIt = nil
    self.dic = nil
    self.NorRefresh = false
end

--重写释放资源
function My:DisposeCustom()
	self:Clear()
    self:SetLnsr("Remove")
    ListTool.ClearToPool(self.itList)
end

return My