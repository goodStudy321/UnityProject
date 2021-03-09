using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

#if UNITY_EDITOR
using Loong;
using UnityEditor;
#endif

namespace Phantom
{
    /// <summary>
    /// 位置角度设置
    /// </summary>
    [System.Serializable]
    public class Anchor
    {
        /// <summary>
        /// 位置
        /// </summary>
        public Vector3 pos;
        /// <summary>
        /// 沿着Y轴的角度
        /// </summary>
        public float eulurY;
    }
    /// <summary>
    /// AU:Loong
    /// TM:
    /// BG:移动位置平台/传送门
    /// </summary>
    public class TraceTeleportNode : FlowChartNode
    {
        #region 字段

        /// <summary>
        /// 主角
        /// </summary>
        private Unit hero = null;
        /// <summary>
        /// 绑定特效索引
        /// </summary>
        private int effectIndex = 0;

        private Coroutine coro = null;

        private Transform tran = null;

        /// <summary>
        /// 平台物体
        /// </summary>
        private GameObject model = null;

        /// <summary>
        /// 忽略Y轴的英雄位置
        /// </summary>
        private Vector2 heroVec = Vector2.zero;
        /// <summary>
        /// 忽略Y轴的平台位置
        /// </summary>
        private Vector2 modelVec = Vector2.zero;


        /// <summary>
        /// 骨骼列表
        /// </summary>
        private List<Transform> bones = new List<Transform>();
        /// <summary>
        /// 特效列表
        /// </summary>
        private List<GameObject> effects = new List<GameObject>();

        /// <summary>
        /// 上升点
        /// </summary>
        private Vector3 risePoint = Vector3.zero;


        /// <summary>
        /// 平台半径
        /// </summary>
        public float radius = 15;

        /// <summary>
        /// 初始位置
        /// </summary>
        public Vector3 oriPos = Vector3.zero;

        /// <summary>
        /// 移动路径点
        /// </summary>
        public List<Vector3> path = new List<Vector3>();

        /// <summary>
        /// 平台名称
        /// </summary>
        public string modelKey = string.Empty;
        /// <summary>
        /// 特效绑定的骨骼名称
        /// </summary>
        public string effectBone = "effect";
        /// <summary>
        /// 特效名称
        /// </summary>
        public string effectName = null;
        /// <summary>
        /// 上升高度
        /// </summary>
        public float riseHeight = 10f;
        /// <summary>
        /// 上升时间
        /// </summary>
        public float riseTime = 1f;
        /// <summary>
        /// 上升后停顿时间
        /// </summary>
        public float riseDelay = 0.5f;
        /// <summary>
        /// 飞行时间
        /// </summary>
        public float flyTime = 5f;
        /// <summary>
        /// 下降时间
        /// </summary>
        public float downTime = 1f;
        /// <summary>
        /// 下降前停顿时间
        /// </summary>
        public float downDelay = 0.5f;

        /// <summary>
        /// 开始点
        /// </summary>
        public Anchor begAnchor = new Anchor();

        /// <summary>
        /// 结束点
        /// </summary>
        public Anchor endAnchor = new Anchor();

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #region 特效绑定
        /// <summary>
        /// 绑定效果
        /// </summary>
        private void BindEffects()
        {
            if (string.IsNullOrEmpty(effectName)) return;
            if (bones.Count == 0) return;
            BindEffect();
        }

        /// <summary>
        /// 加载特效回调
        /// </summary>
        /// <param name="effect"></param>
        private void LoadEffectCallback(GameObject effect)
        {
            effect.transform.parent = bones[effectIndex];
            effect.transform.localPosition = Vector3.zero;
            ++effectIndex;
            if (effectIndex >= bones.Count) return;
            BindEffect();
        }

        /// <summary>
        /// 通过索引绑定效果
        /// </summary>
        private void BindEffect()
        {
            AssetMgr.LoadPrefab(effectName, LoadEffectCallback);
        }

        /// <summary>
        /// 释放特效
        /// </summary>
        private void ClearEffect()
        {
            int length = effects.Count;
            for (int i = 0; i < length; i++)
            {
                GbjPool.Instance.Add(effects[i]);
            }
            effects.Clear();
        }

