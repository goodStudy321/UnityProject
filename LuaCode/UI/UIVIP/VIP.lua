--[[
VIP界面
--]]
VIP=Super:New{Name="VIP"}
local My=VIP
local lvStr=ObjPool.Get(StrBuffer)

function My:Ctor()
	self.cellList={}
end

function My:Init(go)
	self.trans=go.transform
	local TF=TransTool.FindChild
	local CG=ComTool.Get
	local U = UITool.SetBtnClick

	local bg1=TF(self.trans,"Bg1").transform
	self.panel1=CG(UIPanel,bg1,"Panel",self.Name,false)

	self.c1Root = TF(bg1,"Panel/LbRoot")
	self.sprRoot = TF(bg1,"Panel/SprRoot")

	self.c1 = TF(bg1,"Panel/c")
	self.spr = TF(bg1,"Panel/spr")

	local bg2=TF(self.trans,"Bg2").transform
	self.vip=CG(UILabel,bg2,"vip",self.Name,false)
	self.grid2=CG(UIGrid,bg2,"Grid",self.Name,false)

	self.C=TF(bg2,"C").transform
	self.GetBtn=TF(self.C,"GetBtn")
	self.red=TF(self.C,"GetBtn/red")
	self.eff=TF(self.C,"GetBtn/fx_gm")
	self.UI_ZK_01=TF(self.trans,"UI_ZK_01")
	self.UI_ZK=TF(self.trans,"UI_ZK")
	self.has=TF(self.C,"has")
	U(self.C,"GetBtn",self.Name,self.OnGetBtn,self)
	
	self.pos1=Vector3.New(178,-322,0)
	self.pos2=Vector3.New(178,-408.7,0)
	self.fPrice=CG(UILabel,self.C,"fPrice",self.Name,false)
	self.Price=CG(UILabel,self.C,"Price",self.Name,false)

	self.GetLab=CG(UILabel,self.C,"GetBtn/Label",self.Name,false)

	self.next=TF(self.trans,"next")
	self.last=TF(self.trans,"last")
	U(self.trans,"last",self.Name,self.Last,self)
	U(self.trans,"next",self.Name,self.Next,self)

	self:AddLsnr()

	self:InitData()
end

function My:AddLsnr()	
	VIPMgr.eGift:Add(self.OnGift,self)
	VIPMgr.eUpInfo:Add(self.OnUpInfo,self)	
	VIPMgr.eBuy:Add(self.InitData,self)	
end

function My:RmvLsnr()
	VIPMgr.eGift:Remove(self.OnGift,self)
	VIPMgr.eUpInfo:Remove(self.OnUpInfo,self)
	VIPMgr.eBuy:Remove(self.InitData,self)	
end

function My:InitData()
	self.curLv=VIPMgr.vipLv
	if self.curLv==1 then 
		self.last:SetActive(false)
	elseif self.curLv==#VIPLv-1 then
		self.next:SetActive(false)
	end
	self:OnUpInfo()
end

--领取礼包返回
function My:OnGift()
	self.GetBtn:SetActive(false)
	self.has:SetActive(true)
end

--信息更新
function My:OnUpInfo()
	if self.curLv==0 then self.curLv=1 end
	self:CleanCell()
	local data=VIPLv[self.curLv+1]
	if(data==nil)then iTrace.eError("xiaoyu","VIP等级表为空 id:".. self.curLv)return end
	self:UpLvLab(data)
	self:UpLvGigt(data)
	--self:UpGift()
	self.Price.text=data.Price
	self.fPrice.text=data.fPrice
	self.panel1.clipOffset=Vector2.New(0,0)
	self.panel1.transform.localPosition=Vector3.zero
end

--领取礼包
function My:OnGetBtn() 
	if VIPMgr.GetVIPLv()<self.curLv then UITip.Log("等级不足无法购买") return end
	VIPMgr.ReqGift(self.curLv)
end


function My:Last()
	self.next:SetActive(true)
	self.curLv=self.curLv-1
	self:OnUpInfo()
	if self.curLv==1 then 
		self.last:SetActive(false)
	end
end

function My:Next()
	self.last:SetActive(true)
	self.curLv=self.curLv+1
	self:OnUpInfo()
	if self.curLv==#VIPLv-1 then 
		self.next:SetActive(false)
	end
end

