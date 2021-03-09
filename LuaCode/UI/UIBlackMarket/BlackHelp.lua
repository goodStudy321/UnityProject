BlackHelp={Name="BlackHelp"}
My.ActiveState=true
local My = BlackHelp
My.ItemGoLst={}
My.ActiveId=2003
My.ChooseAllTime=0
My.runtime=0
My.interval=1
My.AllobjLst={}
--创建格子
function My.CreatItem( root )
	local TF = TransTool.Find
	local tip = "UIBlackMarket"
	for i=1,12 do
		local pos = TF(root,"pos"..i,tip)
		local go = soonTool.Get("BlackShowItem",pos)
		table.insert( My.ItemGoLst,go)
	end
end

function My.OpenDo( )
	local msg186 = GlobalTemp["186"]
	My.ChooseAllTime=msg186.Value2[1]
	local msg185 = GlobalTemp["185"]
	My.interval=msg185.Value3
	My.TimeExtent=msg185.Value1
	My.ShowTime()
end

--点击开始
function My.StartClick( )
	if My.timer:GetRestTime()<30 then
		UITip.Log("剩余活动时间不足30秒")
		return
	end
	if BlackMarketMgr.lessTimes<1 then
		UITip.Log("无鉴宝次数")
		return
	end
    if BlackHelp.ActiveState then
        BlackMarketMgr.sendStart()
    else
        UITip.Log("活动结束")
    end
end

function My.StartChoose( )
	My.SetAndStrat( BlackMarketMgr.ItemLst )
	My.ChooseTimeGo(  )
end

function My.SetAndStrat( lst )
	soonTool.ObjAddList(My.AllobjLst)	
	BlackEffShow.Clear()
	local len = #lst
	for i=1,len do
		local strid = tostring(lst[i])
		local obj = ObjPool.Get(BlackShowItem)
		local go =My.ItemGoLst[i]
		local msg = tBlack[strid]
		obj:Init(go)
        obj:SetId(msg,i)
        obj:timeStart()
        My.AllobjLst[i]=obj
	end
end
--选择倒计时
function My.ChooseTimeGo(  )
	if not My.chosetimer then
		My.chosetimer = ObjPool.Get(DateTimer)
	end
	local timer = My.chosetimer
	local seconds = My.ChooseAllTime
	timer:Stop()
	if seconds <= 0 then
		My:chosetimerCompleteCb()
	else
		timer.invlCb:Add(My.chosetimerInvlCb, My)
    	timer.complete:Add(My.chosetimerCompleteCb, My)
		timer.seconds = seconds
		timer.interval=1
		UIBlackMarket:ChoseTime(My.ChooseAllTime)
        timer:Start()
        My:InvlCb()
	end
end
function My:chosetimerInvlCb(  )
	My.runtime=math.floor(My.chosetimer:GetRestTime()+0.5)
	UIBlackMarket:ChoseTime(My.runtime)
	if My.runtime%My.interval~=0 then
		return
	end
	local len = #My.TimeExtent
	local GetTimes = 1
	for i=len,1,-1 do
		local msg =  My.TimeExtent[i]
		local k = msg.id
		if k>=My.runtime then
			GetTimes=msg.value
			break;
		end
	end
	local showlst =  BlackEffShow.GetCanShow( GetTimes )
	My.ShowEffAndAinItem( showlst  )
end
function My.ShowEffAndAinItem( lst  )
	local len = #lst
	for i=1,len do
		My.AllobjLst[lst[i]]:EffAndAniShow()
	end
end
function My:chosetimerCompleteCb(  )
	return
end
--活动时间
function My.ShowTime()
	My.ActiveState=true
    local data =NewActivMgr:GetActivInfo(My.ActiveId)
	if not data then return end 
	local eDate = data.endTime
	local seconds = eDate - TimeTool.GetServerTimeNow()*0.001
	if not My.timer then
		My.timer = ObjPool.Get(DateTimer)
	end
	local timer = My.timer
	timer:Stop()
	if seconds <= 0 then
		My:CompleteCb()
	else
		timer.invlCb:Add(My.InvlCb, My)
    	timer.complete:Add(My.CompleteCb, My)
		timer.seconds = seconds
		timer.fmtOp = 0
        timer:Start()
        My:InvlCb()
	end
end
-- 间隔倒计时
function My:InvlCb()
	local text = self.timer.remain
	UIBlackMarket:TimeLab(text)
end
--结束倒计时
function My:CompleteCb()
	My.ActiveState=false
	UIBlackMarket:TimeLab("活动结束")
end

function My.SendChoose( id )
	BlackMarketMgr.SendExtract(id)
end

function My.extracBack(  )
	UIMgr.Open(UIGetRewardPanel.Name, My.OpenGetRewardCb, My)
end

function My.choseBack(  )
	My.runtime=0
	My.chosetimer:Stop()
end

function My:OpenGetRewardCb(name  )
	local ui = UIMgr.Get(name)
	if ui then
		local BackItem = UIBlackMarket.Showdic
        ui:UpdateData(BackItem)
        TableTool.ClearDic(BackItem)
	end
end

function My.CloseCheck( )
	if My.runtime>0 then
		BlackMarketMgr.SendExtract(BlackMarketMgr.ItemLst[1])
	end
end

function My.Clear(  )
    if  My.timer then
        My.timer:AutoToPool();
        My.timer = nil
	end
	My.CloseCheck( )
	if My.chosetimer then
		My.chosetimer:AutoToPool();
        My.chosetimer = nil
	end
	soonTool.AddList(My.ItemLst,"BlackShowItem")
	soonTool.ClearList(My.ItemGoLst)
	soonTool.ObjAddList(My.AllobjLst)
	soonTool.DesGo("BlackShowItem",bool)
end


return My;