using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ParticleSystemMgr : MonoBehaviour {

    public ParticleSystem mSystem;

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}

    public void SetPos(Vector3 pos)
    {
        this.transform.localPosition = pos;
    }

    public void Simulate()
    {
        if (mSystem == null) return;
        mSystem.Play();
    }
}
