void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec3 col = texture(iChannel0, uv).rgb;

    // Increase overall brightness/contrast a bit (tweak these)
    col *= 1.25;                 // brightness gain (try 1.15–1.40)
    col = pow(col, vec3(0.90));   // gamma lift (lower = brighter mids; try 0.85–0.95)

    fragColor = vec4(col, 1.0);
}
