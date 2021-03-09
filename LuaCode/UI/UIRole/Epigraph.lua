
require("UI/UIRole/EpigraphItem")
Epigraph={Name="Epigraph"}
local My=Epigraph
local SL = SkillLvTemp;
--技能id
My.SkillId=0
--选择的铭文id
My.EpgId=0
--可以升级
My.lvUpnowRed=nil
--选中铭文
My.cur=0;
--升级保留
My.upIdex=0;
--是否有以前打铭文
My.inbefor=false
My.isChose=false;
My.skillGetWay = {
	"世界Boss",
	"洞天福地",
	"道庭Boss"
	-- "道庭商店"
}
function My:Init( root )
    self.lvl= User.instance.MapData.Level    
    local tip = self.Name
    local TF = TransTool.Find;
    local TFC = TransTool.FindChild;
	local UC = UITool.SetLsnrClick;
    local CG = ComTool.Get;
    local root = root
    self.ObjLst={}
    self.go=root.gameObject;
    self.grid=CG(UIGrid,root,"grid",tip)
    if self.ObjLst==nil then
        self.ObjLst={}
    end
    for i=1,3 do
        local path = "grid/skillbg"..i
        self.ObjLst[i]=ObjPool.Get(EpigraphItem)
        local go =TF(root,path,tip)
        self.ObjLst[i]:Init(go)
    end
    self.nowDec =CG(UILabel,root,"nowDec")
    self.nexDec =CG(UILabel,root,"nexDec")
    self.lmtDec =CG(UILabel,root,"bfsk/dec")
    self.sklName =CG(UILabel,root,"name")
    self.curLv=CG(UILabel,root,"lv")
    self.ndPoint=CG(UILabel,root,"point")
    local btnRoot = TF(root,"btn")
    self.resBtn=TFC(btnRoot,"reset")
    self.resRed=TFC(btnRoot,"reset/red")
    self.resRed:SetActive(false);
    -- self.resLab=CG(UILabel,btnRoot,"reset/Label")
    self.upBtn=TFC(btnRoot,"Uplv")
    self.upRed=TFC(btnRoot,"Uplv/red")
    self.upLab=CG(UILabel,btnRoot,"Uplv/Label")
    self.upTxt="激活铭文"
    -- self.resLab.text=self.resTxt
    UC(btnRoot, "reset", tip, self.resetClick, self);
    UC(btnRoot, "Uplv", tip, self.upClick, self);
    UC(root, "close", tip, self.SetFalseSelf, self);
	UITool.SetLsnrSelf(self.ndPoint.gameObject,self.toshowIcon,self,self.Name,false)
end

function My:toshowIcon( go  )
    if  self.costId~=nil and self.costId~=0 then
        local url=self.ndPoint:GetUrlAtPosition(UICamera.lastWorldPosition)
        if not url then return end
		SkillHelp.ShowMsg(self.ndPoint, self.costId,0.35,0.35 )
	end
end

function My:upClick( )
    -- if self.skillInfo.seal_id~=self.EpgId then
    --     UITip.Log("未激活此铭文")
    --     return
    -- end
    if My.lvUpnowRed.max then
        UITip.Log("达到最大级")
        return
    end
    if My.lvUpnowRed.seal_unlmt~=true then
        UITip.Log("等级不足")
        return
    end
    if My.lvUpnowRed.seal_exp~=true then
        UITip.Log("道具不足")
        self:AddPoint(  )
        return
    end
    My.upIdex=My.cur
    SkillMgr.SealUpSend(self.SkillId,self.EpgId);
end
function My:AddPoint(  )
    UIMgr.Open(UIGetWay.Name, self.OpenGetWayCb ,self)
end
function My:OpenGetWayCb(name)
    local ui = UIMgr.Get(name)
	ui:SetPos(Vector3(260,-81,0))
	local len = #My.skillGetWay
	for i = 1,len do
		ui:CreateCell(My.skillGetWay[i], self.OnClickGetWayItem, self)
	end
