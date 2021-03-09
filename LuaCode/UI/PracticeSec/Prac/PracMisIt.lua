PracMisIt = Super:New{Name = "PracMisIt"}
local My = PracMisIt

function My:Init(obj)
    self.Gbj = obj.gameObject
    local trans = obj.transform
    local name = trans.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
	local US = UITool.SetLsnrSelf

	self.iconTex = CG(UITexture,trans,"tex",name)
	self.desLab = CG(UILabel,trans,"des",name)
	self.slidLab = CG(UILabel,trans,"slidLab",name)
	self.rewLab = CG(UILabel,trans,"tiLab",name)
	self.btn = TFC(trans,"btn",name)
	self.btnLab = CG(UILabel,trans,"btn/lab",name)
	self.red = TFC(trans,"btn/red",name)
	self.flag = TFC(trans,"flag",name)
	
	US(self.btn,self.ClickBtn,self,name,false)

	self.missionId = 0
	self.missionState = 0
end

function My:LoadTex()
	local cfg = ItemData["27"]
	AssetMgr:Load(cfg.icon, ObjHandler(self.SetIcon, self))
end

--设置图标
function My:SetIcon(tex)
	if self.texName == nil then
		self.iconTex.mainTexture = tex
		self.texName = tex.name
	end
end

--清理texture
function My:ClearIcon()
	if self.texName then
	  AssetMgr:Unload(self.texName,".png",false)
	  self.texName = nil
	end
end

function My:ClickBtn()
	local misId = self.missionId
	local misState = self.missionState
	local cfg = PracticeMisCfg[misId]
	if misState == 1 then
		local getWay = cfg.jump
		UITabMgr.Open(getWay)
	elseif misState == 2 then
		PracSecMgr:ReqPracMisReward(misId)
	end
end

function My:SetActive(ac)
    self.Gbj:SetActive(ac)
end

function My:UpdateData(data)
	self:LoadTex()
	local misId = data.mission_id
	local misTabInfo = PracSecMgr.pracInfoTab.misStateTab[misId]
	local cfg = PracticeMisCfg[misId]
	local slidStr = string.format("%s/%s",misTabInfo.misCompTimes,cfg.condArg)
	local pacNum = cfg.pracNum
	pacNum = string.format("x%s",pacNum)
	self.desLab.text = cfg.des
	self.slidLab.text = slidStr
	self.rewLab.text = pacNum
	local nameNum = misId + 1500
	local misState = PracSecMgr:PrasMisState(misId)  --任务状态 1：前往  2：领取   3：已完成
	local tab = {"前往","领取 ","完成"}
	self.btnLab.text = tab[misState]
	self.red:SetActive(misState == 2)
	self.flag:SetActive(misState == 3)
	self.btn:SetActive(misState ~= 3)
	if misState == 3 then
		nameNum = misId + 2500
	elseif misState == 2 then
		nameNum = misId + 1000
	end
	self.Gbj.name = nameNum
	self.missionId = misId
	self.missionState = misState
end

function My:Dispose()
	self.missionId = 0
	self.missionState = 0
	TableTool.ClearUserData(self)
	self:ClearIcon()
end