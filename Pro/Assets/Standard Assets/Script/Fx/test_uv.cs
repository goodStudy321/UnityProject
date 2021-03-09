using UnityEngine;
using System.Collections;

public class test_uv : MonoBehaviour
{
    public float x1speed = 0;
    public float y1speed = 0;


    private Vector2 v1;

    private Renderer render = null;

    void Start()
    {
        v1 = Vector2.zero;
        render = GetComponent<Renderer>();
        //AssetBundleManager.GetBundle("dataconfig", getdata);
    }
    void Update()
    {
        if (render == null) return;
        if (render.materials == null) return;
        v1.x += Time.fixedDeltaTime * x1speed * 3;
        v1.y += Time.fixedDeltaTime * y1speed * 3;


        for (int a = 0; a < render.materials.Length; a++)
        {
            if (render.materials[0].HasProperty("_MainTex"))
            {
                render.materials[0].mainTextureOffset = v1;
            }
        }
    }
}
