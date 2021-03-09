using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.4.27
    /// BG:资源处理器视图
    /// </summary>
    public class AssetProcessorView : EditViewBase
    {
        #region 字段
        [SerializeField]
        [HideInInspector]
        private bool use = false;

        [SerializeField]
        [HideInInspector]
        private ModelProcessorData modelData = new ModelProcessorData();

        [SerializeField]
        [HideInInspector]
        private AudioProcessorData audioData = new AudioProcessorData();

        [SerializeField]
        [HideInInspector]
        private TextureProcessorData textureData = new TextureProcessorData();

        [SerializeField]
        [HideInInspector]
        private AssetProcessorDictionary dic = new AssetProcessorDictionary();

        #endregion

        #region 属性
        /// <summary>
        /// true:启用嗅探总开关
        /// </summary>
        public bool Use { get { return use; } }

        /// <summary>
        /// 模型处理数据
        /// </summary>
        public ModelProcessorData ModelData { get { return modelData; } }

        /// <summary>
        /// 音效处理数据
        /// </summary>
        public AudioProcessorData AudioData { get { return audioData; } }

        /// <summary>
        /// 图片处理数据
        /// </summary>
        public TextureProcessorData TextureData { get { return textureData; } }

        /// <summary>
        /// 后缀序列化字典
        /// </summary>
        public AssetProcessorDictionary Dic { get { return dic; } }
        #endregion

        #region 私有方法


        private void DrawRule()
        {
            if (!UIEditTool.DrawHeader("资源处理规则", "snifferRule", StyleTool.Host)) return;
            UIEditLayout.HelpWaring("1,对音频,图片,模型的导入设置,根据实际需求进行设置,资源处理选项对其有效");
            UIEditLayout.HelpWaring(string.Format("2:以下所有的资源处理规则只对{0}目录下的文件有效!", EditSceneView.prefix));
            UIEditLayout.HelpWaring("3:文件导入时,会自动设置资源包名称和后缀");
            UIEditLayout.HelpWaring("4:文件导入时,会自动分类放入相应的文件夹");
            UIEditLayout.HelpWaring("5:文件导入时,发现已经存在同名的文件,会红字提示");
            UIEditLayout.HelpWaring("6:文件删除时,会自动删除对应的资源包名称");
            UIEditLayout.HelpWaring(string.Format("7:文件移动时,如果移动到{0}目录之外,自动清除对应资源包名称", EditSceneView.prefix));
            UIEditLayout.HelpWaring(string.Format("8:文件移动时,如果自{0}目录之外移动到内,自动重新设置资源包名称", EditSceneView.prefix));

            EditorGUILayout.BeginHorizontal(StyleTool.Group);
            UIEditLayout.Toggle("总开关", ref use, this);
            EditorGUILayout.EndVertical();

        }

        private void DrawDic()
        {
            if (!UIEditTool.DrawHeader("根据后缀确定资源嗅探选项", "suffixSnif", StyleTool.Host)) return;
            if (dic.ks.Count == 0)
            {
                EditorGUILayout.LabelField("后缀字典中没有没有内容"); return;
            }
            int row = 1;
            int index = 0;
            if (dic.ks.Count > 3) row = Mathf.CeilToInt(dic.ks.Count / 3f);
            for (int i = 0; i < row; i++)
            {
                EditorGUILayout.BeginHorizontal();
                for (int j = 0; j < 3; j++)
                {
                    if (index >= dic.ks.Count) break;
                    EditorGUILayout.BeginHorizontal(StyleTool.Group, GUILayout.Width(100));
                    EditorGUI.BeginChangeCheck();
                    bool newValue = EditorGUILayout.Toggle(dic.ks[index], dic.vs[index]);
                    if (EditorGUI.EndChangeCheck())
                    {
                        EditUtil.RegisterUndo("togValue", this);
                        dic.vs[index] = newValue;
                        dic[dic.ks[index]] = newValue;
                    }
                    EditorGUILayout.EndHorizontal();
                    index++;
                }
                EditorGUILayout.EndHorizontal();
            }
        }
        #endregion
        /// <summary>
        /// 绘制
        /// </summary>
        protected override void OnGUICustom()
        {
            DrawRule();
            EditorGUILayout.Space();
            modelData.OnGUI(this);
            EditorGUILayout.Space();
            audioData.OnGUI(this);
            EditorGUILayout.Space();
            textureData.OnGUI(this);
            EditorGUILayout.Space();
            DrawDic();
        }
        #region 保护方法

        #endregion

        #region 公开方法

        #endregion
    }
}
