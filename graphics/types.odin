package adrastea_graphics

Mesh :: struct($Vertex_Attributes: typeid) {
    vertices        : #soa[]Vertex_Attributes,
    index_buffer    : [][3]i16,
}

Render_Target :: struct {
    width: u32,
    height: u32,
    buffer: []u8,
}

Render_Pass_Property_Block :: struct {
    model_mat      : matrix[4, 4]f32,
    view_mat       : matrix[4, 4]f32,
    projection_mat : matrix[4, 4]f32,
    
    mv_mat         : matrix[4, 4]f32,
    mvp_mat        : matrix[4, 4]f32,
}

Render_Pass :: struct {
    render_target  : ^Render_Target,
    property_block : Render_Pass_Property_Block,
}


Shader :: struct($Material_Property_Block, $Vertex_Attributes, $Vertex_Output: typeid) {
    vertex_program      : proc "contextless" (vertex_input: Vertex_Attributes, render_pass_properties: ^Render_Pass_Property_Block, material_properties: ^Material_Property_Block) -> Vertex_Output,
    fragment_program    : proc "contextless" (vertex_output: Vertex_Output, render_pass_properties: ^Render_Pass_Property_Block, material_properties: ^Material_Property_Block) -> u8,
}


Shader_Cull_Backface_Flags :: bit_set[Shader_Cull_Backface_Flag; u8]
Shader_Cull_Backface_Flag  :: enum {
    Clockwise,
    Counter_Clockwise,
}

Shader_Depth_Test_Flags :: bit_set[Shader_Depth_Test_Flag; u8]
Shader_Depth_Test_Flag  :: enum {
    Less,
    Equal,
    Greater,
}

Material :: struct(Shader_Type($M_Prop, $V_Attr, $V_Out): typeid/$Shader) {
    shader         : ^Shader_Type,
    property_block : M_Prop,
    cull_backface  : Shader_Cull_Backface_Flags,
    depth_test     : Shader_Depth_Test_Flags,
    depth_write    : b8,
}
