# DirectX12 Simple Raytracing HLSL Shader

Implemented raytracing on spheres using HLSL shader, not DXR.

<img title="" src="/Images/image3.png" alt="image3.png" width="622">

```hlsl
float4 PS(VertexOut pin) : SV_Target {
...
    float3 tracedLight = ReflectTraceRay(gEyePosW, -toEyeW, gLights[0], gSpheres, gPlanes[0], 3);

    float4 litColor;
    litColor.rgb = tracedLight;

    // Common convention to take alpha from diffuse material.
    litColor.a = gDiffuseAlbedo.a;

    return litColor;
}
```

```hlsl

```

Since HLSL shader does not support recursive functions, this raytracing is implemented using the for statement.

## Reference

[&quot;Introduction to 3D Game Programming with DirectX 12&quot;](https://github.com/d3dcoder/d3d12book)
