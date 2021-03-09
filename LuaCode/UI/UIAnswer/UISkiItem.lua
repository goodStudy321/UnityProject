--[[
 	authors 	:Liu
 	date    	:2018-5-9 14:37:40
 	descrition 	:技能项
--]]

UISkiItem = Super:New{Name = "UISkiItem"}

local My = UISkiItem

local AssetMgr = Loong.Game.AssetMgr

function My:Init(root, index)
    local des = self.Name
    local CG = ComTool.Get

    self.root = root
    self.index = index
    self.coldTime = (index == 1) and 40 or 60
    self.skiStr = (index == 1) and "AnswerSkill_1.png" or "AnswerSkill_2.png"
    self.clickEff = "UI_Skill_Clik1"
    self.coldDownEff = "UI_Skill_ColdDown"
    self.mask = CG(UISprite, root, "mask")
    self.Tex = CG(UITexture, root, "tex")
    self.timeLab = CG(UILabel, root, "timeLab")
    self.isHurt = false
    UIEvent.Get(root.gameObject).onPress = UIEventListener.BoolDelegate(self.OnPress, self)
    UITool.SetBtnSelf(root, self.OnSkiClick, self, des)
    self.mask.fillAmount = 0
    self:LoadSkiIcon()
    self:CreateTimer()
end

--检测鼠标按下
function My:OnPress(go, isPress)
    if not go then return end
    if isPress then
        self.IsAutoClick = Time.realtimeSinceStartup
    else
        self.IsAutoClick = nil
        local ui = UIMgr.Get(UIComTips.Name)
        if ui then
            ui:Close()  
        end
    end
end

--检查鼠标持续按下
function My:Update()
    if self.IsAutoClick then
		if Time.realtimeSinceStartup - self.IsAutoClick > 0.25 then
			self.IsAutoClick = Time.realtimeSinceStartup
			self:ShowSkillInfo()
		end
	end
end

--显示技能信息
function My:ShowSkillInfo()
    local str1 = "踢人：随机将一个玩家\n从一侧踢到另外一侧"
    local pos1 = Vector3.New(390, -214, 0)
    local str2 = "混乱：造成随机一个玩家在3秒\n内不能控制方向和释放技能"
    local pos2 = Vector3.New(470, -120, 0)
    if self.index == 1 then
        UIComTips:Show(str2, pos2)
    else
        UIComTips:Show(str1, pos1)
    end
end

--点击技能
function My:OnSkiClick()
    if self.isHurt then
        UITip.Log("混乱中不能使用技能")
        return
    end
    self:UseSki(self.mask)
end

--使用技能
function My:UseSki(mask)
    if mask.fillAmount == 0 then
        --拿到玩家3米范围内的某一个玩家的Uid
        local target = FindHelper.instance:GetRdmUnitByDis(3)
        if tostring(target) == "0" then
            UITip.Log("技能周围内，没有可攻击的玩家")
            return
        end
        self:UnloadEff(self.coldDownEff)
        mask.fillAmount = 1
        local interval = Time.deltaTime
        self.timer:Restart(self.coldTime, interval)
        --设置技能UI特效
        self:SetSkiEff(self.clickEff)
        local posIndex = AnswerInfo.GetXPos()
        if posIndex == -1 then return end
        --答题技能攻击请求
        AnswerMgr:ReqAnswerAtk(self.index, posIndex, tostring(target))
    end
end

--设置技能特效
function My:SetSkiEff(path)
    AssetMgr.LoadPrefab(path, GbjHandler(self.LoadSkiEff, self))
end

--技能特效
function My:LoadSkiEff(go)
    self.eff = go
    local tran = go.transform
    TransTool.AddChild(self.root, tran)
    tran.localEulerAngles = Vector3.zero
end

--卸载特效
function My:UnloadEff(effName)
    if self.eff then
        AssetMgr.Instance:Unload(effName, false)
        self.eff = nil
    end
end

--加载技能图标
function My:LoadSkiIcon()
    AssetMgr.Instance:Load(self.skiStr, ObjHandler(self.SetIcon, self))
end

--设置技能图标
function My:SetIcon(tex)
    if self.Tex then
        self.Tex.mainTexture = tex
    end
end

--设置倒计时文本
function My:SetTimeLab(sec)
    local str = (sec < 1) and 0 or sec
    self.timeLab.text = str
end

--创建计时器
function My:CreateTimer()
    if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
end

--间隔倒数
function My:InvCountDown()
    local time = self.timer:GetRestTime()
    self.mask.fillAmount = time / self.coldTime
    local sec = math.floor(time)
    self:SetTimeLab(sec)
end

--结束倒计时
function My:EndCountDown()
    self.mask.fillAmount = 0
    self:UnloadEff(self.clickEff)
    self:SetSkiEff(self.coldDownEff)
    self.timeLab.text = ""
end

--清理缓存
function My:Clear()
    self.isHurt = false
end

--释放资源
function My:Dispose()
    self:Clear()
    if self.timer then
        self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
    end
    AssetMgr.Instance:Unload(self.skiStr, false)
    AssetMgr.Instance:Unload(self.clickEff, false)
    AssetMgr.Instance:Unload(self.coldDownEff, false)
end

return My