        /// <summary>
        /// 设置效果绑定点
        /// </summary>
        private void SetBone()
        {
            bones.Clear();
            var childs = model.GetComponentsInChildren<Transform>(true);
            int length = childs.Length;
            for (int i = 0; i < length; i++)
            {
                var child = childs[i];
                if (child.name.Equals(effectBone))
                {
                    bones.Add(child);
                }
            }
        }
        #endregion

        /// <summary>
        /// 设置路径
        /// </summary>
        private void SetPath()
        {
            int length = path.Count;
            for (int i = 0; i < length; i++)
            {
                Vector3 point = path[i];
                path[i] = new Vector3(point.x, point.y + riseHeight, point.z);
            }

            path.Reverse();
            Vector3 start = new Vector3(oriPos.x, riseHeight, oriPos.z);
            path.Add(start);

            risePoint = start;

            path.Reverse();

            Vector3 end = endAnchor.pos;
            end.Set(end.x, end.y + riseHeight, end.z);
            path.Add(end);
        }

        /// <summary>
        /// 有高度路径移动
        /// </summary>
        private void MovePathHaveHeight()
        {
            var go = tran.gameObject;

            Hashtable riseArgs = new Hashtable();
            riseArgs.Add("position", risePoint);
            riseArgs.Add("time", riseTime);
            riseArgs.Add("easetype", iTween.EaseType.linear);
            iTween.MoveTo(go, riseArgs);

            float flyDelay = riseTime + riseDelay;
            Hashtable flyArgs = new Hashtable();
            flyArgs.Add("delay", flyDelay);
            flyArgs.Add("path", path.ToArray());
            flyArgs.Add("time", flyTime);
            flyArgs.Add("easetype", iTween.EaseType.linear);
            iTween.MoveTo(go, flyArgs);

            float rotDelay = flyDelay + flyTime;
            Vector3 eulur = new Vector3(0, endAnchor.eulurY, 0);
            Hashtable rotArgs = new Hashtable();
            rotArgs.Add("delay", rotDelay);
            rotArgs.Add("islocal", true);
            rotArgs.Add("rotation", eulur);
            rotArgs.Add("time", downDelay);
            rotArgs.Add("easetype", iTween.EaseType.linear);
            iTween.RotateTo(go, rotArgs);

            float downArgsDelay = rotDelay + downDelay + 0.25f;
            Hashtable downArgs = new Hashtable();
            downArgs.Add("delay", downArgsDelay);
            downArgs.Add("position", endAnchor.pos);
            downArgs.Add("time", downTime);
            downArgs.Add("easetype", iTween.EaseType.linear);
            downArgs.Add("oncomplete", "Complete");
            iTween.MoveTo(go, downArgs);
        }

        /// <summary>
        /// 无高度路径移动
        /// </summary>
        private void MovePathNoHeight()
        {
            Hashtable flyArgs = new Hashtable();
            flyArgs.Add("path", path.ToArray());
            flyArgs.Add("time", flyTime);
            flyArgs.Add("easetype", iTween.EaseType.linear);
            flyArgs.Add("oncomplete", "Complete");
            iTween.MoveTo(tran.gameObject, flyArgs);
        }

        /// <summary>
        /// 绑定平台
        /// </summary>
        private void BindModel()
        {
            tran.position = model.transform.position;
            tran.eulerAngles = model.transform.eulerAngles;
            model.transform.parent = tran;
            hero.ActionStatus.ignoreGravityGlobal = true;
            hero.UnitTrans.parent = tran;
        }

        /// <summary>
        /// 解绑平台
        /// </summary>
        private void DebindModel()
        {
            if (model == null) return;
            model.transform.parent = null;
            hero.UnitTrans.parent = null;
            hero.ActionStatus.ignoreGravityGlobal = false;
            tran.position = oriPos;
            tran.eulerAngles = Vector3.zero;
            NetMove.RequestChangePosDir(hero, hero.Position);
        }

