#define MaxLights 16
#define MaxSpheres 10

struct Light {
    float3 Strength;
    float FalloffStart; // point/spot light only
    float3 Direction;   // directional/spot light only
    float FalloffEnd;   // point/spot light only
    float3 Position;    // point light only
    float SpotPower;    // spot light only
};

struct Material {
    float4 DiffuseAlbedo;
    float Reflectance;
    float Shininess;
};

struct Sphere {
    float3 CenterPosition;
    float Radius;
    float4 DiffuseAlbedo;
    float Reflectance;
    float Shininess;
};

struct Plane {
    float3 CenterPosition;
    float3 Normal;
    float3 SpanW;
    float3 SpanH;
    float4 DiffuseAlbedo;
    float Reflectance;
    float Shininess;
};

struct TandSphere {
    float t;
    Sphere sphere;
};

float3 GetReflection(float3 direction, float3 normal) {
    //proj = dot(normal, direction) * normal
    //reflection = (direction - proj) + (-proj) = direction - 2proj
    float3 new_dir = direction - 2 * normal * dot(normal, direction);
    return new_dir / length(new_dir);
}

float IntersectRaySphere(float3 startPoint, float3 direction, Sphere sphere) {
    float3 sphereCenter = sphere.CenterPosition;
    float sphereRadius = sphere.Radius;

    float3 diffCenter = sphereCenter - startPoint;

    //R^2 = t^2 * (dir^2) - 2t * (diff*dir) + diff^2
    float a = dot(direction, direction);
    float b = -2.0f * dot(direction, diffCenter);
    float c = dot(diffCenter, diffCenter) - sphereRadius * sphereRadius;

    float b24ac = b * b - 4 * a * c;

    if (b24ac < 0.0f) {
        return -1.0f;
    }

    if (abs(b24ac) < 0.001f) {
        return -b / (2 * a);
    }
    float sqrt = pow(b24ac, 0.5f);

    //a must > 0
    float t1 = (-b - sqrt) / (2.0f * a);
    float t2 = (-b + sqrt) / (2.0f * a);

    // t2 > t1
    if (t1 < 0.001f) {
        return t2;
    }
    else {
        return t1;
    }
}

float IntersectRayPlane(float3 startPoint, float3 direction, Plane plane) {
    float3 planeCenter = plane.CenterPosition;
    float3 planeNormal = plane.Normal;

    float3 diffCenter = planeCenter - startPoint;

    //t*dir = diffCenter + (w_on_plane + h_on_plane);
    //t*dot(dir,normal) = dot(diffCenter, normal);
    //t = dot(diffCenter,normal) / dot(dir,normal) ;
    //if abs (dot(t*dir - diffCenter, plane.SpanW)) > 1 : return -1;
    //if abs (dot(t*dir - diffCenter, plane.SpanH)) > 1 : return -1;

    float t = dot(diffCenter, planeNormal) / dot(direction, planeNormal);

    if (abs(dot(t * direction - diffCenter, plane.SpanW)) > length(plane.SpanW) * length(t * direction - diffCenter)) { return -1.0f; }
    if (abs(dot(t * direction - diffCenter, plane.SpanH)) > length(plane.SpanH) * length(t * direction - diffCenter)) { return -1.0f; }

    return t;
}

TandSphere ClosestIntersection(float3 startPoint, float3 direction, Sphere spheres[MaxSpheres]) {
    TandSphere ts;
    float t_min = 1000.0f;
    Sphere s_min;
    float3 zero = 0.0f;
    s_min.CenterPosition = zero;
    s_min.Radius = 0.0f;

    int i = 0;
    for (i = 0; i < MaxSpheres; i++) {
        float t = IntersectRaySphere(startPoint, direction, spheres[i]);

        if (t < 0.001f) {
            continue;
        }
        
        if (t < t_min) {
            t_min = t;
            s_min.CenterPosition = spheres[i].CenterPosition;
            s_min.Radius = spheres[i].Radius;
            s_min.DiffuseAlbedo = spheres[i].DiffuseAlbedo;
            s_min.Reflectance = spheres[i].Reflectance;
            s_min.Shininess = spheres[i].Shininess;
        }
    }

    ts.t = t_min;
    ts.sphere = s_min;

    return ts;
}

