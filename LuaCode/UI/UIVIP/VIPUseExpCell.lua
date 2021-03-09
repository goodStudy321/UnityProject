--[[
VIP经验卡使用
]]
VIPUseExpCell=VIPBuyCell:New{Name="VIPUseExpCell"}
local My = VIPUseExpCell
My.eClick=Event()

function My:InitCustom( ... )
    local TF = TransTool.FindChild
    self.price.gameObject:SetActive(false)
    local icon = TF(self.trans,"icon")
    icon:SetActive(false)
    self.btn.text="使用"
    self.red=TF(self.trans,"Btn/red")
end

function My:UpData(id,num)
    self.id=id
    self.trans.name=self.id
    self.num=num
    local item = ItemData[tostring(id)]
    if not item then iTrace.eError("xiaoyu","VIP经验卡为空 id: "..id)return end
    self.item=item
    self.name.text=item.name
    self.des.text="增加"..item.uFxArg[1].."点VIP经验"
    self.cell:UpData(self.id,num)
    self.red:SetActive(num>0)
end

function My:OnClick()
    My.eClick()
    if self.num>1 then
        UIMgr.Open(BatchUse.Name,self.BatchUseCb,self)
    else
        PropMgr.ReqUse(self.id,1,1)
    end
end

function My:BatchUseCb(name)
    local ui=UIMgr.Get(name)
	if ui then
		ui:UpData(self.item)
	end
end

function My:SetBtn(isGray)
    if isGray==true then
        UITool.SetGray(self.Btn,false)
    else
        UITool.SetNormal(self.Btn)
    end
end