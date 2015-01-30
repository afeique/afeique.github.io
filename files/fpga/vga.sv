module vga
	(input  logic CLOCK_50, reset,
	 output logic HS, VS, blank,
	 output logic [8:0] row,
	 output logic [9:0] col);

	logic not_hs_clr, not_vs_clr, row_en, row_clr, col_clr;
	logic [19:0] vs_count;
	logic [10:0] hs_count, col_11;
	logic not_HS, not_VS, hs_disp, vs_disp;

	counter #(20) c0(CLOCK_50, ~not_vs_clr | reset, 1'b1, vs_count); // vs counter
	counter #(11) c1(CLOCK_50, ~not_hs_clr | reset, 1'b1, hs_count); // hs counter
	counter #(9)  c2(CLOCK_50, row_clr | reset, row_en, row); // row counter
	counter #(11) c3(CLOCK_50, col_clr | reset, hs_disp & vs_disp, col_11); // col counter

	assign col = col_11[10:1];	
	assign HS = ~not_HS;
	assign VS = ~not_VS;
	assign blank = ~(hs_disp & vs_disp);
	assign row_en = vs_disp & ~not_hs_clr;

	range_check #(11) r0(hs_count, 11'd0, 11'd192-11'd1, not_HS); // HS: T_PW
	range_check #(20) r1(vs_count, 20'd0, 20'd3200-20'd1, not_VS); // VS: T_PW
	range_check #(11) r2(hs_count, 11'd0, 11'd1600-11'd2, not_hs_clr); // HS: T_S
	range_check #(20) r3(vs_count, 20'd0, 20'd833600-20'd2, not_vs_clr); // VS: T_S
	offset_check #(11) r4(hs_count, 11'd192 + 11'd96, 11'd1280-11'd1, hs_disp); // HS: T_DISP
	offset_check #(20) r5(vs_count, 20'd3200 + 20'd46400, 20'd768000-20'd1, vs_disp); // VS: T_DISP
	offset_check #(11) r6(hs_count, 11'd192, 11'd96-11'd1, col_clr); // clears the column during HS_BP
	offset_check #(20) r7(vs_count, 20'd3200, 20'd46400-11'd1, row_clr); // clears the row during VS_BP
endmodule: vga


