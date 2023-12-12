package adrastea_renderer

import "../common"

Mesh :: common.Mesh

Render_Target :: struct {
    width: u32,
    height: u32,
    buffer: []u8,
}