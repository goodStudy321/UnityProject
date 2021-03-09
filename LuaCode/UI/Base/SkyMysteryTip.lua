--[[
天机印tip
]]
require("UI/UISkyMysterySeal/UISkyMysterySealTip")
SkyMysteryTip=UIBase:New{Name="SkyMysteryTip"}
local My = SkyMysteryTip

My.isInWarehouse = false

function My:InitCustom()
    self.tip=ObjPool.Get(UISkyMysterySealTip)
    self.tip:Init(self.gbj,true)

    UITool.SetLsnrClick(self.root,"transBg",self.Name,self.Close,self)

    self.FamilyBtn = TransTool.FindChild(self.root, "FamilyBtn")
end

function My:UpData(item)
    self.tip:UpdateData(item)
end

function My:ShowBtn(btnList, clickCell)
    self.tb = clickCell.tb
    if (clickCell.item.worth > 0 or clickCell.item.cost > 0) and clickCell.showDepotPoint then
        if btnList then
            for i,btnName in ipairs(btnList) do
                if (isWayExit==false and btnName==UIContentY.btnList[18]) or btnName~=UIContentY.btnList[18] then
                    self:AddBtn(btnName)
                end
            end
        end
    end
end

function My:AddBtn(name)
    local go = self.FamilyBtn
    go:SetActive(true)
    go.name=name
    go.transform.localScale=Vector3.one
    UITool.SetBtnSelf(go,self[name],self,self.Name)
    local lab = ComTool.Get(UILabel,go.transform,"Label",self.Name,false)
    lab.text=UIContentY.btnNameList[name]
end

--兑换
function My:Exchange()
    --// LY add begin
    if self.tb ~= nil and self.tb.id ~= nil then
        FamilyMgr:ReqFamilyExcDepot(self.tb.id, 1);
    else
        iTrace.Error("LY", "Exchange error !!! ");
    end
    --// LY add end

    self:Close()
end

--捐献
function My:Donate()
    --// LY add begin
    if self.tb ~= nil and self.tb.id ~= nil then
        local itemUIdTbl = {self.tb.id};
        FamilyMgr:ReqFamilyDonate(itemUIdTbl);
    else
        iTrace.Error("LY", "Donate error !!! ");
    end
    --// LY add end

    self:Close()
end

function My:DisposeCustom( ... )
    self.isInWarehouse = false
    if self.tip then ObjPool.Add(self.tip) self.tip=nil end
    if self.FamilyBtn then self.FamilyBtn:SetActive(false) end
end

return My