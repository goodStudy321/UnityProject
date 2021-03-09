--加载脚本
require("UI/UIFiveNat/FiveBarrierItem")
require("UI/UIFiveNat/FiveBtnOnMap")
require("UI/UIFiveNat/FiveBuytip")
require("UI/UIFiveNat/FiveCopyTip")
require("UI/UIFiveNat/FiveMap")
require("UI/UIFiveNat/FiveMosterTip")
require("UI/UIFiveNat/FiveNextShow")
require("UI/UIFiveNat/FiveNextShowItem")
require("UI/UIFiveNat/FiveNextTip")
require("UI/UIFiveNat/FivePropertyTip")
require("UI/UIFiveNat/FiveNatShow")
require("UI/UIFiveNat/FiveRank")
require("UI/UIFiveNat/MyFiveRankItem")
require("UI/UIFiveNat/FiveNextMsg")
--end
FiveCopyHelp={Name="FiveCopyHelp"}
local My = FiveCopyHelp
My.fvElmtDefs={}
local defs = My.fvElmtDefs;
defs[ProType.Metal_Atk] = "metalDef";
defs[ProType.Wood_Atk] = "woodDef";
defs[ProType.Water_Atk] = "waterDef";
defs[ProType.Fire_Atk] = "fireDef";
defs[ProType.Soil_Atk] = "soilDef";
local AtkFvLst = {ProType.Metal_Atk,ProType.Wood_Atk,ProType.Water_Atk,ProType.Fire_Atk,ProType.Soil_Atk }
My.AtkFvLst=AtkFvLst
----------------------------------------------------
---
My.txtUload={}
--当前副本id
My.curCopyId=0
--当前层
My.CurFloor=0;
--第一个副本Id
My.FistCopyId=70101
--当前通关副本
My.curMaxCopyId=0
--应该挑战副本
My.ChallengeId=0
--当前解锁层
My.UnLockFloor=0
--最大管卡数量
My.MaxCopyLv=24
--地图上副本选中
My.CurMapSlct=nil
--最大幻力
My.illMax=0
--幻力恢复
My.illSpeed=0
--天机勾玉最大
My.natMax=0
--天机勾玉恢复
My.natSpeed=0
--天机yu一次购买价格
My.natOnceGet=0
--天机yu一次购买数量
My.natOnceCostLst={}
--幻力id
My.illItemNum=25
--幻力图片
My.illIconTxt="25.png"
--天机图片
My.naxIconTxt="700006.png"
--玩家id
My.playId=0
--event
    My.ShowOnClick=Event()
--end
----------------------------------------------------------
--打开面版
function My.OpenFiveBigan( )
    My.PlayIdUpdate()
    My.ChangeChallenge( )
    My.IllNatChange()
    My.BuyBasInfo( )
    FiveNextShow:Open()
    FiveMap:UpdateLever()
    FiveNatShow:UpdateInfo()
    FiveBtnOnMap:UnLockfloor()
    FiveBtnOnMap:UpdateFloor()
    FiveNextMsg:Close()
end

function My.PlayIdUpdate(  )
    My.playId=User.MapData.UID
end

function My.BuyBasInfo( )
    local glMsg = GlobalTemp["156"].Value2
    local glMsg1 = GlobalTemp["156"].Value1
    My.natOnceGet=glMsg1[1].id
    for i=1,#glMsg do
        My.natOnceCostLst[i]=glMsg[i]
    end
end
function My.mathCostAll(num  )
    local start = FiveElmtMgr.buy_illusion_times
    local AllCost = 0
    for i=start+1,start+num do
      local msg = My.natOnceCostLst[i]
      if msg==nil then
          iTrace.Error("soon","glb表156没有配置当前的价钱"..i)
          return AllCost
      end
      AllCost=AllCost+msg
    end
    return AllCost
end

function My.IllNatChange()
    local msg = FiveElmtMgr.floorMsg[My.UnLockFloor]
    My.illMax=msg.illMax
    local decimal =msg.illSpeed*60
    decimal = math.floor(decimal +0.5)  
    My.illSpeed=decimal
    My.natMax=msg.natMax
    My.natSpeed=msg.natSpeed
