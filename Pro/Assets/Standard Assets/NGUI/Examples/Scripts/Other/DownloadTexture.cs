//----------------------------------------------
//            NGUI: Next-Gen UI kit
// Copyright © 2011-2016 Tasharen Entertainment
//----------------------------------------------

using UnityEngine;
using System.Collections;
using UnityEngine.Networking;

/// <summary>
/// Simple script that shows how to download a remote texture and assign it to be used by a UITexture.
/// </summary>

[RequireComponent(typeof(UITexture))]
public class DownloadTexture : MonoBehaviour
{
	public string url = "http://www.yourwebsite.com/logo.png";
	public bool pixelPerfect = true;

	Texture2D mTex;

	IEnumerator Start ()
	{
        UnityWebRequest request = UnityWebRequest.Get(url);
        DownloadHandlerTexture dlhTex = new DownloadHandlerTexture();
        request.downloadHandler = dlhTex;

        yield return request.SendWebRequest();
        mTex = dlhTex.texture;

		if (mTex != null)
		{
			UITexture ut = GetComponent<UITexture>();
			ut.mainTexture = mTex;
			if (pixelPerfect) ut.MakePixelPerfect();
		}
        request.Dispose();
	}

	void OnDestroy ()
	{
		if (mTex != null) Destroy(mTex);
	}
}
