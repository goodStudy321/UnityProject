--[[
直升V4
]]
UIToV4=UIBase:New{Name="UIToV4"}
local My = UIToV4

function My:InitCustom()
    local trans = self.root
    local CG=ComTool.Get

    UITool.SetBtnClick(trans,"CloseBtn",self.Name,self.Close,self)
    UITool.SetBtnClick(trans,"Button",self.Name,self.OnToV4,self)
    self.Panel=CG(UIScrollView,trans,"Panel",self.Name,false)
    self.Lab=CG(UILabel,trans,"Panel/Label",self.Name,false)
    self.msg=CG(UILabel,trans,"msg",self.Name,false)
end


function My:UpData(curId)
    local data = VIPLv[5]
    local des = VIP.GetVIPDes(data)
    self.Lab.text=des

    local id4="210003"
    local firstBuy = VIPMgr.firstBuy
    local curBuy=VIPBuy[curId]
    local toBuy = VIPBuy[id4]
    local lerp = toBuy.price-curBuy.price
    self.lerp=lerp
    self.msg.text="你确定花费"..lerp.."元宝直升V4吗？"
end

function My:OnToV4()
    local isenough = RoleAssets.IsEnoughAsset(2,self.lerp)
    if isenough==true then 
        VIPMgr.ReqVIPDirect()
    else
        StoreMgr.JumpRechange()
    end
    self:Close()
end


function My:DisposeCustom()
    TableTool.ClearUserData(self)
end



return My