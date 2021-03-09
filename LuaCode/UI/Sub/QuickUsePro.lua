--[[
快速使用
--]]
local AssetMgr = Loong.Game.AssetMgr
QuickUsePro = UIBase:New{Name = "QuickUsePro"}
local My = QuickUsePro
My.eDispose=Event()
My.eClose = Event()
My.eOnClick=Event()
function My:InitCustom()
	local TF = TransTool.FindChild
	local CG = ComTool.Get
	self.C=TF(self.root,"C").transform
	-- self.findUI=TF(self.C,"findUI")
	self.cell=ObjPool.Get(Cell)
	self.cell:InitLoadPool(self.C,nil,nil,nil,nil,Vector3.New(0,58,0))
	-- self.cellGo = self.cell.trans.gameObject
	self.NameLab = CG(UILabel, self.C, "NameLab", self.Name, false)
	self.TimeLab = CG(UISlider, self.C, "TimeLab", self.Name, false)
	self.des=CG(UILabel,self.C,"des",self.Name,false)

	UITool.SetLsnrClick(self.C,"CloseBtn",self.Name,self.OnClick,self)
	self.btnLab=CG(UILabel,self.C,"Button/Label",self.Name,false)
	UITool.SetLsnrClick(self.C,"Button",self.Name,self.OnClickBtn,self)

	self.timer=ObjPool.Get(iTimer)
	self.timer.interval=0.1
	self.timer.invlCb:Add(self.OnTimeLab,self)
	self.timer.complete:Add(self.Cb,self)
end

function My:OpenCustom()
	if self.TimeLab~=nil then 
		self.TimeLab.value=1
	end
end

--是否能被记录
function My:CanRecords()
	do return false end
end

--持续显示 ，不受配置tOn == 1 影响
function My:ConDisplay()
	do return true end
end

function My:OnTimeLab()
	self.TimeLab.value=(1/self.timer.seconds)*self.timer:GetRestTime()
end

function My:Cb()
	if not self.isbuy and self.isDirUse~=false then self:DealUse() end
	self:Close()
	self:CleanData()
	My.eDispose()
end

function My:SNameLab(text)
	if text then
		self.NameLab.text=text
	else
		local color = UIMisc.LabColor(self.item.quality)
		self.NameLab.text=color..self.item.name
	end
end

function My:SetEvent(fn)
    SceneMgr.eChangeEndEvent[fn](SceneMgr.eChangeEndEvent,self.UpSprite,self)
end

function My:UpSprite()
	self:Open()
	self.cell:UpIcon(self.item,true)
end

--协议事件
function My:UpData(type_id,num,id,time,btnName,text,des,isDirUse)
	--EventMgr.Add("StartPlayAnim",EventHandler(self.Cb,self))
	self:SetEvent("Add")

	QuickUseMgr.isBegin=false
	if not time then self.time=10 else self.time=time end
	if not des then des="" end
	self.item=UIMisc.FindCreate(type_id)
	self.num=num
	self.id=id
	self.isDirUse=isDirUse
	-- self:setStatus( true )
	self.cell:UpData(self.item,self.num)
	self:SNameLab(text)
	self:UpBtn(btnName)
	self.des.text=des

	local tb=PropMgr.tbDic[tostring(id)]
	if tb then
		self.cell:ShowLimit(tb.market_end_time)
	end
	self.cell:UpBind(false)
	self.timer.seconds=self.time
	self.timer:Start()
end

function My:UpdateFindBack(type_id,num, name,btnname,cb,obj  )
	self:SetEvent("Add")

	QuickUseMgr.isBegin=false
	self.time=10 
	-- self:setStatus( false )
	self.num=num
	self.item=UIMisc.FindCreate(type_id)
	self.btnLab.text =btnname
	self.NameLab.text=name
	self.cell:UpData(self.item,self.num)
	self.cbOnclick=cb
	self.cbOnclickObj=obj
	My.eOnClick:Add(self.cbOnclick,self.cbOnclickObj)
	self.timer.seconds=self.time
	self.timer:Start()
end

-- function My:setStatus( status )
-- 	self.cellGo:SetActive(status)
-- 	self.findUI:SetActive(not status);
-- end

function My:UpBtn(text)
	if text then self.btnLab.text=text return end
	local uFx = self.item.uFx
	if uFx==1 or uFx==28 then
		self.btnLab.text="装备"
	else
		self.btnLab.text="使用"
	end
end

function My:OnClick(go)
	if User.instance.MapData.Level<60 then
		self:DealUse()
	else
		My.eClose(self.item.id)
	end

	self:Close()
	self:CleanData()
	My.eDispose()
end

function My:OnClickBtn()
	My.eOnClick();
	self:DealUse()
	self:Close()
	self:CleanData()
	My.eDispose()
end

--处理离线挂机卡
function My:DealUse()
	JumpMgr:Clear()
	if self.btnLab.text=="购买" then
		StoreMgr.OpenStoreId(31010)
		return 
	end
	if self.btnLab.text=="查看" then
		self:CheckInfo()
		return 
	end
	if self.btnLab.text=="前往" then
		return 
	end
	local uFx = self.item.uFx
	local jump = self.item.jump
	if jump and CutscenePlayMgr.instance.IsPlaying == true then return end
	if uFx==1 then
		QuickUseMgr.PropUse(self.item,self.id,1)
	elseif uFx==82 then --技能书
		SkillMgr:ReqSkillUp(self.item.skillBaseId[1])
		--SkillMgr:quickUpLv(self.item,self.id)
	elseif uFx==85 then --铭文
		SkillMgr:quickUpLv(self.item,self.id)
	else
		local num = PropMgr.TypeIdByNum(self.item.id)
		if num==0 then return end
		self.num=num<self.num and num or self.num
		QuickUseMgr.PropUse(self.item,self.id,self.num)
	end
end

--离线挂机卡时间判定
function My:LineTime(des)
	self.time=10
	local num = PropMgr.TypeIdByNum(31010) or 0
	self:UpData("31010")
	if num<=0 then 
		self.isbuy=true
		self:UpBtn("购买")
	else
		self.isbuy=false
	end
	self.des.text=des
end

--查看守护续费
function My:CheckInfo()
	GuardMgr.Renewal(self.item.id)
end

function My:CleanData()
	self:SetEvent("Remove")
	My.eOnClick:Clear()
	self.time=10
	self.des.text=""
	self.isbuy=nil
	self.isrenew=nil
	QuickUseMgr.isBegin=true
	if self.timer then self.timer:Stop() end
	--EventMgr.Remove("StartPlayAnim",EventHandler(self.Cb,self))
	-- if self.cbOnclick~=nil then
	-- 	My.eOnClick:Remove(self.cbOnclick,self.cbOnclickObj)
	-- end
	-- if(self.cell~=nil)then self.cell:DestroyGo() ObjPool.Add(self.cell) end
end

function My:DisposeCustom( ... )
	
end

return My