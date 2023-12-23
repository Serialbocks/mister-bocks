`timescale 1ns/1ns
// top end ff for verilator

module top(
   input clk_pixel /*verilator public_flat*/,
   input clk_ram /*verilator public_flat*/,
   input clk_sdram /*verilator public_flat*/,
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
   output       ioctl_wait
);

reg        SDRAM_CLK;
reg [12:0] SDRAM_A;
reg  [1:0] SDRAM_BA;
reg  [15:0] SDRAM_DQ;
reg        SDRAM_DQML;
reg        SDRAM_DQMH;
reg        SDRAM_nCS;
reg        SDRAM_nCAS;
reg        SDRAM_nRAS;
reg        SDRAM_nWE;
reg        SDRAM_CKE;

assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
reg locked = 1'b0;

wire VGA_DE;
bocks_top bocks_top (
   .clk_pixel  	(clk_pixel),
   .clk_sys 		(clk_pixel),
   .clk_ram 		(clk_ram),
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
   .ioctl_addr ({ 2'b0, ioctl_addr }),
   .ioctl_wait(ioctl_wait),
   .locked(locked),
   .SDRAM_CLK      ( SDRAM_CLK),
   .SDRAM_DQ       ( SDRAM_DQ                  ),
   .SDRAM_A        ( SDRAM_A                   ),
   .SDRAM_DQMH     ( SDRAM_DQMH 				),
   .SDRAM_DQML     ( SDRAM_DQML 				),
   .SDRAM_nCS      ( SDRAM_nCS                 ),
   .SDRAM_BA       ( SDRAM_BA                  ),
   .SDRAM_nWE      ( SDRAM_nWE                 ),
   .SDRAM_nRAS     ( SDRAM_nRAS                ),
   .SDRAM_nCAS     ( SDRAM_nCAS                ),
   .SDRAM_CKE      ( SDRAM_CKE )
);
   
endmodule
