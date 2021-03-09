require("UI/UIEquip/Tg1")
require("UI/UIEquip/Tg2")
require("UI/UIEquip/Tg3")
require("UI/UIEquip/Tg4")
require("UI/UIEquip/Tg5")
require("UI/UIEquip/Tg6")
require("UI/Base/EquipTgBase")

EquipTg=EquipTgBase:New{Name="EquipTg"}
local My = EquipTg

function My:InitCustom(go)
    local TF=TransTool.FindChild

   local g1 = ObjPool.Get(Tg1)
   g1:Init(TF(self.trans,"tg1"),TF(self.trans,"TipPanel/Suit"))

   local g2 = ObjPool.Get(Tg2)
   g2:Init(TF(self.trans,"tg2"))

   local g3 = ObjPool.Get(Tg3)
   g3:Init(TF(self.trans,"tg3"),TF(self.trans,"TipPanel/GemTip"))

   local g4 = ObjPool.Get(Tg4)
   g4:Init(TF(self.trans,"tg4"))

   local g5 = ObjPool.Get(Tg5)
   g5:Init(TF(self.trans,"tg5"))

   local g6 = ObjPool.Get(Tg6)
   g6:Init(TF(self.trans,"tg6"))

   table.insert( self.tgList, g1 )
   table.insert( self.tgList, g2 )
   table.insert( self.tgList, g3 )
   table.insert( self.tgList, g4 )
   table.insert( self.tgList, g5 )
   table.insert( self.tgList, g6 )

   self:InitTog(6)

   if not self.eWitchTg then  self.eWitchTg=Event() end

   for i=1,6 do
       local open = OpenMgr:IsOpen(EquipMgr.sysDic[tostring(i)])
       self.togList[i].gameObject:SetActive(open)
       self:ChangeRed(i)
   end
end

function My:SwitchTgCustom()
    local curTg = self.tgList[self.bTp]
    if curTg.SwitchTg then curTg:SwitchTg(self.sTp) end
    UIEquip.bTp=self.bTp
    self.eWitchTg()
end

function My:SetEvent(fn)
    EquipMgr.eChangeRed[fn](EquipMgr.eChangeRed,self.ChangeRed,self)
    PropMgr.eRemove[fn](PropMgr.eRemove,self.PropRmove,self)
	PropMgr.eAdd[fn](PropMgr.eAdd,self.PropAdd,self)
	PropMgr.eUpNum[fn](PropMgr.eUpNum,self.PropUpNum,self)
end

function My:ChangeRed(tp)
    local red = self.togRedList[tp]
    local isred = EquipMgr.redBool[tostring(tp)] or false
    red:SetActive(isred)
end

function My:PropRmove(id,tp,type_id,action)
    if tp~=1 then return end
	self:UpTgData(type_id)
end

function My:PropAdd(tb,action,tp)
	if tp~=1 then return end
	self:UpTgData(tb.type_id)
end

function My:PropUpNum(tb,tp,num,action)
	if tp~=1 then return end
	self:UpTgData(tb.type_id)
end

function My:UpTgData(type_id)
	local item = UIMisc.FindCreate(type_id)
	local uFx = item.uFx
    local tg = self.tgList[self.bTp]
    local tb = EquipMgr.hasEquipDic[tostring(EquipPanel.curPart)]
	if uFx==31 then --宝石
        if tg and self.bTp==3 then tg:UpData(tb) end
    elseif uFx==77 then --文印
        if tg and self.bTp==5 then tg:UpData(tb) end
	elseif uFx==1 then --装备
		
	else --道具
        if tg and (self.bTp==2 ) then tg:UpData(tb) end
        if tg and (self.bTp==4 ) then 
            local htb = EquipMgr.hasEquipDic[tostring(HnEPanel.curPart)]
            tg:UpData(htb,HnEPanel.curPart) 
        end
	end
end