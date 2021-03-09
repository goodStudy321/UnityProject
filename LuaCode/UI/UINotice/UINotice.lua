--[[
公告
--]]
UINotice=UIBase:New{Name="UINotice"}
local My=UINotice

local AssetMgr=Loong.Game.AssetMgr
local show=nil
local panel = nil
local showPre=nil
local playTween=nil
local showGoList={}

local noShow=nil
local noShowLab=nil
local noShowW = nil

local notice = nil
local noticeLab = nil

My.isBegain1=true
My.isBegain2=true
My.isBegain3=true

local list={}

local openList = {}

function My:InitCustom()
	local CG=ComTool.Get
	local TF=TransTool.FindChild

	showGo=TF(self.root,"show")
	panel=TF(showGo.transform,"Panel").transform
	showPre=TF(showGo.transform,"Label")
	showPre:SetActive(false)

	noShowGo=TF(self.root,"noShow")
	noShowLab=CG(UILabel,noShowGo.transform,"Label",self.Name,false)
	noShowWidge=CG(UIWidget,noShowGo.transform,"Label",self.Name,false)
	noShowW=noShowLab.transform:GetComponent(typeof(UIWidget))
	UITool.SetLsnrSelf(noShowLab.gameObject,self.ClickUrl,self,self.Name, false)

	notice=TF(self.root,"notice")
	noticeLab=CG(UILabel,notice.transform,"Label",self.Name,false)

	self.timer=ObjPool.Get(iTimer)
	self.timer.complete:Add(self.Complete,self)
	self.timer2=ObjPool.Get(iTimer)
	self.timer2.complete:Add(self.OnFinsh,self)
	self.timer3=ObjPool.Get(iTimer)
	self.timer3.complete:Add(self.NoticeEnd,self)

	NoticeMgr.eRefresh:Add(self.ChatRefresh,self)
end

--是否能被记录
function My:CanRecords()
	do return false end
end

--持续显示 ，不受配置tOn == 1 影响
function My:ConDisplay()
	do return true end
end

function My:Update()
	self:UpShow()
	self:UpNoShow()
	self:UpNotice()
end

--即时显示消息
function My:ChatRefresh(show,pos,text)
	if show==1 then --showList
		self:Complete(true)
		self:OnEnd(true)
		NoticeMgr.isRefresh=true
		self:UpShow(pos,true)
	else
		self:OnFinsh(true)
		NoticeMgr.isRefresh=true
		self:UpNoShow(pos,true)
	end
end


