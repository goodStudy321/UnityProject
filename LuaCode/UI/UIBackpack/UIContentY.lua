--[[
背包循环利用的格子竖向
]]
require("UI/UIBackpack/UIContentX")
UIContentY=Super:New{Name="UIContentY"}
local My = UIContentY
My.btnList={"Equip","Sale","Use","Compound","Inset","PutIn","GetOut","PutAway","sealInsert","Renew","Strengthen",
            "Buy","SoldOut","Exchange","Donate","EseChoose","Choose","GetWay"}
My.btnNameList = {Equip="装备",Sale="出售",Use="使用",Compound="合成",Inset="镶嵌",PutIn="放入",GetOut="取出",PutAway="上架",
                sealInsert="镶嵌",Renew="续费",Strengthen="强化",Buy="购买",SoldOut="下架",Exchange="兑换",Donate="捐献",
                EseChoose="取消选择",Choose="选择",GetWay="获取途径"}

local btn={}

function My:Ctor()
    self.dic={}
    self.realIndexDic={}
end

function My:Init(go,tp,isBag,PreGrid, delayShowEff)
    self.mOpen = false;

    self.tp=tp
    self.isBag=isBag
    self.PreGrid=PreGrid
    local TF=TransTool.FindChild
    local CG = ComTool.Get
    local trans = go.transform
    self.trans=trans
    
    self.UIContent=CG(UIWrapContent,trans,"Panel/UIWrapContent",self.Name,false)
    self.sortBtn = TF(self.trans,"SortOut")
    self.sortLab=CG(UILabel,self.sortBtn.transform,"Label",self.Name,false)
    UITool.SetLsnrSelf(self.sortBtn,self.SortOut,self,self.Name)
    self:InitDATA() 
    self:InitCustom() 

    self.timer = ObjPool.Get(iTimer)
	self.timer.invlCb:Add(self.InvlCb, self)
    self.timer.complete:Add(self.Cb, self)

    self.delayShowEff = delayShowEff;
end

function My:InitCustom( ... )
    self:Create(4,6)
end

function My:SortOut()
    PropMgr.isSort=true
    PropMgr.tp=self.tp
	PropMgr.ReqMerge(self.tp)
end

function My:SetEvent(fn)
    PropMgr.eAdd[fn](PropMgr.eAdd,self.OnAdd,self)
	PropMgr.eRemove[fn](PropMgr.eRemove,My.OnRmove,self)
    PropMgr.eUpNum[fn](PropMgr.eUpNum,My.OnUpNum,self)    
    PropMgr.eSort[fn](PropMgr.eSort,self.OnSort,self)
    PropMgr.eGrid[fn](PropMgr.eGrid,self.UpGrid,self)
    PropMgr.eUpFight[fn](PropMgr.eUpFight,self.UpdateView,self)
    --PropMgr.eUpdate[fn](PropMgr.eUpdate,self.UpdateView,self)
    UIItemCell.eClick[fn](UIItemCell.eClick,self.OnClickCell,self)
end

function My:InitDATA()
    self.maxNum = BagGrid[tostring(self.tp)].maxNum
end

function My:OnClickCell(name,index)
    if not index then return end 
    local cell = self:GetCell(index)
    if not cell then return end
    local tp = cell.tp
    if self.isBag==true and cell.isBag~=true then return end
    if tp~=self.tp then return end
    local islock = cell.islock
    if islock==true then --判断是否是锁定状态，是的话点开开启格子界面
        UIMgr.Open(AddCellPanel.Name,self.OpenCb,self)
    end
end

function My:OpenCb(name)
    local ui=UIMgr.Get(name)
    if ui then
        ui:UpData(self.tp)
    end
end

function My:UpCellData(tb, delayShowEff)
    local index = tb.index
    local cell=self:GetCell(index)
    if cell then self:RefreshCell(tb,cell, delayShowEff) end
end

