FeverFindView = Super:New{Name = "FeverFindView"}
local My = FeverFindView
My.itemLst={}
My.texList={}
My.Showdic={}
function My:Init( root )
    local US = UITool.SetBtnClick
    local USS = UITool.SetLsnrSelf
   self.root=root
   local trans = root
   local TFC = TransTool.FindChild
   local CG = ComTool.Get
   self.sel = CG(UIToggle,trans,"sel",tip,false)
   self.allGrid = CG(UIGrid,trans,"allGrid")   
   self.icon1 = CG(UITexture,trans,"needNum/icon",des)
   self.icon2 = CG(UITexture,trans,"hasNum/icon",des)
   self.needNum = CG(UILabel,trans,"needNum",des)
   self.hasNum = CG(UILabel,trans,"hasNum",des)
   self.item = TFC(trans,"allGrid/item",des)   
   self.OgoldLb = CG(UILabel,trans,"Oglod",des)
   self.FgoldLb = CG(UILabel,trans,"Fglod",des)
   soonTool.setPerfab(self.item,"FeverFindItem")
   FeverCircle.notToPlay=self.sel.value
   TreaFeverMgr:SetIsOn(FeverCircle.notToPlay)
   USS(self.sel.transform,self.OnTog,self)
   self.OpenOneRed=TFC(trans,"openOBtn/red",des)
   US(trans, "openOBtn", des, self.OnOOpen, self)
   US(trans, "openFBtn", des, self.OnFOpen, self)
   self:ShowKey()
   self:Lsnr( "Add" )
end
function My:Lsnr( fun )
    PropMgr.eGetAdd[fun](PropMgr.eGetAdd, self.OnAdd, self)
end

function My:OnTog()
    FeverCircle.notToPlay=self.sel.value
    FeverCircle.Over( )
end

function My:Show( index )
    FeverCircle.Over( )
    My.CurCell=nil
    self:ShowKeyNum(index)
    self:ShowNorAward(index)
end
function My:ShowKey()
    local iconId = GlobalTemp["153"].Value2[1]
    local iconName = ItemData[tostring(iconId)].icon
    AssetMgr:Load(iconName, ObjHandler(self.LoadIconFin,self))
    self.iconName = iconName
end

function My:LoadIconFin(obj)
	if self.icon1 then
        self.icon1.mainTexture = obj
        self.icon2.mainTexture = obj
		table.insert( self.texList, obj.name )
	else
		AssetTool.UnloadTex(obj.name)
	end
end

function My:ShowKeyNum(index)
    local needKey ,haveKey,needGold,AllGold = FeverHelp.GetAllPrice(1,index)
    self.needNum.text = needKey
    self.hasNum.text = haveKey
    self.OgoldLb.text = AllGold
    if haveKey>=needKey and needKey~=0 then
        self.OpenOneRed:SetActive(true)
    else
        self.OpenOneRed:SetActive(false)
    end
    local needKey2 ,haveKey2,needGold2,AllGold2 = FeverHelp.GetAllPrice(5,index)
    self.FgoldLb.text = AllGold2
end

-- 开箱一次
function My:OnOOpen()
    if FeverCircle.isOn then
        UITip.Warning("正在抽奖，请稍等")
        return
    end
    local value = TreaFeverMgr:IsCanOpen()
    if not value then return end
    self.NeedDif =0
    local needKey ,haveKey,needGold,AllGold = FeverHelp.GetAllPrice(1,FeverHelp.curLayer)
    self.needGold=needGold
    if needKey>haveKey then
        local msg =string.format("当前神秘宝藏钥匙不足，是否使用%s元宝购买并开箱",needGold);
        MsgBox.ShowYesNo(msg,self.OpenOnce,self,"确定",self.isNo,self,"取消");
        return
    end
    self:OpenOnce(  )
end

function My:OpenOnce(  )
    allNum = 0
    index = 0
    local isMon = FeverHelp.IsHasMoney(self.needGold)
    if not isMon then return end
    TreaFeverMgr:ReqOpen(1)
end

