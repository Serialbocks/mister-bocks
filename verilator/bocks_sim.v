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

   wire VGA_DE;
   bocks_top bocks_top (
   	 .pclk  (clk_sys),
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
