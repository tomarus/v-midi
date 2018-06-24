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
    output wire [3:0] VGA_B,    // 4-bit VGA blue output
    input [15:0] Activity,
    input [15:0] OUTActivity
);

// generate a 25 MHz pixel strobe
reg [15:0] cnt;
reg pix_stb;
always @(posedge CLK) {pix_stb, cnt} <= cnt + 16'h4000;  // divide by 4: (2^16)/4 = 0x4000

wire [9:0] x;  // current pixel x position: 10-bit value: 0-1023
wire [8:0] y;  // current pixel y position:  9-bit value: 0-511
wire active;
wire animate;

vga640x480 display (
    .i_clk(CLK),
    .i_pix_stb(pix_stb),
    .i_rst(RST_BTN),
    .o_hs(VGA_HS_O), 
    .o_vs(VGA_VS_O),
    .o_active(active),
    .o_animate(animate),
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
reg [22*8-1:0] str;
initial begin
    for (i=0; i<80*30; i=i+1) text[i] = 0;
    str = "TomarOS 0.1";
    for (i=0; i<11; i=i+1) text[1*80+i] = str[(10-i)*8+:8];
    str = "38911 Basic Bytes Free";
    for (i=0; i<22; i=i+1) text[3*80+i] = str[(21-i)*8+:8];
    str = "Ready.";
    for (i=0; i<6; i=i+1) text[5*80+i] = str[(5-i)*8+:8];
end

//

reg [6:0] cursor_x = 0;
reg [4:0] cursor_y = 6;
wire cursor = (x >= cursor_x * 8) && (x <= (cursor_x + 1) * 8) && (y >= cursor_y * 16) && (y <= (cursor_y + 1) * 16);

//

reg [3:0] act [0:15];
reg [3:0] oact [0:15];
reg [1:0] cntr = 0;
always @(posedge CLK)
begin
    for (i=0;i<16;i=i+1) begin
        if (Activity[i]) act[i] <= 4'b1111;
        if (OUTActivity[i]) oact[i] <= 4'b1111;
    end

    if (animate)
    begin
        cntr <= cntr + 1;
        if (cntr == 0) begin 
            for (i=0;i<16;i=i+1)
            begin
                 act[i] <= (act[i] > 0) ? act[i] - 1 : 0;
                 oact[i] <= (oact[i] > 0) ? oact[i] - 1 : 0;
            end
         end
    end
end

wire [3:0] xact = x / (640/16);
wire [3:0] off = 4'b1111 - act[xact];
wire xoff = x % (640/16) > off && (640/16) - x % (640/16) > off;
wire [3:0] activity = (y>400+off && y<440-off) && xoff ? act[xact] : 0;
wire [3:0] oactivity = (y>440+off && y<480-off) && xoff ? oact[xact] : 0;

//

assign VGA_R[3:0] = active ? {4{pixel^cursor}} | oactivity : 0;
assign VGA_G[3:0] = active ? {4{pixel^cursor}} | activity : 0;
assign VGA_B[3:0] = active ? {4{pixel^cursor}} : 0;

endmodule