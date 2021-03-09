--[[
同心结 xiaoyu
--]]
local AssetMgr=Loong.Game.AssetMgr
UIKnot=Super:New{Name="UIKnot"}
local My = UIKnot

function My:Ctor()
    self.list={}
    self.attList={}
    self.openList={}
end

function My:Init(trans)
    self.go=trans.gameObject
    self.trans=trans
    local CG=ComTool.Get
    local TF=TransTool.FindChild
    
    self.pre=TF(self.trans,"lab")
    local l = TF(self.trans,"L").transform
    for i=1,10 do
        local g = CG(UISprite,l,"s"..i,self.Name,false)
        self.list[i]=g
    end
    self.cell1=ObjPool.Get(UIItemCell)
    self.cell1:InitLoadPool(l,nil,nil,nil,nil,Vector3.New(-232.5,44.9,0))
    self.fx=TF(l,"eff/FX_jhjj")
    self.fx:SetActive(false)
    self.lock=TF(l,"lock")
    self.rank=CG(UILabel,l,"rank",self.Name,false)
    self.lv=CG(UILabel,l,"lv",self.Name,false)
    self.name=CG(UILabel,l,"name",self.Name,false)
    self.grid1 = CG(UIGrid,l,"att/Grid",self.Name,false) 
    self.tipBg=CG(UISprite,l,"tip",self.Name,false)
    self.tip=CG(UILabel,l,"tip/Label",self.Name,false)

    local r = TF(self.trans,"R").transform
    self.fightLab=CG(UILabel,r,"fight",self.Name,false)
    local att1 = TF(r,"Att1").transform
    self.grid2 = CG(UIGrid,att1,"Grid",self.Name,false) 
    local att2 = TF(r,"Att2").transform
    self.cell2=ObjPool.Get(UIItemCell)
    self.cell2:InitLoadPool(att2,nil,nil,nil,nil,Vector3.New(0,-76.5,0))
    self.slider=CG(UISlider,att2,"Slider",self.Name,false)
    self.sliderVal=CG(UILabel,att2,"Slider/lab",self.Name,false)
    local U = UITool.SetBtnClick
    self.red1=TF(r,"Promote/red")
    self.red2=TF(r,"APromote/red")
    U(r,"Promote",self.Name,self.Promote,self)
    U(r,"APromote",self.Name,self.APromote,self)
    U(att2,"tip",self.Name,self.Tip,self)
    U(att2,"tip/Label/mask",self.Name,self.CloseTip,self)
    self.tipLab=CG(UILabel,att2,"tip/Label",self.Name,false)
    self.APromoteLab=CG(UILabel,r,"APromote/Label",self.Name,false)

    self.time=0
    self.isA=false
    self.fight=0
    
    self:UpData()
    self:UpRed(KnotMgr.isRed,KnotMgr.KnotNum)
    self:AddE()
end

function My:AddE()
    KnotMgr.eKnot:Add(self.Knot,self)
    KnotMgr.eRed:Add(self.UpRed,self)
    MarryMgr.eMarry:Add(self.UpData,self)
    MarryMgr.eDivorce:Add(self.UpData,self)
end

function My:ReE()
    KnotMgr.eKnot:Remove(self.Knot,self)
    KnotMgr.eRed:Remove(self.UpRed,self)
    MarryMgr.eMarry:Remove(self.UpData,self)
    MarryMgr.eDivorce:Remove(self.UpData,self)
end

function My:Knot()
    self.fight=0
    self.fx:SetActive(false)
    self.fx:SetActive(true)
    self:UpData()
end

function My:UpRed(isred,num)
    self.red1:SetActive(isred)
    self.red2:SetActive(isred)
    self.cell2:UpLab(tostring(num))
end

