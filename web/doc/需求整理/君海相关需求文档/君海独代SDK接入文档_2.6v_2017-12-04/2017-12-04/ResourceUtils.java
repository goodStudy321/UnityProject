package com.junhai.sdk.utils;

import android.content.Context;

/**
 * Created by weijie on 2015/9/6.
 */
public class ResourceUtils {

    public static int getLayoutId(Context context, String resource) {
        return context.getResources().getIdentifier(resource, "layout", context.getPackageName());
    }

    public static int getStringId(Context context, String resource) {
        return context.getResources().getIdentifier(resource, "string", context.getPackageName());
    }

    public static int getDrawableId(Context context, String resource) {
        return context.getResources().getIdentifier(resource, "drawable", context.getPackageName());
    }

    public static int getStyleId(Context context, String resource) {
        return context.getResources().getIdentifier(resource, "style", context.getPackageName());
    }

    public static int getId(Context context, String resource) {
        return context.getResources().getIdentifier(resource, "id", context.getPackageName());
    }

    public static int getColorId(Context context, String resource) {
        return context.getResources().getIdentifier(resource, "color", context.getPackageName());
    }
}
