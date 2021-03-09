--[[
同心结Tip
--]]
KnotTip=UIBase:New{Name="KnotTip"}
local My=KnotTip
local list = {}
local str = ObjPool.Get(StrBuffer)


function My:InitCustom()
	local CG=ComTool.Get
	local TF=TransTool.FindChild

	self.top=CG(UISprite,self.root,"Bg/top",self.Name,false)
	local All = TF(self.root,"All").transform	
	self.lvLab=CG(UILabel,All,"lv",self.Name,false)
	self.cell=ObjPool.Get(Cell)
	self.cell:InitLoadPool(self.root,nil,nil,nil,nil,Vector3.New(-106.5,249,0))

	self.NameLab=CG(UILabel,All,"Name",self.Name,false)

	self.Work=CG(UILabel,All,"Work",self.Name,false)
	self.Part=CG(UILabel,All,"Part",self.Name,false)
	self.Fight=CG(UILabel,All,"Fight",self.Name,false)
	self.AllFight=CG(UILabel,All,"AllFight",self.Name,false)

	self.des=CG(UILabel,self.root,"des",self.Name,false)

	self.att=TF(self.root,"AttPanel/att").transform
	self.titlePre=TF(self.att,"title")
	self.labPre=TF(self.att,"lab")

	UITool.SetLsnrClick(self.root,"Mask",self.Name,self.Close,self)
end

function My:UpData(type_id)
	self.type_id=type_id
	self.item=ItemData[tostring(type_id)]	
	if(self.item==nil)then iTrace.eError("xiaoyu","道具表为空 id: "..type_id)return end
	self.cell:UpData(self.item)
	self.top.spriteName="cell_a0"..self.item.quality

	--描述
	self.des.text=self.item.des or ""

	--名字
	local col=UIMisc.LabColor(self.item.quality)
	self.NameLab.text=col..self.item.name

	--职业
	self.Work.text="[67CC67]通用"

	--部位
	self.knot = KnotData[MarryInfo.data.knotid+1]
	if not self.knot then iTrace.eError("xiaoyu","同心结表为空 id: "..MarryInfo.data.knotid)return end
	local rank = self.knot.rank
	local lv = self.knot.lv
	self.Part.text=UIMisc.NumToStr(rank,"阶"..self.item.name)

	--装备评分
	local a1=0
	local attList = self.knot.baseAtt
	for i,v in ipairs(attList) do
		a1= a1+PropTool.PropFight(v.id,v.val)
	end
	 
	local fight=math.floor(a1*(10000+0)/10000)
	self.Fight.text="[cccccc]装备评分  [67cc67]"..tostring(fight)
	self.AllFight.text="[cccccc]综合评分  [67cc67]"..tostring(fight)

	--装备等级
	self.lvLab.text="[cccccc]装备等阶  [67cc67]"..UIMisc.NumToStr(rank,"阶")

	self:KnotBase()
	self:KnotAtt()
	self:MarryReShip()
end

--基础属性
function My:KnotBase()
	str:Dispose()
	local attList = self.knot.baseAtt
	for i,v in ipairs(attList) do
		if(StrTool.IsNullOrEmpty(str:ToStr())==false)then
			str:Line()
		end
		local name = PropTool.GetNameById(v.id)
		local val = PropTool.GetValByID(v.id,v.val)
		str:Apd("[cccccc]"):Apd(name):Apd("  "):Apd(val)
	end
	local tex=str:ToStr()
	if(StrTool.IsNullOrEmpty(tex))then return end
	--标题
	self:CreateTitle("基础属性")
	self:CreateLab(tex)
end


--仙侣属性
function My:KnotAtt()
	str:Dispose()
	local attList = self.knot.att
	for i,v in ipairs(attList) do
		if(StrTool.IsNullOrEmpty(str:ToStr())==false)then
			str:Line()
		end
		local name = PropTool.GetNameById(v.id)
		local val = PropTool.GetValByID(v.id,v.val)
		str:Apd("[cccccc]"):Apd(name):Apd("  "):Apd(val)
	end
	local tex=str:ToStr()
	if(StrTool.IsNullOrEmpty(tex))then return end
	--标题
	self:CreateTitle("仙侣属性")
	self:CreateLab(tex)
end

--仙侣关系
function My:MarryReShip()
	str:Dispose()
	local info=MarryInfo.data.coupleInfo
	if info then --有侠侣
		local name=info.name
		local nm = User.instance.MapData.Name
		local sex=info.sex

		if sex==1 then --1 男
			str:Apd("夫君： "..name)
			str:Apd("\n娘子： "..nm)
		elseif sex==0 then --0 女
			str:Apd("夫君： "..nm)
			str:Apd("\n娘子： "..name)
		end
	else
		str:Apd("无")
	end
	--标题
	self:CreateTitle("仙侣关系")
	local tex=str:ToStr()
	self:CreateLab(tex)

end

function My:CreateTitle(text)
	self:Create(text,self.titlePre,19)
end

function My:CreateLab(text)
	self:Create(text,self.labPre,5)
end

function My:Create(text,pre,lerpY)
	local t = list

	local go = GameObject.Instantiate(pre)
	go.transform.parent=self.att.transform
	go:SetActive(true)
	go.transform.localScale=Vector3.one
	local y=0
	if(#t>0)then
		local last = t[#t]
		y = last.transform.localPosition.y-last.printedSize.y-lerpY
	end
	go.transform.localPosition=Vector3.New(0,y,0)

	local label=go:GetComponent(typeof(UILabel))
	label.text=text
	list[#list+1]=label
end

function My:CloseCustom()
	if self.cell then self.cell:DestroyGo() ObjPool.Add(self.cell) self.cell=nil end
	while(#list>0)do
		local att = list[#list].gameObject
		GameObject.Destroy(att)
		list[#list]=nil
	end
end

return My