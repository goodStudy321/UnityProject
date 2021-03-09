--[[
 	authors 	:Liu
 	date    	:2018-12-10 16:00:00
 	descrition 	:结婚商城界面
--]]

UIMarryStoreMenu = Super:New{Name = "UIMarryStoreMenu"}

local My = UIMarryStoreMenu

local strs = "UI/UIMarry/UIMarryInfo/"
require(strs.."UIMarryStoreIt")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild
    local str = "goodsBg/Scroll View/Grid"
    
    local item = FindC(root, str.."/item", des)
    self.goldLab = CG(UILabel, root, "desBg/coinBg1/coinLab")
    self.bindGoldLab = CG(UILabel, root, "desBg/coinBg2/coinLab")
    self.titleLab = CG(UILabel, root, "titleBg/lab")
    self.desLab = CG(UILabel, root, "desBg/lab")

    self.num = 1
    self.itList = {}
    self.isBack = true
    self.go = root.gameObject

    SetB(root, "close", des, self.OnClose, self)

    self:InitShopItem(item)
    self:UpGoldLab()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    RoleAssets.eUpAsset[func](RoleAssets.eUpAsset, self.UpGoldLab, self)
    MarryMgr.ePopClick[func](MarryMgr.ePopClick, self.RespPopClick, self)
end

--响应弹窗点击
function My:RespPopClick(isAllShow)
    if not isAllShow and self.go.activeSelf then
        VIPMgr.OpenVIP(1)
    end
end

--初始化商城项
function My:InitShopItem(item)
    local Add = TransTool.AddChild
    local parent = item.transform.parent
    local list = {}
    for k,v in pairs(StoreData) do
        if v.storeTp == 9 then
            table.insert(list, v)
        end
    end
    table.sort(list, function(a,b) return a.id < b.id end)
    for i,v in ipairs(list) do
        if v.storeTp == 9 then
            local go = Instantiate(item)
            local tran = go.transform
            go.name = 100000 + v.curPrice
            Add(parent, tran)
            local it = ObjPool.Get(UIMarryStoreIt)
            it:Init(tran, v)
            table.insert(self.itList, it)
            if i == 1 then
                self:UpDesLab(it.cfg)
            end
        end
    end
    item:SetActive(false)
end

--更新货币文本
function My:UpGoldLab(ty)
    local info = RoleAssets
    self.goldLab.text = info.Gold
    self.bindGoldLab.text = info.BindGold
end

--更新描述文本
function My:UpDesLab(cfg)
    local key = cfg.PropId
    local itCfg = ItemData[key]
    if itCfg == nil then return end
    self.titleLab.text = cfg.name
    self.desLab.text = itCfg.des
end

--点击关闭
function My:OnClose()
    if not self.isBack then
        UIMarryInfo:Close()
    else
        UIMarryInfo:SetMenuState(4)
    end
end

--设置返回状态
function My:SetIsBack()
    self.isBack = false
end

--清理缓存
function My:Clear()
    self.num = 0
    self.isBack = true
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
    ListTool.ClearToPool(self.itList)
end
    
return My