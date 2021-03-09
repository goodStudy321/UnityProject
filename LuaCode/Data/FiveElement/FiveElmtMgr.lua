require("Data/FiveElement/FiveCarnetTip")
FiveElmtMgr = {Name = "FiveElmtMgr"}
local My = FiveElmtMgr;
My.isInit = false;
--当前通过的副本id
My.curMaxCopyId=0
--幻力
My.illusion=0
--幻力刷新
My.eIllUpdata=Event()
--已经购买了幻力的次数
My.buy_illusion_times=0
--天机勾玉可以领取的数量
My.nat_intensify=0
--勾玉刷新
My.eNatUpdata=Event()
--解锁层
My.unlock_floor=1
My.floorMsg=nil
My.eIllBuyBack=Event()
--最大进入改变
My.eCurMax=Event()
My.eRed=Event()
My.eGoNextRed=Event()
My.eIllRedRed=Event()
My.eNatRed=Event()
My.eNatGetSuc=Event()
My.Red=false
My.illRed=false
My.book_list={}
My.eBook=Event()
My.CanGoNxt=false
My.CanGoTip="未通关"
My.OpenOnceBecauseCanEnter=false;
My.onceRed=false;
function My:Init()
    self:AddLsnr();
    self:DoTabel()
end

function My:AddLsnr()
    local PA =  ProtoLsnr.AddByName
    PA("m_copy_five_elements_unlock_toc",self.ResElementsUnlock,self); 
    PA("m_copy_illusion_update_toc",self.illusionUpdate,self)   
    PA("m_role_nature_book_update_toc",self.BookUpdate,self)   
    PA("m_copy_buy_illusion_toc",self.BuyIllusionBack,self)
    PA("m_copy_min_update_toc",self.UpdateMin,self)
    PA("m_copy_nat_intensify_toc",self.getNatBack,self)
    PA("m_copy_five_elements_update_toc",self.MaxCopyChange,self)
    -- PropMgr.eUpdate:Add(My.GetNatInBag)
end


-- function My.GetNatInBag(  )
--     My.goNextRed(  )
-- end

function My.GetMaxFlootInfo(  )
    local msg = My.floorMsg[My.unlock_floor]
    if msg==nil then
        iTrace.eError("soon","五行幻境表没有配置"..My.unlock_floor)
       return My.floorMsg[1]
    end
    return msg
end
--判断副本是否开起
function My.UnLockCopy( copyId )
    if copyId==nil then
        iTrace.eError("sooon","传入为空")
        return false
    end
    if copyId>My.curMaxCopyId+1 then
        return false
    end
    return true
end

--天机勾玉可以领取的数量达到最大各处刷新
function My.NatRed( )
    My.natRed=false
    local msg = My.GetMaxFlootInfo()
    local max = msg.natMax
    if max<=My.nat_intensify then
        My.natRed=true
    end
    My.eNatRed()
    My.BigRed(  )
end

function My.BigRed(  )
    if My.natRed or My.CanGoNxt or My.onceRed then
       My.Red=true
    else
        My.Red=false
    end
    My:RfrSpirEqRed()
    My.eRed()
end
function My:RfrSpirEqRed()
	local actId = ActivityMgr.DJ
    local red = My.Red
    if My.IsOpen() then    
        if red == true then
            SystemMgr:ShowActivity(actId,11)
        else
            SystemMgr:HideActivity(actId,11)
        end
    end
end

function My.CanDoOneEnter(  )
    My.onceRed=false;
    local id = tostring(My.curMaxCopyId)
    local msg = FvElmntCfg[id]
    if msg==nil then
        msg= FvElmntCfg["70101"]
    end
    local costIllusion = msg.costIllusion
    if costIllusion<=My.illusion  and not My.OpenOnceBecauseCanEnter then
        My.onceRed=true;
    else
        My.OpenOnceBecauseCanEnter=false
    end
end

function My.OpenChange(  )
   if  My.onceRed then
    My.onceRed=false
    My.OpenOnceBecauseCanEnter =true
   end
   My.BigRed(  )
end

function My.FullIllRed(  )
    My.illRed=false
    local msg = My.GetMaxFlootInfo()
    local max = msg.illMax
    if max<=My.illusion then
        My.illRed=true
    end
    My.CanDoOneEnter(  )
    My.eIllRedRed()
    My.BigRed(  )
end

function My.goNextRed(  )
     My.CanGoNext( )
    My.eGoNextRed()
    My.BigRed(  )
end

