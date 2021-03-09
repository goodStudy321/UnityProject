--[[
装备Tip
--]]
local AssetMgr=Loong.Game.AssetMgr
EquipRoot=Super:New{Name="EquipRoot"}
local My=EquipRoot
local attL={"hp","atk","def","arm"}
local specialAtt={"hp","atk","atkP","pvpAdd","addskilldam","reduceskilldam","hpadd","atkadd","ampdam","damred"}
local attSeaL={"dodge","hit","tena","crit"}
local POS=nil

function My:Ctor()	
	self.AttList={}
	self.NoneList={}
	self.index = 1
	self.str=ObjPool.Get(StrBuffer)
	self.colorList={}
end


function My:Init(go)
	self.root=go.transform

	local CG=ComTool.Get
	local TF=TransTool.FindChild

	--EquipCell

	self.Bg=TF(self.root,"Bg")
	self.SpecialBg=TF(self.root,"SpecialBg")
	self.top=CG(UISprite,self.root,"Bg/top",self.Name,false)
	local All = TF(self.root,"All").transform	
	self.rob=CG(UILabel,All,"Rob",self.Name,false)
	self.lvLab=CG(UILabel,All,"lv",self.Name,false)
	self.worth=CG(UILabel,All,"worth",self.Name,false)
	self.sellLb=CG(UILabel,All,"sellP",self.Name,false)
	self.cell=ObjPool.Get(Cell)
	self.cell:InitLoadPool(self.root,nil,nil,nil,nil,Vector3.New(-106.5,249.32,0))

	self.NameLab=CG(UILabel,All,"Name",self.Name,false)

	self.Work=CG(UILabel,All,"Work",self.Name,false)
	self.Part=CG(UILabel,All,"Part",self.Name,false)
	self.Fight=CG(UILabel,All,"Fight",self.Name,false)
	self.AllFight=CG(UILabel,All,"AllFight",self.Name,false)

	--AttPanel
	self.panel=CG(UIPanel,self.root,"AttPanel",self.Name,false)
	POS=self.panel.transform.localPosition
	self.att=TF(self.panel.transform,"att").transform

	self.titlePre=TF(self.att,"title")
	self.labPre=TF(self.att,"lab")
	self.nonePre=TF(self.att,"none")

	self.time = CG(UILabel,self.root.transform,"time",self.Name,false)
	self.time.gameObject:SetActive(false)
end

function My:UpData(obj,suit,attWhat)
	if(type(obj)=="table")then 
		self.tb=obj  
		self.type_id=tostring(self.tb.type_id )
		self.endTime = obj.market_end_time
	elseif(type(obj)=="string")then
		self.type_id=obj
	else
		self.type_id=tostring(obj)
	end

	self.item=ItemData[self.type_id]	
	if(self.item==nil)then iTrace.eError("xiaoyu","道具表为空 id: "..self.type_id)return end
	self.equip=EquipBaseTemp[self.type_id]
	if(self.equip==nil)then iTrace.eError("xiaoyu","装备表为空 id: "..self.type_id)return end
	self.cell:UpData(self.item)
	self.top.spriteName="cell_a0"..self.item.quality

	self:UpStrLv()
	self:UpRob()
	self:UpLv()
	self:UpWorth()
	self:UpSell()
	self:UpName()
	self:UpWork()
	self:UpPart()
	self:UpFight()
	self:SpecialAtt()
	self:BaseAtt()
	self:RankAtt(attWhat)
	self:ConsiAtt()
	self:GemInlay()
	self:SealInlay()
	self:SuitAtt(suit)
	self:GetWayDes()
end

function My:ShowlimTime()
	--// 不可上架显示
	local endTime = self.endTime
	local value = false
	local nowTime = TimeTool.GetServerTimeNow()*0.001
	if self.item and self.item.startPrice and self.item.AucSecId and endTime then
		--local time = self.item.time
		local time = endTime - nowTime
		if endTime ~= 1 and endTime > 0 then
			if nowTime - endTime <= 0 then
				if not self.timer then
					self.timer = ObjPool.Get(DateTimer)
				end
				self.timer:Stop()
				self.timer.invlCb:Add(self.InvlCb, self)
				self.timer.complete:Add(self.CompleteCb, self)
				self.timer.seconds = time + 1
				self.timer.fmtOp = 0
				self.timer:Start()
				self:InvlCb()
				value = true
				self.cell:ShowLimit(endTime)
			else
				value = false
			end
			self.time.gameObject:SetActive(value)
		end
	end
