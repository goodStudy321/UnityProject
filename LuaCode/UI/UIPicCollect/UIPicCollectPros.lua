--region UIPicCollectPros.lua
--Date
--此文件由[HS]创建生成


UIPicCollectPros = Super:New{Name="UIPicCollectPros"}
local M = UIPicCollectPros

M.GroupPro = false

function M:Init(go)
	local name = "图鉴Pros"
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Pros = {}
	self.Adds = {}
	for i=1,4 do
		local data = {}
		data.Value = C(UILabel, trans, "Pro_"..i, name, false)
		data.Label = C(UILabel, trans, string.format("Pro_%s/Label",i), name, false)
		table.insert(self.Pros, data)
		local add = C(UILabel, trans, "Add_"..i, name, false)
		table.insert(self.Adds, add)
	end
end

function M:UpdatyeTemp(temp, nTemp)
	local list = {}
	if temp.pro1 then
		table.insert(list, temp.pro1)
	end
	if temp.pro2 then
		table.insert(list, temp.pro2)
	end
	if temp.pro3 then
		table.insert(list, temp.pro3)
	end
	if temp.pro4 then
		table.insert(list, temp.pro4)
	end
	local nlist = {}
	if nTemp then
		if nTemp.pro1 then
			table.insert(nlist, nTemp.pro1)
		end
		if nTemp.pro2 then
			table.insert(nlist, nTemp.pro2)
		end
		if nTemp.pro3 then
			table.insert(nlist, nTemp.pro3)
		end
		if nTemp.pro4 then
			table.insert(nlist, nTemp.pro4)
		end
	end
	self:UpdatePro(list, nlist)
end

function M:UpdateProTemp(temp)
	self:UpdatePro(temp.pro, nil)
end

function M:UpdatePro(list, nlist)
	self:Clear()
	local notPro = false
	if not list or #list == 0 then notPro = true end
	local len = #self.Pros
	if notPro == false then
		if len > 0 then
			for i=1,len do
				if #list >=i then
					self:AddPro(i, list[i])
				end
			end
		end
	end
	if not nlist or #nlist == 0 then return end
	if  len > 0 then
		for i=1,len do
			local pro = nil
			local nPro = nil
			if #nlist >= i then
				nPro = nlist[i]
			end
			if notPro == true and nPro then
				pro = {k = nPro.k, v = 0}
				self:AddPro(i, pro)
			else
				pro = list[i]
			end
			self:AddAPro(i, pro, nPro)
		end
	end
end

function M:AddPro(index, pro)
	if not pro then return end
	if #self.Pros < index then return end
	if self.Pros[index] then
		if self.Pros[index].Label then
			if self.GroupPro == false then
				self.Pros[index].Label.text = PropTool.GetNameById(pro.k).."："
			else
				self.Pros[index].Label.text = PropTool.GetNameById(pro.k).." +"..PropTool.GetValByID(pro.k ,pro.v)
			end
		end
		if self.GroupPro == false then
			if self.Pros[index].Value then
				self.Pros[index].Value.text = PropTool.GetValByID(pro.k ,pro.v)
			end
		end
	end
end

function M:AddAPro(index, pro, npro)
	if not pro  then return end
	if #self.Adds < index then return end
	if self.Adds[index] then
		local txt = ""
		if npro then
			txt = string.format("+ %s",  PropTool.GetValByID(npro.k,npro.v-pro.v))
		else
			txt = "(已经满级)"
		end
		self.Adds[index].text = txt
	end
end

function M:Clear()
	local pros = self.Pros
	if pros then
		for i,v in ipairs(pros) do
			v.Value.text = ""
			v.Label.text = ""
		end
	end
	local adds = self.Adds
	if adds then
		for i,v in ipairs(adds) do
			v.text = ""
		end
	end
end

function M:Dispose()
	local pros = self.Pros
	if pros then
		local len = #pros
		while len > 0 do
			local data = pros[len]
			data = nil
			table.remove(self.Pros, len)
			len = #pros
		end
	end
	pros = nil
	adds = nil
end
--endregion
