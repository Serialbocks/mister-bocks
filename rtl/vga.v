
// (c) 2023 John Jones

// VGA controller generating 160x100 pixles. The VGA mode ised is 640x400
// combining every 4 row and column

// http://tinyvga.com/vga-timing/640x400@70Hz

module vga (
	// pixel clock
	input  pclk,

	// VGA output
	output reg	hs,
	output reg 	vs,
	output [7:0] r,
	output [7:0] g,
	output [7:0] b,
	output reg VGA_HB,
	output reg VGA_VB,
	output VGA_DE
);
					
// 640x400 70HZ VESA according to  http://tinyvga.com/vga-timing/640x400@70Hz

parameter H   = 640;    // width of visible area
parameter HFP = 16;     // unused time before hsync
parameter HS  = 96;     // width of hsync
parameter HBP = 48;     // unused time after hsync

parameter V   = 400;    // height of visible area
parameter VFP = 12;     // unused time before vsync
parameter VS  = 2;      // width of vsync
parameter VBP = 35;     // unused time after vsync

parameter PIXEL_COUNT = 256000; // 640 * 400

parameter FONT_NUM_CHARS = 96;
parameter FONT_BMP_SIZE = 768;

parameter CHAR_WIDTH = 8;
parameter CHAR_HEIGHT = 8;
parameter SCREEN_CHAR_WIDTH = 80;
parameter SCREEN_CHAR_HEIGHT = 50;
parameter WHITE = 8'h00;
parameter BLACK = 8'hff;

reg [7:0] vmem [PIXEL_COUNT-1:0];

reg [7:0] font_bmp [FONT_BMP_SIZE-1:0];
reg [17:0] cursor_index;
reg cursor_init = 1'b0;

initial begin
   $readmemh("font.mif", font_bmp, 0, FONT_BMP_SIZE-1);
end

wire [17:0] row;
wire [17:0] column;
wire [9:0] bmp_index0, bmp_index1, bmp_index2, bmp_index3, bmp_index4, bmp_index5, bmp_index6, bmp_index7;
wire [17:0] row0_pixel, row1_pixel, row2_pixel, row3_pixel, row4_pixel, row5_pixel, row6_pixel, row7_pixel;