float3 CalcLighting(float3 pos, float3 normal, float3 view, Light light, Sphere spheres[MaxSpheres], Plane plane) {
    float3 i = 0.0f;
    float Shininess = 10.0f;
    //shadow check
    //Sphere
    TandSphere ts = ClosestIntersection(pos, -light.Direction, spheres);
    //Plane
    float plane_t = IntersectRayPlane(pos, -light.Direction, plane);
    if ((ts.t < 999.0f && ts.t > 0.001f) || plane_t > 0.001f) return i;


    //diffuse
    float n_dot_l = dot(normal, -light.Direction);
    if (n_dot_l > 0.0f) {
        i += light.Strength * n_dot_l / (length(normal) * length(light.Direction));
    }

    if (ts.t < 999.0f && ts.t > 0.01f) {
        if (plane_t < 0.001f) {
            //min = sphere
            Shininess = ts.sphere.Shininess;
        }
        else {
            if (ts.t > plane_t) {
                //min = plane
                Shininess = plane.Shininess;
            }
            else {
                //min = sphere
                Shininess = ts.sphere.Shininess;
            }
        }
    }
    else {
        //min == plane
        Shininess = plane.Shininess;
    }


    //specular
    float3 reflect_l = GetReflection(-light.Direction, normal);
    float light_on_view = dot(reflect_l, view);
    if (light_on_view > 0.0f) {
        i += light.Strength * pow(light_on_view / (length(reflect_l)*length(view)), Shininess);
    }

    return i;
}

float3 TraceRay(float3 startPoint, float3 direction, Light light, Sphere spheres[MaxSpheres], Plane plane) {

    TandSphere ts = ClosestIntersection(startPoint, direction, spheres);
    float plane_t = IntersectRayPlane(startPoint, direction, plane);
    float3 diffuseColor = 0.0f;
    float3 blackColor = 0.0f;

    if ((ts.t < 0.001f || ts.t > 999.0f) && plane_t < 0.001f) {
        return blackColor;
    }
    else {
        float3 newPoint;
        float3 normal;
        if (ts.t < 999.0f && ts.t > 0.01f) {
            if (plane_t < 0.001f) {
                //min = sphere
                newPoint = startPoint + ts.t * direction;
                normal = (newPoint - ts.sphere.CenterPosition) / ts.sphere.Radius;
                diffuseColor = ts.sphere.DiffuseAlbedo.rgb;
            }
            else {
                if (ts.t > plane_t) {
                    //min = plane
                    newPoint = startPoint + plane_t * direction;
                    normal = plane.Normal;
                    diffuseColor = plane.DiffuseAlbedo.rgb;
                }
                else {
                    //min = sphere
                    newPoint = startPoint + ts.t * direction;
                    normal = (newPoint - ts.sphere.CenterPosition) / ts.sphere.Radius;
                    diffuseColor = ts.sphere.DiffuseAlbedo.rgb;
                }
            }
        }
        else {
            //min == plane
            newPoint = startPoint + plane_t * direction;
            normal = plane.Normal;
            diffuseColor = plane.DiffuseAlbedo.rgb;
        }

        return diffuseColor * CalcLighting(newPoint, normal, direction, light, spheres, plane);
    }
}

float3 ReflectTraceRay(float3 startPoint, float3 direction, Light light, Sphere spheres[MaxSpheres], Plane plane, int num) {
    float3 color = 0.0f;

    float3 p = startPoint;
    float3 d = direction;
    float r = 0.0f;
    float3 diffuseColor = 0.0f;
    float3 blackColor = 0.0f;

    for (int i = 0; i < num; i++) {
        TandSphere ts = ClosestIntersection(p, d, spheres);
        float plane_t = IntersectRayPlane(p, d, plane);

        if ((ts.t < 0.001f || ts.t > 999.0f) && plane_t < 0.001f) {
            color += blackColor;
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
                    diffuseColor = ts.sphere.DiffuseAlbedo.rgb;
                    r = ts.sphere.Reflectance;
                }
                else {
                    if (ts.t > plane_t) {
                        //min = plane
                        newPoint = p + plane_t * d;
                        normal = plane.Normal;
                        diffuseColor = plane.DiffuseAlbedo.rgb;
                        r = plane.Reflectance;
                    }
                    else {
                        //min = sphere
                        newPoint = p + ts.t * d;
                        normal = (newPoint - ts.sphere.CenterPosition) / ts.sphere.Radius;
                        diffuseColor = ts.sphere.DiffuseAlbedo.rgb;
                        r = ts.sphere.Reflectance;
                    }
                }
            }
            else {
                //min == plane
                newPoint = p + plane_t * d;
                normal = plane.Normal;
                diffuseColor = plane.DiffuseAlbedo.rgb;
                r = plane.Reflectance;
            }


            if (i == 0) {
                //fisrt ray = only get local color
                float3 local_color = diffuseColor * CalcLighting(newPoint, normal, d, light, spheres, plane);
                color += local_color;
            }
            else {
                //reflected ray = trace ray and get color
                float3 reflected_color = TraceRay(p, d, light, spheres, plane);
                color +=  reflected_color * pow(r, (float)i);
            }

            //update current point & direction
            p = newPoint;
            d = GetReflection(d, normal);

        }
    }
    return color;
}