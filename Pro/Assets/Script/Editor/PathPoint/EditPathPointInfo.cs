using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        54974b83-1ed0-4d14-b1a5-10b53977aa6e
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/4/10 14:36:48
    /// BG:编辑路径移动点信息
    /// </summary>
    [Serializable]
    public class EditPathPointInfo
    {
        #region 字段
        private int select = 0;

        public List<PathPointInfo> infos = new List<PathPointInfo>();
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
        public void OnGUI(Object obj)
        {
            UIDrawTool.IDrawLst<PathPointInfo>(obj, infos, "EditPointsInfo", "路径");
        }

        public void Read(PathInfo pathMoveInfo)
        {
            if (pathMoveInfo == null) return;
            infos.Clear();
            int length = pathMoveInfo.points.list.Count;
            for (int i = 0; i < length; i++)
            {

                PathPointInfo info = new PathPointInfo();
                info.Read(pathMoveInfo.points.list[i]);
                infos.Add(info);
            }
        }

        public void DrawSceneGUI(Object obj)
        {
            if (GUILayout.Button("聚焦")) SceneViewUtil.Focus(infos[select].pos);
            UIDrawTool.Buttons(obj, "点列表", "点", infos.Count, ref select);
        }

        public void DrawSceneHandle(Object obj)
        {
            if (Event.current != null)
            {
                UIVectorUtil.AddInfo<PathPointInfo>(obj, infos, "点", Event.current.shift, 0);
                UIVectorUtil.SetInfo<PathPointInfo>(obj, infos, select, "点", Event.current.control, 0);
            }
            UIVectorUtil.DrawInfos<PathPointInfo>(obj, infos, Color.yellow, "点", select, true);
        }

        public override string ToString()
        {
            StringBuilder sb = new StringBuilder();
            int length = infos.Count;
            int last = length - 1;
            for (int i = 0; i < length; i++)
            {
                PathPointInfo info = infos[i];
                string str = info.ToString();
                sb.Append(str);
                if (i < last) sb.Append(";");
            }
            return sb.ToString();
        }
        #endregion
    }
}