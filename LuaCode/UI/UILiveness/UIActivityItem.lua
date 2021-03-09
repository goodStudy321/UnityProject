--[[
 	authors 	:Liu
 	date    	:2018-4-10 15:09:28
 	descrition 	:活动项
--]]

UIActivityItem = Super:New{Name="UIActivityItem"}

local My = UIActivityItem

-- 初始化活动项
function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local CGS = ComTool.GetSelf
    local FindC = TransTool.FindChild
    local str = "joinBtn"

    self.root = root
    self.cfg = cfg

    self.label = CG(UILabel, root, "ActivityName")
    self.liveLab = CG(UILabel, root, "Liveness/Label")
    self.countLab = CG(UILabel, root, "Count/Label")
    self.joinLab = CG(UILabel, root, str.."/Label")
    self.typeSpr = CG(UISprite, root, "typeSpr")
    self.joinBtn = CG(UIButton, root, str)
    self.joinSpr = CG(UISprite, root, str)
    self.Tex = CG(UITexture, root, "Tex")
    self.tog = CGS(UIToggle, root, des)

    AssetMgr:Load(cfg.icon, ObjHandler(self.SetTex, self))

    UITool.SetBtnSelf(root, self.OnItemClick, self, des)
    
    self:UpShow(cfg)
    self:InitTypeSpr(cfg)
end

--点击活动项
function My:OnItemClick()
    local xPos = self.root.localPosition.x
    UILiveness:SetDesPos(xPos)
    LivenessInfo.btnIndex = self.cfg.id
    self:UpdateShow()
end

--更新描述模块
function My:UpdateShow()
    local cfg = self.cfg
    local id = (cfg.id == 19) and 16 or cfg.id
    local key = tostring(id)
    UILiveness.detail:UpShow(cfg, LivenessInfo.countDic[key])
end

--点击参加按钮
function My:OnJoinClick()
    local id = self.cfg.id
    if id == 1 then--日常任务
        if LuaTool.Length(MissionMgr.TurnList) > 0 then
			self:MissionTrigger(MissionType.Turn)
		else
			UITip.Log("无可接受的日常任务")
		end
    elseif id == 18 then--道庭任务
        if CustomInfo:IsJoinFamily() then
            if OpenMgr:IsOpen(33) then
                UIMgr.Open(UIFamilyMission.Name)
            else
                UITip.Log("系统未开启")
            end
        end
    elseif id == 29 then--推荐挂机点
        LivenessMgr:AutoHangup()
    elseif id == 23 then--道庭Boss
        if CustomInfo:IsJoinFamily() then
            UIMgr.Open(UIFamilyBossIt.Name)
        end
    elseif id == 16 then--道庭护送
        if CustomInfo:IsJoinFamily() then
            if FamilyEscortMgr:GetOpenStatus() then
                UIMgr.Open(UIFamilyEscort.Name)
            else
                UITip.Log("活动未开启")
            end
        end
    elseif id == 7 then--装备强化
        UITabMgr.OpenMenu(self.cfg.jumpInfo)
    else
        UITabMgr.Open(self.cfg.jumpInfo)
    end
    UIMgr.Close(UILiveness.Name)
end

--任务触发
function My:MissionTrigger(type)
    Hangup:SetAutoHangup(true);
    MissionMgr:AutoExecuteActionOfType(type)
end

--更新文本显示
function My:UpShow(cfg)
    self.label.text = cfg.name
    local val = LivenessMgr:GetCount(cfg)
    local labText = (val == 0) and val or cfg.once * val
    self.liveLab.text = labText.."/"..cfg.total
    self.countLab.text = val.."/"..cfg.count

    local go1 = self.countLab.transform.parent.gameObject
    local go2 = self.liveLab.transform.parent.gameObject
    go1:SetActive(cfg.count~=0)
    go2:SetActive(cfg.count~=0)
end

