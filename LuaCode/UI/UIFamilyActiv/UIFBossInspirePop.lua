--[[
 	authors 	:Liu
 	date    	:2019-6-13 12:07:00
 	descrition 	:道庭Boss鼓舞弹窗
--]]

UIFBossInspirePop = Super:New{Name="UIFBossInspirePop"}

local My = UIFBossInspirePop

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local Find = TransTool.Find
    local SetB = UITool.SetBtnClick

	self.cellList = {}
	self.go = root.gameObject

	self.lab1 = CG(UILabel, root, "lab1")
	self.lab2 = CG(UILabel, root, "lab2")
	self.lab3 = CG(UILabel, root, "lab3")
	self.goldLab = CG(UILabel, root, "btn/countLab")
	self.grid = Find(root, "Grid", des)

	SetB(root, "btn", des, self.OnInspire, self)
	SetB(root, "close", des, self.Close, self)

	self:InitCell()
end

--更新数据
function My:UpData()
	local data = FamilyBossInfo.data
	local buffData = FamilyBossInfo.buffData
	if data == nil or buffData == nil then return end

	local atk = buffData.atk * 100
	local maxAtk = (buffData.atk * buffData.allInspire) * 100
	local curAtk = (data.allInspire * buffData.atk) * 100
	self.lab1.text = string.format("[F4DDBDFF]每次助威可增加道庭所有成员[00FF00FF]%s%%[-]伤害（上限[00FF00FF]%s%%[-]）", atk, maxAtk)
	self.lab2.text = string.format("[F39800FF]当前助威：道庭伤害[00FF00FF]+%s%%", curAtk)
	self.lab3.text = string.format("[F4DDBDFF]个人助威次数：%s/%s", data.inspire, buffData.inspire)
	self.goldLab.text = buffData.gold
end

--初始化道具
function My:InitCell()
	local buffData = FamilyBossInfo.buffData
	if buffData == nil then return end
	for i,v in ipairs(buffData.award) do
		local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.grid, 0.8)
        cell:UpData(v.id, v.value)
        table.insert(self.cellList, cell)
	end
end

--点击助威
function My:OnInspire()
	local data = FamilyBossInfo.data
	local buffData = FamilyBossInfo.buffData
	if data == nil or buffData == nil then return end
	local val = buffData.inspire - data.inspire
	if val <= 0 then
		UITip.Log("助威次数已满")
		return
	end

	if CustomInfo:IsBuySucc(buffData.gold) then
		FamilyBossMgr:ReqInspire()
	else
		StoreMgr.JumpRechange()
	end
end

--打开
function My:Open()
	self.go:SetActive(true)
	self:UpData()
end

--关闭
function My:Close()
	self.go:SetActive(false)
end

--清理缓存
function My:Clear()
    
end

--释放资源
function My:Dispose()
	self:Clear()
	TableTool.ClearListToPool(self.cellList)
end

return My