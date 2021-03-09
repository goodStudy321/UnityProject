using System;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// 处理事件
/// </summary>
/// <param name="objs">可变长度参数数组</param>
public delegate void EventHandler(params object[] objs);


/*
 * CO:            
 * Copyright:   2017-forever
 * CLR Version: 4.0.30319.42000  
 * GUID:        3d845c47-128a-4476-9151-d81cfd43895a
*/

/// <summary>
/// AU:Loong
/// TM:2017/5/15 15:29:07
/// BG:事件管理
/// </summary>
public static class EventMgr
{
    #region 字段
    private static Dictionary<string, EventHandler> dic = new Dictionary<string, EventHandler>();
    #endregion

    #region 属性

    #endregion

    #region 构造方法

    #endregion

    #region 私有方法

    #endregion

    #region 保护方法

    #endregion

    #region 公开方法
    /// <summary>
    /// 添加事件
    /// </summary>
    /// <param name="key">键值</param>
    /// <param name="handler">处理器</param>
    public static void Add(string key, EventHandler handler)
    {
        if (string.IsNullOrEmpty(key)) return;
        if (handler == null) return;
        if (dic.ContainsKey(key))
        {
            dic[key] += handler;
        }
        else
        {
            dic[key] = handler;
        }
    }

    /// <summary>
    /// 清除事件
    /// </summary>
    /// <param name="key">键值</param>
    public static void Clear(string key)
    {
        if (string.IsNullOrEmpty(key)) return;
        if (dic.ContainsKey(key))
        {
            dic.Remove(key);
        }
    }

    /// <summary>
    /// 移除事件
    /// </summary>
    /// <param name="key">键值</param>
    /// <param name="handler">处理器</param>
    public static void Remove(string key, EventHandler handler)
    {
        if (string.IsNullOrEmpty(key)) return;
        if (handler == null) return;
        if (!dic.ContainsKey(key)) return;
        if (dic[key] == null) return;
        dic[key] -= handler;
    }

    /// <summary>
    /// 触发事件
    /// </summary>
    /// <param name="key">键值</param>
    /// <param name="args">参数</param>
    public static void Trigger(string key, params object[] args)
    {
        if (string.IsNullOrEmpty(key)) return;
        if (!dic.ContainsKey(key)) return;
        {
            EventHandler handler = dic[key];
            if (handler != null)
            {
                if (args == null || args.Length <= 0)
                    handler();
                else
                    handler(args);
            }
        }
    }
    #endregion
}