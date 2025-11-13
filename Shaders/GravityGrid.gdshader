shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float alpha_value : hint_range(0.0, 1.0) = 1.0;
uniform int point_count = 0;
uniform vec2 points[16]; // world positions
uniform float masses[16];
uniform float influence_radius = 400.0; // max distance for pinch
uniform float pinch_strength = -0.001; // tweak for intensity

varying vec2 frag_world_pos;

void vertex() {
    frag_world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    vec2 uv = UV;
    vec2 tex_size = vec2(textureSize(TEXTURE, 0)); // Get texture size once
    float tex_width = tex_size.x; // Use width as the consistent scale factor

    for (int i = 0; i < point_count; i++) {
        // direction from fragment to point, in local sprite space
        vec2 dir_local = points[i] - frag_world_pos;

        float dist = length(dir_local);

        if (dist < influence_radius && dist > 0.0) { // Add dist > 0.0 to prevent division by zero
			float ratio = dist / influence_radius;
			float f = pow(1.0 - ratio, 2.0);
            
            vec2 dir_norm = dir_local / dist; 
            float displacement_magnitude = f * masses[i] * pinch_strength;
            float uv_displacement = displacement_magnitude / tex_width; 
            uv += dir_norm * uv_displacement;
        }
    }

    // 1. Sample the texture at the distorted UV
    vec4 texture_color = texture(TEXTURE, uv);

    // 2. Apply the color tint (RGB)
    vec3 tinted_rgb = texture_color.rgb * tint_color.rgb;

    // 3. Apply the combined alpha (Original Alpha * Tint Alpha * Global Alpha)
    float final_alpha = texture_color.a * tint_color.a * alpha_value;

    // 4. Set the final COLOR
    COLOR = vec4(tinted_rgb, final_alpha);
}