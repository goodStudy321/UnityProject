//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/5/10 10:46:35
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /// <summary>
    /// UICopyMainInfoData
    /// </summary>
    public class UICopyMainInfoData
    {
        #region 字段

        /// <summary>
        /// 标题
        /// </summary>
        public string title = null;

        public int titleID = 0;

        /// <summary>
        /// 目标
        /// </summary>
        public string target = null;

        public int targetID = 0;

        /// <summary>
        /// 男性解锁文本
        /// </summary>
        public string manUnlock = null;

        public int manUnlockID = 0;

        /// <summary>
        /// 女性解锁文本
        /// </summary>
        public string womanUnlock = null;

        public int womanUnlockID = 0;

        /// <summary>
        /// 男性图标
        /// </summary>
        public string manIcon = null;

        /// <summary>
        /// 女性图标
        /// </summary>
        public string womanIcon = null;
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

        public void Read(BinaryReader br)
        {
            ExString.Read(ref title, br);
            ExString.Read(ref target, br);
            titleID = br.ReadInt32();
            targetID = br.ReadInt32();

            ExString.Read(ref manUnlock, br);
            ExString.Read(ref womanUnlock, br);

            manUnlockID = br.ReadInt32();
            womanUnlockID = br.ReadInt32(); 
            ExString.Read(ref manIcon, br);
            ExString.Read(ref womanIcon, br);

        }

        public void Write(BinaryWriter bw)
        {
            ExString.Write(title, bw);
            ExString.Write(target, bw);

            bw.Write(titleID);
            bw.Write(targetID);

            ExString.Write(manUnlock, bw);
            ExString.Write(womanUnlock, bw);

            bw.Write(manUnlockID);
            bw.Write(womanUnlockID);
            ExString.Write(manIcon, bw);
            ExString.Write(womanIcon, bw);
        }

        public void Copy(UICopyMainInfoData other)
        {
            titleID = other.titleID;
            targetID = other.targetID;
            manUnlock = other.manUnlock;
            womanUnlock = other.womanUnlock;
            manIcon = other.manIcon;
            womanIcon = other.womanIcon;
        }

        #endregion

#if UNITY_EDITOR
        public void Draw(Object obj)
        {
            UIEditLayout.TextField("标题", ref title, obj);
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.IntField("标题ID:", ref titleID, obj);
            EditorGUILayout.LabelField("", "", StyleTool.RedX, UIOptUtil.plus);
            EditorGUILayout.EndHorizontal();
            UIEditLayout.TextField("目标", ref target, obj);
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.IntField("目标ID:", ref targetID, obj);
            EditorGUILayout.LabelField("", "", StyleTool.RedX, UIOptUtil.plus);
            EditorGUILayout.EndHorizontal();

            UIEditLayout.TextField("解锁描述(男)", ref manUnlock, obj);
            UIEditLayout.IntField("解锁描述(男)ID:", ref manUnlockID, obj);
            UIEditLayout.TextField("解锁描述(女)", ref womanUnlock, obj);
            UIEditLayout.IntField("解锁描述(女)ID:", ref womanUnlockID, obj);

            UIEditLayout.TextField("图标(男)", ref manIcon, obj);
            UIEditLayout.TextField("图标(女)", ref womanIcon, obj);

        }
#endif
    }
}