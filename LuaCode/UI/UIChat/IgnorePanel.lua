--[[
屏蔽名单
--]]
require("UI/UIChat/IgnoreCell")

IgnorePanel=Super:New{Name="IgnorePanel"}
local My = IgnorePanel

function My:Ctor()
    self.dic={}
end

function My:Init(go)
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local trans = go.transform
    self.go=go

    local U = UITool.SetBtnClick

    U(trans,"OpenBtn",self.Name,self.OnClick,self)
    U(trans,"Button",self.Name,self.Close,self)
    self.none=TF(trans,"none")
    self.pre=TF(trans,"C")
    self.Grid=CG(UIGrid,trans,"Panel/Grid",self.Name,false)
end

function My:OnBan(tp,id)
    if tp==1 then --屏蔽
        local info=ChatMgr.BanDic[tostring(id)]
        self:AddBan(info)
    elseif tp==2 then --解除屏蔽
        if id==0 then
            self.none:SetActive(true)
            self.isnone=true
            TableTool.ClearDicToPool(self.dic)
        else
            local cell = self.dic[tostring(id)]
            ObjPool.Add(cell)
            self.dic[tostring(id)]=cell
        end
    end
    self.Grid:Reposition()
end

function My:UpData()
    ChatMgr.eBan:Add(self.OnBan,self)

    local dic = ChatMgr.BanDic
    local count = TableTool.GetDicCount(dic)
    if count==0 then
        self.isnone=true
    else
        self.isnone=false
        for k,v in pairs(dic) do
            self:AddBan(v)
        end  
        self.Grid:Reposition()
    end
    self.none:SetActive(count==0)
end

function My:AddBan(info)
    local go = GameObject.Instantiate(self.pre)
    go:SetActive(true)
    go.transform.parent=self.Grid.transform
    go.transform.localScale=Vector3.one
    go.transform.localPosition=Vector3.zero
    local cell = ObjPool.Get(IgnoreCell)
    cell:Init(go)
    cell:UpData(info)
    self.dic[tostring(info.rId)]=cell
end

--全部解除
function My:OnClick()
    if self.isnone==true then
        UITip.Error("您在【区域】频道暂未屏蔽玩家")
    else
        ChatMgr.ReqBanDel(0)
    end
end

function My:Close()
    self:Clean()
    self.go:SetActive(false)
end

function My:Open()
    self.go:SetActive(true)
end

function My:Clean()
    self.isnone=nil
    ChatMgr.eBan:Remove(self.OnBan,self)
    TableTool.ClearDicToPool(self.dic)
end