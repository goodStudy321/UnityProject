--[[
收集信息
]]
require("UI/Base/SkillTip")
require("UI/UIEquipCollection/CollectAtt")
CollectInfo=Super:New{Name="CollectInfo"}
local My = CollectInfo

function My:Init(go)
    if not self.list then self.list={} end
    if not self.goList then self.goList={} end
    local trans = go.transform
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    self.Slider=CG(UISlider,trans,"Slider",self.Name,false)
    self.grid=CG(UIGrid,trans,"Grid",self.Name,false)
    self.pre1=TF(trans,"Grid/C")
    self.curVal=CG(UILabel,trans,"curVal",self.Name,false)
    self.Cell=ObjPool.Get(Cell)
    self.Cell:InitLoadPool(TF(trans,"bg").transform,nil,nil,nil,nil,Vector3.New(0,3.52,0))
    self.btn=TF(trans,"Btn")
    self.btnLab=CG(UILabel,trans,"Btn/Label",self.Name,false)
    self.btnRed=TF(trans,"Btn/red")
    UITool.SetBtnClick(trans,"Btn",self.Name,self.OnBtn,self)
    self.Tab=CG(UITable,trans,"panel/Table",self.Name,false)
    self.pre2=TF(trans,"panel/Table/C")

    self.str=ObjPool.Get(StrBuffer)

    self.info=nil

    self:SetEvent("Add")
end

