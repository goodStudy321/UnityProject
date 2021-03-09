using UnityEngine;
#if UNITY_EDITOR
	using UnityEditor;
#endif
using System.Collections;
using System.Collections.Generic;
using System.Linq;

public class MeshCombineUtilityAFS {
	
	public struct MeshInstance
	{
		public Mesh      mesh;
		public int       subMeshIndex;
		public Matrix4x4 transform;
		
		public Vector3   groundNormal;
		public float     scale;
		public Vector3   pivot;
	}
	
	public static Mesh Combine (MeshInstance[] combines, bool bakeGroundLightingGrass, bool bakeGroundLightingFoliage, float randomBrightness, float randomPulse, float randomBending, float randomFluttering, Color HealthyColor, Color DryColor, float NoiseSpread, bool bakeScale, bool simplyCombine, float NoiseSpreadFoliage, bool createUniqueUV2, bool useUV4, bool bakePivots
)
	{
		int vertexCount = 0;
		int triangleCount = 0;

		int instances = combines.Length;
		
		for (int i = 0; i < instances; i++) {
			if (combines[i].mesh)
			{
				vertexCount += combines[i].mesh.vertexCount;
				triangleCount += combines[i].mesh.GetTriangles(combines[i].subMeshIndex).Length;
			}
		}

		Vector3[] vertices = new Vector3[vertexCount] ;
		Vector3[] normals = new Vector3[vertexCount] ;
		Vector4[] tangents = new Vector4[vertexCount] ;

		Vector3[] uvGrass = new Vector3[vertexCount];
		Vector2[] uv = new Vector2[vertexCount];
//		
		Vector2[] uv1 = new Vector2[vertexCount];
		Color[] colors = new Color[vertexCount];
//
		Vector2[] uv4 = new Vector2[vertexCount];
		
		int[] triangles = new int[triangleCount];
		int offset = 0;

		bool copyUV4 = false;

		for (int i = 0; i < instances; i++) {
			if(combines[i].mesh){
				int count = combines[i].mesh.vertexCount;
				Vector3[] combine_vertices = combines[i].mesh.vertices;
				Copy(count, combine_vertices, vertices, ref offset, combines[i].transform);
				combine_vertices = null;
			}
		}
		offset = 0;

		for (int i = 0; i < instances; i++) {
			if(combines[i].mesh){
				Matrix4x4 invTranspose = combines[i].transform;
				invTranspose = invTranspose.inverse.transpose;
				if (bakeGroundLightingGrass) {
					CopyNormalGround (combines[i].mesh.vertexCount, combines[i].mesh.normals, normals, ref offset, invTranspose, combines[i].groundNormal);
				}
				else {
					CopyNormal(combines[i].mesh.vertexCount, combines[i].mesh.normals, normals, ref offset, invTranspose);
				}
			}
		}
		offset = 0;

		for (int i = 0; i < instances; i++) {
			if(combines[i].mesh){
				Matrix4x4 invTranspose = combines[i].transform;
				invTranspose = invTranspose.inverse.transpose;
				CopyTangents(combines[i].mesh.vertexCount, combines[i].mesh.tangents, tangents, ref offset, invTranspose);
			}
		}
		offset = 0;

		for (int i = 0; i < instances; i++) {
			if(combines[i].mesh){
				if (bakeGroundLightingGrass) {
					CopyUVGrass(combines[i].mesh.vertexCount, combines[i].mesh.uv, uvGrass, ref offset, combines[i].pivot );
				}
				else {
					Copy(combines[i].mesh.vertexCount, combines[i].mesh.uv, uv, ref offset);
				}
			}
		}
		offset = 0;

		// only needed when using the foliage shader ground lighting version
		if (bakeGroundLightingFoliage) {
			for (int i = 0; i < instances; i++) {
				if(combines[i].mesh){
					Copy_uv1(combines[i].mesh.vertexCount, combines[i].mesh.uv, uv1, ref offset, new Vector2(combines[i].groundNormal.x, combines[i].groundNormal.z));
				}
			}
			offset = 0;
		}
		
		// Copy uv4 
		for (int i = 0; i < instances; i++) {
			if(combines[i].mesh){
				if (combines[i].mesh.uv4 != null && useUV4)
				{
					copyUV4 = true;
					Copy_uv4(combines[i].mesh.vertexCount, combines[i].mesh.uv4, uv4, ref offset, combines[i].scale, bakeScale, combines[i].pivot, NoiseSpreadFoliage, randomBending);
				}
			}
		}
		offset = 0;
		

		for (int i = 0; i < instances; i++) {
			if(combines[i].mesh){
				// either add healthy and dry colors (grass shader)
				if (bakeGroundLightingGrass) {
					CopyColors_grass(combines[i].mesh.vertexCount, combines[i].mesh.colors, colors, ref offset, HealthyColor, DryColor, NoiseSpread, combines[i].pivot );
				}
				// or simply add random color to create more variety (r,a and b) and bake scale
				else {
					CopyColors(combines[i].mesh.vertexCount, combines[i].mesh.colors, colors, ref offset, combines[i].scale, bakeScale, combines[i].pivot, NoiseSpreadFoliage, randomPulse, randomFluttering, randomBrightness, randomBending, copyUV4);
				}
			}
		}
		offset = 0;

	//	bake pivots
		Vector4[] combinedUV4 = {Vector4.zero};
		Vector2[] simpleUV4 = {Vector2.zero};
		if(bakePivots && !bakeGroundLightingGrass) {
			combinedUV4 = new Vector4[vertexCount];
			simpleUV4 = new Vector2[vertexCount];
			for (int i = 0; i < instances; i++) {
				if(combines[i].mesh){
					BakePivot(combines[i].mesh.vertexCount, combines[i].mesh.vertices, combines[i].mesh.uv4, combinedUV4, simpleUV4, ref offset, combines[i].scale, combines[i].transform, combines[i].pivot, copyUV4);
				}
			}
		}

	//	copy triangles
		int triangleOffset=0;
		int vertexOffset=0;
		int[] inputtriangles;

		for (int i = 0; i < instances; i++) {
			if(combines[i].mesh){
				inputtriangles = combines[i].mesh.GetTriangles(combines[i].subMeshIndex);
				int length = inputtriangles.Length;
				// http://answers.unity3d.com/questions/416049/huge-gc-overhead-when-accessing-trisverts-from-mes.html
				// for (int i=0;i<inputtriangles.Length;i++) // causes GC!
				for (int j = 0; j < length; j++) // causes GC!
				{
					triangles[j+triangleOffset] = inputtriangles[j] + vertexOffset;
				}
				triangleOffset += length;
				vertexOffset += combines[i].mesh.vertexCount;
			}
		}
		// Clean up
		inputtriangles = null;

		
		Mesh mesh = new Mesh();
		mesh.name = "Combined Mesh";
		mesh.vertices = vertices;
		mesh.normals = normals;
		mesh.colors = colors;
		if (bakeGroundLightingGrass) {
			mesh.SetUVs(0, uvGrass.ToList() );
		}
		else {
			mesh.uv = uv;
		}
		// only needed for foliage shader, skip it on grass and plants using the regular shader
		if (bakeGroundLightingFoliage) {
			mesh.uv2 = uv1;
		}

		if (copyUV4 && !bakeGroundLightingGrass) {
			if (bakePivots) {
				var uv4List = combinedUV4.ToList();
				mesh.SetUVs(3, uv4List);
				//
				combinedUV4 = null;
				uv4List = null;
			}
			else {
				mesh.uv4 = uv4;		
			}
		}
		else if (bakePivots && !bakeGroundLightingGrass) {
			mesh.uv4 = simpleUV4;
		}

		mesh.tangents = tangents;
		mesh.triangles = triangles;

		#if UNITY_EDITOR
			if(createUniqueUV2 && !bakeGroundLightingFoliage) {
				Unwrapping.GenerateSecondaryUVSet(mesh);
			}
		#endif

		// Clean up
		vertices = null;
		normals = null;
		tangents = null;
		triangles = null;
		uv = null;
		uv1 = null;
		colors = null;
		triangles = null;
		combinedUV4 = null;
		simpleUV4 = null;

		return mesh;
	}
	
