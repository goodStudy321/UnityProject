--[[
背包/仓库 创建，整理，删除
--]]
local AssetMgr=Loong.Game.AssetMgr
CellUpdate=Super:New{Name="CellUpdate"}
local My=CellUpdate
local CG = ComTool.Get

function My:Ctor()
    self.goList={}
    self.dic={}
    self.idDic={}
end

--@isBag:是否是背包（不是仓库背包，默认可不填）
--@tp:1：仓库背包 2：个人仓库 3：寻宝临时仓库 4：许愿池仓库 8：通天塔活动仓库
function My:Init(go)
	local TF=TransTool.FindChild
	local U=UITool.SetBtnClick
	self.trans=go.transform

    self.panel=CG(UIPanel,self.trans,"Panel",self.Name,false)
    self.POS=self.panel.transform.localPosition
	self.grid=CG(UIGrid,self.trans,"Panel/Grid",self.Name,false)
    self.grid.onCustomSort=function(a,b) return self:SortName(a,b)end
    self.sortBtn = TF(self.trans,"SortOut").transform
    self.bg=self.sortBtn:GetComponent(typeof(UISprite))
	self.lab=CG(UILabel,self.sortBtn.transform,"Label",self.Name,false)
	self.box=self.sortBtn:GetComponent(typeof(UnityEngine.BoxCollider))
    UITool.SetLsnrSelf(self.sortBtn,self.SortOut,self,self.Name)

    self:CheckBtn()
    self:AddE()

    self.timer = ObjPool.Get(iTimer)
	self.timer.invlCb:Add(self.InvlCb, self)
    self.timer.complete:Add(self.Cb, self)
    
    self.numIndex=-1
end

function My:AddE()
	PropMgr.eAdd:Add(self.OnAdd,self)
	PropMgr.eRemove:Add(self.OnRemove,self)
	PropMgr.eUpNum:Add(self.OnUpNum,self)
	PropMgr.eClean:Add(self.OnClean,self)
    PropMgr.eSort:Add(self.Sort,self)
    PropMgr.eGrid:Add(self.OnGrid,self)
    PropMgr.eUpFight:Add(self.OnUpFight,self)
end

function My:RemoveE()
	PropMgr.eAdd:Remove(self.OnAdd,self)
	PropMgr.eRemove:Remove(self.OnRemove,self)
	PropMgr.eUpNum:Remove(self.OnUpNum,self)
	PropMgr.eClean:Remove(self.OnClean,self)	
    PropMgr.eSort:Remove(self.Sort,self)  
    PropMgr.eGrid:Remove(self.OnGrid,self)
    PropMgr.eUpFight:Remove(self.OnUpFight,self)
end

function My:SortOut()
    PropMgr.isSort=true
    PropMgr.tp=self.tp
	PropMgr.ReqMerge(self.tp)
end

function My:InitData(tp,isBag)
    self.tp=tp
    self.isBag=isBag
    self.tbDic=nil
    if self.tp==1 then self.tbDic=PropMgr.tbDic
    elseif self.tp==2 then self.tbDic=PropMgr.tb2Dic
    elseif self.tp==3 then self.tbDic=PropMgr.tb3Dic
    elseif self.tp==4 then self.tbDic=PropMgr.tb4Dic
    elseif self.tp==8 then self.tbDic=PropMgr.tb8Dic
    end

    self.max = PropMgr.cellNumDic[tostring(self.tp)]
    local num = BagGrid[tostring(self.tp)].maxNum
	for i=1,num do
        self:CreateCell(i)
    end	
    self.grid:Reposition()
    
    for k,v in pairs(self.tbDic) do
        self:OnAdd(v,0,self.tp)
    end
end

function My.SortGo(a,b)
    return tonumber(a.name)<tonumber(b.name)
end

--==============================--
--desc:监听协议事件
--time:2018-06-22 07:21:22
--@tb:道具结构
--@action:服务端下发的宏定义
--@btn:需要显示的按钮名字列表
--@compare:是否需要跟身上已穿戴装备进行对比
--@return 
--==============================-----------
-- local equipBtn = {"Equip","Sale"}
-- local propBtn = {"Sale","Use"}
-- local gemBtn = {"Compound","Inset"}
-- local tp1={"PutIn"}
-- local tp2={"GetOut"}

local btnList={"Equip","Sale","Use","Compound","Inset","PutIn","GetOut","PutAway","sealInsert","Renew"}
local btn={}