function My:UpData(id)
    self:CleanData()
    self.id=id
    self.isMaxNum=false --套装是否满件
    self.info=EquipCollectionMgr.infoDic[id] or {}
    local suit_num = self.info.suit_num or 0
    local data = EquipCollData[id]
    if not data then iTrace.eError("xiaoyu","装备套装表为空 id: "..tostring(id))return end
    local numList = data.numList
    for i,v in ipairs(numList) do
        local att = data["att"..i]
        local go = GameObject.Instantiate(self.pre2)
        go:SetActive(true)
        local trans = go.transform
        trans.parent=self.Tab.transform
        trans.localPosition=Vector3.zero
        trans.localScale=Vector3.one
        local color = v<=suit_num and "[00FF00FF]" or "[F4DDBDFF]"
        local cell = ObjPool.Get(CollectAtt)
        cell:Init(go)
        cell:UpData(v,att,color)
        self.list[i]=cell

        local goo = GameObject.Instantiate(self.pre1)
        goo:SetActive(true)
        local gooTrans = goo.transform
        gooTrans.parent=self.grid.transform
        gooTrans.localPosition=Vector3.zero
        gooTrans.localScale=Vector3.one
        local lab = ComTool.Get(UILabel,gooTrans,"Label",self.Name,false)
        lab.text=tostring(v)
        self.goList[i]=goo
    end
    self.Tab.repositionNow=true
    self.grid.repositionNow=true
    --self.Cell:UpData(data.skillList.value,data.skillList.id)

   self:NextNumDown(id,numList)
   self:UpSlider(id,numList,#data.idList)
   self:UpSkill(data.skillList)
   self:UpBtnState()
   self:ShowRed()
end

function My:UpSkill(skillList)
    local num = skillList.id
    local id = skillList.value
    local data = SkillLvTemp[tostring(id)]
    if not data then iTrace.eError("xiaoyu","技能等级配置表为空 id: "..id)return end
    local icon = data.icon
    AssetMgr:Load(icon,ObjHandler(self.Cell.LoadIcon,self.Cell))
    local cellGo =self.Cell.trans.gameObject
    local iconGo = self.Cell.Icon.gameObject
    if self.info.is_active==true then
        UITool.SetNormal(cellGo) 
        UITool.SetNormal(iconGo) 
    else
        UITool.SetGray(cellGo,true)
        UITool.SetGray(iconGo,true)
    end
end

function My:NextNumDown(id,numList)
    for i,v in ipairs(self.list) do
        v:TweenState(false)
    end
    local nextDown = self:NextNumIndex(id,numList)
    self.nextNum=numList[nextDown]
    local nextCell = self.list[nextDown]
    self.nextCell=nextCell
    nextCell:TweenState(true)
end

function My:NextNumIndex(id,numList)
    local nextIndex = 0
    local hasNum = self.info.suit_num or 0
    if hasNum==0 then return 1 end
    if hasNum==numList[#numList] then self.isMaxNum=true return #numList end
    for i,v in ipairs(numList) do
        if v==hasNum then return i+1 end
    end
end

function My:UpSlider(id,numList,allNum)
    local hasNum = self.info.suit_num or 0
    if self.info and self.info.is_active==true then hasNum=allNum end
    local maxNum = numList[#numList]
    self.str:Dispose()
    self.str:Apd("当前进度: "):Apd(hasNum):Apd("/"):Apd(allNum)
    self.Slider.value=hasNum/maxNum
    self.curVal.text=self.str:ToStr()
end

function My:UpBtnState()
    local isActive = self.info.is_active or false
    local state = true
    if self.isMaxNum==true and isActive==true then  
        state=false 
    end
    self.btn:SetActive(state) 
    local btnName = (self.isMaxNum==true and isActive==false) and "领取" or "激活"
    self.btnLab.text=btnName
end

--激活并领取
function My:OnBtn()
    local isActive = self.info.is_active or false
    local id = tonumber(self.id)
    if self.isMaxNum==false then
        local nextIds = EquipCollectionMgr.GetActiveNextIds(self.nextNum,self.id)
        if #nextIds<self.nextNum then UITip.Log("数量不足无法激活套装")return end
        EquipCollectionMgr.ReqSuitActive(id,self.nextNum,nextIds)
    elseif self.isMaxNum==true and isActive==false then
        EquipCollectionMgr.ReqSkillActive(id)
    end
end

function My:CleanData()
    ListTool.ClearToPool(self.list)
    for i,v in ipairs(self.goList) do
        Destroy(v)
    end
    ListTool.Clear(self.goList)
end

function My:SetEvent(fn)
    self.Cell.eClickCell[fn](self.Cell.eClickCell,self.OnClickCell,self)
end

function My:OnClickCell()
    if not self.skillTip then 
        LoadPrefab(PropTip.Name,GbjHandler(self.LoadTip,self))
    else
        self.skillTip:Open()
        local data = EquipCollData[self.id]
        local isActive=self.info.is_active or false
        self.skillTip:UpData(data.skillList,isActive)
    end
end

function My:LoadTip(go)
    local ui = UIMgr.Get(UIEquipCollection.Name)
    local root = ui.root
    go:SetActive(true)
    local trans = go.transform
    trans.parent=root
    trans.localScale=Vector3.one
    trans.localPosition=Vector3.zero

    local panel = ui.root:GetComponent(typeof(UIPanel))
    UITool.Sort(go,panel.depth+5)
    self.skillTip=ObjPool.Get(SkillTip)
    self.skillTip:InitData(trans,self.Cell.trans.position)
    self.skillTip:Open()
    local data = EquipCollData[self.id]
    local isActive=self.info.is_active or false
    self.skillTip:UpData(data.skillList,isActive)
end

function My:ShowRed()
    local id = tostring(self.id)
    local isred = EquipCollectionMgr.redDic[id] or false
    local skillRed = EquipCollectionMgr.skillRedDic[id] or false
    if self.nextCell then self.nextCell:ShowRed(isred==true and skillRed~=true) end
    if isred==false then isred=skillRed end
    self.btnRed:SetActive(isred)
end

function My:Dispose()
    self:SetEvent("Remove")
    self:CleanData()
    self.list=nil
    self.goList=nil
    if self.str then ObjPool.Add(self.str) self.str=nil end
    if self.skillTip then ObjPool.Add(self.skillTip) self.skillTip=nil end
    TableTool.ClearUserData(self)
end