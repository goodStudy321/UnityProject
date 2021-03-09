--[[
装备界面Tip
--]]
require("UI/UIEquip/GemTip")
require("UI/UIEquip/AttC")
require("UI/UIEquip/Suit")

TipPanel=Super:New{Name="TipPanel"}
local My = TipPanel

function My:Init(go)
	self.trans=go.transform
	local TF=TransTool.FindChild
	local CG=ComTool.Get
	local U = UITool.SetLsnrClick
	
	self.mAttC = TF(self.trans, "AttC")
	self.mSuit = TF(self.trans, "Suit")
	self.mGemTip = TF(self.trans, "GemTip")
	self.mSelectE=TF(self.trans, "SelectE")

	self.work=UIMisc.GetWork(User.instance.MapData.Category)
	self.bg=TF(self.trans,"Tipbg")
	self.lab1=CG(UILabel,self.trans,"Tipbg/lab1",self.Name,false)
	U(self.trans,"Tipbg/mask",self.Name,self.HideTip,self)

	self:AddE()
end

function My:AddE()
	--T11.eSuit:Add(self.OnSuit,self)
	--GemCell.eClickGem:Add(self.OnGem,self)
	SealCell.eClickSeal:Add(self.OnSeal,self)
	--Tg2.eAtt:Add(self.OnAtt,self)
	--T34.eCell:Add(self.OnEquip,self)
	--T34.eTip:Add(self.OnTipInfo,self)
end

function My:ReE()
	--T11.eSuit:Remove(self.OnSuit,self)
	--GemCell.eClickGem:Remove(self.OnGem,self)
	SealCell.eClickSeal:Add(self.OnSeal,self)
	--Tg2.eAtt:Remove(self.OnAtt,self)
	--T34.eCell:Remove(self.OnEquip,self)
	--T34.eTip:Add(self.OnTipInfo,self)
end

function My:OnSuit(type_id)
	if not self.Suit then
		self.Suit=ObjPool.Get(Suit)
		self.Suit:Init(self.mSuit)
	end
	self.Suit:UpData(type_id)
	self.C=self.Suit
end

function My:OnGem(title,tipList,lock)
	if lock  then
		UITip.Log("无法镶嵌");
		return;
	end
	if not self.GemTip then
		self.GemTip=GemTip
		self.GemTip:Init(self.mGemTip)
	end
	self.GemTip:UpData(title,tipList)
	self.C=self.GemTip
end
function My:OnSeal(title,tipList,lock)
	if lock  then
		UITip.Log("无法镶嵌");
		return;
	end
	if not self.GemTip then
		self.GemTip=GemTip
		self.GemTip:Init(self.mGemTip)
	end
	self.GemTip:UpData(title,tipList,true)
	self.C=self.GemTip
end
function My:OnAtt(type_id,group)
	if not self.AttC then
		self.AttC=ObjPool.Get(AttC)
		self.AttC:Init(self.mAttC)
	end
	self.AttC:UpData(type_id,group)
	self.C=self.AttC
end

function My:OnEquip(data,Group)
	if not self.SelectE then 
		self.SelectE=ObjPool.Get(SelectE) 
		self.SelectE:Init(self.mSelectE)
	end	
	self.SelectE:UpData(data,Group)
	self.C=self.SelectE
end

function My:OnTipInfo(type_id)
	local com = EquipCompound[type_id]
	if not com then return end
	local id = tostring(com.canId[1])
	local item = ItemData[id]
	local equip = EquipBaseTemp[id]
	self.lab1.text="1、多件[66c34e]"..self.work.."[-]职业[66c34e]"..com.rank.."[-]阶[66c34e]"..(equip.startLv).."[-]星的"..self:GetQua(item.quality).."装备可合成"

	self.bg:SetActive(true)
end

function My:GetQua(qua)
	local color = UIMisc.LabColor(qua)
	local x = ""
	if qua==1 then
		x="白色"
	elseif qua==2 then
		x="蓝色"
	elseif qua==3 then
		x="紫色"
	elseif qua==4 then
		x="橙色"
	elseif qua==5 then
		x="红色"
	elseif qua==6 then
		x="粉色"
	end
	return color..x.."[-]"
end

--隐藏Tip
function My:HideTip()
	self.bg:SetActive(false)
end

function My:Close(go)
	if self.C then self.C:Close() end
	go:SetActive(false)
end

function My:Dispose()
	self:ReE()
	if(self.Suit)then ObjPool.Add(self.Suit)  self.Suit=nil end
	if(self.GemTip)then self.GemTip:Dispose(); self.GemTip=nil end
	if(self.AttC)then ObjPool.Add(self.AttC) self.AttC=nil end
	if(self.SelectE)then ObjPool.Add(self.SelectE) self.SelectE=nil end
	self.C=nil
	TableTool.ClearUserData(self)
end