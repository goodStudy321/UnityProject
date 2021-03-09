--[[
道具tip基类
]]
require("UI/Base/ItemModelPanel")
PropTipBase=Super:New{Name="PropTipBase"}
local My = PropTipBase

function My:InitCustom(go,pos)
    self.root=go.transform
    self.pos=pos
	local CG=ComTool.Get
	local TF = TransTool.FindChild
	
	self.panel=self.root:GetComponent(typeof(UIPanel))
	self.bg=CG(UISprite,self.root,"Bg",self.Name,false)
	local bg = self.bg.transform
	self.cell=ObjPool.Get(Cell)
	self.cell:InitLoadPool(bg.transform,nil,nil,nil,nil,Vector3.New(-107,-58,0))
	
	self.Grid=CG(UIGrid,bg,"Panel/Grid",self.Name,false)
	self.NameLab=CG(UILabel,bg,"Name",self.Name,false)
	self.worth=CG(UILabel,bg,"worth",self.Name,false)
	self.sellLb=CG(UILabel,bg,"sellP",self.Name,false)
	self.Lv=CG(UILabel,bg,"Lv",self.Name,false)
	self.Tp=CG(UILabel,bg,"Tp",self.Name,false)
	self.Des=CG(UILabel,bg,"Panel/Des",self.Name,false)
	self.top=CG(UISprite,bg,"top",self.Name,false)
	self.time = CG(UILabel,bg,"time",self.Name,false)
	self.labWorth = CG(UILabel, bg, "labWorth")
	
	self.BtnGrid=CG(UIGrid,bg,"Btn",self.Name,false)
	self.btn=TF(self.BtnGrid.transform,"Btn")

	BatchUse.eClose:Add(self.OnClose,self)
	if not self.list then self.list={} end
	self.str=ObjPool.Get(StrBuffer)

	self.eClose=Event()

	if not self.Btns then self.Btns={} end
	if not self.dic then self.dic={} end
	UITool.SetLsnrClick(self.root,"Bg/mask",self.Name,self.OnClose,self)
end

function My:UpBgHeight()
	local height=self.Des.height+168
	if height<640 then
		self.bg.height=height
	else
		self.bg.height=640
		local pos=self.root.localPosition
		self.root.localPosition=Vector3.New(pos.x,pos.y+117,pos.z)
	end
end

