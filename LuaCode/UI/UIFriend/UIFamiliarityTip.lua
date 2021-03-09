--region UICell.lua
--Cell基类 只有Icon
--此文件由[HS]创建生成

UIFamiliarityTip = {}
local M = UIFamiliarityTip

--构造函数
function M:New(go)
	self.GO = go
	local trans = self.GO.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Bg = C(UISprite, trans, "Tip1", name, false)
	self.End = C(UILabel, trans, "Tip1/Sprite/End", name, false)
	self.Name = C(UILabel, trans, "Tip1/Name", name, false)
	self.Lv = C(UILabel, trans, "Tip1/Lv", name, false)
	self.Value = C(UILabel, trans, "Tip1/Value", name, false)
	self.Pro = C(UILabel, trans, "Tip1/Pro", name, false)
 	self.Close1 = T(trans, "Tip1/Close")

	 self.TempBg = C(UISprite, trans, "Tip2", name, false)
	 self.TempEnd = C(UILabel, trans, "Tip2/Sprite/End", name, false)
	self.TempPro = C(UILabel, trans, "Tip2/Pro", name, false)
	self.TempValue = C(UILabel, trans, "Tip2/Value", name, false)
	self.TempDes = C(UILabel, trans, "Tip2/Des", name, false)
	self.Close2 = T(trans, "Tip2/Close")
	local E = UITool.SetLsnrSelf
	E(self.GO, self.OnCloseBtn, self)
	E(self.Close1, self.OnCloseBtn, self)
	E(self.Close2, self.OnCloseBtn, self)
	return M
end

function M:UpdateData(temp, value)
	self:CurTempPro(temp, value)
	self:UpdateTempPro()
end

function M:CurTempPro(temp, value)
	if not temp then return end
	if self.Name then
		self.Name.text = temp.name
	end
	if self.Lv then	
		self.Lv.text = tostring(temp.lv)
	end
	if self.Value then
		self.Value.text = tostring(value)
	end
	if self.Pro then
		local buff = BuffTemp[tostring(temp.buff)]
		if buff and buff.valueList then
			self.Pro.text = self:GetProDes(buff.valueList, "\n")
		else
			self.Pro.text = "无"
		end
	end
	self:UpdateBg(self.Bg, self.End)
end

function M:UpdateTempPro()	
	if not self.TempPro or StrTool.IsNullOrEmpty(self.TempPro.text)== true then return end
	local name = ""
	local value = ""
	local des = ""
	for i=1,#FamiliarityTemp do
		local temp = FamiliarityTemp[i]
		local buff = BuffTemp[tostring(temp.buff)]
		local color = self:GetColor(i)
		if not StrTool.IsNullOrEmpty(name) then
			name = string.format("%s\n[%s]%s[-]", name, color, temp.name)
		else
			name = string.format("[%s]%s[-]", color, temp.name)
		end
		if not StrTool.IsNullOrEmpty(value) then
			value = string.format("%s\n[%s]%s[-]", value, color, temp.need)
		else
			value = string.format("[%s]%s[-]", color, temp.need)
		end
		local s = "无"	
		if buff and buff.valueList then
			s = self:GetProDes(buff.valueList, "；")
		end
		if not StrTool.IsNullOrEmpty(des) then
			des = string.format("%s\n[%s]%s[-]", des, color, s)
		else
			des = string.format("[%s]%s[-]", color, s)
		end
	end
	self.TempPro.text = name
	self.TempValue.text = value
	self.TempDes.text = des
	self:UpdateBg(self.TempBg, self.TempEnd)
end

function M:GetColor(i)
	if i >=2 and i <= 3 then
		return "3DE66D"
	elseif i >=4 and i <= 6 then
		return "4E97F1"
	elseif i >=7 and i <= 9 then
		return "9D44B4"
	elseif i >=10 and i <= 12 then
		return "BF6D0C"
	end
	return "ffffff"
end

function M:GetProDes(list, symbol)
	local str = ""
	for i=1,#list do
		local s = ""
		if i < #list then
			s = symbol
		end
		str = string.format( "%s%s%s",str, self:GetPro(list[i]), s)
	end
	return str
end

function M:GetPro(data)
	local name = PropTool.GetNameById(data.k)
	if data.k == 26 then
		return string.format("%s +%s%%",name, math.floor(data.v / 100))
	end
	return string.format("%s +%s",name, data.v)
end

function M:UpdateBg(bg, e)
	if bg and e then
		local h = math.abs(e.transform.localPosition.y)  + e.height
		bg.height = h
		e:UpdateAnchors()
	end
end

function M:OnCloseBtn()
	self:SetActive(false)
end

--清楚数据
function M:Clean()
	if self.Name then
		self.Name.text = ""
	end
	if self.Lv then	
		self.Lv.text = ""
	end
	if self.Value then
		self.Value.text = ""
	end
	if self.Pro then
		self.Pro.text = ""
	end
end

function M:SetActive(value)
	if not value then self:Clean() end
	if self.GO then 
		self.GO:SetActive(value) 
	end
end

--释放或销毁
function M:Dispose()
end
--endregion
