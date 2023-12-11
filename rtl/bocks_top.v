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

parameter H   = 640;    // width of visible area
parameter HFP = 16;     // unused time before hsync
parameter HS  = 96;     // width of hsync
parameter HBP = 48;     // unused time after hsync

parameter V   = 400;    // height of visible area
parameter VFP = 12;     // unused time before vsync
parameter VS  = 2;      // width of vsync
parameter VBP = 35;     // unused time after vsync

parameter PIXEL_COUNT = 256000; // 640 * 400

reg[9:0]  h_cnt;        // horizontal pixel counter
reg[9:0]  v_cnt;        // vertical pixel counter

// horizontal pixel counter
always@(posedge pclk) begin
	if(h_cnt==H+HFP+HS+HBP-1)   h_cnt <= 10'b0;
	else                        h_cnt <= h_cnt + 10'b1;
end

// veritical pixel counter
always@(posedge pclk) begin
	// the vertical counter is processed at the begin of each hsync
	if(h_cnt == H+HFP) begin
		if(v_cnt==VS+VBP+V+VFP-1)  v_cnt <= 10'b0; 
		else							   v_cnt <= v_cnt + 10'b1;
	end
end

reg cpu_init = 1'b0;
reg cpu_wr = 1'b1;
reg [7:0] cpu_data = 8'b11100000;
reg [31:0] cpu_addr = 32'h00000000;


always@(posedge pclk) begin
	if(cpu_addr < PIXEL_COUNT && v_cnt < V && h_cnt < H) begin
		cpu_wr <= 1'b1;
      cpu_init <= 1'b1;
      cpu_addr <= cpu_addr + 1'b1;
      if(v_cnt < 300) begin
         if(h_cnt < 212)
            cpu_data <= 8'b11100000;
         else if(h_cnt >= 212 && h_cnt < 424)
            cpu_data <= 8'b00011100;
         else
            cpu_data <= 8'b00000011;
      end else begin
         if(h_cnt < 320)
            cpu_data <= 8'b11111111;
         else
            cpu_data <= 8'b00000000;
      end

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