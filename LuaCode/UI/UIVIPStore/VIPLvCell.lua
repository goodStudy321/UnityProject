--[[


--]]
local AssetMgr=Loong.Game.AssetMgr

VIPLvCell=Super:New{Name="VIPLvCell"}
local My = VIPLvCell

function My:Init(pre,parent)
    local go = GameObject.Instantiate(pre)
    go:SetActive(true)
    go.transform.parent=parent
    go.transform.localPosition=Vector3.zero
    go.transform.localScale=Vector3.one

    self.go=go
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local trans = go.transform
    self.trans=trans
    self.grid=CG(UIGrid,trans,"Grid",self.Name,false)
    self.VIPLab=CG(UISprite,trans,"VIPLab/v",self.Name,false)
    self.PriceLab=CG(UILabel,trans,"PriceLab",self.Name,false)
    self.btn=TF(self.trans,"Btn")
    self.btnLab=CG(UILabel,self.trans,"Btn/Label",self.Name,false)
    UITool.SetBtnSelf(self.btn,self.OnClick,self,self.Name)
    self.red=TF(self.btn.transform,"red")
    self.red:SetActive(false)
    self.has=CG(UISprite,self.trans,"has",self.Name,false)
    self.has.gameObject:SetActive(false)

    VIPMgr.eGift:Add(self.OnGift,self)
end

function My:OnGift()
    local lv = VIPMgr.GetVIPLv()
    if self.curLv<=lv then 
        local isbuy = VIPMgr.giftDic[tostring(self.curLv)] or false
        self:UpGift(isbuy)

        local vip = VIPLv[self.curLv+1]
        local price = vip.Price
        self.price=price
        self.PriceLab.text=tostring(price)
    else
        self.VIPLab.spriteName="vip"..self.curLv
    end  
    self.PriceLab.gameObject:SetActive(self.curLv<=lv)
    self.VIPLab.transform.parent.gameObject:SetActive(self.curLv>lv)
end

function My:OnRed(state)
    self.red:SetActive(state)
end

function My:UpData(vipLv,vipTag)
    self.curLv=vipLv-1
    if not self.list then self.list={} end
    local data = VIPLv[vipLv]
    if not data then iTrace.Error("xiaoyu","VIP等级表为空 id: "..vipLv)return end
    local list=data.giftList
    for i,v in ipairs(list) do
        local cell=ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.grid.transform,0.78)
        cell:UpData(v.id,v.val)
        if vipTag and vipTag[i] then cell:FirstPayLeft(vipTag[i]) end
        self.list[i]=cell
    end
    self.grid:Reposition()

   self:OnGift()  
end

--购买完等级礼包
function My:UpGift(isbuy)
    local text=""
    if isbuy==true then
        text="已购买"
        self.has.gameObject:SetActive(true)
        self.btn:SetActive(false)
    else
        text = "购买"
    end
    self.btnLab.text=text
end

function My:OnClick()
    if VIPMgr.GetVIPLv()<self.curLv then UITip.Log("等级不足无法购买") return end
	VIPMgr.ReqGift(self.curLv)
end

function My:Clean()
    while #self.list>0 do
        local cell = self.list[#self.list]
        cell:DestroyGo()
        ObjPool.Add(cell)
        self.list[#self.list]=nil
    end
    Destroy(self.go)
end

function My:Dispose()
    self:Clean()
    VIPMgr.eGift:Remove(self.OnGift,self)
    TableTool.ClearUserData(self)
    My=nil
end