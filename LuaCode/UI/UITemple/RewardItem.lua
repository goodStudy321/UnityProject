RewardItem=Super:New{Name="RewardItem"}
local My = RewardItem

function My:init( go,winNum,rwdId )
    local CG = ComTool.Get
    local TF = TransTool.Find
    local Tip = self.Name
    self.root=go.transform
    self.go=go
    self.winNum=CG(UILabel,self.root,"winNum",Tip)
    self.RwdGrid=TF(self.root,"RwdGrid",Tip)
    self.eGrid=CG(UIGrid,self.root,"RwdGrid")
    self.isAllot=CG(UIButton,self.root,"isAllot",Tip)
    self.isAllotLbl=CG(UILabel,self.root,"isAllot/lbl")
    --展示奖励
    local lst = streakRWD[rwdId]
    local rwdlist =lst.RWD
    self.winNum.text=string.format( "连胜%s次奖励",lst.winNum)
    self.btnId=lst.winNum
    self:Dispose()
    self.Glist={}
    self:SetBtn()
    for i=1,#rwdlist do
        local cell = ObjPool.Get(UIItemCell)
        local key = rwdlist[i].id
        cell:InitLoadPool( self.RwdGrid,0.7)
        cell:UpData(key, rwdlist[i].num)
        table.insert(self.Glist, cell)
    end
    self.eGrid:Reposition();
end
--更新时候清空
function My:Dispose(  )
    if self.Glist==nil then
        return
    end
    local len  = #self.Glist
    for i=len,1,-1 do
       local ds= self.Glist[i]
       ds:DestroyGo()
       ObjPool.Add(ds)
       self.Glist[i]=nil
    end
  end
function My:SetBtn()
    local btnId = self.btnId
    self.model=UITemple.getNowModel()
    local active = UIStreakReward:isMyFamily(self.model.family_name)
    local can = UIStreakReward:CanAllot()
    local btn = self.isAllot.gameObject
    local SetGray = UITool.SetGray
    local cv_time = self.model.cv_times
    if active and cv_time>=btnId  then
        btn:SetActive(true)
        if cv_time==btnId and TempleMgr.GetFmlInfo().cv_reward~=nil 
         and TempleMgr.GetFmlInfo().cv_reward[1] ~= nil then
            if can then
                self.isAllot.enabled=true
                UITool.SetNormal(btn)
                self.isAllotLbl.text="分配"
                UITool.SetLsnrSelf(self.isAllot, self.toAllot, self, nil, false)
            else 
                self.isAllot.enabled=false                
                SetGray(btn)
                self.isAllotLbl.text="分配"
            end
        else
            self.isAllot.enabled=false                
            SetGray(btn)
            self.isAllotLbl.text="已分配"
        end
    else
        btn:SetActive(false)
    end
end

function My:setGray( )
    self.isAllot.enabled=false                
    self.isAllotLbl.text="已分配"
    UITool.SetGray( self.isAllot.gameObject)
end

function My:toAllot( )
    UIShowMember:open()
    UIShowMember:setWinTimes(self.btnId)
end

