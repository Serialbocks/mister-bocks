module bocks_top (
   // pixel clock
   input  clk_pixel,
   input  clk_ram,
   input  clk_sys,

   // VGA output
   output     hs,
   output     vs,
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
   output       ioctl_wait,
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
   output        SDRAM_CKE,

   output [3:0] test_cpu_state,
   output [2:0] test_ioctl_state,
   output [7:0] test_ch0_dout,
   output [24:0] test_ch0_addr
);

parameter SCALE = 2;
parameter PIXEL_COUNT = 307200; // 640 * 480
parameter PIXEL_WIDTH = 640;
parameter PIXEL_HEIGHT = 480;
parameter PIXEL_REVERSE_V_END = (5120 << (SCALE - 1));
parameter PIXEL_FORWARD_H_END = PIXEL_WIDTH - { 25'd0, CHAR_WIDTH };

parameter FONT_NUM_CHARS = 96;

parameter CHAR_WIDTH = (7'd8 << (SCALE - 1));
parameter CHAR_HEIGHT = (7'd8 << (SCALE - 1));
parameter SCREEN_CHAR_WIDTH = (PIXEL_WIDTH >> (3 + SCALE - 1)); // 40 for scale 2
parameter SCREEN_CHAR_HEIGHT = (PIXEL_HEIGHT >> (3 + SCALE - 1)); // 30 for scale 2
parameter SCREEN_CHAR_TOTAL = 11'd1200; // For scale 2
parameter WHITE = 8'hff;
parameter BLACK = 8'h00;
parameter RED = 8'he0;

localparam FONT_ADDR_START = 25'h0000000;
localparam IOCTL_STATE_IDLE = 3'b000;
localparam IOCTL_STATE_WRITE = 3'b001;
localparam IOCTL_STATE_WAIT = 3'b010;
localparam IOCTL_STATE_REFRESH = 3'b011;

assign ioctl_wait = !initialized || ioctl_state != IOCTL_STATE_IDLE;
assign refresh = set_refresh || ioctl_state == IOCTL_STATE_WAIT;

// initialization
reg [27:0] init_state = 28'd0;
wire initialized;
assign initialized = init_state[23];
always@(posedge clk_sys) begin
   if(!initialized) begin
      init_state <= init_state + 28'd1;
      if(init_state[19]) begin
         sdram_init <= 1'b0;
      end
   end
end

// ch0 input control
assign test_ch0_addr = ch0_addr;
always@(posedge clk_sys) begin
   if(ioctl_wait || ioctl_wr)
      ch0_addr <=ioctl_addr[24:0] + FONT_ADDR_START;
   else if(cpu_state == CPU_STATE_SCREEN_INIT || 
      cpu_state == CPU_STATE_SCREEN_WRITE || 
      cpu_state == CPU_STATE_SCREEN_WRITE_WAIT || 
      cpu_state == CPU_STATE_SCREEN_WRITE_WAIT2 ||
      cpu_state == CPU_STATE_SCREEN_READ ||
      cpu_state == CPU_STATE_SCREEN_READ_WAIT ||
      cpu_state == CPU_STATE_SCREEN_READ_WAIT2)
      ch0_addr <= SCREEN_ADDR_START + { 14'd0, char_index };   
   else
      ch0_addr <= FONT_ADDR_START + { 15'd0, bmp_index };

   if(ioctl_state == IOCTL_STATE_WRITE ||
      cpu_state == CPU_STATE_SCREEN_WRITE_WAIT)
      ch0_wr <= 1'd1;
   else if(ioctl_state == IOCTL_STATE_REFRESH ||
      cpu_state == CPU_STATE_SCREEN_WRITE_WAIT2)
      ch0_wr <= 1'd0;
end

// ioctl state machine
reg [2:0] ioctl_state = IOCTL_STATE_IDLE;
assign test_ioctl_state = ioctl_state;
always@(posedge clk_sys) begin
   if(!initialized) begin end
   else if(ioctl_state == IOCTL_STATE_IDLE && ioctl_wr) begin
      ioctl_state <= IOCTL_STATE_WRITE;
   end
   else if(ioctl_state == IOCTL_STATE_WRITE) begin
      ioctl_state <= IOCTL_STATE_WAIT;
   end
   else if(ioctl_state == IOCTL_STATE_WAIT) begin
      ioctl_state <= ch0_busy ? IOCTL_STATE_WAIT : IOCTL_STATE_REFRESH;
   end
   else if(ioctl_state == IOCTL_STATE_REFRESH) begin
      ioctl_state <= IOCTL_STATE_IDLE;
   end
end

reg cpu_wr = 1'b0;
reg [7:0] cpu_data = 8'b00000000;
reg [31:0] cpu_addr = 32'h00000000;
reg [10:0] char_index = 11'd0;
reg [6:0] char_h_bit_cnt = 7'd0;
reg [6:0] char_v_bit_cnt = 7'd0;
reg [6:0] char_h_cnt = 7'd0;
reg [9:0] bmp_index;
reg [7:0] bmp_data;
reg [7:0] char_color = WHITE;
reg [7:0] screen_char = 8'b0;

localparam CPU_STATE_IDLE = 4'b0000;
localparam CPU_STATE_READ_FONT = 4'b0001;
localparam CPU_STATE_READ_FONT_WAIT = 4'b0010;
localparam CPU_STATE_PROCESS = 4'b0011;
localparam CPU_STATE_SCREEN_INIT = 4'b0100;
localparam CPU_STATE_SCREEN_WRITE = 4'b0101;
localparam CPU_STATE_SCREEN_WRITE_WAIT = 4'b0110;
localparam CPU_STATE_SCREEN_WRITE_WAIT2 = 4'b0111;
localparam CPU_STATE_SCREEN_READ = 4'b1000;
localparam CPU_STATE_SCREEN_READ_WAIT = 4'b1001;
localparam CPU_STATE_SCREEN_READ_WAIT2 = 4'b1010;

localparam SCREEN_ADDR_START = 25'h0002000;

// CPU state machine
reg [3:0] cpu_state = CPU_STATE_SCREEN_INIT;
assign test_cpu_state = cpu_state;
assign test_ch0_dout = ch0_dout;
always@(posedge clk_sys) begin
   if(ioctl_state == IOCTL_STATE_IDLE && !ioctl_wr && initialized) begin
      if(cpu_state == CPU_STATE_IDLE) begin
         cpu_state <= CPU_STATE_READ_FONT;
         set_refresh <= 1'b0;
      end
      else if(cpu_state == CPU_STATE_READ_FONT) begin
         cpu_state <= CPU_STATE_READ_FONT_WAIT;
         ch0_rd <= 1'b1;
      end
      else if(cpu_state == CPU_STATE_READ_FONT_WAIT) begin
         ch0_rd <= 1'b0;
         if(!ch0_busy) begin
            bmp_data <= ch0_dout;
            cpu_state <= CPU_STATE_PROCESS;
            set_refresh <= 1'b1;
         end
      end
      else if(cpu_state == CPU_STATE_SCREEN_READ) begin
         cpu_state <= ch0_busy ? 
            CPU_STATE_SCREEN_READ_WAIT : CPU_STATE_SCREEN_READ;
         ch0_rd <= 1'b1;
      end
      else if(cpu_state == CPU_STATE_SCREEN_READ_WAIT) begin
         if(!ch0_busy) begin
            ch0_rd <= 1'b0;
            screen_char <= ch0_dout;
            cpu_state <= CPU_STATE_SCREEN_READ_WAIT2;
         end
      end
      else if(cpu_state == CPU_STATE_SCREEN_READ_WAIT2) begin
         bmp_index <= { screen_char[6:0], 3'b0 };
         cpu_state <= CPU_STATE_IDLE;
      end
      else if(cpu_state == CPU_STATE_SCREEN_INIT) begin
         if(initialized) begin
            if(char_index < SCREEN_CHAR_TOTAL)
               cpu_state <= CPU_STATE_SCREEN_WRITE;
            else begin
               cpu_state <= CPU_STATE_IDLE;
               char_index <= 11'd0;
            end
         end
      end
      else if(cpu_state == CPU_STATE_SCREEN_WRITE) begin
         cpu_state <= CPU_STATE_SCREEN_WRITE_WAIT;
      end
      else if(cpu_state == CPU_STATE_SCREEN_WRITE_WAIT) begin
         cpu_state <= ch0_busy ? 
            CPU_STATE_SCREEN_WRITE_WAIT : CPU_STATE_SCREEN_WRITE_WAIT2;
      end
      else if(cpu_state == CPU_STATE_SCREEN_WRITE_WAIT2) begin
         char_index <= char_index + 11'd1;
         cpu_state <= CPU_STATE_SCREEN_INIT;
      end
      else if(cpu_state == CPU_STATE_PROCESS) begin
         if(char_index < SCREEN_CHAR_TOTAL) begin
            cpu_data <= bmp_data[3'd7 - char_h_bit_cnt[1+SCALE:SCALE-1]] ? 
               char_color : BLACK;

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
                  if(SCALE == 1 || char_v_bit_cnt[SCALE - 2]) begin
                     bmp_index <= bmp_index + 10'b1;
                     cpu_state <= CPU_STATE_IDLE;
                  end
               end
               else begin
                  // next character
                  char_v_bit_cnt <= 7'b0;
                  char_index <= char_index + 11'b1;
                  //bmp_index <= { screen_chars[char_index + 11'b1][6:0], 3'b0 };
                  cpu_state <= CPU_STATE_SCREEN_READ;
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
            //bmp_index <= { screen_chars[11'b0][6:0], 3'b0 };
            cpu_state <= CPU_STATE_SCREEN_READ;
            char_index <= 11'b0;
            cpu_wr <= 1'b0;
            //cpu_state <= CPU_STATE_IDLE;
         end
      end
   end
   else begin
      cpu_addr <= 32'h00000000;
      char_index <= 11'b0;
      char_h_bit_cnt <= 7'd0;
      char_v_bit_cnt <= 7'd0;
      char_h_cnt <= 7'd0;
      cpu_wr <= 1'b0;
      cpu_state <= CPU_STATE_SCREEN_INIT;
   end
   
end

wire refresh;
reg set_refresh = 1'b0;
reg sdram_init = 1'b1;
reg[24:0] ch0_addr;
reg        ch0_rd = 1'd1;
reg ch0_wr = 1'd0;
wire [7:0] ch0_din = (ioctl_wait || ioctl_wr) ? 
   ioctl_dout : 
   char_index < 11'd96 ? char_index[7:0] : 8'd0;
wire [7:0] ch0_dout;
wire       ch0_busy;

sdram sdram
(
   .SDRAM_CLK      ( SDRAM_CLK     ),
   .SDRAM_DQ       ( SDRAM_DQ      ),
   .SDRAM_A        ( SDRAM_A       ),
   .SDRAM_DQMH     ( SDRAM_DQMH    ),
   .SDRAM_DQML     ( SDRAM_DQML    ),
   .SDRAM_nCS      ( SDRAM_nCS     ),
   .SDRAM_BA       ( SDRAM_BA      ),
   .SDRAM_nWE      ( SDRAM_nWE     ),
   .SDRAM_nRAS     ( SDRAM_nRAS    ),
   .SDRAM_nCAS     ( SDRAM_nCAS    ),
   .SDRAM_CKE      ( SDRAM_CKE     ),

    // system interface
    .clk        (clk_ram),
    .init       (sdram_init),

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