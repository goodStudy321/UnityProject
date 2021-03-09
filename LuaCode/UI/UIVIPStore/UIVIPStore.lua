--[[
VIP商城
--]]
require("UI/UIVIPStore/VIPStorePanel")
require("UI/UIVIPStore/VIPPanel")
UIVIPStore=UIBase:New{Name="UIVIPStore"}
local My = UIVIPStore

function My:InitCustom()
    local trans = self.root
    local TF = TransTool.FindChild
    local CG = ComTool.Get
    local U = UITool.SetLsnrSelf
    local UU = UITool.SetLsnrClick

    if self.togDic==nil then self.togDic={} end
    if self.tgDic==nil then self.tgDic={} end

    local grid=CG(UIGrid,trans,"Grid",self.Name,false)
    for i=1,4 do
        local tog=CG(UIToggle,grid.transform,"Tg"..i,self.Name,false)
        self.togDic[i]=tog
        U(tog.gameObject,self.OnClick,self,self.Name)
        local state = (i==1 or i==4) and true or false --策划让屏蔽的
        tog.gameObject:SetActive(state)
    end
    grid:Reposition()
    self.red3=TF(trans,"Grid/Tg3/red")
    self.red4=TF(trans,"Grid/Tg4/red")
    UU(trans,"CloseBtn",self.Name,self.Close,self)

    local tg =ObjPool.Get(StorePanel)
    tg:Init(TF(trans,"StorePanel"))
    self.tgDic[1]=tg  
    self.tgDic[2]=tg   

    local tg3 =ObjPool.Get(VIPStorePanel)
    tg3:Init(TF(trans,"VIPStorePanel"))
    self.tgDic[3]=tg3
    

    local tg4 =ObjPool.Get(VIPPanel)
    tg4:Init(TF(trans,"VIPPanel"))
    self.tgDic[4]=tg4   

    self:OnRed()

    VIPMgr.eVIPStoreRed:Add(self.OnRed,self)
end

function My:OnRed()
    self.red3:SetActive(VIPMgr.VipsRed["3"])
    self.red4:SetActive(VIPMgr.VipsRed["4"])
end

function My:OnClick(go)   
    local tp = string.sub(go.name,3)
    if tp then       
        self:SwatchTg(tp)
    end
end

function My:OpenTabByIdx(t1, t2, t3, t4)
    self:SwatchTg(t1)
end

function My:SwatchTg(tp)
    tp=tonumber(tp)
    local tog=self.togDic[tp]
    tog.value=true
    if self.curTp then 
        self.tgDic[self.curTp]:Close()
    end
    self.curTp=tp
    local tg=self.tgDic[self.curTp]
    tg:Open()
    if self.curTp<=2 then  tg.panel:CreateC(tp+9) end
end

function My:Clear()
    -- body
end

function My:DisposeCustom()
    JumpMgr.eOpenJump()
    VIPMgr.eVIPStoreRed:Remove(self.OnRed,self)
    self.curTp=nil
    TableTool.ClearDicToPool(self.tgDic)
end

return My