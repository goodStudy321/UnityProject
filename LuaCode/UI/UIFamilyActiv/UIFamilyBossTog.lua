--[[
 	authors 	:Liu
 	date    	:2019-6-11 20:10:00
 	descrition 	:道庭Boss项
--]]

UIFamilyBossTog = Super:New{Name="UIFamilyBossTog"}

local My = UIFamilyBossTog

function My:Init(root, begTime, lastTime, mCfg, type)
    local des = self.Name
    local CG = ComTool.Get
    local CGS = ComTool.GetSelf
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.texName = nil
    self.type = type
    self.mCfg = mCfg
    if self.mCfg == nil then return end

    self.tog = CGS(UIToggle, root, des)
    self.spr1 = CGS(UISprite, root, des)
    self.spr2 = CG(UISprite, root, "bgs/spr1")
    self.tex = CG(UITexture, root, "tex")
    self.nameLab1 = CG(UILabel, root, "nameLab1")
    self.nameLab2 = CG(UILabel, root, "nameLab2")
    self.timeLab = CG(UILabel, root, "timeLab")
    self.countLab = CG(UILabel, root, "countLab")
    self.slider = CG(UISlider, root, "progress")
    self.action = FindC(root, "Action", des)
    self.killSpr = FindC(root, "killSpr", des)

    SetB(root, "rankBtn", des, self.OnRank, self)

    self:InitTex()
    self:InitBossName()
    self:InitHpSlider(type)
    self:InitCountLab(type)
    self:InitTimeLab(begTime, lastTime)
end

--初始化Hp
function My:InitHpSlider(type)
    local data = FamilyBossInfo.data
    local value = (type==1) and data.hpValue1 or data.hpValue2
    self.slider.value = value/100
    self.killSpr:SetActive(value<=0)
end

--初始化时间
function My:InitTimeLab(begTime, lastTime)
    local list = { begTime }
    local str = CustomInfo:GetTimeLab(list, lastTime)
    self.timeLab.text = string.format("挑战时间：%s", str)
end

--初始化参与人数
function My:InitCountLab(type)
    local data = FamilyBossInfo.data
    local count = (type==1) and data.joinCount1 or data.joinCount2
    self.countLab.text = string.format("道庭参与人数：%s人", count)
end

--初始化Boss名字
function My:InitBossName()
    self.nameLab1.text = self.mCfg.name
    self.nameLab2.text = self.mCfg.name
end

--初始化贴图
function My:InitTex()
    self.texName = self.mCfg.icon
    AssetMgr:Load(self.texName, ObjHandler(self.SetIcon, self))
end

--设置贴图
function My:SetIcon(tex)
    self.tex.mainTexture = tex
end

--点击排行榜
function My:OnRank()
    FamilyBossMgr:ReqRankInfo(self.type)
end

--更新自身状态
function My:UpState(state)
    self.tog.value = state
    self.nameLab1.gameObject:SetActive(not state)
    self.nameLab2.gameObject:SetActive(state)
    local str = (state==true) and "xm_a02" or "xm_a06"
    self.spr1.spriteName = str
    self.spr2.spriteName = str
end

--更新红点
function My:UpAction()
    local data = FamilyBossInfo.data
    local value = (self.type==1) and data.hpValue1 or data.hpValue2
    if value < 1 then return end
	self.action:SetActive(true)
end

--卸载贴图
function My:UnloadTex()
    if self.texName then
        AssetMgr:Unload(self.texName, false)
        self.texName = nil
    end
end

--清理缓存
function My:Clear()
    self.mCfg = nil
end

--释放资源
function My:Dispose()
    self:Clear()
    self:UnloadTex()
end

return My