--[[
宝石格子
--]]
UIGemCell=Super:New{Name="UIGemCell"}
local My=UIGemCell
My.eClick=Event()

function My:Init(go)
	local CG=ComTool.Get
	local TF=TransTool.FindChild
	self.trans=go.transform
	self.red=TF(self.trans,"red")

	self.cell=ObjPool.Get(Cell)
	self.cell:InitLoadPool(self.trans,0.75,nil,nil,nil,Vector3.New(-89,0,0))
	self.NameLab=CG(UILabel,self.trans,"Name",self.Name,false)
	--self.Lab=CG(UILabel,self.trans,"Lab",self.Name,false)
	self.Bg=CG(UISprite,self.trans,"bg",self.Name,false)
	--UITool.SetBtnClick(self.trans,"Button",self.Name,self.OnClick,self)	
	UITool.SetLsnrSelf(go,self.ClickCell,self,self.Name,false)	
	--self.BtnLab	=CG(UILabel,self.trans,"Button/Label",self.Name,false)
end

function My:UpData(type_id,isSeal,red)
	self.isSeal=isSeal and true or false
	self.type_id=tostring(type_id)
	self.trans.name=self.type_id
	local item = ItemData[self.type_id]
	if(item==nil)then iTrace.eError("xiaoyu","道具表为空 type_id: "..self.type_id)return end
	local tex = ""
	local num = PropMgr.TypeIdByNum(self.type_id)
	if(num>1)then tex=tostring(num)end
	self.cell:UpData(item,tex)
	self:UpName(isSeal)
	self.red:SetActive(red);
end

function My:UpName(isSeal)
	local tab = isSeal and tSealData or GemData
	self.NameLab.text=tab[self.type_id].name
end

function My:ClickCell()
	GemTip.gemId=tonumber(self.type_id)
	self:ShowBg(true)

	local tb = EquipMgr.hasEquipDic[EquipPanel.curPart]
	if not tb then return end
	local type_id =tb.type_id
	if self.isSeal then
		EquipMgr.ReqSealPunch(type_id,GemTip.gemId,GemTip.clickIndex)
	else
		EquipMgr.ReqPunch(type_id,GemTip.gemId,GemTip.clickIndex)
	end
	My.eClick()
end

function My:ShowBg(state)
	-- if state==true then
	-- 	self.Bg.spriteName="ty_a12"
	-- else
	-- 	self.Bg.spriteName="ty_a3"
	-- end
end


function My:Dispose()
	self.isSeal=false;
	UIGemCell.eClick:Remove(self.OnClickCell,self)
	if(self.cell~=nil)then self.cell:DestroyGo() ObjPool.Add(self.cell) self.cell=nil end	
	GbjPool:Add(self.trans.gameObject)
	if(self.tex~=nil)then ObjPool.Add(self.tex) end
	ListTool.Clear(self.att)
	TableTool.ClearUserData(self)
end