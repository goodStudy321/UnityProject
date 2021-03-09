--[[
套装
]]
require("UI/UISuit/BaseCell")
require("UI/UISuit/UISuitCell")
require("UI/UISuit/ItemTip")
require("UI/UISuit/SuitDetailTip")
require("UI/UISuit/ResolveTip")

UISuit=UIBase:New{Name="UISuit"}
local My = UISuit
local clickPart = nil
local clickSuit = nil

function My:InitCustom()
    local CG = ComTool.Get
	local TF = TransTool.FindChild
    local trans = self.root
    local U = UITool.SetBtnSelf
    local US = UITool.SetLsnrClick

    self.tog1=CG(UIToggle,trans,"Grid/Tog1",self.Name,false)
    self.tog2=CG(UIToggle,trans,"Grid/Tog2",self.Name,false)
    self.tog1Red=TF(trans,"Grid/Tog1/red")
    self.tog2Red=TF(trans,"Grid/Tog2/red")

    self.TipPanel=TF(trans,"TipPanel")
    self.eff=TF(trans,"eff")
    self.eff:SetActive(false)
    
    -----------------center
    self.center=TF(trans,"center").transform
    self.centerGrid =CG(UIGrid,self.center,"Grid",self.Name,false)
    self.fightLab=CG(UILabel,self.center,"fight/Label",self.Name,false)

    ------------------right
    local right = TF(trans,"right").transform
    self.ActiveBtn=TF(right,"ActiveBtn")
    self.ResolveBtn=TF(right,"ResolveBtn")
    self.UpBtn=TF(right,"UpBtn")
    self.maxRank=TF(right,"maxRank")

    self.nameLab=CG(UILabel,right,"nameLab",self.Name,false)
    self.consumeLab=CG(UILabel,right,"consumeLab",self.Name,false)
    self.consumeIcon=CG(UITexture,right,"consumeLab/icon",self.Name,false)
    self.attPanel=CG(UIPanel,right,"AttPanel",self.Name,false)
    self.att=TF(right,"AttPanel/att")
    local att = self.att.transform
    self.BaseAttLab=CG(UILabel,att,"BaseAttLab/Label",self.Name,false)
    self.SuitAttLab=CG(UILabel,att,"SuitAttLab",self.Name,false)
    self.partLab=CG(UILabel,att,"partLab",self.Name,false)
    self.suitLab=CG(UILabel,att,"suitLab",self.Name,false)
    self.titlePre=TF(att,"title")
    self.labPre=TF(att,"lab")

    -----------------tip
    local tip = TF(trans,"TipPanel").transform

    self.SuitDetailTip=ObjPool.Get(SuitDetailTip)
    self.SuitDetailTip:Init(TF(tip,"SuitDetailTip"))

    self.ItemTip=ObjPool.Get(ItemTip)
    self.ItemTip:Init(TF(tip,"ItemTip"))

    self.ResolveTip=ObjPool.Get(ResolveTip)
    self.ResolveTip:Init(TF(tip,"ResolveTip"))

    U(self.tog1,self.Attack,self,self.Name,false)
    U(self.tog2,self.Def,self,self.Name,false)
    U(self.ActiveBtn,self.OnActiveUp,self,self.Name,false)
    U(self.ResolveBtn,self.OnResolve,self,self.Name,false)
    U(self.UpBtn,self.OnActiveUp,self,self.Name,false)
    US(trans,"CloseBtn",self.Name,self.Close,self)
    US(trans,"center/DetailBtn",self.Name,self.OnDetailBtn,self)
    if not self.suitList then self.suitList={} end
    if not self.str then self.str=ObjPool.Get(StrBuffer) end
    if not self.AttList then self.AttList={} end
    if not self.suitDic then self.suitDic={} end
end

function My:OpenCustom()
    self:SetEvent("Add")
end