function My:RefreshCell(tb,cell, delayShowEff)
    local tp = self.tp
    ListTool.Clear(btn)
    local compare=false
    local index=tb.index
    local isSale=true
    if tp==1 and self.isBag==true then
        local item = ItemData[tostring(tb.type_id)]
        if item==nil then iTrace.eError("xiaoyu","道具表为空  id: ".. tb.type_id)return end 
        local uFx=item.uFx
        if uFx ==1 or uFx==28 then --装备
            btn[#btn+1]=My.btnList[1]
            if uFx==28 and item.id~=40009 then btn[#btn+1]=My.btnList[10] end
        elseif uFx==31 then --宝石
            local jump = item.jump
            if jump then btn[#btn+1]=My.btnList[4] end
            btn[#btn+1]=My.btnList[5]
        elseif uFx==77 then --纹印
            local jump = item.jump
            if jump then btn[#btn+1]=My.btnList[4] end
            btn[#btn+1]=My.btnList[9]
        else --道具
            local use=item.canUse or 0
            if use==1 then btn[#btn+1]=My.btnList[3] end
        end
        compare=true
        local price=item.price or 0
        if price~=0 then 
            if uFx==69 then
                self:OpenWord()
            else
                btn[#btn+1]=My.btnList[2] 
            end
        end
    elseif tp==1 then
        btn[#btn+1]=My.btnList[6] 
    elseif tp==2 then
        btn[#btn+1]=My.btnList[7]
    elseif tp==3 then 
        btn[#btn+1]=My.btnList[7]
    elseif tp==4 then 
        btn[#btn+1]=My.btnList[7]
    end

    cell:TipData(tb,tb.num,btn,compare, nil, delayShowEff)
    cell:UpBind(tb.bind)
    cell:SetDoubleClick(self.tp,self.isBag)
    if tp<3 then        
        cell:IconUp(tb.isUp)
        cell:IconDown(tb.isDown)
    end
    cell.index=tb.index
    cell.islock=false
end

-- 开服集字道具操作
function My:OpenWord()
    local isOpen = LivenessInfo:GetActInfoById(1005)
    local info = LivenessInfo.xsActivInfo["1005"]
    if  isOpen == false then
        btn[#btn+1]=My.btnList[2]
        return
    end
    local now = TimeTool.GetServerTimeNow()*0.001
    if info and info.eTime < now then
        btn[#btn+1]=My.btnList[2]
    end
end

function My:UpDataList(indexStart)
    local dic = PropMgr.tbAll["tp"..self.tp]
    local idList = PropMgr.sortIdDic[self.tp]
    local indexEnd = indexStart+3
    if indexEnd+1>self.maxNum then indexEnd=self.maxNum-1 end
    for i=indexStart,indexEnd do
        local id = idList[i+1]
        local cell=self:GetCell(i)
        cell.trans.gameObject.name=tostring(i)
        if id and dic[tostring(id)]~=nil then --有数据
            local tb=dic[tostring(id)]
            if tb then self:RefreshCell(tb,cell, self.delayShowEff) end
        else
            cell:Clean()
            self:ShowLockCell(cell,i)
            cell.index=i
        end
    end
end

function My:UpdateViewTexture()
    self:UpdateView()
end

function My:UpdateView()
    for i,rIndex in pairs(self.realIndexDic) do
        local startIndex = rIndex*self.Xnum
        self:UpDataList(startIndex)
    end
end

function My:UpGrid(bagid,add)
    if self.tp~=bagid then return end
    local max=PropMgr.cellNumDic[tostring(self.tp)]
    for i=1,add do
        local index=max-i
        local cell=self:GetCell(index)
        if cell then cell:Clean() end
    end
end

function My:Create(Xnum,Ynum)
    self.UIContent.minIndex=-(self.maxNum/4-1)
    self.UIContent.maxIndex=0

    self.Xnum=Xnum
    self.Ynum=Ynum
    for i=1,Ynum do
        local go = GameObject.Instantiate(self.PreGrid)
 		go.name=tostring(i)
        go:SetActive(true)
        go.transform.parent=self.UIContent.transform
        go.transform.localPosition=Vector3.New(0,-(i-1)*90,0)
        go.transform.localScale=Vector3.one        
        local contentX=ObjPool.Get(UIContentX)
        contentX:Init(go)
        contentX:Create(Xnum,self.tp,self.isBag)
        self.dic[tostring(i-1)]=contentX
    end
    --self.UIContent:Reset()
    self.UIContent.onInitializeItem=function(go,index,realIndex) self:OnUpdateItem(go,index,realIndex) end
end

function My:OnUpdateItem(go,index,realIndex)
    local list = self.realIndexDic
    local rIndex = realIndex<0 and realIndex*-1 or realIndex
    list[tostring(index)]=rIndex
    self:UpDataList(self.Xnum*rIndex) 
end

function My:GetCell(index)
	local isExist=self:IsExist(index)
    if isExist==false then return nil end    local w,h = self:GetXY(index)
    local contentX = self.dic[tostring(self:GetRealH(h))]
    local cell = contentX.dic[tostring(w)]
    return cell
end

function My:ShowLockCell(cell,index)
    local num = PropMgr.cellNumDic[tostring(self.tp)]
    if index+1>num then 
        cell:Lock(1)
        cell.islock=true
    else
        cell:Lock(0.01) 
        cell.islock=false
    end
end

function My:IsExist(index)
    local isExist = false
    local data = nil
    for i,rIndex in pairs(self.realIndexDic) do
        local max = self.Xnum*rIndex+self.Xnum-1
        local min = self.Xnum*rIndex
        if index>=min and index<=max then 
            isExist=true 
            data=kv
            break 
        end
    end
    return isExist,data
end

function My:GetXY(index)
    local w,h = nil
    local y,x = math.modf(index/self.Xnum )
    h = y
    w = index - y*self.Xnum
    return w,h
end

function My:GetRealH(h)
    local y,x=math.modf( h/self.Ynum )
    local realH = h-y*self.Ynum
    return realH
end

function My:UpData(tb)
   
end

function My:InvlCb()
    if LuaTool.IsNull(self.trans) then return end
	if not self.time then return end
	self.time=self.time-1
	self.sortLab.text=tostring(self.time)
end

function My:Cb()
    if LuaTool.IsNull(self.trans) then return end
	self:SortState(false)
end

function My:CleanData()
    -- body
end

function My:Open()
    self.mOpen = true;
    self:SetEvent("Add")
end

function My:Close()
    self:SetEvent("Remove")
    self.mOpen = false;
end

function My:Dispose()
    self:SortState(false)
    if self.timer then
        self.timer:AutoToPool()
        self.timer=nil 
    end
    TableTool.ClearDicToPool(self.dic)
    TableTool.ClearDic(self.realIndexDic)
    self.delayShowEff = nil;
    self.mOpen = false;
end

---------------------------协议监听
function My:OnAdd(tb,action,tp)
    if self.tp~=tp then return end
    self:UpCellData(tb, self.delayShowEff)
end

function My:OnRmove(id,tp,type_id,action,index)
    if self.tp~=tp then return end
    local cell = self:GetCell(index)
    if cell then cell:Clean() end
end

function My:OnUpNum(tb,tp,num,action)
	if self.tp~=tp then return end
    local cell = self:GetCell(tb.index)
    if cell then cell:UpLab(tb.num) end
end
function My:OnSort(tp)
    if self.tp~=tp then return end

    self.time=5
    self.timer.seconds=self.time
    self.sortLab.text=tostring(self.time)
	self.timer:Start()
    self:SortState(true,5)
    local text=nil
    if self.tp==1 then text="已整理背包"
    else text="已整理仓库" end
    UITip.Log(text)
    
    self:UpdateView()
end

function My:SortState(state,time)
    local text=nil
    if self.isBag==true and self.tp==1 then text="整理"
    elseif self.tp==1 then text="背包整理"
    elseif self.tp==2 then text="仓库整理"
    elseif self.tp==3 or self.tp==4 then text="整理"  end
	if(state==true)then
        self.sortLab.text=tostring(time)	
        UITool.SetGray(self.sortBtn,false)	
	else
        self.sortLab.text=text
        UITool.SetNormal(self.sortBtn)	
    end
end

---/// LY add begin

function My:Update()
    if self.mOpen == nil or self.mOpen == false then
        return;
    end
    
    for k, contentX in pairs(self.dic) do
        contentX:Update();
    end
end

---/// LY add end


--------------------------------------