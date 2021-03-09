/**
* @author ty
* @date 2016.9
* @Description 从摄像机当前画面截图进行高斯模糊处理
*/
using UnityEngine;
using System.Collections;
using Loong.Game;

public class RapidBlurEffectTexture
{
    public static readonly RapidBlurEffectTexture instance = new RapidBlurEffectTexture();

    private UITexture uit = null;

    public RapidBlurEffectTexture()
    {
    }

    public UITexture OnShow(GameObject parent)
    {
        if (parent == null) return null;
        GameObject go = new GameObject("GaussBackground");
        if (go)
        {
            uit = go.AddComponent<UITexture>();
            if(uit)
            {
                uit.width = Screen.width;
                uit.height = Screen.height;
                uit.depth = -2;
                uit.transform.parent = parent.transform;
                uit.transform.localPosition = Vector3.zero;
                uit.transform.localScale = Vector3.one;
                uit.material = new Material(Shader.Find("Game/Base/RapidBlurEffectTexture"));
            }
        }
        Global.Main.StartCoroutine(Loong.Game.TexTool.ScreenShot(new Rect(0, 0, 1334, 750), Callback));
        return uit;
    }

    private void Callback(Texture2D t2d)
    {
        if (uit)
        {
            uit.mainTexture = t2d;
        }
    }

}
