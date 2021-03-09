--[[
区域加入
]]
require("UI/UISecretArea/AreaCell")
require("UI/UISecretArea/UISecretAreaSV")
AreaJoin=Super:New{Name="AreaJoin"}
local My = AreaJoin
local WIDTH = 82

local SAMgr = SecretAreaMgr
local SANW = SecretAreaNetwork
My.SelectKey=nil


function My:Init(go)
    self.str=ObjPool.Get(StrBuffer)
    self.go=go
    local trans = go.transform
    local UB = UITool.SetBtnClick
    local CG = ComTool.Get
    local TF = TransTool.FindChild

    self.SVC = UISecretAreaSV:New()
    self.SVC:Init(TF(trans,"bg"))

    UB(trans,"bg/StepBg/InspireBtn",self.Name,self.InspireBtn,self,false)
    self.MoveBtn=TF(trans,"MoveBtn")
    self.NoMove=TF(trans,"NoMove")
    self.moveLab=CG(UILabel,trans,"MoveBtn/Label",self.Name,false)
    UB(trans,"MoveBtn",self.Name,self.OnMoveBtn,self,false)
    UB(trans,"bg/StepBg/StoreBtn",self.Name,self.StoreBtn,self,false)
    self.StoreBtnRed=TF(trans,"bg/StepBg/StoreBtn/red")
    self.HarryBtn=TF(trans,"bg/StepBg/HarryBtn")
    self.HarryBtnRed=TF(trans,"bg/StepBg/HarryBtn/red")
    UB(trans,"bg/StepBg/HarryBtn",self.Name,self.OnHarryBtn,self,false)
    UB(trans,"bg/StepBg/TargetBtn",self.Name,self.OnTargetBtn,self,false)
    self.moveTime=CG(UILabel,trans,"moveTime",self.Name,false)
    self.endTime=CG(UILabel,trans,"bg/StepBg/endTime",self.Name,false)
    self.myFight=CG(UILabel,trans,"bg/StepBg/myFight",self.Name,false)

    ------------info
    local info = TF(trans,"info").transform
    UB(info,"tip",self.Name,self.OnTipBtn,self,false)
    self.nameLab=CG(UILabel,info,"nameLab",self.Name,false)
    self.numLab=CG(UILabel,info,"numLab",self.Name,false)
    self.unKnow=TF(info,"prop/unKnow")
    self.Cell=ObjPool.Get(UIItemCell)
    self.Cell:InitLoadPool(TF(info,"prop").transform,0.8,nil,nil,nil,Vector3.New(129.6,-1.5))
    self.infoGrid=CG(UIGrid,info,"Grid",self.Name,false)
    local infoGrid = self.infoGrid.transform
    self.timeLab=CG(UILabel,infoGrid,"timeLab",self.Name,false)
    self.actualTimeLab=CG(UILabel,infoGrid,"actualTimeLab",self.Name,false)
    self.hasTime=CG(UILabel,infoGrid,"hasTime",self.Name,false)
    self.now=TF(infoGrid,"now")
    self.Slider=CG(UISlider,infoGrid,"now/Slider",self.Name,false)
    self.SliderVal=CG(UILabel,infoGrid,"now/SliderVal",self.Name,false)
    --self.fightLab=CG(UILabel,infoGrid,"fightLab",self.Name,false)
    self.recommendLab=CG(UILabel,infoGrid,"recommendLab",self.Name,false)
    self.otherName=CG(UILabel,infoGrid,"otherName",self.Name,false)
    self.otherFight=CG(UILabel,infoGrid,"otherFight",self.Name,false)
    self.family=TF(infoGrid,"familyLab")
    self.familyLab=CG(UILabel,infoGrid,"familyLab/Label",self.Name,false)
    --self.canFight=CG(UILabel,infoGrid,"canFight",self.Name,false)


    self.timer2=ObjPool.Get(DateTimer)
    self.timer2.invlCb:Add(self.GatherInvlCbCb,self)
    self.timer2.complete:Add(self.GatherCompleteCb,self)

    My.SelectKey = nil
