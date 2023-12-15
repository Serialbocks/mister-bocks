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
   output VGA_VB,

   input        ioctl_download,
   input        ioctl_wr,
   input [24:0] ioctl_addr,
   input [7:0]  ioctl_dout,
   input [7:0]  ioctl_index,
   output reg   ioctl_wait=1'b0
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
   	 .VGA_DE(VGA_DE),
       .ioctl_dout(ioctl_dout),
	   .ioctl_wr(ioctl_wr & ioctl_download),
	   .ioctl_addr ({ 2'b0, ioctl_addr })
   );
   
endmodule
