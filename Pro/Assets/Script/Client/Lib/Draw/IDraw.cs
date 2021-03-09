#if UNITY_EDITOR
using System.Collections;

namespace Hello.Game
{
    public interface IDraw
    {
        void Draw(UnityEngine.Object obj, IList lst, int idx);
    }
}

#endif
