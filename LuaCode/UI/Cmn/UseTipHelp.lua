UseTipHelp={Name = "UseTipHelp"}
local My = UseTipHelp
My.cando=true
function My:ItemInfo(id ,state,cb,str )
    self.id =id;
    local data=ItemData[tostring(id)]
    UIUseTip:Show(data,state,cb,self,Vector3(210,-130,0),str)
end
--小仙女
function My:CheckBossSence( id )
if My.cando then        
     local state,str= GuardMgr.GetGuardState()
     if state==1 then
        state ="购买"
        cb=self.BuyCb
     elseif state==2 then
        state ="穿戴"
        cb=self.UserCb
     elseif state==3 then
        state ="购买"
        cb=self.BuyCb
    else
        return
     end
    self:ItemInfo(id ,state,cb,str)
    My.cando=false
    self:TimeStart()
end
end

function My:TimeStart(  )
    self.Timer = ObjPool.Get(DateTimer);
    self.Timer.complete:Add(self.EndCountDown, self);
    self.Timer.seconds = GlobalTemp["138"].Value3
    self.Timer.cnt = 0;
    self.Timer:Start();
end

function My:EndCountDown()
    if self.Timer ~=nil then
        self.cando=true
        self.Timer:AutoToPool();
        self.Timer = nil;
    end
end

function My:BuyCb()
	StoreMgr.TypeIdBuy(self.id, 1)
end

function My:UserCb()
    PropMgr.ReqUse(self.id, 1, 1)
end