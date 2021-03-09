--[[
 	author 	    :Loong
 	date    	:2018-04-16 20:19:31
 	descrition 	:These resources are left to third parties for secondary packaging and replacement
--]]

WWWTool = {}

local My = WWWTool

--刷新
function My.Refresh()
  My.chgPath = CSApp.WwwStreaming .. "chg/"
end

--加载资源
--op:0:贴图,1:文本
--path(string):路径
--func(回调方法):回调参数1:文本或图片,参数2:错误信息
--self(回调方法的对象)
function My.Load(op, path, func, self, ...)
  if func == nil then return end
  local www = UnityWebRequest.Get(path)
  local dlHdl = nil
  if op == 0 then
    dlHdl = DownloadHandlerTexture.New()
    www.downloadHandler = dlHdl;
  end
  www:SendWebRequest();
  coroutine.www(www)
  local isError = www.isNetworkError or www.isHttpError
  local err = www.error
  if isError then
    iTrace.Error("Loong", "加载:", path, ", 错误:", err)
    if StrTool.IsNullOrEmpty(err) then err="net error" end
  else
    err = nil
  end
  local val = nil
  if err == nil then
    if op == 0 then
      val = dlHdl.texture
    else
      val = www.downloadHandler.text
    end
  end
  if self then
    func(self, val, err, ...)
  else
    func(val, err, ...)
  end
  www:Dispose()
end

function My.LoadTex(path, func, self, ...)
  coroutine.start(My.Load, 0, path, func, self, ...)
end

function My.LoadText(path, func, self)
  coroutine.start(My.Load, 1, path, func, self)
end

--加载可替换资源
function My.LoadChgTex(path, func, self)
  if My.chgPath == nil then My.Refresh() end
  local full = My.chgPath .. path
  coroutine.start(My.Load, 0, full, func, self)
end

--加载流文件夹资源
function My.LoadStreamTex(path, func, self)
  local full = App.Streaming .. path
  coroutine.start(My.Load, 0, full, func, self)
end
