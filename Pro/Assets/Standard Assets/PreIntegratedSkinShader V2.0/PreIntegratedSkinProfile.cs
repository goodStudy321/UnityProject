using UnityEngine;
using System.Collections;

namespace JBrothers.PreIntegratedSkinShader2 {
	public class PreIntegratedSkinProfile : ScriptableObject {
		// The diffusion profile is represented as parameters for a sum of 6 gaussians as described in section
		// "Diffusion Profiles" in http://http.developer.nvidia.com/GPUGems3/gpugems3_ch14.html.
		// If you really want to represent other measured profiles you'll need to study the referenced papers and fit
		// your [dipole/multipole] functions to 6 gaussians in Mathematica/Matlab/Octave.
		// I didn't, I'm marely using their values for default profile and some fantasy for others.
		// Since Unity 4.3 doesn't support struct properties vec4s will do.
		// x,y,z contain red, green and blue weights respectively, w is variance (think blur of the layer/pass).
		public Vector4 gauss6_1;
		public Vector4 gauss6_2;
		public Vector4 gauss6_3;
		public Vector4 gauss6_4;
		public Vector4 gauss6_5;
		public Vector4 gauss6_6;

		// Values derived from the main 6 gaussians. Normalized and with some precomputation.
		// See the shader code for how these are used.
		// They are fed as uniforms to the shader using these exact names.
		[HideInInspector, SerializeField] private Vector4 _PSSProfileHigh_weighths1_var1;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileHigh_weighths2_var2;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileHigh_weighths3_var3;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileHigh_weighths4_var4;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileHigh_weighths5_var5;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileHigh_weighths6_var6;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileHigh_sqrtvar1234;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileHigh_transl123_sqrtvar5;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileHigh_transl456_sqrtvar6;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileMedium_weighths1_var1;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileMedium_weighths2_var2;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileMedium_weighths3_var3;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileMedium_transl123;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileMedium_sqrtvar123;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileLow_weighths1_var1;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileLow_weighths2_var2;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileLow_sqrtvar12;
		[HideInInspector, SerializeField] private Vector4 _PSSProfileLow_transl;

		[HideInInspector]
		public bool needsRenormalize = true;
		[HideInInspector,]
		public bool needsRecalcDerived = true;

		[HideInInspector]
		public Texture2D referenceTexture;

		/// <summary>
		/// Normalize color weights of the main 6 gaussians.
		/// </summary>
		public void NormalizeOriginalWeights() {
			RecalculateDerived();

			gauss6_1.x = _PSSProfileHigh_weighths1_var1.x;
			gauss6_1.y = _PSSProfileHigh_weighths1_var1.y;
			gauss6_1.z = _PSSProfileHigh_weighths1_var1.z;
			gauss6_2.x = _PSSProfileHigh_weighths2_var2.x;
			gauss6_2.y = _PSSProfileHigh_weighths2_var2.y;
			gauss6_2.z = _PSSProfileHigh_weighths2_var2.z;
			gauss6_3.x = _PSSProfileHigh_weighths3_var3.x;
			gauss6_3.y = _PSSProfileHigh_weighths3_var3.y;
			gauss6_3.z = _PSSProfileHigh_weighths3_var3.z;
			gauss6_4.x = _PSSProfileHigh_weighths4_var4.x;
			gauss6_4.y = _PSSProfileHigh_weighths4_var4.y;
			gauss6_4.z = _PSSProfileHigh_weighths4_var4.z;
			gauss6_5.x = _PSSProfileHigh_weighths5_var5.x;
			gauss6_5.y = _PSSProfileHigh_weighths5_var5.y;
			gauss6_5.z = _PSSProfileHigh_weighths5_var5.z;
			gauss6_6.x = _PSSProfileHigh_weighths6_var6.x;
			gauss6_6.y = _PSSProfileHigh_weighths6_var6.y;
			gauss6_6.z = _PSSProfileHigh_weighths6_var6.z;

			needsRenormalize = false;
		}