--跑马灯
function My:UpShow(index,forceUpdate)
	if NoticeMgr.isRefresh==true and (forceUpdate == nil or forceUpdate == false)  then return end
	if not index then index=1 end
	local count = #NoticeMgr.showList
	local tb = nil
	if(count>0 and My.isBegain1==true)then
		tb=NoticeMgr.showList[index]
	end
	if not tb then return end
	My.isBegain1=false
	local new=NoticeMgr.DealTx(tb)
	local go = nil
	if #openList>0 then
		go=openList[1]
		table.remove( openList,index)
	else
		go=GameObject.Instantiate(showPre)
	end
	go.name=tostring(tb.id)
	showGoList[#showGoList+1]=go
	go.transform.parent=panel
	go:SetActive(true)
	go.transform.localScale=Vector3.one
	go.transform.localPosition=Vector3.zero
	local lab=go:GetComponent(typeof(UILabel))
	local widge = go:GetComponent(typeof(UIWidget))
	lab.text=new
	self:ShowModel(showGo.transform,tb.id)
	local tween=go:GetComponent(typeof(UIPlayTween))
	local tweenPos=go:GetComponent(typeof(TweenPosition))
	EventDelegate.Add(tween.onFinished,EventDelegate.Callback(self.OnEnd, self))
	self:NoticeShow(lab,tween,tweenPos)
	showGo:SetActive(true)
	widge:ResizeCollider()
		
	UITool.SetLsnrSelf(go,self.ClickUrl,self,self.Name,false)

	--self.timer:Dispose() --千万记得不要调用Dispose
	--self.timer.seconds=11
	self.timer:Stop()
	self.timer:Start(8)

	local tb = NoticeMgr.showList[index]
    ObjPool.Add(tb)
	table.remove(NoticeMgr.showList,index)

	ChatMgr.SetSys(new,tb.id,false)

	noShowW:ResizeCollider()
end

function My:ShowModel(parent,id)
	local notice = Notice[tostring(id)]
	local model = notice.model
	if not model then return end
	local pos = notice.modelPos or Vector3.zero
	local rota = notice.modelRotate or Vector3.one 
	local del = ObjPool.Get(DelGbj)
	del:Adds(parent,pos,rota)
	del:SetFunc(self.LoadCb,self)
	AssetMgr.LoadPrefab(model,GbjHandler(del.Execute,del))
end

function My:LoadCb(go,parent,pos,rota)
	go.transform.parent=parent  
	go:SetActive(true)
	go.transform.localPosition=pos
	go.transform.localEulerAngles=rota
	go.transform.localScale=Vector3.one*345
	LayerTool.Set(go.transform,23);
	self.model=go
end

function My:Complete()
	My.isBegain1=true
	NoticeMgr.isRefresh=false
	self.timer:Stop()
end

function My:OnEnd(forceUpdate)
	local go = showGoList[1]
	go.transform.parent=nil
	go:SetActive(false)
	openList[#openList+1]=go
	table.remove(showGoList,1)

	if self.model then 
		Destroy(self.model)
		self.model=nil 
	end
	--self:Complete()

	if forceUpdate~=true then self:CloseNotice(1) end
end

--公告
function My:UpNoShow(index, forceUpdate)
	if NoticeMgr.isRefresh==true and (forceUpdate == nil or forceUpdate == false)  then return end
	if not index then self.index2=1 else self.index2=index end
	local count = #NoticeMgr.noShowList
	local tb = nil
	if(count>0 and My.isBegain2==true)then
		tb=NoticeMgr.noShowList[self.index2]
	end
	if not tb then return end
	local new=NoticeMgr.DealTx(tb)
	noShowLab.name=tostring(tb.id)
	noShowLab.text=new
	noShowGo:SetActive(true)
	noShowWidge:ResizeCollider()
	My.isBegain2=false
	self.timer2.text=new
	self.timer2:Stop()
	self.timer2:Start(3)
	

    ObjPool.Add(tb)
	table.remove(NoticeMgr.noShowList,self.index2)

	ChatMgr.SetSys(new,tb.id,false)
end

function My:OnFinsh(forceUpdate)
	self.timer2:Stop()
	NoticeMgr.isRefresh=false
	My.isBegain2=true
	if forceUpdate~=true then self:CloseNotice(0) end
end

--大字广播
function My:UpNotice()
	local count = #NoticeMgr.noticeList
	local tb = nil
	if count>0 and My.isBegain3==true then
		tb=NoticeMgr.noticeList[1]
	end
	if not tb then return end
	My.isBegain3=false
	notice:SetActive(true)
	local msg=NoticeMgr.DealTx(tb)
	noticeLab.text=msg
	self.timer3:Stop()
	self.timer3:Start(3)

	ObjPool.Add(tb)
	table.remove(NoticeMgr.noticeList, 1)
end

function My:NoticeEnd()
	self.timer3:Stop()
	self.isBegain3=true
	if #NoticeMgr.noticeList==0 then
		notice:SetActive(false)
	end
end

function My:CloseNotice(show)
	if show==1 and #NoticeMgr.showList==0 and NoticeMgr.isRefresh==false then
		if panel.childCount==0 then 
			showGo:SetActive(false)
		end
	elseif show==0 and #NoticeMgr.noShowList==0 and NoticeMgr.isRefresh==false then
		noShowGo:SetActive(false)
	end
end

function My:ClickUrl(go)
	local lab = go:GetComponent(typeof(UILabel))
	if lab then
		local url=lab:GetUrlAtPosition(UICamera.lastWorldPosition)
		NoticeMgr.DealUrl(go.name,url)
	end
end



--跑马灯
function My:NoticeShow(lab,tween,tweenPos)
	local x=266 - lab.printedSize.x-530
 	tweenPos.to=Vector3.New(x,0,0)
 	tween.resetOnPlay = true
 	tween:Play(true)
end


function My:CloseCustom()
end

function My:DisposeCustom()
	if self.timer then self.timer:AutoToPool() self.timer=nil end
	if self.timer2 then self.timer2:AutoToPool() self.timer2=nil end
	if self.timer3 then self.timer3:AutoToPool() self.timer3=nil end
end

return My