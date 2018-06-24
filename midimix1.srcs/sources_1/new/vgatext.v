`timescale 1ns / 1ps

module vgatext(
    input clk,
    input [9:0] vga_x,
    input [8:0] vga_y,
    input [6:0] txt_x,
    input [4:0] txt_y,
    input [7:0] inchr,
    input inrdy,
    output pixel
);
    
// setup character rom
wire [11:0] address;
wire [7:0] char_data;
vga_char_rom vga_char_rom_inst (
    .clk(clk),
    .addr(address),
    .data(char_data)
);
    
reg [7:0] text [0:80*30];
    
wire [4:0] ty = vga_y / 16;
wire [6:0] tx = vga_x / 8;
wire [7:0] curchr = text[(ty*80) + tx];
        
assign address = (curchr * 16) + vga_y%16;
assign pixel = char_data[8-vga_x%8];

always @(posedge inrdy) text[(txt_y*80) + txt_x] <= inchr;

endmodule
