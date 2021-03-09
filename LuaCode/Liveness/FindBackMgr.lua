FindBackMgr={Name="FindBackMgr"};
local My = FindBackMgr;

--红点状态
--现在作废只做次数判断不做红点控制
My.isDot=0;
--新版本
My.Red=false;
--找回信息
My.FindList={};
--开始推送
My.eFind=Event();
My.eFindRed=Event();
--购买之类数据刷新
My.eBuy=Event();

My.CopyLst={};

My.sendOver=false;
My.quckUse=false;

--打开判断返回
My.eStartBacK=Event()
--
My.sendOnce=true
function My:Init()
    self:setLnsr();
end

--设置监听
function My:setLnsr( )
    My.sendOver=false;
    local PA = ProtoLsnr.AddByName;
	PA("m_resource_info_toc",self.reFind, self);
    PA("m_resource_retrieve_toc",self.BuyBack, self);
    CopyMgr.eUpdateCopyStar:Add(self.CopyInfo, self);
    QuickUseMgr.eEndSprite:Add(self.doOtherMsg,self);
end
--副本信息
function My:CopyInfo( type, id)
    local idx = self.CopyLst[type];
    if idx==nil then
        self.CopyLst[type]=id;
    else
        self.CopyLst[type]=id>idx and id or idx ;
    end
end

function My:doOtherMsg(  )
    if My.sendOver==false then
        My.quckUse=true;
      return
    end
    if My.sendOnce then
        if My.isDot>0 then
            QuickUseMgr.OpenFindBack()
        end
        My.eStartBacK(My.isDot>0)
        My.sendOnce=false
    end
end

function My.OpenChangeOver(  )
    My.Red=false;
    LivenessMgr:UpRedDot();
    My.eFindRed()
end

--推送
function My:reFind(msg)
    soonTool.ClearList(self.FindList);
    for i=1,#msg.resource_list do
        local ls = {};
        local ms = msg.resource_list[i];
        ls.id=ms.resource_id;
        ls.bas=ms.base_times;
        My.Red=false
        if ls.bas>0 then
            My.isDot=My.isDot+1;
            My.Red=true
        end
        ls.ext=ms.extra_times;
        ls.extBuyStart=ms.copy_extra_buy_times;
        if ls.extBuyStart==0 or ls.extBuyStart==nil then
            ls.extBuyStart=1
        end
        self.FindList[ls.id]=ls;
    end
    self.eFind();
    My.sendOver=true;
    if My.quckUse then
        My:doOtherMsg(  )
        My.quckUse=false
    end
end
--购买发送
function My:sendBuy(id,type,times)
    local msg = ProtoPool.Get("m_resource_retrieve_tos");
    msg.resource_id=id;
    msg.type=type;
    msg.times=times;
    ProtoMgr.Send(msg);
end
--购买返回
function My:BuyBack(msg)
    if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err);
    else
        local t = self.FindList[msg.resource.resource_id]
        t.bas=msg.resource.base_times;
        t.ext=msg.resource.extra_times;
        if t.bas==0 then
            My.isDot=My.isDot-1;
        end
        self.eBuy(t.id);
        -- if My.isDot==0 then
        --     LivenessMgr:UpRedDot();
        -- end
        UITip.Log("找回成功");
    end
end

function My:Clear( )
    self.isDot=0;
    My.sendOnce=true
end

return My;
