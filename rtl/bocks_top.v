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

reg cpu_init = 1'b0;
reg cpu_wr = 1'b1;
reg [7:0] cpu_data = 8'b00011100;
reg [31:0] cpu_addr = 32'h00000000;

always@(posedge pclk) begin
	if(cpu_addr < 256000) begin
		cpu_wr <= 1'b1;
      cpu_data <= 8'b00011100;
      cpu_init <= 1'b1;
      cpu_addr <= cpu_addr + 1'b1;
	end
   else begin
      cpu_wr <= 1'b0;
   end
end

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
   .VGA_HB(VGA_HB),
   .VGA_VB(VGA_VB),
   .VGA_DE(VGA_DE)
);

endmodule