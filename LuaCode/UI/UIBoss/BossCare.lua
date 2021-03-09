BossCare={Name="BossCare"};
local My = BossCare;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

function My:Init(go)
    self:Clear( )
    local root = go.transform;
    self.go = go.gameObject;
    UITool.SetLsnrSelf(root,self.onCick,self,self.Name,false);
    UITool.SetLsnrClick(root,"tip",self.Name,self.showTip,self, nil, false);
    self.care=ComTool.GetSelf(UIToggle,root);
    self.bossId=0;
    self:lsnr("Add");
end

--监听boss格子被点击
function My:lsnr(func )
    BossHelp.eSltBCell[func](BossHelp.eSltBCell, self.SlctChange, self);

end

function My:SlctChange( )
    if LuaTool.IsNull(self.care)  then
        return
    end
    local cell = BossHelp.CurCell
    if cell==nil then
        return
    end
   self.bossId=tonumber(cell.MontId);
   self.care.gameObject:SetActive(cell.isOpen) 
   self.care.value=NetBoss:GetIsCare(self.bossId);
end

function My:showTip( )
    local str = "[99886BFF]成功关注时将会在Boss刷新前1分钟通知你[-]";
    UIComTips:Show(str, Vector3(-10,179,0));
end

function My:onCick()
  local value = self.care.value;
  local id = self.bossId;
  NetBoss:ResCare(id,value);
end

function My:Clear( )
    if LuaTool.IsNull(self.care) then
        return
    end
    self.care=nil
    self:lsnr("Remove");
end