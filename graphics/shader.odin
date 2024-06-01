package adrastea_graphics


// The type of `material_properties` must match in both the vertex and fragment stages.
// The type of the vertex stage's return value must match the fragment stage's `vert_to_frag` parameter.
shader_create :: proc (
    vertex:   proc "contextless" (vert_in: Vertex_Attributes, 
                                  pass_properties: ^Render_Pass_Property_Block, 
                                  material_properties: ^$Mat_Props
                                 ) -> Vertex_To_Fragment,
    fragment: proc "contextless" (vert_to_frag: Vertex_To_Fragment,
                                  pass_properties: ^Render_Pass_Property_Block, 
                                  material_properties: ^Mat_Props
                                 ) -> Fragment
    ) -> Shader(Mat_Props) {


    return Shader(Mat_Props) {
        vertex_program   = vertex,
        fragment_program = fragment,
    }
}


shader_destroy :: proc(shader: ^Shader) {
    // Nothing to clean up yet.
}


material_create :: proc (shader: ^Shader($Mat_Props), properties: Mat_Props) -> Material(Mat_Props) {
    return Material(Mat_Props) {
        shader     = shader,
        properties = properties,
    }
}


material_destroy :: proc(material: ^Material) {
    // Nothing to clean up yet.
}

material_properties :: proc "contextless" (material: ^Material($Mat_Props)) -> ^Mat_Props {
    return &material.properties
}