assign row = cursor_index / 18'd80;
assign column = cursor_index - (row * 18'd80);
assign bmp_index0 = 10'd8 * cursor_index[9:0];
assign bmp_index1 = bmp_index0 + 10'd1;
assign bmp_index2 = bmp_index1 + 10'd1;
assign bmp_index3 = bmp_index2 + 10'd1;
assign bmp_index4 = bmp_index3 + 10'd1;
assign bmp_index5 = bmp_index4 + 10'd1;
assign bmp_index6 = bmp_index5 + 10'd1;
assign bmp_index7 = bmp_index6 + 10'd1;
assign row0_pixel = (18'd8 * 18'd640 * row) +
	(column * 18'd8);
assign row1_pixel = row0_pixel + 18'd640;
assign row2_pixel = row1_pixel + 18'd640;
assign row3_pixel = row2_pixel + 18'd640;
assign row4_pixel = row3_pixel + 18'd640;
assign row5_pixel = row4_pixel + 18'd640;
assign row6_pixel = row5_pixel + 18'd640;
assign row7_pixel = row6_pixel + 18'd640;

// Copy characters over
always@(posedge pclk) begin
	if(cursor_index < FONT_NUM_CHARS) begin
		// Char row 0
		vmem[row0_pixel] 		 <= font_bmp[bmp_index0][7] ? BLACK : WHITE;
		vmem[row0_pixel + 18'd1] <= font_bmp[bmp_index0][6] ? BLACK : WHITE;
		vmem[row0_pixel + 18'd2] <= font_bmp[bmp_index0][5] ? BLACK : WHITE;
		vmem[row0_pixel + 18'd3] <= font_bmp[bmp_index0][4] ? BLACK : WHITE;
		vmem[row0_pixel + 18'd4] <= font_bmp[bmp_index0][3] ? BLACK : WHITE;
		vmem[row0_pixel + 18'd5] <= font_bmp[bmp_index0][2] ? BLACK : WHITE;
		vmem[row0_pixel + 18'd6] <= font_bmp[bmp_index0][1] ? BLACK : WHITE;
		vmem[row0_pixel + 18'd7] <= font_bmp[bmp_index0][0] ? BLACK : WHITE;

		// Char row 1
		vmem[row1_pixel] 		 <= font_bmp[bmp_index1][7] ? BLACK : WHITE;
		vmem[row1_pixel + 18'd1] <= font_bmp[bmp_index1][6] ? BLACK : WHITE;
		vmem[row1_pixel + 18'd2] <= font_bmp[bmp_index1][5] ? BLACK : WHITE;
		vmem[row1_pixel + 18'd3] <= font_bmp[bmp_index1][4] ? BLACK : WHITE;
		vmem[row1_pixel + 18'd4] <= font_bmp[bmp_index1][3] ? BLACK : WHITE;
		vmem[row1_pixel + 18'd5] <= font_bmp[bmp_index1][2] ? BLACK : WHITE;
		vmem[row1_pixel + 18'd6] <= font_bmp[bmp_index1][1] ? BLACK : WHITE;
		vmem[row1_pixel + 18'd7] <= font_bmp[bmp_index1][0] ? BLACK : WHITE;

		// Char row 2
		vmem[row2_pixel] 		 <= font_bmp[bmp_index2][7] ? BLACK : WHITE;
		vmem[row2_pixel + 18'd1] <= font_bmp[bmp_index2][6] ? BLACK : WHITE;
		vmem[row2_pixel + 18'd2] <= font_bmp[bmp_index2][5] ? BLACK : WHITE;
		vmem[row2_pixel + 18'd3] <= font_bmp[bmp_index2][4] ? BLACK : WHITE;
		vmem[row2_pixel + 18'd4] <= font_bmp[bmp_index2][3] ? BLACK : WHITE;
		vmem[row2_pixel + 18'd5] <= font_bmp[bmp_index2][2] ? BLACK : WHITE;
		vmem[row2_pixel + 18'd6] <= font_bmp[bmp_index2][1] ? BLACK : WHITE;
		vmem[row2_pixel + 18'd7] <= font_bmp[bmp_index2][0] ? BLACK : WHITE;

		// Char row 3
		vmem[row3_pixel] 		 <= font_bmp[bmp_index3][7] ? BLACK : WHITE;
		vmem[row3_pixel + 18'd1] <= font_bmp[bmp_index3][6] ? BLACK : WHITE;
		vmem[row3_pixel + 18'd2] <= font_bmp[bmp_index3][5] ? BLACK : WHITE;
		vmem[row3_pixel + 18'd3] <= font_bmp[bmp_index3][4] ? BLACK : WHITE;
		vmem[row3_pixel + 18'd4] <= font_bmp[bmp_index3][3] ? BLACK : WHITE;
		vmem[row3_pixel + 18'd5] <= font_bmp[bmp_index3][2] ? BLACK : WHITE;
		vmem[row3_pixel + 18'd6] <= font_bmp[bmp_index3][1] ? BLACK : WHITE;
		vmem[row3_pixel + 18'd7] <= font_bmp[bmp_index3][0] ? BLACK : WHITE;

		// Char row 4
		vmem[row4_pixel] 		 <= font_bmp[bmp_index4][7] ? BLACK : WHITE;
		vmem[row4_pixel + 18'd1] <= font_bmp[bmp_index4][6] ? BLACK : WHITE;
		vmem[row4_pixel + 18'd2] <= font_bmp[bmp_index4][5] ? BLACK : WHITE;
		vmem[row4_pixel + 18'd3] <= font_bmp[bmp_index4][4] ? BLACK : WHITE;
		vmem[row4_pixel + 18'd4] <= font_bmp[bmp_index4][3] ? BLACK : WHITE;
		vmem[row4_pixel + 18'd5] <= font_bmp[bmp_index4][2] ? BLACK : WHITE;
		vmem[row4_pixel + 18'd6] <= font_bmp[bmp_index4][1] ? BLACK : WHITE;
		vmem[row4_pixel + 18'd7] <= font_bmp[bmp_index4][0] ? BLACK : WHITE;

		// Char row 5
		vmem[row5_pixel] 		 <= font_bmp[bmp_index5][7] ? BLACK : WHITE;
		vmem[row5_pixel + 18'd1] <= font_bmp[bmp_index5][6] ? BLACK : WHITE;
		vmem[row5_pixel + 18'd2] <= font_bmp[bmp_index5][5] ? BLACK : WHITE;
		vmem[row5_pixel + 18'd3] <= font_bmp[bmp_index5][4] ? BLACK : WHITE;
		vmem[row5_pixel + 18'd4] <= font_bmp[bmp_index5][3] ? BLACK : WHITE;
		vmem[row5_pixel + 18'd5] <= font_bmp[bmp_index5][2] ? BLACK : WHITE;
		vmem[row5_pixel + 18'd6] <= font_bmp[bmp_index5][1] ? BLACK : WHITE;
		vmem[row5_pixel + 18'd7] <= font_bmp[bmp_index5][0] ? BLACK : WHITE;

		// Char row 6
		vmem[row6_pixel] 		 <= font_bmp[bmp_index6][7] ? BLACK : WHITE;
		vmem[row6_pixel + 18'd1] <= font_bmp[bmp_index6][6] ? BLACK : WHITE;
		vmem[row6_pixel + 18'd2] <= font_bmp[bmp_index6][5] ? BLACK : WHITE;
		vmem[row6_pixel + 18'd3] <= font_bmp[bmp_index6][4] ? BLACK : WHITE;
		vmem[row6_pixel + 18'd4] <= font_bmp[bmp_index6][3] ? BLACK : WHITE;
		vmem[row6_pixel + 18'd5] <= font_bmp[bmp_index6][2] ? BLACK : WHITE;
		vmem[row6_pixel + 18'd6] <= font_bmp[bmp_index6][1] ? BLACK : WHITE;
		vmem[row6_pixel + 18'd7] <= font_bmp[bmp_index6][0] ? BLACK : WHITE;

		// Char row 7
		vmem[row7_pixel] 	     <= font_bmp[bmp_index7][7] ? BLACK : WHITE;
		vmem[row7_pixel + 18'd1] <= font_bmp[bmp_index7][6] ? BLACK : WHITE;
		vmem[row7_pixel + 18'd2] <= font_bmp[bmp_index7][5] ? BLACK : WHITE;
		vmem[row7_pixel + 18'd3] <= font_bmp[bmp_index7][4] ? BLACK : WHITE;
		vmem[row7_pixel + 18'd4] <= font_bmp[bmp_index7][3] ? BLACK : WHITE;
		vmem[row7_pixel + 18'd5] <= font_bmp[bmp_index7][2] ? BLACK : WHITE;
		vmem[row7_pixel + 18'd6] <= font_bmp[bmp_index7][1] ? BLACK : WHITE;
		vmem[row7_pixel + 18'd7] <= font_bmp[bmp_index7][0] ? BLACK : WHITE;

		cursor_init <= 1'b1;
		if(cursor_init)
			cursor_index <= cursor_index + 1'b1;
	end
end

reg[9:0]  h_cnt;        // horizontal pixel counter
reg[9:0]  v_cnt;        // vertical pixel counter

// both counters count from the begin of the visibla area

// horizontal pixel counter
always@(posedge pclk) begin
	if(h_cnt==H+HFP+HS+HBP-1)   h_cnt <= 10'b0;
	else                        h_cnt <= h_cnt + 10'b1;

	// generate negative hsync signal
	if(h_cnt == H+HFP)    hs <= 1'b0;
	if(h_cnt == H+HFP+HS) hs <= 1'b1;

end

// veritical pixel counter
always@(posedge pclk) begin
	// the vertical counter is processed at the begin of each hsync
	if(h_cnt == H+HFP) begin
		if(v_cnt==VS+VBP+V+VFP-1)  v_cnt <= 10'b0; 
		else							   v_cnt <= v_cnt + 10'b1;

	   // generate positive vsync signal
		if(v_cnt == V+VFP)    vs <= 1'b1;
		if(v_cnt == V+VFP+VS) vs <= 1'b0;
	end
end

// read VRAM
reg [31:0] video_counter;
reg [7:0] pixel;
reg de;

always@(posedge pclk) begin
	// The video counter is being reset at the begin of each vsync.
	// Otherwise it's increased every fourth pixel in the visible area.
	// At the end of the first three of four lines the counter is
	// decreased by the total line length to display the same contents
	// for four lines so 100 different lines are displayed on the 400
	// VGA lines.

	// visible area?
	if(v_cnt < V)
		VGA_VB<=0;
	else
		VGA_VB<=1;
	if(h_cnt < H)
		VGA_HB<=0;
	else
		VGA_HB<=1;
	if((v_cnt < V) && (h_cnt < H)) begin
		video_counter <= video_counter + 32'd1;
		
		pixel <= vmem[video_counter];
		de<=1;
	end 
	else begin
		if(h_cnt == H+HFP) begin
			if(v_cnt == V+VFP)
				video_counter <= 32'd0;
			de<=0;
		end
			
		pixel <= 8'h00;   // black
	end
end

assign r = { pixel[7:5],  pixel[7:5] , pixel[7:6]};
assign g = { pixel[4:2],  pixel[4:2] , pixel[4:3]};
assign b = { pixel[1:0], pixel[1:0] , pixel[1:0],pixel[1:0] };

assign VGA_DE = de;

endmodule
