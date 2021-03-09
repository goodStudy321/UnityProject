using System.Collections;
using System.Collections.Generic;
using System;
using UnityEngine;

namespace UnityEditor
{
	internal class XyjStandardShaderGUI : ShaderGUI
	{
		public enum BlendMode
		{
			Opaque,
			Cutout,
			Transparent // Physically plausible transparency mode, implemented as alpha pre-multiply
		}

		public enum ReflectionMode
		{
			AllOn, MetalOnly, AllOff
		}

		private static class Styles
		{
			public static string emptyTootip = "";
			public static GUIContent albedoText = new GUIContent("Albedo", "Albedo (RGB) and Transparency (A)");
			public static GUIContent alphaCutoffText = new GUIContent("Alpha Cutoff", "Threshold for alpha cutoff");

			public static GUIContent normalMapText = new GUIContent("Normal Map", "Normal Map");
			public static GUIContent emissionText = new GUIContent("Emission", "Emission (RGB)");

			public static GUIContent mixedMapText = new GUIContent("Mixed Map", "Occlusion (R), Smoothness (G), Metallic (B)");
			public static GUIContent occlusionStrengthText = new GUIContent("Occlusion Strength", "Occlusion Strength");
			public static GUIContent smoothnessScaleText = new GUIContent("Smoothness", "Smoothness scale factor");
			public static GUIContent smoothnessText = new GUIContent("Smoothness", "Smoothness value");
			public static GUIContent metallicScaleText = new GUIContent("Metallic", "Metallic scale factor");
			public static GUIContent metallicText = new GUIContent("Metallic", "Metallic value");

			public static GUIContent highlightsText = new GUIContent("Specular Highlights", "Specular Highlights");
			//public static GUIContent reflectionsText = new GUIContent("All Reflections", "All Glossy Reflections");
			//public static GUIContent nonmetalReflectionsText = new GUIContent("Non Metal Reflections", "Non Metal Glossy Reflections");
			public static GUIContent lightmapSepcularText = new GUIContent("Lightmap Specular", "Fake reflection when use dir lightmap");
			public static GUIContent fullOcclusionText = new GUIContent("Full Occlusion", "Occlusion direct light");

			public static GUIContent emissionBakeScaleText = new GUIContent("Emission Bake Scale", "When bake lightmap, use this scale for emission, but not for rendering");

			public static GUIContent needFixingMixedMapText = new GUIContent("Warning: Mixed Map need be linear texture, but this set as sRGB texture.", "");
			public static GUIContent fixnowText = new GUIContent("Fix Now", "");

			public static string whiteSpaceString = " ";
			public static string primaryMapsText = "Main Maps";
			public static string emissionMapsText = "Emission Maps";
			public static string renderingOptionText = "Rendering Options";
			public static string renderingMode = "Rendering Mode";
			public static GUIContent emissiveWarning = new GUIContent("Emissive value is animated but the material has not been configured to support emissive. Please make sure the material itself has some amount of emissive.");
			public static GUIContent emissiveColorWarning = new GUIContent("Ensure emissive color is non-black for emission to have effect.");
			public static readonly string[] blendNames = Enum.GetNames(typeof(BlendMode));
			public static string reflectionMode = "Reflection Mode";
			public static readonly string[] reflectionNames = Enum.GetNames(typeof(ReflectionMode));
		}
		MaterialProperty blendMode = null;
		MaterialProperty albedoMap = null;
		MaterialProperty albedoColor = null;
		MaterialProperty alphaCutoff = null;

		MaterialProperty bumpMap = null;

		MaterialProperty mixedMap = null;
		MaterialProperty occlusionStrength = null;
		MaterialProperty smoothnessScale = null;
		MaterialProperty metallicScale = null;
		MaterialProperty smoothness = null;
		MaterialProperty metallic = null;

		MaterialProperty emissionColorForRendering = null;
		MaterialProperty emissionMap = null;
		MaterialProperty emissionBakeScale = null;