function My:SetEvent(fn)
    UISuitCell.eClick[fn](UISuitCell.eClick,self.ClickSuitCell,self)
    SuitMgr.eSuit[fn](SuitMgr.eSuit,self.OnSuit,self)
    UISuitCell.eLoadEnd[fn](UISuitCell.eLoadEnd,self.OnLoadEnd,self)
    SuitMgr.eRed[fn](SuitMgr.eRed,self.OnRed,self)
end

function My:ClickSuitCell(partId,obj)
    if clickPart then clickPart:IsClick(false) end
    obj:IsClick(true)
    clickPart=obj
    self:SuitAtt()
end

--套装升星或者激活事件
function My:OnSuit(bType,part,partId)
    if self.tp~=bType then return end
    self.eff:SetActive(false)
    self.eff:SetActive(true)
    local cell=self.suitList[part]
    local partData = SuitStarData[partId]
    cell.partId=partId
    cell.data=partData
    cell:UpData()

    self:SuitAtt()
    self:GetFight()
    self:CreateFxLine()
end

function My:OnLoadEnd()
    self.loadNum=self.loadNum+1
    local list = SuitMgr.suitInfo[self.tp]
    if self.loadNum==#list then 
        self.isend2=true
        if self.isend1==true and self.isend2==true then 
            self:CreateFxLine() 
            self:OnRed()
        end
    end
    self.centerGrid:Reposition()
end

function My:OnRed()
    if LuaTool.IsNull(self.root) then return end
    local dic1 = SuitMgr.rankRed1
    local dic2 = SuitMgr.rankRed2
    local tog1red = dic1["0"]
    self.tog1Red:SetActive(tog1red)
    local tog2red = dic2["0"]
    self.tog2Red:SetActive(tog2red)
    local dic = self.tp==1 and dic1 or dic2
    for i,v in ipairs(self.suitList) do
        v:IsRed(false)
    end
    for k,v in pairs(dic) do
        if k~="0" then 
            --local suit = SuitStarData[k]
            local cell = self.suitList[tonumber(k)]
            if cell then cell:IsRed(v) end
        end
    end
end

--分解
function My:OnResolve()
    self.ResolveTip:Open()
    self.ResolveTip:UpData(clickPart.partId)
end

--激活升阶
function My:OnActiveUp()
    local type=self.tp
    local sType=clickPart.data.sType
    --材料不足弹出材料获取界面
    if self.isenough==false then
        JumpMgr:ClearJumpDic()
        self.ItemTip:UpData(self.needId,type,sType)
        return
    end
    local suitNum,suitData=self:CheckIsSuit()
    if suitNum>0 then
        self.str:Dispose()
        self.str:Apd("升阶该部位后，[00FF00FF]"):Apd(suitData.suitName):Apd(suitNum):Apd("[-]件套将解除，战力可能降低，是否继续升阶？")
        MsgBox.ShowYesNo(self.str:ToStr(),self.YesCb,self)
        return
    end
    self:YesCb()
end

function My:YesCb()
    SuitMgr.ReqUpgradeStar(clickPart.data.id)
end

--检测当前部位是否组成套装，是就弹出提示
function My:CheckIsSuit()
    local data=clickPart.data
    if data.rank==0 then return 0,nil end
    local suitData=SuitAttData[tostring(data.suitId)]
    local attList = suitData.attList
    local type = self.tp
    local sType = data.sType
    local list=SuitMgr.suitInfo[type]
    local suitNum = 0
    for i,v in ipairs(attList) do
       local num = v.num
       if self.hasNum>=num then suitNum=num end
    end
    return suitNum,suitData
end

--套装详情
function My:OnDetailBtn()
    self.SuitDetailTip:Open()
    self.SuitDetailTip:UpData(self.tp)
end

function My:OpenTabByIdx(t1, t2, t3, t4)
    self:SwitchTg(t1)
end

function My:SwitchTg(tp)
    if tp==2 then 
        self:Def() 
        self.tog2.value=true
    else  
        self:Attack() 
        self.tog1.value=true
    end
end

--攻击套装
function My:Attack()
    self.tp=1
    self:UpData()
end