-- 开箱五次
function My:OnFOpen()
    if FeverCircle.isOn then
        UITip.Warning("正在抽奖，请稍等")
        return
    end
    local value = TreaFeverMgr:IsCanOpen()
    if not value then return end
    local resNum = TreaFeverMgr:GetResNorAwardNum()
    if resNum < 5 then UITip.Warning("剩余数量不足5次") return end
    local needKey ,haveKey,needGold,AllGold = FeverHelp.GetAllPrice(5,FeverHelp.curLayer)
    self.needGold=needGold
    if needKey>haveKey and needKey~=0  then
        local msg =string.format("当前神秘宝藏钥匙不足，是否使用%s元宝购买并开箱",needGold);
        MsgBox.ShowYesNo(msg,self.OpenFifth,self,"确定",self.isNo,self,"取消");
        return
    end
    self:OpenFifth(  )
end

function My:OpenFifth(  )
    allNum = 0 
    index = 0
    local isMon = FeverHelp.IsHasMoney(self.needGold)
    if not isMon then return end
    TreaFeverMgr:ReqOpen(5)
end

function My:isNo(  )
    return
end
--初始化格子
function My:ShowNorAward(index)
    local datals = TreaFeverMgr:GetNorAward()
    local data = datals[index]
    if not data or #data == 0 then return end
    soonTool.ObjAddList( My.itemLst )
    local len = #data
    for i=1,len do
        local go = soonTool.Get("FeverFindItem")
        local cell = ObjPool.Get(AwardItem)
        cell:Init(go)
        cell:HideCell(false)
        cell:InitItem(data[i])
        My.itemLst[data[i].id]= cell
    end
    self.allGrid:Reposition();
end

-----奖励回发----------------------
My.CurCell=nil
My.CurIndx=1
function My:DoAnim(rwdls )
    self.curAward=rwdls
    local timce = #rwdls
    if timce==0 then
        return
    end
    FeverCircle.DoAnim(timce,rwdls)
end

function My:OnAdd(action,dic)
    if action == 10406 or action == 10408   then
        for i,v in ipairs(dic) do
            local KV = ObjPool.Get(KV)
            KV:Init(v.k,v.v)
            table.insert( My.Showdic, KV )
        end
    end
end

--结束
function My:ShowAll()
    local datals = TreaFeverMgr:GetNorAward()
    local data = datals[FeverHelp.curLayer]
    local num = #self.curAward
    for i=1,num do
        local id = self.curAward[i]
        local msg=data[id]
        My.CurIndx=msg.id
        local obj = My.itemLst[My.CurIndx]
        obj:ChgState(msg)
    end
    if My.CurCell~=nil then
        My.CurCell:Sel(false)
    end
    My.CurCell = My.itemLst[My.CurIndx]
    My.CurCell:OnPlay()
    if #self.Showdic<1 then
        My.CurCell:Sel(false)
      return
    end
    UIMgr.Open(UIGetRewardPanel.Name, self.OpenGetRewardCb, self)
end

function My:OpenGetRewardCb(name)
    local ui = UIMgr.Get(name)
    if ui then
        ui:UpdateData(self.Showdic)
        TableTool.ClearDic(self.Showdic)
	end
end

function My:onceOpen( )
    local datals = TreaFeverMgr:GetNorAward()
    local data = datals[FeverHelp.curLayer]
    local msg=data[My.CurIndx]
    My.CurCell:ChgState(msg)
    FeverCircle.StartCell[FeverHelp.curLayer]=My.CurIndx
end

function My:selctCb()
    if My.CurCell==nil then
        My.CurIndx=1
    else
        My.CurIndx=My.CurIndx+1
        My.CurCell:Sel(false)
        if My.CurIndx > 25 then
            My.CurIndx = 1
        end
    end
    My.CurCell = My.itemLst[My.CurIndx]
    My.CurCell:OnPlay()
end

function My:Clear( )
    self:Lsnr( "Remove" )
    AssetTool.UnloadTex(self.texList)
    soonTool.ObjAddList( My.itemLst )
    soonTool.ObjAddList(My.Showdic)
    FeverCircle.Clear( )
    My.CurCell=nil
end

return My;