		MaterialProperty reflectionMode = null;
		MaterialProperty highlights = null;
		//MaterialProperty reflections = null;
		//MaterialProperty nonmetalReflections = null;
		//MaterialProperty lightmapSpecular = null;
		//MaterialProperty fullOcclusion = null;

		MaterialEditor m_MaterialEditor;
		//ColorPickerHDRConfig m_ColorPickerHDRConfig = new ColorPickerHDRConfig(0f, 99f, 1 / 99f, 3f);

		bool m_FirstTimeApply = true;

		public void FindProperties(MaterialProperty[] props)
		{
			blendMode = FindProperty("_Mode", props);
			albedoMap = FindProperty("_MainTex", props);
			albedoColor = FindProperty("_Color", props);
			alphaCutoff = FindProperty("_Cutoff", props);

			bumpMap = FindProperty("_BumpMap", props);

			mixedMap = FindProperty("_MixedMap", props, false);
			occlusionStrength = FindProperty("_OcclusionStrength", props);
			smoothnessScale = FindProperty("_SmoothnessScale", props, false);
			metallicScale = FindProperty("_MetallicScale", props, false);
			smoothness = FindProperty("_Smoothness", props, false);
			metallic = FindProperty("_Metallic", props, false);

			reflectionMode = FindProperty("_ReflectionMode", props, false);
			highlights = FindProperty("_SpecularHighlights", props, false);
			//reflections = FindProperty("_GlossyReflections", props, false);
			//nonmetalReflections = FindProperty("_NonMetalReflections", props, false);
			//lightmapSpecular = FindProperty("_LightmapSpecular", props, false);
			//fullOcclusion = FindProperty("_FullOcclusion", props, false);

			emissionColorForRendering = FindProperty("_EmissionColor", props);
			emissionMap = FindProperty("_EmissionMap", props);
			emissionBakeScale = FindProperty("_EmissionBakeScale", props);
		}

		public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
		{
			FindProperties(props); // MaterialProperties can be animated so we do not cache them but fetch them every event to ensure animated values are updated correctly
			m_MaterialEditor = materialEditor;
			Material material = materialEditor.target as Material;

			// Make sure that needed setup (ie keywords/renderqueue) are set up if we're switching some existing
			// material to a standard shader.
			// Do this before any GUI code has been issued to prevent layout issues in subsequent GUILayout statements (case 780071)
			if (m_FirstTimeApply) {
				MaterialChanged(material);
				m_FirstTimeApply = false;
			}

			ShaderPropertiesGUI(material);
		}

		public void ShaderPropertiesGUI(Material material)
		{
			// Use default labelWidth
			EditorGUIUtility.labelWidth = 0f;

			// Detect any changes to the material
			EditorGUI.BeginChangeCheck();
			{
				BlendModePopup();

				// Primary properties
				GUILayout.Label(Styles.primaryMapsText, EditorStyles.boldLabel);
				DoAlbedoArea(material);
				m_MaterialEditor.TexturePropertySingleLine(Styles.normalMapText, bumpMap);
				DoMixedMapArea();

				EditorGUILayout.Space();

				GUILayout.Label(Styles.emissionMapsText, EditorStyles.boldLabel);

				DoEmissionArea(material);

				EditorGUILayout.Space();

				// Third properties
				GUILayout.Label(Styles.renderingOptionText, EditorStyles.boldLabel);
				ReflectionModePopup();
				if (highlights != null)
					m_MaterialEditor.ShaderProperty(highlights, Styles.highlightsText);
#if false
				if (reflections != null)
					m_MaterialEditor.ShaderProperty(reflections, Styles.reflectionsText);
				if (nonmetalReflections != null)
					m_MaterialEditor.ShaderProperty(nonmetalReflections, Styles.nonmetalReflectionsText);
				if (lightmapSpecular != null)
					m_MaterialEditor.ShaderProperty(lightmapSpecular, Styles.lightmapSepcularText);
				if (fullOcclusion != null)
					m_MaterialEditor.ShaderProperty(fullOcclusion, Styles.fullOcclusionText);
#endif
			}
			if (EditorGUI.EndChangeCheck()) {
				foreach (var obj in blendMode.targets)
					MaterialChanged((Material)obj);
			}
		}

