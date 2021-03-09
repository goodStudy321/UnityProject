//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/5/5 17:19:40
//=============================================================================

using System;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Phantom
{
    /// <summary>
    /// 区域加载管理器
    /// </summary>
    public class PreloadAreaMgr
    {
        #region 字段
        private uint curID = 0;

        private Action complete = null;

        private ElapsedTime elapsed = new ElapsedTime();

        private HashSet<uint> set = new HashSet<uint>();

        public static readonly PreloadAreaMgr Instance = new PreloadAreaMgr();
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        private PreloadAreaMgr()
        {

        }
        #endregion

        #region 私有方法
        private void Complete()
        {
            AssetMgr.Instance.complete -= Complete;
            if (complete != null) complete();
            complete = null;
            elapsed.End("PreloadArea,ID:{0}", curID);
        }

        private void CreateNpc()
        {
            AssetMgr.Instance.complete -= CreateNpc;
            var cfg = PreloadAreaManager.instance.Find(curID);
            if (cfg == null) return;
            NPCMgr.instance.InstantiateNpc(cfg.npcIDs.list);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public void Init()
        {
            EventMgr.Add("LogoutSuc", Clear);
        }

        public void InsNpc()
        {
            var mainPlayer = InputVectorMove.instance.MoveUnit;
            if (mainPlayer == null) return;
            uint resId = MapPathMgr.instance.GetResIdByPos(mainPlayer.Position);
            var cfg = PreloadAreaManager.instance.Find(resId);
            if (cfg != null) NPCMgr.instance.InstantiateNpc(cfg.npcIDs.list);
        }

        public void Clear(params object[] args)
        {
            //iTrace.Warning("Loong", "PreloadArea clear");
            set.Clear();
        }

        public void Preload(UInt32 id)
        {
            var cfg = PreloadAreaManager.instance.Find(id);
            Preload(cfg);
        }

        public void Preload(PreloadArea cfg)
        {
            if (cfg == null) return;
            curID = cfg.id;
            FlowChartMgr.Preload(cfg.ftNames.list);
            NPCMgr.instance.PreloadNPC(cfg.npcIDs.list);
            AssetMgr.Instance.complete += CreateNpc;
            var lst = cfg.wildIDs.list;
            var length = lst.Count;
            for (int i = 0; i < length; i++)
            {
                var it = lst[i];
                var info = WildMapManager.instance.Find(it);
                if (info == null) continue;
                if (info.monsterId > 0)
                {
                    UnitPreLoad.instance.PreLoadUnitAssetsByTypeId(info.monsterId);
                }
                else if (info.collectionId > 0)
                {
                    CollectionMgr.Preload(info.collectionId);
                }
            }
            if (!set.Contains(cfg.id)) set.Add(cfg.id);
        }


        public void Start(UInt32 id, Action cb)
        {
            var cfg = PreloadAreaManager.instance.Find(id);
            if (cfg == null)
            {
                if (cb != null) cb();
            }
            else if (set.Contains(id))
            {
                if (cb != null) cb();
            }
            else
            {
                curID = id;
                complete += cb;
                elapsed.Beg();
                Preload(cfg);
                AssetMgr.Instance.complete += Complete;
                AssetMgr.Start(null);
            }
        }
        #endregion
    }
}