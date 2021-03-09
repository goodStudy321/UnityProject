FiveNatShow = Super:New{Name="FiveNatShow"}
local My = FiveNatShow
function My:Init(root)
    self.root=root
    self.go=root.gameObject
    --常用工具
    local tip = "FiveNatShow"
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;
    self.natIcon=CG(UITexture,root,"tex_nat",tip)
    self.natSpeed=CG(UILabel,root,"tex_nat/lab_natSpeed",tip)
	self.StepCur = CG(UILabel, root, "curexp", tip, false)
    self.StepLimit = CG(UILabel, root, "limitexp", tip, false)
    	--新的StepExpSlider
    self.StepExpSlider = CG(UISprite,root,"rBg",tip,false)

    self.red=TFC(root,"tex_nat/red",tip)
    self.GetEff=TFC(root,"rBg/effGet",tip)
    self.GetEff:SetActive(false)
    UC(root,"lBg",tip,self.GetSureClick,self)
    UC(root,"tex_nat",tip,self.onClickNat,self)
    self.proSpFx = CG(guiraffe.SubstanceOrb.OrbAnimator, root, "rBg/effnow", tip)
    AssetMgr:Load(FiveCopyHelp.naxIconTxt,ObjHandler(self.LoadnatIcon,self));    
end

function My:onClickNat( )
    local ui = UIMgr.Get(PropTip.Name)
    UIMgr.Open(PropTip.Name,self.OpenCb,self)
end
function My:OpenCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then 
		ui:UpData(700006)
	end
end

function My:GetSureClick(go)
    if FiveElmtMgr.nat_intensify==0 then
       UITip.Log("暂无奖励可领取")
        return 
    end
    FiveCopyHelp.GetNatSend()
end

function My:LoadnatIcon(obj)
	if self.natIcon == nil then
        AssetTool.UnloadTex(obj.name)
        return;
    end
    self.natIcon.mainTexture=obj;    
end
function My:UpdateInfo( )
    self:SetSlider(FiveElmtMgr.nat_intensify, FiveCopyHelp.natMax)
    self:SpeedLab()
    self:setRed(FiveElmtMgr.nat_intensify, FiveCopyHelp.natMax)
end

function My:setRed(cur, limit  )
    self.red:SetActive(cur==limit )
end

function My:ShowGetEff()
    self.GetEff:SetActive(false)
    self.GetEff:SetActive(true)
end

function My:SpeedLab( )
    self.natSpeed.text=string.format( "勾玉凝聚：[00FF00FF]%s[-]个/分钟",FiveCopyHelp.natSpeed)
end

function My:SetSlider(cur, limit)
	if not cur then cur = 0 end
	if not limit then limit = 0 end
	if cur == 0 and limit == 0 then
		if self.StepCur then self.StepCur.text = "0" end
		if self.StepLimit then self.StepLimit.text = "0" end
		if self.StepExpSlider then self.StepExpSlider.fillAmountValue = 0 end
		if self.proSpFx then self.proSpFx.FillRate = 0 end
		return
	end
	if self.StepCur then self.StepCur.text = tostring(cur).."\n——" end
	if self.StepLimit then self.StepLimit.text = tostring(limit) end
	if self.StepExpSlider then self.StepExpSlider.fillAmountValue = cur / limit end
	if self.proSpFx then self.proSpFx.FillRate = cur / limit end
end


function My:Clear()
    AssetMgr:Unload(FiveCopyHelp.naxIconTxt,false);      
end

return My
