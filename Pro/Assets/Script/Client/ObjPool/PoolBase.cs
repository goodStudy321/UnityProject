using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Hello.Game
{
    public class PoolInfo<T> where T : class, new()
    {
        private bool persist;
        
        public bool Persist
        {
            get { return persist; }
            set { persist = value; }
        }

        public Queue<T> queue = new Queue<T>();
    }

    public abstract class PoolBase<T> where T : class, new()
    {
        private Dictionary<string, PoolInfo<T>> dic = new Dictionary<string, PoolInfo<T>>();


        protected virtual T Create(string name)
        {
            return new T();
        }

        protected virtual void Dispose(T t)
        {

        }

        public virtual T Get(string name)
        {
            T t = null;
            if (dic.ContainsKey(name))
            {
                var info = dic[name];
                if(info.queue.Count > 0)
                {
                    t = info.queue.Dequeue();
                }
            }
            if (t == null)
            {
                t = Create(name);
            }
            return t;
        }

        public virtual void Add(string name,T t)
        {
            if (t == null) return;
            PoolInfo<T> info = null;
            if (dic.ContainsKey(name))
            {
                info = dic[name];
            }
            else
            {
                info = new PoolInfo<T>();
                dic[name] = info;
            }
            info.queue.Enqueue(t);
        }

        public void SetPersist(string name,bool val)
        {
            if (dic.ContainsKey(name))
            {
                var info = dic[name];
                info.Persist = val;
            }
        }

        public bool IsPersist(string name)
        {
            if (dic.ContainsKey(name))
            {
                var info = dic[name];
                return info.Persist;
            }
            return false;
        }

        public virtual bool Exist(string name)
        {
            if (dic.ContainsKey(name))
            {
                return dic[name].queue.Count > 0;
            }
            return false;
        }

        public virtual void Dispose()
        {
            var dem = dic.GetEnumerator();
            while (dem.MoveNext())
            {
                var info = dem.Current.Value;
                if (info.Persist) continue;
                var queue = info.queue;
                var qem = queue.GetEnumerator();
                while (qem.MoveNext())
                {
                    var t = qem.Current;
                    Dispose(t);
                }
                queue.Clear();
            }
        }
    }
    
}


