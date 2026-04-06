shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 100.0) = 10.0;

void fragment() {
    float aspect_ratio = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
    
    vec2 size = vec2(pixel_size * aspect_ratio, pixel_size);
    vec2 grid_uv = round(SCREEN_UV * size) / size;
    vec4 background_color = texture(screen_texture, grid_uv);
    
    COLOR = vec4(background_color.rgb, texture(TEXTURE, UV).a);
}