package adrastea_graphics


// The type of `material_properties` must match in both the vertex and fragment stages.
// The type of the vertex stage's return value must match the fragment stage's `vert_to_frag` parameter.
shader_create :: proc (
    vertex:   proc "contextless" (vert_in: Vertex_Attributes, 
                                  pass_properties: ^Render_Pass_Property_Block, 
                                  material_properties: ^$Mat_Props
                                 ) -> (vert_to_frag: $V2F),
    fragment: proc "contextless" (vert_to_frag: V2F, 
                                  pass_properties: ^Render_Pass_Property_Block, 
                                  material_properties: ^Mat_Props
                                 ) -> Fragment
    ) -> Shader(Mat_Props, V2F) {


    return Shader(Mat_Props, V2F) {
        vertex_program   = vertex,
        fragment_program = fragment,
    }
}


shader_destroy :: proc(shader: ^Shader) {
    // Nothing to clean up yet.
}


material_create :: proc (shader: ^Shader($Mat_Props, $V2F), properties: Mat_Props) -> Material(Mat_Props, V2F) {
    return Material(Mat_Props, V2F) {
        shader     = shader,
        properties = properties,
    }
}


material_destroy :: proc(material: ^Material) {
    // Nothing to clean up yet.
}
