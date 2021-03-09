--[[
道具出售界面
--]]
--require("UI/UIBackpack/PsdPanel")
--require("UI/UIBackpack/PricePanel")

-- PropSale = UIBase:New{Name="PropSale"}
-- local My = PropSale

-- local iUId = nil;

-- local curNum = 1
-- local maxNum = 1;
-- --  2--999999
-- local totalPrice = 2

-- local text = ObjPool.Get(StrBuffer)

-- My.limitNum = 0;
-- My.limitPrice = 0;

-- function My:InitCustom()
-- 	local CG=ComTool.Get
-- 	local TF = TransTool.FindChild

-- 	self.vipObj = TF(self.root, "vip");
-- 	self.vipObj:SetActive(false);

-- 	local root = self.root

-- 	self.w1 = TF(root,"w1")
-- 	self.w2 = TF(root,"w2")

-- 	UITool.SetBtnClick(self.root,"PassWord",self.Name,self.PassWord,self)
-- 	UITool.SetBtnClick(self.root,"PutAway",self.Name,self.PutAway,self)
-- 	UITool.SetLsnrClick(self.root,"Close",self.Name,self.Close,self)

-- 	self.Remain=CG(UILabel,self.root,"Remain",self.Name,false)

-- 	self.Cell=ObjPool.Get(Cell)
-- 	self.Cell:InitLoadPool(self.root, nil, nil, nil, nil, Vector3.New(-203.4, 81.1, 0));
-- 	self.NameLab=CG(UILabel,self.root,"Name",self.Name,false)

-- 	self.Price = CG(UILabel,root,"w2/Price",self.Name,false)

-- 	self.minPrice=CG(UILabel,self.root,"w1/minPrice",self.Name,false)
-- 	self.maxPrice=CG(UILabel,self.root,"w1/maxPrice",self.Name,false)
-- 	self.taxTip = CG(UILabel, self.root, "VipTip", self.Name, false)
-- 	self.vipIcon = CG(UISprite, self.root, "vip", self.Name, false);
-- 	--// 设置密码提示
-- 	self.pswTip = CG(UILabel, self.root, "PassWord/Label/Label", self.Name, false);

-- 	UITool.SetLsnrClick(self.root,"InputNum/AddBtn",self.Name,self.AddBtn,self)
-- 	UITool.SetLsnrClick(self.root,"InputNum/ReduceBtn",self.Name,self.ReduceBtn,self)

-- 	UITool.SetLsnrClick(self.root,"w1/InputPrice/AddBtn",self.Name,self.AddPrice,self)
-- 	UITool.SetLsnrClick(self.root,"w1/InputPrice/ReduceBtn",self.Name,self.ReducePrice,self)

-- 	self.InputNum=CG(UIInput,self.root,"InputNum",self.Name,false)
-- 	self.NumLab=CG(UILabel,self.root,"InputNum",self.Name,false)

-- 	self.inputPrice = CG(UIInput,root,"w1/InputPrice/price",self.Name,false)
-- 	self.inputPriceLb=CG(UILabel,root,"w1/InputPrice/price",self.Name,false)
-- 	self.InputPrice = CG(UILabel,root,"w2/InputPrice",self.Name,false)

-- 	self.time = CG(UILabel,root,"time",self.Name,false)

-- 	EventDelegate.Add(self.InputNum.onChange,EventDelegate.Callback(self.OnCNum,self))
-- 	UITool.SetLsnrSelf(self.InputPrice.gameObject,self.OnPrice,self,self.Name, false)
-- 	UITool.SetLsnrSelf(self.inputPriceLb.gameObject,self.OnLimPrice,self,self.Name, false)
-- 	--self:AddE()

-- 	self.setPsw = false;
-- end

-- --// 打开窗口
-- function My:OpenCustom()
-- 	--self:AddE();
-- 	self:ResetDataShow();
-- end

-- --// 关闭窗口
-- function My:CloseCustom()
-- 	--self:RemoveE();
-- 	MarketMgr:SetSalePsw(nil);
-- 	My.limitNum = 0;
-- 	My.limitPrice = 0;
-- end

-- --// 释放
-- function My:DisposeCustom()
-- 	self.Cell:DestroyGo();
-- 	ObjPool.Add(self.Cell);
-- 	if self.timer then
--         self.timer:Stop()
--         self.timer:AutoToPool()
--         self.timer = nil
-- 	end
-- end

-- function My:AddE()
-- 	PricePanel.eNum:Add(self.OnNum,self)
-- 	PricePanel.eClear:Add(self.OnClear,self)
-- 	PricePanel.eConfirm:Add(self.OnConfirm,self)
-- end

-- function My:RemoveE()
-- 	PricePanel.eNum:Remove(self.OnNum,self)
-- 	PricePanel.eClear:Remove(self.OnClear,self)
-- 	PricePanel.eConfirm:Remove(self.OnConfirm,self)
-- end

