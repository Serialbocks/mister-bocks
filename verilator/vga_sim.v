`timescale 1ns/1ns
// top end ff for verilator

module top(
   input clk_sys /*verilator public_flat*/,
   input reset /*verilator public_flat*/,
   input button /*verilator public_flat*/,

   output [7:0] VGA_R /*verilator public_flat*/,
   output [7:0] VGA_G /*verilator public_flat*/,
   output [7:0] VGA_B /*verilator public_flat*/,
   
   output VGA_HS,
   output VGA_VS,
   output VGA_HB,
   output VGA_VB
);
   wire [7:0] color = button ? 8'b111_000_00 : 8'hFF;

   wire VGA_DE;
   vga vga (
   	 .pclk  (clk_sys),
   	 .color (color),
   	 .hs    (VGA_HS),
   	 .vs    (VGA_VS),
   	 .r     (VGA_R),
   	 .g     (VGA_G),
   	 .b     (VGA_B),
       .VGA_HB(VGA_HB),
       .VGA_VB(VGA_VB),
   	 .VGA_DE(VGA_DE)
   );
   
endmodule
