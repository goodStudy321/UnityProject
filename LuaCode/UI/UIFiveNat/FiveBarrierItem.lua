FiveBarrierItem = Super:New{Name="FiveBarrierItem"}
local My = FiveBarrierItem
function My:Init()
    --常用工具
    local tip = "FiveBarrierItem"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;

    UC(root,"uc_choose",tip,self.chooseClick,self)
    self.ChoseTf=TF(root,"uc_choose",tip)
    if self.isBig then
        self.bossname=CG(UILabel,root,"lab_bossname",tip)
        -- self.lock=TFC(root,"gbj_lock",tip)
        self.icon=CG(UITexture,root,"tex_icon",tip)
        UC(root,"tex_icon",tip,self.ShowSMS,self)
    end
    self.maxCan=TFC(root,"maxCan",tip)
    self.eff=TFC(root,"eff",tip)
    self.eff:SetActive(false)
    self:lnsr("Add")
end

function My:UpDateInfo( )
    if FiveCopyHelp.ChallengeId==self.copyId then
        self.isLock=false
        self.MaxChallenge=true
        self.SamlPass=false
    elseif FiveCopyHelp.ChallengeId>self.copyId then
        self.isLock=false
        self.MaxChallenge=false
        self.SamlPass=true
    else
        self.SamlPass=false
        self.isLock=true
        self.MaxChallenge=false
    end
    self.maxCan:SetActive(self.MaxChallenge)
    if self.isBig then
       self:SetBigInfo(  )
    else
        self:SetSaml()
    end
end

function My:BookCollect(  )
   if self.isBig and FiveElmtMgr.CanGoTip=="未集齐套装" and FiveElmtMgr.CanGoNxt==false then
    self.haveThis = FiveElmtMgr.IndexInBook( self.ItemId )
    self.maxCan:SetActive (not self.haveThis)
   elseif self.isBig and  FiveElmtMgr.CanGoNxt then
    self.maxCan:SetActive (false)
   end
end

function My:SetSaml( )
    if   self.SamlPass then
        UITool.SetGray(self.ChoseTf)
    else
        UITool.SetNormal(self.ChoseTf)
    end
end
 function My:ShowSMS(  )
    UIMgr.Open(SkyMysteryTip.Name,self.OpenSky,self)  
 end
function My:SetBigInfo(  )
   self.bossname.text=self.Msg.BossName
--    self.lock:SetActive(self.isLock)
   self.ItemId=self.Msg.skySeal
   self.iconText=tostring(self.ItemId)..".png"
   AssetMgr:Load(self.iconText,ObjHandler(self.LoadIcon,self))
end
function My:OpenSky(name)
	local ui = UIMgr.Get(name)
    if ui then
        local item = UIMisc.FindCreate(self.ItemId)
		ui:UpData(item)
	end
end
function My:LoadIcon(obj )
    if  not LuaTool.IsNull(self.icon) then
        self.icon.mainTexture=obj
        table.insert( FiveCopyHelp.txtUload, obj.name ) 
	else
		AssetTool.UnloadTex(obj.name)
	end
end
function My:CreatOne( copyId,parent )
    self.copyId=copyId
    self.GetGbjName = ""
    self.Msg=FvElmntCfg[tostring(copyId)]
    self.isBig=self.Msg.IsBig==1
    if self.isBig then
        self.GetGbjName="FiveBigItem"
    else
        self.GetGbjName="FiveSmalItem"
    end
    self.go=soonTool.Get(self.GetGbjName,parent )
    if self.isBig  then
        self.go.transform.localPosition=Vector3.New(-81,0,0)
    end
    self.root=self.go.transform
    self:Init()
    self:UpDateInfo( )
    self:FirstScelct()
    self:BookCollect()
end

function My:FirstScelct(  )
   if self.MaxChallenge then
     self:Select()
   end
end

function My:lnsr( fun )
    FiveCopyHelp.ShowOnClick[fun](FiveCopyHelp.ShowOnClick,self.jumpSeclt,self)
    FiveElmtMgr.eBook[fun](FiveElmtMgr.eBook,self.BookCollect,self)
end
function My:jumpSeclt( itemId )
    if itemId==self.ItemId then
        self:Select()
    end
end
function My:Select()
    FiveCopyHelp.MapCopySlct(self)
end

function My:SlctActive( bl )
    self.eff:SetActive(bl)
end

function My:chooseClick()
    self:Select()
    if self.isBig==false and self.SamlPass then
        UITip.Log("已通关")
        return
    end
    if self.isLock then
        UITip.Log("请通关前面关卡")
        return
    end
    --打开tip
    FiveCopyHelp.OpenMosntTip( )
end


function My:Dispose()
    self:lnsr("Remove")
    if self.GetGbjName~=nil then
        soonTool.Add(self.go,self.GetGbjName)
    else
        GameObject.DestroyImmediate( self.go); 
    end
    self.GetGbjName=nil
    self.ItemId=nil
end

return My

