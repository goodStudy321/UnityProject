--[[


--]]
local AssetMgr=Loong.Game.AssetMgr

VIPStoreCell=Super:New{Name="VIPStoreCell"}
local My = VIPStoreCell

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
    self.btn=TF(self.trans,"Btn")
    self.btn:SetActive(true)
    self.btnLab=CG(UILabel,self.trans,"Btn/Label",self.Name,false)
    UITool.SetBtnSelf(self.btn,self.OnClick,self,self.Name)
    self.red=TF(self.btn.transform,"red")
    self.has=CG(UISprite,self.trans,"has",self.Name,false)
    self.has.gameObject:SetActive(false)

    VIPMgr.eVIPStoreRed:Add(self.UpWeek,self)
    self.canWeek=false
end

function My:UpData(vipLv)
    self.curLv=vipLv
    if not self.list then self.list={} end
    local data = VIPLv[vipLv+1]
    if not data then iTrace.Error("xiaoyu","VIP等级表为空 id: "..vipLv)return end
    local list=data.weekList
    for i,v in ipairs(list) do
        local cell=ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.grid.transform,0.78)
        cell:UpData(v.id,v.val)
        self.list[i]=cell
    end
    self.grid:Reposition()
   self:UpWeek()
end

function My:UpWeek()
    if self.curLv==VIPMgr.GetVIPLv() then  
        local text=""
        if VIPMgr.canWeek==false then
            text="已领取"
            self.canWeek=false          
        else
            text = "领取"
            self.canWeek=true
        end
        self.btnLab.text=text
        self.red:SetActive(self.canWeek)
        self.btn:SetActive(self.canWeek)
        self.has.gameObject:SetActive(not self.canWeek)
    end
    self.VIPLab.spriteName="vip"..self.curLv
end

function My:OnClick()
    if self.canWeek==true then --领取
        VIPMgr.ReqWeek()
    else
        VIPMgr.OpenVIP(1)
    end
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
    VIPMgr.eVIPStoreRed:Remove(self.UpWeek,self)
    TableTool.ClearUserData(self)
    My=nil
end