function My:UpPackCell()
	local uFx=self.item.uFx
	if uFx~=25 and uFx~=45 and uFx~=57 and uFx~=58 then return end
	local id=tostring(self.type_id)
	local gift = GiftData[id]
	if not gift then 
		gift=EquipGift[id]
		if not gift then iTrace.eError("xiaoyu","礼包表、自选礼包装备表都找不到这个配置，请找策划  id: "..id)return end
		local giftList =gift.giftList
		for i,v in ipairs(giftList) do
			local id=v.id
			local num=v.val
			self:AddCell(id,num)
		end
	else
		for i=1,10 do
			local item = gift["item"..i]
			if item then 
				for i1,data in ipairs(item.val) do
					local id=data.i1
					if id~=0 then
						local num = data.i2
						local bind=data.i3
						self:AddCell(id,num,bind)
					end
				end          
			end
		end	
	end 
	self.Grid.transform.localPosition=Vector3.New(0,195-self.Des.height,0)
	self.Grid:Reposition()

	local x,y = math.modf( #self.list/4 )
	x=y>0 and x+1 or x
	local addH = 75*x
	local height = self.bg.height+addH+5
	self.bg.height=height<=614 and height or 614
end

function My:AddCell(id,num,bind)
	local cell = ObjPool.Get(UIItemCell)
	cell:InitLoadPool(self.Grid.transform,0.8)
	cell:UpData(id,num)
	cell:UpBind(bind==1)
	self.list[#self.list+1]=cell
end

function My:OpenUpData()
	local wordPos = self.pos
	if self.ismodel==true or wordPos==nil then self.bg.gameObject:SetActive(true) return end
	self.bg.transform.position=wordPos	
	self:OffSetPos()
end

function My:OffSetPos()
	local vx,vy=nil
	local pos = self.bg.transform.localPosition
	local left = pos.x-203
	local right = pos.x+203
	local top = pos.y+50
	local bottom = pos.y
	local bgWidth = self.bg.width/2
	local bgHeight = self.bg.height

	
	--先上后下
	if top-bgHeight<-346 then --超出下边的区域
		--底对着底
		vy=bottom+bgHeight-52
		if (vy>278) then vy=278 end
	else
		vy=top
	end

	if left<-500 then
		vx=right
	else
		vx=left
	end
	self.bg.transform.localPosition=Vector3.New(vx,vy,0)
	self.bg.gameObject:SetActive(true)
end

function My:ShowBtn(btnList)
	local islimit = self:LimitBtn()
	if islimit==true then 
		self:AddBtn(UIContentY.btnList[3])
	else
		local isWayExit = false
		local isAuction = UIMgr.GetActive(UIAuction.Name) 
		if self.item.getwayList and isAuction == -1 then 
			self:AddBtn(UIContentY.btnList[18])
			isWayExit=true
		end
		local tmpBtn = self:ChangeBtn(btnList);
		if tmpBtn then 
			for i,btnName in ipairs(tmpBtn) do
				if (isWayExit==false and btnName==UIContentY.btnList[18]) or btnName~=UIContentY.btnList[18] then 
					self:AddBtn(btnName)
				end
			end
		end
	end
	self.BtnGrid:Reposition()
end

function My:ChangeBtn(btnList)
	btnList = btnList or {}
	if #btnList == 0 then
		return btnList;
	end
	local MyBtn = {}
	if self.item.uFx == 94 then
		local nowTime = TimeTool.GetServerTimeNow()*0.001;
		local endTime = self.tb.endTime;
		local leftTime = endTime - nowTime;
		if leftTime <= 0 then
			MyBtn[1] = "Sale";
			return MyBtn;
		end
	end
	return btnList;
end

function My:LimitBtn()
	-- 判断限时道具
	if self.tb and self.tb.id then
		if self.tb.id >= 1 and self.tb.id <= 1000 then
			local sec = self.item.AucSecId or 0
			local now =  TimeTool.GetServerTimeNow()*0.001
			if not self.tb.market_end_time then return end
			local endTime = now - self.tb.market_end_time
			if self.tb.market_end_time and self.tb.market_end_time == 0 then
				return false
			end
			if self.item.startPrice and endTime and sec~=0 then
				return self.tb.market_end_time == 1 or endTime>0
			end
		end
	end
end

function My:AddBtn(name)
	local go = GameObject.Instantiate(self.btn)
	go:SetActive(true)
	go.name=name
	go.transform.parent=self.BtnGrid.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale=Vector3.one
	UITool.SetBtnSelf(go,self[name],self,self.Name)
	local lab = ComTool.Get(UILabel,go.transform,"Label",self.Name,false)
	lab.text=UIContentY.btnNameList[name]
	self.Btns[#self.Btns+1]=go
end

--使用
function My:Use()
	local data = ItemData[tostring(self.item.id)]
	if data.uFx==82 then
		SkillMgr:quickUpLv(data,self.tb.id)
		self:OnClose()
		return
	end
	if data.uFx==85 then
		SkillMgr:quickUpLv(data,self.tb.id)
		self:OnClose()
		return
	end
	local endTime = self.tb.market_end_time
	local now =  TimeTool.GetServerTimeNow()*0.001
	-- local now = TimeTool.GetServerTimeNow()*0.001
	if data then
		if data.AucSecId and data.startPrice and endTime  then
			-- local endTime = endTime - now
			if endTime == 0 then
				QuickUseMgr.PropUse(self.item,self.tb.id,self.tb.num,1)
			else
				UIMgr.Open(ShelfTip.Name,self.ShelfTipCB,self)
			end
		else
			QuickUseMgr.PropUse(self.item,self.tb.id,self.tb.num)
		end
	end
	self:OnClose()
end

function My:ShelfTipCB(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpData(self.tb)
	end
end


--出售
function My:Sale()
	if(self.item.price==nil)then UITip.Log("该道具不可出售") return end	
	self.str:Dispose()
	self.str:Apd("你确定要出售"):Apd(self.item.name):Apd("道具吗？")
	self.str:Line()
	self.str:Apd("[00FF00FF](出售可获得"):Apd(self.item.price):Apd("银两)[-][-]")
	local title=self.str:ToStr()		
	MsgBox.ShowYesNo(title,self.SaleCb,self)	
	self:OnClose()			
end

function My:SaleCb(name)
	TableTool.ClearDic(self.dic)
	if not self.deal then
		self.deal = ObjPool.Get(Deal)
	end
	self.deal:PanelState(true)
	--self.dic[tostring(self.tb.id)]=self.tb.num
	--PropMgr.ReqSell(self.dic)
end

--合成
function My:Compound()
	UICompound:SwitchTg(1,nil,self.tb.type_id)
	self:OnClose()
end

--镶嵌
function My:Inset()
	EquipMgr.OpenEquip(3)
	self:OnClose()
end

--镶嵌纹印
function My:sealInsert()
	EquipMgr.OpenEquip(5)
	self:OnClose()
end

--兑换
function My:Exchange()
	 --// LY add begin
	 if self.tb ~= nil and self.tb.id ~= nil then
	 	FamilyMgr:ReqFamilyExcDepot(self.tb.id, 1);
	 else
	 	iTrace.Error("LY", "Exchange error !!! ");
	 end
	 --// LY add end
end

--取出
function My:GetOut()
	local tp,dic=PropMgr.GetTp(self.tb.id)
	PropMgr.ReqDepot(tp,1,self.tb.id)
	self:OnClose()
end

--放入
function My:PutIn()
	local tp,dic=PropMgr.GetTp(self.tb.id)
	PropMgr.ReqDepot(1,2,self.tb.id)
	self:OnClose()
end

-- 选取（神秘宝藏用）
function My:Choose()
	self:OnClose()
	TreaFeverMgr:OnChoose()
end

-- 取消选取（神秘宝藏用）
function My:EseChoose()
	TreaFeverMgr:EseChoose()
	self:OnClose()
end

--// 上架
-- function My:PutAway()
-- 	if MarketMgr:OnShelfBuyGoodsNum() > 10 then
-- 		UITip.Error("最大上架数量为10");
-- 		return;
-- 	end

-- 	local maxNum = 1;
-- 	if PropMgr.tbDic ~= nil then
-- 		local tbData = PropMgr.tbDic[tostring(self.tb.id)];
-- 		if tbData ~= nil then
-- 			maxNum = tbData.num;
-- 		end
-- 	end
	

-- 	PropSale.limitNum = maxNum;
-- 	PropSale.limitPrice = 999999;
-- 	UIMgr.Open(PropSale.Name,self.PutCb,self)
-- 	self:OnClose()
-- end

function My:PutCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		if self.item.time then
			ui:ShowWidge(true)
		else
			ui:ShowWidge(false)
		end
		ui:UpData(self.item,self.tb)
	end
end

--获取途径
function My:GetWay()
	GetWayFunc.ItemGetWay(self.type_id)
end


--传入参数为tb或者type_id
function My:UpData(obj)
	if(type(obj)=="table")then 
		self.tb=obj
		PropMgr.SetPropTb(self.tb)
		self.type_id=tostring(self.tb.type_id)
		self.gotTime = obj.market_end_time
	elseif(type(obj)=="string")then
		self.type_id=obj
	else
		self.type_id=tostring(obj)
	end
	self.item=UIMisc.FindCreate(self.type_id)
	if(self.item==nil)then iTrace.eError("xiaoyu","道具表为空 type_id: "..self.type_id)return end
	self.cell:UpData(self.item)
	self.cell:UpBind(self.isBind)
	self:ShowName()
	self:ShowLv()
	self:ShowTp()
	self:ShowDes()
	self:ShowWorth()
	self:ShowTop()
	self:ShowSellP()
	self:ShowWhetherLimit()
	self:ShowModel()
	self:ShowlimTime()
	self:ShowItemLimitTime()

	self:UpBgHeight()
	self:UpPackCell()
	self:OpenUpData()
	if tonumber(self.type_id) == 700003 then
		self.labWorth.gameObject:SetActive(true)
		self.labWorth.transform.localPosition = Vector3.New(self.Des.transform.localPosition.x, -(self.bg.height - 30), 0)
		local worth = ItemData[tostring(self.type_id)].worth
		local cost = ItemData[tostring(self.type_id)].cost
		if PropTip.isInWarehouse then
			self.labWorth.text = "[F4DDBDFF]兑换积分：[-][ffe9bd]"..cost
		else
			self.labWorth.text = "[F4DDBDFF]仓库积分：[-][ffe9bd]"..worth
		end
	else
		self.labWorth.gameObject:SetActive(false)
	end
end

function My:ShowLv()
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
	self.Lv.text=color..result
end

function My:ShowTp()
	self.Tp.text="[cccccc]类型[-]  [67cc67]"..UIMisc.GetType(self.item.type)
end

function My:ShowDes()
	self.str:Dispose()
	local uFx = self.item.uFx or 0
	local itemDes = self.item.des or ""
	if uFx==40 and self.item.uFxArg[1]~=nil then --经验丹
		local lv = User.instance.MapData.Level
		local lvLimit = self.item.uFxArg[2] or 0
		if lvLimit>0 and User.instance.MapData.Level>lvLimit then lv=lvLimit end 
		local ratio = self.item.uFxArg[1]/10000
		local sss=tostring(PropTool.LvGetExp(ratio,lv))
		local text=string.gsub( itemDes,"#",sss)	
		self.str:Apd(text)	
	elseif uFx==57 or uFx==58 or uFx==92 then
		local time=PropMgr.TimeDic[tostring(uFx)]
		if time then
			local StrUse = "今日开启次数："
			local gid = nil
			if uFx==57 then
				gid="84"
			elseif uFx==58 then
				gid="85"
			elseif uFx==92 then
				gid="174"
				StrUse="今日使用次数："
			end
			local global = GlobalTemp[gid]
			if not global then iTrace.eError("xiaoyu","global表为空 id: "..gid)return end
			self.str:Apd(itemDes):Apd("\n"):Apd(StrUse):Apd(time):Apd("/"):Apd(global.Value3)
		end
	else
		self:AddAttDes(uFx,self.type_id,itemDes)
	end
	self:GetWayDes()
	self.Des.text=self.str:ToStr()
end

--属性描述
function My:AddAttDes(uFx,type_id,itemDes)
	self.str:Dispose()
	local id=tonumber(type_id)
	local temp = nil
	if uFx==31 then --宝石
		temp=GemData[type_id]
	elseif uFx==77 then --纹印
		temp=tSealData[type_id]
	elseif uFx==60 then --神兽装备
		temp=SBEquipCfg[type_id]
	elseif uFx==8 then --坐骑时装 
		temp=BinTool.Find(MountChangeLvCfg,id)
	elseif uFx==12 then --宠物时装 
		temp=BinTool.Find(PetChangeLvCfg,id)
	elseif uFx==9 then --法宝时装 
		temp=BinTool.KeyFind(MWSkinCfg,id,"acPropId")
	elseif uFx==10 then --神兵时装 
		temp=BinTool.Find(GWSkinCfg,id)
	elseif uFx==11 then --翅膀时装 
		temp=BinTool.Find(WingSkinCfg,id)
	elseif uFx==41 then --时装 
		temp=FashionAdvCfg[type_id]
	elseif uFx==38 then --称号
		temp=TitleCfg[tostring(self.item.uFxArg[1])]
	elseif uFx==96 then --宝座皮肤 
		temp=BinTool.Find(ThroneChangeLvCfg,id)
	elseif uFx==20 then --符文 
		temp=BinTool.Find(RuneLvCfg,id)
	elseif uFx==89 then --丹药
		temp=ElixirCfg[type_id]
	end
	if temp then
		if uFx==20 then
			local p1 = temp.p1
			local v1 = temp.v1
			local p2 = temp.p2
			local v2 = temp.v2
			local maxTemp = nil
			if temp.lv==1 then 
				maxTemp=BinTool.Find(RuneLvCfg,tonumber(temp.maxId))
			end
			if v1 then 
				self:GetAtt(p1,v1,temp,maxTemp)
			end
			if v2 then 
				self:GetAtt(p2,v2,temp,maxTemp)
			end
		elseif uFx==89 then
			for i=1, ElixirMgr.maxProCount do
				local proList = temp["pro"..i]
				if #proList > 0 then
					local id = proList[1]
					local v = PropTool.GetNameById(id)
					local val = PropTool.GetValByID(id,proList[2] )
					self.str:Apd(v):Apd("+"):Apd(val)
					local name = PropName[id]
					if name.show==1 then self.str:Apd("%")end
					self.str:Apd("\n")
				end
			end
		else
			for i,pro in ipairs(PropName) do
				local v=pro.nLua
				if v then 
					local val = temp[v] or 0
					if val~=0 then
						local vName = PropTool.GetName(v)
						local vVal = PropTool.GetValByNLua(v,val)
						self.str:Apd(vName):Apd("+"):Apd(vVal)
						local name = PropTool.Get(v)
						if name.show==1 then self.str:Apd("%")end
						self.str:Apd("\n")
					end
				end
			end
			
		end
	end
	local text = self.str:ToStr()
	local newText = string.gsub( itemDes,"#",text)
	self.str:Dispose()
	self.str:Apd(newText)
end

function My:GetAtt(id,val,temp,maxTemp)
	self.str:Apd(PropTool.GetNameById(id)):Apd("  "):Apd(PropTool.GetValByID(id,val))
	local name = PropName[id]
	if name.show==1 then self.str:Apd("%")end
	if maxTemp and maxTemp.v1 and temp.lv==1 then 
		self.str:Apd("(满级效果 "):Apd(PropTool.GetValByID(maxTemp.p1,maxTemp.v1))
		local name1 = PropName[maxTemp.p1]
		if name1.show==1 then self.str:Apd("%")end
		self.str:Apd(")") 
	end
	self.str:Line()
end


--获取途径描述
function My:GetWayDes()
	local way=self.item.getwayList
	if way then
		self.str:Line():Line()
		self.str:Apd("【获得途径】")
		self.str:Line()
		self.str:Apd("[67cc67]")
		for i,v in ipairs(way) do
			local data = GetWayData[tostring(v)]
			if not data then iTrace.eError("xiaoyu","获取表为空 id: "..v)return end
			local text = data.des
			self.str:Apd(text)
			if i~=#way then self.str:Apd("、") end
		end
	end
end

function My:ShowWorth()
	if self.item.id==30360 then
		local g = GlobalTemp["13"]
		self.str:Line()
		self.str:Apd("[-]仓库积分：[ffe9bd]"):Apd(g.Value3)
		self.Des.text=self.str:ToStr()
	end
end

function My:ShowSellP()
	if self.item.price then
		self.str:Line()
		self.str:Apd("[-]售价：[00FF00]"):Apd(self.item.price)
		self.Des.text=self.str:ToStr()
	end
end

--有效期
function My:ShowWhetherLimit()
	if self.item.limitTime or self.item.uFx == 95 then
		self.str:Line()
		self.str:Apd("[-][67cc67]")
		local day,hour,min,seconds = self:GetDated()
		if day==0 and hour==0 and min==0 and seconds==0  then
			self.str:Apd("【已过期】")
		else
			self.str:Apd("【有效期：")
			if day~=0 then 
				self.str:Apd(day):Apd("天")
			end
			if hour then 
				self.str:Apd(hour):Apd("小时")
			end
			if min then
				self.str:Apd(min):Apd("分")
			end
			self.str:Apd("】")
		end
		self.Des.text=self.str:ToStr()
	end
end

function My:GetDated()
	local day,hour,min,seconds=0,0,0,0
	local time=nil
	if self.tb and self.tb.startTime~=0 then
		local now=TimeTool.GetServerTimeNow()*0.001
		local lerp=self.tb.endTime-now
		if lerp>0 then time=lerp else return 0,0,0,0 end
	else
		if self.item.uFx == 95 then
			time = self.item.uFxArg[1]
		else
			time=self.item.limitTime
		end
	end
	day,hour=DateTool.GetDay(time)
	if hour~=0 then hour,min=DateTool.GetHour(hour) end
	if min~=0 then min,seconds=DateTool.GetMinu(min) end
	return day,hour,min,seconds
end

--显示物品限时实时时间
function My:ShowItemLimitTime()
	local limitTime = self.item.limitTime;
	if limitTime == nil then
		return;
	end
	if self.tb == nil then
		return;
	end
	local endTime = self.tb.endTime;
	if endTime == nil then
		return;
	end
	local nowTime = TimeTool.GetServerTimeNow()*0.001;
	local leftTime = endTime - nowTime;
	if leftTime <= 0 then
		return;
	end
	if not self.timer then
		self.timer = ObjPool.Get(DateTimer);
		self.timer.invlCb:Add(self.LimitInvlCb, self);
		self.timer.complete:Add(self.LimitComplete, self);
		self.timer.fmtOp = 0;
	end
	self.timer:Stop();
	self.timer.seconds = leftTime;
	self.timer:Start();
	self:LimitInvlCb();
	self.time.gameObject:SetActive(true);
end

--限时时间间隔回调
function My:LimitInvlCb()
	if self.time then
		local text = "【剩余时间："..self.timer.remain.."】";
		self.time.text = text;
	end
end

--限时时间完成回调
function My:LimitComplete()
	self.time.gameObject:SetActive(false);
	self:ShowWhetherLimit();
end

function My:ShowlimTime()
	--// 不可上架显示
	local gotTime = self.gotTime
	local value = false
	local nowTime = TimeTool.GetServerTimeNow()*0.001
	if self.item and self.item.auctionTime and gotTime then
		local time = self.item.time
		local endTime = gotTime - nowTime
		if gotTime ~= 1 and gotTime > 0 then
			if nowTime - gotTime <= 0 then
				if not self.timer then
					self.timer = ObjPool.Get(DateTimer)
				end
				self.timer:Stop()
				self.timer.invlCb:Add(self.InvlCb, self)
				self.timer.complete:Add(self.CompleteCb, self)
				self.timer.seconds = endTime
				self.timer.fmtOp = 0
				self.timer:Start()
				self:InvlCb()
				value = true
				self.cell:ShowLimit(gotTime)
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

function My:CompleteCb()
	self.time.gameObject:SetActive(false)
	self.cell:ShowLimit(self.gotTime)
end

function My:ShowTop()
	self.top.spriteName="cell_a0"..self.item.quality
end

--设置外观类模型
function My:ShowModel()
	local istrue=UIItemModel.IsTrue(self.type_id)
	if istrue==true then
		local pos=self.bg.transform.localPosition
		UIItemModel.pos=pos+Vector3(-367,-228,0)
		UIMgr.Open(UIItemModel.Name)
	end
	self.ismodel=istrue
end

function My:ShowName()
	local col=UIMisc.LabColor(self.item.quality)
	self.NameLab.text=col..self.item.name
end

function My:OnClose()
	self.eClose()
end

function My:Dispose()
	while #self.list>0 do
		local cell=self.list[#self.list]
		cell:DestroyGo() 
		ObjPool.Add(cell)
		self.list[#self.list]=nil
	end
	self.pos=nil
	My.width=nil
	BatchUse.eClose:Remove(self.OnClose,self)
	if self.cell then self.cell:DestroyGo() ObjPool.Add(self.cell) self.cell=nil end
	local ui = UIMgr.Get(UIItemModel.Name)
	if ui then 
		ui:Close()
	end
	self.item=nil
	self.tb=nil
	self.type_id=nil
	ListTool.Clear(self.Btns)
	if self.timer then
        self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
	end
	if self.str then ObjPool.Get(self.str) self.str=nil end
	Destroy(self.root.gameObject)
end