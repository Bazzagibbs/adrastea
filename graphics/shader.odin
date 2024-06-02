package adrastea_graphics


// The type of `material_properties` must match in both the vertex and fragment stages.
//
// `vertex` is a shader stage that takes the following parameters:
//  - `vert_in`                 - A mesh's vertex input
//  - `pass_properties`         - The property block of the current render pass
//  - `material_properties`     - The property block of the current material
// returns `Vertex_To_Fragment` - Data that will be interpolated and passed to the fragment shader stage
//
// `fragment` is a shader stage that takes the following parameters:
//  - `vert_to_frag`        - Interpolated data from the vertex stage output
//  - `face_normal`         - Normal of the face this fragment was generated from, calculated using cross product. The vector is of unit length.
//  - `pass_properties`     - The property block of the current render pass
//  - `material_properties` - The property block of the current material
//  returns `Fragment`      - Data that is drawn to the render target
shader_create :: proc (
    $Mat_Props: typeid,
    vertex:   proc "contextless" (vert_in: Vertex_Attributes, 
                                  pass_properties: ^Render_Pass_Property_Block, 
                                  material_properties: ^Mat_Props
                                 ) -> Vertex_To_Fragment,
    fragment: proc "contextless" (vert_to_frag: Vertex_To_Fragment,
                                  face_normal: [3]f32,
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
