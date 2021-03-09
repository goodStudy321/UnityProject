EpigraphItem=Super:New{Name="EpigraphItem"}
local My = EpigraphItem
local AssetMgr=Loong.Game.AssetMgr

function My:Init( root )
    self.id =0
    local tip = self.Name
    local TF = TransTool.Find;
    local TFC = TransTool.FindChild;
    local US = UITool.SetLsnrSelf
    local CG = ComTool.Get;
    self.root = root
    self.eff=TFC(root,"eff")
    self.isLvUp=false
    self.red=TFC(root,"red")
    self.seclt=TFC(root,"select")
    self.Icon=CG(UITexture,root,"Icon")
    self.curLoadText = ""
    self:other( )
    US(root,self.OnClick,self,tip)
end

function My:setInfo( id ,epgId,inbefor,reddec )
    self.reddec=reddec
    self.isLvUp=reddec.seal_up
    self.red:SetActive(self.isLvUp)
    self.inbefor=inbefor
    self:other( )
    self.id=id
    self.epgId=epgId
    self.isDispose=false
    if tSkillEpg[tostring(self.epgId)]==nil then
        iTrace.Error("soon","没找到此铭文 请配置铭文id="..epgId)
        return;
    end
    if self.curLoadText~="" then
        AssetMgr.Instance:Unload(self.curLoadText,false)
    end
    self.icontext=tSkillEpg[tostring(self.epgId)].icon
    if  self.icontext==nil and  self.icontext=="" then
        iTrace.Error("soon","请配置铭文图片铭文id="..epgId)
        return;
    end
    UITool.SetGray(self.Icon);
    AssetMgr.Instance:Load(self.icontext,ObjHandler(self.LoadIcon,self))
end

function My:Unlock()
    UITool.SetNormal(self.Icon);
end

function My:ShowEff( b  )
    self.eff:SetActive(b)
end

function My:LoadIcon(obj )
    if not self.isDispose then
        self.Icon.mainTexture=obj
        self.curLoadText=self.icontext
	else
        AssetTool.UnloadTex(obj.name)
	end
    self.isDispose=true
end

function My:OnClick( )
    self.seclt:SetActive(true)
    Epigraph:OnChose(self.id,self.epgId,self.inbefor,self.reddec)
end

function My:other( )
    self.seclt:SetActive(false)
end

function My:Dispose(  )
    AssetMgr.Instance:Unload(self.icontext,false)
    self.curLoadText=""
    self.isDispose=true
    self.inbefor=nil
end

return My;