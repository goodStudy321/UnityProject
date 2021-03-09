FiveBuytip = Super:New{Name="FiveBuytip"}
local My = FiveBuytip
My.BuyTimes=1
My.ItemCel=nil

function My:Init(root)
    self.root=root
    self.go=root.gameObject
    --常用工具
    local tip = "FiveBuytip"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;

    UC(root,"uc_Close",tip,self.CloseClick,self)
    self.vipTip=CG(UILabel,root,"lab_vipTip",tip)
    self.CostShow=CG(UILabel,root,"lab_CostShow",tip)
    self.egTime=CG(UILabel,root,"lab_egTime",tip)
    UC(root,"lab_egTime/uc_add",tip,self.addClick,self)
    UC(root,"lab_egTime/uc_dec",tip,self.decClick,self)
    self.AllBuy=CG(UILabel,root,"lab_AllBuy",tip)
    self.IllWillGet=CG(UILabel,root,"lab_IllWillGet",tip)
    self.Enter=CG(UIButton,root,"btn_Enter",tip)
    self.IllIcon=CG(UITexture,root,"IllIcon",tip)
    self.illSpeed=CG(UILabel,root,"illSpeed",tip)
    self.illNow=CG(UILabel,root,"illNow",tip)
    self.rwdrt=TF(root,"rwdrt",tip)
    AssetMgr:Load(FiveCopyHelp.illIconTxt,ObjHandler(self.LoadIllIcon,self));    
    self:ClickEvent()
    self:GetItemNat( )
    self.Iopen=false
end

function My:GetItemNat( )
    My.ItemCel=soonTool.AddOneCell(self.rwdrt,FiveCopyHelp.illItemNum,1)
end

--加载icon完成
function My:LoadIllIcon(obj)
	if self.IllIcon == nil then
        AssetTool.UnloadTex(obj.name)
        return;
    end
    self.IllIcon.mainTexture=obj;    
end
function My:Open( )
    self.Iopen=true
    self.go:SetActive(true)
    self:UpDateTimes(  )
    self:UpdtGetAndCost( )
    self:UpDateIll(  )
end

function My:UpDateIll(  )
    if self.Iopen==true then
        self.illNow.text=string.format( "%s/%s",FiveElmtMgr.illusion,FiveCopyHelp.illMax)        
    end
end
function My:UpDateTimes(  )
    if self.Iopen==true then
        local vipLv = VIPMgr.GetVIPLv()
        local vipInfo = soonTool.GetVipInfo(vipLv)
        self.MaxTimes = vipInfo.FiveBuyTimes
        My.BuyTimes=1
        self.NowMaxCanBuy=self.MaxTimes-FiveElmtMgr.buy_illusion_times
        local nextTimes,nextvp = soonTool.FindNextNum("FiveBuyTimes",vipLv)
        self.nextTimes=nextTimes
        self.nextvp=nextvp
        My.BuyTimes=1
        self:UpdtGetAndCost( )   
    end
end


function My:ClickEvent()
   local US = UITool.SetLsnrSelf
   US(self.Enter, self.EnterClick, self)
end

function My:ChangeTiems(num )
    local NowTimes=My.BuyTimes+num
    if NowTimes<1 then
        return
    end
    if NowTimes>self.NowMaxCanBuy then
        UITip.Log("已经达到今天最大购买次数")
        return
    end
    My.BuyTimes=NowTimes
    self:UpdtGetAndCost( )
end

function My:UpdtGetAndCost( )
    self.egTime.text= My.BuyTimes
    self.AllCost=FiveCopyHelp.mathCostAll(My.BuyTimes)
    self.AllGet=My.BuyTimes*FiveCopyHelp.natOnceGet
    self.AllBuy.text=string.format( "(当日可购买%s/%s)", self.NowMaxCanBuy,self.MaxTimes)
    self.CostShow.text=self.AllCost
    self.IllWillGet.text=self.AllGet
    self.illSpeed.text=string.format( "%s/小时",FiveCopyHelp.illSpeed)
    if self.nextTimes~=0 then
        self.vipTip.text=string.format( "VIP%s可购买次数增加到%s次", self.nextvp,self.nextTimes)
    else
        self.vipTip.text=""
    end
end


function My:addClick(go)
    self:ChangeTiems(1 )
end

function My:decClick(go)
    self:ChangeTiems(-1 )
end

function My:EnterClick(go)
    if self.NowMaxCanBuy<1 then
        UITip.Log("已经达到今天最大购买次数")
        return
    end
    local MyGold = RoleAssets.Gold
    if MyGold<self.AllCost then
        UITip.Log("元宝不足")
        StoreMgr.JumpRechange()
        return
    end
    FiveCopyHelp.buyIllSend(self.BuyTimes)
    -- FiveCopyTip:Close()
end

function My:CloseClick(go)
    FiveCopyTip:Close()
end

function My:Close()
    self.Iopen=false
    self.go:SetActive(false)
end
function My:Clear()
    AssetMgr:Unload(FiveCopyHelp.illIconTxt,false); 
    soonTool.desOneCell(My.ItemCel)
    self.Iopen=false
end

return My
