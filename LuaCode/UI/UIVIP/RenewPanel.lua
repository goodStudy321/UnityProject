--[[
VIP购买
--]]
require("UI/UIVIP/VIPBuyCell")
require("UI/UIVIP/VIPUseExpCell")
require("UI/UIVIP/ToV4Cell")

RenewPanel=Super:New{Name="RenewPanel"}
local My = RenewPanel

function My:Ctor()
    self.list={}
end


function My:Init(go)
    self.go=go
    local trans = go.transform
    self.grid=ComTool.Get(UIGrid,trans,"Grid",self.Name,false)
    self.grid.onCustomSort=self.SortName
    self.pre=TransTool.FindChild(trans,"C")
    UITool.SetBtnClick(trans,"CloseBtn",self.Name,self.Close,self)

    VIPBuyCell.eClick:Add(self.Close,self)
    VIPUseExpCell.eClick:Add(self.Close,self)
end

function My.SortName(a,b)
    local num1 = tonumber(a.name)
    local num2 = tonumber(b.name)
	if(num1<num2)then
		return -1
	elseif (num1>num2)then
		return 1
	else
		return 0
	end
end

function My:UpData(btnState)
    if btnState==1 then
        local toV4Price = self:ToVIP4()
        if StrTool.IsNullOrEmpty(toV4Price)~=true then
            local type_id = 210003
            local cell = ObjPool.Get(ToV4Cell)
            cell:Init(self.pre,self.grid.transform)
            cell:UpData(type_id,toV4Price)
            self.list[#self.list+1]=cell
        end

        local type_id = 210005
        local num = PropMgr.TypeIdByNum(type_id)
        local cell = ObjPool.Get(VIPUseExpCell)
        cell:Init(self.pre,self.grid.transform)
        cell:UpData(type_id,num)
        cell:SetBtn(num==0)
        self.list[#self.list+1]=cell

        local type_id = 210006
        local num = PropMgr.TypeIdByNum(type_id)
        local cell = ObjPool.Get(VIPUseExpCell)
        cell:Init(self.pre,self.grid.transform)
        cell:UpData(type_id,num)
        cell:SetBtn(num==0)
        self.list[#self.list+1]=cell
    elseif btnState==3 then
        for k,v in pairs(VIPBuy) do
            local cell = ObjPool.Get(VIPBuyCell)
            cell:Init(self.pre,self.grid.transform)
            cell:UpData(k)
            self.list[#self.list+1]=cell
        end
    end
    
    self.grid:Reposition()
end

--玩家购买过真仙卡或者仙尊卡，且玩家VIP等级处于VIP1-VIP3时
function My:ToVIP4()
    local money = ""
	local vip = VIPMgr.GetVIPLv()
	local id1 = "210001"
	local id2 = "210002"
	local id4 = "210003"
	local buyDic = VIPMgr.firstBuy
	if buyDic[id4]~=true then
		local vipBuy4 = VIPBuy[id4]
		local vipbuy=nil
		if buyDic[id2]==true and vip>=1 and vip<=3 then 
			vipbuy = VIPBuy[id2]		
		elseif buyDic[id1]==true and vip>=1 and vip<=3 then
			vipbuy = VIPBuy[id1]
		end
		if not vipbuy then return money end
		money = vipBuy4.price-vipbuy.price
		return money
    end
    return money
end

function My:Open()
    self.go:SetActive(true)
end

function My:Close()
    self.go:SetActive(false)
    TableTool.ClearDicToPool(self.list)
end

function My:Dispose()
    VIPBuyCell.eClick:Remove(self.Close,self)
    VIPUseExpCell.eClick:Remove(self.Close,self)
    TableTool.ClearDicToPool(self.list)
    TableTool.ClearUserData(self)
end