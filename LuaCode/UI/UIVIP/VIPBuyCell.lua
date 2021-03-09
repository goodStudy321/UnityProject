--[[
VIP格子基类
--]]
local AssetMgr=Loong.Game.AssetMgr
VIPBuyCell=Super:New{Name="VIPBuyCell"}
local My=VIPBuyCell
My.eClick=Event()

function My:Init(mPre,parent)
    local go = GameObject.Instantiate(mPre)
    go:SetActive(true)
    go.transform.parent=parent
    go.transform.localPosition=Vector3.zero
    go.transform.localScale=Vector3.one
    
    local TF = TransTool.FindChild
    local CG = ComTool.Get
    self.trans = go.transform

    self.cell=ObjPool.Get(UIItemCell)
    self.cell:InitLoadPool(self.trans,nil,nil,nil,nil,Vector3.New(-191.8,0,0))
    self.icon=TF(self.trans,"icon")
    --self.icon=CG(UISprite,self.trans,"icon",self.Name,false)
    self.name=CG(UILabel,self.trans,"name",self.Name,false)
    self.des=CG(UILabel,self.trans,"des",self.Name,false)
    self.price=CG(UILabel,self.trans,"price",self.Name,false)
    self.Btn=TF(self.trans,"Btn")
    UITool.SetBtnClick(self.trans,"Btn",self.Name,self.OnClick,self)
    self.btn = ComTool.Get(UILabel,self.trans,"Btn/Label",self.Name,false)
    self:InitCustom()
end

function My:InitCustom( ... )
    -- body
end

function My:UpData(id)
    self.id=id
    self.trans.name=self.id

    local vipbuy = VIPBuy[self.id]
    if not vipbuy then iTrace.Error("xiaoyu","VIP购买表为空 id: "..id)return end
    self.name.text=vipbuy.name
    local store = StoreData[vipbuy.shopid]
    if not store then iTrace.Error("xiaoyu","商城表为空 id: "..vipbuy.shopid)return end
    self.isenough=RoleAssets.IsEnoughAsset(2,store.curPrice)
    self.des.text="增加"..vipbuy.day.."天VIP时长"
    self.cell:UpData(self.id)
    local num = PropMgr.TypeIdByNum(id)
    self.num=num
    if num==0 then
        self.price.text=store.curPrice
    else
        self.cell:UpLab(num)
    end
    self.price.gameObject:SetActive(num==0)
    self.icon:SetActive(num==0)
    local btnText = num==0 and "购买并使用" or "使用"
    self.btn.text=btnText
end

--购买并使用
function My:OnClick()
    if self.num==0 then 
        if self.isenough==true then 
            VIPMgr.ReqBuy(tonumber(self.id))
        else
            StoreMgr.JumpRechange()
        end
    else
        PropMgr.ReqUse(tonumber(self.id),1,1)
    end
    My.eClick()
end

function My:Dispose()
    Destroy(self.trans.gameObject)
    TableTool.ClearUserData(self)
end