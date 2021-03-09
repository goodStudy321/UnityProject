using UnityEngine;
using System.Collections;

namespace JBrothers.PreIntegratedSkinShader2 {
	public class LookupTextureDefinition {
		/// <summary>
		/// kernel name of the compute shader and shader name suffix for non dx11 bake
		/// </summary>
		public string KernelName;

		/// <summary>
		/// parameter name in the skin shader, used when applying a profile to a material
		/// </summary>
		public string ParameterName;

		/// <summary>
		/// Lookup texture format. Mostly to differentiate between rgb32 and argb32 since there's no hdr support at
		/// this time.
		/// </summary>
		public TextureFormat Format = TextureFormat.RGB24;

		/// <summary>
		/// Number of kernel threads dispatched at a time.
		/// </summary>
		//public int KernelThreads = 1;

		public int Width = 256;
		public int Height = 256;

		public bool MipMaps = false;
		/// <summary>
		/// For lookups with mip map trickery when too small mips are useless. When set to 1 the last mip level (1x1)
		/// will be computed as if it was the second to last one and the normalized mip level passed to compute shader
		/// will be scaled down accordingly.
		/// </summary>
		public int MipMapSkipLastNLevels = 0;

		public TextureWrapMode wrapMode = TextureWrapMode.Clamp;

		internal static LookupTextureDefinition[] LookupDefinitions = {
			new LookupTextureDefinition() { KernelName="Direct", ParameterName="_LookupDirect", Format=TextureFormat.RGB24, Width=256, Height=256, MipMaps=true, MipMapSkipLastNLevels=2},
			new LookupTextureDefinition() { KernelName="DirectSM2", ParameterName="_LookupDirectSM2", Format=TextureFormat.ARGB32, Width=128, Height=32},
			//new LookupTextureDefinition() { KernelName="SH", ParameterName="_LookupSH", Format=TextureFormat.ARGB32, Width=256, Height=64, MipMaps=true, MipMapSkipLastNLevels=2},
			//new LookupTextureDefinition() { KernelName="SHSM2", ParameterName="_LookupSHSM2", Format=TextureFormat.ARGB32, Width=256, Height=1},
			new LookupTextureDefinition() { KernelName="SH", ParameterName="_LookupSH", Format=TextureFormat.ARGB32, Width=256, Height=1},
			new LookupTextureDefinition() { KernelName="SpecAO", ParameterName="_LookupSpecAO", Format=TextureFormat.RGB24 /*could be Alpha8, but lookup generation doesn't support it ATM*/, Width=32, Height=32},

		};
	}
}