		public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader)
		{
			// _Emission property is lost after assigning Standard shader to the material
			// thus transfer it before assigning the new shader
			if (material.HasProperty("_Emission")) {
				material.SetColor("_EmissionColor", material.GetColor("_Emission"));
			}

			base.AssignNewShaderToMaterial(material, oldShader, newShader);

			if (oldShader == null || !oldShader.name.Contains("Legacy Shaders/")) {
				SetupMaterialWithBlendMode(material, (BlendMode)material.GetFloat("_Mode"));
				return;
			}

			BlendMode blendMode = BlendMode.Opaque;
			if (oldShader.name.Contains("/Transparent/Cutout/")) {
				blendMode = BlendMode.Cutout;
			}
			else if (oldShader.name.Contains("/Transparent/")) {
				// NOTE: legacy shaders did not provide physically based transparency
				// therefore Fade mode
				blendMode = BlendMode.Transparent;
			}
			material.SetFloat("_Mode", (float)blendMode);

			//material.SetFloat("", (float)reflectionMode);

			MaterialChanged(material);
		}

		void BlendModePopup()
		{
			EditorGUI.showMixedValue = blendMode.hasMixedValue;
			var mode = (BlendMode)blendMode.floatValue;

			EditorGUI.BeginChangeCheck();
			mode = (BlendMode)EditorGUILayout.Popup(Styles.renderingMode, (int)mode, Styles.blendNames);
			if (EditorGUI.EndChangeCheck()) {
				m_MaterialEditor.RegisterPropertyChangeUndo("Rendering Mode");
				blendMode.floatValue = (float)mode;
			}

			EditorGUI.showMixedValue = false;
		}

		void ReflectionModePopup()
		{
			EditorGUI.showMixedValue = reflectionMode.hasMixedValue;
			var mode = (ReflectionMode)reflectionMode.floatValue;

			EditorGUI.BeginChangeCheck();
			mode = (ReflectionMode)EditorGUILayout.Popup(Styles.reflectionMode, (int)mode, Styles.reflectionNames);
			if (EditorGUI.EndChangeCheck()) {
				m_MaterialEditor.RegisterPropertyChangeUndo("Reflection Mode");
				reflectionMode.floatValue = (float)mode;
			}

			EditorGUI.showMixedValue = false;
		}

		void DoAlbedoArea(Material material)
		{
			m_MaterialEditor.TexturePropertySingleLine(Styles.albedoText, albedoMap, albedoColor);
			if (((BlendMode)material.GetFloat("_Mode") == BlendMode.Cutout)) {
				m_MaterialEditor.ShaderProperty(alphaCutoff, Styles.alphaCutoffText.text, MaterialEditor.kMiniTextureFieldLabelIndentLevel + 1);
			}
		}

		void DoEmissionArea(Material material)
		{
			bool showHelpBox = !HasValidEmissiveKeyword(material);

			bool hadEmissionTexture = emissionMap.textureValue != null;

			// Texture and HDR color controls
			m_MaterialEditor.TexturePropertyWithHDRColor(Styles.emissionText, emissionMap, emissionColorForRendering, false);

			int indentation = MaterialEditor.kMiniTextureFieldLabelIndentLevel + 1; // align with labels of texture properties
			m_MaterialEditor.ShaderProperty(emissionBakeScale, Styles.emissionBakeScaleText, indentation);

			// If texture was assigned and color was black set color to white
			float brightness = emissionColorForRendering.colorValue.maxColorComponent;
			if (emissionMap.textureValue != null && !hadEmissionTexture && brightness <= 0f)
				emissionColorForRendering.colorValue = Color.white;

			// Emission for GI?
			m_MaterialEditor.LightmapEmissionProperty(MaterialEditor.kMiniTextureFieldLabelIndentLevel + 1);

			if (showHelpBox) {
				EditorGUILayout.HelpBox(Styles.emissiveWarning.text, MessageType.Warning);
			}
		}

