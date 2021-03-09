FindBackTip=Super:New{Name="FindBackTip"};
local My = FindBackTip;

function My:Init(root)
    local tip = self.Name;
    self.root = root;
    self.go=self.root.gameObject;
    local TF = TransTool.Find;
    local CG = ComTool.Get;
    local UC = UITool.SetLsnrClick;
    local ED = EventDelegate;
    local EC, ES = ED.Callback, ED.Set;
    local btnRoot = TF(root,"btn",tip);
    UC(btnRoot,"no",tip,self.Close,self);
    UC(btnRoot,"close",tip,self.Close,self);
    UC(btnRoot,"ok",tip,self.Buy,self);
    self.slide=CG(UISlider,root,"slide",tip);
    local slRoot = self.slide.transform
    self.BuyNumTxt=CG(UILabel,slRoot,"thump/lbl",tip);
    self.NowBuyNum=0;
    self.allCost=0;
    UC(slRoot,"add",tip,self.Change,self);
    UC(slRoot,"des",tip,self.Change,self);
    ES(self.slide.onChange, EC(self.SetValWithPos, self));
    local infoRoot = TF(root,"info",tip);
    self.title=CG(UILabel,infoRoot,"title",tip);
    self.moneySay=CG(UILabel,infoRoot,"moneySay",tip);
    self.p_sb = ObjPool.Get(StrBuffer);
end

function My:Open(id,num,title,bas,ext,money,goldExt)
    self.id=id;
    self.type=num;
    self.go:SetActive(true);
    self.title.text=title;
    self.bas=bas;
    self.ext=ext;
    self.all=bas+self.ext;
    self.onceMoney=money;
    self.goldExt=goldExt;
    self:SetPosWithVal(bas);
end
--通过值确定位置
function My:SetPosWithVal(num)
    self.slide.value=(1/self.all)*num;
    self:SetVale(num);
end
--通过位置确定值
function My:SetValWithPos()
    if self.all==nil  then
        return;
    end
    local num = math.ceil( self.slide.value*self.all);
    self:SetVale(num);
end
--更新数据
function My:SetVale( num )
    self.BuyNumTxt.text=num;
    self.NowBuyNum=num;
    self.p_sb:Dispose();
    if num>self.bas then
        if self.isExp then
            self.allCost=self.bas*self.onceMoney +  self:ExpextAll( num-self.bas )
        else
            self.allCost=self.bas*self.onceMoney + (num-self.bas)*self.goldExt;
        end
    else
        self.allCost=num*self.onceMoney;
    end
    if self.type==1 then
        if self.goldExt~=nil and self.goldExt~="nil" and self.goldExt~=0 then
            self.goldExt=self.isExp and self.goldExtexp[num-self.bas] or self.goldExt
            self.p_sb:Apd("总价:"):Apd(self.allCost):Apd("绑元(单价"):Apd(self.onceMoney)
            :Apd("绑元,额外单价"):Apd(self.goldExt):Apd("绑元)");
        else
            self.p_sb:Apd("总价:"):Apd(self.allCost):Apd("绑元(单价"):Apd(self.onceMoney)
            :Apd("绑元)");
        end
    else
        local allCost = math.NumToStrCtr(self.allCost);
        local onceMoney = math.NumToStrCtr(self.onceMoney);
        self.p_sb:Apd("总价:"):Apd(allCost):Apd("银两(单价"):Apd(onceMoney)
        :Apd("银两)");
    end
    self.moneySay.text = self.p_sb:ToStr();
end

function My:ExpextAll( num )
    local ALLCost = 0
    for i=self.extBuyStart,num do
        ALLCost=ALLCost+self.goldExtexp[i]
    end
    return ALLCost
end

function My:expMsg( isExp, extBuyStart, tFBInfo )
    self.isExp=isExp
    self.extBuyStart=extBuyStart
    self.goldExtexp=tFBInfo.goldExt
end

function My:Change(go)
    local name = go.name
    local num = 0;
    if name =="add" then
        num = self.NowBuyNum+1;
        if num>self.all then
            return;
        end
    else
        num = self.NowBuyNum-1;
        if num<0 then
            return;
        end
    end
    self:SetPosWithVal(num);
end

function My:Buy()
    local MyMoney=0;
    if self.NowBuyNum==0 then
        return;
    end
    if self.type==1 then
        MyMoney = RoleAssets.Gold+RoleAssets.BindGold;
        if self.allCost<MyMoney then
            FindBackMgr:sendBuy(self.id,self.type,self.NowBuyNum);
            self:Close();
        else
            UITip.Log("元宝不足");
        end
    else
        MyMoney = RoleAssets.Silver;
        if self.allCost<MyMoney then
            FindBackMgr:sendBuy(self.id,self.type,self.NowBuyNum);
            self:Close();
        else
            UITip.Log("银两不足");
        end
    end
end

function My:Close( )
    if LuaTool.IsNull(self.go)  then
       return
    end
    self.go:SetActive(false);
end

function My:Clear( )
    ObjPool.Add(self.p_sb);
    TableTool.ClearUserData(self);
    ObjPool.Add(self);
end

return My;