--防御套装
function My:Def()
    local isopen = self:IsOpen()
    if isopen==false then 
        self.tog1.value=true
        self.tog2.value=false
        return 
    end
    self.tp=2
    self:UpData()
end

function My:IsOpen()
    local global = GlobalTemp["134"]
    local lv = global.Value2[1]
    if User.instance.MapData.Level<lv then 
        UITip.Log("坐等"..lv.."级开启系统吧！")
        return false 
    end
end

--显示套装属性
function My:SuitAtt()
    local data=clickPart.data
    self.isMax=self:IsMaxRank(data.rank)
    local nextData=nil
    if self.isMax==false then
        nextData= SuitStarData[tostring(data.nextId)]
        if not nextData then iTrace.eError("xiaoyu","套装升星表为空 id: "..data.nextId)return end
    end

     --名字
    self.str:Dispose()
    local name=data.partName
    local rank=data.rank
    self.str:Apd("[F4DDBDFF]"):Apd(name)
    if rank == 0 then
        self.str:Apd(" [CC2500FF]("):Apd("未打造)[-]")
    else
        self.str:Apd(" ("):Apd(rank):Apd("阶)")
    end
    self.nameLab.text=self.str:ToStr()

    --消耗
    if nextData then self:ShowConsume(data,nextData) end

    --基础属性
    self.BaseAttLab.text=self:BaseAtt(data.attList,nextData)

    --套装属性
    local id=data.rank>0 and data.suitId or nextData.suitId
    self:GetSuitAtt(tostring(id))

    --按钮状态
    self:BtnState(data.rank)
end

function My:UpData()
    self:CreatePart()
    self:GetFight()
    self:CreateModel()
end

function My:CreateModel()
    if self.model then
        GbjPool:Add(self.model)
        self.model=nil
    end
    local path= User.MapData.Sex==1 and "P_Male_glow0"..self.tp or "P_Female_glow0"..self.tp  
    LoadPrefab(path,GbjHandler(self.SetPos,self))
end

function My:SetPos(go)
	local pos = Vector3.New(-305,-344,580) 
	local scale = Vector3.one*375
    local rota = Vector3.New(0,163,0)
    go.transform.parent=self.center
	go.transform.localPosition=pos
	go.transform.localScale=scale
    go.transform.localEulerAngles=rota
    self.model=go
    LayerTool.Set(go,19)
end

