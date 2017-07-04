// applies a laplacian filter to draw the image as an outline
// inverts alpha first, so the outline will be drawn AROUND the opaque area, not on top of it
vec4 resultColor;
vec4 textureColor;
extern vec2 stepSize;

vec4 effect(vec4 color, Image texture, vec2 texturePos, vec2 screenPos) {
    number alpha = 4 * abs(1 - texture2D(texture, texturePos).a);
    alpha -= abs(1 - texture2D(texture, texturePos + vec2( stepSize.x, 0.0f)).a);
    alpha -= abs(1 - texture2D(texture, texturePos + vec2(-stepSize.x, 0.0f)).a);
    alpha -= abs(1 - texture2D(texture, texturePos + vec2( 0.0f,  stepSize.y)).a);
    alpha -= abs(1 - texture2D(texture, texturePos + vec2( 0.0f, -stepSize.y)).a);
    return vec4(1.0f, 1.0f, 1.0f, alpha);
}