		public void RecalculateDerived() {
			// take original 6 gaussians and normalize their color weights
			Vector3 sum = Vector3.zero;

			Vector3 w1 = gauss6_1;
			Vector3 w2 = gauss6_2;
			Vector3 w3 = gauss6_3;
			Vector3 w4 = gauss6_4;
			Vector3 w5 = gauss6_5;
			Vector3 w6 = gauss6_6;

			sum += w1;
			sum += w2;
			sum += w3;
			sum += w4;
			sum += w5;
			sum += w6;

			w1.x /= sum.x;
			w1.y /= sum.y;
			w1.z /= sum.z;
			w2.x /= sum.x;
			w2.y /= sum.y;
			w2.z /= sum.z;
			w3.x /= sum.x;
			w3.y /= sum.y;
			w3.z /= sum.z;
			w4.x /= sum.x;
			w4.y /= sum.y;
			w4.z /= sum.z;
			w5.x /= sum.x;
			w5.y /= sum.y;
			w5.z /= sum.z;
			w6.x /= sum.x;
			w6.y /= sum.y;
			w6.z /= sum.z;

			float lum1 = new Color(w1.x,w1.y,w1.z).grayscale;
			float lum2 = new Color(w2.x,w2.y,w2.z).grayscale;
			float lum3 = new Color(w3.x,w3.y,w3.z).grayscale;
			float lum4 = new Color(w4.x,w4.y,w4.z).grayscale;
			float lum5 = new Color(w5.x,w5.y,w5.z).grayscale;
			float lum6 = new Color(w6.x,w6.y,w6.z).grayscale;

			// pack the weights of each gaussian component with variance
			_PSSProfileHigh_weighths1_var1 = new Vector4(w1.x, w1.y, w1.z, gauss6_1.w);
			_PSSProfileHigh_weighths2_var2 = new Vector4(w2.x, w2.y, w2.z, gauss6_2.w);
			_PSSProfileHigh_weighths3_var3 = new Vector4(w3.x, w3.y, w3.z, gauss6_3.w);
			_PSSProfileHigh_weighths4_var4 = new Vector4(w4.x, w4.y, w4.z, gauss6_4.w);
			_PSSProfileHigh_weighths5_var5 = new Vector4(w5.x, w5.y, w5.z, gauss6_5.w);
			_PSSProfileHigh_weighths6_var6 = new Vector4(w6.x, w6.y, w6.z, gauss6_6.w);
			// reduce to 3 gaussians: weights summed directly, respective variances weight-summed accordingly
			// NB: no need to renormalize, the total sum is still white.
			_PSSProfileMedium_weighths1_var1 = new Vector4(w1.x+w2.x, w1.y+w2.y, w1.z+w2.z, (gauss6_1.w*lum1 + gauss6_2.w*lum2) / (lum1+lum2));
			_PSSProfileMedium_weighths2_var2 = new Vector4(w3.x+w4.x, w3.y+w4.y, w3.z+w4.z, (gauss6_3.w*lum3 + gauss6_4.w*lum4) / (lum3+lum4));
			_PSSProfileMedium_weighths3_var3 = new Vector4(w5.x+w6.x, w5.y+w6.y, w5.z+w6.z, (gauss6_5.w*lum5 + gauss6_6.w*lum6) / (lum5+lum6));
			// and to 2 gaussians...
			_PSSProfileLow_weighths1_var1 = new Vector4(w1.x+w2.x+w3.x, w1.y+w2.y+w3.y, w1.z+w2.z+w3.z, (gauss6_1.w*lum1 + gauss6_2.w*lum2 + gauss6_3.w*lum3) / (lum1+lum2+lum3));
			_PSSProfileLow_weighths2_var2 = new Vector4(w4.x+w5.x+w6.x, w4.y+w5.y+w6.y, w4.z+w5.z+w6.z, (gauss6_4.w*lum4 + gauss6_5.w*lum5 + gauss6_6.w*lum6) / (lum4+lum5+lum6));

			// Pre-compute square root of variance
			_PSSProfileHigh_sqrtvar1234.x = Mathf.Sqrt(_PSSProfileHigh_weighths1_var1.w);
			_PSSProfileHigh_sqrtvar1234.y = Mathf.Sqrt(_PSSProfileHigh_weighths2_var2.w);
			_PSSProfileHigh_sqrtvar1234.z = Mathf.Sqrt(_PSSProfileHigh_weighths3_var3.w);
			_PSSProfileHigh_sqrtvar1234.w = Mathf.Sqrt(_PSSProfileHigh_weighths4_var4.w);
			_PSSProfileMedium_sqrtvar123.x = Mathf.Sqrt(_PSSProfileMedium_weighths1_var1.w);
			_PSSProfileMedium_sqrtvar123.y = Mathf.Sqrt(_PSSProfileMedium_weighths2_var2.w);
			_PSSProfileMedium_sqrtvar123.z = Mathf.Sqrt(_PSSProfileMedium_weighths3_var3.w);
			_PSSProfileLow_sqrtvar12.x = Mathf.Sqrt(_PSSProfileLow_weighths1_var1.w);
			_PSSProfileLow_sqrtvar12.y = Mathf.Sqrt(_PSSProfileLow_weighths2_var2.w);
			_PSSProfileHigh_transl123_sqrtvar5.w = Mathf.Sqrt(_PSSProfileHigh_weighths5_var5.w);
			_PSSProfileHigh_transl456_sqrtvar6.w = Mathf.Sqrt(_PSSProfileHigh_weighths6_var6.w);

			// Pre-compute exponential factors for translucency.
			// See the shader for explanation.
			float minusLog2E = -1.44269504088896340736f; // = -log2(e)
			_PSSProfileHigh_transl123_sqrtvar5.x = minusLog2E / gauss6_1.w;
			_PSSProfileHigh_transl123_sqrtvar5.y = minusLog2E / gauss6_2.w;
			_PSSProfileHigh_transl123_sqrtvar5.z = minusLog2E / gauss6_3.w;
			_PSSProfileHigh_transl456_sqrtvar6.x = minusLog2E / gauss6_4.w;
			_PSSProfileHigh_transl456_sqrtvar6.y = minusLog2E / gauss6_5.w;
			_PSSProfileHigh_transl456_sqrtvar6.z = minusLog2E / gauss6_6.w;
			_PSSProfileMedium_transl123.x = minusLog2E / _PSSProfileMedium_weighths1_var1.w;
			_PSSProfileMedium_transl123.y = minusLog2E / _PSSProfileMedium_weighths2_var2.w;
			_PSSProfileMedium_transl123.z = minusLog2E / _PSSProfileMedium_weighths3_var3.w;


			Vector3 varianceRGB;
			varianceRGB.x = gauss6_1.w*w1.x + gauss6_2.w*w2.x + gauss6_3.w*w3.x + gauss6_4.w*w4.x + gauss6_5.w*w5.x + gauss6_6.w*w6.x;
			varianceRGB.y = gauss6_1.w*w1.y + gauss6_2.w*w2.y + gauss6_3.w*w3.y + gauss6_4.w*w4.y + gauss6_5.w*w5.y + gauss6_6.w*w6.y;
			varianceRGB.z = gauss6_1.w*w1.z + gauss6_2.w*w2.z + gauss6_3.w*w3.z + gauss6_4.w*w4.z + gauss6_5.w*w5.z + gauss6_6.w*w6.z;


			_PSSProfileLow_transl.x = minusLog2E / varianceRGB.x;
			_PSSProfileLow_transl.y = minusLog2E / varianceRGB.y;
			_PSSProfileLow_transl.z = minusLog2E / varianceRGB.z;

			// weighted average variance for when we need to be cheapstakes and sample only once
			//_PSSProfileLow_transl.w = gauss6_1.w*lum1 + gauss6_2.w*lum2 + gauss6_3.w*lum3 + gauss6_4.w*lum4 + gauss6_5.w*lum5 + gauss6_6.w*lum6;

			needsRecalcDerived = false;
		}

