# DirectX12 Simple Raytracing HLSL Shader

Implemented raytracing on spheres using HLSL shader, not DXR.

<img title="" src="/Images/image2.png" alt="image1.png" width="622">

```hlsl
float4 PS(VertexOut pin) : SV_Target {
...
    Material mat = { gDiffuseAlbedo, gReflectance, gShininess };
    
    float3 tracedLight = ReflectTraceRay(gEyePosW, -toEyeW, gLights[0], gSpheres, gPlanes[0], mat, 3);

    float4 litColor;
    litColor.rgb = tracedLight;

    // Common convention to take alpha from diffuse material.
    litColor.a = gDiffuseAlbedo.a;

    return litColor;
}
```

```hlsl
float3 ReflectTraceRay(float3 startPoint, float3 direction, Light light, Sphere spheres[MaxSpheres], Plane plane, Material mat, int num) {
    float3 color = 0.0f;

    float3 p = startPoint;
    float3 d = direction;
    float r = mat.Reflectance;
    float3 backgroundColor = 0.0f;

    for (int i = 0; i < num; i++) {
        TandSphere ts = ClosestIntersection(p, d, spheres);
        float plane_t = IntersectRayPlane(p, d, plane);

        if ((ts.t < 0.001f || ts.t > 999.0f) && plane_t < 0.001f) {
            color += backgroundColor;
            break;
        }
        else {
            float3 newPoint;
            float3 normal;
            if (ts.t < 999.0f && ts.t > 0.01f) {
                if (plane_t < 0.01f) {
                    //min = sphere
                    newPoint = p + ts.t * d;
                    normal = (newPoint - ts.sphere.CenterPosition) / ts.sphere.Radius;
                }
                else {
                    if (ts.t > plane_t) {
                        //min = plane
                        newPoint = p + plane_t * d;
                        normal = plane.Normal;
                    }
                    else {
                        //min = sphere
                        newPoint = p + ts.t * d;
                        normal = (newPoint - ts.sphere.CenterPosition) / ts.sphere.Radius;
                    }
                }
            }
            else {
                //min == plane
                newPoint = p + plane_t * d;
                normal = plane.Normal;
            }


            if (i == 0) {
                //fisrt ray = only get local color
                float3 local_color = mat.DiffuseAlbedo.rgb * CalcLighting(newPoint, normal, d, light, spheres, plane, mat);
                color += local_color;
            }
            else {
                //reflected ray = trace ray and get color
                float3 reflected_color = TraceRay(p, d, light, spheres, plane, mat);
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
