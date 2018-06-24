module vga_char_rom (
    input clk,
    input [11:0] addr,
    output reg [7:0] data
);

reg [7:0] char_ram [0:2048];
initial begin
    $readmemb("char_rom.data", char_ram);
end

always @(posedge clk) data <= char_ram[addr];

endmodule