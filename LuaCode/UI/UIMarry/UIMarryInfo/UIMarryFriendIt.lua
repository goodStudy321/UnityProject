--[[
 	authors 	:Liu
 	date    	:2018-12-6 20:00:00
 	descrition 	:亲密好友项
--]]

UIMarryFriendIt = Super:New{Name = "UIMarryFriendIt"}

local My = UIMarryFriendIt

function My:Init(root, data)
    local des = self.Name
    local CG = ComTool.Get
    local CGS = ComTool.GetSelf
    local SetS = UITool.SetBtnSelf

    -- self.bg = CGS(UISprite, root, des)
    self.spr = CG(UISprite, root, "icon")
    self.vipLab = CG(UILabel, root, "vipLab")
    self.nameLab = CG(UILabel, root, "nameLab")
    self.feelLab = CG(UILabel, root, "feelLab")
    self.data = data
    self.go = root.gameObject
    SetS(root, self.OnClick, self)
    self:InitData(data)
end

--点击自身
function My:OnClick()
    if not self.data.Online then
        UITip.Log("在线的好友才能提亲")
        return
    end
    local cfg = GlobalTemp["52"]
    if cfg then
        if self.data.Level < cfg.Value3 then
            local str = string.format("好友等级至少达到%s级才能提亲", cfg.Value3)
            UITip.Log(str)
            return
        end
    end
    MarryInfo.data.selectInfo = self.data
    local it = UIMarryInfo.pType
    it:UpOtherInfo(self.data.Name, self.data.Sex)
    it:OnPopClose()
end

--更新显示
function My:UpShow(val)
    local isShow = self:IsShow(val)
    self.go:SetActive(isShow)
end

--判断是否显示
function My:IsShow(val)
    if self:IsLvOrFriendly(val) and self.data.Online then
        return true
    end
    return false
end

--是否满足等级或好感度
function My:IsLvOrFriendly(val)
    local cfg = GlobalTemp["52"]
    if cfg then
        local coupleID = self.data.CoupleID
        if coupleID == nil then return false end
        --if self.data.Level < cfg.Value3 or self.data.Friendly < val or tonumber(coupleID) > 0 then
        if self.data.Level < cfg.Value3 or tonumber(coupleID) > 0 then
            return false
        end
    else
        return false
    end
    return true
end

--初始化数据
function My:InitData(data)
    -- self.texName = string.format( "tx_0%s.png", data.Category)
    -- AssetMgr:Load(self.texName, ObjHandler(self.SetIcon, self))

    local str = (data.Sex == 0) and "TX_01" or "TX_02"
	self.spr.spriteName = str
    self.vipLab.text = "V"..data.VIP---------------------------------------------
    self.nameLab.text = data.Name
    self.feelLab.text = data.Friendly
    -- self.feelLab.text = ""
    -- self:UpData()
end

--更新数据
-- function My:UpData()
--     if self.data.Online then
--         self.bg.spriteName = "ty_a23"
--     else
--         self.bg.spriteName = "ty_a8"
--     end
-- end

--设置贴图
-- function My:SetIcon(tex)
--     self.tex.mainTexture = tex
-- end

--清理缓存
function My:Clear()
    -- AssetMgr:Unload(self.texName,false)
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My