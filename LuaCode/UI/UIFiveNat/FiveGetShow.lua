FiveGetShow = Super:New{Name="FiveGetShow"}
local My = FiveGetShow
function My:Init(root)
    self.root=root
    self.go=root.gameObject
    --常用工具
    local tip = "FiveGetShow"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;

    UC(root,"uc_Close",tip,self.CloseClick,self)
    self.titleName=CG(UILabel,root,"lab_titleName",tip)
    UC(root,"uc_buySure",tip,self.buySureClick,self)
    UC(root,"uc_GetSure",tip,self.GetSureClick,self)
    UC(root,"uc_toSNS",tip,self.toSNSClick,self)
    self.IllSpeed=CG(UILabel,root,"lab_IllSpeed",tip)
    self.NatSpeed=CG(UILabel,root,"lab_NatSpeed",tip)
    self.IllShow=CG(UILabel,root,"lab_IllShow",tip)
    self.NatShow=CG(UILabel,root,"lab_NatShow",tip)
    self.IllIcon=CG(UITexture,root,"tf_illTF",tip)
    self.natIcon=CG(UITexture,root,"tf_NatTF",tip)
    AssetMgr:Load(FiveCopyHelp.illIconTxt,ObjHandler(self.LoadIllIcon,self));
    AssetMgr:Load(FiveCopyHelp.naxIconTxt,ObjHandler(self.LoadnatIcon,self));
end
--加载icon完成
function My:LoadIllIcon(obj)
	if self.IllIcon == nil then
        AssetTool.UnloadTex(obj.name)
        return;
    end
    self.IllIcon.mainTexture=obj;    
end
function My:LoadnatIcon(obj)
	if self.natIcon == nil then
        AssetTool.UnloadTex(obj.name)
        return;
    end
    self.natIcon.mainTexture=obj;    
end

function My:Open( )
    local Msg = FiveElmtMgr.floorMsg[FiveCopyHelp.CurFloor]
    self.titleName.text =Msg.CopyName
    self.go:SetActive(true)
end
function My:UnLockfloor(  )
    self:UpDateIll()
    self:UpdateNat()
    self:UpIllSpeed()
    self:UpNatSpeed()
end

function My:UpIllSpeed(  )
    self.IllSpeed.text=string.format("获取速度:%s/分钟",FiveCopyHelp.illSpeed)
end
function My:UpNatSpeed(  )
    self.NatSpeed.text=string.format("获取速度:%s/分钟",FiveCopyHelp.natSpeed)
end
function My:UpDateIll(  )
    self.IllShow.text=string.format("%s/%s",FiveElmtMgr.illusion,FiveCopyHelp.illMax)
end

function My:UpdateNat( )
    self.NatShow.text=string.format("%s/%s",FiveElmtMgr.nat_intensify,FiveCopyHelp.natMax)
end

function My:CloseClick(go)
    self.go:SetActive(false)
end

function My:buySureClick(go)
    FiveCopyHelp.OpenTip(FiveBuytip)
end

function My:GetSureClick(go)
     if FiveElmtMgr.nat_intensify==0 then
        UITip.Log("暂无奖励可领取")
         return 
     end
     FiveCopyHelp.GetNatSend()
end

function My:toSNSClick(go)
    FiveCopyHelp.toUISMS()
end

function My:Clear()
    AssetMgr:Unload(FiveCopyHelp.illIconTxt,false);  
    AssetMgr:Unload(FiveCopyHelp.naxIconTxt,false);  
end

return My