        /// <summary>
        /// 检查所有的单位是否进入平台
        /// </summary>
        /// <returns></returns>
        private IEnumerator CheckRadius()
        {
            float dis = 0;
            while (true)
            {
                heroVec.Set(hero.Position.x, hero.Position.z);
                modelVec.Set(tran.position.x, tran.position.z);
                dis = Vector2.Distance(heroVec, modelVec);
                if (dis < radius)
                {
                    break;
                }
                else
                {
                    yield return 0;
                    continue;
                }
            }
            BindEffects();
            BindModel();
            if (riseHeight == 0)
            {
                MovePathNoHeight();
            }
            else
            {
                MovePathHaveHeight();
            }
        }

        private void Clear()
        {
            iTween.Stop(tran.gameObject);
            if (coro != null) MonoEvent.Stop(coro);
            coro = null;
        }

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            effectIndex = 0;
            model = ComponentBind.Get(modelKey);
            if (model == null)
            {
                LogError(string.Format("没有发现键值为:{0}的平台", modelKey));
                Complete();
                return;
            }
            hero = InputVectorMove.instance.MoveUnit;
            if (hero == null)
            {
                LogError("主角不存在");
                Complete();
            }
            else if (hero.Dead || hero.DestroyState)
            {
                LogError("主角已死亡");
                Complete();
            }
            else
            {
                SetBone();
                coro = MonoEvent.Start(CheckRadius());
            }
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            ClearEffect();
            DebindModel();
            coro = null;
        }




        #endregion

        #region 公开方法
        public override void Initialize()
        {
            base.Initialize();
            tran = FindOrCreate(name);
            tran.position = oriPos;
            SetPath();
        }

        public override void Preload()
        {
            PreloadMgr.prefab.Add(effectName);
        }

        public override void Stop()
        {
            base.Stop();
            Clear();
        }

        public override void Dispose()
        {
            base.Dispose();
            Clear();
        }
        #endregion

        #region 编辑器字段/属性/方法
#if UNITY_EDITOR

        private Vector3 euler = new Vector3(90, 0, 0);


        protected override void EditCompleteDynamicCustom()
        {
            iTween.Stop(tran.gameObject);
        }

        /// <summary>
        /// 在场景中显示Anchor
        /// </summary>
        private void EditShowAnchor(Object o, Anchor anchor, string des)
        {
            Vector3 rot = new Vector3(0, anchor.eulurY, 0);
            Handles.ArrowHandleCap(o.GetInstanceID(), anchor.pos, Quaternion.Euler(rot), 4f, EventType.Repaint);
            Handles.Label(anchor.pos, des);
        }


        /// <summary>
        /// 通过平台模型设置位置和角度
        /// </summary>
        /// <param name="anchor"></param>
        private void EditGetAnchorFromModel(Object o, Anchor anchor)
        {
            var go = ComBindTool.GetGo<ComponentBind>(modelKey);
            if (go == null)
            {
                UIEditTip.Log("没有发现键值为:{0}的物体", modelKey);
            }
            else
            {
                EditUtil.RegisterUndo("GetAnchor", o);
                anchor.pos = go.transform.position;
                anchor.eulurY = go.transform.eulerAngles.y;
            }
        }

        /// <summary>
        /// 将角度和位置设置到平台
        /// </summary>
        /// <param name="anchor"></param>
        private void EditSetModelByAnchor(Anchor anchor)
        {
            var go = ComBindTool.GetGo<ComponentBind>(modelKey);
            if (go == null)
            {
                UIEditTip.Error("没有发现键值为:{0}的物体", modelKey);
            }
            else
            {
                EditUtil.RegisterUndo("GetAnchor", go);
                go.transform.position = anchor.pos;
                go.transform.eulerAngles = new Vector3(0, anchor.eulurY, 0);
            }
        }

