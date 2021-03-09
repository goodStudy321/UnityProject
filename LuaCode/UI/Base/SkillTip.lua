--[[
技能tip
]]
require("UI/Base/PropTipBase")
SkillTip=PropTipBase:New{Name="SkillTip"}
local My = SkillTip

function My:InitData(trans,pos)
    self.root=trans

    self.C=TransTool.FindChild(self.root,"C")
    local c = self.C.transform
    UITool.SetLsnrClick(c,"Bg/mask",self.Name,self.OnClose,self)
    self.IsActive=TransTool.FindChild(c,"Bg/IsActive")
    self:InitCustom(self.C,pos)
end

function My:UpData(skillList,isActive)
    local id = skillList.value
    local data = SkillLvTemp[tostring(id)]
    if not data then iTrace.eError("xiaoyu","技能等级配置表为空 id: "..id)return end
    local icon = data.icon
    AssetMgr:Load(icon,ObjHandler(self.cell.LoadIcon,self.cell))

    self.NameLab.text=data.name
    self.Des.text=data.desc
    self.Tp.text=""
    self.Lv.text="Lv."..data.level
    self.IsActive:SetActive(isActive==true)

    self:UpBgHeight()
	self:OpenUpData()
end

function My:Open()
    -- local ui = UIMgr.Get(UIEquipCollection.Name)
    -- local depth = ui.root:GetComponent(typeof(UIPanel)).depth
    -- local panel = self.root:GetComponent(typeof(UIPanel))
    -- panel.depth=depth+1
    -- local desPanel = ComTool.Get(UIPanel,self.root,"Bg/Panel",self.Name,false)
    -- desPanel.depth=depth+2
    self.root.gameObject:SetActive(true)
end


function My:OnClose( ... )
    self.root.gameObject:SetActive(false)
end