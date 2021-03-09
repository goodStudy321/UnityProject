--// 小地图指引分类列表
require("UI/UIMapSystem/UIMapGLstItem");

UIMapTblList = {Name = "UIMapTblList"};


local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 创建列表
function UIMapTblList:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIMapTblList:Init(gameObj)
  
    local tip = "指引点分类列表"

    --// 按钮物体
    self.tblObj = gameObj;
    --// 面板transform
    self.rootTrans = self.tblObj.transform;

    local C = ComTool.Get;
    local CF = ComTool.GetSelf;
    local T = TransTool.FindChild;

    --// 克隆主体
	self.itemMain = T(self.rootTrans, "S/Table/Item_99");


    --// 名称
    self.nameLb = C(UILabel, self.rootTrans, "title", tip, false);
    --// 展开标志
    self.showSign = C(UISprite, self.rootTrans, "fold", tip, false);
    --// 排序控件
    self.itemTbl = C(UITable, self.rootTrans, "S/Table", tip, false);
    
    self.UIPTween = CF(UIPlayTween, self.rootTrans, tip);


    --// self按钮
    local com = CF(UIButton, self.rootTrans, tip);
    UIEvent.Get(com.gameObject).onClick = function(gameObject) self:ClickSelf(); end;


    --// 道庭成员条目列表
    self.itemList = {};
    --// 是否选择
    self.isSel = false;
    self.showSign.spriteName = "triangle_dark";
    --self.UIPTween.resetOnPlay = true;
end

--// 关闭窗口重置
function UIMapTblList:CloseWndReset()
    self.isSel = false;
    --self.UIPTween.resetOnPlay = true;
end

--// 销毁释放窗口
function UIMapTblList:Dispose()
    for i = 1, #self.itemList do
		ObjPool.Add(self.itemList[i]);
	end
	self.itemList = {};
end

--// 链接列表
function UIMapTblList:LinkAndConfig(titleName, type, infoTbl, ctnr)
    self.nameLb.text = titleName;
    self:RenewItemNum(#infoTbl);

    for i = 1, #infoTbl do
        self.itemList[i]:LinkAndConfig(infoTbl[i], type, ctnr, nil);
    end
end

--// 显示隐藏
function UIMapTblList:Show(sOh)
	self.tblObj:SetActive(sOh);
end

--// 点击自身
function UIMapTblList:ClickSelf()
    local sp;
    if self.isSel == false then
        self.isSel = true;
        sp = "triangle_light";
    else
        self.isSel = false;
        sp = "triangle_dark";
    end
    
    self.showSign.spriteName = sp
end

--// 克隆
function UIMapTblList:CloneItem()
    local Inst = GameObject.Instantiate;
    local TA = TransTool.AddChild;

    local cloneObj = Inst(self.itemMain);
    TA(self.itemMain.transform.parent, cloneObj.transform);
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIMapGLstItem);
	cloneItem:Init(cloneObj);
	cloneObj.name = string.gsub(self.itemMain.name, "99", tostring(#self.itemList + 1));
	self.itemList[#self.itemList + 1] = cloneItem;

	return cloneItem;
end

--// 重置数量
function UIMapTblList:RenewItemNum(number)
	for a = 1, #self.itemList do
		self.itemList[a]:Show(false);
	end

	local realNum = number;
	if realNum <= #self.itemList then
		for a = 1, realNum do
			self.itemList[a]:Show(true);
		end
	else
		for a = 1, #self.itemList do
			self.itemList[a]:Show(true)
		end

		local needNum = realNum - #self.itemList;
		for a = 1, needNum do
			self:CloneItem();
		end
	end

	self.itemTbl:Reposition();
end

function UIMapTblList:Reposition()
    self.itemTbl:Reposition();
end