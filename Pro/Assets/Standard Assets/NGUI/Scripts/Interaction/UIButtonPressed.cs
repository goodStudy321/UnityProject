using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[AddComponentMenu("NGUI/Interaction/Button Pressed")]
public class UIButtonPressed : MonoBehaviour
{
    public List<GameObject> targets;

    void OnPress(bool pressed)
    {
        for(int i = 0; i < targets.Count; i ++)
        {
            targets[i].SetActive(pressed);
        }
	}
}
