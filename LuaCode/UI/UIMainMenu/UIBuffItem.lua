--region UIBuffItem.lua
--Date
--此文件由[HS]创建生成

UIBuffItem = Super:New{Name="UIBuffItem"}
local M = UIBuffItem

--注册的事件回调函数

function M:Init(go)
	local name = "UI主界面Buff Item"
	self.GO = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	
	self.Icon = C(UITexture, trans, "Icon", name, false)
	self.NameLab = C(UILabel, trans, "Name", name, false)
	self.Status = C(UILabel, trans, "Status", name, false)
	self.Des = C(UILabel, trans, "Des", name, false)

	self.TimerTool = ObjPool.Get(DateTimer)
	self.TimerTool.invlCb:Add(self.InvCountDown, self)
	self.TimerTool.complete:Add(self.EndCountDown, self)
	self.IsDownCount = false
end

function M:UpdateData(data)
	self.Data = data
	local temp = data.Temp
	if temp then
		self:UpdateIcon(temp.path)
		self:UpdateName(temp.name)
		self:UpdateStatus(data.StartTime, data.EndTime)
		self:UpdateDes(temp.valueList, data.Value)
	end
end

function M:UpdateIcon(path)
	if StrTool.IsNullOrEmpty(path) then
		if self.Data then
			path = self.Data.Temp.path
		end
	end
	if StrTool.IsNullOrEmpty(path) then return end
	self:UnloadIcon()
	local del = ObjPool.Get(Del1Arg)
	del:SetFunc(self.SetTex, self)
	del:Add(self.Icon)
	self.IconName = path
	AssetMgr:Load(path,ObjHandler(del.Execute,del))
end

function M:UpdateName(name)
	if self.NameLab then
		self.NameLab.text = name
	end
end

function M:UpdateStatus(sTime, eTime)
	local value = "永久"
	local localTime = tonumber(User:GetServerTimeNow())
	if eTime > 0 then
		local time = eTime - Mathf.Floor(localTime/1000)
		if time > 0 then
			value = DateTool.FmtSec(time, 3, 1)
			if self.IsDownCount == false then
				self.IsDownCount = true
				if self.TimerTool then
					self.TimerTool.seconds = time
					self.TimerTool:Start()
				end
			end
		end
	end
	if self.Status then
		self.Status.text = value
	end
end

function M:UpdateDes(list, value)
	local des = ""
	if not list then return end
	local len = #list
	for	i=1,len do 
		local kv = list[i]
		local temp = PropName[kv.k]
		if temp then
			local t = temp.show
			local num = 0
			if t == 0 then
				num = value * kv.v
			elseif t == 1 then
				num = string.format("%s%%", value * (kv.v / 100))
			end
			des = string.format( "%s %s+%s", des, temp.Text, num)
		end
	end
	if self.Des then
		self.Des.text = des
	end
end

function M:SetTex(tex, icon)
	if tex and icon then
		icon.mainTexture = tex
	end
end

function M:UnloadIcon()
	if not StrTool.IsNullOrEmpty(self.IconName) then
		AssetMgr:Unload(self.IconName, ".png", false)
	end
	self.IconName = nil
end

function M:InvCountDown()
	local data = self.Data
	if data then
		self:UpdateStatus(data.StartTime, data.EndTime)
	end
end

function M:EndCountDown()
	if self.Des then
		self.Des.text = ""
	end
end

function M:Clear()
	self:UnloadIcon()
	if self.TimerTool then 
		self.TimerTool:Stop()
	end
end

function M:Dispose()
	self:Clear()
	if self.GO then
		self.GO.transform.parent = nil
		Destroy(self.GO)
	end
	if self.TimerTool then self.TimerTool:AutoToPool() end
	self.TimerTool = nil
	self.GO = nil
end
--endregion
