//
// Module vga is the top level vga-text module.
// Basics taken from https://timetoexplore.net/blog/arty-fpga-vga-verilog-01
// See also: https://github.com/bntmorgan/vga-text-mode
//

module vga(
    input wire CLK,             // board clock: 100 MHz on Arty & Basys 3
    input wire RST_BTN,         // reset button
    output wire VGA_HS_O,       // horizontal sync output
    output wire VGA_VS_O,       // vertical sync output
    output wire [3:0] VGA_R,    // 4-bit VGA red output
    output wire [3:0] VGA_G,    // 4-bit VGA green output
    output wire [3:0] VGA_B     // 4-bit VGA blue output
);

// generate a 25 MHz pixel strobe
reg [15:0] cnt;
reg pix_stb;
always @(posedge CLK) {pix_stb, cnt} <= cnt + 16'h4000;  // divide by 4: (2^16)/4 = 0x4000

wire [9:0] x;  // current pixel x position: 10-bit value: 0-1023
wire [8:0] y;  // current pixel y position:  9-bit value: 0-511
wire active;

vga640x480 display (
    .i_clk(CLK),
    .i_pix_stb(pix_stb),
    .i_rst(RST_BTN),
    .o_hs(VGA_HS_O), 
    .o_vs(VGA_VS_O),
    .o_active(active), 
    .o_x(x), 
    .o_y(y)
);

//

reg [6:0] inx = 0;
reg [4:0] iny = 0;
reg [7:0] text [0:80*30];
wire [7:0] inchr = text[(iny*80)+inx];
wire pixel;

always @(posedge CLK)
begin
    inx <= inx > 79 ? 0 : inx + 1;
    iny <= iny > 29 ? 0 : iny + 1;
end

vgatext vgatext_inst (
    .clk(CLK),
    .vga_x(x),
    .vga_y(y),
    .txt_x(inx),
    .txt_y(iny),
    .inchr(inchr),
    .inrdy(CLK),
    .pixel(pixel)
);

integer i;
reg [6*8-1:0] str;
initial begin
    for (i=0; i<80*30; i=i+1) text[i] = 0;
    str = "Login:";
    for (i=0; i<6; i=i+1) text[29*80+i] = str[(5-i)*8+:8];
end

assign VGA_R[3:0] = active ? {4{pixel}} : 0;
assign VGA_G[3:0] = active ? {4{pixel}} : 0;
assign VGA_B[3:0] = active ? {4{pixel}} : 0;

endmodule