--[[
上上签
]]
require("UI/UIDrawLots/UIDrawModel")
UIDrawLots=UIBase:New{Name="UIDrawLots"}
local My = UIDrawLots

function My:InitCustom()
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local U = UITool.SetBtnClick
    local trans = self.root
    if not self.cellList then self.cellList={} end
    if not self.getList then self.getList={} end

    self.modCam=CG(Camera,trans,"modCam",self.Name,false)
    self.modCam.depth=UIMgr.Cam.depth+1
    self.grid=CG(UIGrid,trans,"Panel/Grid",self.Name,false)
    self.grid.onCustomSort=function(a,b) return self:SortName(a,b)end
    self.timeLab=CG(UILabel,trans,"timeLab",self.Name,false)
    self.superRoot=TF(trans,"SuperCell").transform
    self.onceConsume=CG(UILabel,trans,"OnceBtn/Consume/Label",self.Name,false)
    self.tenConsume=CG(UILabel,trans,"TenBtn/Consume/Label",self.Name,false)
    self.onceIcon=CG(UITexture,trans,"OnceBtn/Consume/icon",self.Name,false)
    self.tenIcon=CG(UITexture,trans,"TenBtn/Consume/icon",self.Name,false)
    self.remainLab=CG(UILabel,trans,"remainLab",self.Name,false)

    self.bigCell=ObjPool.Get(UIItemCell)
    self.bigCell:InitLoadPool(self.superRoot)

    self.drawModel=ObjPool.Get(UIDrawModel)
    self.drawModel:Init(self.gbj)
    
    U(trans,"CloseBtn",self.Name,self.Close,self)
    U(trans,"OnceBtn",self.Name,self.OnOnceBtn,self)
    U(trans,"TenBtn",self.Name,self.OnTenBtn,self)
    self:SetEvent("Add")

    self:InitData()
end

function My:SortName(a,b)
	local num1 = tonumber(a.name)
	local num2 = tonumber(b.name)
	if(num1<num2)then
		return -1
	elseif (num1>num2)then
		return 1
	else
		return 0
	end
end

function My:SetEvent(fn)
    DrawLotsMgr.eUp[fn](DrawLotsMgr.eUp,self.UpData,self)
end

function My:InitData( ... )
    self:ShowPrice()
    self:ShowReward()
    self:UpData()
    self:ShowTime()
end

function My:UpData(List)
    self:ShowBigReward()
    self:ShowModel()
    self:ShowGetReward(List)
    self.remainLab.text=string.format( "剩余签数: %s",DrawLotsMgr.remainNum)
end

function My:ShowBigReward( ... )
    local id = DrawLotsMgr.bigReward
    local temp = DrawLotsData[tostring(id)]
    if not temp then iTrace.eError("xiaoyu","上上签表为空 id: "..id)return end
    local type_id = temp.propId
    self.bigId=type_id
    local num = temp.num
    self.bigCell:UpData(type_id,num)
end

function My:ShowReward( ... )
    local activiInfo = NewActivMgr:GetActivInfo("2004")
    local lv=DrawLotsMgr.lv
    for k,v in pairs(DrawLotsData) do
        local lvLimit = v.lvLimit
        if lv>=lvLimit[1] and lv<=lvLimit[2] and v.tp==2 and activiInfo.configNum==v.cIndex then 
            local cell = ObjPool.Get(UIItemCell)
            cell:InitLoadPool(self.grid.transform)
            cell.trans.name=k
            cell:UpData(v.propId,v.num)
            table.insert( self.cellList, cell)
        end
    end
end

function My:ShowPrice( ... )
    local temp = GlobalTemp["182"]
    self.global=temp
    local val = temp.Value1

    local item1 = UIMisc.FindCreate(val[1].id)
    local path1 = item1.icon
    AssetMgr:Load(path1,ObjHandler(self.LoadIcon1,self))
    self.onceConsume.text=tostring(val[1].value)

    local item2 = UIMisc.FindCreate(val[2].id)
    local path2 = item2.icon
    AssetMgr:Load(path2,ObjHandler(self.LoadIcon2,self))
    self.tenConsume.text=tostring(val[2].value)
end

function My:LoadIcon1(obj)
    self.onceIcon.mainTexture=obj
end

function My:LoadIcon2(obj)
    self.tenIcon.mainTexture=obj
end


function My:OnOnceBtn( ... )
    local val = self.global.Value1[1]
    local IsEnough = RoleAssets.IsEnoughAsset(val.id,val.value)
    if IsEnough==false then
        StoreMgr.JumpRechange()
    else
        DrawLotsNetwork.ReqPray(1)
    end
end

function My:OnTenBtn( ... )
    local num = DrawLotsMgr.remainNum
    if num<10 then 
        UITip.Log("剩余抽奖次数不足10次！")
        return 
    end
    local val = self.global.Value1[2]
    local IsEnough = RoleAssets.IsEnoughAsset(val.id,val.value)
    if IsEnough==false then
        StoreMgr.JumpRechange()
    else
        DrawLotsNetwork.ReqPray(10)
    end
end

--显示倒计时
function My:ShowTime()
    local tb = NewActivMgr:GetActivInfo(2004)
    local endTime = tb.endTime or 0
    --iTrace.eError("xiaoyu","   endTime: "..tostring(endTime))
    local lerp =endTime- DateTool.GetServerTimeSecondNow()
    if lerp<=0 then 
        UITip.Log("活动已结束！")
        self:OnComplete()
        self:Close()
        return 
    end
    if not self.timer then 
        self.timeLab.text=string.format( "活动倒计时：%s",DateTool.FmtSec(lerp))
        self.timer=ObjPool.Get(DateTimer)
        self.timer.invlCb:Add(self.OnInvlCb,self)
        self.timer.complete:Add(self.OnComplete, self)
        self.timer.seconds=lerp
        self.timer:Start()
    end
end

function My:OnInvlCb( ... )
    self.timeLab.text=string.format( "活动倒计时：%s",self.timer.remain)
end

function My:OnComplete()
    self.timeLab.gameObject:SetActive(false)
end

function My:ShowModel()
    self.drawModel:UpData(self.bigId)
end

function My:ShowGetReward(List)
    if not List then return end
    local getList = self.getList
    ListTool.ClearToPool(getList)
    for i,v in ipairs(List) do
        local temp = DrawLotsData[tostring(v)]
        local id = temp.propId
        local num = temp.num
        local kv = ObjPool.Get(KV)
        kv:Init(id,num)
        table.insert( getList, kv)
    end
    UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
end

function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(self.getList)
	end
end

function My:DisposeCustom()
    self:SetEvent("Remove")
    if self.timer then self.timer:AutoToPool() self.timer=nil end
    if self.bigCell then self.bigCell:DestroyGo() ObjPool.Add(self.bigCell) self.bigCell=nil end
    while #self.cellList>0 do
        local cell = self.cellList[#self.cellList]
        cell:DestroyGo()
        ObjPool.Add(cell)
        self.cellList[#self.cellList]=nil
    end
    if self.drawModel then ObjPool.Add(self.drawModel) self.drawModel=nil end
end

return My