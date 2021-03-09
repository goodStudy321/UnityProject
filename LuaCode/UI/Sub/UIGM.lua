UIGM=UIBase:New{Name="UIGM"}
local My = UIGM
local GM = GMTemp
require("UI/Sub/gmItem")
local GMIN =GMManager.instance
--自定义打开检查
-- function My:Check()
-- 	if GMIN.IsGm==true then
-- 		return true;
-- 	else
-- 		return false;
-- 	end
-- end

My.GMid=1

function UIGM:InitCustom()
	self.mInput= ComTool.Get(UIInput,self.root,"Input",self.Name,false)
	self.mBg=TransTool.FindChild(self.root, "transBg")
	self.mBg:SetActive(false)
	self.mInput.label.maxLineCount = 1
	self.ConfirmBtn=TransTool.FindChild(self.root, "ConfirmBtn")
	UIEventListener.Get(self.mBg).onClick=function(gameObject) self:OnClickHandler(gameObject) end
	UIEventListener.Get(self.ConfirmBtn).onClick=function(gameObject) self:OnClickHandler(gameObject) end
	--soon的gm
	local TF = TransTool.FindChild
	local CG = ComTool.Get
	local soonRt = TF(self.root,"soon").transform    
	local UC = UITool.SetLsnrClick;
	UC(soonRt, "close", name, self.Close, self);
	self.num1Value=10000
	self.chooseGm = CG(UIButton,soonRt,"choosegm")
	self.chooseInfo=CG(UILabel,soonRt,"choosegm/info")
	self.num1=CG(UIInput,soonRt,"num1")
	self.find=CG(UIButton,soonRt,"find")
	self.num2=CG(UIInput,soonRt,"num2")
	self.sview=CG(UIScrollView,soonRt,"sv")
	self.sv=self.sview.gameObject
	self.Grid=CG(UIGrid,soonRt,"sv/Grid")
	self.choose=TF(soonRt,"sv/Grid/choose")
	self.go=self.choose.gameObject
	self.go:SetActive(false)
	local USBC = UITool.SetBtnClick
	USBC(soonRt, "yesBtn", des, self.soonSend, self)
	self.sv:SetActive(false)
	self:AddEvent()
	self:showChoose()
	self.root.gameObject:SetActive(false)	
end

function My:showChoose(id,name,num)
	if num == nil then
		self.chooseInfo.text=GM[self.GMid].name		
	elseif num==0 then
		self.GMid=id
		self.chooseInfo.text=name
	elseif num==1 then
		self.num1Value=id
		self.num1.value=id
	end
end
--监听
function My:AddEvent( )
	local E = UITool.SetBtnSelf
	if self.find then	
		E(self.find, self.findCell,self)
	end
	if self.chooseGm then	
		E(self.chooseGm, self.gmCell,self)
	end
end
--加载格子
function My:gmCell(  )
	if self.items~=nil then
		return
	end
	self.items={}
	self.sv:SetActive(false)
	for i=1,#GM do
		local v = GM[i]
		self:Creat(v.id,v.name,0)
	end
	self.sv:SetActive(true)	
	self.Grid:Reposition()
	self.sview:ResetPosition()
end
--寻找格子
function My:findCell( )
	if self.items~=nil then
		return
	end
	self.items={}
	self.sv:SetActive(false)
	local nStr = tostring(self.num1.value)
	local Creatlist = {}
	local name = GM[self.GMid].name
	if name=="获得道具"  then
		if nStr=="" then
			iTrace.Error("ll","道具太多拒绝全部加载，请输入关键字")
			return
		end
		Creatlist=ItemData
	end
	if name =="开启活动" or name=="关闭活动" then
		Creatlist=ActiveInfo
	end
	local str="q"
	if nStr ~="" then
		 str =nStr
	end
	self:NameFind(Creatlist,str)
	self.sv:SetActive(true)	
	self.Grid:Reposition()
	self.sview:ResetPosition()	
end
--匹配搜索
function My:NameFind( dic ,str)
	local Dic = {}
	for k,v in pairs(dic) do
		if str=="q" then
			Dic[v.id]=v.name
			self:Creat(v.id,v.name,1)
		else
			local b = string.find(v.name,str)
			if b ~= nil then
				Dic[v.id]=v.name
				self:Creat(v.id,v.name,1)
			end
		end	
	end
end
--0事gm，1事参数1
function My:Creat(k,v,num)
	local go = UnityEngine.GameObject.Instantiate(self.go)
	go:SetActive(true)
    local t = go.transform    
    t.parent = self.Grid.transform
    t.localScale = Vector3.one
    t.localPosition = Vector3.zero
	local cell = ObjPool.Get(gmItem)
	cell:init(go,k,v,num)
    table.insert(self.items, cell)
end
--发送数据
function My:soonSend( )
	if self.GMid == 44 then
		local str1 = self.num1.value
		local str2 = self.num2.value
		self:FindObj(str1,str2)
		return
	end
	local str = GM[self.GMid].gm
	local b = string.find(str,",")
	local str2 = self.num1.value
	if  GM[self.GMid].name=="输出日志" then
		if App.IsDebug==false then
			return;
		end
	 local b = 	User.instance.EnableLog;
	 User.instance.EnableLog = not b;
	 return;
	end
	if  GM[self.GMid].name=="五行设置" then
		for i=1,5 do
			local str4 = str..","..tostring(70+i)..";"..str2
				GMIN:OnSubmitText(str4)
		end
	 return;
	end 
	if StrTool.IsNullOrEmpty(self.num2.value)~=true then
		str2=str2..";"..self.num2.value
	end
    if b==nil then
		GMIN:SendReqMes(str,str2)
	else
		str=str..str2
		GMIN:OnSubmitText(str)
  end
  self:Close()
end


function UIGM:FindObj(name, state)
		MapHelper.instance:FindObj(name, state)
end

--点击触发
function UIGM:OnClickHandler(gameObject)
	if(gameObject.name=="transBg") then
		-- self:Close()
	elseif(gameObject.name=="ConfirmBtn") then
		--self:OnSubmit()
		GMIN:OnSubmit(self.mInput)
	else
		iTrace.Error("soon","找不到点击的button")
	end
end

--禁止关闭
function My:ConDisplay()
    do return true end
end


function My:Clear( )
	if self.items~=nil then
		local len = #self.items
		for i=1,len do
			GameObject.Destroy(self.items[len+1-i].go)
			self.items[len+1-i]=nil
		end
		self.items=nil
	end
end


return UIGM