		/// <summary>
		///   <para>Make a help box with a message and button. Returns true, if button was pressed.</para>
		/// </summary>
		/// <param name="messageContent">The message text.</param>
		/// <param name="buttonContent">The button text.</param>
		/// <returns>
		///   <para>Returns true, if button was pressed.</para>
		/// </returns>
		public bool HelpBoxWithButton(GUIContent messageContent, GUIContent buttonContent)
		{
			Rect rect = GUILayoutUtility.GetRect(messageContent, EditorStyles.helpBox);
			GUILayoutUtility.GetRect(1f, 25f);
			rect.height += 25f;
			GUI.Label(rect, messageContent, EditorStyles.helpBox);
			Rect position = new Rect(rect.xMax - 60f - 4f, rect.yMax - 20f - 4f, 60f, 20f);
			return GUI.Button(position, buttonContent);
		}

		void DoMixedMapArea()
		{
			bool hasMixedMap = false;
			hasMixedMap = mixedMap.textureValue != null;
			m_MaterialEditor.TexturePropertySingleLine(Styles.mixedMapText, mixedMap);
			if (MixedMapNeedsFixing(mixedMap)) {
				if (this.HelpBoxWithButton(Styles.needFixingMixedMapText, Styles.fixnowText)) {
					FixMixedMapAsLinear(mixedMap);
				}
			}

			int indentation = MaterialEditor.kMiniTextureFieldLabelIndentLevel + 1; // align with labels of texture properties
			if (hasMixedMap) {
				m_MaterialEditor.ShaderProperty(occlusionStrength, Styles.occlusionStrengthText, indentation);
				m_MaterialEditor.ShaderProperty(smoothnessScale, Styles.smoothnessScaleText, indentation);
				m_MaterialEditor.ShaderProperty(metallicScale, Styles.metallicScaleText, indentation);
			}
			else {
				m_MaterialEditor.ShaderProperty(smoothness, Styles.smoothnessText, indentation);
				m_MaterialEditor.ShaderProperty(metallic, Styles.metallicScaleText, indentation);
			}
		}

		public static void SetupMaterialWithReflectionMode(Material material, ReflectionMode reflectionMode)
		{
			switch (reflectionMode) {
			case ReflectionMode.AllOn:
				material.DisableKeyword("_REFLECTION_METALONLY");
				material.DisableKeyword("_REFLECTION_ALLOFF");
				break;
			case ReflectionMode.MetalOnly:
				material.EnableKeyword("_REFLECTION_METALONLY");
				material.DisableKeyword("_REFLECTION_ALLOFF");
				break;
			case ReflectionMode.AllOff:
				material.DisableKeyword("_REFLECTION_METALONLY");
				material.EnableKeyword("_REFLECTION_ALLOFF");
				break;
			}
		}

		public static void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
		{
			switch (blendMode) {
			case BlendMode.Opaque:
				material.SetOverrideTag("RenderType", "");
				material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
				material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
				material.SetInt("_ZWrite", 1);
				material.SetInt("_Cull", (int)UnityEngine.Rendering.CullMode.Back);
				material.DisableKeyword("_ALPHATEST_ON");
				//material.DisableKeyword("_ALPHABLEND_ON");
				material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
				material.renderQueue = -1;
				break;
			case BlendMode.Cutout:
				material.SetOverrideTag("RenderType", "TransparentCutout");
				material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
				material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
				material.SetInt("_ZWrite", 1);
				material.SetInt("_Cull", (int)UnityEngine.Rendering.CullMode.Off);
				material.EnableKeyword("_ALPHATEST_ON");
				//material.DisableKeyword("_ALPHABLEND_ON");
				material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
				material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
				break;
#if false
			case BlendMode.Fade:
				material.SetOverrideTag("RenderType", "Transparent");
				material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
				material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
				material.SetInt("_ZWrite", 0);
				material.DisableKeyword("_ALPHATEST_ON");
				material.EnableKeyword("_ALPHABLEND_ON");
				material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
				material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
				break;
#endif
			case BlendMode.Transparent:
				material.SetOverrideTag("RenderType", "Transparent");
				material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
				material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
				material.SetInt("_ZWrite", 0);
				material.SetInt("_Cull", (int)UnityEngine.Rendering.CullMode.Off);
				material.DisableKeyword("_ALPHATEST_ON");
				//material.DisableKeyword("_ALPHABLEND_ON");
				material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
				material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
				break;
			}
		}

