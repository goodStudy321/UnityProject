using System;
using UnityEngine;
using Phantom.Protocal;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        e9cdb7db-4ed8-4b36-9c37-2e36daba4e9f
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/12 15:07:05
    /// BG:采集物管理
    /// </summary>
    public static class CollectionMgr
    {
        #region 字段
        private static long curID = -1;

        private static Transform root = null;

        private static CollectionState state = CollectionState.None;


        private static List<CollectionBase> collects = new List<CollectionBase>();

        /// <summary>
        /// 采集物字典 键值:UID
        /// </summary>
        private static Dictionary<long, CollectionBase> dic = new Dictionary<long, CollectionBase>();

        /// <summary>
        /// 默认模型
        /// </summary>
        public const string DefaultMod = "Collection_cube";
        #endregion

        #region 属性
        /// <summary>
        /// 当前进入采集的采集物ID
        /// </summary>
        public static long CurID
        {
            get { return curID; }
            set { curID = value; }
        }

        /// <summary>
        /// 当前采集物
        /// </summary>
        public static CollectionBase Cur
        {
            get
            {
                return Get(curID);
            }
        }


        /// <summary>
        /// 采集物根结点
        /// </summary>
        public static Transform Root
        {
            get { return root; }
            set { root = value; }
        }

        /// <summary>
        /// 采集状态
        /// </summary>
        public static CollectionState State
        {
            get { return state; }
            set
            {
                state = value;
                //iTrace.Warning("Loong", "采集状态:" + state);
            }
        }

        /// <summary>
        /// 采集物列表
        /// </summary>
        public static List<CollectionBase> Collects
        {
            get { return collects; }
        }


        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 请求开始采集
        /// </summary>
        private static void ReqBegCollect(params object[] args)
        {
            if (CurID == -1) return;
            CollectionBase collect = Get(CurID);
            if (collect != null) collect.ReqBegCollect();
        }

        /// <summary>
        /// 响应开始采集
        /// </summary>
        /// <param name="args"></param>
        private static void RespBegCollect(object obj)
        {
            m_collect_start_toc resp = obj as m_collect_start_toc;
            CollectionBase collect = Get(resp.collect_id);
            if (collect != null) collect.RespBegCollect(resp);
        }

        /// <summary>
        /// 请求停止采集
        /// </summary>
        public static void ReqStopCollect(params object[] args)
        {
            if (CurID == -1) return;
            CollectionBase collect = Get(CurID);
            if (collect != null) collect.ReqStopCollect();
        }

        /// <summary>
        /// 响应停止采集
        /// </summary>
        /// <param name="resp"></param>
        public static void RespStopCollect(object obj)
        {
            m_collect_stop_toc resp = obj as m_collect_stop_toc;
            CollectionBase collect = Get(resp.collect_id);
            if (collect != null) collect.RespStopCollect(resp);
        }


        /// <summary>
        /// 响应结束采集
        /// </summary>
        /// <param name="obj"></param>
        private static void RespEndCollect(object obj)
        {
            m_collect_succ_toc resp = obj as m_collect_succ_toc;
            CollectionBase collect = Get(resp.collect_id);
            if (collect != null) collect.RespEndCollect(resp);
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 初始化
        /// </summary>
        public static void Initialize()
        {
            Root = TransTool.CreateRoot(typeof(CollectionMgr).Name);
        }

        public static void Update()
        {
            int length = collects.Count;
            for (int i = 0; i < length; i++)
            {
                collects[i].Update();
            }
        }

        /// <summary>
        /// 获取采集物
        /// </summary>
        /// <param name="uid">唯一ID</param>
        /// <returns></returns>
        public static CollectionBase Get(long uid)
        {
            if (dic.ContainsKey(uid)) return dic[uid];
            return null;
        }

        /// <summary>
        /// 查找第一个具有指定ID的采集物
        /// </summary>
        /// <param name="id">采集物ID</param>
        /// <returns></returns>
        public static CollectionBase Get(uint id)
        {
            int length = collects.Count;
            for (int i = 0; i < length; i++)
            {
                CollectionBase item = collects[i];
                if (item.Info == null) continue;
                if (item.Info.id == id) return item;
            }
            return null;
        }

        /// <summary>
        /// 添加
        /// </summary>
        /// <param name="uid">唯一ID</param>
        /// <param name="value">采集物</param>
        public static void Add(long uid, CollectionBase value)
        {
            if (value == null) return;
            if (dic.ContainsKey(uid))
            {
                iTrace.Error("Loong", string.Format("已经存在UID为:{0}的采集物,无法添加", uid));
            }
            else
            {
                dic.Add(uid, value);
                collects.Add(value);
                value.Initilize();
                //EventMgr.Trigger("CollectCreate", uid, value.Info.id);
            }
        }

        /// <summary>
        /// 移除
        /// </summary>
        /// <param name="uid">唯一ID</param>
        public static bool Remove(long uid)
        {
            if (!dic.ContainsKey(uid)) return false;
            CollectionBase collect = dic[uid];
            //iTrace.eLog("Loong", string.Format("移除采集物,UID:{0}, ID:{1}", uid, collect.Info.id));
            dic.Remove(uid);
            collects.Remove(collect);
            collect.Dispose();
            return true;
        }

        /// <summary>
        /// 释放
        /// </summary>
        public static void Dispose()
        {
            int length = collects.Count;
            for (int i = 0; i < length; i++)
            {
                collects[i].Dispose();
            }
            dic.Clear();
            collects.Clear();
            Reset();
        }

        /// <summary>
        /// 重置
        /// </summary>
        public static void Reset()
        {
            EventMgr.Trigger("ResetCollect");
            State = CollectionState.None;
            CurID = -1;
        }

        /// <summary>
        /// 获取离主角最近的采集物坐标
        /// </summary>
        /// <param name="typeID">类型ID</param>
        /// <param name="uidStr">过滤UID字符串</param>
        /// <returns></returns>
        public static GameObject GetNearest(uint typeID, string uidStr, bool isFilter = false)
        {
            var hero = InputMgr.instance.mOwner;
            var tran = hero.UnitTrans;
            if (tran == null) return null;
            var heroPos = tran.position;
            float dis = float.MaxValue;
            float tmpDis = 0;
            int length = collects.Count;
            var tmpPos = Vector3.zero;
            GameObject target = null;
            List<GameObject> targetList = new List<GameObject>();
            for (int i = 0; i < length; i++)
            {
                var it = collects[i];
                var info = it.Info;
                if (info == null) continue;
                if (info.id != typeID) continue;
                var go = it.Go;
                if (go == null) continue;
                if (!string.IsNullOrEmpty(uidStr))
                {
                    if (go.name.Equals(uidStr)) continue;
                }
                tmpPos = go.transform.position;
                tmpDis = Vector3.Distance(heroPos, tmpPos);
                if (tmpDis < dis)
                {
                    dis = tmpDis;
                    target = go;
                }
                targetList.Add(go);
            }
            if (isFilter == true)
            {
                for (int i = 0; i < targetList.Count; i++)
                {
                    if (targetList[i] == target)
                    {
                        targetList.Remove(targetList[i]);
                    }
                }
                int len = targetList.Count;
                int index = UnityEngine.Random.Range(0, len);
                return targetList[index];
            }
            return target;
        }

        /// <summary>
        /// 创建采集物
        /// </summary>
        /// <param name="id">采集物ID</param>
        /// <param name="uid">唯一ID</param>
        /// <param name="pos">位置</param>
        public static void Create(UInt32 id, long uid, Vector3 pos)
        {
            if (dic.ContainsKey(uid))
            {
                iTrace.Log("Loong", "已存在UID为:{0}的采集物", uid);
                return;
            }
            CollectionInfo info = CollectionInfoManager.instance.Find(id);
            if (info == null)
            {
                iTrace.Error("Loong", "无ID为:{0}的采集物配置", id);
            }
            else if (!Condition(info))
            {
                return;
            }
            else if (string.IsNullOrEmpty(info.model))
            {
                iTrace.Error("Loong", "ID为:{0}的采集物未配置模型", id);
            }
            else
            {
                var model = GetModName(info);
                var ccd = ObjPool.Instance.Get<CollectionCreateDel>();
                ccd.Position = pos;
                ccd.Info = info;
                ccd.UID = uid;
                AssetMgr.LoadPrefab(model, ccd.Callback);
            }
        }


        public static string GetModName(CollectionInfo info)
        {
            var name = info.model + Suffix.Prefab;
            if (AssetMgr.Instance.Exist(name))
            {
                return info.model;
            }
            return DefaultMod;
        }

        /// <summary>
        /// 服务器返回创建
        /// </summary>
        public static void Create(p_map_actor actor)
        {
            if (actor.collection_extra == null)
            {
                iTrace.Error("Loong", "UID为:{0}的采集物配置(collection_extra)数据为空", actor.actor_id);
            }
            else
            {
                Vector3 pos = NetMove.GetPositon(actor.pos);
                uint id = (uint)actor.collection_extra.type_id;
                Create(id, actor.actor_id, pos);
            }
        }

        /// <summary>
        /// 创建条件
        /// </summary>
        /// <returns></returns>
        public static bool Condition(CollectionInfo info)
        {
            if (info == null) return false;
            CollectionInfo.CreateCond cond = info.cond;
            if (cond.type == 1)
            {
                if (User.instance.MapData.Level > cond.arg)
                {
                    return false;
                }
            }
            else if (cond.type == 2)
            {
                int id = User.instance.MainMissionId;
                if (id > cond.arg)
                {
                    return false;
                }
                //                 MissionData data = User.instance.MainMission;
                //                 if (data == null) return true;
                //                 if (data.MissionID > cond.arg)
                //                 {
                //                     return false;
                //                 }
            }
            return true;
        }

        /// <summary>
        /// 预加载
        /// </summary>
        /// <param name="info"></param>
        public static void Preload(SceneInfo info)
        {
            if (info == null) return;
            var lst = info.updateList.list;
            Preload(lst);
        }

        /// <summary>
        /// 通过id列表预加载
        /// </summary>
        /// <param name="lst">id列表</param>
        public static void Preload(List<uint> lst)
        {
            int length = lst.Count;
            for (int i = 0; i < length; i++)
            {
                uint id = lst[i];
                var rCfg = WildMapManager.instance.Find(id);
                if (rCfg == null) continue;
                uint cID = rCfg.collectionId;
                if (cID < 1) continue;
                Preload(cID);
            }
        }

        /// <summary>
        /// 预加载
        /// </summary>
        /// <param name="collectionID">采集配置id</param>
        public static void Preload(uint collectionID)
        {
            CollectionInfo info = CollectionInfoManager.instance.Find(collectionID);
            if (info == null) return;

            if (string.IsNullOrEmpty(info.model))
            {
                iTrace.Error("Loong", "ID为:{0}的采集物没有配置模型", info.id);
            }
            else
            {
                PreloadMgr.prefab.Add(info.model);
            }
        }

        /// <summary>
        /// 添加监听
        /// </summary>
        public static void AddLsnr()
        {
            EventMgr.Add(EventKey.ReqBegCollect, ReqBegCollect);
            EventMgr.Add(EventKey.ReqStopCollect, ReqStopCollect);
            NetworkListener.Add<m_collect_start_toc>(RespBegCollect);
            NetworkListener.Add<m_collect_stop_toc>(RespStopCollect);
            NetworkListener.Add<m_collect_succ_toc>(RespEndCollect);

        }

        /// <summary>
        /// 移除监听
        /// </summary>
        public static void RemoveLsnr()
        {
            EventMgr.Remove(EventKey.ReqBegCollect, ReqBegCollect);
            EventMgr.Remove(EventKey.ReqStopCollect, ReqStopCollect);
            NetworkListener.Remove<m_collect_succ_toc>(RespEndCollect);
            NetworkListener.Remove<m_collect_stop_toc>(RespStopCollect);
            NetworkListener.Remove<m_collect_start_toc>(RespBegCollect);
        }

        #endregion
    }
}