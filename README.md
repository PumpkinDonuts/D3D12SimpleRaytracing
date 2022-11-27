# DirectX12 Simple Raytracing HLSL Shader

Implemented raytracing on spheres using HLSL shader, not DXR.

<img title="" src="/Images/image2.png" alt="image1.png" width="622">

```hlsl
float4 PS(VertexOut pin) : SV_Target {
...
    Material mat = { gDiffuseAlbedo, gReflectance, gShininess };
    //float3 tracedLight = TraceRay(gEyePosW, -toEyeW, gLights[0], gSpheres, mat);
    float3 tracedLight = ReflectTraceRay(gEyePosW, -toEyeW, gLights[0], gSpheres, mat, 2);

    float4 litColor;
    litColor.rgb = tracedLight;

    // Common convention to take alpha from diffuse material.
    litColor.a = gDiffuseAlbedo.a;

    return litColor;
}
```

```hlsl
float3 ReflectTraceRay(float3 startPoint, float3 direction, Light light, Sphere spheres[MaxSpheres], Material mat, int num){
    float3 color = 0.0f;

    float3 p = startPoint;
    float3 d = direction;
    float r = mat.Reflectance;

    for (int i = 0; i < num; i++) {
        float3 backgroundColor = 0.0f;
        TandSphere ts = ClosestIntersection(p, d, spheres);
        if (ts.t < 0.001f || ts.t > 999.0f) {
            color += backgroundColor;
            break;
        }
        else {
            float3 newPoint = startPoint + ts.t * direction;
            float3 normal = (newPoint - ts.sphere.CenterPosition) / ts.sphere.Radius;

            if (i == 0) {
                //fisrt ray = only get local color
                float3 local_color = mat.DiffuseAlbedo.rgb * CalcLighting(newPoint, normal, d, light, spheres, mat);
                color += local_color;
            }
            else {
                //reflected ray = trace ray and get color
                float3 reflected_color = TraceRay(p, d, light, spheres, mat);
                color +=  reflected_color * pow(r, (float)i);
            }

            //update current point & direction
            p = newPoint;
            d = GetReflection(d, normal);
        }
    }
    return color;
}
```

Since HLSL shader does not support recursive functions, this raytracing is implemented using the for statement.

## Reference

[&quot;Introduction to 3D Game Programming with DirectX 12&quot;](https://github.com/d3dcoder/d3d12book)
