--[[
 	authors 	:Liu
 	date    	:2018-11-2 15:10:00
 	descrition 	:仙魂合成界面（Toggle项）
--]]

UIImmSoulCompTogsIt = Super:New{Name = "UIImmSoulCompTogsIt"}

local My = UIImmSoulCompTogsIt

function My:Init(root, cfg, num)
    local des = self.Name
    local CG = ComTool.Get
    local CGS = ComTool.GetSelf
    local FindC = TransTool.FindChild
    local SetS = UITool.SetLsnrSelf

    local lab1 = CG(UILabel, root, "lab1")
    local lab2 = CG(UILabel, root, "lab2")
    SetS(root, self.OnTog, self, des)
    self.spr = CGS(UISprite, root, des)
    self.tog = CGS(UIToggle, root, des)
    self.alpha = self.spr.alpha
    self.cfg = cfg
    self.num = num
    self.root = root
    self:InitLab(cfg, lab1, lab2)
end

--设置索引
function My:SetIndex(index)
    self.index = index
end

--初始化Tog状态
function My:SetTogState(state)
    self.tog.value = state
end

--设置alpha值
function My:SetAlpha(num)
    self.spr.alpha = num
end

--点击Tog
function My:OnTog(go)
    local info = ImmortalSoulInfo
    local togNum = info:GetTogIndex(self.cfg.id)
    info:SetTogIndex(togNum)
    info:SetTabIndex(self.index)
    local it = UIImmortalSoul.mod2.compShow
    it:UnloadTexs()
    it:UpData()
    it:UpLab()
end

--初始化文本
function My:InitLab(cfg, lab1, lab2)
    lab1.text = cfg.name
    lab2.text = cfg.name
end

--清理缓存
function My:Clear()
	
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My