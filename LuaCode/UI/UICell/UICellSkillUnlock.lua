--region UICellSkillUnlock.lua
--Cell 技能解锁 拥有品质，强化等级 UILabel 一般用作数量
--此文件由[HS]创建生成

UICellSkillUnlock = baseclass(UICell)

--构造函数
function UICellSkillUnlock:Ctor(go)
	self.Name = "UICellSkillUnlock"
end

--初始化控件
function UICellSkillUnlock:Init()
	self:Super("Init")
	self.Lock = TransTool.FindChild(self.gameObject.transform, "Lock")
end

--更新Quality
function UICellSkillUnlock:IsUnlock(value)
	if self.Lock then self.Lock:SetActive(not value) end
end

--清楚数据
function UICellSkillUnlock:Clean()
	self:Super("Clean")
	self:IsUnlock(false)
end

--释放或销毁
function UICellSkillUnlock:Dispose(isDestory)
	self.Lock = nil
	self:Super("Dispose", isDestory)
end
