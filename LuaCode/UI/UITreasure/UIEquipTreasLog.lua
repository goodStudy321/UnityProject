--[[
 	authors 	:Liu
 	date    	:2018-6-27 12:00:00
 	descrition 	:装备寻宝轮盘
--]]

UIEquipTreasLog = Super:New{Name="UIEquipTreasLog"}

local My = UIEquipTreasLog

function My:Init(root, index)
	local des, FinC = self.Name, TransTool.FindChild
	local SetS, Find = UITool.SetLsnrSelf, TransTool.Find
	local str = "serverLog/Scroll View"
	self.wLogList = {}
	self.sLogList = {}
	self.index = index
	self.GetS = ComTool.GetSelf
	self.svTran = Find(root, str, des)
	self.svTran1 = Find(root, "myLog/Scroll View", des)
	self.logItem = FinC(root, str.."/item", des)
	self.logItem:SetActive(false)
	for i=1, 2 do
		local tog = FinC(root, "tog"..i, des)
		SetS(tog, self.OnTog, self, des)
	end
end

--初始化世界寻宝日志
function My:InitWLog(name, iconId)
	local tran, lab = self:InitLogLab(name, iconId, true)
	if tran == nil then return end
	local list = self.wLogList
	if #list > 0 then
		local tab = self.GetS(UITable, tran, self.Name)
		local padding = tab.padding
		local off = (self.offset) and self.offset or 0
		padding.y = self.ySize + off
		tab.padding = padding
		self.offset = padding.y
	end
	self.ySize = lab.localSize.y + 10
	--存储游戏对象
	table.insert(list, tran)
end

--新增世界寻宝日志
function My:AddWLog(name, iconId)
	self:AddLog(self.wLogList, name, iconId, true)
end

--删除世界寻宝日志
function My:DelWLog()
	self:DelLog(self.wLogList)
end

--初始化自身寻宝日志
function My:InitSLog(iconId)
	local tran, lab = self:InitLogLab(User.MapData.Name, iconId, false)
	if tran == nil then return end
	local list = self.sLogList
	if #list > 0 then
		local tab = self.GetS(UITable, tran, self.Name)
		local padding = tab.padding
		local off = (self.offset1) and self.offset1 or 0
		padding.y = self.ySize1 + off
		tab.padding = padding
		self.offset1 = padding.y
	end
	self.ySize1 = lab.localSize.y + 10
	--存储游戏对象
	table.insert(list, tran)
end

--新增自身寻宝日志
function My:AddSLog(iconId)
	self:AddLog(self.sLogList, User.MapData.Name, iconId, false)
end

--删除自身寻宝日志
function My:DelSLog()
	self:DelLog(self.sLogList)
end

--新增寻宝日志
function My:AddLog(list, name, iconId, isWord)
	local tran, lab = self:InitLogLab(name, iconId, isWord)
	if tran == nil then return end
	local labY = lab.localSize.y + 10
	for i,v in ipairs(list) do
		local tab = self.GetS(UITable, v, self.Name)
		local padding = tab.padding
		padding.y = padding.y + labY
		tab.padding = padding
		tab:Reposition()
	end
	--存储游戏对象
	table.insert(list, 1, tran)
end

--删除日志
function My:DelLog(list)
	GameObject.Destroy(list[#list].gameObject)
	table.remove(list, #list)
end

--初始化寻宝日志文本
function My:InitLogLab(name, iconId, isWord)
	local key = tostring(iconId)
	if ItemData[key] == nil then
		iTrace.Log("SJ", string.format("id为 %s 的道具不存在！", key))
		return nil
	end
	local item = Instantiate(self.logItem)
	local tran = item.transform
	local Add = TransTool.AddChild
	if (isWord) then
		Add(self.svTran, tran)
	else
		Add(self.svTran1, tran)
	end
	tran.localPosition = self.logItem.transform.localPosition
	item:SetActive(true)

	local temp = TransTool.FindChild(tran, "lab", self.Name)
	local lab = temp:GetComponent(typeof(UILabel))
	local qua = ItemData[key].quality
	local col = UIMisc.LabColor(qua)
	if isWord then
		lab.text = "喜从天降，[[679ECC]"..name.."[-]]在[679ECC]神秘宝藏[-]中获得了"..col..ItemData[key].name
	else
		lab.text = "恭喜，[[679ECC]"..name.."[-]]在[679ECC]神秘宝藏[-]中获得了"..col..ItemData[key].name
	end
	return tran, lab
end

--点击按钮
function My:OnTog(go)
	if go.name == "tog1" then
		self:ResetLogsPos(self.wLogList)
	elseif go.name == "tog2" then
		self:ResetLogsPos(self.sLogList)
	end
end

--重置日志位置
function My:ResetLogsPos(list)
	for i,v in ipairs(list) do
		local tab = self.GetS(UITable, v, self.Name)
		tab:Reposition()
	end
end

--清理缓存
function My:Clear()
	self.offset = nil
	self.offset1 = nil
	self.ySize = nil
	self.ySize1 = nil
	TableTool.ClearUserData(self)
end
    
--释放资源
function My:Dispose()
	self:Clear()
end

return My