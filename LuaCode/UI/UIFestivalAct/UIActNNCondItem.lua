--[[
 	authors 	:Liu
 	date    	:2019-2-14 15:00:00
 	descrition 	:你侬我侬条件项
--]]

UIActNNCondItem = Super:New{Name = "UIActNNCondItem"}

local My = UIActNNCondItem

function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.cfg = cfg
    self.go = root.gameObject
    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab2")
    self.tex = CG(UITexture, root, "sprBg/spr1")
    self.texLab = CG(UILabel, root, "sprBg/lab")
    self.btnLab = CG(UILabel, root, "btn/lab")
    self.btn = FindC(root, "btn", des)
    self.complete = FindC(root, "complete", des)

    SetB(root, "btn", des, self.OnBtn, self)

    self:ChangeName()
    self:InitDesLab()
    self:UpCondCount()
    self:InitIcon()
end

--点击立即前往
function My:OnBtn()
    local O = UIMgr.Open
    local type = self.cfg.jumpType
    local amgr = ActivityMgr
    local isShowTips = false

    if type == 100101 then--充值
        local IsShield = UITabMgr.Pattern2(1002)
		if not IsShield then VIPMgr.OpenVIP(1) else isShowTips = true end

    elseif type == 100102 then--世界Boss
        local isOpen = UITabMgr.IsOpen(amgr.BOSS)
		if isOpen then O(UIBoss.Name) end

    elseif type == 100103 then--个人BOSS
        local isOpen = OpenMgr:IsOpen(411)
        if isOpen then
            BossHelp.curType = 3
            O(UIBoss.Name)
        else 
            isShowTips = true 
        end

    elseif type == 100104 then--幽冥地界
        local isOpen = OpenMgr:IsOpen(410)
        if isOpen then
            BossHelp.curType = 4
            O(UIBoss.Name)
        else 
            isShowTips = true 
        end

    elseif type == 100105 then--符文寻宝
        local isOpen = OpenMgr:IsOpen(504)
        if isOpen then  UITreasure:OpenTab(2) else isShowTips = true end

    elseif type == 100106 then--装备寻宝
		local isOpen = UITabMgr.IsOpen(amgr.XB)
		if isOpen then UITreasure:OpenTab(1) end

    elseif type == 100107 then--闭关修炼
        --if PrayMgr:IsOpen() then UILvAward:OpenTab(5) else isShowTips = true end

        if PrayMgr:IsOpen() then
            UIRobbery:OpenRobbery(1);
        else isShowTips = true end

    elseif type == 100108 then--日常任务
        self:MissionTrigger(MissionType.Turn)

    elseif type == 100109 then--青竹院
        -- local isOpen = OpenMgr:IsOpen(401)
        local copy, isOpen = CopyMgr:GetCurCopy(CopyType.Exp)
		if isOpen then UICopy:Show(CopyType.Exp) else isShowTips = true end

    elseif type == 100110 then--失落谷
        -- local isOpen = OpenMgr:IsOpen(402)
        local copy, isOpen = CopyMgr:GetCurCopy(CopyType.SingleTD)
		if isOpen then UICopy:Show(CopyType.SingleTD) else isShowTips = true end

    elseif type == 100111 then--百湾角
        -- local isOpen = OpenMgr:IsOpen(405)
        local copy, isOpen = CopyMgr:GetCurCopy(CopyType.Glod)
		if isOpen then UICopy:Show(CopyType.Glod) else isShowTips = true end

    elseif type == 100112 then--幽魂林
        -- local isOpen = OpenMgr:IsOpen(408)
        local copy, isOpen = CopyMgr:GetCurCopy(CopyType.XH)
        if isOpen then UICopy:Show(CopyType.XH) else isShowTips = true end

    elseif type == 100113 then--逍遥神坛
        local isOpen = UITabMgr.IsOpen(amgr.QYZD)
        if isOpen then UIMgr.Open(UITopFightIt.Name) end

    elseif type == 100114 then--诛仙战场
        local isOpen = UITabMgr.IsOpen(amgr.JJD)
        if isOpen then UIArena.OpenArena(4) end
        
    elseif type == 100115 then--仙峰论剑
        local isOpen = UITabMgr.IsOpen(amgr.JJD)
        if isOpen then UIArena.OpenArena(2) end

    elseif type == 100116 then--许愿池
        local isOpen = UITabMgr.IsOpen(amgr.XYC)
        if isOpen then O(UIWish.Name) end

    elseif type == 100117 then--神兽岛
        local isOpen = OpenMgr:IsOpen(413)
        if isOpen then
            BossHelp.curType = 5
            O(UIBoss.Name)
        else 
            isShowTips = true
        end

    elseif type == 100118 then--洞天福地
        local isOpen = OpenMgr:IsOpen(412)
        if isOpen then
            BossHelp.curType = 2
            O(UIBoss.Name)
        else 
            isShowTips = true 
        end

    elseif type == 100119 then--远古遗迹
        local isOpen = OpenMgr:IsOpen(415)
        if isOpen then
            BossHelp.curType = 7
            BossHelp.OpenBoss(7)
        else 
            isShowTips = true 
        end

    elseif type == 100120 then--装备副本
        -- local isOpen = OpenMgr:IsOpen(404)
        local copy, isOpen = CopyMgr:GetCurCopy(CopyType.Equip)
        if isOpen then UICopy:Show(CopyType.Equip) else isShowTips = true end
    end

    if isShowTips then UITip.Log("系统未开启") end
