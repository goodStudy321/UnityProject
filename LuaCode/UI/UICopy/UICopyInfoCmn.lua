UICopyInfoCmn = UICopyInfoBase:New{Name = "UICopyInfoCmn"}

local M = UICopyInfoCmn

M.Cells = {}
M.CurStarList = {}
M.NextStarList = {}

--构造函数
function M:InitSelf()
	local trans = self.left
	local C = ComTool.Get
	local T = TransTool.FindChild
	local E = UITool.SetLsnrSelf
	local name = self.Name
	
	self.NameLab = C(UILabel, trans, "Name", name, false)
	self.Target = C(UILabel, trans, "Target", name, false)
	self.Time = C(UILabel, trans, "ori/Time", name, false)
	self.Wu = T(trans, "ori/Wu")
	E(self.Target, self.OnClickTarget, self)

	self.Grid = C(UIGrid, trans, "ori/Grid", name, false)

	self.StarLab = C(UILabel, trans, "ori/Star", name, false)

	self.curStar = T(trans, "ori/CurStar")
	self.nextStar = T(trans, "ori/NextStar")

	self.oriGbj = T(trans,"ori")
    self.othGbj = T(trans,"oth")
    self.wuLab = C(UILabel,trans,"oth/Wu")
    self.rwInfo = T(trans,"oth/RwdInfo")
    self.rwGrid = C(UIGrid,trans,"oth/RwdInfo/Grid")

	self:GetStar(self.curStar.transform, self.CurStarList)
	self:GetStar(self.nextStar.transform, self.NextStarList)

	self:SetEvent(EventMgr.Add)
end

function M:GetStar(trans, list)
	local FC = TransTool.FindChild
	for i=1,3 do
		local star = FC(trans, "Star"..i)
		table.insert(list, star)
	end
end

function M:SetLsnrSelf(key)
	CopyMgr.eCopyInfoCountDown[key](CopyMgr.eCopyInfoCountDown, self.UpdateStar, self)
end

function M:SetEvent(E)
	E("NavPathComplete",EventHandler(self.NavPathComplete, self))
end

function M:OnClickTarget(go)
	local temp = self.Temp
	if not temp then return end
	local info = CopyMgr.CopyInfo
	local childTemp = CopyMgr:GetChilTemp(temp, info)
	if not childTemp then return end
	local list = childTemp.pos
	if not list then return end
	local p1 = list[1]
	local p2 = list[2]
	local tPos = Vector3.New((p1.x + p2.x), 0, (p1.y + p2.y)) / 200
	
	User:SetCopyDesPos(tPos.x,tPos.y,tPos.x,tPos.y)
	Hangup:SetAutoSkill(false);
	Hangup:SetSituFight(true);
end

function M:NavPathComplete(t, id)
	if t == PathRType.PRT_PATH_SUC then
		local temp = self.Temp
		if temp and temp.id == User.SceneId then
			Hangup:SetSituFight(true);
		end
	end
end

function M:InitData()
	local info = CopyMgr.CopyInfo
	if not info then return end

	local copyCfg = self.Temp
	local copyType = copyCfg.type
	local copyNum,curHonor,maxHonor = CopyMgr:GetCopyNum(self.Temp)
	if copyType ~= CopyType.Equip then
		copyNum = 1
	end
    if copyNum <= 0 then
        self.wuLab.gameObject:SetActive(curHonor >= maxHonor)
        self.rwInfo:SetActive(curHonor < maxHonor)
    end
    self.oriGbj:SetActive(copyNum > 0)
    self.othGbj:SetActive(copyNum <= 0)
	local rwNum = GlobalTemp["201"].Value2[1]
	local pId = GlobalTemp["201"].Value3
	local tab = {{k = pId,v = rwNum}}
	self:UpdateCellData(tab,self.rwGrid)

	self:UpdateName()
	self:UpdateTime(info)
	self:UpdateSub()
end

function M:UpdateName()
	local temp = self.Temp
	if not temp then return end
	if self.NameLab then
		self.NameLab.text = temp.name
	end
end

function M:UpdateSub()
	if self.Target then
		local name = ""
		local monster = nil
		local info = CopyMgr.CopyInfo
		local chilTemp = CopyMgr:GetChilTemp(self.Temp, info)
		if not chilTemp then return end
		if chilTemp.mId then
			monster = MonsterTemp[tostring(chilTemp.mId)]
		end
		if monster then name = monster.name end
		self.Target.text = string.format("[%s](%s/%s)", name, info.Sub, chilTemp.mNum)
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
		
		if self.Temp.type ~= CopyType.ZHTower then
			if min then
				if t < 0 then t = t * -1 end
				self.Time.text = string.format("[f39800]%s[f4ddbd]后降为[f39800]%s[-]级[-]",DateTool.FmtSec(t, 3, 1), min) 
			end
			if self.Star and  self.Star == i then return end
			CopyMgr.CopyEndStar = i
			if not self.Star or self.Star ~= i then
				self.Star = i
				self:UpdateReward()
			end
			self.StarLab.text = string.format( "[f4ddbd]当前评级为：[f39800]%s",str)
			self.Time.gameObject:SetActive(min ~= nil)
		else
			self.curStar:SetActive(true)
			self.nextStar:SetActive(min ~= nil)
			if min then
				if t < 0 then t = t * -1 end
				self.Time.text = string.format("[f39800]%s[f4ddbd]后降为:",DateTool.FmtSec(t, 3, 1)) 
			end
			if self.Star and  self.Star == i then return end
			CopyMgr.CopyEndStar = i
			if not self.Star or self.Star ~= i then
				self.Star = i
				self:UpdateReward()
			end
			self.StarLab.text = "[f4ddbd]当前评级为:"	
			local list = self.CurStarList	
			for j=1,#list do
				list[j]:SetActive(j<=i)
			end

			local nList = self.NextStarList
			local next = i-1
			for j=1,#nList do
				nList[j]:SetActive(j<=next)
			end
			self.Time.gameObject:SetActive(min ~= nil)	
		end
	end
end


function M:UpdateReward()
	local temp = self.Temp
	if not temp then return end
	
	local copyCfg = self.Temp
	local copyType = copyCfg.type
	local copyNum,curHonor,maxHonor = CopyMgr:GetCopyNum(self.Temp)
	if copyType ~= CopyType.Equip then
		copyNum = 1
	end
	if copyNum <= 0 then return end

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

function M:UpdateCellData(data,grid)
	grid = grid or self.Grid
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
			item:InitLoadPool(grid.transform)
			item:UpData(data[i].k, data[i].v)
			table.insert(self.Cells, item)
        end
    end
    grid:Reposition()
end

function M:DisposeSelf()
	self:SetEvent(EventMgr.Remove)
	TableTool.ClearListToPool(self.Cells)
	TableTool.ClearDic(self.CurStarList)
	TableTool.ClearDic(self.NextStarList)
	self.Star = nil
end

return M
