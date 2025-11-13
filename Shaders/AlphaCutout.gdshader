shader_type canvas_item;

uniform vec2 circle_center_world = vec2(0.0); // world position of circle center
uniform float circle_radius = 200.0;
uniform float fade_width = 50.0;

varying vec2 frag_world_pos;

void vertex() {
    // FRAGCOORD.xy will still be screen space, but we want world space
    frag_world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    // Distance in world space
    float dist = distance(frag_world_pos, circle_center_world);

    // Smooth alpha mask
    float alpha_mask = smoothstep(circle_radius + fade_width, circle_radius, dist);

    COLOR = vec4(tex_color.rgb, tex_color.a * alpha_mask);
}
