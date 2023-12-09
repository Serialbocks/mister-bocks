module bocks_top (
   // pixel clock
   input  pclk,
   // VGA output
   output 	hs,
   output 	vs,
   output [7:0] r,
   output [7:0] g,
   output [7:0] b,
   output VGA_HB,
   output VGA_VB,
   output VGA_DE
);

wire cpu_wr = 0;
wire [7:0] cpu_data = 8'h00;
wire [31:0] cpu_addr = 32'h00000000;

vga vga (
	 .pclk  (pclk),
	 .cpu_clk(pclk),
	 .cpu_wr(cpu_wr),
	 .cpu_addr(cpu_addr),
	 .cpu_data(cpu_data),
	 .hs    (hs),
	 .vs    (vs),
	 .r     (r),
	 .g     (g),
	 .b     (b),
	 .VGA_DE(VGA_DE)
);

endmodule