using UnityEngine;
using UnityEditor;
using System.Collections;

namespace JBrothers.PreIntegratedSkinShader2 {
	public class LookupTextureGenerator {
		[MenuItem ("GameObject/Pre-Integrated Skin Shader 2.0/Generate Lookup Textures")]
		public static void Generate() {
			#if !UNITY_5_5_OR_NEWER
			if (!SystemInfo.supportsRenderTextures) {
				EditorUtility.DisplayDialog("Bummer!", "Render textures not supported! Either you're running on " +
					"ancient hardware, lack proper GPU driver or are running Unity Free < 5.0. Note that you can " +
					"just use the provided lookup textures.", "got it");
				return;
			}
			#else
			// From 5.5 on SystemInfo.supportsRenderTextures always returns true and Unity produces an ugly warning.
			#endif

			string rootPath = FindPSSRootPath();
			Debug.Log("LookupTextureGenerator: start");

			LookupTextureDefinition[] lookupDefinitions = LookupTextureDefinition.LookupDefinitions;
			bool cancelled = EditorUtility.DisplayCancelableProgressBar("Generating lookup textures", "setup", 0f);
			try {
				for (int lookupInd=0; lookupInd<lookupDefinitions.Length; lookupInd++) {
					LookupTextureDefinition lookupDef = lookupDefinitions[lookupInd];

					float progress = (float)lookupInd / (float)lookupDefinitions.Length;
					cancelled = EditorUtility.DisplayCancelableProgressBar("Generating lookup textures", lookupDef.ParameterName, progress);
					if (cancelled) {
						Debug.Log("Operation cancelled by user");
						break;
					}

					string path = rootPath + "/Resources/PSSLookup" + lookupDef.KernelName + ".asset";
					Debug.Log("generating " + path);

					Texture2D outputTexture = AssetDatabase.LoadMainAssetAtPath(path) as Texture2D;
					if (outputTexture == null) {
						outputTexture = new Texture2D(lookupDef.Width, lookupDef.Height, lookupDef.Format, lookupDef.MipMaps, true);
						AssetDatabase.CreateAsset(outputTexture, path);
					} else {
						// If the lookup texture already exists, then reuse the asset in order to keep it's GUID for
						// sake of fast prototyping, so the materials can keep the reference.
						outputTexture.Resize(lookupDef.Width, lookupDef.Height, lookupDef.Format, lookupDef.MipMaps);
					}
					outputTexture.name = lookupDef.ParameterName;

					// make it not editable just so people don'r screw it up
					outputTexture.hideFlags = HideFlags.NotEditable;

					// important for correct mip level interpolation, so GPU doesn't interfare and the result is linear
					outputTexture.anisoLevel = 0;

					outputTexture.wrapMode = lookupDef.wrapMode;
					if (lookupDef.MipMaps) {
						// interpolate between mip levels
						outputTexture.filterMode = FilterMode.Trilinear;
					} else {
						// no mips, trilinear is not necessary
						outputTexture.filterMode = FilterMode.Bilinear;
					}

					string shaderName = "Hidden/PreIntegratedSkinShader/ComputeLookup/" + lookupDef.KernelName;
					Shader shader = shaderName != null ? Shader.Find(shaderName) : null;
					if (shader == null)
						throw new System.Exception("shader not found: " + shaderName);

					Material material = new Material(shader);
					try {
						material.hideFlags = HideFlags.HideAndDontSave;

						int textureWidth = lookupDef.Width;
						int textureHeight = lookupDef.Height;
//						int kernelWidth = Mathf.Min(lookupDef.KernelWidth, textureWidth);
//						int kernelHeight = Mathf.Min(lookupDef.KernelHeight, textureHeight);
						int mipCount = lookupDef.MipMaps ? (1 + Mathf.FloorToInt(Mathf.Log(Mathf.Max(textureWidth, textureHeight), 2f))) : 1;

						Debug.Log("textureWidth: " + textureWidth);
						Debug.Log("textureHeight: " + textureHeight);
//						Debug.Log("kernelWidth: " + kernelWidth);
//						Debug.Log("kernelHeight: " + kernelHeight);
						Debug.Log("mipCount: " + mipCount);

						for (int mipLevel = 0; mipLevel<mipCount; mipLevel++) {
							int mipOrTextureWidth = Mathf.Max(1, textureWidth >> (mipLevel));
							int mipOrTextureHeight = Mathf.Max(1, textureHeight >> (mipLevel));
							float mipLevelNormalized;
							if (mipCount > 1) {
								mipLevelNormalized = Mathf.Min(1.0f, (float)(mipLevel)/(float)(mipCount-1 - lookupDef.MipMapSkipLastNLevels));
							} else {
								mipLevelNormalized = 0f;
							}
							
							Debug.Log("mip level: " + mipLevel);
							Debug.Log("mipLevelNormalized: " + mipLevelNormalized);
							Debug.Log("mipOrTextureWidth: " + mipOrTextureWidth);
							Debug.Log("mipOrTextureHeight: " + mipOrTextureHeight);

							RenderTexture outRT = new RenderTexture(mipOrTextureWidth, mipOrTextureHeight, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
							try {
								outRT.useMipMap = false;
								#if UNITY_5_5_OR_NEWER
								outRT.autoGenerateMips = false;
								#else
								outRT.generateMips = false;
								#endif
								outRT.antiAliasing = 1;
								outRT.anisoLevel = 0;
								if (!outRT.Create())
									throw new System.Exception("couldn't create render texture");

								RenderTexture oldRndT = RenderTexture.active;
								try {
									material.SetInt("_MipLevel", mipLevel);
									material.SetInt("_MipCount", mipCount);
									material.SetFloat("_MipLevelNormalized", mipLevelNormalized);
									material.SetInt("_TextureWidth", outputTexture.width);
									material.SetInt("_TextureHeight", outputTexture.height);
									material.SetInt("_KernelX", 0);
									material.SetInt("_KernelY", 0);
									material.SetInt("_KernelWidth", mipOrTextureWidth);
									material.SetInt("_KernelHeight", mipOrTextureHeight);

									RenderTexture.active = outRT;
									//Graphics.SetRenderTarget(outRT, mipLevel);
									
//									Rect viewportRect = new Rect(0f, 0f, outputTexture.width, outputTexture.height);
									
									GL.PushMatrix();
									GL.LoadPixelMatrix(0f, outputTexture.width, outputTexture.height, 0f);
									
//									Rect outputRectUVSpace = new Rect(0,0,1,1);
									
									Vector2 halfTexelSize = new Vector2(1f/(float)mipOrTextureWidth, 1f/(float)mipOrTextureHeight);
									Debug.Log("halfTexelSize="+halfTexelSize);
									
									for (int i=0 ; i<material.passCount; i++) {
										material.SetPass(i);
										
										GL.Begin(GL.QUADS);
										
										GL.TexCoord2(-halfTexelSize.x, 1+halfTexelSize.y);
										GL.Vertex3(0, 0, 0);
										
										GL.TexCoord2(1+halfTexelSize.x, 1+halfTexelSize.y);
										GL.Vertex3(outputTexture.width, 0, 0);
										
										GL.TexCoord2(1+halfTexelSize.x, 0-halfTexelSize.y);
										GL.Vertex3(outputTexture.width, outputTexture.height, 0);
										
										GL.TexCoord2(-halfTexelSize.x, 0-halfTexelSize.y);
										GL.Vertex3(0, outputTexture.height, 0);
										
										GL.End();
									}
									
									GL.PopMatrix();

									if (mipLevel > 0) {
										// Since ReadPixels always reads mip level 0, need to allocate a temporary texture
										// and then move the pixels around on CPU side. Which is not a problem in our case.

										// allocate a temporary texture for  instead of reading directly
										Texture2D tempTex = new Texture2D(mipOrTextureWidth, mipOrTextureHeight, outputTexture.format, false, true);
										try {
											tempTex.ReadPixels(new Rect(0, 0, mipOrTextureWidth, mipOrTextureHeight), 0, 0, false);
											var pixels = tempTex.GetPixels(0, 0, mipOrTextureWidth, mipOrTextureHeight, 0);
											Debug.Log(tempTex.GetPixel(0,0));
											outputTexture.SetPixels(0, 0, mipOrTextureWidth, mipOrTextureHeight, pixels, mipLevel);
										} finally {
											Object.DestroyImmediate(tempTex);
										}
									} else {
										outputTexture.ReadPixels(new Rect(0, 0, outputTexture.width, outputTexture.height), 0, 0, false);
									}

								} finally {
									RenderTexture.active = oldRndT;
									outRT.Release();
								}
							} finally {
								Object.DestroyImmediate(outRT);
							}
						}

					} finally {
						Object.DestroyImmediate(material);
					}

					outputTexture.Apply(false);
				}
			} finally {
				EditorUtility.ClearProgressBar();
			}

			Debug.Log("LookupTextureGenerator: end");
		}

		private static string FindPSSRootPath() {
			// A little hack to dynamically find the root path where the PreIntegratedSkinShader resides.
			// Not really important, could just as well hard code the path.
			var tmp = ScriptableObject.CreateInstance<PreIntegratedSkinProfile>();
			try {
				string path = AssetDatabase.GetAssetPath(MonoScript.FromScriptableObject(tmp));
				path = System.IO.Path.GetDirectoryName(path); // root is it's parent
				return path;
			} finally {
				Object.DestroyImmediate(tmp);
			}
		}
	}
}