end

function My:SetEvent(fn)
    SAMgr.eTime[fn](SAMgr.eTime,self.EndTimeTip,self)
    SAMgr.eInit[fn](SAMgr.eInit, self.InitData, self)
    SAMgr.eMoveNum[fn](SAMgr.eMoveNum, self.UpdateMove, self)
    SAMgr.eNight[fn](SAMgr.eNight,self.OnNight,self)
    SAMgr.eInspireNum[fn](SAMgr.eInspireNum,self.OnInspireNum,self)
    SAMgr.ePlayerInfo[fn](SAMgr.ePlayerInfo,self.OnPlayerInfo,self)
    SAMgr.eClickCell[fn](SAMgr.eClickCell, self.ClickCell, self)
    SAMgr.ePlunderHistory[fn](SAMgr.ePlunderHistory,self.UpdateHistroryRed,self)
    SAMgr.eUpdateCellInfo[fn](SAMgr.eUpdateCellInfo, self.UpdateCellInfo, self)
    SAMgr.eGood[fn](SAMgr.eGood,self.ShowStoreBtnRed,self)
end

--==============================--
--初始化网格/数据
function My:InitData()
    self:UpdateSelfPos()
    self:UpdateMove()
end

--更新地图网格
function My:UpdateSelfPos()
    local origin = SAMgr.Origin
    self.SVC:UpdateCells(origin.x, origin.y)
    self.SVC:ResetOrigin()
end


--更新右侧属性
function My:UpdateInfo(info)
    if info then
        local key = tostring(info.type_id)
        local temp = SecretData[key]
        local role = (info.role and info.role.role_id==User.instance.MapData.UIDStr)and info.role or nil
        if temp then 
            self:BaseInfo(info, temp) --显示格子的基本信息
            self:UpdateTime(temp,role)
        end
    else
        self:ResetBaseInfo()
        self:UpdateTime()
    end
    self:OnRoleInfo(info)
end

--更新基础信息
function My:BaseInfo(pro, temp,po)
    self.nameLab.text = UIMisc.LabColor(temp.qua)..temp.name.."[-]"
    self:ResourceInfo(pro, temp)
    self:BossInfo(temp)
end

function My:ResetBaseInfo()
    self.nameLab.text = "未知迷雾"
    self.numLab.text = "[F4DCBEFF]采集次数: 未知"
    self.timeLab.text = "默认效率: 未知"
    self.actualTimeLab.text="实际效率: 未知"
    self.recommendLab.gameObject:SetActive(false)
    self.Cell:SetActive(false)
    self.unKnow:SetActive(true)
end

--更新资源数据
function My:ResourceInfo(info, temp)
    local propList = temp.propList
    local v = temp.num
    if info.num ~= nil then v = info.num end
    local l = temp.num
    local color = v==0 and "[-][CC2500FF]" or ""
    self.numLab.text = string.format( "[F4DCBEFF]采集次数: %s%s/%s",color,v,l)
    self.Cell:UpData(propList[1],propList[2])
    self.Cell:SetActive(true)
    self.unKnow:SetActive(false)
    if v==0 then --清空资源图片
        local cell = self.SVC.CellDic[info.key]
        if cell then cell:LoadProp(nil) end
    end
end

--更新角色
function My:OnRoleInfo(info)
    local ishasTime,isnow,isfightLab,isotherName= false,false,false,false
    if info then
        local temp = SecretData[tostring(info.type_id)]
        if temp then
            local role = info.role
            if role then
                local role_id = role.role_id
                if role_id == User.instance.MapData.UIDStr then  --自己
                    ishasTime=true
                    isnow = info.num > 0
                    self:UpdatePlayerInfo(info)
                else      
                    isotherName=true
                    local isCommonFamily =self:IsCommonFamily(role.fid)
                    self:SetName(isCommonFamily,role)
                    self.otherFight.text="玩家战力: "..role.power   
                end
            end
            self.family:SetActive(temp.familyAdd~=nil)
            --self.canFight.gameObject:SetActive(temp.fight~=nil)
            self:SetFamily(info,temp,role)
            --self:SetCanFight(temp)
        end
    end

    self.hasTime.gameObject:SetActive(ishasTime)
    self.now:SetActive(isnow)
    self.otherFight.gameObject:SetActive(isotherName)
    self.otherName.gameObject:SetActive(isotherName)
    self.infoGrid:Reposition()
    if not info then self.family:SetActive(false) end
