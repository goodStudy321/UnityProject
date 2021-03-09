--[[
套装属性
--]]
local GbjPool=Loong.Game.GbjPool.Instance

AttC=Super:New{Name="AttC"}
local My=AttC

function My:Ctor()
	self.list={}
	self.total=ObjPool.Get(StrBuffer)
end

function My:Init(go)
	self.trans=go.transform
	local CG=ComTool.Get
	local TF=TransTool.FindChild

	self.NameL=CG(UILabel,self.trans,"Name",self.Name,false)
	self.C=TF(self.trans,"C").transform
	self.Title=CG(UILabel,self.C,"Title",self.Name,false)
	self.Label=CG(UILabel,self.C,"Label",self.Name,false)
	UITool.SetLsnrClick(self.trans,"Mask",self.Name,self.Close,self)
end

function My:UpData(type_id,gp)
	self:Open()
	self:CleanList()

	local equip=EquipBaseTemp[tostring(type_id)]
	if(equip==nil)then iTrace.Error("Loong", "装备==null id:".. type_id) return end
	local group=nil
	local title =nil
	if(gp==1)then
		group=equip.suit1
		title=" [e9ac50][诛仙]"
	elseif(gp==2)then
		group=equip.suit2
		title=" [e9ac50][诛神]"
	end
	if(group==nil)then return end
	local suit=EquipSuit[tostring(group)]
	if(suit==nil)then iTrace.Error("Loong", "装备套装表==null id:".. group) return end

	local num1=suit.num1
	local num2=suit.num2
	local num3=suit.num3

	local max = nil
	if(num3~=0)then max=num3
	elseif(num2~=0)then max=num2
	else max=num1 
	end
	local curNum = EquipMgr.GetCurNum(gp,group)
	self.NameL.text=StrTool.Concat(title..suit.name.. "[-]  [67cc67]".. curNum.."/".. max)

	local att1=suit.att1
	if(num1~=nil and num1~=0)then
		self:SetNA(curNum,num1,att1)
	end

	
	local att2=suit.att2
	if(num2~=nil and num2~=0)then
		self:SetNA(curNum,num2,att2)
	end

	
	local att3=suit.att3
	if(num3~=nil and num3~=0)then
		self:SetNA(curNum,num3,att3)
	end

end

function My:SetNA(curNum,num,att)
	self.total:Dispose()
	self:SetT(curNum,num)	
	for i,v in ipairs(att) do
		local id=v.id
		local val=v.val
		local name = "[8a7f72]"..PropTool.GetNameById(id)
		local va = "[ffe9bd]"..PropTool.GetValByID(id,val).."[-]"
		self.total:Apd(name):Apd("：[-]"):Apd(va):Apd("\n")
	end
	local content = self.total:ToStr()
	if(StrTool.IsNullOrEmpty(content)==false)then
		self:SetL(self.total:ToStr())
	end
end

--套装效果 lab
function My:SetT(curNum,num)
	local t= GameObject.Instantiate(self.Title)
	t.transform.parent=self.C
	t.transform.localScale=Vector3.one
	local y=0
	if(#self.list>0)then
		local last = self.list[#self.list]
		local lastLab=last:GetComponent(typeof(UILabel))
		y=last.transform.localPosition.y-lastLab.printedSize.y
	end
	t.transform.localPosition=Vector3.New(0,y,0)

	local col = "[67cc67]"
	if(curNum<num)then
		col="[e83030]"
	end
	t.text=StrTool.Concat("[e9ac50]套装效果：[-]",col,tostring(num),"件")
	t.gameObject:SetActive(true)

	self.list[#self.list+1]=t
end

--攻击：+999 lab
function My:SetL(content)
	local l= GameObject.Instantiate(self.Label)
	l.transform.parent=self.C
	l.transform.localScale=Vector3.one
	local y = self.list[#self.list].transform.localPosition.y-40
	l.transform.localPosition=Vector3.New(0,y,0)
	l.text=content
	l.gameObject:SetActive(true)

	self.list[#self.list+1]=l
end

function My:Open()
	self.trans.gameObject:SetActive(true)
end

function My:Close()
	self.trans.gameObject:SetActive(false)
	self:CleanList()
end

function My:CleanList()
	while(#self.list>0)do
		local go=self.list[#self.list]
		GameObject.Destroy(go)
		self.list[#self.list]=nil
	end
	self.NameL.text=""
	self.total:Dispose()
end

function My:Dispose()
	self:Close()
end