--[[
守护续费
]]
UIElfRenewal=UIBase:New{Name="UIElfRenewal"}
local My = UIElfRenewal


function My:InitCustom()
    local CG = ComTool.Get
	local TF = TransTool.FindChild
    local trans = self.root
    local U = UITool.SetBtnClick

    U(trans,"CloseBtn",self.Name,self.Close,self)
    U(trans,"btn",self.Name,self.OnBuy,self)
    self.lab=CG(UILabel,trans,"btn/money",self.Name,false)
    self.icon=CG(UISprite,trans,"btn/icon",self.Name,false)
    self.s1=TF(trans,"s1")
    self.s2=TF(trans,"s2")

    self.Cell=ObjPool.Get(UIItemCell)
    self.Cell:InitLoadPool(trans,nil,nil,nil,nil,Vector3.New(0,-6,0))

end

function My:UpData(id)
    --绑元 5  元宝 2 仙女
    if id==40003 then id=40001 end
    self.s1:SetActive(id~=40002)
    self.s2:SetActive(id==40002)

    self.Cell:UpData(id)

    local tp=id==40002 and 2 or 5
    local spriteName = id==40002 and "money_02" or "money_03"

    local shopid = StoreMgr.GetStoreId(tp,id)
    self.shopid=shopid
    local store = StoreData[tostring(shopid)]
    if not store then iTrace.eError("xiaoyu","商城表为空 id:  "..shopid)return end
    self.lab.text=store.curPrice
    self.icon.spriteName=spriteName

    self.msg=id==40002 and "是否花费"..store.curPrice.."元宝购买7天小仙女" or "是否花费"..store.curPrice.."绑元购买7天小精灵"
end

function My:OnBuy()
    MsgBox.ShowYesNo(self.msg,self.BuyCb,self)
  
end

function My:BuyCb()
    StoreMgr.ReqBugGoods(self.shopid,1)
    self:Close()
end

function My:CloseCustom()
    if self.Cell then self.Cell:DestroyGo() ObjPool.Add(self.Cell) self.Cell=nil end
end

return My