end

--初始化贴图
function My:InitIcon()
    local type = self.cfg.jumpType
    if type == 100101 then--充值
        self:UpIcon("sys_29.png")
        self:UpIconName("充值")
    elseif type == 100102 then--世界Boss
        self:UpIcon("sys_17.png")
        self:UpIconName("世界Boss")
    elseif type == 100103 then--个人BOSS
        self:UpIcon("sys_17.png")
        self:UpIconName("个人BOSS")
    elseif type == 100104 then--幽冥地界
        self:UpIcon("sys_17.png")
        self:UpIconName("幽冥地界")
    elseif type == 100105 then--符文寻宝
        self:UpIcon("sys_50.png")
        self:UpIconName("符文寻宝")
    elseif type == 100106 then--装备寻宝
        self:UpIcon("sys_33.png")
        self:UpIconName("装备寻宝")
    elseif type == 100107 then--闭关修炼
        self:UpIcon("sys_44.png")
        self:UpIconName("闭关修炼")
    elseif type == 100108 then--日常任务
        self:UpIcon("sys_7.png")
        self:UpIconName("日常任务")
    elseif type == 100109 then--青竹院
        self:UpIcon("sys_24.png")
        self:UpIconName("青竹院")
    elseif type == 100110 then--失落谷
        self:UpIcon("sys_32.png")
        self:UpIconName("失落谷")
    elseif type == 100111 then--百湾角
        self:UpIcon("sys_32.png")
        self:UpIconName("百湾角")
    elseif type == 100112 then--幽魂林
        self:UpIcon("sys_32.png")
        self:UpIconName("幽魂林")
    elseif type == 100113 then--逍遥神坛
        self:UpIcon("sys_34.png")
        self:UpIconName("逍遥神坛")
    elseif type == 100114 then--诛仙战场
        self:UpIcon("sys_32.png")
        self:UpIconName("诛仙战场")
    elseif type == 100115 then--仙峰论剑
        self:UpIcon("sys_36.png")
        self:UpIconName("仙峰论剑")
    elseif type == 100116 then--许愿池
        self:UpIcon("sys_33.png")
        self:UpIconName("许愿池")
    elseif type == 100117 then--神兽岛
        self:UpIcon("sys_36.png")
        self:UpIconName("神兽岛")
    elseif type == 100118 then--洞天福地
        self:UpIcon("sys_17.png")
        self:UpIconName("洞天福地")
    elseif type == 100119 then--远古遗迹
        self:UpIcon("sys_17.png")
        self:UpIconName("远古遗迹")
    elseif type == 100120 then--装备副本
        self:UpIcon("sys_32.png")
        self:UpIconName("装备副本")
    end
end

--更新跳转图标名称
function My:UpIconName(str)
    self.texLab.text = str
end

--初始化兑换道具
function My:UpIcon(texName)
    self.texName = texName
    AssetMgr:Load(self.texName, ObjHandler(self.SetIcon, self))
end

--设置贴图
function My:SetIcon(tex)
    self.tex.mainTexture = tex
end

--任务触发
function My:MissionTrigger(type)
    Hangup:SetAutoHangup(true);
    MissionMgr:AutoExecuteActionOfType(type)
end

--初始化描述文本
function My:InitDesLab()
    self.lab1.text = self.cfg.des
end

--更新条件次数
function My:UpCondCount()
    local cfg = self.cfg
    local str = string.format("%s/%s", cfg.count, cfg.allCount)
    self.lab2.text = str
    self:UpBtnState(cfg.count, cfg.allCount)
end

--更新按钮状态
function My:UpBtnState(count, allCount)
    if count >= allCount then
        self.btn:SetActive(false)
        self.complete:SetActive(true)
    end
end

--初始化名字
function My:ChangeName()
    local num = 0
    local cfg = self.cfg
    if cfg.count >= cfg.allCount then
        num = cfg.id + 5000
    else
        num = cfg.id + 1000
    end
    self.go.name = num
end

--清理缓存
function My:Clear()
    TableTool.ClearUserData(self)
end

--释放资源
function My:Dispose()
    self:Clear()
    AssetMgr:Unload(self.texName,false)
end

return My