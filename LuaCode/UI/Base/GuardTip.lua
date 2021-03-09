--[[
守护系统Tip
--]]
GuardTip=UIBase:New{Name="GuardTip"}
local My=GuardTip
local Btns={}
local bDic = {}
local attStr =ObjPool.Get(StrBuffer)

function My:InitCustom()
	local CG=ComTool.Get
	local TF=TransTool.FindChild

	--EquipCell
	self.cell=ObjPool.Get(Cell)
	self.cell:InitLoadPool(self.root,nil,nil,nil,nil,Vector3.New(195,252,0))

	self.bg=CG(UISprite,self.root,"bg/tp",self.Name,false)
	self.EquipTitle=TF(self.root,"EquipTitle")
	self.AttLab=CG(UILabel,self.root,"Att/lab",self.Name,false)
	self.NameLab=CG(UILabel,self.root,"Name",self.Name,false)
	self.Work=CG(UILabel,self.root,"Work",self.Name,false)
	self.Part=CG(UILabel,self.root,"Part",self.Name,false)
	self.Fight=CG(UILabel,self.root,"Fight",self.Name,false)
	self.AllFight=CG(UILabel,self.root,"AllFight",self.Name,false)
	self.Time=CG(UILabel,self.root,"Time",self.Name,false)
	self.Des=CG(UILabel,self.root,"Des/lab",self.Name,false)
	self.Price=CG(UILabel,self.root,"Price/lab",self.Name,false)

	--操作按钮
	self.Btn=CG(UIGrid,self.root,"Btn",self.Name,false)

	UITool.SetLsnrClick(self.root,"Mask",self.Name,self.Close,self)
end

