/// <summary>
/// Generic Mono singleton.
/// </summary>
using UnityEngine;
namespace CloudVoiceIM
{
    public abstract class MonoSingleton<T> : MonoBehaviour where T : MonoSingleton<T>
    {

        static bool isPlaying = true;
        private static T m_Instance = null;

        public static T instance
        {
            get
            {
                if (!isPlaying) return default(T);
                if (m_Instance == null)
                {
                    m_Instance = GameObject.FindObjectOfType(typeof(T)) as T;
                    if (m_Instance == null)
                    {
                        m_Instance = new GameObject("Singleton of " + typeof(T).ToString(), typeof(T)).GetComponent<T>();
                        m_Instance.Init();
                    }

                }
                return m_Instance;
            }
        }

        private void Awake()
        {

            if (m_Instance == null)
            {
                m_Instance = this as T;
            }

#if UNITY_EDITOR
#pragma warning disable 618
            UnityEditor.EditorApplication.playmodeStateChanged += () =>
                {
                    if (!UnityEditor.EditorApplication.isPlayingOrWillChangePlaymode &&
                            UnityEditor.EditorApplication.isPlaying)
                    {
                        //Debug.Log("PlayModeChange:" + UnityEditor.EditorApplication.isPlaying);
                        isPlaying = false;
                    }
                };
#pragma warning restore
#endif

        }
        public void Create()
        {

        }

        public virtual void Init() { }


        private void OnApplicationQuit()
        {
            m_Instance = null;
            isPlaying = false;
        }
    }
}