using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

[AttributeUsage(AttributeTargets.Method| AttributeTargets.Property|AttributeTargets.Field)]
public class UnityEditorAttribute : Attribute  {


    public UnityEditorAttribute()
    {
            
    }

}
