BossCostTip=UIBase:New{Name="BossCostTip"}
local My = BossCostTip
My.eClose=Event()
function My:InitCustom(  )
    local go = self.root.gameObject
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;
    local CG = ComTool.Get;
    local trans =self.root
    go:SetActive(false);
    self.go=go;
    self.ItemRoot = TF(trans,"NeedItem",name);
    -- self.CostNum = CG(UILabel,trans,"CostNum",name,false);
    self.Desc = CG(UILabel,trans,"Desc",name,false);
    self.Title = CG(UILabel,trans,"Title",name,false);
    self.witch=CG(UILabel,trans,"CostNum/lab",name,false);
    self.EnterLab=CG(UILabel,trans,"Enter/Label",name,false)
    UC(trans,"Cancel",name,self.cilkClose,self);
    UC(trans,"Close",name,self.cilkClose,self);
    UC(trans,"Enter",name,self.EnterC,self);
end

function My:cilkClose(  )
    My.eClose()
    self:Close();
end
function My:doTipInfo(title,mapId,itemId,num )
    self.Title.text=title;
    self.mapId=mapId;   
    self.ItemId=itemId;
    self.num=num
    self:OpenTip(itemId,num);
end
--打开提示
function My:OpenTip(itemId,num)
    -- self.CostNum.text = tostring(num);
    self.EnterLab.text="进入"
    local itemdate=UIMisc.FindCreate(itemId)
    local labName=itemdate.name
    local sw =   string.format("挑战%s需要消耗%s",self.Title.text,labName);
    self.witch.text=sw;
    self.Item = ObjPool.Get(UIItemCell);
    self.Item:InitLoadPool(self.ItemRoot,1);
    local hasNum = PropMgr.TypeIdByNum(itemId);
    local text = string.format("%s/%s",hasNum,num);
    self.Item:UpData(itemId,text);
    self.Num =self.num - hasNum ;
    if self.Num>0 then
        local price = StoreMgr.GetTotalPrice(itemId, self.Num);
        local desc = string.format("可消耗%s绑元进入(绑元不足消耗元宝)",price);
        self.price=price
        self.Desc.text = desc;
    else
        self.Desc.text=""
    end
    self.go:SetActive(true);
end
function My:use( title,ItemId,num )
    self.ItemId=ItemId
    local VpLv = VIPMgr.GetVIPLv()
    self.VpLv=VpLv
    self.Title.text=title;
    self.num=num
    local sw =   string.format("消耗疲劳药水增加挑战次数");
    self.witch.text=sw;
    self.Item = ObjPool.Get(UIItemCell);
    self.Item:InitLoadPool(self.ItemRoot,1);
    local hasNum = PropMgr.TypeIdByNum(ItemId);
    local text = string.format("%s/%s",hasNum, self.num);
    self.Item:UpData(ItemId,text);
    self.Num =self.num - hasNum ;
    self.Desc.text=""
    self.EnterLab.text="使用"
    if self.Num>0 then
        self.go:SetActive(false);
        UITip.Log("无疲劳药水")
    else
        self.go:SetActive(true);
        self:lsnr("Add")
    end
end
function My:Buy( title,ItemId,num )
    self.ItemId=ItemId
    local VpLv = VIPMgr.GetVIPLv()
    self.VpLv=VpLv
    self.Title.text=title;
    self.num=num
    local sw =   string.format("消耗[67cc67]疲劳药水[-]增加挑战次数");
    self.witch.text=sw;
    self.Item = ObjPool.Get(UIItemCell);
    self.Item:InitLoadPool(self.ItemRoot,1);
    self.go:SetActive(true);
    self:reBuy()
    self:lsnr("Add")
end
function My:lsnr( fun )
    NetBoss.eUpTieTime[fun](NetBoss.eUpTieTime,self.AddBack,self)
    PropMgr.eUpdate[fun](PropMgr.eUpdate,self.reBuy,self)
end
function My:AddBack( )
    UITip.Log("挑战次数增加")
    self:reBuy()
end
function My:reBuy(  )
    local itemId=self.ItemId
    local hasNum = PropMgr.TypeIdByNum(itemId);
    local text = string.format("%s/%s",hasNum, self.num);
    self.Item:UpData(itemId,text);
    self.Num =self.num - hasNum ;
    local gbIn = GlobalTemp["122"].Value3
    -- local AllBuys = gbIn.id
    local vipInfo = soonTool.GetVipInfo(self.VpLv)
    local AllBuys=vipInfo.tieBuy
    self.BuyTime=AllBuys-NetBoss.WldBuyTimes
    self.AllBuys=AllBuys
    if self.Num>0 then
        self.price = gbIn*self.Num;
        local desc = string.format("道具不足可消耗[67cc67]%s绑元[-]购买(绑元不足消耗元宝)\n[67cc67]VIP%s[-]今日可购买 [67cc67]%s/%s[-] 次",self.price,self.VpLv,self.BuyTime,self.AllBuys);
        self.Desc.text = desc;
        self.EnterLab.text="购买"
    else
        self.Desc.text=""
        self.EnterLab.text="使用"
    end
end

function My:OnlyUse(  )
    -- body
end

--关闭提示
function My:Clear()
    self.go:SetActive(false);

    self:lsnr("Remove")
    local item = self.Item;
    if item ~= nil then
        item:DestroyGo();
        ObjPool.Add(item);
        self.Item = nil;
    end
end


--进入
function My:EnterC(go)
    if  self.EnterLab.text=="进入" then
        self:Close();
        if self.Num ~= nil and self.ItemId ~= nil and self.Num > 0 then
            local desc = string.format("道具数量不足，是否消耗%s绑元购买进入？(绑元不足消耗元宝)",self.price); 
            MsgBox.ShowYesNo(desc, self.YesCb,self, "确定", self.NoCb,self, "取消")
        else
            SceneMgr:ReqPreEnter(self.mapId, false,true);
        end
    elseif  self.EnterLab.text=="使用" then
        -- self.backTimes=0
        PropMgr.ReqUse(self.ItemId, 1,1)
    elseif  self.EnterLab.text=="购买" then
       local MyMoney = RoleAssets.Gold+RoleAssets.BindGold;
        if MyMoney<self.price then
            UITip.Log("元宝不足")
            return ;
        end
        local BuyTime=NetBoss.WldBuyTimes
        if BuyTime >= self.AllBuys then
            UITip.Log("今日可购买次数已用完")
            return ;
        end
        local desc = string.format("是否消耗%s绑元购买并使用？(绑元不足消耗元宝)",self.price); 
        MsgBox.ShowYesNo(desc, self.YesBuy,self, "确定", self.NoBuy,self, "取消")
    end
end
function My:YesBuy(  )
    NetBoss.sendBossBuy()
end
--确认消耗进入
function My:YesCb()
    local num = self.Num;    
    StoreMgr.TypeIdBuy(self.ItemId,num,false);
    SceneMgr:ReqPreEnter(self.mapId, false,true);
end
function My:NoCb( )
    return;
end
function My:NoBuy( )
    return;
end
return My;