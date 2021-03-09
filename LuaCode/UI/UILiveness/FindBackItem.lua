FindBackItem=Super:New{Name="FindBackItem"};
local My = FindBackItem;
function My:Ctor()
    self.cellLst={};
end

function My:Init(go,id)
    self.root=go.transform;
    local root = self.root;
    local tip = self.Name;
    local CG = ComTool.Get;
    local TF = TransTool.Find
    local TFC = TransTool.FindChild;
    local US = UITool.SetBtnSelf;
    self.tFBInfo=tFindBack[id];
    self.IsTimes= self.tFBInfo.IsTimes==1
    self.tit=CG(UILabel,root,"tit",tip);
    self.fbBtn=TFC(root,"fbstation/fbBtn",tip);
    self.fbBtnLab=CG(UILabel,root,"fbstation/fbBtn/find",tip);
    US(self.fbBtn.transform,self.toTip,self);
    self.tbFBTxt=CG(UILabel,root,"fbstation/tbFB",tip);
    self.tbFB=self.tbFBTxt.transform.gameObject;
    --买方式
    local cstRoot = TF(root,"coststation",tip);
    self.goldGO=TFC(cstRoot,"gold",tip);
    self.goldTxt=CG(UILabel,self.goldGO.transform,"Label",tip);
    self.sliverGO=TFC(cstRoot,"sliver",tip);
    self.sliverTxt=CG(UILabel,self.sliverGO.transform,"Label",tip);
    --奖励格子
    self.grid=CG(UIGrid,root,"sv/Grid",tip);
    --调用
    self:GetMsg(id);
    self:doMsg( );
   
    self:lsnr("Add");
end
--初始化数据
function My:doMsg( )
    local num = UIFindBack.type;
    self:doTitle(num);
    self:AddRWD();
    self.tbFBTxt.text=string.format( "剩余%s次额外次数可用绑元找回",self.ext);
    self:fbstation(num);
    self.sliverTxt.text=self.silver;
    self:doGold( );
    self:ChangeStage(num)
end
--当前模式1绑元2银两
function  My:ChangeStage(num)
    self.type=num;
    if num==1 then
        self.goldGO:SetActive(true);
        self.sliverGO:SetActive(false);
        self:ChangeRwd(1);
    else
        self.goldGO:SetActive(false);
        self.sliverGO:SetActive(true);
        self:ChangeRwd(0.5);
    end
    self:doTitle(num);
    self:fbstation(num )
    self:doBtnLab( )    
end

--购买成功
function My:BuySuc( )
    local FL = FindBackMgr.FindList[self.id];
    self.bas=FL.bas;
    self.ext=FL.ext;
    local num = UIFindBack.type;
    self:doTitle(num);
    self:fbstation(num,true);
    self:doGold( );
    local TFI = self.tFBInfo;   
    if  self.isExp then
        self.goldExt=TFI.goldExt[self.extBuyStart]; 
    else
        self.goldExt=TFI.goldExt[1]; 
    end
end

function My:doGold( )
    if self.bas>0 and self.goldTxt.text~=self.gold  then
        self.goldTxt.text=self.gold;
    elseif self.goldTxt.text~=self.gold then
        self.goldTxt.text=self.goldExt;
    end
end

--监听
function My:lsnr(fun)
    UIFindBack.eChange[fun](UIFindBack.eChange,self.ChangeStage,self);
end

