using Phantom;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.10.27
    /// BG:组件绑定脚本,通过key可以快速查找到指定的组件或者游戏对象
    /// </summary>
    [AddComponentMenu("Loong/组件绑定")]
    public class ComponentBind : MonoBehaviour
#if UNITY_EDITOR
        , IComBind
#endif
    {
        #region 字段

        /// <summary>
        /// 唯一的键值
        /// </summary>
        [SerializeField]
        [HideInInspector]
        private string key;

        /// <summary>
        /// true:开始隐藏
        /// </summary>
        public bool hidden;

        /// <summary>
        /// 任务ID
        /// </summary>
        public int mssnID;

        /// <summary>
        /// 任务ID大于时激活状态 0:关闭,1:激活
        /// </summary>
        public int mssnActive = 0;



        /// <summary>
        /// 组件字典
        /// </summary>
        private static Dictionary<string, GameObject> dic = new Dictionary<string, GameObject>();

        #endregion

        #region 属性
        public string Key
        {
            get { return key; }
        }
        #endregion

        #region 私有方法
        private void Awake()
        {
            if (string.IsNullOrEmpty(key)) return;
            if (dic.ContainsKey(key))
            {
                /*var tip = string.Format("already owned key:{0},one:{1},another:{2} ", key, dic[key].name, name);
                iTrace.Error("Loong", tip);*/
                Destroy(this);
            }
            else
            {
                dic.Add(key, gameObject);
            }
            if (hidden)
            {
                gameObject.SetActive(false);
            }
            if (mssnID > 0)
            {
                EventMgr.Add("MssnChange", MssnChange);
                MssnChange(UserBridge.Instance.mainMissionId);
            }

        }

        private void OnDestroy()
        {
            if (string.IsNullOrEmpty(key)) return;
            if (dic.ContainsKey(key)) dic.Remove(key);
            if (mssnID > 0) EventMgr.Remove("MssnChange", MssnChange);
        }

        private void MssnChange(params object[] args)
        {
            if (args == null || args.Length < 1) return;
            var id = System.Convert.ToInt32(args[0]);
            if (id > mssnID)
            {
                var at = (mssnActive > 0);
                gameObject.SetActive(at);
            }
        }

        /// <summary>
        /// 检查有效性 返回真有效 反之无效
        /// </summary>
        private static bool Check(string key)
        {
            if (string.IsNullOrEmpty(key)) return false;
            if (!dic.ContainsKey(key)) return false;
            return true;
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 检查键是否存在
        /// </summary>
        public static bool Exist(string key)
        {
            return dic.ContainsKey(key);
        }

        /// <summary>
        /// 在一个物体上添加一个指定的键 注意使用Add之后,不要直接直接Get,而应该使用返回值进行操作
        /// </summary>
        public static ComponentBind Add(string key, GameObject target)
        {
            if (string.IsNullOrEmpty(key)) return null;
            else if (target == null) return null;
            else if (dic.ContainsKey(key))
            {
                Debug.LogErrorFormat("Loong, 已有键为:{ 0}的ComponentBind组件,物体: { 1}", key, dic[key].name); return null;
            }
            else if (target.GetComponent<ComponentBind>() != null)
            {
                Debug.LogErrorFormat("Loong,物体{0}上已有ComponentBind组件", target.name); return null;
            }
            ComponentBind bind = target.AddComponent<ComponentBind>();
            dic.Add(key, target);
            bind.key = key;
            return bind;
        }

        /// <summary>
        /// 移除指定键
        /// </summary>
        public static bool Remove(string key)
        {
            if (!Check(key)) return false;
            ComponentBind bind = dic[key].GetComponent<ComponentBind>();
            if (bind != null) Destroy(bind);
            dic.Remove(key);
            return true;
        }

        /// <summary>
        /// 获取指定键值物体上的T类型组件
        /// </summary>
        public static T Get<T>(string key) where T : Component
        {
            if (!Check(key)) return null;
            T t = dic[key].GetComponent<T>();
            if (t == null) return null;
            return t;
        }

        /// <summary>
        /// 获取指定键值物体
        /// </summary>
        public static GameObject Get(string key)
        {
            if (!Check(key)) return null;
            return dic[key];
        }

        #region 编辑器字段/属性/脚本
#if UNITY_EDITOR

        public void OnInspGUI()
        {
            EditorGUILayout.BeginVertical("groupBox");
            if (gameObject.activeSelf)
            {
                key = EditorGUILayout.TextField("键值:", key);
                if (string.IsNullOrEmpty(key))
                {
                    EditorGUILayout.HelpBox("键值不能为空", MessageType.Error);
                }
                else
                {
                    EditorGUILayout.HelpBox("确保键值是唯一的", MessageType.Info);
                }

                hidden = EditorGUILayout.Toggle("开始隐藏:", hidden);
            }
            else
            {
                EditorGUILayout.HelpBox("物体状态不需隐藏", MessageType.Error);
            }

            EditorGUILayout.EndVertical();

            EditorGUILayout.BeginVertical("groupBox");
            mssnID = EditorGUILayout.IntField("任务ID:", mssnID);
            mssnActive = EditorGUILayout.Popup("激活状态:", mssnActive, DefineTool.activeArr);
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
        #endregion
    }
}