-- --// 重置数据并显示
-- function My:ResetDataShow()
-- 	curNum = 1;
-- 	totalPrice = 2;
-- 	self.setPsw = false;
-- 	self.pswTip.text = "v4以上使用";
-- 	self:ShowPrice();
-- 	self:ShowNum();
-- 	text:Dispose();
-- 	text:Apd(tostring(totalPrice));
-- 	self:ShowInput();

-- 	self:ShowTaxTip();
-- end

-- function My:InitLimData()
-- 	if not self.item then return end
-- 	totalPrice = self.item.priceInt[1]
-- 	self:ShowLimPrice()
-- 	self:ShowDiffPrice()
-- 	self:ShowTime()
-- end

-- --// 显示税率提示
-- function My:ShowTaxTip()
-- 	local vip = VIPMgr.GetVIPLv();
-- 	if vip > 0 then
-- 		local vipCfg = VIPLv[vip+1];
-- 		local taxP = 0;
-- 		if vipCfg ~= nil then
-- 			taxP = tonumber(vipCfg.arg22);
-- 			taxP = taxP / 100;
-- 		end
-- 		--self.taxTip.text = "您当前为[1EFF00FF]Vip"..vip.."[-]，税率为[67CC67]"..taxP.."%[-]";
-- 		self.taxTip.text = "您当前为     ，税率为[67CC67]"..taxP.."%[-]";
-- 		self.vipObj:SetActive(true);
-- 		self.vipIcon.spriteName = StrTool.Concat("vip", tostring(vip));
-- 	else
-- 		self.taxTip.text = "您不是[1EFF00FF]Vip[-]，税率为[67CC67]30%[-]";
-- 		self.vipObj:SetActive(false);
-- 	end
-- end

-- function My:OnNum(name)
-- 	if My.limitPrice ~= nil and My.limitPrice > 0 then
-- 		local curNum = tonumber(text:ToStr());
-- 		if curNum ~= nil then
-- 			if curNum * 10 + tonumber(name) > My.limitPrice then
-- 				local showText = StrTool.Concat("最大值为", tostring(My.limitPrice));
-- 				UITip.Log(showText);
-- 				return;
-- 			end
-- 		end
-- 	end

-- 	text:Apd(name)
-- 	if self.type == 1 then
-- 		self:ShowlimInput()
-- 	else
-- 		self:ShowInput()
-- 	end
-- end

-- function My:OnClear()
-- 	text:Dispose()
-- 	if self.type == 1 then
-- 		self:ShowlimInput()
-- 	else
-- 		self:ShowInput()
-- 	end
-- end

-- function My:OnConfirm()
-- 	self:RemoveE();
-- 	local cur = tonumber(text:ToStr());
-- 	if self.type == 1 then
-- 		if not self.item then return end
-- 		local min = self.item.priceInt[1]
-- 		if cur == nil or cur < min then
-- 			cur = min
-- 		end
-- 		totalPrice = cur
-- 		self:ShowLimPrice()
-- 	else
-- 		if cur == nil or cur < 2 then
-- 			cur = 2;
-- 		end
-- 		totalPrice = cur
-- 		--单价
-- 		self:ShowPrice()
-- 		self.InputPrice.text = tostring(totalPrice);
-- 	end
-- end

-- function My:UpData(item, tb)
-- 	local itemUid = 0
-- 	if type(tb) == "table" then
-- 		self.tb = tb
-- 		itemUid = tb.id
-- 	else
-- 		self:ShowWidge(false)
-- 		itemUid = tb
-- 	end
-- 	local iData = ItemData[tostring(item.id)];
-- 	self.item = item
-- 	if not self.item then return end
-- 	self:ShowPriceInt()
-- 	if iData ~= nil and iData.uFx == 1 then
-- 		maxNum = 1;
-- 	else
-- 		-- maxNum = PropMgr.TypeIdByNum(item.id)
-- 		-- if maxNum == nil then
-- 		-- 	maxNum = 1;
-- 		-- end
		
-- 		maxNum = 1;
-- 		if itemUid ~= nil then
-- 			if PropMgr.tbDic[tostring(itemUid)] ~= nil then
-- 				maxNum = PropMgr.tbDic[tostring(itemUid)].num;
-- 			end
-- 			if maxNum == nil then
-- 				maxNum = 1;
-- 			end
-- 		end
-- 	end
-- 	if self.type == 1 then
-- 		self:InitLimData()
-- 		local list = PropMgr.typeIdDic[tostring(item.id)]
-- 		local num = 0;
-- 		for i,v in ipairs(list) do
-- 			local tb = PropMgr.tbDic[tostring(v)]
-- 			local now = TimeTool.GetServerTimeNow()*0.001
-- 			local gotTime = tb.gotTime
-- 			local targetTime = item.time
-- 			local time = gotTime - now + tonumber(targetTime)
-- 			if time > 0 then
-- 				num = num + 1
-- 			end
-- 		end
-- 		maxNum = num
-- 	end