function My:OnAdd(tb,action,tp)
    if tp~=self.tp then return end
    ListTool.Clear(btn)
    local compare=false
    local index=tb.index
    local go=self.goList[index+1].gameObject
    local eff = CG(UISprite,go.transform,"eff",self.Name,false)
    eff.alpha=0.004
    local cell=ObjPool.Get(UIItemCell)
    cell.isInitLoadPool=true
    cell.index=tb.index
    cell:Init(go)
    cell.trans.name=tostring(index)
    if tp==1 and self.isBag==true then
        local item = ItemData[tostring(tb.type_id)]
        if item==nil then iTrace.eError("xiaoyu","道具表为空  id: ".. tb.type_id)return end 
        local uFx=item.uFx
        if uFx ==1 or uFx==28 then --装备
            local price=item.price or 0
            btn[#btn+1]=btnList[1]
            if price~=0 then btn[#btn+1]=btnList[2] end
            if uFx==28 then btn[#btn+1]=btnList[10] end
        elseif uFx==31 then --宝石
            local jump = item.jump
            if jump then btn[#btn+1]=btnList[4] end
            btn[#btn+1]=btnList[5]
        elseif uFx==77 then --纹印
            local jump = item.jump
            if jump then btn[#btn+1]=btnList[4] end
            btn[#btn+1]=btnList[9]
        else --道具
            local use=item.canUse or 0
            local price=item.price or 0
            if use==1 then btn[#btn+1]=btnList[3] end
            if price~=0 then
                if uFx == 69 then
                    self:OpenWord()
                else
                    btn[#btn+1]=btnList[2]
                end
            end
        end
        compare=true
        -- local sec = item.SecType or 0
        -- if sec~=0 then btn[#btn+1]=btnList[8] end
    elseif tp==1 then
        btn[#btn+1]=btnList[6] 
    elseif tp==2 then
        btn[#btn+1]=btnList[7]
    elseif tp==3 then 
        btn[#btn+1]=btnList[7]
    elseif tp==4 then 
        btn[#btn+1]=btnList[7]
    elseif tp == 8 then
        btn[#btn+1]=btnList[7]
    end
    cell:TipData(tb,tb.num,btn,compare)
    cell:UpBind(tb.bind)
    if tp<3 then        
        cell:IconUp(tb.isUp)
        cell:IconDown(tb.isDown)
    end
    self.dic[tostring(tb.id)]=cell
    self.idDic[cell.trans.name]=tb.id
    if (tp==1 or tp==2) and not self.isBag then 
        cell.isTip=false
        UIEventListener.Get(go).onDoubleClick = function(go) self:OnDoubleClick(go) end 
    end
end

function My:OnRemove(id,tp)
    if tp~=self.tp then return end
    local cell=self.dic[tostring(id)]
    UIEventListener.Get(cell.trans.gameObject).onClick=nil
    UIEventListener.Get(cell.trans.gameObject).onDoubleClick=nil
    self.idDic[cell.trans.name]=nil
    cell.index=nil
    ObjPool.Add(cell)
	self.dic[tostring(id)]=nil
end

function My:OnUpNum(tb,tp)
    if tp~=self.tp then return end
    local cell=self.dic[tostring(tb.id)]
    cell:UpData(tb.type_id,tb.num)
    cell:IconUp(tb.isUp)
    cell:IconDown(tb.isDown)
    cell.index=tb.index
end

function My:OnClean(tp)
    if tp~=self.tp then return end
    for k,v in pairs(self.dic) do
        UIEventListener.Get(v.trans.gameObject).onClick=nil
        UIEventListener.Get(v.trans.gameObject).onDoubleClick=nil
        v.isTip=nil
        ObjPool.Add(v)
        self.dic[k]=nil
    end
    TableTool.ClearDic(self.idDic)
end

function My:Sort(tp)
    if tp~=self.tp then return end
	for k,v in pairs(self.tbDic) do
        self:OnAdd(v,nil,tp)
	end
	self.time=5
    self.timer.seconds=self.time
    self.lab.text=tostring(self.time)
	self.timer:Start()
    self:SortState(true,5)

    local text=nil
    if self.tp==1 then text="已整理背包"
    elseif self.tp==2 or self.tp==3 or self.tp==4 or self.tp == 8 then text="已整理仓库" end
	UITip.Log(text)
end

function My:OnGrid(bagid,add)
    if self.tp~=bagid then return end
    self.max=PropMgr.cellNumDic[tostring(self.tp)]
    for i=0,add-1 do
        local num=self.max-i
        local go = self.goList[num]
        UIEventListener.Get(go).onClick = nil
        local eff = CG(UISprite,go.transform,"eff",self.Name,false)
        eff.alpha=0.001
    end
end

function My:OnUpFight()
    if self.tp>2 then return end
    local dic = PropMgr.tbDic
    if self.tp==2 then dic=PropMgr.tb2Dic end
    
    for k,v in pairs(self.dic) do
        local tb = dic[k]
        v:IconUp(tb.isUp)
        v:IconDown(tb.isDown)
    end
end

-------------------------私有
function My:InvlCb()
    if LuaTool.IsNull(self.trans) then return end
	if not self.time then return end
	self.time=self.time-1
	self.lab.text=tostring(self.time)
end

function My:Cb()
    if LuaTool.IsNull(self.bg)then return end
	self:SortState(false)
end

function My:SortName(a,b)
	local num1 = tonumber(a.name)
    local num2 = tonumber(b.name)
    if not num1 or not num2 then return 0  end
	if(num1<num2)then
		return -1
	elseif (num1>num2)then
		return 1
	else
		return 0
	end
end

function My:CreateCell(pos)   
    self.pos=pos
    AssetMgr.LoadPrefab("ItemCell",GbjHandler(self.LoadPrefab,self))
end

function My:LoadPrefab(go)
    go:SetActive(true)
	go.transform.parent=self.grid.transform
	go.transform.localPosition=Vector3.zero
    go.transform.localScale=Vector3.one
    --self.numIndex=self.numIndex+1
    go.name=tostring(self.pos)
    self.goList[#self.goList+1]=go

    if self.pos>self.max then --未开启的格子
        local eff = CG(UISprite,go.transform,"eff",self.Name,false)
        eff.alpha=1
        UITool.SetLsnrSelf(go,self.OnClick,self,self.Name, false)
    end
end

function My:OnClick(go)
    UIMgr.Open(AddCellPanel.Name,self.OpenCb,self)
end

function My:OnDoubleClick(go)
    if not self.tp then return end
    local id = self.idDic[go.name]
    local to = 1
    if self.tp==1 then to=2 end
    PropMgr.ReqDepot(self.tp,to,id)
    local cell = self.dic[tostring(id)]
    if cell then
        cell.doubleClick=true
        cell:Complete()
    end
end

function My:OpenCb(name)
    local ui=UIMgr.Get(name)
    if ui then
        ui:UpData(self.tp)
    end
end

function My:SortState(state,time)
    local text=nil
    if self.isBag==true and self.tp==1 then text="整理"
    elseif self.tp==1 then text="背包整理"
    elseif self.tp==2 then text="仓库整理"
    elseif self.tp==3 or self.tp==4 or self.tp == 8 then 
        text="整理"  
    end
	if(state==true)then
		self.bg.color=Color.New(0,0.54,0.45)
		self.lab.text=tostring(time)		
	else
		self.bg.color=Color.New(1,1,1)
		self.lab.text=text
    end
    self.box.enabled=not state
end

--检测当前界面是否为装备寻宝
function My:CheckBtn()
    local ui1 = UIMgr.Get(UITreasure.Name)
    local ui2 = UIMgr.Get(UIWish.Name)
    local ui3 = UIMgr.Get(UITongTianTower.Name);
    if ui1 or ui2 or ui3 then
        if self.trans.name == "bg3" then
            self.sortAllBtn = TransTool.Find(self.trans, "SortOutAll", self.Name)
            UITool.SetLsnrSelf(self.sortAllBtn,self.SortOutAll,self,self.Name)
        end
    end
end

-- 开服集字道具操作
function My:OpenWord()
    local isOpen = LivenessInfo:GetActInfoById(1005)
    local info = LivenessInfo.xsActivInfo["1005"]
    if  isOpen == false then
        btn[#btn+1]=btnList[2]
        return
    end
    local now = TimeTool.GetServerTimeNow()*0.001
    if info and info.eTime < now then
        btn[#btn+1]=btnList[2]
    end
end

--点击装备寻宝仓库一键取出按钮(许愿池，通天塔活动)
function My:SortOutAll()
    local ui1 = UIMgr.Get(UITreasure.Name)
    local ui2 = UIMgr.Get(UIWish.Name)
    local ui3 = UIMgr.Get(UITongTianTower.Name);
    local index = 0
    local dic = {}
    if ui1 then index = 3 end
    if ui2 then index = 4 end
    if ui3 then index = 8 end
    if index == 0 then return end
    if index == 3 then dic = PropMgr.tb3Dic end
    if index == 4 then dic = PropMgr.tb4Dic end
    if index == 8 then dic = PropMgr.tb8Dic end
    for k,v in pairs(dic) do
        TreasureMgr:ReqSortOutAll(index)
        return
    end
    UITip.Log("仓库里没有任何物品")
end

function My:Dispose()
    self:SortState(false)
    self:RemoveE()
    self:OnClean(self.tp)
    self.tp=nil
    self.isBag=nil
    self.POS=nil
    if self.timer then 
        self.timer:AutoToPool()
        self.timer=nil
    end
    while #self.goList>0 do
        local go = self.goList[#self.goList]
        if go.name~="ItemCell" and tonumber(go.name)>=self.max then
            local eff = CG(UISprite,go.transform,"eff",self.Name,false)
            eff.alpha=0.004
        end
        go.name="ItemCell"
        UIEventListener.Get(go).onClick=nil
        UIEventListener.Get(go).onDoubleClick=nil
        GbjPool:Add(go)
        self.goList[#self.goList]=nil
    end
    TableTool.ClearUserData(self)
end