using System;
using System.IO;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Hello.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.5.10
    /// BG:日志输出基类
    /// </summary>
    public abstract class LogBase : IDisposable
    {
        #region 字段
        private bool canWrite = false;

        private bool outTrack = true;
#if GAME_DEBUG || CS_HOTFIX_ENABLE

        private bool pauseing = false;
#endif

        private string filePath = "";
        #endregion

        #region 属性
        /// <summary>
        /// true:可写入文件
        /// </summary>
        public bool CanWrite
        {
            get { return canWrite; }
            set { canWrite = value; }
        }

#if GAME_DEBUG || CS_HOTFIX_ENABLE
        /// <summary>
        /// true:暂停中
        /// </summary>
        public bool Pauseing
        {
            get { return pauseing; }
            set { pauseing = value; }
        }

#endif
        /// <summary>
        /// true:输出堆栈
        /// </summary>
        public bool OutTrack
        {
            get { return outTrack; }
            set { outTrack = value; }
        }
        /// <summary>
        /// 日志文件路径
        /// </summary>
        public string FilePath
        {
            get { return filePath; }
            set { filePath = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public LogBase()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 初始化
        /// </summary>
        public abstract void Init();

#if GAME_DEBUG || CS_HOTFIX_ENABLE
        /// <summary>
        /// 绘制UI
        /// </summary>
        public abstract void OnGUI();

        /// <summary>
        /// 更新
        /// </summary>
        public abstract void Update();

        /// <summary>
        /// 打开
        /// </summary>
        public abstract void Open();

        /// <summary>
        /// 关闭
        /// </summary>
        public abstract void Close();



#endif
        /// <summary>
        /// 清除
        /// </summary>
        public abstract void Clear();
        /// <summary>
        /// 写入
        /// </summary>
        /// <param name="msg">信息</param>
        /// <param name="stack">堆栈</param>
        /// <param name="type">类型</param>
        public abstract void Write(string msg, string stack, LogType type);

        /// <summary>
        /// 清理日志文件
        /// </summary>
        public void ClearFile()
        {
            FileTool.SafeDelete(FilePath);
        }

        /// <summary>
        /// 释放
        /// </summary>
        public virtual void Dispose()
        {

            Clear();
            ClearFile();
            FilePath = "";
        }
        #endregion
    }
}