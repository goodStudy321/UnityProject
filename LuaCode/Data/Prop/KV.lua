KV=Super:New{Name="KV"}

function KV:Init(k,v,b)
    self.k=k
    self.v=v
    self.b=b
end

function KV:Dispose()
    self.k=nil
    self.v=nil
    self.b=nil
end