-- 	iUId = itemUid;
-- 	self.Cell:UpData(item)
-- 	if tb and type(tb) == "table" and tb.gotTime then
-- 		self.Cell:ShowLimit(tb.market_end_time)
-- 		self.Cell:UpBind(false)
-- 	end
-- 	local qua = UIMisc.LabColor(item.quality)
-- 	self.NameLab.text=qua..item.name

-- 	self:ShowRemain();
-- end

-- --// 密码设置完成
-- function My:OnPswConfirm(pswStr)
-- 	MarketMgr:SetSalePsw(pswStr);
-- 	if pswStr ~= nil and pswStr ~= "" then
-- 		self.setPsw = true;
-- 		self.pswTip.text = "已设置密码";
-- 	end
-- 	PsdPanel.eConfirm:Remove(self.OnPswConfirm, self);
-- end

-- --交易密码
-- function My:PassWord()
-- 	-- UITip.Log("此功能暂未开放");
-- 	-- return;

-- 	local vipLv = VIPMgr.GetVIPLv();
-- 	if vipLv < 4 then
-- 		UITip.Error("Vip等级不足！");
-- 		return;
-- 	end

-- 	-- if(self.psdPanel==nil)then
-- 	-- 	self.psdPanel=ObjPool.Get(PsdPanel)
-- 	-- 	self.psdPanel:Init(TransTool.FindChild(self.root,"PsdPanel"))
-- 	-- end
-- 	-- self.psdPanel:Open()

-- 	PsdPanel.eConfirm:Add(self.OnPswConfirm, self)
-- 	UIMgr.Open(PsdPanel.Name);
-- end

-- --上架
-- function My:PutAway()
-- 	--UITip.Log("功能暂未开放")

-- 	if iUId == nil then
-- 		return;
-- 	end

-- 	local itemUid = iUId;
-- 	local num = curNum;
-- 	local tPrice = totalPrice;
-- 	local tUPrice = math.ceil(totalPrice/curNum);
-- 	local psw = MarketMgr:GetSalePsw();

-- 	MarketMgr:ReqMarketOnShelf(itemUid, num, tPrice, tUPrice, psw);
-- 	self:Close();
-- end

-- function My:AddBtn()
-- 	if(curNum >= maxNum)then
-- 		curNum = maxNum;
-- 	else
-- 		if My.limitNum ~= nil and My.limitNum > 0 and curNum >= My.limitNum then
-- 			local showText = StrTool.Concat("最大数量为", tostring(My.limitNum));
-- 			UITip.Log(showText);
-- 			curNum = My.limitNum;
-- 		else
-- 			curNum=curNum + 1
-- 		end
-- 	end
	
-- 	self:ShowNum();
-- 	self:NumChange();
-- 	self:ShowPrice();
-- end

-- function My:ReduceBtn()
-- 	if(curNum <= 1)then
-- 		curNum = 1;
-- 		return;
-- 	end
-- 	curNum=curNum-1
-- 	self:ShowNum()
-- 	self:NumChange()
-- 	self:ShowPrice();
-- end

-- -- 增加价格按钮
-- function My:AddPrice()
-- 	if not self.item then return end
-- 	local maxNum = self.item.priceInt[2]
-- 	if totalPrice >= maxNum then
-- 		totalPrice = maxNum
-- 	else
-- 		totalPrice=totalPrice+1
-- 	end
-- 	self:ShowLimPrice()
-- end

-- -- 减少价格按钮
-- function My:ReducePrice()
-- 	if not self.item then return end
-- 	local minNum = self.item.priceInt[1]
-- 	if totalPrice <= minNum then
-- 		totalPrice = minNum
-- 		return
-- 	end
-- 	totalPrice = totalPrice-1
-- 	self:ShowLimPrice()
-- end

-- -- 显限时道具的价格
-- function My:ShowLimPrice()
-- 	if totalPrice > self.item.priceInt[2] then
-- 		totalPrice = self.item.priceInt[2]
-- 	end
-- 	if totalPrice < self.item.priceInt[1] then
-- 		totalPrice = self.item.priceInt[1]
-- 	end
-- 	self.inputPriceLb.text = tostring(totalPrice)
-- 	self.inputPrice.value = tostring(totalPrice)
-- end

