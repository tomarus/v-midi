`timescale 1ns / 1ps

module master(
    input  clk,
    input  btnC,
    input [1:0]JC,
    output [6:0]seg,
    output [3:0]an,
    output dp,
    output [15:0]led,
    output [1:0]JB
);

//

reg rst = 1;
reg [3:0] dpis = 4'b1111;
wire blinky;
wire [15:0] byte;
reg [15:0] sbyte = 0;

sevenseg sw_led_inst (clk, byte[3:0], byte[7:4], byte[11:8], byte[15:12], dpis[3:0], seg[6:0], dp, an[3:0]);
tempo tempo_inst (clk, blinky);

reg [1:0]w;
always @(posedge blinky)
begin
    dpis[3:0] = 4'b1111;
    w <= w + 1;
    dpis[3-w] = 0;
end

wire  btnC_db;
onetimeclick otc_btnC (clk, btnC, btnC_db);

//

localparam NPORTS = 2;

reg [NPORTS-1:0] txdv;
reg [NPORTS*8-1:0] txdata;
wire [NPORTS*8-1:0] rxdata;
wire [NPORTS-1:0] rxdv;
midi_port ports[NPORTS-1:0] (clk, rst, txdv, JB, txdata, rxdv, JC, rxdata);

//


//reg [36:0]cfg = 36'b111111111111111111111111111111111111;

reg [3:0]port;

reg reset_running;
reg [4:0] reset_counter;
reg [4:0] chcnt = 0;
reg [3:0] msgcnt = 0;

reg sysex_running = 0;
reg [4:0] sysex_runpos = 0;
reg [16*8-1:0] sxdata = 0; // 16 * 8 bits of sysex command max
reg [4:0] sxpos = 0;

reg [NPORTS*2-1:0] portstate;

always @(posedge clk)
begin
    rst <= 0;

    if (reset_running)
        runreset();
    else if (btnC_db) begin
        reset_counter <= 0;
        reset_running <= 1;
        chcnt <= 0;
        msgcnt <= 0;
    end
    else begin
        for (port=0; port<NPORTS; port=port+1) begin
            txdv[port] = 0;
        end
        if (sysex_running) runsysex();
        for (port=0; port<NPORTS; port=port+1) begin
            if (rxdv[port]) begin
                handlebyte(port, rxdata[port*8+:8], portstate[port*2+:2]);
            end
        end
    end

    counter();
end

localparam s_IDLE = 2'b00;
localparam s_DATA = 2'b01;
localparam s_SYSEX = 2'b10;

localparam sx_BEGIN = 2'b00;
localparam sx_ID1 = 2'b01;
localparam sx_ID2 = 2'b10;
localparam sx_BUF = 2'b11;
reg [NPORTS*2-1:0] sxstate;

task handlebyte;
input [3:0]port;
input [7:0]byte;
input [2:0]state;
begin
    case (byte[7])
    // command
    1'b1:
        begin
            case (byte[7:0])
            8'hf8: begin
                // skip klok
            end
            8'hf0: begin
                sendbyte(port, byte);
                portstate[port*2+:2] <= s_SYSEX;
                sxstate[port*2+:2] <= sx_BEGIN;
            end
            8'hf7: begin
                sendbyte(port, byte);
                portstate[port*2+:2] <= s_IDLE;
                sysex_running <= 1;
                sysex_runpos <= 0;

                reset_counter <= 0;
                chcnt <= 0;
            end
            default: begin
                sendbyte(port, byte);
            end
            endcase
        end
     // data
     1'b0:
        begin
            sendbyte(port, byte);

            case (state[2:0])
//            s_IDLE:
//            s_DATA:
            s_SYSEX:
                begin
                 handlesysex(port, byte[7:0]);
                end
            endcase
        end
    endcase
end
endtask

//  output.send
//      0xf0, 0x7d,        // sysex, non commercial / educational manufacturer id.
//      0x2a, 0x4d,        // my own little secret magic number id for this router.
//      0x00,              // COMMAND 0x00 = request sysex config dump.
//      0xf7
//  response = 0xf0, 0x7d, 0x2a, 0x4d,
//      0x40, 0x01,            // RESPONSE 0x40, version 1
//      0x01, 0x02,            // 1 inport, 2 outports
//      byte(int(bpm) >> 7),   // current speet msb
//      byte(int(bpm) & 0x7f), // current speed lsb
//      0xf7

reg [11*8-1:0] cfg = 'hf0_7d_2a_4d_40_01_02_02_00_70_f7;

task runsysex;
begin
    if (sxpos == 0 || sxdata[7:0] != 0) begin // cnd 0 = request config dunp
//    if (sxpos == 0) begin // cnd 0 = request config dunp
        sysex_running <= 0;
    end
    else begin
        allportmsg(cfg[(11-reset_counter)*8+:8]);
        reset_counter <= reset_counter + 1;
        if (reset_counter == 8'd11) begin
            sysex_running <= 0;
       end
    end
end
endtask

task handlesysex;
input [3:0]port;
input [7:0]byte;
begin
   case (sxstate[port*2+:2])
    sx_BEGIN: begin
        if (byte[7:0] == 8'h7d) sxstate[port*2+:2] <= sx_ID1;
    end
    sx_ID1: begin
        if (byte[7:0] == 8'h2a) sxstate[port*2+:2] <= sx_ID2;
    end
    sx_ID2: begin
        if (byte[7:0] == 8'h4d) begin
            sbyte = 16'b0000000000000000;
            sxstate[port*2+:2] <= sx_BUF;
            sxpos[4:0] <= 4'b0000;
        end
    end
    sx_BUF:
        begin
            sxdata[sxpos*8+:8] <= byte[7:0];
            sxpos <= sxpos + 1;
        end
    endcase
end
endtask

// reset

task runreset;
begin
    case (reset_counter)
    3'h0: begin
        allportmsg(8'hfc);
        reset_counter <= reset_counter + 1;
    end
    3'h1:
        allportallchmsg(8'hb0, 8'h78, 8'h00); // All sound off
    3'h2:
        allportallchmsg(8'hb0, 8'h79, 8'h00); // Reset all controllers
    3'h3:
        allportallchmsg(8'hb0, 8'h7b, 8'h00); // All notes off
    3'h4: begin
        reset_running <= 0;
    end
    endcase
end
endtask

task allportallchmsg;
input [7:0]msg1, msg2, msg3;
begin
    case (msgcnt)
    3'b000: begin
        allportmsg(msg1 + chcnt);
        msgcnt <= msgcnt + 1;
    end
    3'b001: begin
        allportmsg(msg2);
        msgcnt <= msgcnt + 1;
    end
    3'b010: begin
        allportmsg(msg3);
        msgcnt <= 0;

        if (chcnt == 4'd15) begin
            reset_counter <= reset_counter + 1;
            chcnt <= 0;
        end
        else begin
            chcnt <= chcnt + 1;
        end
    end
    endcase
end
endtask

task allportmsg;
input [7:0]msg;
    for (port=0; port<NPORTS; port=port+1) begin
        sendbyte(port, msg);
    end
endtask

task sendbyte;
input [3:0] port;
input [7:0] byte;
begin
    txdata[port*8+:8] <= byte[7:0];
    txdv[port] = 1;
end
endtask

// debug counter

task counter;
    if (rxdv[0] || rxdv[1])
        sbyte = sbyte + 1;
    else if (btnC_db)
        sbyte = 16'b0000000000000000;
endtask

//

assign byte = sbyte;
assign led[15:0] = sbyte[15:0];
endmodule