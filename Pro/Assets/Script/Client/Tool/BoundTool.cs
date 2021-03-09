using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.05.21
    /// BG:包围盒工具
    /// </summary>
    public static class BoundTool
    {
        #region 字段

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

        /// <summary>
        /// 获取游戏对象的高度;
        /// 查找对象上是否有碰撞,如果有返回碰撞盒高度,反之返回渲染组件高度
        /// </summary>
        /// <param name="target">游戏物体</param>
        /// <returns></returns>
        public static float MaxHeight(GameObject target)
        {
            if (target == null) return 0;
            Collider col = target.GetComponent<Collider>();
            if (col == null)
            {
                Renderer renderer = Max<Renderer>(target);
                if (renderer == null) return 0;
                else return renderer.bounds.size.y;
            }
            else
            {
                CapsuleCollider cpc = col as CapsuleCollider;
                if (cpc != null)
                    return cpc.height * target.transform.localScale.y;
                return col.bounds.size.y;
            }
        }

        /// <summary>
        /// 获取游戏对象的高度;
        /// 查找对象上是否有碰撞,如果有返回碰撞盒高度,反之返回渲染组件高度
        /// </summary>
        /// <param name="target"></param>
        /// <returns></returns>
        public static float MaxHeight(Transform target)
        {
            if (target == null) return 0;
            return MaxHeight(target.gameObject);
        }

        /// <summary>
        /// 获取物体及子物体上渲染组件包围盒最大的一个
        /// </summary>
        /// <typeparam name="T">获取类型</typeparam>
        /// <param name="target">目标物体</param>
        /// <returns></returns>
        public static T Max<T>(GameObject target) where T : Renderer
        {
            if (target == null) return null;
            T[] arr = target.GetComponentsInChildren<T>(true);
            if (arr == null || arr.Length == 0) return null;
            Vector3 size = Vector3.zero;
            float temp = 0;
            float maxValue = 0;
            T result = null;
            int length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                size = arr[i].bounds.size;
                temp = Mathf.Max(size.x, size.y, size.z);
                if (temp < maxValue) continue;
                result = arr[i];
                maxValue = temp;
            }
            return result;
        }

        /// <summary>
        /// 获取物体及子物体上渲染组件包围盒最大的一个
        /// </summary>
        /// <typeparam name="T">获取类型</typeparam>
        /// <param name="target">目标变换组件</param>
        /// <returns></returns>
        public static T Max<T>(Transform target) where T : Renderer
        {
            return Max<T>(target.gameObject);
        }
        #endregion
    }
}