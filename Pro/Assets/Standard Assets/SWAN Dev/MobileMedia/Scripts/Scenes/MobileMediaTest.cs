/// <summary>
/// By SwanDEV 2017
/// </summary>

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using System.IO;
using System;

public class MobileMediaTest : DImageDisplayHandler
{
	public CanvasScaler canvasScaler;

	public Image displayImage;
	public Text debugText;

	private string hints = "Mobile Media Plugin Demo\nTo test save/pick media to/from Native, please build Android, iOS app and test on device.\n\n";

	void Start()
	{
		debugText.text = hints;

		//Check screen orientation for setting canvas resolution
		if(Screen.width > Screen.height)
		{
			canvasScaler.referenceResolution = new Vector2(1920, 1080);
		}
		else
		{
			canvasScaler.referenceResolution = new Vector2(1080, 1920);
		}
	}

	public void PickImage()
	{
		MobileMedia.PickImage((imagePath)=>{
			// Implement your code to load & use the image using the returned image path:
			if(!string.IsNullOrEmpty(imagePath))
			{
				//FileInfo fileInfo = new FileInfo(imagePath);
				byte[] imageBytes = File.ReadAllBytes(imagePath);
				Texture2D texture2D = new Texture2D(1, 1, TextureFormat.ARGB32, false); 
				texture2D.LoadImage(imageBytes);

				// Display image
				_ShowImage(_ToSprite(texture2D));

				Debug.Log("Image Path: " + imagePath);
				debugText.text = hints + "Image Path: " + imagePath;
			}
			else
			{
				Debug.Log("Path is empty or null.");
			}
		});
	}

	public void PickVideo()
	{
		MobileMedia.PickVideo((videoPath)=>{
			// Implement your code to load & play the video using the returned video path:
			if(!string.IsNullOrEmpty(videoPath))
			{
				Debug.Log("Video Path: " + videoPath);
				debugText.text = hints + "Video Path: " + videoPath;
			}
			else
			{
				Debug.Log("Path is empty or null.");
			}
		});
	}

	public void SaveJPG()
	{
		TakeScreenshot((tex2D)=>{
			string savePath = MobileMedia.SaveImage(tex2D, "MobileMediaTest", new FilePathName().GetJpgFileName(), MobileMedia.ImageFormat.JPG);
			_ShowImage(_ToSprite(tex2D));

			debugText.text = hints + "Save Path: " + savePath;
			Debug.Log("Save Path: " + savePath);
		});
	}

	public void SavePNG()
	{
		TakeScreenshot((tex2D)=>{
			string savePath = MobileMedia.SaveImage(tex2D, "MobileMediaTest", new FilePathName().GetPngFileName(), MobileMedia.ImageFormat.PNG);
			_ShowImage(_ToSprite(tex2D));

			debugText.text = hints + "Save Path: " + savePath;
			Debug.Log("Save Path: " + savePath);
		});
	}

	public void SaveGIF()
	{
		TakeScreenshot((tex2D)=>{
			string savePath = MobileMedia.SaveImage(tex2D, "MobileMediaTest", new FilePathName().GetGifFileName(), MobileMedia.ImageFormat.GIF);
			_ShowImage(_ToSprite(tex2D));

			debugText.text = hints + "Save Path: " + savePath;
			Debug.Log("Save Path: " + savePath);
		});
	}

	/// <summary>
	/// To test save Mp4 file to Native. Put your Mp4 file(s) in the Assets/StreamingAssets folder.
	/// </summary>
	public void SaveMP4()
	{
		string existingVideoPath = "";
		List<string> mp4Paths = new FilePathName().GetFilePaths(Application.streamingAssetsPath, new List<string>{".mp4"});

		string tmpText = hints + "mp4Paths: ";
		for(int i=0; i<mp4Paths.Count; i++)
		{
			tmpText = tmpText + "\n" + mp4Paths[i];
		}
		debugText.text = tmpText;
		Debug.Log("mp4Paths: " + tmpText);

		if(mp4Paths != null && mp4Paths.Count > 0)
		{
			existingVideoPath = mp4Paths[UnityEngine.Random.Range(0, mp4Paths.Count)];
			Debug.Log("existingVideoPath: " + existingVideoPath + " | mp4Paths.Count: " + mp4Paths.Count);

			if(File.Exists(existingVideoPath))
			{
				byte[] mp4Bytes = new FilePathName().ReadFileToBytes(existingVideoPath);
				string savePath = MobileMedia.SaveVideo(mp4Bytes, "MobileMediaTest", "MyMp4Video", ".mp4");

				debugText.text += "\n\nSave Path: " + savePath;
				Debug.Log("Save Path: " + savePath);
			}
		}

	}

	private void _ShowImage(Sprite sprite)
	{
		base.SetImage(displayImage, sprite);
	}


	#region ----- Others -----
	public void MoreAssetsAndDocuments()
	{
		Application.OpenURL("https://www.swanob2.com/assets");
	}

	public void TakeScreenshot(Action<Texture2D> onComplete)
	{
		StartCoroutine(_TakeScreenshot(onComplete));
	}

	private IEnumerator _TakeScreenshot(Action<Texture2D> onComplete)
	{
		yield return new WaitForEndOfFrame();
		int width = Screen.width;
		int height = Screen.height;
		Texture2D readTex = new Texture2D(width, height, TextureFormat.RGB24, false);
		Rect rect = new Rect(0, 0, width, height);
		readTex.ReadPixels(rect, 0, 0);
		readTex.Apply();
		onComplete(readTex);
	}

	private Sprite _ToSprite(Texture2D texture)
	{
		if(texture == null) return null;

		Vector2 pivot = new Vector2(0.5f, 0.5f);
		float pixelPerUnit = 100;
		return Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), pivot, pixelPerUnit);
	}
	#endregion

}
