shader_type canvas_item;

uniform sampler2D normal_map;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;
uniform float ambient_light : hint_range(0.0, 1.0) = 3.0; // Softens shadows

void fragment() {
    vec3 normal = texture(normal_map, UV).rgb;
    
    // Convert normal map colors to -1 to 1 range
    normal = normalize(normal * 2.0 - 1.0);
    
    // Apply normal map strength
    normal.xy *= normal_strength; 
    normal = normalize(normal);
    
    // Define light direction (customizable)
    vec2 light_dir = normalize(vec2(1.0, -1.0));  
    float diff = max(dot(normal.xy, light_dir), ambient_light); // Ensures some brightness

    vec4 albedo = texture(TEXTURE, UV);
    COLOR.rgb = albedo.rgb * diff; 
    COLOR.a = albedo.a;
}