end

function My:SetName(isCommonFamily,role)
    local color = ""
    if isCommonFamily==true then color="[-][00FF00FF]" end
    self.otherName.text=string.format( "[F4DCBEFF]当前玩家: %s%s",color,role.name)
end

function My:SetFamily(info,temp,role)
    local fight = role~=nil and role.power or 0
    local isFamilyAdd = false
    local isRoundFamily,isFight = false,false
    if info.x==SAMgr.Origin.x and info.y==SAMgr.Origin.y then 
        isFamilyAdd = role~=nil and role.isFamilyAdd or false
        --isRoundFamily=self:IsRoundFamily()
        isFight=self:IsFight(temp,fight)
    end
    self.str:Dispose()
    local familyAdd = temp.familyAdd
    local familyColor = isFamilyAdd==true and "[00FF00FF]" or "[726C62FF]"
    if familyAdd then self.str:Apd(familyColor):Apd("相邻格子有道庭成员采集时间缩短"):Apd(familyAdd):Apd("%[-]\n\n")end
    if temp.fight then 
        local fightColor = isFight==true and "[00FF00FF]" or "[726C62FF]"
        self.str:Apd(fightColor):Apd("达到推荐战力采集时间减少"):Apd(temp.fight[2]):Apd("分钟[-]")
    end
    self.familyLab.text=self.str:ToStr()
end

-- function My:SetCanFight(temp)
--     local fight = temp.fight
--     if fight then 
--         local time = temp.needtime-fight[2]
--         self.canFight.text=string.format( "战力达标: %s分钟/次",time)
--     end
-- end

function My:IsCommonFamily(fid)
    local info = SAMgr.NightRoundDic[string.format("%s_%s", SAMgr.Origin.x, SAMgr.Origin.y)]
    if info==nil then return end
    return info.role.fid==fid and fid~="0"
end

function My:IsRoundFamily(fid)
    local info = SAMgr.NightRoundDic[string.format("%s_%s", SAMgr.Origin.x, SAMgr.Origin.y)]
    if not info then return false end
    if not info.role then return false end
    local fid = info.role.fid
    if fid=="0" then return false end
    local dic = SAMgr.NightRoundDic
    local rid = User.instance.MapData.UIDStr
    for k,v in pairs(dic) do
        if v.role and v.role.fid==fid and tostring(v.role.role_id)~=rid  then return true end
    end
    return false
end

function My:IsFight(temp,fight)
    if not temp.fight then return false end
    return fight>=temp.fight[1]
end

--更新主角信息
function My:UpdatePlayerInfo(info)
    if info then
        local role = info.role
        if role and role.role_id == User.instance.MapData.UIDStr then
            local needTime = SAMgr.CollectEndTime-DateTool.GetServerTimeSecondNow()
            local temp = SecretData[tostring(info.type_id)]
            if temp then 
                self.timer2:Stop()
                if needTime > 0 then
                    self.timer2.seconds=needTime
                    self.Slider.value=self.timer2:GetRestTime()/(temp.needtime*60)
                    self.SliderVal.text= DateTool.FmtSec(needTime,0,0)
                    self.timer2:Start()
                end
            end    
            self.hasTime.text= string.format("已采集:%s次",SAMgr.CollectNum)
        end
    end
    --self:UpdateFightValue(info)
end

