BlackShowItem=Super:New{Name="BlackShowItem"}
local My = BlackShowItem
local Animation = UnityEngine.Animation
function My:Ctor(  )
    --特效
    self.EffLst={}
end

function My:Init(go)
    self.go=go
    self.root=go.transform;

    --常用工具
    local tip = "BlackShowItem"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;
    local parent =self.root.parent
    self.box = TF(root,"uc_box",tip)
    self.box.localRotation=Vector3.zero
    -- self.Animatordo = self.box:GetComponent(typeof(Animator));
    self.Animatordo = CG(Animation,root,"uc_box",tip)
    UC(root,"uc_box",tip,self.SendChoose,self)
    self.effroot=TF(root,"uc_box/effroot",tip)
    for i=1,3 do
        local eff = TFC(self.effroot,tostring(i),tip)
        eff:SetActive(false)
        table.insert(  self.EffLst, eff)
    end
    if   self.timer==nil then
        self.timer= ObjPool.Get(DateTimer);   
    end
    self.timer.complete:Add(self.EndTime,self);
end


function My:SetId( msg,index )
    self.index=index
    self.id=msg.id
    self.gears=msg.gears
    self.ani=msg.ani
    self.eff=msg.eff
    self.EffNeedShow=self.EffLst[self.eff]
    self.WiteTime=msg.WiteTime
	self.Animatordo:Stop()
end

function My:EffAndAniShow(  )
    -- iTrace.eError("soon",self.id.."   "..)
    self.EffNeedShow:SetActive(false)
    self.EffNeedShow:SetActive(true)
    self.Animatordo:Stop()
    self.Animatordo:Play(self.ani);
    -- local tempClip = self.Animatordo:GetClip(self.ani);
    -- if tempClip ~= nil then
    --     print("1111111111111           "..tempClip.name)
    -- end
end

function My:timeStart( )
    if self.WiteTime<1 then
        self:EndTime(  )
        return
    end
    self.timer.seconds = self.WiteTime
    self.timer:Start()
end

function My:SendChoose( )
   BlackHelp.SendChoose(self.id)
end

function My:EndTime(  )
    BlackEffShow.SetCanUseLst(self.index)
    if  self.timer then
        self.timer:AutoToPool();
        self.timer = nil
    end
end

function My:Dispose()
    self.Animatordo =nil
    soonTool.ClearList( self.EffLst)
	TableTool.ClearUserData(self)
    if  self.timer then
        self.timer:AutoToPool();
        self.timer = nil
    end
end