--套装连线
function My:CreateFxLine()
    for i,v in ipairs(self.suitList) do
        v:HideLine()
    end
    local type=self.tp
    local list = SuitMgr.suitInfo[type]
    for k,v in pairs(self.suitDic) do
        ListTool.Clear(v)
        self.suitDic[k]=nil
    end
    for i,v in ipairs(list) do
        local data = SuitStarData[v]
        local suitId=tostring(data.suitId)
        local idList = self.suitDic[suitId]
        if not idList then idList={} self.suitDic[suitId]=idList end
        idList[#idList+1]=data.part
    end
    for suitId,v in pairs(self.suitDic) do
        local suitData=SuitAttData[suitId]
        local att=suitData.attList
        local isSuit = false
        if att then
            local minNum=att[1].num
            if #v>=minNum then isSuit=true end
        end
        if isSuit==false then ListTool.Clear(v) self.suitDic[suitId]=nil end
    end

    local tp1,tp2=0,0
    for k,v in pairs(self.suitDic) do
        local sType = SuitAttData[k].sType
        local tp=nil
        if sType==1 then 
            tp1=tp1+1
            tp=tp1
        else
            tp2=tp2+1
            tp=tp2
        end
        local minPart = v[1]
        local maxPart = v[#v]
        for i=minPart,maxPart do
            local cell = self.suitList[i]
            local iss = i~=maxPart and true or false
            local isexit = self:IsExitPart(i,v)
            if tp>1 then 
                cell:ShowLeftLine(isexit,iss) 
            else 
                cell:ShowRightLine(isexit,iss) 
            end
        end
    end
end

function My:IsExitPart(part,list)
    local isexit = false
    for i,v in ipairs(list) do
        if v==part then isexit= true break end
    end
    return isexit
end

function My:CreatePart()
    self:CleanData()
    self.loadNum=0
    self.isend1=false
    self.isend2=false
    local bType=self.tp
    local list=SuitMgr.suitInfo[bType]
    if #SuitMgr.suitInfo==0 then iTrace.eError("xiaoyu","套装信息为空")return end
    if not list then iTrace.eError("xiaoyu","套装信息为空 type: "..tostring(type))return end
    for i,v in ipairs(list) do
        local cell = ObjPool.Get(UISuitCell)
        if i==1 then 
            cell.isClick=true 
            clickPart=cell 
        end
        cell:Init(self.centerGrid,v)
        if i==1 then 
            self:SuitAtt() 
        end
        self.suitList[i]=cell
    end
    self.isend1=true
    if self.isend1==true and self.isend2==true then 
        self:CreateFxLine() 
        self:OnRed()
    end
end

function My:ShowConsume(curData,nextData)
    self.str:Dispose()
    local data = nextData
    local need = nextData.needList
    local needId=nextData.needList[1]
    self.needId=needId
    local num=need[1]==curData.needList[1] and need[2]-curData.needList[2] or need[2] 

    local has = PropMgr.TypeIdByNum(needId)
    self.isenough=has>=num
    local color = self.isenough==true and "[F4DDBDFF]" or "[CC2500FF]"
    self.str:Apd(color):Apd(has):Apd("/"):Apd(num)
    self.consumeLab.text=self.str:ToStr()
    local item = ItemData[tostring(needId)]
    AssetMgr:Load(item.icon,ObjHandler(self.LoadIcon,self))
end

function My:LoadIcon(obj)
    self.consumeIcon.mainTexture=obj
end

function My:BaseAtt(attList,nextData)
    local nextAtt = nextData~=nil and nextData.attList or nil
    self.str:Dispose()
    for i,v in ipairs(attList) do
        if StrTool.IsNullOrEmpty(self.str:ToStr())~=true then 
            self.str:Line() 
        end
        local id = v.id
        local val = v.val
        local name = PropTool.GetNameById(id)
        local va = PropTool.GetValByID(id,val)
        if nextAtt then 
            local nextVal = nextAtt[i].val
            local lerpVa = PropTool.GetValByID(id,nextVal-val)
            self.str:Apd("[F4DDBDFF]"):Apd(name):Apd("+"):Apd(va):Apd("[-]   [00FF00FF]+"):Apd(lerpVa):Apd("[-]")
        else
            self.str:Apd("[F4DDBDFF]"):Apd(name):Apd("+"):Apd(va)
        end
       
    end
    return self.str:ToStr()
end

--套装属性
function My:GetSuitAtt(suitId)
    local bType=self.tp
    local suitData = SuitAttData[suitId]
    if not suitData then iTrace.eError("xiaoyu","套装属性表为空  suitId: "..suitId) return end
    local hasNum = clickPart.data.rank==0 and 0 or self:GetPartStarNum()
    self.hasNum=hasNum
    local attList=suitData.attList
    local maxNum =attList[#attList].num

    self.str:Dispose()
    self.str:Apd("[F39800FF]"):Apd(suitData.rank):Apd("阶"):Apd(suitData.suitName):Apd(" [-][00FF00FF]("):Apd(hasNum):Apd("/"):Apd(maxNum):Apd(")")
    self.SuitAttLab.text=self.str:ToStr()

    --部位
    self.str:Dispose()
    local partList = SuitMgr.suitInfo[bType]
    local num=0
    for i,v in ipairs(partList) do
        local data = SuitStarData[v]
        if data.sType==clickPart.data.sType then 
            num=num+1
            local part=data.part
            local color="[B2B2B2FF]"
            if data.rank==clickPart.data.rank and data.rank>0 then color="[00FF00FF]" end
            self.str:Apd(color):Apd(data.rank):Apd("阶"):Apd(SuitMgr.partList[part])
            if num==3 then
                self.str:Line()
            else
                self.str:Apd("      ")
            end
        end
    end
    self.partLab.text=self.str:ToStr()

    self.str:Dispose()
    local att = nil
    for i,v in ipairs(attList) do
        local num=v.num
        local list=v.val
        local color=hasNum>=num and "[00FF00FF]" or "[B2B2B2FF]"
        self.str:Apd(color):Apd(num):Apd("件套：")
        self.str:Line()
        att=hasNum>=num and list or att
        for i1,v1 in ipairs(list) do
            local name = PropTool.GetNameById(v1.id)
            local val = PropTool.GetValByID(v1.id,v1.val) 
            self.str:Apd("    "):Apd(name):Apd(" + "):Apd(val)
            local apdLine=true 
            if i==#attList and i1==#list then apdLine=false end
            if apdLine==true then self.str:Line() end
        end
    end
    self.suitLab.text=self.str:ToStr()
end

--整个套装的战力
function My:GetFight()
    -- local fight = 0
    -- if not self.suitDic then self.suitDic={} end
    -- TableTool.ClearDic(self.suitDic)
    -- local type = self.tp
    -- local list = SuitMgr.suitInfo[type]
    -- for i,v in ipairs(list) do
    --     local data=SuitStarData[v]
    --     local att = data.attList
    --     for i,v in ipairs(att) do
    --         local f = PropTool.PropFight(v.id,v.val)
    --         fight=fight+f
    --     end
    --     local suitId=data.suitId
    --     local num = self.suitDic[tostring(suitId)]
    --     num=not num and 1 or num+1
    --     self.suitDic[tostring(suitId)]=num
    -- end

    -- for k,v in pairs(self.suitDic) do
    --     local suitData = SuitAttData[k]
    --     local attList = suitData.attList
    --     if attList then 
    --         for i1,v1 in ipairs(attList) do
    --             if v>=v1.num then 
    --                 local num=v1.num 
    --                 local att=v1.val 

    --                 for i2,v2 in ipairs(att) do
    --                     local f=PropTool.PropFight(v2.id,v2.val)
    --                     fight=fight+f
    --                 end
    --             end
    --         end
    --     end
    -- end
    -- self.fightLab.text=tostring(math.ceil( fight ))

    self.fightLab.text=tostring(User.MapData:GetFightValue(40))
end

function My:BtnState(rank)
    self.ActiveBtn:SetActive(rank==0)
    self.ResolveBtn:SetActive(rank>0)
    self.UpBtn:SetActive(rank>0 and self.isMax==false)
    self.maxRank:SetActive(self.isMax==true)
    self.consumeLab.gameObject:SetActive(self.isMax==false)
    self.consumeLab.transform.localPosition=rank==0 and Vector3.New(-8.1,-254,0) or Vector3.New(63,-254,0)
end

function My:IsMaxRank(rank)
    local bType=self.tp
    local list = SuitMgr.suitList[bType]
    local part=clickPart.data.part
    local rankList=list[part]
    local max=rankList[#rankList]
    local maxData=SuitStarData[max]
    return rank==maxData.rank
end

function My:GetPartStarNum()
    local rank = clickPart.data.rank
    local sType=clickPart.data.sType
    local type = self.tp
    local num = 0
    local list = SuitMgr.suitInfo[type]
    for i,v in ipairs(list) do
        local data = SuitStarData[v]
        if data.rank==rank and data.sType==sType then num=num+1 end
    end
    return num
end

function My:CleanData()
    ListTool.ClearToPool(self.suitList)
end

function My:DisposeCustom()
    self:SetEvent("Remove")
    if self.str then ObjPool.Add(self.str) self.str=nil end
    if self.ItemTip then ObjPool.Add(self.ItemTip) self.ItemTip=nil end
    if self.SuitDetailTip then ObjPool.Add(self.SuitDetailTip) self.SuitDetailTip=nil end
    if self.ResolveTip then ObjPool.Add(self.ResolveTip) self.ResolveTip=nil end
    self:CleanData()
    JumpMgr.eOpenJump()
end

function My:Clear()
    self:Close()
end


return My