end
--改变最大层数
function My.FloorChange( )
    My.CurFloor=FiveElmtMgr.unlock_floor
    My.OpenFiveBigan( )
    My.OpenTip(FiveNextTip)
    FiveNextMsg:Close()
end

function My:toSendRank( )
    RankNetMgr:ReqRankInfo(10010)
end

function My.OpenTip( tip )
    local name = tip.Name
    if name=="FiveNextTip" then
        FiveCopyTip:OpenFiveNextTip()
    elseif name=="FivePropertyTip" then
        FiveCopyTip:OpenFivePropertyTip()
    elseif name=="FiveMosterTip" then
        FiveCopyTip:OpenFiveMosterTip()
    elseif name=="FiveRank" then
        FiveCopyTip:OpenFiveRankTip()
    elseif name=="FiveBuytip" then
        FiveCopyTip:OpenFiveBuytip()
    end
end

function My.changeFloor( num )
    My.CurFloor=My.CurFloor+num
    My.ChangeChallenge( )
    FiveNextShow:Open()
    FiveMap:UpdateLever()
    FiveBtnOnMap:UpdateFloor()
end

function My.ChangeChallenge( )
    My.UnLockFloor=FiveElmtMgr.unlock_floor
    My.CurFloor=My.CurFloor==0 and FiveElmtMgr.unlock_floor or My.CurFloor
    My.curMaxCopyId= FiveElmtMgr.curMaxCopyId 
    if FiveElmtMgr.curMaxCopyId==0  then
        My.ChallengeId= My.FistCopyId 
    else
        local msg = FvElmntCfg[tostring(My.curMaxCopyId)]
        if msg.layer~=My.UnLockFloor then
            My.ChallengeId= FiveElmtMgr.floorMsg[My.UnLockFloor].CopyLst[1]
        else
            My.ChallengeId=My.curMaxCopyId+1
        end
    end
end

--打开提示

--事件监听
function My.lnsr( fun )
    FiveElmtMgr.eIllUpdata[fun]( FiveElmtMgr.eIllUpdata,My.IllChange)
    FiveElmtMgr.eNatUpdata[fun]( FiveElmtMgr.eNatUpdata,My.NatChange)
    FiveElmtMgr.eCurMax[fun]( FiveElmtMgr.eCurMax,My.FloorChange)
    FiveElmtMgr.eNatGetSuc[fun]( FiveElmtMgr.eNatGetSuc,My.GetNatBack)
    FiveElmtMgr.eGoNextRed[fun]( FiveElmtMgr.eGoNextRed,My.UpdatNextRed)
    FiveElmtMgr.eIllBuyBack[fun]( FiveElmtMgr.eIllBuyBack,My.IllBuySuc)
    FiveElmtMgr.eBook[fun]( FiveElmtMgr.eBook,My.BookUpdate)
    CopyMgr.eUpdateCopyCleanReward[fun]( CopyMgr.eUpdateCopyCleanReward,My.UpdateCopyCleanReward)
end
function My.BookUpdate(  )
    FiveNextShow:Open()
end
function My.IllBuySuc(  )
    FiveBuytip:UpDateTimes()
end

function My.UpdatNextRed(  )
    FiveNextShow:GoNextRed( )
end

function My.GetNatBack(  )
   FiveNatShow:ShowGetEff()
end

function My.UpdateCopyCleanReward()
	UIMgr.Open(UIGetRewardPanel.Name, My.UpdateGetRewardData)
end
function My.UpdateGetRewardData(name)
	local ui = UIMgr.Dic[name]
	if ui then
		local rewards = CopyMgr.CopyCleanRewards
		local list = nil
		if rewards then
			list = {}
			for i,v in ipairs(rewards) do
				local data = {}
				data.k = v.k
                data.v = v.v
                data.b = false
                if  data.v~=0 and data.v~="0" then
                    table.insert(list,data)
                end
			end
		end
		if not list then ui:Close() return end
		ui:UpdateData(list)
	end
end

--更新幻力
function My.IllChange(  )
    FiveBtnOnMap:UpDateIll()
    FiveBuytip:UpDateIll()
end
--更新勾玉
function My.NatChange(  )
    -- FiveBtnOnMap:UpdateNat()
    FiveNatShow:UpdateInfo()
