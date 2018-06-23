`timescale 1ns / 1ps

module sevenseg(
    input  clock,
    input  [3:0]in1, in2, in3, in4, dpi,
    output [6:0]seg,
    output dp,
    output [3:0]an
);
   
localparam N = 17;

reg [N-1:0] count;
reg [3:0] sseg;
reg [3:0] antmp;
reg [6:0] ssegtmp;
reg dptmp;

always @ (posedge clock)
begin
    count <= count + 1;
end

always @ (*)
begin
    case (count[N-1:N-2])
    2'b00:
        begin
            sseg = in1;
            dptmp = dpi[0];
            antmp = 4'b1110;
        end
    2'b01:
        begin
            sseg = in2;
            dptmp = dpi[1];
            antmp = 4'b1101;
        end
    2'b10:
        begin
            sseg = in3;
            dptmp = dpi[2];
            antmp = 4'b1011;
        end
    2'b11:
        begin
            sseg = in4;
            dptmp = dpi[3];
            antmp = 4'b0111;
        end
    endcase
end

always @ (*)
begin
    case (sseg)
    4'd0: ssegtmp = 7'b1000000;
    4'd1: ssegtmp = 7'b1111001;
    4'd2: ssegtmp = 7'b0100100;
    4'd3: ssegtmp = 7'b0110000;
    4'd4: ssegtmp = 7'b0011001;
    4'd5: ssegtmp = 7'b0010010;
    4'd6: ssegtmp = 7'b0000010;
    4'd7: ssegtmp = 7'b1111000;
    4'd8: ssegtmp = 7'b0000000;
    4'd9: ssegtmp = 7'b0010000;
    4'd10: ssegtmp = 7'b0001000;
    4'd11: ssegtmp = 7'b0000011;
    4'd12: ssegtmp = 7'b1000110;
    4'd13: ssegtmp = 7'b0100001;
    4'd14: ssegtmp = 7'b0000110;
    4'd15: ssegtmp = 7'b0001110;
    default: ssegtmp = 7'b0111111;
    endcase
end

assign an = antmp;
assign seg[6:0] = ssegtmp;
assign dp = dptmp;

endmodule