function My:UpData()
    self:DestroyAtt(true)
    self.type_id=KnotMgr.KnotId
    --进阶消耗
    self.cell2:UpData(self.type_id)

    local id = MarryInfo.data.knotid+1
    if id>1 then 
        local type_id=EquipMgr.KnotCell()
        if type_id then self.cell1:UpData(type_id) end
        self.lock:SetActive(false)
    end
   
    local nextid = id+1
    local max=KnotData[#KnotData]
    if nextid>max.id then nextid=id end 
   
    local knot = KnotData[id]
    if not knot then iTrace.eError("xiaoyu","同心结表为空 id: "..tostring(id))return end
    local next = KnotData[nextid]

    local rank = knot.rank
    local lv = knot.lv    
    if rank>0 then self.rank.text=UIMisc.NumToStr(rank,"阶") end
   if lv>0 then self.lv.text=UIMisc.NumToStr(lv,"级") end
    --点心
    for i=1,lv do
        self.list[i].spriteName="xn_txj_02"
    end
    for i=lv+1,#self.list do
         self.list[i].spriteName="xn_txj_03"
    end

    self.fightLab.text=tostring(self.fight)

     --self.lv.text=UIMisc
     local exp = MarryInfo.data.knotExp   
     local curExp = next.exp
     self.slider.value=exp/curExp
     self.sliderVal.text=tostring(exp).."/"..curExp

    --仙侣属性
    local info = MarryInfo.data.coupleInfo
    if info then --已婚
        self.tip.text="加成中"
        self.tipBg.spriteName="xn_ty_12"
    else --未婚
        self.tip.text="未激活"
        self.tipBg.spriteName="xn_ty_13"
    end
    local att = knot.att
    local nextAtt = nil
    if next then nextAtt=next.att end
    self:SetAtt(self.grid1,att,nextAtt,info~=nil)

   
    --属性加成
    local baseAtt = knot.baseAtt
    local nextBaseAtt = nil
    if next then nextBaseAtt=next.baseAtt end
    self:SetAtt(self.grid2,baseAtt,nextBaseAtt,true)

    --战力
    self.fightLab.text=tostring(self.fight)

end

function My:SetAtt(parent,list,next,isadd)
    for i,v in ipairs(list) do
        local id = v.id
        local val = v.val
        local add = ""
        if next then
            for i1,v1 in ipairs(next) do
                if v1.id==id then
                    local v = v1.val-val
                    if v>0 then 
                        add="+"..PropTool.GetValByID(id,v)
                    end
                    break
                end
            end
        end

        if isadd==true then 
            self.fight=self.fight+PropTool.PropFight(id,val) 
        end
        local name = PropTool.GetNameById(id)
        local text = PropTool.GetValByID(id,val)
        local go=nil
        if #self.openList>0 then
            go=self.openList[#self.openList]
            self.openList[#self.openList]=nil
        else
            go=GameObject.Instantiate(self.pre)
        end
        go:SetActive(true)
        go.transform.parent=parent.transform
        go.transform.localPosition=Vector3.zero
        go.transform.localScale=Vector3.one
        local lab = go:GetComponent(typeof(UILabel))
        lab.text=name..":"..text.."[88f8ff]"..add
        self.attList[#self.attList+1]=go
    end
    parent:Reposition()
end

function My:Promote()
    self:UsePromote()
end

function My:APromote()
    self:UsePromote(true)
end

function My:UsePromote(isAkey)
    local num =  PropMgr.TypeIdByNum(self.type_id)
    local pNum = isAkey==true and num or 1
    if num>0 then 
        PropMgr.ReqUse(self.type_id,pNum,1)
    else
        UITip.Log("材料不足提升失败")
    end
end

function My:Tip()
    local data = InvestDesCfg["1023"]
    if not data then iTrace.eError("xiaoyu","投资文本为空 id  1023 ")return end
    self.tipLab.gameObject:SetActive(true)
    self.tipLab.text=data.des
end

function My:CloseTip()
    self.tipLab.gameObject:SetActive(false)
end

function My:Close()
    self.fx:SetActive(false)
end

function My:HideAtt()
   for i,v in ipairs(self.attList) do
       v:SetActive(false)
       v.transform.parent=nil
       GbjPool:Add(v)
   end
end

function My:DestroyAtt(ishide)
    while #self.attList>0 do
        local go = self.attList[#self.attList]
        if ishide==true then
            go:SetActive(false)
            self.openList[#self.openList+1]=go
        else
            GameObject.Destroy(go)
        end     
        self.attList[#self.attList]=nil
    end
end

function My:Dispose()
    if self.cell1 then self.cell1:DestroyGo() ObjPool.Add(self.cell1) self.cell1=nil end
    if self.cell2 then self.cell2:DestroyGo() ObjPool.Add(self.cell2) self.cell2=nil end
    self:ReE()
    self:DestroyAtt()
    ListTool.Clear(self.openList)
end