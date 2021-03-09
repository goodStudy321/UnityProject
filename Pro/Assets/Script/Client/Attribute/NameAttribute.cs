using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.2.15
    /// BG:名称属性
    /// </summary>
    [AttributeUsage(AttributeTargets.Class, AllowMultiple = false, Inherited = false)]
    public class NameAttribute : Attribute
    {
        #region 字段
        private string name = "";
        #endregion

        #region 属性
        public string Name
        {
            get { return name; }
        }
        #endregion

        #region 构造方法
        public NameAttribute(string name)
        {
            this.name = name;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #endregion
    }
}