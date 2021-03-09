using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NpcGenerater : MonoBehaviour
{
	public GameObject NpcPrefab;
	public int NpcCount;

	// Use this for initialization
	void Start ()
	{
		for (int i = 0; i < NpcCount; i++)
		{
			Vector3 pos = new Vector3 (Random.Range (-50f, 50f), 15f, Random.Range (-15f, 15f));
			GameObject npc = Instantiate (NpcPrefab, pos, Quaternion.Euler (0, Random.Range (0f, 360f), 0));
			npc.transform.SetParent (transform);
		}
	}
}