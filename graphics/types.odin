package adrastea_graphics

import pd_gfx "../playdate/graphics"

Color :: enum u8 {
    black = 0,
    white = 1,
}

Mesh :: struct {
    vertices        : []Vertex_Attributes,
    index_buffer    : [][3]i16,
}

Vertex_Attributes :: struct {
    position     : [3]f32,
    tex_coord    : [2]f32,
    user_scalar  : f32,
}

Vertex_To_Fragment :: struct {
    position     : [4]f32,  // In clip space
    tex_coord    : [2]f32,
    user_scalar  : f32,
}

Fragment :: struct {
    discard : bool,
    color   : Color,
}


Render_Target :: struct {
    support_depth       : bool,
    width               : u32,
    height              : u32,
    buffer_color        : []Color,
    buffer_depth        : []f32,
}

Render_Pass_Property_Block :: struct {
    model_mat      : matrix[4, 4]f32,
    view_mat       : matrix[4, 4]f32,
    projection_mat : matrix[4, 4]f32,
    
    mv_mat         : matrix[4, 4]f32,
    mvp_mat        : matrix[4, 4]f32,
}

Render_Pass :: struct {
    render_target : ^Render_Target,
    properties    : Render_Pass_Property_Block,
}


Shader :: struct ($Mat_Props: typeid) {
    vertex_program      : proc "contextless" (vertex_input: Vertex_Attributes, render_pass_properties: ^Render_Pass_Property_Block, material_properties: ^Mat_Props) -> Vertex_To_Fragment,
    fragment_program    : proc "contextless" (vert_to_frag: Vertex_To_Fragment, face_normal: [3]f32, render_pass_properties: ^Render_Pass_Property_Block, material_properties: ^Mat_Props) -> Fragment,
}


Shader_Cull_Backface_Flags :: bit_set[Shader_Cull_Backface_Flag; u8]
Shader_Cull_Backface_Flag  :: enum {
    Clockwise,
    Counter_Clockwise,
}

Shader_Depth_Test_Flag  :: enum {
    GEqual,
    LEqual,
    Greater,
    Less,
    Equal,
    NotEqual,
    Always,
    Never,
}

Material :: struct ($Mat_Props: typeid) {
    shader         : ^Shader(Mat_Props),
    properties     : Mat_Props,
    cull_backface  : Shader_Cull_Backface_Flags,
    depth_test     : Shader_Depth_Test_Flag,
    depth_write    : b8,
}