function My:DoTabel(  )
    My.floorMsg=tFvFloor
    for k,v in pairs(FvElmntCfg) do
        local lv = v.copyLv
        local Floor = v.layer
        local lst = My.floorMsg[Floor].CopyLst
        if lst==nil then
            lst={}
        end
        lst[lv]=v.id
        My.floorMsg[Floor].CopyLst=lst
    end
end

function My.CanGoNext( )
    if My.curMaxCopyId==0 then
        My.CanGoNxt=false
        My.CanGoTip="未通关"
        return
    end
    local Info = FvElmntCfg[tostring(My.curMaxCopyId)]
    local floor = Info.layer
    local lv = Info.copyLv
    if floor~=My.unlock_floor or  lv<FiveCopyHelp.MaxCopyLv then
        My.CanGoNxt=false
        My.CanGoTip="未通关"
        return
    end
    My.CanGoTip="未集齐套装"
    local canEnter = true
    local Msg = FiveElmtMgr.floorMsg[My.unlock_floor]
    local CopyNeed= Msg.CopyNeed
    for i=1,#CopyNeed do
       local bl =  My.IndexInBook( CopyNeed[i] )
       if bl==false then
        My.CanGoNxt=false
        return
       end
    end
    My.CanGoNxt=true
end
function My.IndexInBook( id )
    local len = #My.book_list
    for i=1,len do
        if id==My.book_list[i] then
           return true
        end
    end
    return false
end
--为true时候开启过了num类型
function My:CopyIsOpen( copyid  )
    return copyid<=My.curMaxCopyId
end

function My:MaxCopyChange(msg)
    My.curMaxCopyId=msg.cur_five_elements
    My.goNextRed(  )
end

function My.IsOpen( )
    return OpenMgr:IsOpen(407) 
end

function My.OpenLv(  )
   local lv = SystemOpenTemp["407"].trigParam
   return lv
end

function My:illusionUpdate( msg )
   My.illusion=msg.illusion
   My.FullIllRed(  )
   My.eIllUpdata()
end

function My:BookUpdate( msg )
    My.book_list = msg.book_list
    My.goNextRed(  )
    My.eBook()
end

function My:ResElementsUnlock(msg)
    if msg.err_code==0 then
        My.unlock_floor = msg.unlock_floor;
        My.eCurMax()
        My.goNextRed(  )
        FiveCarnetTip:Clear()
    else
        UITip.Log(ErrorCodeMgr.GetError(msg.err_code));
    end
end
function My.unLockFloor( unlock_floor )
    local msg = ProtoPool.Get("m_copy_five_elements_unlock_tos");
    msg.unlock_floor=unlock_floor
    ProtoMgr.Send(msg);
end

function My.toGetNat( )
    local msg = ProtoPool.Get("m_copy_nat_intensify_tos");
    ProtoMgr.Send(msg);
end

function My.toBuyIll(buy_times )
    local msg = ProtoPool.Get("m_copy_buy_illusion_tos");
    msg.buy_times=buy_times
    ProtoMgr.Send(msg);
end

function My:getNatBack( msg )
    if msg.err_code==0 then
        My.nat_intensify=msg.nat_intensify
        My.NatRed( )
        My.eNatUpdata()
        My.eNatGetSuc()
    else
        UITip.Log(ErrorCodeMgr.GetError(msg.err_code));
    end
end

function My:UpdateMin( msg )
    My.illusion=msg.illusion
    My.nat_intensify=msg.nat_intensify
    My.FullIllRed(  )
    My.NatRed( )
    My.eNatUpdata()
    My.eIllUpdata()
end

function My:BuyIllusionBack( msg )
    if msg.err_code==0 then
        My.illusion=msg.illusion
        My.buy_illusion_times = msg.buy_illusion_times;
        My.FullIllRed(  )
        My.eIllUpdata()
        My.eIllBuyBack()
        UITip.Log("购买成功")
    else
        UITip.Log(ErrorCodeMgr.GetError(msg.err_code));
    end
end


--初始化五行幻境
function My:InitFvElmt(msg)
    My.curMaxCopyId=msg.cur_five_elements
    My.illusion=msg.illusion
    My.unlock_floor=msg.unlock_floor
    My.buy_illusion_times=msg.buy_illusion_times
    My.nat_intensify=msg.nat_intensify
    My.FullIllRed(  )
    My.NatRed( )
    My.goNextRed(  )
end


function My:Clear(isReconnect)
    --当前最大可以进入层
    My.curMaxCopyId=0
    FiveCarnetTip:Clear()
end

function My:Dispose()
    self:Clear();
end

return My;