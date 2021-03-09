UIStreakReward=UITmpRwdBase:New{Name="UIStreakReward"}
local My = UIStreakReward

function My:InitCustom(root)
    local CG = ComTool.Get
    local TF = TransTool.Find
    local Tip = self.Name
    local Root=root
    self.Grid=CG(UIGrid,Root,"sv/Grid",Tip)
    self.item=TF(self.Grid.transform,"item",Tip)
    self.Items={}
    self.go=self.item.gameObject
    local infoRT = TF(Root,"info",Tip)
    self.num=CG(UILabel,infoRT,"num",Tip)
    
    self.infoList=UITemple.getModelList()
    self:setRwdID() 
    TempleMgr.eStreakSuc:Add(self.changeBtn,self);   
end
--1连续type为1
function My:my_open( )
    UIShowMember:setType(1)
    self:show(self.rank)   
    self.Grid:Reposition()     
end

function My:setRwdID()
    self.one={}
    self.two={}
    self.three={}
    self.IDlist={self.one,self.two,self.three}
    self.worldLvl=FamilyBossInfo.worldLv 
    if self.worldLvl==nil then
        self.worldLvl=0;
    end  
    for i=1,#streakRWD do
     local info = streakRWD[i]
        if info.worldLvl.k<self.worldLvl and info.worldLvl.v >= self.worldLvl then
            if self.infoList[1]~=nil and info.rank==1 then
                table.insert(self.one,i)
             elseif self.infoList[2]~=nil and info.rank==2  then 
                 table.insert(self.two,i)
             elseif self.infoList[3]~=nil and  info.rank==3 then
                 table.insert(self.three,i)
            end
        end
    end
end

function My:show()
    len=#self.Items
    for i=1,len do
        self.Items[i].go:SetActive(false)
    end
    self.num.text= string.format("%s次",self.infoList[self.rank].cv_times)
    self:setItem()
end

function My:setItem() 
    local cv_times = self.infoList[self.rank].cv_times
    local rankRwd=self.IDlist[self.rank]
    local start=cv_times-10
    local End=cv_times+10
    local len = #rankRwd
    if start<1 then start=1 end
    if End>len then End=len end
    for i=start,End do
        local k = i-start+1
        local rwdId = rankRwd[i]
        if self.Items[k]~=nil then
            self:Updata(k,i,rwdId)
        else
            --创建格子
            local go = self.item.gameObject
            local g = UnityEngine.GameObject.Instantiate(go)
            local name = i
            if i<10 then
                name="0"..i 
            end
            g.name=name
            My:AddItem(i,g,rwdId)
        end
    end
    self.item.gameObject:SetActive(false)    
end

   
--更新
function My:Updata(k,winNum,rwdId )
    local go = self.Items[k].go
    go:SetActive(true)
    local cell = ObjPool.Get(RewardItem)
    cell:init(go,winNum,rwdId)
end
function My:AddItem(winNum,go,rwdId)
    local Add = TransTool.AddChild
    go:SetActive(true)
    local trans =go.transform
    Add(self.Grid.transform,trans)
    local cell = ObjPool.Get(RewardItem)
    cell:init(go,winNum,rwdId)
    table.insert(self.Items, cell)
end

--发送领取协议
function My:send(name,times)
    local info = TempleMgr.GetFmlInfo()
    local id = info.memberName[name]
    local kv= {}
    kv.id = self.rank
    kv.val=times
    self.timesToSend=times;
    TempleMgr.toSendStreak(id,kv)
end

function My:changeBtn( )
    for i=1,#self.Items do
        if self.Items[i].btnId==self.timesToSend then
            self.Items[i]:setGray();
        end
    end
end

function My:ClearItem( )
    for i=#self.Items,1,-1 do
        ObjPool.Add(self.Items[i])
    end
end

function My:doClear()
    TempleMgr.eStreakSuc:Remove(self.changeBtn,self);  
    if self.Items==nil then
        return
    end
    for i=#self.Items,1,-1 do
        GameObject.Destroy(self.Items[i].go)
        ObjPool.Add(self.Items[i])
    end
    self.Items=nil
end
return My
