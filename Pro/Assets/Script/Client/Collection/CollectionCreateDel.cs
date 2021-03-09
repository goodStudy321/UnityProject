using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        d199e414-7b49-499f-8662-233d866cf164
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/12 16:46:16
    /// BG:
    /// </summary>
    public class CollectionCreateDel : DelObj<GameObject>
    {
        #region 字段
        private long uid = -1;

        private CollectionInfo info = null;

        private Vector3 pos = Vector3.zero;
        #endregion

        #region 属性

        /// <summary>
        /// 唯一ID
        /// </summary>
        public long UID
        {
            get { return uid; }
            set { uid = value; }
        }

        /// <summary>
        /// 创建位置
        /// </summary>
        public Vector3 Position
        {
            get { return pos; }
            set { pos = value; }
        }

        /// <summary>
        /// 采集配置信息
        /// </summary>
        public CollectionInfo Info
        {
            get { return info; }
            set { info = value; }
        }
        #endregion

        #region 构造方法
        public CollectionCreateDel()
        {

        }
        #endregion

        #region 私有方法
        private void Set(GameObject t)
        {
            if (info.ht > 0)
            {
                pos.Set(pos.x, info.ht * 0.01f, pos.z);
            }
            else
            {
                pos = RaycastTool.GetGroundHitPos(pos, false);
            }
            t.transform.parent = CollectionMgr.Root;
            t.transform.position = pos;
            t.SetActive(true);
            if (info.modelsize != 0) t.transform.localScale = Vector3.one * Info.modelsize * 0.01f;
            CollectionBase collect = CollectionFty.Create(Info, t, UID);
            CollectionMgr.Add(UID, collect);
        }
        #endregion

        #region 保护方法
        protected override GameObject Get(UnityEngine.Object obj)
        {
            GameObject go = obj as GameObject;
            return go;
        }

        protected override void Execute(GameObject t)
        {
            if (t == null)
            {
                iTrace.Error("Loong", "创建ID为:{0}的采集物时,没有加载到模型:{1}", Info.id, info.model);
                AssetMgr.LoadPrefab("Collection_cube", Set);
            }
            else
            {
                Set(t);
                //iTrace.eLog("Loong", string.Format("创建采集物成功,UID:{0}, ID:{1}", UID, Info.id));
            }

        }
        #endregion

        #region 公开方法
        public override void Dispose()
        {
            pos.Set(0, 0, 0);
            Info = null;
            UID = -1;
        }
        #endregion
    }
}