	static void Copy (int vertexcount, Vector3[] src, Vector3[] dst, ref int offset, Matrix4x4 transform)
	{
		int arrayLength = src.Length;
		for (int i=0;i<arrayLength;i++)
			dst[i+offset] = transform.MultiplyPoint3x4(src[i]);
		offset += vertexcount;
	}

// copy mesh normals
	static void CopyNormal (int vertexcount, Vector3[] src, Vector3[] dst, ref int offset, Matrix4x4 transform)
	{
		for (int i=0;i<src.Length;i++)
			dst[i+offset] = transform.MultiplyVector(src[i]).normalized;
		offset += vertexcount;
	}
	
// overwrite the mesh’s normals by the groundNormal (grass shader)
	static void CopyNormalGround (int vertexcount, Vector3[] src, Vector3[] dst, ref int offset, Matrix4x4 transform, Vector3 groundNormal)
	{
		for (int i=0;i<src.Length;i++)
			dst[i+offset] = groundNormal;
		offset += vertexcount;
	}

// copy uvs
	static void Copy (int vertexcount, Vector2[] src, Vector2[] dst, ref int offset)
	{
		for (int i=0;i<src.Length;i++)
			dst[i+offset] = src[i];
		offset += vertexcount;
	}

// copy uvs for Grass
	static void CopyUVGrass (int vertexcount, Vector2[] src, Vector3[] dst, ref int offset, Vector3 pivot)
	{
		for (int i=0;i<src.Length;i++) {
			dst[i+offset].x = src[i].x;
			dst[i+offset].y = src[i].y;
			// bake instance variance (range 0.0 - 1.0)
			dst[i+offset].z = ((pivot.x + pivot.z) * 3.3f) % 1.0f;
		}
		offset += vertexcount;
	}

// copy uv4s
	static void Copy_uv4 (int vertexcount, Vector2[] src, Vector2[] dst, ref int offset, float scale, bool bakeScale, Vector3 pivot, float NoiseSpread, float randomBending)
	{
		float noise = Mathf.PerlinNoise(Mathf.Abs(pivot.x), Mathf.Abs(pivot.y) );
		if (!bakeScale) {
			scale = 1.0f;
		}
		for (int i=0;i<src.Length;i++) {
			dst[i+offset] = new Vector2(src[i].x * scale * (1.0f - randomBending * noise ), src[i].y);
		}
		offset += vertexcount;
	}
	
// store ground normal in uv1 (foliage shader)
	static void Copy_uv1 (int vertexcount, Vector2[] src, Vector2[] dst, ref int offset, Vector2 groundNormal)
	{
		for (int i=0;i<src.Length;i++)
			dst[i+offset] = groundNormal;
		offset += vertexcount;
	}
	
// add random colors (rgba) to create more variety (foliage shader)
	static void CopyColors (int vertexcount, Color[] src, Color[] dst, ref int offset, float scale, bool bakeScale, Vector3 pivot, float NoiseSpread, float randomPulse, float randomFluttering, float randomBrightness, float randomBending, bool copyUV4)
	{
		float noise = Mathf.PerlinNoise(pivot.x * pivot.x * NoiseSpread, pivot.z * pivot.z * NoiseSpread);
		//float noise1 = Mathf.PerlinNoise(pivot.x * pivot.x * Mathf.Abs(pivot.x), pivot.z * pivot.z * Mathf.Abs(pivot.z) );
		for (int i=0;i<src.Length;i++) {
			// compress ambient occlusion value and add scale
			// src[i].a = (4.0f * Mathf.Clamp(src[i].a * 255.0f / 4.0f, 0.0f, 63.0f) + Scale ) / 255.0f;
			// phase (only plus)
			src[i].r += randomPulse * noise * 0.25f;
			//fluttering (plus / minus)
			src[i].g = src[i].g * (1 + randomFluttering * (noise - 0.5f) );
			//bending (only plus)
			if (bakeScale) {
				// scale
				src[i].b = src[i].b * scale * (1 + randomBending * noise);
			}
			else {
				src[i].b = src[i].b * (1 + randomBending * noise);	
			}
			//	add variation per mesh 
			if (copyUV4){
				src[i].b = randomPulse * noise; //noise1 * noise1;
			}
			//brightness (only darken)
			src[i].a = src[i].a - (noise * randomBrightness);
			dst[i+offset] = src[i];
		}
		offset += vertexcount;
	}
	
// deprecated: store ground normal (grass shader translucency) and add random colors (r and a) to create more variety
	static void CopyColors_groundNormal_old (int vertexcount, Color[] src, Color[] dst, ref int offset, Color RandColor, Vector2 groundNormal)
	{
		for (int i=0;i<src.Length;i++) {
			dst[i+offset] = src[i] + RandColor;
			dst[i+offset].r = groundNormal.x;
			dst[i+offset].g = groundNormal.y;
		}
		offset += vertexcount;
	}
	
// store dry and healthy colors (grass shader) / src.color.b contains ambient occlusion
	static void CopyColors_grass (int vertexcount, Color[] src, Color[] dst, ref int offset, Color HealthyColor, Color DryColor, float NoiseSpread, Vector3 pivot)
	{
		Color BlendColor = Color.Lerp (HealthyColor, DryColor, Mathf.PerlinNoise(pivot.x * NoiseSpread, pivot.z * NoiseSpread) );
		
		for (int i=0;i<src.Length;i++) {
			dst[i+offset].a = src[i].a;
			dst[i+offset].r = Mathf.Lerp (1.0f, BlendColor.r, BlendColor.a) * src[i].b;
			dst[i+offset].g = Mathf.Lerp (1.0f, BlendColor.g, BlendColor.a) * src[i].b;
			dst[i+offset].b = Mathf.Lerp (1.0f, BlendColor.b, BlendColor.a) * src[i].b;
		}
		offset += vertexcount;
	}
	
