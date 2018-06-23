`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2018 01:39:39 AM
// Design Name: 
// Module Name: tempo
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


module tempo(
    input  clock,
    output led
//    output [7:0]byte,
//    output txdv
);

reg [31:0]count = 0;
reg [31:0]beat = 0;
reg blinker;

wire pps = (count == 0);
wire bc = (beat == 0);

//localparam bpm = 125;
//localparam hz = 100_000_000;
//localparam irq = hz * (bpm / 60 / 96);
localparam irq = 2_000_000;

always @(posedge clock)
begin
    count <= pps ? irq -1 : count - 1;
    if (pps) 
    begin
        beat <= bc ? 23 : beat - 1;
        if (beat > 17)
        begin
            blinker = 0;
        end
        else
        begin
            blinker = 1;
        end
    end
end

assign led = blinker;

//assign byte[7:0] = 8'b11111110;
//assign txdv = pps ? 1'b1 : 1'b0;

endmodule