end

function My:InvlCb()
	local text = "【"..self.timer.remain.."后可上架】"
	if self.time then
		self.time.text = text
	end
end

local btnList={"Equip","Sale","Use","Compound","Inset","PutIn","GetOut","PutAway","sealInsert","Renew"}

function My:CompleteCb()
	self.time.gameObject:SetActive(false)
	self.cell:ShowLimit(self.endTime)
	self:UpdateBtn()
end

function My:UpdateBtn()
	local btn = {}
	local item = ItemData[tostring(self.tb.type_id)]
	if item == nil then return end
	local uFx=item.uFx
	if uFx ==1 or uFx==28 then --装备
		local price=item.price or 0
		if price~=0 then btn[#btn+1]=btnList[2] end
		btn[#btn+1]=btnList[1]
		if uFx==28 then btn[#btn+1]=btnList[10] end
	end
	EquipTip:ShowBtn(btn)
end

function My:UpStrLv()
	self.lv=0
	if self.tb then 
		self.lv=self.tb.lv or 0 
		-- if self.lv>self.equip.max then self.lv=self.equip.max end
	end
end

--境界
function My:UpRob()
	self.str:Dispose()
	local rob=self.item.realm or 0
	local color="[67CC67]"
	local robText = "境界  不限"
	if rob~=0 then
		local data = RobberyMgr:GetCurCfg(rob)
		robText=data.floorName
		local robcfg = RobberyMgr:GetCurCfg()
		if not robcfg or robcfg.id<rob then color=UIMisc.LabColor(5) end
		self.str:Apd(color):Apd("境界  "):Apd(robText)
	else
		self.str:Apd(color):Apd(robText)
	end
	self.rob.text=self.str:ToStr()
end

function My:UpLv()
	local lv=self.item.useLevel
	local color ="[67CC67]"
	local result = "不限"
	if(lv~=nil)then 
		if(User.instance.MapData.Level<lv)then
			color=UIMisc.LabColor(5)
		end
		local limitLv = GlobalTemp["90"].Value3
		if lv <=limitLv then result=color.."等级  "..lv.."级"
		else result=color.."化神  "..(lv-limitLv).."级" end		
	end
	self.lvLab.text=color..result
end

function My:UpWorth()
	local w = self.item.worth
	local c = self.item.cost
	if w ~= 0 then
		if EquipTip.isInWarehouse then
			self.worth.text="[F4DDBDFF]兑换积分：[-][ffe9bd]"..c
		else
			self.worth.text="[F4DDBDFF]仓库积分：[-][ffe9bd]"..w
		end
	else
		self.worth.text=""
	end
	--if w~=0 and EquipTip.showDepotPoint==true then self.worth.text="[F4DDBDFF]仓库积分：[-][ffe9bd]"..w
	--else self.worth.text="" end
end

function My:UpSell()
	local id = self.equip.id
	local s = ItemData[tostring(id)].price
	if s ~= 0 then
		self.sellLb.text = "[F4DDBDFF]售价：[-][00FF00]"..s
	else
		self.sellLb.text = ""
	end
end

function My:UpName()
	local col=UIMisc.LabColor(self.item.quality)
	local text=""
	if self.lv~=0 then 
		text=" + "..self.lv
	end
	self.NameLab.text=col..self.item.name..text
end

--	职业
function My:UpWork()
	self.str:Dispose()
	local color = "[67CC67]"
	local uw=User.instance.MapData.Category
	local cate=self.item.cateLim or 0
	local gil=self.item.gilgulLv or 0	
	if cate==0 then self.Work.text=color.."通用" return end	
	if gil ==0 then --没有转生等级	
		if(uw~=cate)then
			color=UIMisc.LabColor(5)
		end
		self.str:Apd(color):Apd(UIMisc.GetWork(cate)		)
	else --有转生等级
		if(RebirthMsg.RbLev<gil or cate~=uw)then
			color=UIMisc.LabColor(5)
		end	
		local w = nil
		if cate==1 then
			w=UIMisc.GetSex1(gil)
		else
			w=UIMisc.GetSex2(gil)
		end
		self.str:Apd(color):Apd(w):Apd("("):Apd(UIMisc.NumToStr(gil)):Apd("转)")
	
	end	
	self.Work.text=self.str:ToStr()
end

--部位
function My:UpPart()
	local part = UIMisc.WearParts(self.equip.wearParts)
	--local rank = UIMisc.GetStepStr(self.equip.wearRank)
	self.Part.text=part
end

--装备评分=（装备基础属性总战力）*（10000+装备极品属性评分之和）/10000
--综合评分=（装备基础属性总战力+装备强化属性总战力）*（10000+装备极品属性评分之和）/10000
function My:UpFight()
	local a1,a2,colorList
	if self.tb then 
		a1,a2,colorDic=PropTool.EquipTbFight(self.tb) 
	else
		a1,a2,colorDic=PropTool.EquipFight(self.type_id)
	end

	local fight=math.floor(a1*(10000+a2)/10000)
	self.Fight.text="[F4DDBDFF]装备评分  [67cc67]"..tostring(fight)

	--强化
	local str = 0
	if self.lv>0 then
		local id=tostring(EquipMgr.FindType(tonumber(self.equip.wearParts))+self.lv)
		local data = EquipStr[id]
		if not data then iTrace.eError("xiaoyu","装备强化概率表为空 id: "..id)return end
		str=PropTool.GetFight(data)
	end

	local allFight=math.floor((a1+str)*(10000+a2)/10000)
	self.AllFight.text="[F4DDBDFF]综合评分  [67cc67]"..tostring(allFight)

	ListTool.Clear(self.colorList)
	if colorDic then 
		for k,v in pairs(colorDic) do
			self.colorList[#self.colorList+1]=v
		end
	end

	if #self.colorList>1 then 
		table.sort( self.colorList, My.SortColor )
	end
end

function My.SortColor(a,b)
	return a.b>b.b
end

--戒指&手镯特殊属性
function My:SpecialAtt()
	self.str:Dispose()
	for i,nLua in ipairs(specialAtt) do
		local temp = SpecialItemData[tostring(self.equip.id)]
		self.Bg:SetActive(temp==nil)
		self.SpecialBg:SetActive(temp~=nil)
		if not temp then return end
		local va=temp[nLua] or 0
		if(va~=0)then
			if(StrTool.IsNullOrEmpty(self.str:ToStr())==false)then
				self.str:Line()
			end
			local name = PropTool.GetName(nLua)
			local val = PropTool.GetValByNLua(nLua,va)
			self.str:Apd("[F4DDBDFF]"):Apd(name):Apd("  "):Apd(val)
		end
	end
	local tex=self.str:ToStr()
	if(StrTool.IsNullOrEmpty(tex))then return end
	--标题
	local go=self:CreateTitle("特殊属性")
	local bg = ComTool.Get(UISprite,go.transform,"bg",self.Name,false)
	bg.spriteName="tips_wenbentiao"
	self:CreateLab(tex)
end

	
--基础属性 强化属性
function My:BaseAtt()
	self.str:Dispose()
	local tab = self.equip.addID
	if #tab>0 then
		for i,nLua in ipairs(attL) do
			local temp = self.equip
			local va=temp[nLua] or 0
			if(va~=0)then
				if(StrTool.IsNullOrEmpty(self.str:ToStr())==false)then
					self.str:Line()
				end
				local name = PropTool.GetName(nLua)
				local val = PropTool.GetValByNLua(nLua,va)
				local com = self:GetComVal(nLua,tab)
				if(com==nil)then com="" end
				self.str:Apd("[F4DDBDFF]"):Apd(name):Apd("  "):Apd(val):Apd(com)
			end
		end
		local tex=self.str:ToStr()
		if(StrTool.IsNullOrEmpty(tex))then return end
		--标题
		self:CreateTitle("基础属性")
		self:CreateLab(tex)
	end
end

function My:GetComVal(nLua)
	if self.lv>0 then
		local id = tostring(EquipMgr.FindType(tonumber(self.equip.wearParts))+self.lv)
		local data = EquipStr[id]
		if not data then iTrace.eError("xiaoyu","装备强化概率表为空 id: "..id)return end
		local val = data[nLua]
		if not val then 
			return 
		end
		return " [67cc67](强化+"..val..")"
	end
	return nil
end

--卓越属性
function My:RankAtt(attWhat)
	self.str:Dispose()
	if #self.colorList==0 then return end
	self:CreateTitle("卓越属性")
	for i,v in ipairs(self.colorList) do
		if(StrTool.IsNullOrEmpty(self.str:ToStr())==false)then
			self.str:Line()
		end
		if attWhat==true then 
			self.str:Apd("?????")
		else
			local color = UIMisc.LabColor(v.b)
			local name=PropTool.GetNameById(tonumber(v.k))
			local val=PropTool.GetValByID(tonumber(v.k),v.v)
			self.str:Apd(color):Apd(name):Apd("    +"):Apd(val)
		end		
	end
	local tex=self.str:ToStr()
	self:CreateLab(tex)
end

--洗炼属性
function My:ConsiAtt()
	if not self.tb then return end
	self.str:Dispose()
	local cList = self.tb.cList
	if not cList or #cList==0 then return end
	self:CreateTitle("洗炼属性")
	for i,kv in ipairs(cList) do
		local id = kv.v
		local val = kv.b
		local prop = PropName[id]
		local nLua = prop.nLua
		local list= EquipMgr.conciseDic[tostring(self.equip.wearParts)]
		for i1,v in ipairs(list) do
			local consi = EquipConcise[v]
			local arg = consi[nLua]
			if arg then 
				local min = arg[1]
				local max = arg[2]
				if val>=min and val<=max then 
					local color = UIMisc.LabColor(consi.qua)
					local name=prop.name
					local val=PropTool.GetValByID(id,val)
					if(StrTool.IsNullOrEmpty(self.str:ToStr())==false)then
						self.str:Line()
					end
					self.str:Apd(color):Apd(name):Apd("    +"):Apd(val)
					break
				end
			end
		end
	end
	local tex=self.str:ToStr()
	self:CreateLab(tex)
end

--宝石镶嵌
function My:GemInlay()
	self:CreateTitle("宝石镶嵌")	
	local count=self.equip.holesNum
	for i=1,count do
		if(self.tb~=nil and self.tb.stDic~=nil)then 
			local dic=self.tb.stDic
			local id=dic[tostring(i)]
			if id~=nil then
				self:GemI(id)
			else
				local tex="     [F8D7B4FF]未镶嵌"
				self:CreateLab(tex)
				self:CreateNone(false)
			end
		else
			local text="     [F8D7B4FF]未镶嵌"
			self:CreateLab(text)
			self:CreateNone(false)
		end
	end
	if not self.tb then return end
	local dic=self.tb.stDic
	if not dic then 
		self:NoVIP()
		return 
	end
	local vip = dic["6"] 
	if vip then 
		self:GemI(vip,true)
	else
		self:NoVIP()
	end
end

function My:NoVIP()
	local tex="     [F8D7B4FF]未开启   VIP7专享" 
	if VIPMgr.GetVIPLv()>=7 then 
		tex="     [F8D7B4FF]未镶嵌   VIP7专享" 
	end
	self:CreateLab(tex)
	self:CreateNone(false)
end

function My:GemI(id,add)
	self.str:Dispose()	
	local gem=GemData[tostring(id)]
	local item=ItemData[tostring(id)]
	local color = "     [B1A495]"
	if(gem.type==1)then --生命宝石
		color = "     [679ECC]"	
	elseif(gem.type==3)then --攻击宝石
		color = "     [e83030]"
	end
	self.str:Apd(color):Apd(item.name)
	if add==true then self.str:Apd("   [F8D7B4FF]VIP7专享") end
	local tex = self.str:ToStr()
	if(StrTool.IsNullOrEmpty(tex)==false)then
		self:CreateLab("  [F8D7B4FF]"..tex)
		--self:CreateNone("type_".. gem.type)
		self:CreateNone(true,gem.type)
	end
	self.str:Dispose()
	for i,nLua in ipairs(attL) do
		local  vv = gem[nLua]
		if(vv~=nil and vv~=0)then
			local name = PropTool.GetName(nLua)
			local val = PropTool.GetValByNLua(nLua,vv)
			if(StrTool.IsNullOrEmpty(self.str:ToStr())==false)then
				--self.str:Line()
			end
			self.str:Apd("    [F4DDBDFF]"):Apd(name):Apd("  "):Apd(val)
		end					
	end
	local str=self.str:ToStr()
	if StrTool.IsNullOrEmpty(str)==false then self:CreateLab(str) end
end

--纹印镶嵌
function My:SealInlay()
	self:CreateTitle("纹印")	
	local count=self.equip.SealholesNum
	for i=1,count do
		if(self.tb~=nil and self.tb.slDic~=nil)then 
			local dic=self.tb.slDic
			local id=dic[tostring(i)]
			if id~=nil then
				self:sealI(id)
			else
				local tex="     [F8D7B4FF]未镶嵌"
				self:CreateLab(tex)
				self:CreateNone(false)
			end
		else
			local text="     [F8D7B4FF]未镶嵌"
			self:CreateLab(text)
			self:CreateNone(false)
		end
	end
	if not self.tb then return end
	local dic=self.tb.slDic
	if not dic then 
		self:NoSealVIP()
		return 
	end
	local vip = dic["5"] 
	if vip then 
		self:sealI(vip,true)
	else
		self:NoSealVIP()
	end
end

function My:NoSealVIP()
	local tex="     [F8D7B4FF]未开启   VIP8专享" 
	local vip = VIPMgr.GetVIPLv()
	local vipInfo = soonTool.GetVipInfo(vip)
	if vipInfo.sealVip== 1 then 
		tex="     [F8D7B4FF]未镶嵌   VIP8专享" 
	end
	self:CreateLab(tex)
	self:CreateNone(false)
end

function My:sealI(id,add)
	self.str:Dispose()	
	local gem=tSealData[tostring(id)]
	local item=ItemData[tostring(id)]
	local color = "     [B1A495]"
	if(gem.type==1)then --生命纹印
		color = "     [679ECC]"	
	elseif(gem.type==3)then --攻击纹印
		color = "     [e83030]"
	end
	self.str:Apd(color):Apd(item.name)
	if add==true then self.str:Apd("   [F8D7B4FF]VIP8专享") end
	local tex = self.str:ToStr()
	if(StrTool.IsNullOrEmpty(tex)==false)then
		self:CreateLab("  [F8D7B4FF]"..tex)
		--self:CreateNone("type_".. gem.type)
		self:CreateNone(true,gem.type,true)
	end
	self.str:Dispose()
	for i,nLua in ipairs(attSeaL) do
		local  vv = gem[nLua]
		if(vv~=nil and vv~=0)then
			local name = PropTool.GetName(nLua)
			local val = PropTool.GetValByNLua(nLua,vv)
			if(StrTool.IsNullOrEmpty(self.str:ToStr())==false)then
				--self.str:Line()
			end
			self.str:Apd("    [F4DDBDFF]"):Apd(name):Apd("  "):Apd(val)
		end					
	end
	local str=self.str:ToStr()
	if StrTool.IsNullOrEmpty(str)==false then self:CreateLab(str) end
end
--诛仙诛神套装
function My:SuitAtt(suit)
	local gp=nil
	if suit then 
		gp=suit
	else
		if(self.tb==nil)then return end
		gp=self.tb.suitLv
	end	 
	if(gp==nil or gp==0)then return end
	for i=1,gp do
		self:CreateSuit(i)
	end
end

--获取途径描述
function My:GetWayDes()
	local way=self.item.getwayList
	if way then
		self.str:Dispose()
		self.str:Line()
		self.str:Apd("【获得途径】")
		self.str:Line()
		self.str:Apd("[67cc67]")
		for i,v in ipairs(way) do
			local data = GetWayData[tostring(v)]
			if not data then iTrace.eError("xiaoyu","获取表为空 id: "..i)return end
			local text = data.des
			self.str:Apd(text)
			if i~=#way then self.str:Apd("、") end
		end
		self:CreateLab(self.str:ToStr())
	end
end

function My:CreateSuit(gp)
	self.str:Dispose()
	local group=nil
	local title =nil
	if(gp==1)then --诛仙
		group=self.equip.suit1
		title="[e9ac50]【诛仙】"
	elseif(gp==2)then --诛神
		group=self.equip.suit2
		title="[e9ac50]【诛神】"
	end
	if not group then return end
	local suit=EquipSuit[tostring(group)]
	if(suit==nil)then iTrace.Error("Loong", "装备套装表==null group:"..tostring(group).."  id: "..tostring(self.equip.id)) return end
	local num1=suit.num1
	local num2=suit.num2
	local num3=suit.num3
	local max = nil
	if(num3~=nil)then max=num3
	elseif(num2~=nil)then max=num2
	else max=num1 
	end
	local curNum = EquipMgr.GetCurNum(gp,group)
	local ct = StrTool.Concat(title..suit.name.. "[-]   [67cc67]".. curNum.."/".. max)
	self:CreateTitle(ct)
	local att1=suit.att1
	self:SetNA(curNum,num1,att1)

	
	local att2=suit.att2
	self:SetNA(curNum,num2,att2)

	
	local att3=suit.att3
	self:SetNA(curNum,num3,att3)
end

function My:SetNA(curNum,num,att)
	self.str:Dispose()
	if(num~=nil)then
		local color="[67cc67]"
		if(curNum<num)then color="[8a7f72]" end		
		for i,v in ipairs(att) do
			if(StrTool.IsNullOrEmpty(self.str:ToStr())==false)then
				self.str:Line()
			end
			if(i==1)then 
				self.str:Apd(color):Apd("["):Apd(num):Apd("件]")
			end
			local id = v.id
			local val = PropTool.GetValByID(id,v.val)
			local pro=BinTool.Find(PropName,id)
			if(pro==nil)then iTrace.Error("Loong", "属性表==null id:".. id)return end
			self.str:Apd(pro.name):Apd("  +"):Apd(val)
		end
	end
	local tex = self.str:ToStr()
	self:CreateLab(tex)
end

function My:CreateTitle(text)
	return self:Create(text,self.titlePre,19)
end

function My:CreateLab(text)
	self:Create(text,self.labPre,5)
end

function My:CreateNone(state,type,isSeal)
	local trans=self.AttList[#self.AttList].transform
	local go = GameObject.Instantiate(self.nonePre)
	go.transform.parent=trans
	go:SetActive(true)
	go.transform.localScale=Vector3.one
	go.transform.localPosition=Vector3.New(13,-9,0)
	local spr=go:GetComponent(typeof(UISprite))
	local path = 0
	if type then 
		path=type 
		if isSeal then
			path= path+20
		end
	end
	spr.spriteName=EquipColor[path]
	-- local has = TransTool.FindChild(go.transform,"has")
	-- has:SetActive(state)

	self.NoneList[#self.NoneList+1]=go
end

function My:Create(text,pre,lerpY)
	local t = self.AttList

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
	self.AttList[#self.AttList+1]=label
	return go
end

function My:Open()
	self.root.gameObject:SetActive(true)
end

function My:Close()
	self.root.gameObject:SetActive(false)
end

function My:Dispose()
	self:Close()
	if self.cell then
		self.cell:DestroyGo()
		ObjPool.Add(self.cell)
		self.cell=nil
	end
	while(#self.NoneList>0)do
		local non=self.NoneList[#self.NoneList]
		GameObject.Destroy(non)
		self.NoneList[#self.NoneList]=nil
	end
	while(#self.AttList>0)do
		local att = self.AttList[#self.AttList].gameObject
		GameObject.Destroy(att)
		self.AttList[#self.AttList]=nil
	end
	self.panel.clipOffset = Vector2.zero
	self.panel.transform.localPosition = POS
	self.type_id=nil
	self.tb=nil

	if self.timer then
        self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
	end
end

return My