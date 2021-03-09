/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.5.29 20:17:52
 ============================================================================*/

using System;

namespace Loong.Game
{
    /// <summary>
    /// 压缩基类
    /// </summary>
    public abstract class CompBase
    {
        #region 字段
        private float pro = 0;
        private string src = null;
        private string dest = null;
        #endregion

        #region 属性
        public float Pro
        {
            get { return pro; }
            set { pro = value; }
        }

        /// <summary>
        /// 源目录或者文件路径
        /// </summary>
        public string Src
        {
            get { return src; }
            set { src = value; }
        }


        /// <summary>
        /// 目标路径
        /// </summary>
        public string Dest
        {
            get { return dest; }
            set { dest = value; }
        }

        #endregion

        #region 委托事件
        /// <summary>
        /// 进度
        /// </summary>
        public event Action<float> progress;

        /// <summary>
        /// 结束事件,true:成功,false失败
        /// </summary>
        public event Action<CompBase, bool> complete;
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected void SetPro(float val)
        {
            pro = val;
            if (progress != null) progress(val);
        }

        protected void Complete(bool result)
        {
            if (complete != null)
            {
                complete(this, result);
            }
        }
        #endregion

        #region 公开方法
        /// <summary>
        /// 通过线程池调用
        /// </summary>
        /// <param name="obj"></param>
        public void Execute(object obj)
        {
            Execute();
        }

        /// <summary>
        /// 执行
        /// </summary>
        public abstract bool Execute();
        #endregion

    }
}