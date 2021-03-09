using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

namespace Hello.Game
{
    public class ObjPool : PoolBase<object>
    {
        public static readonly ObjPool Instance = new ObjPool();

        private ObjPool()
        {

        }

        protected override object Create(string name)
        {
            object obj = null;
            var type = Type.GetType(name);
            if(type == null)
            {
                iTrace.Error("Hello", "not find type:{0}", name);
            }
            else
            {
                obj = Activator.CreateInstance(type, null);
            }
            return obj;
        }

        public T1 Get<T1>() where T1 : class, new()
        {
            var name = typeof(T1).FullName;
            var t = Get(name);
            return t as T1;
        }

        public object Get(Type type)
        {
            if (type == null) return null;
            return Get(type.FullName);
        }

        public void Add(object obj)
        {
            if (obj == null) return;
            Add(obj.GetType().FullName, obj);
        }
    }
}

