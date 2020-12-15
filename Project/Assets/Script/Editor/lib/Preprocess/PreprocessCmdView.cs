using Hello.Game;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace Hello.Edit
{
    public class PreprocessCmdView : EditViewBase
    {
        [SerializeField]
        [HideInInspector]
        private BuildTargetGroup targetGroup;

        private List<string> userSymbols = new List<string>();

        [SerializeField]
        [HideInInspector]
        private List<string> comSymbols = new List<string>
        {
            "GAME_GUIDE",
            "GAME_DEBUG",
            "HELLO_AB_LSNR",
            "HELLO_USE_ZIP",
            "HELLO_TEST_UPG",
            "HELLO_SCRIPT_KEY",
            "HELLO_LOG_DISABLE",
            "HELLO_UITIP_DISABLE"
        };

        [SerializeField]
        [HideInInspector]
        private string inputUseSymbol = string.Empty;

        [SerializeField]
        [HideInInspector]
        private string inputComSymbol = string.Empty;

        private Vector2 targetPos = Vector2.zero;
        private Vector2 commenPos = Vector2.zero;
        private GUILayoutOption[] symbolOptions = new GUILayoutOption[] { GUILayout.Height(30) };

        /// <summary>
        /// 绘制
        /// </summary>
        protected override void OnGUICustom()
        {
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space();
            EditorGUILayout.BeginVertical();

            EditorGUILayout.Space();
            EditorGUILayout.Space();

            SetProperty();

            SetCmdSymbol();

            EditorGUILayout.EndVertical();
            EditorGUILayout.Space();
            EditorGUILayout.Space();

            EditorGUILayout.EndHorizontal();
        }


        private void SetProperty()
        {
            if (!UIEditTool.DrawHeader("基本属性", "CmdViewProperty", StyleTool.Host)) return;
            EditorGUI.BeginChangeCheck();
            BuildTargetGroup newValue = (BuildTargetGroup)EditorGUILayout.EnumPopup("目标平台:", targetGroup);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("EnumPopupValue", this);
            targetGroup = newValue;
            SetUseSymbols();
        }

        private void SetCmdSymbol()
        {
            if (!UIEditTool.DrawHeader("设置指令", "SetCmdSymbol", StyleTool.Host)) return;
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space();

            ShowAddedSymbols();
            EditorGUILayout.Space();


            ShowCommenSymbols();
            EditorGUILayout.EndHorizontal();
        }

        /// <summary>
        /// 显示已经添加的指令
        /// </summary>
        private void ShowAddedSymbols()
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.LabelField("已添加指令列表:", symbolOptions);

            EditorGUILayout.Space();
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("输入指令：", GUILayout.Width(60));

            inputUseSymbol = EditorGUILayout.TextField(inputUseSymbol, symbolOptions);
            if (GUILayout.Button("", StyleTool.Plus))
            {
                Add(inputUseSymbol, userSymbols);
            }
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space();

            targetPos = EditorGUILayout.BeginScrollView(targetPos, GUILayout.MaxHeight(Win.position.height - 200));
            if (userSymbols.Count != 0)
            {
                for (int i = 0; i < userSymbols.Count; i++)
                {
                    if (string.IsNullOrEmpty(userSymbols[i]))
                        continue;
                    EditorGUILayout.BeginHorizontal(StyleTool.Box);
                    EditorGUILayout.LabelField(userSymbols[i], symbolOptions);
                    if (GUILayout.Button("", StyleTool.Minus))
                    { Remove(userSymbols, i); break; }
                    EditorGUILayout.EndHorizontal();
                }
            }
            EditorGUILayout.EndScrollView();
            if (GUILayout.Button("应用指令", symbolOptions))
            {
                Apply();
            }
            EditorGUILayout.EndVertical();
        }

        /// <summary>
        /// 显示用户常用的指令
        /// </summary>
        private void ShowCommenSymbols()
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.LabelField("常用指令列表:", symbolOptions);
            EditorGUILayout.Space();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("输入指令:", GUILayout.Width(60));
            inputComSymbol = EditorGUILayout.TextField(inputComSymbol, symbolOptions);
            if (GUILayout.Button("", StyleTool.Plus))
            {
                Add(inputComSymbol, comSymbols);
            }
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space();

            commenPos = EditorGUILayout.BeginScrollView(commenPos, GUILayout.MaxHeight(Win.position.height - 200));

            int comLength = comSymbols.Count;
            for (int i = 0; i < comLength; i++)
            {
                EditorGUILayout.BeginHorizontal(StyleTool.Box);
                EditorGUILayout.LabelField(comSymbols[i], symbolOptions);
                if (GUILayout.Button("", StyleTool.Plus))
                    Add(comSymbols[i], userSymbols);
                else if (GUILayout.Button("", StyleTool.Minus))
                {
                    Remove(comSymbols, i); break;
                }
                EditorGUILayout.EndHorizontal();
            }
            EditorGUILayout.EndScrollView();

            EditorGUILayout.EndVertical();
        }

        private void SetUseSymbols()
        {
            userSymbols.Clear();
            string strs = PlayerSettings.GetScriptingDefineSymbolsForGroup(targetGroup);
            string[] symbols = strs.Split(';');
            int length = symbols.Length;
            for (int i = 0; i < length; i++)
            {
                string str = symbols[i];
                if (string.IsNullOrEmpty(str)) continue;
                userSymbols.Add(str);
            }
        }

        private void SetTargetGroup()
        {
            targetGroup = BuildSettingsUtil.GetGroup();
        }

        private void Apply()
        {
            PreprocessCmdUtil.Apply(userSymbols, targetGroup);
        }

        private void Add(string symbol, List<string> symbols)
        {
            if (string.IsNullOrEmpty(symbol))
            {
                this.ShowTip("顶农个肺~空的"); return;
            }
            if (symbols.Contains(symbol))
            {
                this.ShowTip("顶侬个肺~已经有了"); return;
            }
            this.ShowTip(string.Format("添加指令{0}成功", symbol));
            EditUtil.RegisterUndo("Add", this);
            symbols.Add(symbol);
            AssetDatabase.SaveAssets();
        }

        private void Remove(List<string> symbols, int i)
        {
            EditUtil.RegisterUndo("Remove", this);
            symbols.RemoveAt(i);
            Event.current.Use();
            AssetDatabase.SaveAssets();
        }

        /// <summary>
        /// 初始化
        /// </summary>
        public override void Initialize()
        {
            SetTargetGroup();
            SetUseSymbols();
        }
    }
}

