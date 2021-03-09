UIShutReward=UITmpRwdBase:New{Name="UIShutReward"}
local My = UIShutReward
function My:InitCustom(root )
    self.root=root
    local  CG= ComTool.Get
    local tip = self.Name
    self.buffTxt=CG(UILabel,root,"info/buff",tip)
    self.rwdRoot=TransTool.Find(root,"RwdGrid",tip)
    self.model=UITemple.getModelList()[1]
    self.winNum=self.model.cv_times
    if self.winNum<2 then
        self.rwdinfo="0%"
    elseif  self.winNum<#ShutRWD then
        local shutInfo = ShutRWD[self.winNum]
        local buffId = tostring(shutInfo.buff)
        local numifo = BuffTemp[buffId]
        local numlist = numifo.valueList
        local num = numlist[1].v
        self.rwdinfo=(num/10000).."%"
    else
        iTrace.Error("帮战终结buff","连胜超出配表策划快去配表")
    end
    self.isAllot=CG(UIButton,root,"btn/isAllot",tip)
    self.isAllotLbl=CG(UILabel,root,"btn/isAllot/lbl",tip) 
    self.Glist={}
    self:show()  
    TempleMgr.eshut:Add(self.SetBtn,self);
end
--0为中断
function My:my_open( )
   UIShowMember:setType(0)
end

function My:show(  )
    self.buffTxt.text=self.rwdinfo
    self:SetBtn()
    if self.my_family_info.end_cv==0 then return end
    self:rwdShow()
end

function My:SetBtn( )
    local active = self:isMyFamily(self.model.family_name)
    local can = self:CanAllot()
    local btn = self.isAllot.gameObject
    local SetGray = UITool.SetGray
    local ed = self.my_family_info.end_cv
    if active and ed ~=0  then
        btn:SetActive(true)
        -- if ed ~= 0  then
         if can then
                self.isAllot.enabled=true
                UITool.SetNormal(btn)
                self.isAllotLbl.text="分配"
                UITool.SetLsnrSelf(self.isAllot, self.toAllot, self, nil, false)
            else 
                My.isAllot.enabled=false                
                SetGray(btn)
                self.isAllotLbl.text="分配"
         end
        -- else
        --     SetGray(btn)
        --     self.isAllotLbl.text="无法分配"
        -- end
    else
        btn:SetActive(false)
    end
end

--打开分配
function My:toAllot( )
    UIShowMember:open()
end
--展示奖励
function My:rwdShow( )
    local rwdlist = ShutRWD[self.winNum].RWD
    for i=1,#rwdlist do
        local cell = ObjPool.Get(UIItemCell)
        local key = rwdlist[i].id
        cell:InitLoadPool( self.rwdRoot,0.7)
        cell:UpData(key, rwdlist[i].num)
        table.insert(self.Glist, cell)
    end
end
--发送领取协议
function My:send(name)
    local id = TempleMgr.GetFmlInfo().memberName[name]
    TempleMgr.toSendShut(id)
    local btn = self.isAllot.gameObject
    My.isAllot.enabled=false  
    btn:SetActive(false)
    UIShowMember:close()
end

function My:doClear( )
    self.Glist=nil
    TempleMgr.eshut:Remove(self.SetBtn,self);
end
return My