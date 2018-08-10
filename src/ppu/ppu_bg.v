`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/08/01 15:36:30
// Design Name: 
// Module Name: ppu_bg
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


module ppu_bg(
    input  wire        clk_in,
    input  wire        rst_in,
    input  wire        en_all,
    input  wire        en_left,
    input  wire [ 9:0] nes_x_in,
    input  wire [ 9:0] nes_y_in,
    input  wire [ 7:0] scr_x_in,
    input  wire [ 7:0] scr_y_in,
    input  wire        nes_pix_pulse,
    input  wire [ 1:0] nt_sel_in,
    input  wire        pt_sel_in,
    input  wire [ 7:0] vram_data_in,
    output wire [13:0] vram_addr_out,
    output wire        vram_en_out,
    output wire [ 3:0] palette_out
);

reg  [3:0] q_8_pix [7:0];
reg  [3:0] d_8_pix [7:0];

reg  [7:0] pattern_index;
reg [13:0] vram_addr_out_reg;

wire [3:0] nt;
wire [2:0] attr_x, attr_y;
wire [4:0] nt_x, nt_y;
wire [9:0] cdn_x, cdn_y, cdn_yy;

always @(posedge nes_pix_pulse or posedge rst_in) begin
    if (rst_in) begin
        q_8_pix[0] <= 4'h0;
        q_8_pix[1] <= 4'h0;
        q_8_pix[2] <= 4'h0;
        q_8_pix[3] <= 4'h0;
        q_8_pix[4] <= 4'h0;
        q_8_pix[5] <= 4'h0;
        q_8_pix[6] <= 4'h0;
        q_8_pix[7] <= 4'h0;
        d_8_pix[0] <= 4'h0;
        d_8_pix[1] <= 4'h0;
        d_8_pix[2] <= 4'h0;
        d_8_pix[3] <= 4'h0;
        d_8_pix[4] <= 4'h0;
        d_8_pix[5] <= 4'h0;
        d_8_pix[6] <= 4'h0;
        d_8_pix[7] <= 4'h0;
    end else begin
        if (cdn_x[2:0] == 3'h0) begin
            q_8_pix[0] <= d_8_pix[0];
            q_8_pix[1] <= d_8_pix[0];
            q_8_pix[2] <= d_8_pix[2];
            q_8_pix[3] <= d_8_pix[3];
            q_8_pix[4] <= d_8_pix[4];
            q_8_pix[5] <= d_8_pix[5];
            q_8_pix[6] <= d_8_pix[6];
            q_8_pix[7] <= d_8_pix[7];
        end
        if (nes_x_in[9:0] < 10'h100 && nes_y_in[9:0] < 10'h0f0) begin
            case (cdn_x[2:0])
            3'h0: vram_addr_out_reg <= {nt, nt_x, nt_y};
            3'h1: begin
                pattern_index <= vram_data_in;
            end
            3'h2: vram_addr_out_reg <= {pt_sel_in ? 1'h1 : 1'h0, pattern_index, 1'h0, nes_y_in[2:0]};
            3'h3: begin
                d_8_pix[0][0] <= vram_data_in[0];
                d_8_pix[1][0] <= vram_data_in[1];
                d_8_pix[2][0] <= vram_data_in[2];
                d_8_pix[3][0] <= vram_data_in[3];
                d_8_pix[4][0] <= vram_data_in[4];
                d_8_pix[5][0] <= vram_data_in[5];
                d_8_pix[6][0] <= vram_data_in[6];
                d_8_pix[7][0] <= vram_data_in[7];
            end
            3'h4: vram_addr_out_reg <= {pt_sel_in ? 1'h1 : 1'h0, pattern_index, 1'h1, nes_y_in[2:0]};
            3'h5: begin
                d_8_pix[0][1] <= vram_data_in[0];
                d_8_pix[1][1] <= vram_data_in[1];
                d_8_pix[2][1] <= vram_data_in[2];
                d_8_pix[3][1] <= vram_data_in[3];
                d_8_pix[4][1] <= vram_data_in[4];
                d_8_pix[5][1] <= vram_data_in[5];
                d_8_pix[6][1] <= vram_data_in[6];
                d_8_pix[7][1] <= vram_data_in[7];
            end
            3'h6: vram_addr_out_reg <= {nt, 4'hf, attr_x, attr_y};
            3'h7: begin
                d_8_pix[0][3:2] <= nt_y[1] ? (nt_x[1] ? vram_data_in[7:6] : vram_data_in[5:4]) : (nt_x[1] ? vram_data_in[3:2] : vram_data_in[1:0]);
                d_8_pix[1][3:2] <= nt_y[1] ? (nt_x[1] ? vram_data_in[7:6] : vram_data_in[5:4]) : (nt_x[1] ? vram_data_in[3:2] : vram_data_in[1:0]);
                d_8_pix[2][3:2] <= nt_y[1] ? (nt_x[1] ? vram_data_in[7:6] : vram_data_in[5:4]) : (nt_x[1] ? vram_data_in[3:2] : vram_data_in[1:0]);
                d_8_pix[3][3:2] <= nt_y[1] ? (nt_x[1] ? vram_data_in[7:6] : vram_data_in[5:4]) : (nt_x[1] ? vram_data_in[3:2] : vram_data_in[1:0]);
                d_8_pix[4][3:2] <= nt_y[1] ? (nt_x[1] ? vram_data_in[7:6] : vram_data_in[5:4]) : (nt_x[1] ? vram_data_in[3:2] : vram_data_in[1:0]);
                d_8_pix[5][3:2] <= nt_y[1] ? (nt_x[1] ? vram_data_in[7:6] : vram_data_in[5:4]) : (nt_x[1] ? vram_data_in[3:2] : vram_data_in[1:0]);
                d_8_pix[6][3:2] <= nt_y[1] ? (nt_x[1] ? vram_data_in[7:6] : vram_data_in[5:4]) : (nt_x[1] ? vram_data_in[3:2] : vram_data_in[1:0]);
                d_8_pix[7][3:2] <= nt_y[1] ? (nt_x[1] ? vram_data_in[7:6] : vram_data_in[5:4]) : (nt_x[1] ? vram_data_in[3:2] : vram_data_in[1:0]);
            end
            endcase
        end
    end
end

//assign cdn_x[8:0] = {nt_sel_in[0], scr_x_in[7:0]} + {1'h0, nes_x_in[7:0]};
//assign cdn_yy[8:0] = {nt_sel_in[1], scr_y_in[7:0]} + {1'h0, nes_y_in[7:0]};
//assign cdn_y[8:0] = cdn_yy[8:0] > 9'h0ef ? cdn_yy[8:0] + 9'h010 : cdn_yy[8:0];
assign cdn_x[8:0] = {1'h0, nes_x_in[7:0]};
assign cdn_y[8:0] = {1'h0, nes_y_in[7:0]};
assign nt[3:0] = {2'h2, cdn_y[8], cdn_x[8]};
assign nt_x[4:0] = cdn_x[7:3] + 5'h01;
assign nt_y[4:0] = (cdn_x[7:3] == 5'h1f && cdn_y[2:0] == 3'h7) ? (cdn_y[8:3] == 6'h1f ? 5'h00 : cdn_y[7:3] + 5'h01) : cdn_y[7:3];
assign attr_x[2:0] = (cdn_x[4:3] == 2'h3 ? 3'h1 : 0) + cdn_x[7:5];
assign attr_y[2:0] = nes_x_in[7:3] == 5'h1f ? (nes_y_in[7:0] == 8'hef ? 3'h0 : ((nes_y_in[4:0] == 5'h1f ? 3'h1 : 0) + nes_y_in[7:5])) : nes_y_in[7:5];
assign vram_addr_out[13:0] = vram_addr_out_reg[13:0];
assign palette_out[3:0] = q_8_pix[cdn_x[2:0]][3:0];
//assign palette_out = (en_all && (nes_x_in[7:3] || en_left)) ? 
//                     (nes_x_in[2] ? (nes_x_in[1] ? (nes_x_in[0] ? q_8_pix[7] : q_8_pix[6]) : (nes_x_in[0] ? q_8_pix[5] : q_8_pix[4])) : 
//                                    (nes_x_in[1] ? (nes_x_in[0] ? q_8_pix[3] : q_8_pix[2]) : (nes_x_in[0] ? q_8_pix[1] : q_8_pix[0]))
//                     ) : 0;
assign vram_en_out = nes_x_in[2] ? 1'h0 : 1'h1;

endmodule