        private void EditDrawAnchor(Object o, Anchor anchor, string title)
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.LabelField(title);
            anchor.pos = EditorGUILayout.Vector3Field("位置", anchor.pos);
            anchor.eulurY = EditorGUILayout.FloatField("角度", anchor.eulurY);
            if (GUILayout.Button("拾取平台位置和角度")) EditGetAnchorFromModel(o, anchor);
            else if (GUILayout.Button("设置平台位置和角度")) EditSetModelByAnchor(anchor);
            EditorGUILayout.EndVertical();
        }

        private void EditDrawKey(Object o)
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.TextField("平台键值:", ref modelKey, o);
            if (GUILayout.Button("定位")) ComBindTool.Ping<ComponentBind>(modelKey);
            EditorGUILayout.EndHorizontal();
            if (string.IsNullOrEmpty(modelKey))
            {
                UIEditLayout.HelpError("键值不能为空");
            }
            else
            {
                EditDrawAnchor(o, begAnchor, "平台起始位置和角度");
            }
            EditorGUILayout.EndVertical();
        }
        private void EditDrawEffect(Object o)
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.TextField("特效骨骼名称:", ref effectBone, o);

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("绑定特效名称/可选:");
            UIEditLayout.TextField("", ref effectName, o);
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.EndVertical();
        }

        private void EditDrawRise(Object o)
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.FloatField("平台半径/米:", ref radius, o);
            UIEditLayout.FloatField("升起高度/米:", ref riseHeight, o);
            if (riseHeight == 0)
            {
                UIEditLayout.HelpWaring("高度为0时不应用上升");
            }
            else
            {
                UIEditLayout.FloatField("升起时间/秒:", ref riseTime, o);
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("升起后停顿时间/秒:");
                UIEditLayout.FloatField("", ref riseDelay, o);
                EditorGUILayout.EndHorizontal();
            }
            EditorGUILayout.EndVertical();
        }

        private void EditDrawDown(Object o)
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            if (riseHeight == 0)
            {
                UIEditLayout.HelpWaring("高度为0时不应用下落");
            }
            else
            {
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("下降前停顿时间/秒:");
                UIEditLayout.FloatField("", ref downDelay, o);
                EditorGUILayout.EndHorizontal();
                UIEditLayout.FloatField("下落时间/秒:", ref downTime, o);
            }
            if (!string.IsNullOrEmpty(modelKey)) EditDrawAnchor(o, endAnchor, "平台结束位置和角度");
            EditorGUILayout.EndVertical();
        }

        protected override void EditDrawCtrlUI(Object o)
        {
            UIDrawTool.Buttons(o, "空中路径点列表", "路径点", path.Count, ref placeIndex);
        }

        public override void EditCreate()
        {
            oriPos = SceneViewUtil.GetCenterPosGround();
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 3";
        }

        public override void EditDrawSceneGui(Object o)
        {
            base.EditDrawSceneGui(o);
            UIHandleTool.FreeMove(o, ref oriPos, Handles.RectangleHandleCap);
            Handles.CircleHandleCap(o.GetInstanceID(), oriPos, Quaternion.Euler(euler), radius, EventType.Repaint);
            string tip = "空中路径点";
            UIVectorUtil.Add(o, path, tip, e.shift);
            UIVectorUtil.Set(o, path, placeIndex, tip, e.control, 0);
            UIVectorUtil.Set(o, ref oriPos, tip, e.control, 2);
            UIVectorUtil.Draw(o, path, Color.red, tip, placeIndex, true);
            EditShowAnchor(o, begAnchor, "起始点");
            EditShowAnchor(o, endAnchor, "结束点");
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);


            EditDrawKey(o);

            EditDrawEffect(o);

            EditDrawRise(o);

            UIEditLayout.Vector3Field("飞行初始位置:", ref oriPos, o);
            UIEditLayout.FloatField("飞行时间/秒:", ref flyTime, o);

            EditDrawDown(o);

            UIEditLayout.HelpInfo("Ctrl+中键顶啊及,可设置初始位置");
            UIEditLayout.HelpInfo("Ctrl+左键点击,可设置目标位置");
            UIEditLayout.HelpInfo("Shift+左键点击,可添加空中路径点");
            UIVectorUtil.Draw(o, path, "teleportPath", "空中路径点列表");
        }
#endif
        #endregion
    }
}