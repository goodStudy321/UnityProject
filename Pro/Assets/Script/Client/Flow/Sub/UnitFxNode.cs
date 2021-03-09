using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /// <summary>
    /// AU:Loong
    /// TM:2016.04.21,16:58:48
    /// CO:nuolan1.ActionSoso1
    /// BG:
    /// </summary>
    [System.Serializable]
    public class UnitFxNode : FlowChartNode
    {
        #region 字段
        private Unit target = null;
        /// <summary>
        /// 绑定ID
        /// </summary>
        public long uid = 0;
        /// <summary>
        /// 特效名称
        /// </summary>
        public string fxName = "";

        /// <summary>
        /// 骨骼名称 不填时代表根节点即脚下
        /// </summary>
        public string boneName = "";

        #endregion

        #region 属性

        #endregion

        #region 私有方法

        private void Die(Unit u)
        {
            if (u != target) return;
            RemoveFx();
        }

        /// <summary>
        /// 移除特效
        /// </summary>
        private void RemoveFx()
        {
            Transform bone = target.mUnitBoneInfo.GetBoneByName(boneName);
            Transform fx = bone.Find(fxName);
            if (fx != null)
            {
                GbjPool.Instance.Add(fx.gameObject);
            }
        }

        /// <summary>
        /// 设置特效
        /// </summary>
        /// <param name="u"></param>
        private void AddFx(GameObject go)
        {
            Transform bone = target.mUnitBoneInfo.GetBoneByName(boneName);
            if (bone == null)
            {
                Debug.LogError(Format("没有名称为:{0}的骨骼", boneName));
            }
            else
            {
                Transform tran = go.transform;
                tran.parent = bone;
                tran.localPosition = Vector3.zero;
                UnitEventMgr.die += Die;
            }
            Complete();
        }


        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            if (string.IsNullOrEmpty(fxName))
            {
#if UNITY_EDITOR
                Debug.LogError(Format("必须指定特效名称"));
#endif
                Complete(); return;
            }
            if (uid == 0)
            {
                target = InputMgr.instance.mOwner;
            }
            else
            {
                target = UnitMgr.instance.FindUnitByUid(uid);
            }
            if (target == null)
            {
                Debug.LogError(Format("无uid为:{0}的单位", uid));
            }
            else if (target.Dead || target.DestroyState)
            {
                Complete();
            }
            else
            {
                AssetMgr.LoadPrefab(fxName, AddFx);
            }
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            uid = br.ReadInt64();
            ExString.Read(ref fxName, br);
            ExString.Read(ref boneName, br);
            //fxName = br.ReadString();
            //boneName = br.ReadString();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(uid);
            ExString.Write(fxName, bw);
            ExString.Write(boneName, bw);
            //bw.Write(fxName);
            //bw.Write(boneName);
        }

        public override void Preload()
        {
            PreloadMgr.prefab.Add(fxName);
        }

        public override void Dispose()
        {
            RemoveFx();
        }

        #endregion


        #region 编辑器字段/属性/方法

#if UNITY_EDITOR

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as UnitFxNode;
            if (node == null) return;
            uid = node.uid;
            fxName = node.fxName;
            boneName = node.boneName;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 5";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical(StyleTool.Group);

            UIEditLayout.LongField("目标UID:", ref uid, o);
            if (uid == 0)
            {
                UIEditLayout.HelpInfo("本地玩家");
            }
            UIEditLayout.TextField("特效名称", ref fxName, o);
            if (string.IsNullOrEmpty(fxName))
            {
                UIEditLayout.HelpError("必须指定有效名称");
            }
            UIEditLayout.TextField("绑定位置:", ref boneName, o);
            if (string.IsNullOrEmpty(boneName))
            {
                UIEditLayout.HelpInfo("正下方");
            }
            EditorGUILayout.EndVertical();
        }

#endif
        #endregion
    }
}