--信息整理
function My:GetMsg(id)
       --推送的信息
   local FL = FindBackMgr.FindList[id];
   self.id=FL.id;
   self.bas=FL.bas;
   self.ext=FL.ext == nil and 0 or FL.ext;
   self.extBuyStart=FL.extBuyStart 
   --表信息
   self.isExp=false
   if  self.id==1 then
    self.isExp=true
   end
   local TFI = self.tFBInfo;   
    local lv = User.instance.MapData.Level;
    self.name = TFI.name;
    self.copyID = TFI.name;
    self.rwdLst=TFI.cell;
    self.silver=TFI.silver;
    self.gold=TFI.gold;
    if  self.isExp then
        self.goldExt=TFI.goldExt[self.extBuyStart]; 
    else
        self.goldExt=TFI.goldExt[1]; 
    end
    local cellexp = self.rwdLst[1];
    if  cellexp.id~=nil and cellexp.id==100  then
        if  cellexp.num==0 then
            local actexp = LvCfg[tostring(lv)].exp;
            if actexp==nil then
                iTrace.Error("H 活动经验 需要配置 ","当前等级为= "..lv)
                actexp=1000*lv+1050;
            end
            local exp= actexp*TFI.exp/10000
            self.exp=exp;
            self.rwdLst[1].num=exp;
        else
            self.exp=num;
        end
    end
   local copy = TFI.copyID;
   if copy~=0 then
        self.iscopy=true;
        local type = CopyTemp[tostring(copy)].type;
        copy = FindBackMgr.CopyLst[type];
        if copy==nil then
            copy=TFI.copyID;
        end
        local rwdLst = CopyTemp[tostring(copy)].findRED;
        if rwdLst==nil  then
            rwdLst={};
        end
        self.copyRwd=rwdLst;
        for i=1,#rwdLst do
            table.insert( self.rwdLst,rwdLst[i]);
        end
   end

end

--添加奖励
function My:AddRWD( )
    soonTool.AddItemCell(self.rwdLst,self.grid,self.cellLst,0.85);
end

function My:doTitle(num)
   local text = "ss";
    if num==2 or self.ext==0 then
        text=string.format( "%s(可找回%s次)",self.name,self.bas);
    elseif num==1 and self.ext>0 then
        local p_sb = ObjPool.Get(StrBuffer);
        p_sb:Apd(self.name):Apd("[F4DDBDFF](可找回"):Apd(self.bas)
        :Apd("次，额外次数"):Apd(self.ext):Apd("次)[-]");
        text = p_sb:ToStr();
        ObjPool.Add(p_sb);
    end

    self.titTXT =text;
    self.tit.text=text;
end

function My:doBtnLab( )
    if self.IsTimes  then
        self.fbBtnLab.text="次数找回"
        self.sliverGO:SetActive(false)

    else
        self.fbBtnLab.text="资源找回"
        -- self.sliverGO:SetActive(true)
    end

end

--改变奖励数量
function My:ChangeRwd(num)
    for i=1,#self.rwdLst do
        local inf = self.rwdLst[i];
        local change = inf.num*num;
        change = change<2 and "" or change;
        self.cellLst[i]:UpLab(change);
    end
end

--额外和找回true为找回
function My:fbstation(num,b )
    if (self.bas==0 or  self.IsTimes) and num==2  then
        self.fbBtn:SetActive(false);
        self.tbFB:SetActive(true);
        if self.IsTimes then
            self.tbFBTxt.text=string.format( "可用绑元\n找回次数",self.ext);
        elseif  b then
            self.tbFBTxt.text=string.format( "剩余%s次额外次数可用绑元找回",self.ext);
                
        end
    else
        self.fbBtn:SetActive(true);
        self.tbFB:SetActive(false);
    end
end

--弹出提示
function My:toTip()
    local num = self.type;
    UILiveness.zh.FBTobj:expMsg(self.isExp, self.extBuyStart, self.tFBInfo)
    if num==1 then
        UILiveness.zh.FBTobj:Open(self.id,num,self.titTXT,self.bas,self.ext,self.gold,self.goldExt);
    else
        UILiveness.zh.FBTobj:Open(self.id,num,self.titTXT,self.bas,0,self.silver,0);
    end
end

function My:Dispose()
    self:lsnr("Remove");
    soonTool.desCell(self.cellLst);
    if  self.iscopy==true then
        local rwdLst=self.copyRwd;
        for i=1,#rwdLst do
            table.remove( self.rwdLst,#self.rwdLst);
        end
        self.iscopy=false;
    end
    TableTool.ClearUserData(self);
end

function My:Clear( )
    self:Dispose()
    soonTool.desCell(self.cellLst);
end

return My; 