--更新采集效率
function My:UpdateTime(temp,role)
    local str = "默认效率: 未知"
    local str1 = "实际效率: 未知"
    if temp then 
        local fight = temp.fight
        local fAdd=temp.familyAdd
        local time = temp.needtime
        local time1 = time
        if fight then   
            if SAMgr.Power >= fight[1] then
                time1 = time1 - fight[2]
            end
        end 
        if fAdd and role then
            local isFamily=role.isFamilyAdd
            if isFamily==true then 
                time1 = time1 - time*fAdd/100
            end
        end
        str = string.format("默认效率: %s分钟/次",time)
        str1 = string.format("实际效率: %s分钟/次",time1)
    end
    self.timeLab.text = str
    self.actualTimeLab.text=str1
end

function My:UpdateMove()
    --下面按钮数据 
    local num = SAMgr.MoveNum 
    self.moveTime.text= string.format("行动次数：%s", num) 
    if num == 0 then
        UITool.SetGray(self.MoveBtn,false)
        --self:OnMoveBtn()
    else
        UITool.SetNormal(self.MoveBtn)
    end
end

function My:UpdateHistroryRed()
    --拦截红点
    self.HarryBtnRed:SetActive(SAMgr.IsPlunderRed==true)
end

--更新boss数据
function My:BossInfo(temp)
    local type=temp.type
    if type==2 then 
        local color = SAMgr.Power>=temp.fight[1] and "[-][00FF00FF]" or "" 
        self.recommendLab.text = string.format("[F4DCBEFF]推荐战力: %s%s",color,temp.fight[1]) 
    end
    self.recommendLab.gameObject:SetActive(type==2)
end

-- --更新战斗力
-- function My:UpdateFightValue(info)
-- 	local fighting = 0
--     if info then
--         local role = info.role
--         if role and role.role_id == User.instance.MapData.UIDStr then
--             fighting = role.power
--         end
--     end
-- 	if self.fightLab then
-- 		self.fightLab.text = string.format("我的战力: %s",fighting)
-- 	end
-- end



--确认回调，进行拦截
function My:plunderCb()
    local cell = self.SVC.SelectCell
    if not cell or LuaTool.IsNull(cell.Root) == true then return end
    local info = SAMgr.NightRoundDic[cell.Root.name]
    if not info then return end
    local role = info.role
    if role then
        SANW.ReqPlunder(tonumber(role.role_id))
    end
end

--确认回调 ，请求进行移动
function My:MoveCb()
    local cell = self.SVC.SelectCell
    if cell and LuaTool.IsNull(cell.Root) == false then
        local list = StrTool.Split(cell.Root.name, "_")
        SANW.ReqShift(tonumber(list[1]), tonumber(list[2]))
    end
end

--==============================--
--刷新格子数据
function My:UpdateCellInfo(key)
    self.SVC:SetItemDataForKey(key)
    if My.SelectKey ~= key then return end
    self:UpdateSelectInfo()
end

--显示资源仓库红点
function My:ShowStoreBtnRed()
    self.StoreBtnRed:SetActive(SAMgr.IsGoodRed)
end

--更新九宫位置
function My:OnNight(value)
    self.SVC:UpdateNight(value)
end

function My:OnInspireNum()
    self:OnSelectCell()
    local ui = UIMgr.Get(MsgBox.Name)
    if ui then
        local msg = self:GetInspireMsg()
        ui.msgLbl.text=msg
    end
end

function My:OnPlayerInfo()
    self:OnSelectCell()
    self:UpMyFight()
end

--更新鼓舞次数
function My:OnSelectCell()
    local origin = SecretAreaMgr.Origin
    if My.SelectKey ~= string.format("%s_%s",origin.x,origin.y) then return end
    self:UpdateSelectInfo()
end
--==============================--
--点击格子事件回调
function My:ClickCell(key)
    My.SelectKey = key

    self:UpdateSelectInfo() 