	static void CopyTangents (int vertexcount, Vector4[] src, Vector4[] dst, ref int offset, Matrix4x4 transform)
	{
		for (int i=0;i<src.Length;i++)
		{
			Vector4 p4 = src[i];
			Vector3 p = new Vector3(p4.x, p4.y, p4.z);
			p = transform.MultiplyVector(p).normalized;
			dst[i+offset] = new Vector4(p.x, p.y, p.z, p4.w);
		}
			
		offset += vertexcount;
	}

//	bake pivots
	
	// Helper method to go from a float to int
	static int ConvertInt(float value)
	{
	    //Scale and bias
	    value = (value + 1.0f) * 0.5f;
	    return (int)(value*255.0f);
	}

	static void BakePivot (int vertexcount, Vector3[] vertex, Vector2[] src, Vector4[] dst, Vector2[] simpleUV4, ref int offset, float scale, Matrix4x4 transform, Vector3 pivot, bool copyUV4) {
		Vector3 newPivot = transform.MultiplyPoint3x4(new Vector3(0,0,0));
		Vector3 newPosition;
		Vector3 normalToPivot;
		float distance;
		uint packedColor;
		float packedNormal;
		//float arraylength = (copyUV4) ? src.Length : simpleUV4.Length;
		for (int i = 0; i < vertex.Length; i++)
		{
			newPosition = transform.MultiplyPoint3x4(vertex[i]);
			normalToPivot = newPosition - newPivot;
			distance = Vector3.Magnitude(normalToPivot);
			normalToPivot = Vector3.Normalize(-normalToPivot);
			// normal packed into float: all 3 components as we need the sign
			// https://www.opengl.org/discussion_boards/showthread.php/162035-GLSL-packing-a-normal-in-a-single-float
			packedColor = (uint)(  (ConvertInt(normalToPivot.x) << 16) | ( ConvertInt(normalToPivot.y) << 8) | ConvertInt(normalToPivot.z) );
			packedNormal = (float) ( ((double)packedColor) / ((double) (1 << 24)) );
			// Bending already stored in UV4?
			if(copyUV4) {
				dst[i+offset] = new Vector4(src[i].x, src[i].y, packedNormal, distance); // src[i] out of index????
			}
			// If not Vector2 is enough
			else {
				simpleUV4[i+offset] = new Vector2(packedNormal, distance);
			}
		}
		offset += vertexcount;
	}
}
