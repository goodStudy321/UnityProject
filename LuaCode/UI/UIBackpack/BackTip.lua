--[[

背包tip
]]
BackTip=Super:New{Name="BackTip"}
local My = BackTip

function My:Ctor()
    self.titleList={"装备星级加成","累积强化加成","全身宝石加成"}
end

function My:Init(go)
    self.go=go
    local TF = TransTool.FindChild
    local CG = ComTool.Get
    self.trans=go.transform

    local U = UITool.SetBtnClick
    U(self.trans,"Star",self.Name,self.Star,self)
    U(self.trans,"Strengthen",self.Name,self.Strengthen,self)
    U(self.trans,"Gem",self.Name,self.Gem,self)
    self.TipPanel=TF(self.trans,"TipPanel")
    local t=self.TipPanel.transform
    self.title=CG(UILabel,t,"title",self.Name,false)
    self.curLab=CG(UILabel,t,"curLab",self.Name,false)
    self.nextLab=CG(UILabel,t,"nextLab",self.Name,false)

    UITool.SetLsnrClick(t,"Mask",self.Name,self.Close,self)

    self.Str=ObjPool.Get(StrBuffer)
end

function My:Star( ... )
   self:UpData(1)
end

function My:Strengthen( ... )
    self:UpData(2)
end

function My:Gem( ... )
    self:UpData(3)
end

--1.星级 2.强化 3.宝石
function My:UpData(id)
    self.TipPanel:SetActive(true)
    self.Str:Dispose()
    local title = ""
    if id==1 then
        self:Str1()
    elseif id==2 then
        self:Str2()
    elseif id==3 then
        self:Str3()
    end
    title=self.titleList[id]
    self.title.text=title
end

