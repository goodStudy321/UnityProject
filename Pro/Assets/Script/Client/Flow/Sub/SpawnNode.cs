using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using Phantom.Protocal;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
using System.Threading;
#endif

namespace Phantom
{
    /// <summary>
    /// AU:Loong
    /// TM:
    /// BG:AI生成点
    /// </summary>
    [Serializable]
    public class SpawnNode : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// 创建数量
        /// </summary>
        private int count = 0;

        private Coroutine coro = null;

        private HashSet<long> uidSet = new HashSet<long>();

        public List<SpawnInfo> infos = new List<SpawnInfo>();

        #endregion

        #region 属性
        /// <summary>
        /// 出生信息
        /// </summary>
        public List<SpawnInfo> Infos
        {
            get { return infos; }
            set { infos = value; }
        }

        /// <summary>
        /// 创建单位UID集
        /// </summary>
        public HashSet<long> UIDSet
        {
            get { return uidSet; }
        }


        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private void Clear()
        {
            if (coro != null) MonoEvent.Stop(coro);
            coro = null;
        }

        /// <summary>
        /// 创建单位监听
        /// </summary>
        /// <param name="unit"></param>
        private void CreateUnit(Unit unit)
        {
            if (unit == null) return;
            if (!uidSet.Contains(unit.UnitUID)) return;
            ++count;
#if UNITY_EDITOR
            created.Add(unit.UnitUID);
#endif
            if (uidSet.Count == count)
            {
                Complete();
            }
        }

        private IEnumerator Send()
        {
            //添加创建监听事件
            UnitEventMgr.create += CreateUnit;
            int length = infos.Count;
            for (int i = 0; i < length; i++)
            {
                SpawnInfo info = Infos[i];
                yield return new WaitForSeconds(info.Duration);
                m_single_summon_tos req = ObjPool.Instance.Get<m_single_summon_tos>();
                if (req.monster == null)
                    req.monster = ObjPool.Instance.Get<p_single_summon>();
                req.monster.actor_id = info.UID;
                req.monster.type_id = info.TypeID;
                req.monster.action_string = info.BornAnimID;
                req.monster.pos = NetMove.GetPointInfo(info.pos, info.RotY);
                NetworkClient.Send<m_single_summon_tos>(req);
            }
        }
        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
#if UNITY_EDITOR
            created.Clear();
#endif
            if (Infos.Count == 0)
            {
                Debug.LogError(Format("出生节点信息数量为空"));
                Complete();
            }
            else
            {
                coro = MonoEvent.Start(Send());
            }
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            UnitEventMgr.create -= CreateUnit;
        }


        #endregion

        #region 公开方法

        public override void Stop()
        {
            base.Stop();
            Clear();
            UnitEventMgr.create -= CreateUnit;
        }

        public override void Initialize()
        {
            base.Initialize();
            int length = Infos.Count;
            for (int i = 0; i < length; i++)
            {
                SpawnInfo info = Infos[i];
                if (uidSet.Contains(info.UID))
                {
                    Debug.LogError(Format("出生信息中具有重复UID:{0}", info.UID));
                }
                else
                {
                    uidSet.Add(info.UID);
                }
            }
        }

        public override void Preload()
        {
            int length = Infos.Count;
            for (int i = 0; i < length; i++)
            {
                SpawnInfo info = Infos[i];
                uint baseID = (uint)info.TypeID;
                UnitPreLoad.instance.PreLoadUnitAssetsByTypeId(baseID);
            }
        }

        public override void Dispose()
        {
            Clear();
            //移除创建监听事件
            UnitEventMgr.create -= CreateUnit;

            int length = infos.Count;
            for (int i = 0; i < length; i++)
            {
                long uid = infos[i].UID;
                Unit unit = UnitMgr.instance.FindUnitByUid(uid);
                if (unit == null) continue;
                m_single_ai_tos req = ObjPool.Instance.Get<m_single_ai_tos>();
                req.monster_id = uid; req.type = 4;
                NetworkClient.Send<m_single_ai_tos>(req);
            }
        }

        public override void Reset()
        {
            base.Reset();
            count = 0;
        }

        public override void Read(BinaryReader br)
        {
            base.Read(br);
            int length = br.ReadInt32();
            for (int i = 0; i < length; i++)
            {
                var it = new SpawnInfo();
                it.Read(br);
                infos.Add(it);
            }
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            int length = infos.Count;
            bw.Write(length);
            for (int i = 0; i < length; i++)
            {
                var it = infos[i];
                it.Write(bw);
            }
        }
        #endregion


        #region 编辑器字段/属性/方法

#if UNITY_EDITOR

        /// <summary>
        /// 已创建列表
        /// </summary>
        private List<long> created = new List<long>();

        protected override void EditDrawCtrlUI(Object o)
        {
            UIDrawTool.Buttons(o, "出生点列表:", "出生点:", infos.Count, ref placeIndex);
        }


        protected override void EditDrawDebug(Object o)
        {
            if (count == UIDSet.Count)
            {
                UIEditLayout.HelpInfo("已全部创建完成");
            }
            else
            {
                EditorGUILayout.LabelField("已创建单位数量:", count.ToString());
            }
            UIDrawTool.LongLst(o, created, "Created", "已创建单位UID列表");
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 2";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical(StyleTool.Box);
            UIEditLayout.HelpInfo("通过在场景视图,Ctrl+左键点击,可以添加生成点并设置位置");
            UIEditLayout.HelpInfo("通过在场景视图,点击对应按钮,Ctrl+右键点击,可以设置生成点位置");
            UIDrawTool.IDrawLst<SpawnInfo>(o, infos, "SpawnInfos", "生成点信息列表");
            EditorGUILayout.EndVertical();

        }

        public override void EditDrawSceneGui(Object o)
        {
            base.EditDrawSceneGui(o);
            if (e == null) return;
            UIVectorUtil.AddInfo<SpawnInfo>(o, infos, "出生点", e.control);
            UIVectorUtil.SetInfo<SpawnInfo>(o, infos, placeIndex, "出生点", e.control);
            UIVectorUtil.DrawInfos<SpawnInfo>(o, infos, Color.green, "出生点", placeIndex);
        }

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as SpawnNode;
            if (node == null) return;
            int length = node.infos.Count;
            for (int i = 0; i < length; i++)
            {
                var oinfo = node.infos[i];
                var info = new SpawnInfo();
                info.Copy(oinfo);

                Thread.Sleep(1);
                infos.Add(info);
            }
        }

        public override void EditClickNode()
        {
            if (placeIndex >= infos.Count) return;
            Vector3 pos = infos[placeIndex].pos;
            SceneViewUtil.Focus(pos);
        }

#endif
        #endregion
    }
}