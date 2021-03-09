using UnityEngine;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.6.5
    /// BG:继承MonoBehaviour的单例模式
    /// </summary>
    public class MonoSingleton<T> : MonoStatic<T> where T : MonoBehaviour
    {
        /// <summary>
        /// 获取单例
        /// </summary>
        /// <returns></returns>
        public static T Instance
        {
            get
            {
                CreateDummy();
                return instance;
            }
        }

        protected virtual void OnDestroy()
        {
            instance = null;
        }
    }
}