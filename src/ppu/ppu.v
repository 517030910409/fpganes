/***************************************************************************************************
** fpga_nes/hw/src/ppu/ppu.v
*
*  Copyright (c) 2012, Brian Bennett
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without modification, are permitted
*  provided that the following conditions are met:
*
*  1. Redistributions of source code must retain the above copyright notice, this list of conditions
*     and the following disclaimer.
*  2. Redistributions in binary form must reproduce the above copyright notice, this list of
*     conditions and the following disclaimer in the documentation and/or other materials provided
*     with the distribution.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
*  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
*  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
*  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
*  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
*  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
*  Picture processing unit block.
***************************************************************************************************/

module ppu(
    input  wire        clk_in,        // 100MHz system clock signal
    input  wire        rst_in,        // reset signal
    input  wire [ 2:0] ri_sel_in,     // register interface reg select
    input  wire        ri_ncs_in,     // register interface enable
    input  wire        ri_r_nw_in,    // register interface read/write select
    input  wire [ 7:0] ri_d_in,       // register interface data in
    input  wire [ 7:0] vram_d_in,     // video memory data bus (input)
    output wire        hsync_out,     // vga hsync signal
    output wire        vsync_out,     // vga vsync signal
    output wire [ 2:0] r_out,         // vga red signal
    output wire [ 2:0] g_out,         // vga green signal
    output wire [ 1:0] b_out,         // vga blue signal
    output wire [ 7:0] ri_d_out,      // register interface data out
    output wire        nvbl_out,      // /VBL (low during vertical blank)
    output wire [13:0] vram_a_out,    // video memory address bus
    output wire [ 7:0] vram_d_out,    // video memory data bus (output)
    output wire        vram_wr_out    // video memory read/write select
);

//
// PPU_VGA: VGA output block.
//
wire [5:0] vga_sys_palette_idx;
wire [9:0] vga_nes_x;
wire [9:0] vga_nes_y;
wire [9:0] vga_nes_y_next;
wire       vga_pix_pulse;
wire       vga_vblank;
wire [1:0] nt_sel;
wire       bg_pt_sel;
wire       bg_en_all;
wire       bg_en_left;
wire [7:0] scr_x;
wire [7:0] scr_y;

ppu_vga ppu_vga_blk(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .sys_palette_idx_in(vga_sys_palette_idx),
    .hsync_out(hsync_out),
    .vsync_out(vsync_out),
    .r_out(r_out),
    .g_out(g_out),
    .b_out(b_out),
    .nes_x_out(vga_nes_x),
    .nes_y_out(vga_nes_y),
    .pix_pulse_out(vga_pix_pulse),
    .vblank_out(vga_vblank)
);

wire        ri_vram_en;
wire        ri_vram_wr;
wire [13:0] ri_vram_addr;
wire        nmi_en;

ppu_ri ppu_ri_blk(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .vblank_in(vga_vblank),
    .ri_en_in(~ri_ncs_in),
    .ri_sel_in(ri_sel_in),
    .ri_wr_in(~ri_r_nw_in),
    .ri_data_in(ri_d_in),
    .vram_data_in(vram_d_in),
    .vram_addr_out(ri_vram_addr),
    .vram_data_out(vram_d_out),
    .vram_wr_out(ri_vram_wr),
    .vram_en_out(ri_vram_en),
    .ri_data_out(ri_d_out),
    .nt_sel_out(nt_sel),
    .bg_pt_sel_out(bg_pt_sel),
    .bg_en_all_out(bg_en_all),
    .bg_en_left_out(bg_en_left),
    .scr_x_out(scr_x),
    .scr_y_out(scr_y),
    .nmi_en_out(nmi_en)
);
    
wire [ 3:0] bg_palette;
wire        bg_vram_en;
wire [13:0] bg_vram_addr;

ppu_bg ppu_bg_blk(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .en_all(bg_en_all),
    .en_left(bg_en_left),
    .nes_x_in(vga_nes_x),
    .nes_y_in(vga_nes_y),
    .scr_x_in(scr_x),
    .scr_y_in(scr_y),
    .nes_pix_pulse(vga_pix_pulse),
    .nt_sel_in(nt_sel),
    .pt_sel_in(bg_pt_sel),
    .vram_data_in(vram_d_in),
    .vram_addr_out(bg_vram_addr),
    .vram_en_out(bg_vram_en),
    .palette_out(bg_palette)
);

reg  [5:0] palette_ram [31:0];

`define PRAM_A(addr) ((addr & 5'h03) ? addr :  (addr & 5'h0f))

always @(posedge clk_in or posedge rst_in) begin
    if (rst_in) begin
        palette_ram[`PRAM_A(5'h00)] <= 6'h09;
        palette_ram[`PRAM_A(5'h01)] <= 6'h01;
        palette_ram[`PRAM_A(5'h02)] <= 6'h00;
        palette_ram[`PRAM_A(5'h03)] <= 6'h01;
        palette_ram[`PRAM_A(5'h04)] <= 6'h00;
        palette_ram[`PRAM_A(5'h05)] <= 6'h02;
        palette_ram[`PRAM_A(5'h06)] <= 6'h02;
        palette_ram[`PRAM_A(5'h07)] <= 6'h0d;
        palette_ram[`PRAM_A(5'h08)] <= 6'h08;
        palette_ram[`PRAM_A(5'h09)] <= 6'h10;
        palette_ram[`PRAM_A(5'h0a)] <= 6'h08;
        palette_ram[`PRAM_A(5'h0b)] <= 6'h24;
        palette_ram[`PRAM_A(5'h0c)] <= 6'h00;
        palette_ram[`PRAM_A(5'h0d)] <= 6'h00;
        palette_ram[`PRAM_A(5'h0e)] <= 6'h04;
        palette_ram[`PRAM_A(5'h0f)] <= 6'h2c;
        palette_ram[`PRAM_A(5'h11)] <= 6'h01;
        palette_ram[`PRAM_A(5'h12)] <= 6'h34;
        palette_ram[`PRAM_A(5'h13)] <= 6'h03;
        palette_ram[`PRAM_A(5'h15)] <= 6'h04;
        palette_ram[`PRAM_A(5'h16)] <= 6'h00;
        palette_ram[`PRAM_A(5'h17)] <= 6'h14;
        palette_ram[`PRAM_A(5'h19)] <= 6'h3a;
        palette_ram[`PRAM_A(5'h1a)] <= 6'h00;
        palette_ram[`PRAM_A(5'h1b)] <= 6'h02;
        palette_ram[`PRAM_A(5'h1d)] <= 6'h20;
        palette_ram[`PRAM_A(5'h1e)] <= 6'h2c;
        palette_ram[`PRAM_A(5'h1f)] <= 6'h08;
    end else begin
        if (~ri_ncs_in && ri_vram_en && ri_vram_wr && ri_vram_addr[13:8] == 6'h3f)
            palette_ram[`PRAM_A(ri_vram_addr[4:0])] <= vram_d_out[5:0];
    end
end

assign vram_a_out = ~ri_ncs_in ? ri_vram_addr : bg_vram_addr;
assign vram_wr_out = ~ri_ncs_in ? ri_vram_wr : 1'h0;
assign nvbl_out = ~nmi_en ? ~vga_vblank : 1'h1;
assign vga_sys_palette_idx = palette_ram[{1'h0, bg_palette}];
//assign vga_sys_palette_idx = palette_ram[vga_nes_x[4:0]];

endmodule