module ChipInterface
	(input  logic CLOCK_50,
	 input  logic [3:0] KEY,
	 input  logic [17:0] SW,
	 output logic [6:0] HEX4, HEX5, HEX6, HEX7,
	 output logic [7:0] VGA_R, VGA_G, VGA_B,
	 output logic VGA_BLANK_N, VGA_CLK, VGA_SYNC_N, VGA_VS, VGA_HS);

	logic reset, en, init, blank, slow, update, serving, scored, current_point,
	      draw_left_paddle, draw_right_paddle, draw_ball;

	// last point = 0: last point went to left player
	// last point = 1: last point went to right player
	// intuition: 0 is more "left", 1 is more "right"
	// current point follows same logic	

	logic [20:0] count;
	logic [8:0] row, paddle_height, paddle_move_speed, ball_height, ball_y_speed,
                    left_paddle_y_top, left_paddle_y_bot,
                    right_paddle_y_top, right_paddle_y_bot;
	logic [9:0] col, paddle_width, ball_width, ball_x_speed,
	            left_paddle_x_left, left_paddle_x_right,
                    right_paddle_x_left, right_paddle_x_right;
	logic [23:0] VGA_RGB;
	logic [5:0] pulse60_count;
	logic [6:0] left_score, right_score;
	logic [7:0] left_score_bcd, right_score_bcd;

	always_comb begin
		{VGA_R, VGA_G, VGA_B} = VGA_RGB;
		VGA_CLK = ~CLOCK_50;
		VGA_BLANK_N = ~blank;
		VGA_SYNC_N = 1'b0;
		VGA_RGB = 24'h0 | 
			(draw_left_paddle ? 24'hffff00 : 24'h0) | 
			(draw_right_paddle ? 24'h00ffff : 24'h0) | 
			(draw_ball ? 24'hffffff : 24'h0);		
		update = (row == 9'd479 & col == 10'd639) ? 1'b1 : 1'b0;
		en = slow ? (pulse60_count == 6'd59) : update;
		reset = ~KEY[0] | init;
		slow = ~KEY[1];
		serving = KEY[3];
		paddle_height = 9'd47;
		paddle_width = 10'd3;
		paddle_move_speed = 9'd5;
		left_paddle_x_left = 10'd60;
		left_paddle_x_right = left_paddle_x_left + paddle_width;
		right_paddle_x_left = 10'd577;
		right_paddle_x_right = right_paddle_x_left + paddle_width;
		ball_width = 9'd4;
		ball_height = 10'd4;
		ball_x_speed = 10'd2;
		ball_y_speed = 9'd1;
	end
	
	vga v(CLOCK_50, reset, VGA_HS, VGA_VS, blank, row, col);
	
	counter #(6) pulse60(CLOCK_50, ~slow | pulse60_count == 6'd59, slow & update, pulse60_count);

	paddle left_paddle (CLOCK_50, reset, update, SW[17], SW[16], row, paddle_height, paddle_move_speed, col, 
		left_paddle_x_left, left_paddle_x_right, 
		left_paddle_y_top,  left_paddle_y_bot,  draw_left_paddle);
	paddle right_paddle(CLOCK_50, reset, update, SW[1],  SW[0],  row, paddle_height, paddle_move_speed, col, 
		right_paddle_x_left, right_paddle_x_right,
		right_paddle_y_top, right_paddle_y_bot, draw_right_paddle);
	ball ping_pong(CLOCK_50, reset, en, serving,
		row, ball_height, ball_y_speed, 
		left_paddle_y_top,  left_paddle_y_bot,
		right_paddle_y_top, right_paddle_y_bot,
		col, ball_width, ball_x_speed,
		left_paddle_x_left,  left_paddle_x_right,
		right_paddle_x_left, right_paddle_x_right,
		scored, current_point, draw_ball);
		

	bcd2 b0(reset, scored & ~current_point, left_score_bcd);
	bcd2 b1(reset, scored & current_point,  right_score_bcd);

	BCDtoSevenSegment ssd0(left_score_bcd[7:4],  HEX7, 1'b0);
	BCDtoSevenSegment ssd1(left_score_bcd[3:0],  HEX6, 1'b0);
	BCDtoSevenSegment ssd2(right_score_bcd[7:4], HEX5, 1'b0);
	BCDtoSevenSegment ssd3(right_score_bcd[3:0], HEX4, 1'b0);

	// boot into the correct initial positions
	enum logic [2:0] {INIT_0, INIT_1, INIT_2, LOOP} cs, ns;
	always_ff @(posedge CLOCK_50) begin
		cs <= ns;
	end
	always_comb begin
		init = 1'b1;
		case (cs)
			default: ns = INIT_1;
			INIT_1: ns = INIT_2;
			INIT_2: ns = LOOP;
			LOOP: begin
				init = 1'b0;
				ns = LOOP;
			end
		endcase
	end
endmodule: ChipInterface


/*
module vga_test;

  logic CLOCK_50, reset, HS, VS, blank, clk, not_HS, not_VS;
  logic [10:0] hs_count;
  logic [19:0] vs_count;
  logic [8:0] row;
  logic [9:0] col;

  vga v(.*);

  assign CLOCK_50 = clk;

  initial begin
    clk = 0;
    forever #10 clk = ~clk;
  end

  initial begin
    reset = 1;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    reset = 0;
    #40000000 $finish;
  end

endmodule: vga_test
*/

/*
module ChipInterface
	(input  logic CLOCK_50,
	 input  logic [3:0] KEY,
	 input  logic [17:0] SW,
	 output logic [6:0] HEX4, HEX5, HEX6, HEX7,
	 output logic [7:0] VGA_R, VGA_G, VGA_B,
	 output logic VGA_BLANK_N, VGA_CLK, VGA_SYNC_N, VGA_VS, VGA_HS);

	logic blank;

	logic [8:0] row;
	logic [9:0] col;	

	assign VGA_CLK = ~CLOCK_50;
	assign VGA_BLANK_N = ~blank;
	
	// following sequential logic handles resetting vga module, needed for counters
	enum logic [1:0] {INIT, LOOP} currState, nextState;
	always_ff @(posedge clk) begin
		case (currState)
			default: begin
				init <= 1;
				nextState = LOOP;
			end
			LOOP: begin
				init <= 0;
				nextState = LOOP;
			end
		endcase
	end
	vga v(CLOCK_50, ~KEY[0] | init, VGA_HS, VGA_VS, blank, row, col);

	logic R, G, G1, G2, B, B1, B2, B3, B4;

	range_check #(10) r0(col, 10'd320, 10'd639, R);
	range_check #(10) r1(col, 10'd160, 10'd319, G1);
	range_check #(10) r2(col, 10'd480, 10'd639, G2);
	range_check #(10) r3(col, 10'd80, 10'd159, B1);
	range_check #(10) r4(col, 10'd240, 10'd319, B2);
	range_check #(10) r5(col, 10'd400, 10'd479, B3);
	range_check #(10) r6(col, 10'd560, 10'd639, B4);

	assign G = G1 | G2;
	assign B = B1 | B2 | B3 | B4;

	assign VGA_R = R ? 8'hff : 8'h00;
	assign VGA_G = G ? 8'hff : 8'h00;
	assign VGA_B = B ? 8'hff : 8'h00;

	assign VGA_SYNC_N = 1'b0;
endmodule: ChipInterface
*/
