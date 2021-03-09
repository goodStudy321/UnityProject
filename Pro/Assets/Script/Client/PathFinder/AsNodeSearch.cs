using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

public class AsNodeSearch : IComparable<AsNodeSearch>
{
    private int id = 0;
    public int F = 0;
    public float Fv = 0F;

    public int ID
    {
        get
        {
            return id;
        }
        private set
        {
            this.id = value;
        }
    }
    
    public AsNodeSearch(int i, int f)
    {
        id = i;
        F = f;
    }

    public AsNodeSearch(int i, float f)
    {
        id = i;
        Fv = f;
    }


    public int CompareTo(AsNodeSearch b)
    {
        return this.F.CompareTo(b.F);
    }
}
