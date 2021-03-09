using UnityEngine;
using System.Collections.Generic;
using System.Reflection;
using System;


class ObjectPool<T>
{
    private static ObjectPool<T> ms_instance = null;
    private LinkedList<T> m_list = new LinkedList<T>();

    protected ObjectPool()
    {
    }

    protected static DT Get<DT>() where DT : ObjectPool<T>, new()
    {
        if (ms_instance == null)
        {
            ms_instance = new DT();
            //ms_instance = Activator.CreateInstance<DT>();
        }

        return ms_instance as DT;
    }

    protected bool Has()
    {
        return 0 < m_list.Count;
    }

    protected T Apply()
    {
        T t = m_list.First.Value;
        m_list.RemoveFirst();

        return t;
    }

    public void Reclaim(T obj)
    {
        m_list.AddLast(obj);
    }
}
    
class EnumPairPool : ObjectPool<ProtoBuf.Serializers.EnumSerializer.EnumPair>
{
    public static EnumPairPool instance
    {
        get { return Get<EnumPairPool>(); }
    }

    /*public ProtoBuf.Serializers.EnumSerializer.EnumPair Apply(int wireValue, object raw, Type type)
    {
        ProtoBuf.Serializers.EnumSerializer.EnumPair obj;
        if (Has())
        {
            obj = Apply();
            obj.Reset(wireValue, raw, type);
        }
        else
        {
            obj = new ProtoBuf.Serializers.EnumSerializer.EnumPair(wireValue, raw, type);
        }

        return obj;
    }*/
}
    