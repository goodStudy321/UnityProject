--[[
 	authors 	:Liu
 	date    	:2018-12-24 16:30:00
 	descrition 	:结婚称号项
--]]

UIMarryTitleIt = Super:New{Name = "UIMarryTitleIt"}

local My = UIMarryTitleIt

function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local FindC = TransTool.FindChild

    self.tex = CG(UITexture, root, "tex")
    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab2")
    self.lab3 = CG(UILabel, root, "lab3")
    self.slider = CG(UISlider, root, "sliderBg/slider")
    self.sliderLab = CG(UILabel, root, "sliderBg/lab")
    self.lab3Go = FindC(root, "lab3", des)
    self.cfg = cfg

    self:InitTex()
    self:InitKnotLab()
    self:InitFriendlyLab()
    self:UpProgress()
end

--更新进度
function My:UpProgress()
    local mean = (self.cfg.babyId == 0) and (1/2) or (1/3)---------暂不处理仙娃
    local myLv, maxLv = self:GetKnotLv()
    local num1, num2 = self:GetFriendly()
    local prog1 = (myLv / maxLv) * mean
    local prog2 = (num1 / num2) * mean
    local progVal = prog1 + prog2
    local labVal = progVal * 100
    local val = math.floor(labVal)
    self.slider.value = progVal
    self.sliderLab.text = val.."%"
    self.progVal = val
end

--初始化好感度文本
function My:InitFriendlyLab()
    local num1, num2 = self:GetFriendly()
    local str = string.format("[FFE9BDFF]亲密度：[88F8FFFF]%s[-]/%s", num1, num2)
    self.lab2.text = str
end

--获取仙侣好感度
function My:GetFriendly()
    local id = MarryInfo.data.coupleid
    local maxFriendly = self.cfg.friendly
    for i,v in ipairs(FriendMgr.FriendList) do
        if id == tonumber(v.ID) then
            if v.Friendly > maxFriendly then
                return maxFriendly, maxFriendly
            end
            return v.Friendly, maxFriendly
        end
    end
    return 0, maxFriendly
end

--初始化同心结文本
function My:InitKnotLab()
    local myLv, maxLv = self:GetKnotLv()
    local str = string.format("[FFE9BDFF]同心锁：[88F8FFFF]%s[-]/%s级", myLv, maxLv)
    self.lab1.text = str
end
    
--获取同心结等级
function My:GetKnotLv()
    local myId = MarryInfo.data.knotid
    local maxId = self.cfg.knotId
    local info1 = KnotData[myId+1]
    local info2 = KnotData[maxId+1]
    if info1 == nil and info2 == nil then
        return 0,0
    end
    if info1 == nil then return 0, info2.lv end
    if info1.lv > info2.lv then return info2.lv, info2.lv end
    return info1.lv, info2.lv
end

--初始化贴图
function My:InitTex()
    local id = self.cfg.titleId
    local key = tostring(id)
    local info = TitleCfg[key]
    if info == nil then return end
    --self.texName1 = info.prefab1..".png"
    self.texName1 = string.sub(info.prefab1,1,-5)..".png"
    AssetMgr:Load(self.texName1, ObjHandler(self.SetIcon1, self))
end

--设置称号
function My:SetIcon1(tex)
    if self.tex then
        self.tex.mainTexture = tex
    end
end

--清理缓存
function My:Clear()
    AssetMgr:Unload(self.texName1,false)
    self.texName1 = nil
end
    
--释放资源
function My:Dispose()
    self:Clear()
end
    
return My