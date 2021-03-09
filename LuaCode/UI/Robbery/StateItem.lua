StateItem = Super:New {Name = "StateItem"}

local My = StateItem

function My:Init(go)
	local des = self.Name
	local root = go.transform
	
	local CG = ComTool.Get
	local TF = TransTool.Find
	local TFC = TransTool.FindChild
	
	self.root = root
	self.rootSp = root:GetComponent(typeof(UISprite))
	
	self.stateObj = TFC(root,"haveS",des)
	self.stateCurObj = TF(root,"curS",des)
	self.selectObj = TF(root,"select",des)
	self.slideLab = CG(UILabel,root,"slidLab",des)
	self.stateLab = CG(UILabel, root, "haveS/lab", des)
	self.stateCurLab = CG(UILabel, root, "curS/lab", des)
	self.slidBg = CG(UISprite,root,"slideBg",des)
	self.slider = CG(UISprite,root,"slideBg/slide",des)
	self.curEffect = TFC(root,"curS/Eff",des)
	-- self.stateCurObj:SetActive(false)
end

function My:InitDate(data)
	self:SetLab(data.nameOnly)
end

function My:SetSlider(rate)
	self.slider.fillAmount = rate
end

function My:SetLab(name)
	self.stateLab.text = name
	self.stateCurLab.text = name
end

--设置境界进度文字显示
function My:SetSlideLab(cur,max)
	local str = string.format( "%s/%s",cur,max)
	self.slideLab.text = str
end

function My:SetCurState(atc)
	self.stateCurObj.gameObject:SetActive(atc)
end

function My:SetHaveState(ac)
	self.stateObj:SetActive(ac)
end

function My:SetSelectState(ac)
	self.selectObj.gameObject:SetActive(ac)
end

function My:SetCurEffect(ac)
	self.curEffect:SetActive(ac)
end

function My:Dispose()
	TableTool.ClearUserData(self)
end
