--[[ 设置密码窗口 --]]

PsdPanel = UIBase:New{Name="PsdPanel"};
local My = PsdPanel;

My.winCtrl = {};

My.eClear = Event();
My.eNum = Event();
My.eConfirm = Event();
--local text = ObjPool.Get(StrBuffer);


function My:InitCustom()
	My.winCtrl.trans = self.root;

	local TF = TransTool.FindChild;
	local CG = ComTool.Get;
	
	UITool.SetBtnClick(My.winCtrl.trans, "Close", self.Name, self.Close, self);
	local grid = TF(My.winCtrl.trans, "Grid").transform;
	for i = 0, 9 do
		local btn = TF(grid, tostring(i));
		UITool.SetLsnrSelf(btn, self.ClickNum, self, self.Name);
	end

	UITool.SetBtnClick(grid, "C", self.Name, self.ClickC, self);
	UITool.SetBtnClick(grid, "OK", self.Name, self.ClickOK, self);

	My.winCtrl.Psd = CG(UILabel, My.winCtrl.trans, "Psd", self.Name, false)

	My.winCtrl.text = ObjPool.Get(StrBuffer);
end

function My:ClickNum(go)
	-- if My.winCtrl.text.Length == 0 and go.name = ="0" then
	-- 	return;
	-- end
	if My.winCtrl.text.Length == 6 then
		UITip.Log("密码为6位！");
		return;
	end

	My.winCtrl.text:Apd(go.name);
	self:ShowPsd();
end

function My:ClickC()
	My.winCtrl.text:Dispose();
	self:ShowPsd();
end

function My:ClickOK()
	if(My.winCtrl.text.Length<6)then
		UITip.Log("请输入正确的六位数密码")
		return
	end

	--// 确认回调
	My.eConfirm(My.winCtrl.text:ToStr());

	My.winCtrl.text:Dispose();
	self:Close();
end

--// 
function My:ShowPsd()
	My.winCtrl.Psd.text = My.winCtrl.text:ToStr();
end

--// 
function My:OpenCustom()
	
end

--// 
function My:CloseCustom()
	
end

--// 
function My:DisposeCustom()
	if My.winCtrl.text ~= nil then
		ObjPool.Add(My.winCtrl.text);
	end
end

return My;