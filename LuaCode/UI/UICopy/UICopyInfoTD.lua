--region UICopyInfoTD.lua
--Date	
--此文件由[HS]创建生成
UICopyInfoTD = UICopyInfoBase:New{Name = "UICopyInfoTD"}

local M = UICopyInfoTD

M.Cells = {}
--构造函数
function M:InitSelf()
	local trans = self.left
	local C = ComTool.Get
	local T = TransTool.FindChild
	local name = self.Name
	self.Tip = C(UILabel, trans, "Tip/Label", name, false)
	
	self.NameLab = C(UILabel, trans, "Name", name, false)
	self.Target = C(UILabel, trans, "Target", name, false)
	self.Time = C(UILabel, trans, "Time", name, false)

	self.Grid = C(UIGrid, trans, "Grid", name, false)

	self.Blood = C(UISprite, trans, "blood", name, false)
	self.BloodValue = C(UILabel, trans, "blood/Label", name, false)

	self.Wu = T(trans, "Wu")

	self.StarLab = C(UILabel, trans, "Star", name, false)
	self.Star = 0

	self.MstTemp = nil
	self.CurWave = 0
	self.IsShowTip = false
	self.Timing = 0

	self:SetEvent(EventMgr.Add)
end

function M:SetLsnrSelf(key)
	CopyMgr.eCopyInfoCountDown[key](CopyMgr.eCopyInfoCountDown, self.UpdateStar, self)
	CopyMgr.eUpdateCreateMonster[key](CopyMgr.eUpdateCreateMonster, self.UpdateCreateMonster, self)
end

function M:SetEvent(E)
	E("OnUpdateMonsterHP", EventHandler(self.UpdateBlood, self))
end

function M:InitData()
	local info = CopyMgr.CopyInfo
	if not info then return end
	self:UpdateName()
	self:UpdateCur()
	self:UpdateTime(info)
end

--开始刷怪了
function M:UpdateCreateMonster(temp)
	if not temp then return end
	local info = CopyMgr.CopyInfo
	if not info then return end
	UICopyInfoTimer:CloseTime()
	self:ShowTip(temp)
end

function M:UpdateName()
	local temp = self.Temp
	if not temp then return end
	if self.NameLab then
		self.NameLab.text = temp.name
	end
end

function M:UpdateCur()
	local temp = self.Temp
	if not temp then return end
	local info = CopyMgr.CopyInfo
	if not info then return end
	local key = temp.id * 100 + 1
	local childTemp = nil
	if temp.type == CopyType.SingleTD then
		childTemp = CopyTDTemp[tostring(key)]
	elseif temp.type == CopyType.HYC then
		childTemp = HYCCopyCfg[tostring(key)]
	end
	if not childTemp then return end
	self.Target.text = string.format("[00ff00]守护%s    (%s/%s)波[-]", MonsterTemp[tostring(childTemp.tId)].name, info.Cur or 0, info.totalWave)
	if self.ChildTemp and self.ChildTemp.id == childTemp.id then return end
	self.ChildTemp = childTemp
	self:UpdateBlood(childTemp.tId, 0, 0)
end

function M:UpdateBlood(id, hp, maxhp)
	local h = tonumber(hp)
	local mh = tonumber(maxhp)
	local childTemp = self.ChildTemp
	if not childTemp then return end
	if id ~= childTemp.tId then return end
	local temp = MonsterTemp[tostring(childTemp.tId)]
	local value = ""
	local fill = 1
	local max = temp.life
	if mh > 0 then 
		max = mh 
		fill = h/mh
		value = string.format("%s%%",math.floor(fill*100)) 	
	else
		value = "100%"
	end 

	if self.Blood then
		self.Blood.gameObject:SetActive(max > 0)
		self.Blood.fillAmountValue = fill
	end
	if self.BloodValue then
		self.BloodValue.text = value
	end
end

function M:UpdateTime(info)
	self:UpdateStar(info.ATime)
end

function M:UpdateStar(time)
	if time == nil then return end
	if self.Temp and self.Temp.sParam then
		local t = time
		local i = 3
		local str  = nil
		local min = nil
		if time >= self.Temp.countDown - self.Temp.sParam[1] then	
			t = self.Temp.countDown - self.Temp.sParam[1] - time
			i = 3
			str = "甲"
			min = "乙"
		elseif time >= self.Temp.countDown - self.Temp.sParam[2] then
			t = self.Temp.countDown - self.Temp.sParam[2] - time
			i = 2
			str = "乙"
			min = "丙"
		elseif 	time >= self.Temp.countDown - self.Temp.sParam[3] then
			t = self.Temp.countDown - self.Temp.sParam[3] - time
			i = 1
			str = "丙"
			min = "无评"
		else
			i = 0
			str = "无评级"
		end
		if min then
			if t < 0 then t = t * -1 end
			self.Time.text = string.format("[f39800]%s[f4ddbd]后降为[f39800]%s[-]级[-]",DateTool.FmtSec(t, 3, 1), min) 
		end
		if self.Star and  self.Star == i then return end
		CopyMgr.CopyEndStar = i
		if self.Star ~= i then
			self.Star = i
			self:UpdateReward()
		end
		self.StarLab.text = string.format( "[f4ddbd]当前评级为：[f39800]%s",str)
		self.Time.gameObject:SetActive(min ~= nil)
	end
end 

function M:UpdateReward()
	local temp = self.Temp
	if not temp then return end

	local kvs = {}
	local star = self.Star
	if star == 3 then
		kvs = temp.sor3
	elseif star == 2 then
		kvs = temp.sor2
	elseif star == 1 then
		kvs = temp.sor1
	end
	self.Wu:SetActive(star == 0)
	self:UpdateCellData(kvs)
end

function M:UpdateCellData(data)
    local len = #data
    local list = self.Cells
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max

    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpData(data[i].k, data[i].v)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local item = ObjPool.Get(UIItemCell)
			item:InitLoadPool(self.Grid.transform)
			item:UpData(data[i].k, data[i].v)
			table.insert(self.Cells, item)
        end
    end
    self.Grid:Reposition()
end


function M:ShowTip(temp)
	local info = CopyMgr.CopyInfo
	if not info then return end
	if not temp then return end
	if not self.Tip then return end
	if self.MstTemp and self.CurWave and self.MstTemp.id == temp.id and self.CurWave == info.Cur then return end
	self.MstTemp = temp
	self.CurWave = info.Cur
	if not info.Cur then self.CurWave = 1 end
	local txt = ""
	if temp.type == MonsterType.Cmm then
		txt = string.format("第【%s】波小怪【%s】正在接近中", self.CurWave, temp.name)
	else
		txt = string.format("BOSS【%s】正在接近中", temp.name)
	end
	self.Tip.gameObject:SetActive(true)
	self.Tip.text = txt
	if self.IsShowTip == true then return end
	self.Timing = Time.realtimeSinceStartup
	self.IsShowTip = true
end

function M:Update()
	if not self.IsShowTip then return end
	if not self.Timing then return end
	if Time.realtimeSinceStartup - self.Timing  > 5 then
		self.Timing = 0
		self.MstTemp = nil
		self.CurWave = 0
		if self.Tip then self.Tip.gameObject:SetActive(false) end
		self.IsShowTip = false
	end
end


function M:DisposeSelf()
	self:SetEvent(EventMgr.Remove)
	TableTool.ClearListToPool(self.Cells)
	self.IsShowTip = nil
	self.Timing = nil
	self.MstTemp = nil
	self.CurWave = nil
end

return M