--    local info = self:UpdateSelectInfo()
--     --如果是在移动状态且非自己的格子则确认是否移动
--     if SAMgr.IsMove==true then
--         local svc = self.SVC
--         local cell = svc.SelectCell
--         local origin = SAMgr.Origin
--         local k = string.format("%s_%s",origin.x,origin.y)
--         if key==k then
--             --MsgBox.ShowYesNo("你已在当前单元格")
--             return
--         end
--         if not info then
--             UITip.Error("不在移动范围，无法移动")
--             --MsgBox.ShowYesNo("未探索区域，不能移动")
--             return
--         end
--         if cell.isNight==false then
--             UITip.Error("不在移动范围，无法移动")
--             --MsgBox.ShowYesNo("超过可移动距离")
--             return
--         end
--         local role = info.role
--         if role then
--             if role.role_id ~= User.MapData.UIDStr then
--                 local msg="[size=24]是否对该玩家进行拦截？拦截成功将互换位置，夺取格子资源的采集权\n[/size][size=20][67cc67]（拦截战力更高的玩家会失败[/size][size=26]，[/size][size=20]无论是否拦截\n成功都会消耗[/size][size=26]1[/size][size=20]点行动次数）[-][/size]"
--                 MsgBox.ShowYesNo(msg,self.plunderCb,self)
--                 return
--             end
--         end
--         local msg = "[size=24]是否移动至该格？移动后会自动开始进行采集[/size]\n[size=20][67cc67]（移动至有剩余采集次数的格子将消耗[/size][size=26]1[/size][size=20]点行动次数）[-][/size]"
--         MsgBox.ShowYesNo(msg,self.MoveCb,self)
--     end
end

function My:UpdateSelectInfo()
    local key = My.SelectKey
    local info = SAMgr.NightRoundDic[key]
    if not info then
        info = SAMgr.LatticeDic[key]    
    end
    self:UpdateInfo(info)
    local isMove = false
    if info then 
        isMove=SecretAreaMgr.IsMoveArea(info.x,info.y)
    end
    self.MoveBtn:SetActive(isMove==true)
    self.NoMove:SetActive(isMove==false)

    self.infoGrid:Reposition()
    return info
end

--点击移动按钮
function My:OnMoveBtn()
    local key = My.SelectKey
    local info = SAMgr.NightRoundDic[key]
    local role = info.role
    if role then
        if role.role_id ~= User.MapData.UIDStr then
            local msg="[size=24]是否对该玩家进行拦截？拦截成功将互换位置，夺取格子资源的采集权\n[/size][size=20][67cc67]（拦截战力更高的玩家会失败[/size][size=26]，[/size][size=20]无论是否拦截\n成功都会消耗[/size][size=26]1[/size][size=20]点行动次数）[-][/size]"
            MsgBox.ShowYesNo(msg,self.plunderCb,self)
            return
        end
    end
    local msg = "[size=24]是否移动至该格？移动后会自动开始进行采集[/size]\n[size=20][67cc67]（移动至有剩余采集次数的格子将消耗[/size][size=26]1[/size][size=20]点行动次数）[-][/size]"
    MsgBox.ShowYesNo(msg,self.MoveCb,self)

    -- self.SVC:ResetOrigin()
    -- local ismove = SAMgr.IsMove==false and true or false
    -- local text = ismove==true and "停止移动" or "移动"
    -- self.moveLab.text=text
    -- SAMgr.IsMove=ismove
    -- self.SVC:SetCanMove()
end

--计时
function My:GatherInvlCbCb()
    local key = My.SelectKey
    if StrTool.IsNullOrEmpty(key) then return end
    local info = SAMgr.LatticeDic[key]
    if not info then return end
    local temp = SecretData[tostring(info.type_id)]
    if not temp then return end
    self.Slider.value=self.timer2:GetRestTime()/(temp.needtime*60)
    self.SliderVal.text=self.timer2.remain 
end

function My:GatherCompleteCb()
    self.Slider.value=0.0
    self.SliderVal.text="收获中..." 
end

--==============================--


--仓库
function My:StoreBtn()
    UIMgr.Open(UIStoreHouse.Name)
end

