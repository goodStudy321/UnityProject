using System;
using System.IO;
using System.Text;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Hello.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.5.10
    /// BG:通用日志类型
    /// </summary>
    public class CommonLog : LogBase
    {
        #region 字段
#if GAME_DEBUG || CS_HOTFIX_ENABLE
        /// <summary>
        /// 当前索引
        /// </summary>
        private int index = 0;

        /// <summary>
        /// 总数量
        /// </summary>
        private int total = 0;


        /// <summary>
        /// 滚动视图位置
        /// </summary>
        private Vector2 logPos = Vector2.zero;

        /// <summary>
        /// 信息列表
        /// </summary>
        private List<string> msgs = new List<string>();


        /// <summary>
        /// 自动排版选项
        /// </summary>
        private GUILayoutOption[] options = new GUILayoutOption[1];

        /// <summary>
        /// 文本样式
        /// </summary>
        private GUIStyle textStyle = new GUIStyle() { wordWrap = true, alignment = TextAnchor.MiddleLeft };

#endif
        /// <summary>
        /// 格式化信息
        /// </summary>
        private StringBuilder temp = new StringBuilder();
        #endregion

        #region 属性
#if GAME_DEBUG || CS_HOTFIX_ENABLE
        /// <summary>
        /// 信息文本颜色
        /// </summary>
        public Color TextColor
        {
            get { return textStyle.normal.textColor; }
            set { textStyle.normal.textColor = value; }
        }
#endif
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion
        public CommonLog(string path)
        {
            FilePath = path;
            Init();
        }
        #region 私有方法
#if GAME_DEBUG || CS_HOTFIX_ENABLE
        private void PrevPage()
        {
            --index; index = Mathf.Clamp(index, 0, total);
        }

        private void NextPage()
        {
            ++index; index = Mathf.Clamp(index, 0, total);
        }

        private void FirstPage()
        {
            index = 0;
        }

        private void LastPage()
        {
            index = total;
        }
#endif
        /// <summary>
        /// 格式化Log信息
        /// </summary>
        /// <param name="msg"></param>
        /// <param name="stack"></param>
        /// <param name="type"></param>
        /// <returns></returns>
        private string Format(string msg, string stack, LogType type)
        {
            if (this.temp.Length > 0) this.temp.Remove(0, this.temp.Length);
            this.temp.Append("时间：").Append(DateTime.Now.ToString("HH:mm:ss fff")).Append(",\t");
            this.temp.Append("类型：").Append(type.ToString()).Append(",\t");
            //自带换行符
            this.temp.Append("输出：").Append(msg).Append(",\n");
            if (OutTrack) this.temp.Append("堆栈：").Append(stack);
            this.temp.Append("\n\n");
            return this.temp.ToString();
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Init()
        {
#if GAME_DEBUG || CS_HOTFIX_ENABLE
            textStyle.fontSize = (int)((Screen.height / 600f) * 20);
            float btnHeight = Screen.height * 0.08f;
            options[0] = GUILayout.Height(btnHeight);
#endif
        }


#if GAME_DEBUG || CS_HOTFIX_ENABLE
        public override void OnGUI()
        {
            GUILayout.BeginHorizontal();
            GUILayout.TextField(FilePath, options);
            GUILayout.Label(index.ToString(), textStyle, options);
            GUILayout.Label("/", textStyle, options);
            GUILayout.Label(total.ToString(), textStyle, options);
            if (GUILayout.Button("上一页", options)) PrevPage();
            else if (GUILayout.Button("下一页", options)) NextPage();
            else if (GUILayout.Button("首页", options)) FirstPage();
            else if (GUILayout.Button("末页", options)) LastPage();
            else if (GUILayout.Button("清理", options)) Clear();
            else if (GUILayout.Button("关闭", options)) iTrace.Enable = false;
            else if (GUILayout.Button(Pauseing ? "恢复" : "暂停", options)) Pauseing = !Pauseing;
            GUILayout.EndHorizontal();
            logPos = GUILayout.BeginScrollView(logPos);
            for (int i = 0; i < 10; i++)
            {
                int idx = index * 10 + i;
                if (idx < msgs.Count) GUILayout.Label(msgs[idx], textStyle);
            }
            GUILayout.EndScrollView();
        }

        public override void Update()
        {
            if (msgs.Count > 10) total = Mathf.FloorToInt(msgs.Count * 0.1f);
        }

        public override void Open()
        {
            Update(); index = total;
        }

        public override void Close()
        {

        }

#endif
        public override void Clear()
        {
#if GAME_DEBUG || CS_HOTFIX_ENABLE
            msgs.Clear();
            index = 0;
            total = 0;
#endif
        }
        public override void Write(string msg, string stack, LogType type)
        {
#if GAME_DEBUG || CS_HOTFIX_ENABLE
            if (Pauseing) return;
            if (msgs.Count == 150) msgs.Clear();
#endif
            string str = Format(msg, stack, type);
#if GAME_DEBUG || CS_HOTFIX_ENABLE
            msgs.Add(str);
            Update();
#endif
            if (!CanWrite) return;
            using (StreamWriter writer = new StreamWriter(FilePath, true, Encoding.UTF8))
            {
                writer.WriteLine(str);
            }
        }

        public override void Dispose()
        {
            base.Dispose();
        }
        #endregion
    }
}