end
----------------------------------------得到属性             
function My.GetMostFiveElm(monsId)
    local AllNum = 0
   for i=1,#AtkFvLst do
    AllNum=AllNum+My.GetFvElmntDef(monsId,AtkFvLst[i])
   end
   return AllNum
end

--获取五行抗性(根据五行攻击属性获取对应五金抗性)
function My.GetFvElmntDef(monsId,fvAtk)
    monsId = tostring(monsId);
    local fvDef = defs[fvAtk];
    local info = MonsterTemp[monsId];
    if info == nil then
        return 0;
    end
    local val = info[fvDef];
    if val == nil then
        return 0;
    end
    return val;
end
--获取玩家属性数字
function My.GetAllRoleElmtNum()
    local AllNum = 0
    for i=1,#AtkFvLst do
     AllNum=AllNum+My.FvRoleElmtNum(AtkFvLst[i])
    end
    return AllNum
end
function My.FvRoleElmtNum(attrId)
    local val = My.GetFvElmtStr(attrId);
    if val == nil then
        val = 0;
    end
    val = tonumber(val);
    return val;
end
function My.GetFvElmtStr(attrId)
    local actData = User.MapData;
    local strVal = actData:GetBaseProperty(attrId);
    return strVal;
end
-------------------------------------------end
--点击锁定地图位置
function My.SeeMap( itemId )
    My.ShowOnClick(itemId)
end
--选中
function My.MapCopySlct( bariItem )
   if My.CurMapSlct~=nil then
    My.CurMapSlct:SlctActive(false)
   end
   My.CurMapSlct=bariItem
   My.CurMapSlct:SlctActive(true)
   soonTool.ChooseInScrollview(My.CurMapSlct.root,FiveMap.texSv)
end
--提示
function My.OpenMosntTip( )
  My.OpenTip(FiveMosterTip)
end

-------------------------------------
--打开天机印
function My.toUISMS(  )
    UIMgr.Open(UISkyMysterySeal.Name)
    My.ClossAllPanel( )
    JumpMgr:InitJump(UIRobbery.Name,11)
end
--突破下层
function My.goNextFloor(  )
    FiveElmtMgr.unLockFloor(My.UnLockFloor+1)
end
--购买次数
function My.buyIllSend( buyTimes )
    FiveElmtMgr.toBuyIll(buyTimes)
end
--领取奖励
function My.GetNatSend(  )
    FiveElmtMgr.toGetNat()
end
--==============================--

--==============================--
--扫荡副本
function My.toSweepCopy( copyid,num )
   CopyMgr:ReqCopyCleanTos(copyid,num)
end

function My.GetMaxSweepTimes(oneCost)
    if oneCost==0 then
        return 999
    end
    return math.floor( FiveElmtMgr.illusion/oneCost ) 
end

function My.EntrMap( isTip )
    if isTip then
        local desc = "你的五行攻击总属性低于怪物的五行抗性总值，伤害将有所削减，是否继续挑战？"
        MsgBox.ShowYesNo(desc, My.YesCb,My, "确定", My.NoCb,My, "取消");
    else
        My.EntrCopy( )
    end
end
function My.EntrCopy( )
    My.ClossAllPanel( )
    FiveCarnetTip.EnterMapRcd()
    SceneMgr:ReqPreEnter( My.curCopyId,true,true);
end
function My:YesCb(  )
    My.EntrCopy( )
end
function My:NoCb(  )
end

function My.ClossAllPanel(  )
    UIRobbery:OnClickCloseBtn()
end

--==============================----
function My.ClearLoad( )
    local len = #My.txtUload
    for i=len,1,-1 do
        AssetTool.UnloadTex(My.txtUload[i])
       table.remove( My.txtUload, i )
    end
    return  #My.txtUload
end

function My.Clear(  )
    My.CurFloor=0;
    My.curMaxCopyId=0
    My.ChallengeId=0
    My.UnLockFloor=0
    My.CurMapSlct=nil
    FiveNextShow:Clear()
    FiveBtnOnMap:Clear()
    FiveCopyTip:Clear()
    FiveMap:Clear()
    My.ClearLoad( )
    soonTool.DesGo("FiveBigItem")
    soonTool.DesGo("FiveSmalItem")
    soonTool.DesGo("FiveRankItem")
    soonTool.DesGo("FiveNextShowItem")
end

return My;