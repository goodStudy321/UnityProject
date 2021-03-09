--[[
 	authors 	:Liu
 	date    	:2019-3-21 11:00:00
 	descrition 	:限时活动界面4(条件项)
--]]

UIActivMenu4CondIt = Super:New{Name="UIActivMenu4CondIt"}

local My = UIActivMenu4CondIt

function My:Init(root, cfg, val)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick

    self.cfg = cfg
    self.go = root.gameObject

    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab2")
    self.tex1 = CG(UITexture, root, "tex")
    self.tex2 = CG(UITexture, root, "sprBg/spr1")
    self.tex2Lab = CG(UILabel, root, "sprBg/lab")

    SetB(root, "btn", des, self.OnBtn, self)

    self:InitIcon(cfg)
    self:InitLab(cfg, val)
end

--初始化文本
function My:InitLab(cfg, val)
    local info = TimeLimitActivInfo
    self.lab1.text = string.format("[EE9A9EFF]%s[F39800FF]%s灵力值", self.keyword1, cfg.award)
    self.lab2.text = val
    self.tex2Lab.text = self.keyword2
end

--点击立即前往
function My:OnBtn()
    local cfg = self.cfg
    local type = cfg.mType
    if type == 100108 then--日常任务
        self:MissionTrigger(MissionType.Turn)
    else
        UITabMgr.Open(cfg.jumpInfo)
    end
    JumpMgr:InitJump(UITimeLimitActiv.Name, 4)
end

--初始化贴图
function My:InitIcon(cfg)
    local cfg = self.cfg
    local str = string.format(cfg.des, cfg.cond)
    self:UpIcon(cfg.btnIcon)
    self:UpIconName(str, cfg.btnName)
end

--更新跳转图标名称
function My:UpIconName(str1, str2)
    self.keyword1 = str1
    self.keyword2 = str2
end

--初始化兑换道具
function My:UpIcon(texName)
    self.texName = texName
    AssetMgr:Load(self.texName, ObjHandler(self.SetIcon2, self))
end

--设置贴图
function My:SetIcon2(tex)
    if self.tex2 then
        self.tex2.mainTexture = tex
    end
end

--任务触发
function My:MissionTrigger(type)
    Hangup:SetAutoHangup(true);
    MissionMgr:AutoExecuteActionOfType(type)
end

--设置贴图
function My:SetIcon1(tex)
    if self.tex1 then
        self.tex1.mainTexture = tex
    end
end

--清理缓存
function My:Clear()
    AssetMgr:Unload(self.texName,false)
end
    
--释放资源
function My:Dispose()
    self:Clear()
end

return My