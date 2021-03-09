#if UNITY_EDITOR
using System;
using System.Text;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2013-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        2e0dd74f-c7df-4197-b7ec-245ff46ba62b
    */

    /// <summary>
    /// AU:Loong
    /// TM:2013/5/13 10:38:55
    /// BG:编辑器菜单工具
    /// </summary>
    public static class MenuTool
    {
        #region 字段
        /// <summary>
        /// 开发者前缀
        /// </summary>
        public const string Developer = "Developer/";

        /// <summary>
        /// 资源菜单下开发者前缀
        /// </summary>
        public const string ADeveloper = "Assets/Developer";

        /// <summary>
        /// 菜单Loong前缀
        /// </summary>
        public const string Loong = "Developer/Loong/";

        /// <summary>
        /// 资源下菜单Loong前缀
        /// </summary>
        public const string ALoong = "Assets/Developer/Loong/";

        /// <summary>
        /// 游戏对象下菜单前缀
        /// </summary>
        public const string GameObject = "GameObject/";

        /// <summary>
        /// 游戏对象下菜单Loong前缀
        /// </summary>
        public const string GLoong = "GameObject/Loong/";

        /// <summary>
        /// 美术菜单前缀
        /// </summary>
        public const string Art = "Developer/美术/";

        /// <summary>
        /// 资源下美术菜单前缀
        /// </summary>
        public const string AArt = "Assets/Developer/美术/";

        /// <summary>
        /// 策划菜单前缀
        /// </summary>
        public const string Plan = "Developer/策划/";

        /// <summary>
        /// 资源下策划菜单前缀
        /// </summary>
        public const string APlan = "Assets/Developer/策划/";

        /// <summary>
        /// 测试菜单前缀
        /// </summary>
        public const string Test = "Developer/Loong/测试/";

        /// <summary>
        /// 资源下测试菜单前缀
        /// </summary>
        public const string ATest = "Assets/Developer/Loong/测试/";

        /// <summary>
        /// 最低优先级
        /// </summary>
        public const int Lowest = -10000;

        /// <summary>
        /// 最高优先级
        /// </summary>
        public const int Highest = 10000;
#if LOONG_MENU_LOWEST_PRI

        public const int BasePri = Highest;
#else
        public const int BasePri = Lowest;
#endif
        /// <summary>
        /// 测试相关优先级
        /// </summary>
        public const int TestPri = BasePri - 400;

        /// <summary>
        /// 普通相关优先级
        /// </summary>
        public const int NormalPri = BasePri - 200;

        /// <summary>
        /// 资源相关优先级
        /// </summary>
        public const int AssetPri = BasePri;

        /// <summary>
        /// 流程相关优先级
        /// </summary>
        public const int ProcessPri = BasePri + 200;

        /// <summary>
        /// 场景相关优先级
        /// </summary>
        public const int ScenePri = BasePri + 400;

        /// <summary>
        /// 策划优先级
        /// </summary>
        public const int PlanPri = BasePri + 600;

        /// <summary>
        /// 美术优先级
        /// </summary>
        public const int ArtPri = BasePri + 800;
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #endregion
    }
}
#endif