--星级加成
local dic = {}
function My:Str1()
    local lv = 0
    local equipDic = EquipMgr.hasEquipDic
    for k,v in pairs(equipDic) do
        local equip = EquipBaseTemp[tostring(v.type_id)]
        if not equip then iTrace.Error("xioayu","装备属性表为空 id: "..v.type_id)return end
        local viplv = equip.startLv or 0
        lv=lv+viplv
    end
    
    local nextGold = EquipGoal[1]
    if lv<nextGold.lv then --当前0级
        self.Str:Apd("[008ffc]全身装备星级共"):Apd(lv):Apd("星[-]")
        self.curLab.text=self.Str:ToStr()
        self.Str:Dispose()
 
        self:NextStar(nextGold)
    else
        local maxLv = EquipGoal[#EquipGoal]
        if lv>=maxLv.lv then --当前最大等级
            self:CurStar(maxLv,lv)

            self.Str:Apd("[008ffc]下阶目标")
            self.Str:Line()
            self.Str:Apd("当前强化已达最大级[-]")
            self.nextLab.text=self.Str:ToStr()
            self.Str:Dispose()
        else
            for i,v in ipairs(EquipGoal) do               
                local nextGold = EquipGoal[i+1]
                if lv>=v.lv and lv<nextGold.lv then
                    self:CurStar(v,lv)
                    self:NextStar(nextGold)
                    return
                end
            end           
        end     
    end
end

function My:CurStar(v,lv)
    self.Str:Apd("[008ffc]全身装备星级达到"):Apd(v.lv):Apd("星[-]")
    self.Str:Line()  
    self:ShowAttStr(v)
    self.Str:Apd("[00FF00FF]当前星级共"):Apd(lv):Apd("星[-]")
    self.curLab.text=self.Str:ToStr()
    self.Str:Dispose()
end

function My:NextStar(nextGold) 
    self.Str:Apd("[008ffc]下阶目标")
    self.Str:Line()
    self.Str:Apd("全身装备星级达到"):Apd(nextGold.lv):Apd("星[-]")
    self.Str:Line()
    self:ShowAttStr(nextGold)
    self.nextLab.text=self.Str:ToStr()
    self.Str:Dispose()
end

--宝石加成
function My:Str3()
    local lv = 0
    local equipDic = EquipMgr.hasEquipDic
    for k,v in pairs(equipDic) do
        local stDic = v.stDic
        for k,v in pairs(stDic) do
            local gem = GemData[tostring(v)]
            if not gem then iTrace.Error("xiaoyu","宝石表为空 id: "..v)return end
            lv=lv+gem.lv
        end
    end

    local nextLv = GemLv[1]
    if lv<nextLv.lv then
        self.Str:Apd("[008ffc]全身装备宝石共"):Apd(lv):Apd("级[-]")
        self.curLab.text=self.Str:ToStr()
        self.Str:Dispose()  

        
        self:NextGem(nextLv)
    else
        local maxLv = GemLv[#GemLv]
        if lv>=maxLv.lv then --当前最大等级
            self:CurStar(maxLv,lv)

            self.Str:Apd("[008ffc]下阶目标")
            self.Str:Line()
            self.Str:Apd("当前宝石等级已达最大级[-]")
            self.nextLab.text=self.Str:ToStr()
            self.Str:Dispose()
            return
        else
             for i,v in ipairs(GemLv) do
                local nextLv = GemLv[i+1] 
                if lv>=v.lv and lv<nextLv.lv then
                    self:CurStar(v,lv)
                    self:NextStar(nextLv)
                    return
                end
            end           
        end     
    end
end

function My:CurGem(v,lv)
    self.Str:Apd("[008ffc]全身装备宝石共"):Apd(v.lv):Apd("级[-]")
    self.Str:Line()  
    self:ShowAttStr(v)
    self.Str:Apd("[00FF00FF]当前宝石共"):Apd(lv):Apd("级[-]")
    self.curLab.text=self.Str:ToStr()
    self.Str:Dispose()
end

function My:NextGem(nextLv)
    self.Str:Apd("[008ffc]下阶目标")
    self.Str:Line()
    self.Str:Apd("全身装备宝石共"):Apd(nextLv.lv):Apd("级[-]")
    self.Str:Line()
    self:ShowAttStr(nextLv)
    self.nextLab.text=self.Str:ToStr()
    self.Str:Dispose()
end


--强化加成
function My:Str2()
    local lv = 0
    local equipDic = EquipMgr.hasEquipDic
    for k,v in pairs(equipDic) do
        lv=lv+v.lv
    end

    local nextLv = Equiplv[1]
    if lv<nextLv.lv then
        self.Str:Apd("[008ffc]装备累积强化+ "):Apd(lv):Apd("级[-]")
        self.curLab.text=self.Str:ToStr()
        self.Str:Dispose()

        
        self:NextStren(nextLv)
    else
        local maxLv = Equiplv[#Equiplv]
        if lv>=maxLv.lv then
            self:CurStren(maxLv,lv)

            self.Str:Apd("[008ffc]下阶目标")
            self.Str:Line()
            self.Str:Apd("当前强化已达最大级[-]")
            self.nextLab.text=self.Str:ToStr()
            self.Str:Dispose()

            return
        else
            for i,v in ipairs(Equiplv) do
                local nextLv = Equiplv[i+1]
                if lv>=v.lv and lv<nextLv.lv then
                    self:CurStren(v,lv)
                    self:NextStren(nextLv)
                    return
                end
            end
        end
    end
end

function My:CurStren(v,lv)
    self.Str:Apd("[008ffc]装备累积强化+ "):Apd(v.lv):Apd("级[-]")
    self.Str:Line()
    self:ShowAttStr(v)
    self.Str:Apd("[00FF00FF]当前强化+ "):Apd(lv):Apd("级[-]")
    self.curLab.text=self.Str:ToStr()
    self.Str:Dispose()
end

function My:NextStren(nextLv)
    self.Str:Apd("[008ffc]下阶目标")
    self.Str:Line()
    self.Str:Apd("装备累积强化+ "):Apd(nextLv.lv):Apd("级[-]")
    self.Str:Line()
    self:ShowAttStr(nextLv)
    self.nextLab.text=self.Str:ToStr()
    self.Str:Dispose()
end


function My:ShowAttStr(v)
    local hp = v.hp or 0
    self:ShowAtt("hp",hp)
    local atk = v.atk or 0
    self:ShowAtt("atk",atk)
    local def = v.def or 0
    self:ShowAtt("def",def)
    local arm = v.arm or 0
    self:ShowAtt("arm",arm)
end

function My:ShowAtt(nLua,val)
    if val==0 then return end
    local name = PropTool.GetName(nLua)
    local va = PropTool.GetValByNLua(nLua,val)
    self.Str:Apd(name):Apd(":  [00FF00FF]+"):Apd(va):Apd("[-]")
    self.Str:Line()
end

function My:Open()
    self.go:SetActive(true)
end

function My:Close()
    self.TipPanel:SetActive(false)
end

function My:Dispose()
    if self.Str then ObjPool.Add(self.Str) self.Str=nil end
end