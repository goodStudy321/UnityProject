--// 小地图指引点列表条目
UIMapGLstItem = {Name = "UIMapGLstItem"};
local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 创建条目
function UIMapGLstItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIMapGLstItem:Init(gameObj)
  
    local tip = "指引点条目"

    --// 按钮物体
    self.itemObj = gameObj;
    --// 面板transform
    self.rootTrans = self.itemObj.transform;
    --// 
    self.type = 0;
    --// 
    self.info = nil;
    --// 
    self.ctnr = nil;
    --// 点击事件
    self.clickEvnt = nil;
  
    local C = ComTool.Get;
    local CF = ComTool.GetSelf;
    local T = TransTool.FindChild;

    --// 背景间隔图标
    self.bgSign = T(self.rootTrans, "Bg1");
    self.selSign = T(self.rootTrans, "SelSign");
  
    --// 名称
    self.nameLb = C(UILabel, self.rootTrans, "Name", tip, false);
    --// 信息
    self.infoLb = C(UILabel, self.rootTrans, "Info", tip, false);
  
    --// self按钮
    local com = CF(UIButton, self.rootTrans, tip);
    UIEvent.Get(com.gameObject).onClick = function(gameObject) self:ClickSelf(); end;

    --// 小飞鞋按钮
	com = C(UIButton, self.rootTrans, "ShoesBtn", tip, false)
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
	 	self:ClickShoesBtn();
	end;
  
    --// 当前是否选择
    self.isSel = false;
end

--// 链接条目
function UIMapGLstItem:LinkAndConfig(infoTbl, type, ctnr, clickEvnt)
    self.info = infoTbl;
    self.type = type;
    self.ctnr = ctnr;
    self.nameLb.text = infoTbl.name;
    self.infoLb.text = infoTbl.info;
    self.clickEvnt = clickEvnt;
end

--// 显示隐藏
function UIMapGLstItem:Show(sOh)
	self.itemObj:SetActive(sOh);
end

function UIMapGLstItem:ShowBg(show)
    self.bgSign:SetActive(show);
end

--// 设置选择标志
function UIMapGLstItem:SetSel(isSel)
    self.isSel = isSel;

    --local color;
    if self.isSel == true then
        --color = Color.SetVar(1, 0.91, 0.74);
        self.selSign:SetActive(true);
    else
        --color = Color.SetVar(0.69, 0.64, 0.58);
        self.selSign:SetActive(false);
    end
    --self.nameLb.color = color;
end

--// 点击自身
function UIMapGLstItem:ClickSelf()
    if self.ctnr ~= nil then
        self.ctnr:SelectMapPoint(self.type, self.info, self);
        
        if self.type == 2 then
            UIHangTip.CreatTip(self:GetSelfUIPos(), self.info.evilAreaId);
        end
    end

    if self.clickEvnt ~= nil then
        self.clickEvnt();
    end
end

--// 点击小飞鞋按钮
function UIMapGLstItem:ClickShoesBtn()
    if self.info == nil then
        return;
    end

    MapMgr:UseLittleFlyShoes(0, self.info.pos, 1, nil);
end

--// 获取控件自身UI位置
function UIMapGLstItem:GetSelfUIPos()
    return MapHelper.instance:ChangePosToUIPos(self.rootTrans.position);
end