function My:ShowBtn(btnList)
	if(btnList==nil)then return end
	for i,btnName in ipairs(btnList) do
		local btn = TransTool.FindChild(self.Btn.transform,btnName)
		btn:SetActive(true)
		local func=self[btnName]
		if not func then iTrace.eError("xiaoyu"," btnName: "..btnName) return end
		UITool.SetBtnSelf(btn,self[btnName],self,self.Name)
		Btns[#Btns+1]=btn
	end
	self.Btn:Reposition()
end

--取出
function My:GetOut()
	local tp,dic=PropMgr.GetTp(self.tb.id)
	PropMgr.ReqDepot(tp,1,self.tb.id)
	self:Close()
end

--放入
function My:PutIn()
	local tp,dic=PropMgr.GetTp(self.tb.id)
	PropMgr.ReqDepot(1,2,self.tb.id)
	self:Close()
end

--续费
function My:Renew()
	GuardMgr.Renewal(self.item.id)
	self:Close()
end

--装备
function My:Equip()
	if(self.item.canUse==1)then
		local useLv = self.item.useLevel or 1
		if(User.MapData.Level<useLv)then
			UITip.Log("等级不足，无法穿戴")
			return
		end
		PropMgr.ReqUse(self.tb.id,1)
	else
		UITip.Log("不能穿戴")
	end
	self:Close()
end

--出售
function My:Sale()
	if(self.item.price==nil)then UITip.Log("该装备不可出售") return end	
	attStr:Dispose()
	attStr:Apd("出售"):Apd(self.item.name):Apd("将获得"):Apd(self.item.price):Apd("银两，是否确认出售？")			
	MsgBox.ShowYesNo(attStr:ToStr(), self.SaleCb,self)			
	self:Close()
end

function My:SaleCb()
	TableTool.ClearDic(bDic)
	bDic[tostring(self.tb.id)]=self.tb.num
	PropMgr.ReqSell(bDic)
end

--购买
function My:Buy()
	--StoreMgr.TypeIdBuy(self.type_id)		
	GuardMgr.Renewal(self.item.id)	
	self:Close()
end

--获取途径
function My:GetWay()
	GetWayFunc.ItemGetWay(self.type_id)
end

function My:UpData(obj)
	self.tb=nil
	if(type(obj)=="table")then 
		self.tb=obj  
		self.type_id=tostring(self.tb.type_id )
	elseif(type(obj)=="string")then
		self.type_id=obj
	else
		self.type_id=tostring(obj)
	end
	self.item=ItemData[self.type_id]	
	if(self.item==nil)then iTrace.eError("xiaoyu","道具表为空 id: "..self.type_id)return end
	self.deco=Decoration[self.type_id]
	if(self.deco==nil)then iTrace.eError("xiaoyu","饰品表为空 id: "..self.type_id)return end
	self.cell:UpData(self.item)
	self.bg.spriteName="cell_a0"..self.item.quality

	self:UpAtt()
	self:UpName()
	self:UpWork()
	self:UpPart()
	self:UpFight()
	self:UpTime()
	self:UpDes()
	self:UpPrice()
	self:GetWayDes()
	self:ShowModel()
end

--设置外观类模型
function My:ShowModel()
	local istrue=UIItemModel.IsTrue(self.type_id)
	if istrue==true then
		UIItemModel.pos=Vector3.New(-65.8,-23,0)
		UIMgr.Open(UIItemModel.Name)
	end
end

function My:UpAtt()
	attStr:Dispose()
	local list = self.deco.att
	for i,v in ipairs(list) do
		local name = PropTool.GetNameById(v.id)
		local val = PropTool.GetValByID(v.id,v.val)
		if StrTool.IsNullOrEmpty(attStr:ToStr())==false then attStr:Line() end
		attStr:Apd(name):Apd("："):Apd(val)
	end
	local text = attStr:ToStr()
	self.AttLab.text=text
end

function My:UpName()
	attStr:Dispose()
	local col=UIMisc.LabColor(self.item.quality)
	attStr:Apd(col):Apd(self.item.name)
	if(self.tb~=nil and self.tb.lv~=nil and self.tb.lv~=0)then
		attStr:Apd(" + "):Apd(self.tb.lv)
	end
	self.NameLab.text=attStr:ToStr()
end

function My:UpWork()
	local color = "[67CC67]"
	local w =nil 
	local uw=User.instance.MapData.Category
	local cate=self.item.cateLim
	local gil=self.item.gilgulLv or 0		
	if gil ==0 then --没有转生等级	
		w= UIMisc.GetWork(cate)		
		if(uw~=cate)then
			color=UIMisc.LabColor(5)
		end
	else --有转生等级
		if cate==1 then
			w=UIMisc.GetSex1(gil)
		else
			w=UIMisc.GetSex2(gil)
		end
		if(RebirthMsg.RbLev<gil or cate~=uw)then
			color=UIMisc.LabColor(5)
		end	
	end	
	self.Work.text="[cccccc]职业：[-]"..color..w
end

function My:UpPart()
	local part = UIMisc.WearParts(self.deco.part)
	--local rank = UIMisc.GetStepStr(self.deco.rank)
	self.Part.text="[cccccc]部位：[-]"..part
end

function My:UpFight()
	self.Fight.text="[cccccc]装备评分  [67cc67]"..tostring(self.deco.fight)
	self.AllFight.text="[cccccc]综合评分  [67cc67]"..tostring(self.deco.fight)
end

function My:UpTime()
	if not self.tb or (self.tb and self.tb.startTime==self.tb.endTime) then
		self.Time.text=""
		return 
	end
	local endTime=self.tb.endTime 
	local now = TimeTool.GetServerTimeNow()*0.001
	local lerp=endTime-now
	if lerp<=0 then self.Time.text="[f21919]已过期"
	else
		local day,hour = math.modf(lerp/24/3600)
		if day==0 then
			local hh=math.ceil(hour*24)
			self.Time.text="【".. hh.."小时】后过期"
			return 
		end
		if hour>0 then day=day+1 end
		self.Time.text="【".. day.."天】后过期"
	end
end

function My:UpDes()
	attStr:Dispose()
	attStr:Apd(self.item.des)
	self:GetWayDes()
	self.Des.text=attStr:ToStr()
end

function My:UpPrice()
	local text = self.item.price or ""
	self.Price.text=tostring(text)
	local parent = self.Price.transform.parent.gameObject
	if StrTool.IsNullOrEmpty(text) then 
		parent:SetActive(false) 
	else 
		parent:SetActive(true) 
	end
end

--获取途径描述
function My:GetWayDes()
	local way=self.item.getwayList
	if way then
		attStr:Line():Line()
		attStr:Apd("【获得途径】")
		attStr:Line()
		attStr:Apd("[67cc67]")
		for i,v in ipairs(way) do
			local data = GetWayData[tostring(v)]
			if not data then iTrace.eError("xiaoyu","获取表为空 id: "..v)return end
			local text = data.des
			attStr:Apd(text)
			if i~=#way then attStr:Apd("、") end
		end
	end
end

function My:DisposeCustom()
	if self.cell then self.cell:DestroyGo() ObjPool.Add(self.cell) self.cell=nil end
	local ui = UIMgr.Get(UIItemModel.Name)
	if ui then 
		ui:Close()
	end
end

return My