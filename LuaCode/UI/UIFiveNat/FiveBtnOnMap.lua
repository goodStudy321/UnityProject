FiveBtnOnMap = Super:New{Name="FiveBtnOnMap"}
local My = FiveBtnOnMap
function My:Init(root)
    self.root=root
    --常用工具
    local tip = "FiveBtnOnMap"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;
    self.BackBefore=TFC(root,"uc_BackBefore",tip)
    UC(root,"uc_BackBefore",tip,self.BackBeforeClick,self)
    self.illNum=CG(UILabel,root,"lab_illNum",tip)
    UC(root,"lab_illNum/uc_toShowIll",tip,self.toShowIllClick,self)
    UC(root,"lab_illNum/uc_toShowIllsame",tip,self.toShowIllClick,self)
    UC(root,"uc_goSMS",tip,self.ToSMSClick,self)
    UC(root,"uc_FiveRank",tip,self.FiveRankClick,self)
    -- self.NatNum=CG(UILabel,root,"lab_NatNum",tip)
    -- UC(root,"lab_NatNum/uc_toShowNat",tip,self.toShowNatClick,self)
    self.fiveNum=CG(UILabel,root,"lab_fiveNum",tip)
    UC(root,"lab_fiveNum/uc_toShowFive",tip,self.toShowFiveClick,self)
    self.IllIcon=CG(UITexture,root,"lab_illNum/IllIcon",tip)
    -- self.natIcon=CG(UITexture,root,"lab_NatNum/natIcon",tip)
    AssetMgr:Load(FiveCopyHelp.illIconTxt,ObjHandler(self.LoadIllIcon,self));
    -- AssetMgr:Load(FiveCopyHelp.naxIconTxt,ObjHandler(self.LoadnatIcon,self));
end
--加载icon完成
function My:LoadIllIcon(obj)
	if self.IllIcon == nil then
        AssetTool.UnloadTex(obj.name)
        return;
    end
    self.IllIcon.mainTexture=obj;    
end
-- function My:LoadnatIcon(obj)
-- 	if self.natIcon == nil then
--         AssetTool.UnloadTex(obj.name)
--         return;
--     end
--     self.natIcon.mainTexture=obj;    
-- end

function My:UpDateIll(  )
    self.illNum.text=string.format("%s/%s",FiveElmtMgr.illusion,FiveCopyHelp.illMax)
end

-- function My:UpdateNat( )
--     self.NatNum.text=string.format("%s/%s",FiveElmtMgr.nat_intensify,FiveCopyHelp.natMax)
-- end

function My:UpfiveNum( )
    local num = FiveCopyHelp.GetAllRoleElmtNum()
    self.fiveNum.text=tostring(num)
end

function My:UnLockfloor(  )
    self:UpDateIll()
    -- self:UpdateNat()
    self:UpfiveNum()
end

function My:UpdateFloor(  )
    self.notFistFloor=FiveCopyHelp.CurFloor>1
    -- self.BackBefore:SetActive(FiveCopyHelp.CurFloor>1)
end

function My:BackBeforeClick(go)
    if  self.notFistFloor then
        FiveCopyHelp.changeFloor(-1)
    else
        UITip.Log("当前为第一层")
    end
end

function My:toShowIllClick(go)
    FiveCopyHelp.OpenTip( FiveBuytip )
end

-- function My:toShowNatClick(go)
--     FiveCopyHelp.OpenGetShow(  )
-- end

function My:toShowFiveClick(go)
    FiveCopyHelp.OpenTip( FivePropertyTip )
end

function My:ToSMSClick(go)
    FiveCopyHelp.toUISMS()
end

function My:FiveRankClick(  )
   FiveCopyHelp.OpenTip(FiveRank)
end


function My:Clear()
    AssetMgr:Unload(FiveCopyHelp.illIconTxt,false);  
    -- AssetMgr:Unload(FiveCopyHelp.naxIconTxt,false);  
end

return My
