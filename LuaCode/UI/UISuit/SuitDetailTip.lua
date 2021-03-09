--[[
套装详情
]]
SuitDetailTip=Super:New{Name="SuitDetailTip"}
local My = SuitDetailTip

function My:Ctor()
    self.suitDic={}
    self.baseList={}
    self.AttList={}
    self.suitNumDic={}
end

function My:Init(go)
    self.go=go
    local trans = go.transform
    local CG = ComTool.Get
	local TF = TransTool.FindChild
    
    local U = UITool.SetBtnClick

    local trans = go.transform
    local panel =TF(trans,"Panel").transform
    self.panel=CG(UIPanel,trans,"Panel",self.Name,false)
    self.partLab=CG(UILabel,panel,"partLab",self.Name,false)
    self.attLab=CG(UILabel,panel,"attLab",self.Name,false)
    self.suitTitle=TF(panel,"suitTitle")
    self.suitAttLab=TF(panel,"suitAttLab")
    U(trans,"CloseBtn",self.Name,self.Close,self)
    if not self.str then self.str=ObjPool.Get(StrBuffer)end

    self.pos=self.panel.transform.localPosition
end

function My:UpData(type)
    local list=SuitMgr.suitInfo[type]
    if #SuitMgr.suitInfo==0 then iTrace.eError("xiaoyu","套装信息为空")return end
    if not list then iTrace.eError("xiaoyu","套装信息为空 type: "..tostring(type))return end
    --部位描述
    self:PartStr(list)

    --基础属性
    self:BaseAttStr(list)

    --套装属性
    self:SuitAttStr()
end

function My:PartStr(list)
     --清理表
    TableTool.ClearDic(self.suitDic)
    TableTool.ClearDic(self.suitNumDic)
    self.str:Dispose()
    for i,v in ipairs(list) do
        local data = SuitStarData[v]
        local suitId=tostring(data.suitId)
        local num = self.suitDic[suitId]
        num=not num and 1 or num+1
        self.suitDic[suitId]=num
    end
    for suitId,num in pairs(self.suitDic) do
        local suitData=SuitAttData[suitId]
        local color = "[B2B2B2FF]"
        local att=suitData.attList
        if att then
            local minNum=att[1].num
            if num>=minNum then color="[00FF00FF]" self.suitNumDic[suitId]=num end
        end
        self.suitDic[suitId]=color
    end
    for i,v in ipairs(list) do
        local data = SuitStarData[v]
        local suitId=tostring(data.suitId)
        local color = self.suitDic[suitId]
        self.str:Apd(color):Apd(data.rank):Apd("阶"):Apd(SuitMgr.partList[data.part]):Apd("[-]")
        if i==4 or i==8 then self.str:Line() else self.str:Apd("    ") end
    end
    self.partLab.text=self.str:ToStr()
end

function My:BaseAttStr(list)
    TableTool.ClearDic(self.baseList)
    self.str:Dispose()
    for i,v in ipairs(list) do
        local data = SuitStarData[v]
        local attList=data.attList
        for i1,v1 in ipairs(attList) do
            local id = v1.id
            local val = v1.val
            local tabVal = self.baseList[tostring(id)] or 0
            tabVal=tabVal+val
            self.baseList[tostring(id)]=tabVal
        end
    end
    local num = 0
    for k,v in pairs(self.baseList) do
        local id = tonumber(k)
        local name = PropTool.GetNameById(id)
        local val = PropTool.GetValByID(id,v) 
        self.str:Apd("[F4DDBDFF]"):Apd(name):Apd("  [-][00FF00FF]+"):Apd(val):Apd("[-]")
        num=num+1
        if num==2 then self.str:Line() else self.str:Apd("      ") end
    end
    self.attLab.text=self.str:ToStr() 
end

function My:SuitAttStr()
    for k,num in pairs(self.suitNumDic) do
        local suitData=SuitAttData[k] 
        local attList = suitData.attList
        if attList then 
            local minNum=attList[1].num
            local maxNum = attList[#attList].num
            if num>=minNum then
                self.str:Dispose()
                self.str:Apd(suitData.rank):Apd("阶  "):Apd(suitData.suitName):Apd("("):Apd(num):Apd("/"):Apd(maxNum):Apd(")")
                self:CreateTitle(self.str:ToStr())
                self.str:Dispose()
                for i1,v1 in ipairs(attList) do
                    if num>=v1.num then 
                        self.str:Apd("[00FF00FF]【"):Apd(v1.num):Apd("】"):Apd("件套[-]")
                        self.str:Line()
                        for i2,v2 in ipairs(v1.val) do
                            local name = PropTool.GetNameById(v2.id)
                            local val = PropTool.GetValByID(v2.id,v2.val) 
                            self.str:Apd("[F4DDBDFF]"):Apd(name):Apd(":[-]   [00FF00FF]+"):Apd(val):Apd("[-]")
                            self.str:Line()
                        end
                    end
                end
                self:CreateLab(self.str:ToStr())
            end
        end
    end
end

function My:CreateTitle(text)
	self:Create(text,self.suitTitle,19)
end

function My:CreateLab(text)
	self:Create(text,self.suitAttLab,9)
end

function My:Create(text,pre,lerpY)
	local t = self.AttList
	local go = GameObject.Instantiate(pre)
	go.transform.parent=self.panel.transform
	go:SetActive(true)
	go.transform.localScale=Vector3.one
	local y=-15.76
	if(#t>0)then
		local last = t[#t]
		y = last.transform.localPosition.y-last.printedSize.y-lerpY
	end
	go.transform.localPosition=Vector3.New(-272.9,y,0)

	local label=go:GetComponent(typeof(UILabel))
	label.text=text
	self.AttList[#self.AttList+1]=label
end

function My:CleanAttList()
    while #self.AttList>0 do
        local att = self.AttList[#self.AttList].gameObject
		GameObject.Destroy(att)
        self.AttList[#self.AttList]=nil
    end
end

function My:CleanTab()
   
end

function My:Open()
    self.go:SetActive(true)
end

function My:Clean()
    self:CleanAttList()
    TableTool.ClearDic(self.suitDic)
    TableTool.ClearDic(self.suitNumDic)
end

function My:Close()
    self:Clean()
    self.panel.transform.localPosition=self.pos
    self.panel.clipOffset=Vector2.New(0,0)
    self.go:SetActive(false)
end

function My:Dispose()
    self:Clean()
    if self.str then ObjPool.Add(self.str) self.str=nil end
end