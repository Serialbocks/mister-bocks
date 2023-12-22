module bocks_top (
   // pixel clock
   input  clk_pixel,
   input  clk_ram,
   input  clk_sys,

   // VGA output
   output 	hs,
   output 	vs,
   output [7:0] r,
   output [7:0] g,
   output [7:0] b,
   output VGA_HB,
   output VGA_VB,
   output VGA_DE,

   // HPS File IO
   input  [7:0] ioctl_dout,
   input        ioctl_wr,
   input [26:0] ioctl_addr,
   input locked,

   // sdram signals
   output        SDRAM_CLK,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,
   output        SDRAM_CKE
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
parameter SCREEN_CHAR_WIDTH = (PIXEL_WIDTH >> (3 + SCALE - 1)); // 40 for scale 2
parameter SCREEN_CHAR_HEIGHT = (PIXEL_HEIGHT >> (3 + SCALE - 1)); // 30 for scale 2
parameter SCREEN_CHAR_TOTAL = 11'd1200; // For scale 2
parameter WHITE = 8'hff;
parameter BLACK = 8'h00;
parameter RED = 8'he0;

reg [7:0] screen_chars [SCREEN_CHAR_TOTAL-1:0];

reg [7:0] font_bmp [FONT_BMP_SIZE-1:0];

reg cpu_wr = 1'b0;
reg [7:0] cpu_data = 8'b00000000;
reg [31:0] cpu_addr = 32'h00000000;
reg [10:0] char_cnt = 11'd0;
reg [6:0] char_h_bit_cnt = 7'd0;
reg [6:0] char_v_bit_cnt = 7'd0;
reg [6:0] char_h_cnt = 7'd0;
reg [9:0] bmp_index;
reg [7:0] char_color = WHITE;

// counter + addr control
always@(posedge clk_sys) begin
   if(ioctl_wr) begin
      font_bmp[ioctl_addr[9:0]] <= ioctl_dout;
      cpu_addr <= 32'h00000000;
      char_cnt <= 11'b0;
      char_h_bit_cnt <= 7'd0;
      char_v_bit_cnt <= 7'd0;
      char_h_cnt <= 7'd0;
      bmp_index <= { screen_chars[11'b0][6:0], 3'b0 };
      cpu_wr <= 1'b0;
   end
   else if(char_cnt < SCREEN_CHAR_TOTAL) begin
      cpu_data <= font_bmp[bmp_index][3'd7 - char_h_bit_cnt[1+SCALE:SCALE-1]] ? char_color : BLACK;

	   if(char_h_bit_cnt < CHAR_WIDTH) begin
         cpu_wr <= char_v_bit_cnt == CHAR_HEIGHT ? 1'b0 : 1'b1;
         char_h_bit_cnt <= char_h_bit_cnt + 7'b1;
         cpu_addr <= cpu_addr + 1;
      end
      else begin
         cpu_wr <= 1'b0;
         char_h_bit_cnt <= 7'b0;
         if(char_v_bit_cnt < CHAR_HEIGHT) begin
            char_v_bit_cnt <= char_v_bit_cnt + 7'b1;
            cpu_addr <= cpu_addr + PIXEL_FORWARD_H_END;
            if(SCALE == 1 || char_v_bit_cnt[SCALE - 2])
               bmp_index <= bmp_index + 10'b1;
         end
         else begin
            // next character
            char_v_bit_cnt <= 7'b0;
            char_cnt <= char_cnt + 11'b1;
            bmp_index <= { screen_chars[char_cnt + 11'b1][6:0], 3'b0 };
            if(char_h_cnt < SCREEN_CHAR_WIDTH[6:0] - 1'b1) begin
               char_h_cnt <= char_h_cnt + 1'b1;
               cpu_addr <= cpu_addr - PIXEL_REVERSE_V_END;
            end else begin
               char_h_cnt <= 7'd0;
               cpu_addr <= cpu_addr - PIXEL_WIDTH;
            end
         end
      end

   end 
   else begin
      cpu_addr <= 32'h00000000;
      char_h_bit_cnt <= 7'd0;
      char_v_bit_cnt <= 7'd0;
      char_h_cnt <= 7'd0;
      bmp_index <= { screen_chars[11'b0][6:0], 3'b0 };
      char_cnt <= 11'b0;
      cpu_wr <= 1'b0;
   end
end

reg [23:0] clk_div, clk_div2;
wire clk_slow = clk_div[15];
reg prev_clk_slow = 1'b0;
always @(posedge clk_sys)
	clk_div <= clk_div + 24'd1;

always @(posedge clk_slow) begin
   if(char_color == RED) begin
      clk_div2 <= clk_div2 + 24'd1;
   end
   else begin
      clk_div2 <= 24'd0;
   end
end
	

reg refresh = 1'b1;
reg[24:0]  ch0_addr = ADDR_START;
reg        ch0_rd = 1'd1;
reg        ch0_wr = 1'd0;
reg [7:0]  ch0_din = 8'd0;
wire [7:0] ch0_dout;
wire       ch0_busy;
reg[2:0] wr_state = STATE_INITIALIZING;
reg[2:0] rd_state = STATE_IDLE;
reg ch0_wr_done = 1'b0;

// test text output
wire [15:0] byte_text;
wire [63:0] addr_text;

byte_to_hex_text byte_to_hex_text(
   .data(ch0_dout),
   .text(byte_text)
);

quad_to_hex_text quad_to_hex_text(
   .data({ 7'd0, ch0_addr }),
   .text(addr_text)
);

localparam STATE_IDLE  = 3'b000;
localparam STATE_WRITE = 3'b001;
localparam STATE_WAIT  = 3'b010;
localparam STATE_READ  = 3'b011;
localparam STATE_WAIT_LONGER = 3'b100;
localparam STATE_INITIALIZING = 3'b101;
localparam ADDR_TEST_COUNT = 25'b1111111111111111111111111;
localparam ADDR_START = 25'h0000000;

// Test writing to sdram
always@(posedge clk_sys) begin
    if(ioctl_wr || refresh) begin 
      refresh <= 1'b0;
    end
    else 
    if(!ch0_wr_done && (ch0_addr - ADDR_START) < ADDR_TEST_COUNT) begin
      if(wr_state == STATE_INITIALIZING) begin
         wr_state <= clk_slow ? STATE_IDLE : STATE_INITIALIZING;
      end
      else if(wr_state == STATE_IDLE) begin
         wr_state <= STATE_WRITE;
         ch0_din <= ch0_addr[7:0];
      end
      else if(wr_state == STATE_WRITE) begin
         ch0_wr <= 1'b1;
         wr_state <= STATE_WAIT;
      end
      else if(wr_state == STATE_WAIT) begin
         wr_state <= ch0_busy ? STATE_WAIT : STATE_WAIT_LONGER;
      end
      else if(wr_state == STATE_WAIT_LONGER) begin
         ch0_wr <= 1'b0;
         ch0_addr <= ch0_addr + 25'd1;
         wr_state <= STATE_IDLE;
         refresh <= 1'b1;
      end
   end
   else if(!ch0_wr_done) begin
      ch0_wr_done <= 1'b1;
      ch0_addr <= ADDR_START;
      ch0_din <= 8'd0;
   end
   else if(ch0_wr_done && (ch0_addr - ADDR_START) < ADDR_TEST_COUNT) begin
      if(rd_state == STATE_IDLE) begin
         if(prev_clk_slow != clk_slow && (char_color == WHITE || clk_div2[8])) begin
            char_color <= WHITE;
            rd_state <= STATE_READ;
            ch0_rd <= 1'b1;
         end
         else begin
            refresh <= 1'b1;
         end
         prev_clk_slow <= clk_slow;
      end
      else if(rd_state == STATE_READ) begin
         rd_state <= STATE_WAIT;
      end
      else if(rd_state == STATE_WAIT) begin
         rd_state <= ch0_busy ? STATE_WAIT : STATE_WAIT_LONGER;
      end
      else if(rd_state == STATE_WAIT_LONGER) begin
         if(ch0_dout != ch0_addr[7:0]) begin
            char_color <= RED;
         end
         else begin
            char_color <= WHITE;
         end

         screen_chars[11'd0] <= addr_text[63:56];
         screen_chars[11'd1] <= addr_text[55:48];
         screen_chars[11'd2] <= addr_text[47:40];
         screen_chars[11'd3] <= addr_text[39:32];
         screen_chars[11'd4] <= addr_text[31:24];
         screen_chars[11'd5] <= addr_text[23:16];
         screen_chars[11'd6] <= addr_text[15:8];
         screen_chars[11'd7] <= addr_text[7:0];

         screen_chars[11'd9] <= byte_text[15:8];
         screen_chars[11'd10] <= byte_text[7:0];

         ch0_rd <= 1'b0;
         ch0_addr <= ch0_addr + 25'd1;
         rd_state <= STATE_IDLE;
      end
   end
   else if(ch0_wr_done) begin
      ch0_addr <= ADDR_START;
      ch0_wr_done <= 1'b0;
   end
end

sdram sdram
(
   .SDRAM_CLK	    ( SDRAM_CLK     ),
	.SDRAM_DQ       ( SDRAM_DQ      ),
   .SDRAM_A        ( SDRAM_A       ),
	.SDRAM_DQMH     ( SDRAM_DQMH 	  ),
	.SDRAM_DQML     ( SDRAM_DQML 	  ),
   .SDRAM_nCS      ( SDRAM_nCS     ),
   .SDRAM_BA       ( SDRAM_BA      ),
   .SDRAM_nWE      ( SDRAM_nWE     ),
   .SDRAM_nRAS     ( SDRAM_nRAS    ),
   .SDRAM_nCAS     ( SDRAM_nCAS    ),
   .SDRAM_CKE      ( SDRAM_CKE     ),

	// system interface
	.clk        (clk_ram),
	.init       (1'b0),

	// cpu/chipset interface
	.ch0_addr   (ch0_addr),
	.ch0_wr     (ch0_wr),
	.ch0_din    (ch0_din),
	.ch0_rd     (ch0_rd),
	.ch0_dout   (ch0_dout),
	.ch0_busy   (ch0_busy),

	.ch1_addr   ( ),
	.ch1_wr     ( 1'b0 ),
	.ch1_din    ( ),
	.ch1_rd     ( 1'b0 ),
	.ch1_dout   ( ),
	.ch1_busy   ( ),

	// reserved for backup ram save/load
	.ch2_addr   ( ),
	.ch2_wr     ( 1'b0 ),
	.ch2_din    ( ),
	.ch2_rd     ( 1'b0 ),
	.ch2_dout   ( ),
	.ch2_busy   ( ),

	.refresh    (refresh)
);

vga vga (
	.clk_pixel(clk_pixel),
	.clk_cpu(clk_sys),
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