function My.GetVIPDes(data,value)
	lvStr:Dispose()
	local desList = {}
	for i=1,28 do
		local arg=data["arg".. i]		
		if(arg~=nil and arg~=0)then 
			local vt = VIPText[tostring(i)]
			if not vt then iTrace.eError("xiaoyu","VIP文本内容表为空 id: "..i)return end
			local text=vt.text
			if(type(arg)=="table")then 
				for i,v in ipairs(arg) do
					local id = v.id
					local name = PropTool.GetNameById(id)
					local val = PropTool.GetValByID(id,v.val)
					text=string.gsub(text,"#",name,1)
					local cfg = PropName[id]
					if cfg.show==1 then
						text=string.gsub(text,"#",val.."%",1)
					else
						text=string.gsub(text,"#",val,1)
					end
				
				
				end
			else
				local fight = nil
				if i==17 or i==18 or i==22 then arg=arg/100 end
				if i==1 then 
					local title=TitleCfg[tostring(arg)]
					fight = PropTool.GetFight(title)
					arg=title.name
				end
				text=string.gsub(text,"#",arg,1)
				if i==1 then text=string.gsub(text,"#",fight,1) end
			end
			if StrTool.IsNullOrEmpty(value) then
				if not StrTool.IsNullOrEmpty(lvStr:ToStr()) then lvStr:Apd("\n") end
				lvStr:Apd(text)
			else
				desList[#desList + 1] = text
			end
		end
	end
	if StrTool.IsNullOrEmpty(value) then
		return lvStr:ToStr()
	else
		return desList
	end
end

function My:UpLvLab(data)
	local str = My.GetVIPDes(data,true)
	--self.c1.text=str

	if self.DesLB then
		self.DesLB:Dispose()
	end

	if not self.DesLB then
        self.DesLB = ObjPool.Get(VIPContent)
        self.DesLB:Init()
    end
    for i,v in ipairs(str) do
        self.DesLB:CreateLb(self.c1Root,v,self.c1,2,true,self.sprRoot,self.spr)
    end
end

function My:UpLvGigt(data)
	if data.lv>=1 and data.lv<=3 then
		self.UI_ZK_01:SetActive(true)
		self.UI_ZK:SetActive(true)
	else
		self.UI_ZK_01:SetActive(false)
		self.UI_ZK:SetActive(false)
	end
	self.vip.text="VIP".. self.curLv.." 等级礼包"
	local list=data.giftList
	local vipTag = data.vipTag
	self:CreateGift(list,vipTag)
	local state=VIPMgr.giftDic[tostring(self.curLv)] or false
	self.GetBtn:SetActive(not state)
	self.has:SetActive(state)

	local lv = VIPMgr.GetVIPLv()
	local isenough = RoleAssets.IsEnoughAsset(2,tonumber(data.Price))
	local state = false
	if self.curLv<=lv and state~=true and isenough==true then
		state=true
	end
	self.red:SetActive(state)
	self.eff:SetActive(state)
end

function My:CreateGift(list,vipTag)
	local len = 0
	self:CleanCell()
	if(list==nil)then return end
	for i,v in ipairs(list) do
		local path = nil
		if vipTag and vipTag[i] then path=vipTag[i] end
		local type_id=tostring(v.id)
		local num=v.val
		local item=ItemData[type_id]
		if item.uFx==1 then
			self:CreateCell(item,num,1,path)
			len=len+num
		else
			self:CreateCell(item,1,num,path)
			len=len+1
		end	
	end
	self.grid2:Reposition()

	if len<=3 then
		self.C.localPosition=self.pos1
	else
		self.C.localPosition=self.pos2
	end
end

function My:CreateCell(item,len,num,path)
	for i=1,len do
		local cell=ObjPool.Get(UIItemCell)
		cell:InitLoadPool(self.grid2.transform)
		cell:UpData(item,num)
		cell:FirstPayLeft(path)
		self.cellList[#self.cellList+1]=cell
	end
end

function My:CleanCell()
	while #self.cellList>0 do
		local cell=self.cellList[#self.cellList]
		cell:DestroyGo()
		ObjPool.Add(cell)
		self.cellList[#self.cellList]=nil
	end
end

function My:Open()
	self.trans.gameObject:SetActive(true)
end

function My:Close()
	self.trans.gameObject:SetActive(false)
end

function My:Dispose()
	self:RmvLsnr()
	if self.DesLB then
        ObjPool.Add(self.DesLB)
        self.DesLB = nil
    end
	self:CleanCell()
	TableTool.ClearUserData(self)
end
