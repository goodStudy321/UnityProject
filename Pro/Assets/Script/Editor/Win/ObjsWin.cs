using System;
using System.IO;
using Hello.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Hello.Edit
{
    /// <summary>
    /// ObjsWin
    /// </summary>
    public class ObjsWin : PageWin<ObjPathPage, string>
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 打开对象窗口
        /// </summary>
        /// <param name="paths">对象路径列表</param>
        public static void Open(List<string> paths)
        {
            if (paths == null || paths.Count < 1) return;
            var win = GetWindow<ObjsWin>();
            paths.Sort();
            win.Init(paths);
        }


        public static void Open(string[] paths)
        {
            if (paths == null || paths.Length < 1) return;
            var lst = new List<string>(paths);
            Open(lst);
        }

        /// <summary>
        /// 打开对象窗口
        /// </summary>
        /// <param name="objs">对象列表</param>
        public static void Open(List<Object> objs)
        {
            if (objs == null || objs.Count < 1) return;
            var paths = new List<string>();
            int length = objs.Count;
            for (int i = 0; i < length; i++)
            {
                var obj = objs[i];
                if (obj == null) continue;
                var path = AssetDatabase.GetAssetPath(obj);
                if (string.IsNullOrEmpty(path))
                {
                    path = obj.name;
                }
                paths.Add(path);
            }
            Open(paths);
        }
        #endregion
    }
}