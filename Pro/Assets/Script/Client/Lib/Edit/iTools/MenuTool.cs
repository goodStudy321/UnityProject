#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Hello.Game
{
    /// <summary>
    /// 编辑器菜单工具
    /// </summary>
    public static class MenuTool
    {
        /// <summary>
        /// 开发者前缀
        /// </summary>
        public const string Developer = "Developer/";

        /// <summary>
        /// Assets 菜单下开发者前缀
        /// </summary>
        public const string ADeveloper = "Assets/Developer/";

        /// <summary>
        /// 菜单 Hello 前缀
        /// </summary>
        public const string Hello = "Developer/Hello/";

        /// <summary>
        /// Assets 菜单 Hello 前缀
        /// </summary>
        public const string AHello = "Assets/Developer/Hello/";

        /// <summary>
        /// 美术菜单前缀
        /// </summary>
        public const string Art = "Developer/Art/";

        /// <summary>
        /// Assets 美术菜单前缀
        /// </summary>
        public const string AArt = "Assets/Developer/Art/";

        /// <summary>
        /// 策划菜单前缀
        /// </summary>
        public const string Plan = "Developer/Plan/";

        /// <summary>
        /// Assets 策划菜单前缀
        /// </summary>
        public const string APlan = "Developer/APlan/";

        /// <summary>
        /// 最低优先级
        /// </summary>
        public const int Lowest = -10000;

        /// <summary>
        /// 最高优先级
        /// </summary>
        public const int Highest = 10000;

#if HELLO_MENU_LOWEST_PRI
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

    }
}


#endif