-- -- 显示时间
-- function My:ShowTime()
-- 	if not self.tb or not self.item then return end
-- 	local gotTime = self.tb.gotTime
-- 	local now = TimeTool.GetServerTimeNow()*0.001
-- 	local time = self.item.time
-- 	local eTime = gotTime - now + time
-- 	if eTime <= 0 then return end
-- 	if not self.timer then
-- 		self.timer = ObjPool.Get(DateTimer)
-- 	end
-- 	self.timer:Stop()
-- 	self.timer.invlCb:Add(self.InvlCb, self)
--     self.timer.complete:Add(self.CompleteCb, self)
-- 	self.timer.seconds = eTime
-- 	self.timer.fmtOp = 0
--     self.timer:Start()
--     self:InvlCb()
-- end

-- function My:InvlCb()
-- 	if self.time then
-- 		self.time.text = self.timer.remain
-- 	end
-- end

-- function My:CompleteCb()
-- 	UIMgr.Close(self.Name)
-- 	UIMgr.Close(PricePanel.Name)
-- end

-- -- 显示最低最高价格
-- function My:ShowDiffPrice()
-- 	if not self.item or not self.item.priceInt then return end
-- 	self.minPrice.text = self.item.priceInt[1]
-- 	self.maxPrice.text = self.item.priceInt[2]
-- end

-- -- 显示类型  true 为限时 false为常规
-- function My:ShowWidge(value)
-- 	self.time.gameObject:SetActive(value)
-- end

-- -- 是否有价格区间
-- function My:ShowPriceInt()
-- 	if self.item.priceInt then
-- 		self.w1:SetActive(true)
-- 		self.w2:SetActive(false)
-- 		self.type = 1
-- 	else
-- 		self.w1:SetActive(false)
-- 		self.w2:SetActive(true)
-- 		self.type = 2
-- 	end
-- end

-- function My:ShowNum()
-- 	--self.NumLab.text=tostring(curNum)
-- 	self.InputNum.value = tostring(curNum);
-- end

-- function My:OnCNum()
-- 	if(StrTool.IsNullOrEmpty(self.InputNum.value))then return end
-- 	local num = tonumber(self.InputNum.value)
-- 	if(num<1)then num=1 end
-- 	if num > maxNum then
-- 		num = maxNum
-- 	end
-- 	if My.limitNum ~= nil and My.limitNum > 0 and num > My.limitNum then
-- 		local showText = StrTool.Concat("最大数量为", tostring(My.limitNum));
-- 		UITip.Log(showText);
-- 		num = My.limitNum;
-- 	end

-- 	curNum=num

-- 	self.InputNum.value=tostring(curNum)
-- 	self:NumChange()
-- end

-- function My:NumChange()
-- 	self:ShowPrice()
-- 	self:ShowRemain()
-- end

-- --输入物品总价
-- function My:OnPrice()
-- 	text:Dispose()
-- 	self:ShowInput()

-- 	-- if(self.pricePanel==nil)then 
-- 	-- 	self.pricePanel=ObjPool.Get(PricePanel)
-- 	-- 	self.pricePanel:Init(TransTool.FindChild(self.root,"PricePanel"))
-- 	-- end
-- 	-- self.pricePanel:Open()

-- 	self:AddE();
-- 	UIMgr.Open(PricePanel.Name)
-- 	local ui = UIMgr.Get(PricePanel.Name)
-- 	if ui then
-- 		ui:SetPos(Vector3.New(64.6,-323,0))
-- 	end
-- end

-- -- 输入限时物品的总价
-- function My:OnLimPrice()
-- 	text:Dispose()
-- 	self:ShowlimInput()
-- 	self:AddE();
-- 	UIMgr.Open(PricePanel.Name)
-- 	local ui = UIMgr.Get(PricePanel.Name)
-- 	if ui then
-- 		ui:SetPos(Vector3.New(64.6,-323,0))
-- 	end
-- end

-- function My:ShowPrice()
-- 	local cur = math.ceil(totalPrice/curNum)
-- 	if(cur<1)then cur=1 end

-- 	self.Price.text = tostring(cur);
-- end

-- function My:ShowRemain()
-- 	self.Remain.text="（剩余".. (maxNum - curNum).."个）"
-- end

-- function My:ShowInput()
-- 	local price = tonumber(text:ToStr());
-- 	if price == nil then
-- 		price = 2;
-- 	end

-- 	-- if price < 2 then
-- 	-- 	price = 2;
-- 	-- end

-- 	self.InputPrice.text= tostring(price);
-- end

-- function My:ShowlimInput()
-- 	if not self.item then return end 
-- 	local price = tonumber(text:ToStr())
-- 	if price == nil then
-- 		price = self.item.priceInt[1]
-- 	end
-- 	if price >self.item.priceInt[2] then
-- 		local maxPrice = self.item.priceInt[2]
-- 		UITip.Log("最高价为"..maxPrice)
-- 		price = self.item.priceInt[2]
-- 	end
-- 	self.inputPriceLb.text = tostring(price)
-- end

-- return My