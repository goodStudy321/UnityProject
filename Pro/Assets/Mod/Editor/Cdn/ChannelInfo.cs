//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/31 17:26:29
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using Object = UnityEngine.Object;
    /// <summary>
    /// 渠道信息
    /// </summary>

    [Serializable]
    public class ChannelInfo : IDraw
    {
        #region 字段
        public int id = 0;

        public string des = "";

        public List<string> and_gcids = new List<string>() { "null", "0", "Test" };

        public List<string> ios_gcids = new List<string>() { "null", "0", "Test" };
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ChannelInfo()
        {

        }

        public ChannelInfo(int id, string des, string[] and, string[] ios)
        {
            this.id = id;
            this.des = des;
            Add(and_gcids, and);
            Add(ios_gcids, ios);
        }

        public ChannelInfo(int id, string des, string and = null, string ios = null)
        {
            this.id = id;
            this.des = des;
            Add(and_gcids, and);
            Add(ios_gcids, ios);
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Add(List<string> lst, string id)
        {
            if (string.IsNullOrEmpty(id)) return;
            lst.Add(id);
        }

        public void Add(List<string> lst, string[] ids)
        {
            if (ids == null) return;
            int length = ids.Length;
            for (int i = 0; i < length; i++)
            {
                lst.Add(ids[i]);
            }
        }

        public List<string> GetGcids(string plat)
        {
            return (plat == "iOS") ? ios_gcids : and_gcids;
        }

        public void Draw(Object o, IList lst, int idx)
        {
            EditorGUILayout.BeginHorizontal(StyleTool.Win);
            UIEditLayout.IntField(des, ref id, o);
            EditorGUILayout.EndHorizontal();

            UIDrawTool.StringLst(o, ios_gcids, "channelinfogcids", "苹果 GameChannelID列表");
            UIDrawTool.StringLst(o, and_gcids, "channelinfogcids", "安卓 GameChannelID列表");

        }
        #endregion
    }
}