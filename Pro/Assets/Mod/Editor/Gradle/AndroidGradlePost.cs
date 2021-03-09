using Loong.Edit;
using UnityEditor.Android;


public class AndroidGradlePost : IPostGenerateGradleAndroidProject
{

    public int callbackOrder
    {
        get { return 0; }
    }

    public void OnPostGenerateGradleAndroidProject(string path)
    {
        PostGradleMgr.Instance.OnPostGradle(path);
    }

}
