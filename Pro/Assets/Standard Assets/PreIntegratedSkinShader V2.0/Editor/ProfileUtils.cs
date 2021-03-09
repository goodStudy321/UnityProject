using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using System.IO;

namespace JBrothers.PreIntegratedSkinShader2 {
	static class ProfileUtils {
		internal static readonly int ProfileMaterialPropertyID  = Shader.PropertyToID("_PSSProfile");
		
		public static PreIntegratedSkinProfile GetMaterialProfile(Material mat) {
			Texture referenceTextureAsset = mat.GetTexture(ProfileMaterialPropertyID);
			if (referenceTextureAsset != null) {
				string path = AssetDatabase.GetAssetPath(referenceTextureAsset);
				PreIntegratedSkinProfile profile = (PreIntegratedSkinProfile)AssetDatabase.LoadAssetAtPath(path, typeof(PreIntegratedSkinProfile));
				return profile;
			} else {
				return null;
			}
		}
		
		public static void SetMaterialProfile(Material mat, PreIntegratedSkinProfile profile) {
			if (profile != null) {
				if (profile.referenceTexture == null) {
					profile.referenceTexture = new Texture2D(1,1);
					profile.referenceTexture.name = "referenceTexture";
					profile.referenceTexture.hideFlags |= HideFlags.HideInHierarchy;
					profile.referenceTexture.hideFlags |= HideFlags.NotEditable;
					AssetDatabase.AddObjectToAsset(profile.referenceTexture, profile);
				}
				
				mat.SetTexture(ProfileMaterialPropertyID, profile.referenceTexture);
			} else {
				mat.SetTexture(ProfileMaterialPropertyID, null);
			}
		}
		
		[MenuItem("Assets/Create/Pre-Integrated Skin Profile")]
		public static void CreateNewProfile() {
			PreIntegratedSkinProfile profile = ScriptableObject.CreateInstance<PreIntegratedSkinProfile>();
			
			// As a starting point fill the profile with values for caucasian skin.
			profile.gauss6_1 = new Vector4(0.23300f, 0.45500f, 0.64900f, 0.0064f);
			profile.gauss6_2 = new Vector4(0.10000f, 0.33600f, 0.34400f, 0.0484f);
			profile.gauss6_3 = new Vector4(0.11800f, 0.19800f, 0.00000f, 0.1870f);
			profile.gauss6_4 = new Vector4(0.11300f, 0.00700f, 0.00700f, 0.5670f);
			profile.gauss6_5 = new Vector4(0.35800f, 0.00400f, 0.00001f, 1.9900f);
			profile.gauss6_6 = new Vector4(0.07800f, 0.00001f, 0.00001f, 7.4100f);
			
			string path = AssetDatabase.GetAssetPath(Selection.activeObject);
			if (path == "")
				path = "Assets";
			
			if (System.IO.File.Exists(path)) {
				path = System.IO.Path.GetDirectoryName(path) + '/' + System.IO.Path.GetFileNameWithoutExtension(path) + ".asset";
			} else {
				path = path + "/New Skin Profile.asset";
			}
			
			ProjectWindowUtil.CreateAsset(profile, path);
		}
	}
}