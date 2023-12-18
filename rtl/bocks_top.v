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
   output VGA_DE,

   input  [7:0] ioctl_dout,
   input        ioctl_wr,
   input [26:0] ioctl_addr
);

parameter SCALE = 2;
parameter PIXEL_COUNT = 307200; // 640 * 480
parameter PIXEL_WIDTH = 640;
parameter PIXEL_HEIGHT = 480;
parameter PIXEL_REVERSE_V_END = (5120 << (SCALE - 1));
parameter PIXEL_FORWARD_H_END = PIXEL_WIDTH - { 25'd0, CHAR_WIDTH };

parameter FONT_NUM_CHARS = 96;
parameter FONT_BMP_SIZE = 768;

parameter CHAR_WIDTH = (7'd8 << (SCALE - 1));
parameter CHAR_HEIGHT = (7'd8 << (SCALE - 1));
parameter SCREEN_CHAR_WIDTH = (PIXEL_WIDTH >> (3 + SCALE - 1));
parameter SCREEN_CHAR_HEIGHT = (PIXEL_HEIGHT >> (3 + SCALE - 1));
parameter WHITE = 8'hff;
parameter BLACK = 8'h00;

reg [7:0] font_bmp [FONT_BMP_SIZE-1:0];

//initial begin
//   $readmemh("font.mif", font_bmp, 0, FONT_BMP_SIZE-1);
//end

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
   if(ioctl_wr) begin
      font_bmp[ioctl_addr[9:0]] <= ioctl_dout;
      cpu_addr <= 32'h00000000;
      char_cnt <= 7'b0;
      char_h_bit_cnt <= 7'd0;
      char_v_bit_cnt <= 7'd0;
      char_h_cnt <= 7'd0;
      bmp_index <= 10'd0;
      cpu_wr <= 1'b0;
   end
   else if(char_cnt < FONT_NUM_CHARS) begin
      cpu_wr <= 1'b1;
      cpu_data <= font_bmp[bmp_index][3'd7 - char_h_bit_cnt[1+SCALE:SCALE-1]] ? WHITE : BLACK;

	   if(char_h_bit_cnt < CHAR_WIDTH) begin
         char_h_bit_cnt <= char_h_bit_cnt + 7'b1;
         cpu_addr <= cpu_addr + 1;
      end
      else begin
         char_h_bit_cnt <= 7'b0;
         if(char_v_bit_cnt < CHAR_HEIGHT) begin
            char_v_bit_cnt <= char_v_bit_cnt + 7'b1;
            cpu_addr <= cpu_addr + PIXEL_FORWARD_H_END;
            if(char_v_bit_cnt[0])
               bmp_index <= bmp_index + 10'b1;
         end
         else begin
            // next character
            char_v_bit_cnt <= 7'b0;
            char_cnt <= char_cnt + 7'b1;
            bmp_index <= { char_cnt + 7'b1, 3'b0 };
            if(char_h_cnt < SCREEN_CHAR_WIDTH[6:0] - 1'b1) begin
               char_h_cnt <= char_h_cnt + 1'b1;
               cpu_addr <= cpu_addr - PIXEL_REVERSE_V_END;
            end else begin
               char_h_cnt <= 7'd0;
               cpu_addr <= cpu_addr + 1;
            end
         end
      end

   end 
   else begin
      cpu_addr <= 32'h00000000;
      //char_cnt <= 7'b0;
      char_h_bit_cnt <= 7'd0;
      char_v_bit_cnt <= 7'd0;
      char_h_cnt <= 7'd0;
      bmp_index <= 10'd0;
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