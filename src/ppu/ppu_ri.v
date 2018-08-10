`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/08/02 16:52:38
// Design Name: 
// Module Name: ppu_ri
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ppu_ri(
    input  wire        clk_in,
    input  wire        rst_in,
    input  wire        vblank_in,
    input  wire        ri_en_in,
    input  wire [ 2:0] ri_sel_in,
    input  wire        ri_wr_in,
    input  wire [ 7:0] ri_data_in,
    input  wire [ 7:0] vram_data_in,
    output wire [13:0] vram_addr_out,
    output wire [ 7:0] vram_data_out,
    output wire        vram_wr_out,
    output wire        vram_en_out,
    output wire [ 7:0] ri_data_out,
    output wire [ 1:0] nt_sel_out,
    output wire        bg_pt_sel_out,
    output wire        bg_en_all_out,
    output wire        bg_en_left_out,
    output wire [ 7:0] scr_x_out,
    output wire [ 7:0] scr_y_out,
    output wire        nmi_en_out
);

reg  [ 1:0] nt_sel_reg;
reg         bg_pt_sel_reg;
reg         nt_en_all_reg;
reg         nt_en_left_reg;
reg         q_2005_c, q_2006_c;
wire        d_2005_c, d_2006_c;
reg  [ 7:0] scr_x_reg, scr_y_reg;
reg  [13:0] cur_addr;
reg  [ 7:0] cur_data;
wire [13:0] nxt_1_addr, nxt_32_addr;
reg         addr_inc;
reg         vram_wr_reg;
reg  [ 7:0] vram_data_reg;
reg  [ 7:0] ri_data_reg;
reg         update_data;
reg         nmi_en_reg;

always @(posedge ri_en_in or posedge rst_in) begin
    if (rst_in) begin
        q_2005_c <= 0;
        q_2006_c <= 0;
    end else begin
        if (~ri_wr_in) begin
            case (ri_sel_in)
                3'h0: begin
                    nt_sel_reg[1:0] <= ri_data_in[1:0];
                    addr_inc <= ri_data_in[2];
                    bg_pt_sel_reg <= ri_data_in[4];
                    nmi_en_reg = ri_data_in[7];
                end
                3'h1: begin
                    nt_en_all_reg <= ri_data_in[3];
                    nt_en_left_reg <= ri_data_in[1];
                end
                3'h5: begin
                    if (q_2005_c) scr_x_reg[7:0] <= ri_data_in[7:0];
                    else scr_y_reg[7:0] <= ri_data_in[7:0];
                    q_2005_c <= d_2005_c;
                end
                3'h6: begin
                    if (q_2006_c) cur_addr[13:8] <= ri_data_in[5:0];
                    else begin
                        cur_addr[7:0] <= ri_data_in[7:0];
                        update_data <= 1'h1;
                    end
                    q_2006_c <= d_2006_c;
                end
                3'h7: begin
                    vram_data_reg[7:0] <= ri_data_in[7:0];
                    if (addr_inc) cur_addr[13:0] <= nxt_32_addr[13:0];
                    else cur_addr[13:0] <= nxt_1_addr[13:0];
                    update_data <= 1'h1;
                end
            endcase
        end else begin
            case (ri_sel_in)
                3'h2: begin
                    ri_data_reg[7] <= vblank_in;
                end
                3'h7: begin
                    ri_data_reg[7:0] <= cur_data[7:0];
                    if (addr_inc) cur_addr[13:0] <= nxt_32_addr[13:0];
                    else cur_addr[13:0] <= nxt_1_addr[13:0];
                    update_data <= 1'h1;
                end
            endcase
        end
        if (update_data) begin
            update_data <= 1'h0;
            cur_data <= vram_data_in;
        end
        vram_wr_reg <= ~ri_wr_in && ri_sel_in == 3'h7;
    end
end

assign nxt_32_addr[13:0] = cur_addr[13:0] + 14'h020;
assign nxt_1_addr[13:0] = cur_addr[13:0] + 14'h001;
assign d_2005_c = q_2005_c + 1'h1;
assign d_2006_c = q_2006_c + 1'h1;
assign nt_sel_out[1:0] = nt_sel_reg[1:0];
assign bg_pt_sel_out = bg_pt_sel_reg;
assign scr_x_out[7:0] = scr_x_reg[7:0];
assign scr_y_out[7:0] = scr_y_reg[7:0];
assign vram_wr_out = vram_wr_reg;
assign vram_data_out[7:0] = vram_data_reg[7:0];
assign vram_addr_out[13:0] = cur_addr[13:0];
assign ri_data_out[7:0] = ri_data_reg[7:0];
assign vram_en_out = ri_en_in && update_data;
assign nmi_en_out = nmi_en_reg;

endmodule
