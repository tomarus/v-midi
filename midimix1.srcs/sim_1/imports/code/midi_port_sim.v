`timescale 1ns / 1ps

module midi_port_tb();

reg t_clk = 0;
reg t_rst;
reg t_txdv;
wire t_txserial, t_rxserial;
reg [7:0] t_txdata;

wire t_rxdv;
wire [7:0] t_rxdata;

always t_clk = #1 ~t_clk;

midi_port mp_tb(
    .clk(t_clk),
    .rst(t_rst),
    .txdv(t_txdv),
    .txserial(t_txserial),
    .txdata(t_txdata),
    .rxdv(t_rxdv),
    .rxserial(t_rxserial),
    .rxdata(t_rxdata)
);

initial begin
    t_rst = 1;
    #2;
    t_rst = 0;

    t_txdata <= 8'b01011010;
    t_txdv = 1;
    #2;
    t_rst = 0;
    t_txdata <= 8'b10100101;
    t_txdv = 1;
    #2;
    t_rst = 0;
    t_txdata <= 8'b11000011;
    t_txdv = 1;
    #2;
    t_rst = 0;
    t_txdata <= 8'b00111100;
    t_txdv = 1;
    #2;
//    t_txdv = 0;
//    #2;
//    #400000;

    t_txdata <= 8'b01011010;
    t_txdv = 1;
    #2;
    t_rst = 0;
    t_txdata <= 8'b10100101;
    t_txdv = 1;
    #2;
    t_rst = 0;
    t_txdata <= 8'b11000011;
    t_txdv = 1;
    #2;
    t_rst = 0;
    t_txdata <= 8'b00111100;
    #2;
    t_txdv = 0;
    #2;
//    #400000;

    t_txdata <= 8'b01011010;
    t_txdv = 1;
    #2;
    t_rst = 0;
    t_txdata <= 8'b10100101;
    t_txdv = 1;
    #2;
    t_rst = 0;
    t_txdata <= 8'b11000011;
    t_txdv = 1;
    #2;
    t_rst = 0;
    t_txdata <= 8'b00111100;
    t_txdv = 1;
    #2;
    t_txdv = 0;
    #2;
//    #400000;

    t_txdata <= 8'b01011010;
    t_txdv = 1;
    #2;
    t_rst = 0;
    t_txdata <= 8'b10100101;
    t_txdv = 1;
    #2;
    t_rst = 0;
    t_txdata <= 8'b11000011;
    t_txdv = 1;
    #2;
    t_rst = 0;
    t_txdata <= 8'b00111100;
    t_txdv = 1;
    #2;
    t_txdv = 0;
    #2;
//    #400000;
end

endmodule
