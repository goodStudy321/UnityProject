--[[
材料tip
]]
ItemTip=BaseCell:New{Name="ItemTip"}
local My = ItemTip

function My:Init(go)
    self.go=go
    local trans = go.transform
    local CG = ComTool.Get
	local TF = TransTool.FindChild
    local trans = go.transform
    local U = UITool.SetLsnrClick

    self.lab=CG(UILabel,trans,"nameLab",self.Name,false)
    self.numLab=CG(UILabel,trans,"numLab",self.Name,false)
    self.Des=CG(UILabel,trans,"Des",self.Name,false)
    self.Qua=CG(UISprite,trans,"qua",self.Name,false)
    self.Icon=CG(UITexture,trans,"qua/Icon",self.Name,false)

    --U(trans,"Mask",self.Name,self.Close,self)
    if not self.str then self.str=ObjPool.Get(StrBuffer) end
end

function My:UpData(type_id,bType,sType)
    self.bType=bType
    self.sType=sType
    local item = ItemData[tostring(type_id)]
    self:CustomData(item.quality,item.icon,item.name)
    local has = PropMgr.TypeIdByNum(type_id)
    self.type_id=type_id
    self.numLab.text="已有："..has
    self.str:Dispose()
    self.str:Apd("[99886BFF]物品描述：[F4DDBDFF]")
    self.str:Line()
    self.str:Apd(item.des)
    self.str:Line()
  
    local way = item.getwayList
    if way then
        self.str:Apd("[-][99886BFF]获得途径[F4DDBDFF]")
        self.str:Line()
        self.str:Apd("[67cc67]")
		for i,v in ipairs(way) do
			local data = GetWayData[tostring(v)]
			if not data then iTrace.eError("xiaoyu","获取表为空 id: "..v)return end
			local text = data.des
			self.str:Apd(text)
			if i~=#way then self.str:Apd("、") end
        end
        self.str:Line()
    end   
    self.Des.text=self.str:ToStr()

    euiclose:Add(self.OnClose,self)
    self.go:SetActive(true)
    GetWayFunc.ItemGetWay(type_id,Vector3.New(138.75,-160.93,0))
end

function My:OnClose(name)
    if name==UIGetWay.Name then self:Close() end
end

function My:OnClickBoss1()
    BossHelp.curType = 1
	UIMgr.Open(UIBoss.Name)
end

function My:OnClickBoss2()
    BossHelp.curType = 2
	UIMgr.Open(UIBoss.Name)
end

function My:OnClickAuction()
    UIMgr.Open(UIAuction.Name,self.OpenAuctionCb,self)
end

function My:OpenAuctionCb(name)
    local ui = UIMgr.Get(name)
    if ui then 
        ui:SwitchMemu("1003")
    end
end

function My:Close()
    --
    self.go:SetActive(false)
end

function My:Dispose()
    euiclose:Remove(self.OnClose,self)
    if self.str then ObjPool.Add(self.str) self.str=nil end
end