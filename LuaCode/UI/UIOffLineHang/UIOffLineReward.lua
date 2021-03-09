--离线奖励脚本

UIOffLineReward=UIBase:New{Name ="UIOffLineReward"}
local  My = UIOffLineReward
function My:InitCustom()
    --加载根据字段
    local CG = ComTool.Get
    local TFC = TransTool.FindChild
    local TF = TransTool.Find
    local Tip = self.Name
    local Root =self.root
    local ULbRT = TF(Root,"RewardInfo/Info",Tip)
    --加载UIlabel信息
    local ULB = UILabel
    self.OffTime=CG(ULB,ULbRT,"OffTime",Tip)
    self.LvlBefore=CG(ULB,ULbRT,"LvlBefore",Tip)
    self.LvlAfter=CG(ULB,ULbRT,"LvlAfter",Tip)
    self.Exp=CG(ULB,ULbRT,"Exp",Tip)
    self.Coin=CG(ULB,ULbRT,"Coin",Tip)
    self.Pet=CG(ULB,ULbRT,"Pet",Tip)
    self.EqueP=CG(ULB,ULbRT,"EqueP",Tip)
    self.EqueO=CG(ULB,ULbRT,"EqueO",Tip)
    --格子
    self.Grid=TFC(Root.transform,"EquipShow/GetEquip/Grid",Tip)
    self.Glist={}
    --按钮事件
    local UBRT=TF(Root,"btn",Tip)
    local USBC = UITool.SetBtnClick
    USBC(UBRT, "GtBtn", Tip, self.OnClose, self)
    
    --加载方法
    self:ChangeUILB()
end
--文本的改变
function My:ChangeUILB( )
    local ORI = OffRwdMgr    
    local msg =ORI.GetMsg() 
    local my_math =math.NumToStr
    if msg==nil then
        iTrace.Error("soon","发过来数据有问题")
        return
    end
    local time =ORI.TimeStr(msg.offline_min)
    self.OffTime.text = time
    self.LvlBefore.text=UserMgr:chageLv( msg.old_level)
    self.LvlAfter.text=UserMgr:chageLv(msg.new_level)
    self.Exp.text = my_math(tonumber(msg.exp))
    self.Coin.text=my_math(msg.add_silver)
    self.Pet.text=my_math(msg.pet_exp)
    local goods = ORI.GetGoods()
    local e_goods = ORI.GetPetGoods()
    table.sort(goods, My.doSort);
    self:EqueDeal(goods,false)
    self:EqueDeal(e_goods,true)
    self.EqueP.text,self.EqueO.text=self:EqueText(goods,#e_goods)
end
function My.doSort( a,b )
    local aitem = ItemData[tostring( a.type_id)]
    local bitem = ItemData[tostring( b.type_id)]
    if aitem==nil or bitem==nil then
        return  false
    end
    return aitem.quality>bitem.quality
end
--武器处理
function  My:EqueDeal( blist,isEat)
    for i=1,#blist do
        self:AddCell(blist[i],self.Grid,isEat)
    end
end
function My:AddCell( good, grid,isEat)
    local cell = ObjPool.Get(UIItemCell)
    local key = good.type_id
    cell:InitLoadPool(grid.transform)
    cell:UpData(key,good.num)
    cell:Devour(isEat)
	table.insert(self.Glist, cell)
end
--武器文本处理
function My:EqueText(GP,EP)
    local p_color=0
    local o_color = 0
      for i=1,#GP do
            local v = GP[i]
            local item = ItemData[tostring(v.type_id)]
            if item==nil then
                iTrace.Error("soon","存在无效道具,请检查配置表 type_id为 "..v.type_id )
            end
            local qua = item.quality
            if   qua==nil then
                iTrace.Error("soon","存在物品没有品质!id为: "..v.type_id)
            else
                local num =  v.num ~=nil and v.num or 1
                if qua==3 then
                    p_color=p_color + num
                elseif qua==4 then
                    o_color=o_color + num
                end    
            end
        end
    local p_sb = ObjPool.Get(StrBuffer)
    p_sb:Apd("[BA67CC]紫色道具"):Apd(p_color+EP):Apd("件[-]"):Apd("[FFE9BDFF](自动吞噬[00ff00]")
    :Apd(EP):Apd("件[-]"):Apd(")[-]")
    local p_text = p_sb:ToStr()
    ObjPool.Add(p_sb)
    local o_text =string.format( "[E9AC50]橙道具%s件[-]",o_color );
    return p_text , o_text
end

--关闭
function My:OnClose()
    self:Close()
    EvrDayMgr:IsOpenMenu()--是否打开每日累充界面
end
function My:Clear()
    if self.Glist==nil then
        return;
    end
    local len  = #self.Glist
    for i=len,1,-1 do
       local ds= self.Glist[i]
       ds:DestroyGo()
       ObjPool.Add(ds)
       self.Glist[i]=nil
    end
    self.Glist=nil;
end
return My