--初始化活动类型图标
function My:InitTypeSpr(cfg)
    local type = cfg.outType
    local spr = self.typeSpr
    local isShow = (type ~= 0)
    spr.gameObject:SetActive(isShow)
    if type == 1 then
        spr.spriteName = "hyd_jy"
    elseif type == 2 then
        spr.spriteName = "hyd_yl"
    elseif type == 3 then
        spr.spriteName = "hyd_zb"
    elseif type == 4 then
        spr.spriteName = "hyd_cl"
    elseif type == 5 then
        spr.spriteName = "hyd_bb"
    end
end

--未激活状态
function My:NotOpen(str)
    self:SetBtnColor(str, 0, false)
    self:SetGoName(self.cfg, 500)
end

--可参与状态
function My:MayEnter()
    self:SetBtnColor("参 加", 255, true)
    UITool.SetBtnClick(self.root, "joinBtn", self.Name, self.OnJoinClick, self)
    if (self.cfg.count == 0) then
        self:SetGoName(self.cfg, 200)
    else
        self:SetGoName(self.cfg, 100)
    end
end

--已完成状态
function My:YetComplete(str)
    self:SetBtnColor(str, 0, false)
    self:SetGoName(self.cfg, 400)
end

--设置活跃项名字
function My:SetGoName(cfg, num)
    local go = self.root.gameObject
    go.name = cfg.id + num
end

--设置按钮状态
function My:SetBtnState()
    local cfg = self.cfg
    local val = LivenessMgr:GetCount(cfg)
    if User.MapData.Level < cfg.lv then
        local str = string.format("%s级", cfg.lv)
        self:NotOpen(str)
    elseif val >= cfg.count and cfg.count ~= 0 then
        self:YetComplete("已完成")
    else
        self:MayEnter()
    end
end

--设置按钮颜色
function My:SetBtnColor(str, num, state)
    self.joinLab.text = str
    self.joinSpr.color = Color.New(num, 255, 255, 255) / 255.0
    self.joinBtn.enabled = state
end


--更新活动状态
function My:UpActivState()
    local cfg = self.cfg
    local key = tostring(cfg.activId)
    local info = ActiveInfo[key]
    if info == nil and cfg.id ~= 19 then iTrace.Error("SJ", "%s活动配置找不到", key) return end
    local oTime = (info == nil) and cfg.openTime or info.begTime
    local lTime = (info == nil) and cfg.existTime or info.lastTime
    local begDay = (info == nil) and cfg.time or info.begDay
    local hour, min = 0, 0

    for i,v in ipairs(oTime) do
        if i == 1 then
            hour = v.k
            min = v.v
        elseif i == 2 then
            local state = SignInfo:IsActivOpen(lTime, hour, min)
            if state == 2 then
                hour = v.k
                min = v.v
            end
        end
    end
    local sTime = math.floor(TimeTool.GetServerTimeNow()/1000)
    local val = DateTool.GetDate(sTime)
    local week = tostring(val.DayOfWeek)
    for i,v in ipairs(begDay) do
        if v == LivenessInfo.strTab[week] or v == 8 then
            local state = SignInfo:IsActivOpen(lTime, hour, min)
            if state == 1 then--活动开启中
                self:MayEnter()
            elseif state == 2 then--活动已结束
                self:YetComplete("已结束")
            else--活动未开启
                local val = (min == 0) and "00" or min
                local str = string.format("%s:%s", hour, val)
                self:SetBtnColor(str, 0, false)
                self:SetGoName(cfg, 300)
            end
            break
        else--活动未激活
            self:NotOpen("未开启")
        end
    end
end

--更新活动按钮状态
function My:UpBtnState()
    local cfg = self.cfg
    if User.MapData.Level < cfg.lv then
        local str = string.format("%s级", cfg.lv)
        self:NotOpen(str)
        return
    end
    local dic = ActivityMsg.OpenActList
    local activId = cfg.activId
    if dic[activId] then  self:MayEnter() end
end

--设置贴图
function My:SetTex(tex)
    if self.Tex then
        self.Tex.mainTexture = tex
    end
end

--清理缓存
function My:Clear()
    TableTool.ClearUserData(self)
end

-- 释放资源
function My:Dispose()
    AssetMgr:Unload(self.cfg.icon, false)
    self:Clear()
end

return My