end
function My:OnClickGetWayItem(name)
    if name == "世界Boss" then
        BossHelp.OpenBoss(1)
        JumpMgr:InitJump(UIRole.Name,2)
    elseif name == "洞天福地" then
        BossHelp.OpenBoss(2)
        JumpMgr:InitJump(UIRole.Name,2)
    elseif name == "道庭Boss" then
        UIFamilyBossIt:OpenTab(true)
        JumpMgr:InitJump(UIRole.Name,2)
    -- elseif name == "道庭商店" then    
    --     UIMgr.Open(UIDemonArea.Name)
    --     JumpMgr:InitJump(UIRole.Name,2) 
	end
end
function My:SetFalseSelf( )
    My.upIdex=0    
    self.go:SetActive(false)
end

function My:ShowEff( )
   if My.cur==0 then
    return
   end
   self.ObjLst[My.cur]:ShowEff(true)
end

function My:resetClick(  )
    if self.isOpen==false then
        UITip.Log("需要先解锁技能")
        return
    end
    if My.isChose then
        return
    end
    if self.inbefor==false then
        UITip.Log("需要先激活铭文")
        return
    end
    if My.cur==0 then
        UITip.Log("请先激活铭文")
        return
    end
    SkillMgr.ChooseEPG(self.SkillId,self.EpgId);
    -- if self.resTxt=="应用铭文" then
    --   self:ReChoose()
    -- if self.resTxt=="应用铭文" and not My.isChose then
    --     SkillMgr.ChooseEPG(self.SkillId,self.EpgId);
    -- elseif self.resTxt=="激活铭文" then
    --     if self.ChooseRed[1]==false then
    --         UITip.Log("等级不足")
    --        return
    --     end
    --     if self.ChooseRed[2]==false then
    --         UITip.Log("道具不足")
    --         self:AddPoint(  )
    --        return
    --     end
    --     SkillMgr.SealUpSend(self.SkillId,self.EpgId);
    -- end
end
function My:ReChoose(  ) 
    -- local itemId = 2999
    -- local num = 1
    -- self.reitemId=itemId;
    -- local bagNum = PropMgr.TypeIdByNum(itemId);
    -- local str1 = "";
    -- local StoreDatainfo = ItemData[tostring(itemId)]
    -- local name = StoreDatainfo.name
    -- self.renum= bagNum-num
    -- if self.renum>=0 then
    --     str1=string.format("是否使用%s重置铭文",name);
    --     MsgBox.ShowYesNo(str1, self.YesCb,self, "重置", self.NoCb,self, "取消")
    -- else
    --     self.ismybuy=true
    --     StoreMgr.eBuyResp:Add(self.BuySucc,self);
    --     StoreMgr.TypeIdBuy(self.reitemId,-self.renum,true);
    -- end
    SkillMgr:ResetEPG(self.SkillId);
end
--点击MsgBox的确定按钮
-- function My:YesCb()
--     SkillMgr:ResetEPG(self.SkillId);
--     return 
-- end
-- --购买成功
-- function My:BuySucc( )
--     if self.ismybuy then
--         SkillMgr:ResetEPG(self.SkillId);
--     end
--     self.ismybuy=false
--     StoreMgr.eBuyResp:Remove(self.BuySucc,self);
-- end

--点击MsgBox的取消按钮
-- function My:NoCb()
--     return 
-- end

function My:Open( )
    self.go:SetActive(true)
    if My.cur==0 then
        return
    end
    for i=1,#self.ObjLst do
        self.ObjLst[i]:ShowEff( false )
    end
end

function My:show( skillInfo,skillid )
    My.cur=0
    self.SkillId=skillid
    local skill_id =skillid
    local slInfo =  SL[tostring(skill_id)]
    local sealLst =slInfo.sealLst
    if sealLst==nil or #sealLst<3 then
        iTrace.Error("soon","技能配置表没有配置纹印技能id"..skill_id)
        return
    end
    if skillInfo~=nil then
        self.skillInfo =skillInfo
        self.EpgId=skillInfo.seal_id
        self.isOpen=true
    end
    for i=1, 3 do    
        local id = sealLst[i]
        local base=0
        local reddec = skillInfo.seal_upred_list[i]
        if skillInfo.seal_id~=0 then
            local strid = tostring(skillInfo.seal_id)
            local info =tSkillEpg[strid]
            base=info.baseId
        end
        if id==base then
            self.ObjLst[i]:setInfo(i,skillInfo.seal_id,false,reddec)
            if My.upIdex==0 then
                self.ObjLst[i]:OnClick() 
            end
            self.ObjLst[i]:Unlock()  
        else
            local inbefor,curid = SkillMgr.findSealInLst(self.skillInfo,id)
            if inbefor then
                id = curid
            end
            self.ObjLst[i]:setInfo(i,id,inbefor,reddec)
        end
    end

    if skillInfo.seal_id==0 and My.upIdex==0 then
        self.ObjLst[1]:OnClick() 
    end
    if My.upIdex~=0 then
        self.ObjLst[My.upIdex]:OnClick() 
    end