--激励
function My:InspireBtn()
    local msg = self:GetInspireMsg()
    MsgBox.ShowYesNo(msg,self.InspireCb,self,"鼓舞",nil,nil,nil,nil,nil,nil,nil,nil,nil,false)
end

function My:GetInspireMsg()
    self.str:Dispose()
    local data = GlobalTemp["170"]
    local val2 = data.Value2
    local val1 = data.Value1
    local price = RoleAssets:GetTypeName(val2[1])
    self.priceTp=val2[1]
    self.priceNum=val2[2]
    self.str:Apd("是否花费"):Apd(val2[2]):Apd(price):Apd("进行鼓舞，增加")
    :Apd(val1[1].id):Apd("%战力?\n(鼓舞提升战力仅限当天结算前有效)\n\n\n                                   已鼓舞次数：")
    :Apd(SAMgr.InspireNum):Apd("/"):Apd(val1[2].id)
    return self.str:ToStr()
end

function My:InspireCb()
    local IsEnough=RoleAssets.IsEnoughAsset(self.priceTp,self.priceNum)
    if IsEnough then
        SANW.ReqInspire()
    else
        MsgBox.isClose=true
        StoreMgr.JumpRechange()
    end
end

function My:OnButton()
    self.SVC:ResetOriginCells()
end

--拦截
function My:OnHarryBtn() 
    SAMgr.IsPlunderRed=false
    SAMgr.UpdateRed()
    SAMgr.WritePlunderRed()
    self:UpdateHistroryRed()
    UIMgr.Open(MsgTip.Name,self.MsgTip,self)
end     

--指向玩家
function My:OnTargetBtn(  )
    self.SVC:ResetOriginCells()
end

--显示玩法提示
function My:OnTipBtn()
    local cur = 2000;
    local str=InvestDesCfg[tostring(cur)].des;
    UIComTips:Show(str, Vector3(-106,200,0),nil,nil,7,700,UIWidget.Pivot.TopLeft);
end

function My:MsgTip(name)
    local ui = UIMgr.Get(name)
    if ui then 
       local kvList = SecretAreaMgr.PlunderHistory
       local len = #kvList
       if len > 0 then
            for i=1,len do
                local kv = kvList[i]
                self.str:Dispose()
                local time =  DateTool.GetDate(kv.k)
                self.str:Apd("[99886BFF]您在"):Apd(time.Year):Apd("年"):Apd(time.Month):Apd("月"):Apd(time.Day):Apd("日"):Apd(time.Hour):Apd("时"):Apd(time.Minute):Apd("分"):Apd(time.Second):Apd("秒"):Apd("遭到[-][FF0000FF]"):Apd(kv.v):Apd("[-][99886BFF]的拦截！[-]")
                local text = self.str:ToStr()
                ui:ShowLab(text)
            end
        else
            self.str:Dispose()
            self.str:Apd("[99886BFF]【上仙运气不错，暂时没有遭遇其他玩家的拦截】")
            local text = self.str:ToStr()
            ui:ShowCenterLab(text)
       end
    end
end

function My:EndTimeTip(time)
    self.endTime.text=string.format("[f9ab47]距离结束：[-][f4ddbd]%s[-]", time)
end

function My:UpMyFight()
    self.myFight.text=string.format("[f9ab47]我的战力：[-][f4ddbd]%s[-]", SAMgr.Power)
end

function My:Open()
    self:SetEvent("Add")
    self.go:SetActive(true)
    self:EndTimeTip(SecretAreaMgr.timer.remain)
    self:UpMyFight()
end

function My:Close()
    self.SVC:Clean()
    SAMgr.IsMove=false
    self.moveLab.text="移动"
    My.SelectKey = nil
    self:SetEvent("Remove")
    self.go:SetActive(false)
end

function My:Dispose()
    self:Close()
    self.SVC:Dispose()
    SAMgr.IsMove=false
    if self.str then ObjPool.Add(self.str) self.str=nil end
    if self.timer2 then self.timer2:AutoToPool() self.timer2=nil end
end