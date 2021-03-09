--[[
装备强化套装属性
--]]
Suit=Super:New{Name="Suit"}
local My=Suit

function My:Ctor()
	self.curStr = ObjPool.Get(StrBuffer)
	self.lastStr = ObjPool.Get(StrBuffer)
	self.attList = {"hp","atk","def","arm"}
end

function My:Init(go)
	local TF=TransTool.FindChild
	local CG=ComTool.Get
	self.trans=go.transform

	self.curLv=CG(UILabel,self.trans,"curLv",self.Name,false)
	self.curLab=CG(UILabel,self.curLv.transform,"lab",self.Name,false)
	self.lastLv=CG(UILabel,self.trans,"lastLv",self.Name,false)
	self.lastLab=CG(UILabel,self.lastLv.transform,"lab",self.Name,false)
	UITool.SetLsnrClick(self.trans,"Mask",self.Name,self.Close,self)
end

--lv 套装等级
function My:UpData(type_id)
	self:Open()
	self:CleanStr()
	
	local cLv = 0
	local tb = EquipMgr.hasEquipDic
	for k,v in pairs(tb) do
		local equip=EquipBaseTemp[tostring(v.type_id)]
		if not equip then iTrace.eError("xiaoyu","装备表为空 id: "..v.type_id) return end
		cLv=cLv+v.lv
	end

	local data = Equiplv[1]
	if cLv<data.lv then
		for i,v in ipairs(self.attList) do
			local uLua = self.attList[i]
			local name = PropTool.GetName(uLua)
			self.curStr:Apd("[8A7F72]"):Apd(name):Apd("：[-][67CC67]"):Apd(0):Apd("[-]\n")
		end	
		self.curLab.text=self.curStr:ToStr()

		self.lastStr=self:GetAtt("[FFE9BD]",data,self.lastStr)
		self.lastLv.text="下一等级\n全身强化等级  "..data.lv
		self.lastLab.text=self.lastStr:ToStr()
	else
		local maxLv = Equiplv[#Equiplv]
		for i,v in ipairs(Equiplv) do
			if cLv>=maxLv.lv then
				self.lastLv.text="下一等级\n当前等级已达最大级"
				return 
			else
				local next = Equiplv[i+1]
				if cLv>=v.lv and cLv<next.lv then
					self.curStr=self:GetAtt("[8A7F72]",v,self.curStr)
					self.curLv.text="当前等级\n全身强化等级  "..cLv
					self.curLab.text=self.curStr:ToStr()

					self.lastStr=self:GetAtt("[FFE9BD]",next,self.lastStr)
					self.lastLv.text="下一等级\n全身强化等级  "..next.lv
					self.lastLab.text=self.lastStr:ToStr()
					return
				end				
			end
		end

	end
end

function My:GetAtt(col,equipLv,str)
	for i,v in ipairs(self.attList) do
		local uLua = self.attList[i]
		local name = PropTool.GetName(uLua)
		local val = PropTool.GetValByNLua(uLua,equipLv[uLua])
		str:Apd(col):Apd(name):Apd("：[-][67CC67]"):Apd(val):Apd("[-]\n")
	end	
	return str
end

function My:Close()
	self.trans.gameObject:SetActive(false)
	self:CleanStr()
	--ObjPool.Add(self)
end

function My:Open()
	self.trans.gameObject:SetActive(true)
end

function My:CleanStr()
	self.curStr:Dispose()
	self.lastStr:Dispose()
end


function My:Dispose()
	self:Close()
end