		public void ApplyProfile(Material material) {
			ApplyProfile(material, false);
		}

		public void ApplyProfile(Material material, bool noWarn) {
			if (needsRecalcDerived)
				RecalculateDerived();

			material.SetVector("_PSSProfileHigh_weighths1_var1", _PSSProfileHigh_weighths1_var1);
			material.SetVector("_PSSProfileHigh_weighths2_var2", _PSSProfileHigh_weighths2_var2);
			material.SetVector("_PSSProfileHigh_weighths3_var3", _PSSProfileHigh_weighths3_var3);
			material.SetVector("_PSSProfileHigh_weighths4_var4", _PSSProfileHigh_weighths4_var4);
			material.SetVector("_PSSProfileHigh_weighths5_var5", _PSSProfileHigh_weighths5_var5);
			material.SetVector("_PSSProfileHigh_weighths6_var6", _PSSProfileHigh_weighths6_var6);
			material.SetVector("_PSSProfileHigh_sqrtvar1234", _PSSProfileHigh_sqrtvar1234);
			material.SetVector("_PSSProfileHigh_transl123_sqrtvar5", _PSSProfileHigh_transl123_sqrtvar5);
			material.SetVector("_PSSProfileHigh_transl456_sqrtvar6", _PSSProfileHigh_transl456_sqrtvar6);
			material.SetVector("_PSSProfileMedium_weighths1_var1", _PSSProfileMedium_weighths1_var1);
			material.SetVector("_PSSProfileMedium_weighths2_var2", _PSSProfileMedium_weighths2_var2);
			material.SetVector("_PSSProfileMedium_weighths3_var3", _PSSProfileMedium_weighths3_var3);
			material.SetVector("_PSSProfileMedium_transl123", _PSSProfileMedium_transl123);
			material.SetVector("_PSSProfileMedium_sqrtvar123", _PSSProfileMedium_sqrtvar123);
			material.SetVector("_PSSProfileLow_weighths1_var1", _PSSProfileLow_weighths1_var1);
			material.SetVector("_PSSProfileLow_weighths2_var2", _PSSProfileLow_weighths2_var2);
			material.SetVector("_PSSProfileLow_sqrtvar12", _PSSProfileLow_sqrtvar12);
			material.SetVector("_PSSProfileLow_transl", _PSSProfileLow_transl);
		}
	}
}