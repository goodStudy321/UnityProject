--[[
 	authors 	:Liu
 	date    	:2018-5-15 12:27:40
 	descrition 	:签到项
--]]

UISignItem = Super:New{Name = "UISignItem"}

local My = UISignItem

local AssetMgr = Loong.Game.AssetMgr

function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.root = root
    self.lab = CG(UILabel, root, "lab")
    self.itemTran = Find(root, "cell", des)
    self.mask = FindC(root, "mask", des)
    self.mask1 = FindC(root, "spr4", des)
    self.vipLabBg = FindC(root, "spr2", des)
    self.vipLab = CG(UILabel, root, "spr2/lab1")
    self.rateLab = CG(UILabel, root, "spr2/lab2")
    self.btnMask = CG(BoxCollider, root, "btn")

    SetB(root, "btn", des, self.OnClick, self)

    self:InitLab(cfg)
    self:InitCell(cfg)
    self:InitVipLab(cfg)
end

--点击签到
function My:OnClick()
    if SignInfo.isSign then
        UITip.Log("今天已签到")
        return
    end
    SignMgr:ReqSign()
end

--初始化日期文本
function My:InitLab(cfg)
    local num = cfg.id % 30
    local day = (num==0) and 30 or num
    self.lab.text = string.format("第%s天", day)
end

--初始化Cell
function My:InitCell(cfg)
    self.cell = ObjPool.Get(UIItemCell)
    self.cell:InitLoadPool(self.itemTran, 0.8)
    self.cell:UpData(cfg.award[1], cfg.award[2])
end

--设置VIP文本
function My:InitVipLab(cfg)
    local vipLv = cfg.vipLv
    local strList = SignInfo.strList
    self.vipLabBg:SetActive(vipLv > 0)
    self.vipLab.text = "V"..vipLv
    if vipLv >= 10 then
        local tran = self.rateLab.transform
        local pos = tran.localPosition
        tran.localPosition = Vector3.New(pos.x+2.7, pos.y+2.3, 0)
    end
    if cfg.rate > 0 then
        self.rateLab.text = strList[cfg.rate].."倍"
    end
end

--可签到状态
function My:MaySign()
    self.btnMask.enabled = true
end

--已签到状态
function My:YetSign()
    self.btnMask.enabled = false
    self.mask:SetActive(true)
    self.mask1:SetActive(true)
    self.vipLabBg:SetActive(false)
end

--未签到状态
function My:NoSign()
    self.btnMask.enabled = false
end

--清理缓存
function My:Clear()

end

--释放资源
function My:Dispose()
    self:Clear()
    self.cell:DestroyGo()
    ObjPool.Add(self.cell)
    self.cell = nil
end

return My