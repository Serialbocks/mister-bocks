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

parameter PIXEL_COUNT = 256000; // 640 * 400
parameter PIXEL_WIDTH = 640;
parameter PIXEL_REVERSE_V_END = 5120;
parameter PIXEL_FORWARD_H_END = 632;

parameter FONT_NUM_CHARS = 96;
parameter FONT_BMP_SIZE = 768;

parameter CHAR_WIDTH = 7'd8;
parameter CHAR_HEIGHT = 7'd8;
parameter SCREEN_CHAR_WIDTH = 80;
parameter SCREEN_CHAR_HEIGHT = 50;
parameter WHITE = 8'h00;
parameter BLACK = 8'hff;

reg [7:0] font_bmp [FONT_BMP_SIZE-1:0];

initial begin
   $readmemh("font.mif", font_bmp, 0, FONT_BMP_SIZE-1);
end

reg cpu_init = 1'b0;
reg cpu_wr = 1'b0;
reg [7:0] cpu_data = 8'b00000000;
reg [31:0] cpu_addr = 32'h00000000;
reg [6:0] char_cnt = 7'd0;
reg [6:0] char_h_bit_cnt = 7'd0;
reg [6:0] char_v_bit_cnt = 7'd0;
reg [6:0] char_h_cnt = 7'd0;
reg [9:0] bmp_index = 10'd0;

// counter + addr control
always@(posedge pclk) begin
   if(char_cnt < FONT_NUM_CHARS) begin
      cpu_init <= 1'b1;
	   if(char_h_bit_cnt < CHAR_WIDTH) begin
         char_h_bit_cnt <= char_h_bit_cnt + 7'b1;
         cpu_addr <= cpu_addr + 1;
      end
      else begin
         char_h_bit_cnt <= 7'b0;
      end

      if(char_h_bit_cnt == CHAR_WIDTH) begin
         if(char_v_bit_cnt < CHAR_HEIGHT) begin
            char_v_bit_cnt <= char_v_bit_cnt + 7'b1;
            cpu_addr <= cpu_addr + PIXEL_FORWARD_H_END;
            bmp_index <= bmp_index + 10'b1;
         end
         else begin
            // next character
            char_v_bit_cnt <= 7'b0;
            char_cnt <= char_cnt + 7'b1;
            bmp_index <= { char_cnt + 7'b1, 3'b0 };
            if(char_h_cnt < SCREEN_CHAR_WIDTH - 1'b1) begin
               char_h_cnt <= char_h_cnt + 1'b1;
               cpu_addr <= cpu_addr - PIXEL_REVERSE_V_END;
            end else begin
               char_h_cnt <= 7'd0;
               cpu_addr <= cpu_addr + 1;
            end
         end
      end
   end
end

// write control
always@(posedge pclk) begin
	if(char_cnt < FONT_NUM_CHARS) begin
      cpu_wr = 1'b1;
      cpu_data <= font_bmp[bmp_index][3'd7 - char_h_bit_cnt[2:0]] == 1'b1 ? BLACK : WHITE;
   end else begin
      cpu_wr = 1'b0;
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