end


function My:OnChose( index,EpgId,inbefor,reddec )
    if  My.cur~=index then
        if My.cur~=0 then
            local obj = self.ObjLst[My.cur]
            obj:other( )
        end
        My.cur=index;
        My.lvUpnowRed=reddec
        self.EpgId = EpgId
        self:SetInfo( inbefor)
    end
end

function My:SetInfo(inbefor )
    My.inbefor=inbefor
    self.costId=0;
    local p_skill = self.skillInfo
    local tSkillEpgInfo = tSkillEpg[tostring(self.EpgId)]
    self.sklName.text = tSkillEpgInfo.name
    local curLv = 0
    local MaxLv = tSkillEpgInfo.maxLvl
    local nowDec = "[F39800FF]请先应用该铭文[-]"
    local strNex = "[F39800FF]已达到最高等级[-]"
    local lvLm = "[F39800FF]已达到最高等级[-]"
    local costText = ""
    My.isChose=false;
    if inbefor==true or p_skill.seal_id==self.EpgId then
        curLv =tSkillEpgInfo.curLvl
    end
    if p_skill.seal_id==self.EpgId then
        My.isChose=true;
        nowDec="[F39800FF]本级效果:[-][F4DDBDFF]"..tSkillEpgInfo.dec
    end
    local curInfo = tSkillEpg[tostring(self.EpgId)]
    local nextId = self.EpgId+1
    if p_skill.seal_id==0  then
        nextId= self.EpgId
    end
    if inbefor==true and p_skill.seal_id==0 then
        self.resTxt="应用铭文"
    end
    if curLv<MaxLv then
        local tNextInfo = tSkillEpg[tostring(nextId)]
        strNex="[F39800FF]下级效果:[-][F4DDBDFF]"..tNextInfo.dec
        My.lvl= User.instance.MapData.Level  
        if My.lvl>=tNextInfo.lmLvl then
            lvLm=string.format( "[F4DDBDFF]玩家达到%s级[-]",tNextInfo.lmLvl )
        else
            lvLm=string.format( "[F21919FF]玩家达到%s级[-]",tNextInfo.lmLvl )
        end
        if inbefor==true and p_skill.seal_id==0 then
            lvLm=string.format( "[F4DDBDFF]玩家达到%s级[-]",curInfo.lmLvl )
        else
         local costls = tNextInfo.cost
         self.costId=costls[1].k
         local costid = self.costId
         local itemInfo = UIMisc.FindCreate(costid)
         local costName = itemInfo.name
         local hasNum =SkillMgr.SealCostEnough(tNextInfo)
         if hasNum then
            costText=string.format( "[F4DDBDFF]需要道具：[F39800FF][url=][u]%s",costName )
         else
            costText=string.format( "[F21919FF]需要道具：[F39800FF][url=][u]%s", costName)
         end
        end
    end
    
    self.curLv.text=   string.format( "(%s/%s)",curLv,MaxLv )
    self.nowDec.text=nowDec;
    self.nexDec.text=strNex;
    self.lmtDec.text= lvLm;
    self.ndPoint.text=costText
    if inbefor or p_skill.seal_id==self.EpgId then
        self.upTxt="升级铭文"
    else
        self.upTxt="激活铭文"
    end
    self.upLab.text=self.upTxt
    self.upRed:SetActive(My.lvUpnowRed.seal_up)
end

function My:Clear(  )
    self.ismybuy=false
   soonTool.ObjAddList(self.ObjLst);
   StoreMgr.eBuyResp:Remove(self.BuySucc,self);
end

return My;