		static bool ShouldEmissionBeEnabled(Material mat, Color color)
		{
			var realtimeEmission = (mat.globalIlluminationFlags & MaterialGlobalIlluminationFlags.RealtimeEmissive) > 0;
			return color.maxColorComponent > 0.1f / 255.0f || realtimeEmission;
		}

		static void SetMaterialKeywords(Material material)
		{
			// Note: keywords must be based on Material value not on MaterialProperty due to multi-edit & material animation
			// (MaterialProperty value might come from renderer material property block)
			SetKeyword(material, "_NORMALMAP", material.GetTexture("_BumpMap"));
			SetKeyword(material, "_MIXEDMAP", material.GetTexture("_MixedMap"));

			bool shouldEmissionBeEnabled = ShouldEmissionBeEnabled(material, material.GetColor("_EmissionColor"));
			SetKeyword(material, "_EMISSION", shouldEmissionBeEnabled);

			// Setup lightmap emissive flags
			MaterialGlobalIlluminationFlags flags = material.globalIlluminationFlags;
			if ((flags & (MaterialGlobalIlluminationFlags.BakedEmissive | MaterialGlobalIlluminationFlags.RealtimeEmissive)) != 0) {
				flags &= ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
				if (!shouldEmissionBeEnabled)
					flags |= MaterialGlobalIlluminationFlags.EmissiveIsBlack;

				material.globalIlluminationFlags = flags;
			}
		}

		bool HasValidEmissiveKeyword(Material material)
		{
			// Material animation might be out of sync with the material keyword.
			// So if the emission support is disabled on the material, but the property blocks have a value that requires it, then we need to show a warning.
			// (note: (Renderer MaterialPropertyBlock applies its values to emissionColorForRendering))
			bool hasEmissionKeyword = material.IsKeywordEnabled("_EMISSION");
			if (!hasEmissionKeyword && ShouldEmissionBeEnabled(material, emissionColorForRendering.colorValue))
				return false;
			else
				return true;
		}

		static void MaterialChanged(Material material)
		{
			SetupMaterialWithBlendMode(material, (BlendMode)material.GetFloat("_Mode"));

			SetupMaterialWithReflectionMode(material, (ReflectionMode)material.GetFloat("_ReflectionMode"));

			SetMaterialKeywords(material);
		}

		static void SetKeyword(Material m, string keyword, bool state)
		{
			if (state)
				m.EnableKeyword(keyword);
			else
				m.DisableKeyword(keyword);
		}

		static bool MixedMapNeedsFixing(MaterialProperty prop)
		{
			if (prop.type != MaterialProperty.PropType.Texture) {
				return false;
			}
			UnityEngine.Object[] targets = prop.targets;
			Texture tex = prop.textureValue;
			if (!tex)
				return false;

			string path = AssetDatabase.GetAssetPath(tex);
			TextureImporter importer = (TextureImporter)TextureImporter.GetAtPath(path);
			if (importer == null)
				return false;
			if (importer.sRGBTexture)
				return true;

			return false;
		}

		static void FixMixedMapAsLinear(MaterialProperty prop)
		{
			if (prop.type != MaterialProperty.PropType.Texture) {
				return;
			}
			UnityEngine.Object[] targets = prop.targets;
			Texture tex = prop.textureValue;
			if (!tex)
				return;

			string path = AssetDatabase.GetAssetPath(tex);
			TextureImporter importer = (TextureImporter)TextureImporter.GetAtPath(path);
			if (importer == null)
				return;
			if (!importer.sRGBTexture)
				return;

			importer.sRGBTexture = false;
			importer.SaveAndReimport();
		}
	}
}
