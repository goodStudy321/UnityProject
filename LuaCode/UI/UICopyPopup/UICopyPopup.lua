--[[
 	authors 	:Liu
 	date    	:2019-6-22 16:30:00
 	descrition 	:副本弹窗
--]]

UICopyPopup = UIBase:New{Name = "UICopyPopup"}

local My = UICopyPopup

require("UI/UICopyPopup/UIBossInspire")

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local Find = TransTool.Find

    self.bossInspireTran = Find(root, "BossInspire", des)

    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	FamilyBossMgr.eInspire[func](FamilyBossMgr.eInspire, self.RespInspire, self)
end

--响应道庭Boss鼓舞
function My:RespInspire()
    if self.bossInspire then
        self.bossInspire:UpData()
    end
end

--更新道庭Boss鼓舞
function My:UpInspire()
    if self.bossInspire == nil then
        self.bossInspire = ObjPool.Get(UIBossInspire)
        self.bossInspire:Init(self.bossInspireTran)
    end
    self.bossInspire:Open()
end

--清理缓存
function My:Clear()
	if self.bossInspire then
		ObjPool.Add(self.bossInspire)
		self.bossInspire = nil
	end
end

--重写释放资源
function My:DisposeCustom()
    self:Clear()
    self:SetLnsr("Remove")
end

return My