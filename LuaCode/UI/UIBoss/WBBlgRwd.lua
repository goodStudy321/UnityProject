WBBlgRwd = {Name = "WBBlgRwd"}
local My = WBBlgRwd;

function My:Init(trans)
    local name = trans.name;
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;
    self.root = trans;
    self:SetActive(false);
    self.ItemRoot = TF(trans,"ItemRoot",name);
    UC(trans,"bg/yesBtn",name,self.Close,self);
end

--打开面板
function My:Open()
    self:SetActive(true);
    self:SetRwd();
end

--关闭面板
function My:Close()
    self:SetActive(false);
    self:Clear();
end

--设置奖励
function My:SetRwd()
    local rwdId = "35228";
    local cfg = ItemData[rwdId];
    if cfg == nil then
        return;
    end
    self.rwdItem = ObjPool.Get(UIItemCell);
    self.rwdItem:InitLoadPool(self.ItemRoot);
    self.rwdItem:UpData(rwdId);
end

--清理
function My:Clear()
    if self.rwdItem then
        self.rwdItem:DestroyGo()
        ObjPool.Add(self.rwdItem)
        self.rwdItem = nil
    end
end

--设置对象状态
function My:SetActive(active)
    local trans = self.root;
    local isNull = LuaTool.IsNull(trans);
    if isNull == true then
        return;
    end
    trans.gameObject:SetActive(active);
end
