--region *.lua
--Date
--此文件由[HS]创建生成

-- Internal register  
local _baseclass={}  
  
function baseclass(baseClass)  
    local class_type={}  
    class_type.Type   = 'baseclass'  
    class_type.Ctor     = false  
      
    --命名来源于c++类对象中的虚表
    local vtbl = {}  
    --该vtbl被设置为class_type的元表且对class_type的__newindex操作被hook到了在vtbl上进行
    _baseclass[class_type] = vtbl  
    setmetatable(class_type,{__newindex = vtbl, __index = vtbl})  
  
  	--里是用来实现类的继承逻辑的，子类继承自base_type类，子类中的vtbl只保证了通过对象a能够访问到子类中添加的方法，
  	--但是对于那些在子类的父类base_type中的方法就得靠这里来访问。这里给vtbl再设置了一个元表，其中__index原方法指向
  	--的就是父类的vtbl（这里保存有父类中的方法），因此最终的对象访问一个方法（比如print_x()），在其子类的vtbl中找
  	--不到时会向上到类的父类的vtbl中找，并如此递进直到找到了或者确定不存在为止。
    if baseClass then  
        setmetatable(vtbl,{__index=  
            function(t,k)  
                local ret=_baseclass[baseClass][k]  
                vtbl[k]=ret  
                return ret  
            end  
        })  
    end  
      
    class_type.BaseClass   = baseClass 
    class_type.New      = function(...)   
        --创建一个对象，__createfunc依赖。
        local obj= {}  
        obj.BaseClass  = class_type  
        obj.Type  = 'object'  
        do  
            local create  
            create = function(c, ...)  
            	--c（当前类）是否存在super（也即父类）如果存在则递归调用
                if c.BaseClass then  
                    create(c.BaseClass, ...)  
                end  
                --在类（包含当前类及其所有父类）的ctor中声明的变量通通都在obj中被创建，就成功的实现了将对象初始化
                if c.Ctor then  
                    c.Ctor(obj, ...)  
                end  
            end  
  
            create(class_type,...)  
        end  
  		--类（也就是这里即将被返回的class_type表）中添加的任何属性（变量）或方法（函数）都被实际在vtbl中创建，
  		--可以通过对象来访问到类中的方法了（也包括那些不在类的ctor中被申明的变量）
        setmetatable(obj,{ __index = _baseclass[class_type] })  
        return obj  
    end  
  
    class_type.Super = function(self, f, ...)  
        assert(self and self.Type == 'object', string.format("'self' must be a object when call super(self, '%s', ...)", tostring(f)))  
  
        local originsuper = self.BaseClass  
        --子类对象中调用super的f方法时，将沿着继承链表（baseClass chain）自上而下在众父类中寻找第一个与自身f方法不同地址的类
        local s     = originsuper  
        local baseClass  = s.BaseClass  
        --
        while baseClass and s[f] == baseClass[f] do  
            s = baseClass  
            baseClass = baseClass.BaseClass  
        end  
          
        assert(baseClass and baseClass[f], string.format("baseClass class or function cannot be found when call .super(self, '%s', ...)", tostring(f)))  
        --现在super[F]是不同于自self[F]，但F在super也可能继承super类的父类
        while baseClass.BaseClass and baseClass[f] == baseClass.BaseClass[f] do  
            baseClass = baseClass.BaseClass  
        end  
  
        --如果super也有一个父类，暂时设置：super调用父类的方法
        --这是为了避免堆栈溢出
        if baseClass.BaseClass then  
            self.BaseClass = baseClass  
        end  
  
        --现在，调用super的函数
        local result = baseClass[f](self, ...)  
  
        --重新设置 
        if baseClass.BaseClass then  
            self.BaseClass = originsuper  
        end  
  
        return result  
    end  
  
    return class_type 
end  
--endregion
