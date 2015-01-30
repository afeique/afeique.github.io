module paddle
	(input  logic clk, reset, en, move_up, move_down,
	 input  logic [8:0] row, paddle_height, move_speed,
	 input  logic [9:0] col, x_left, x_right,
	 output logic [8:0] y_top, y_bot,
	 output logic draw);
	
	logic in_col, in_row;
	logic [8:0] y_delta, y_next;
	
	range_check #(10) r0(col, x_left, x_right, in_col); 
	range_check #(9)  r1(row, y_top,  y_bot,   in_row);

	always_comb begin
		y_bot = y_top + paddle_height; 

//		y_delta = (move_up & (y_top > move_speed) ? -move_speed : 9'd0) + (move_down & ((y_bot + move_speed) < 9'd479) ? move_speed : 9'd0);
		y_delta = 9'd0;
		if (move_up & ~move_down & y_top > move_speed)
			y_delta = -move_speed;
		else if (~move_up & move_down & y_bot + move_speed < 9'd479)
			y_delta = move_speed;
		y_next = en ? y_top + y_delta : y_top;
		
		draw = in_col & in_row;
	end
	
	always_ff @(posedge clk) begin
		y_top <= reset ? 9'd215 : y_next;
	end
endmodule: paddle

module counter2
  #(parameter WIDTH = 8)
  (input  logic [WIDTH-1:0] D,
   input  logic             clk, clr, en, up, load, by_2,
   output logic [WIDTH-1:0] Q);

  assign incr = by_2 ? 'd2 : 'd1;

  always_ff @(posedge clk)
    if (clr) Q <= 'b0;
    else if (load) Q <= D;
    else if (en)
      if (up) Q <= Q + incr;
      else Q <= Q - incr;
    else Q <= Q;

endmodule: counter2


module ball
	(input  logic clk, reset, en, serving,
	 input  logic [8:0] row, height, y_move_speed,
	                    left_paddle_y_top, left_paddle_y_bot, 
	                    right_paddle_y_top, right_paddle_y_bot,
	 input  logic [9:0] col, width, x_move_speed,
	                    left_paddle_x_left, left_paddle_x_right,
	                    right_paddle_x_left, right_paddle_x_right,
	 output logic scored, current_point, draw);

	// last_point = 0: last point went to left player
	// last_point = 1: last point went to right player
	// intuition: 0 is more "left", 1 is more "right"
	// current point follows same logic

	logic in_col, in_row, 
	      nin_x_bound_left, nin_x_bound_right,
	      nin_y_bound_top,  nin_y_bound_bot,
	      left_paddle_x_collision,  left_paddle_y_collision,
	      right_paddle_x_collision, right_paddle_y_collision
//	      ,in_left_paddle_col, in_right_paddle_col
	      ;
	logic [9:0] x_start, x_left, x_right, x_next, x;
	logic [8:0] y_start, y_top,  y_bot,   y_next, y, height_2;

	range_check #(10) r0(col, x_left, x_right, in_col);
	range_check #(9)  r1(row, y_top,  y_bot,   in_row);

	always_comb begin
		x_right = x_left + width - 10'd1;
		y_bot   = y_top  + height - 9'd1;
		draw = in_col & in_row;
		height_2 = height>>1;
		nin_x_bound_left = x_next + width > 10'd639;
		nin_x_bound_right = x_next >= 10'd639;
		nin_y_bound_top = y_next - height > 9'd479;
		nin_y_bound_bot = y_next + height >= 9'd479;
		x_start = 10'd319 - (width>>1);
		y_start = 10'd239 - height_2;
	end

	enum logic [2:0] {SERVING, LEFT_SCORES, RIGHT_SCORES, MOVE_UR, MOVE_DR, MOVE_UL, MOVE_DL} cs, ns;
	always_ff @(posedge clk) begin
		cs <= reset ? SERVING : ns;
		x_left <= reset ? x_start : (en ? x_next : x_left);
		y_top  <= reset ? y_start : (en ? y_next : y_top);
	end

	range_check #(10) r2(x_right, right_paddle_x_left - 10'd1, right_paddle_x_right, right_paddle_x_collision);
	range_check #(9)  r3(y_top + height_2, right_paddle_y_top, right_paddle_y_bot, right_paddle_y_collision);
	range_check #(10) r4(x_left, left_paddle_x_left, left_paddle_x_right + 10'd1, left_paddle_x_collision);
	range_check #(9)  r5(y_top + height_2, left_paddle_y_top, left_paddle_y_bot, left_paddle_y_collision);

	assign left_paddle_collision = left_paddle_y_collision & left_paddle_x_collision;
	assign right_paddle_collision = right_paddle_y_collision & right_paddle_x_collision;

//	range_check #(10) r7(x_left,  left_paddle_x_left,  left_paddle_x_right,  in_left_paddle_col);
//	range_check #(10) r6(x_right, right_paddle_x_left, right_paddle_x_right, in_right_paddle_col);

	always_comb begin
		scored = 1'b0;
		x_next = 'b0;
		y_next = 'b0;
		current_point = 1'b0;
		ns = SERVING;
			

		case (cs)
			default: begin
				ns = serving ? SERVING : MOVE_DR;
				x_next = x_start;
				y_next = y_start;
			end
			LEFT_SCORES: begin
				ns = serving ? LEFT_SCORES :  MOVE_DL;
				x_next = x_start;
				y_next = y_start;
				scored = 1'b1;
				current_point = 1'b0;
			end
			RIGHT_SCORES: begin
				ns = serving ? RIGHT_SCORES :  MOVE_DR;
				x_next = x_start;
				y_next = y_start;
				scored = 1'b1;
				current_point = 1'b1;
			end
			MOVE_UR: begin
				x_next = x_left + x_move_speed;
				y_next = y_top  - y_move_speed;

				// bounce logic
				// right player misses, left player scores
				ns = nin_x_bound_right ? LEFT_SCORES : (nin_y_bound_top ? MOVE_DR : 
					// connects on right paddle's left edge
					right_paddle_x_collision & right_paddle_y_collision ? MOVE_UL : MOVE_UR
				);
			end
			MOVE_DR: begin
				x_next = x_left + x_move_speed;
				y_next = y_top  + y_move_speed;
				
				// bounce logic
				// right player misses, left player scores
				ns = nin_x_bound_right ? LEFT_SCORES : (nin_y_bound_bot ? MOVE_UR : 
					// connects on right paddle's left edge
					right_paddle_x_collision & right_paddle_y_collision ? MOVE_DL : MOVE_DR
				);
			end
			MOVE_UL: begin
				x_next = x_left - x_move_speed;
				y_next = y_top  - y_move_speed;
				
				// bounce logic
				// left player misses, right player scores
				ns = nin_x_bound_left ? RIGHT_SCORES : (nin_y_bound_top ? MOVE_DL : 
					// connects on left paddle's right edge
					left_paddle_x_collision & left_paddle_y_collision ? MOVE_UR : MOVE_UL
				);
			end
			MOVE_DL: begin
				x_next = x_left - x_move_speed;
				y_next = y_top  + y_move_speed;
				
				// bounce logic
				ns = nin_x_bound_left ? RIGHT_SCORES : (nin_y_bound_bot ? MOVE_UL : 
					// connects on left paddle's right edge
					left_paddle_x_collision & left_paddle_y_collision ? MOVE_DR : MOVE_DL
				);
			end
		endcase
	end
endmodule: ball

module bcd2
        (input  logic reset, incr,
         output logic [7:0] bcd);

        logic [3:0] bcd_l, bcd_h;

	assign bcd = {bcd_h, bcd_l};

        always_ff @(posedge reset, posedge incr) begin
                if (reset) begin
                        bcd_h = 8'b0;
                        bcd_l = 8'b0;
                end else if (incr) begin
			bcd_l = bcd_l + 4'b1;
			
			if (bcd_l > 4'd9) begin
                        	bcd_l = bcd_l - 4'd10;
                        	bcd_h = bcd_h + 4'b1;
                	end
                	if (bcd_h > 4'd9) begin
                        	bcd_h = bcd_h - 4'd10;
                	end
		end
	end
endmodule: bcd2

/*
module bin2bcd
	(input  logic [6:0] bin,
	 output logic [7:0] bcd);

	always_comb begin
		bcd[7:4] = bin/10;
		bcd[3:0] = bin - 10*bcd[7:4];
	end
endmodule: bin2bcd 
*/

/*
module pulse_counter_test
	();

	logic clk, clr, en;
	logic [5:0] count;

	initial begin	
		clk = 0;
		forever #5 clk = ~clk;
	end

	logic reset;
	assign clr = count == 6'd59 | reset; 
	counter #(6) c0(clk, clr, en, count);

	initial begin
		$monitor($time,,"clr:%b, en:%b, count:%d, count==6'd59:%b", clr, en, count, (count == 6'd59));
		en = 1;
		@(posedge clk);
		@(posedge clk);
		for (logic [32:0] i=0; i<64; i++) begin
			if (clr) $display("\n!!!\n");
			@(posedge clk);
		end
		$finish;
	end
endmodule: pulse_counter_test
*/

/*
module left_paddle_test;
	
	logic clk, reset, moveUp, moveDown;
	logic [8:0] row, y, y_delta, y_next, y_top, y_bot;
	logic [9:0] col;
	logic [23:0] rgb;

	left_paddle l(.*);

	initial begin
		clk = 0;
		forever #5 clk = ~clk;
	end

	initial begin
		$monitor($time,,"reset:%b, moveUp:%b, moveDown:%b, row:%d, col:%d, rgb:$%h, y:%d, y_next:%d, y_top:%d, y_bot:%d, y_delta:%d", reset, moveUp, moveDown, row, col, rgb, y, y_next, y_top, y_bot, y_delta);
		reset = 1;
		moveUp = 0;
		moveDown = 0;
		col = 10'd60;
		row = 9'd239;
		@(posedge clk); // reset
		@(posedge clk);
		reset = 0;
		moveUp = 1;
		@(posedge clk);
		@(posedge clk);
		while (y_top > 9'd5)
			@(posedge clk);
		moveUp = 0;
		moveDown = 1;
		while (y_bot < 9'd475)
			@(posedge clk);
		for (col=10'd60; col<10'd63; col++) begin
			for (row=y_top; row<y_bot; row++) begin
				@(posedge clk);
			end
		end
		$finish; 
	end
endmodule: left_paddle_test
*/


module range_check
	#(parameter W=8)
	 (input  logic [W-1:0] val, low, high,
	  output logic is_between);

	always_comb begin
		is_between = ((val >= low) & (val <= high)) ? 1 : 0;
	end
endmodule: range_check 

module offset_check
	#(parameter W=8)
	 (input  logic [W-1:0] val, low, delta,
	  output logic is_between);

	logic [W-1:0] high;

	assign high = low + delta;
	range_check #(W) c0(val, low, high, is_between);
endmodule: offset_check

module counter
	#(parameter W=32)
	 (input  logic clk, clr, en,
	  output logic [W-1:0] count);
	
	always_ff @(posedge clk) begin
		count <= clr ? 'b0 : (en ? count+'b1 : count);
	end
endmodule: counter

module BCDtoSevenSegment
	(input 	logic [3:0] bcd,
	 output logic [6:0] segment,
	 input 	logic       blank);
	
	always_comb
	begin
		case (bcd)
			4'd0: segment = 7'b100_0000;
			4'd1: segment = 7'b111_1001;
			4'd2: segment = 7'b010_0100;
			4'd3: segment = 7'b011_0000;
			4'd4: segment = 7'b001_1001;
			4'd5: segment = 7'b001_0010;
			4'd6: segment = 7'b000_0010;
			4'd7: segment = 7'b111_1000;
			4'd8: segment = 7'b000_0000;
			4'd9: segment = 7'b001_1000;
			// by default, display a dash
			default: segment = 7'b011_1111;
		endcase

		segment = (blank == 1 ? 7'h7f : segment);	
	end
endmodule: BCDtoSevenSegment


/*
module range_check_test;
	logic [7:0] val, low, high;
	logic       is_between;

	range_check r(.*);

	initial begin
		$monitor($time," val=%d, low=%d, high=%d, is_between=%b", val, low, high, is_between);
		$display("Range Check Tests");
		val = 8'd200; low = 8'd100; high = 8'd200;
		#10 val = 8'd201;
		#10 val = 8'd100;
		#10 val = 8'd99;
		#10 low = 8'd200;
		#10 val = 8'd200;
		#10 low = 8'd210;
		#10 val = 8'd210;
		#10 val = 8'd220;
		#10 val = 8'd190;
		#10 val = 8'd205;
	end

endmodule: range_check_test

module offset_check_test;

	logic [7:0] val, low, delta;
	logic       is_between;

	offset_check o(.*);

	initial begin
		#1000
		$monitor($time," val=%d, low=%d, delta=%d, is_between=%b", val, low, delta, is_between);
		$display("Offset Check Tests");
		val = 8'd200; low = 8'd100; delta = 8'd100;
		#10 val = 8'd201;
		#10 val = 8'd100;
		#10 val = 8'd99;
		#10 low = 8'd200;
		#10 val = 8'd200;
		#10 low = 8'd210;
		#10 val = 8'd210;
		#10 val = 8'd220;
		#10 val = 8'd190;
		#10 val = 8'd205;
		#10 $finish;
	end

endmodule: offset_check_test
*/

/*
module register
	#(parameter W=8)
	 (input  logic clk, en, clr,
		output logic [W-1:0] d,
	  output logic [W-1:0] q);

	always_ff @(posedge clk) begin
		q <= clr ? 0 : d;
	end
endmodule: register

module comparator
	#(parameter W=8)
	 (input  logic [W-1:0] A, B,
	  output logic AltB, AeqB, AgtB);

	always_comb begin
		AltB = (A < B)  ? 1 : 0;
		AeqB = (A == B) ? 1 : 0;
		AgtB = (A > B)  ? 1 : 0;
	end
endmodule: comparator

module adder
	#(parameter W=8)
	 (input  logic [W-1:0] A, B,
	  input  logic Cin,
	  output logic [W-1:0] Sum,
	  output logic Cout);
	
	logic [W:0] fullSum;

	always_comb begin
		fullSum = A + B + Cin;
		Sum = fullSum[W-1:0];
		Cout = fullSum[W];
	end
endmodule: adder

module mux
	#(parameter W=8)
	 (input  logic [$clog2(W)-1:0] Sel,
	  input  logic [W-1:0] I,
	  output logic Y);

	assign Y = I[Sel];
endmodule: mux

module mux2to1
	#(parameter W=8)
	 (input  logic Sel,
	  input  logic [W-1:0] I0,
	  input  logic [W-1:0] I1,
	  output logic [W-1:0] Y);

	assign Y = Sel ? I0 : I1;
endmodule: mux2to1

module decoder
	#(parameter W=3)
	 (input  logic en,
	  input  logic [W-1:0] I,
	  output logic [2^W-1:0] D);

	always_comb begin
		D = 0;
		D[I] = en;
	end
endmodule: decoder
*/

/*module counter_test;

  logic c, clk, clr, en;

  counter #(1) count(clk, clr, en, c);

  initial begin
    clk = 0;
    clr = 1;
    #10 clk = 1;
    #5 clr = 0;
    #5 clk = 0;
    forever #10 clk = ~clk;
  end

  initial begin
    $monitor($time,
             " c=%b, clr=%b, en=%b", c, clr, en);
    en = 1;
    #100 $finish;
  end

endmodule: counter_test*/

/*
module pulse_counter
	#(parameter M)
	 (input  logic clk, reset,
	  output logic pulse);

	logic regD, regQ, eqM, clr;

	pulse_counter_fsm ctrl(clk, reset, eqM, clr, pulse);
	adder #($clog2(M-1)) a0(1'b1, regQ, 1'b0, regD, );
	comparator #($clog(M-1)) c0(M-1, regQ, , eqM, ); 
	register #($clog2(M-1)) r0(regD, regQ, clr, clk);
endmodule: pulse_counter

module pulse_counter_fsm
	 (input  logic clk, reset, eq,
	  output logic clr, pulse);

	enum logic [1:0] {COUNT, PULSE} currState, nextState;

	always_ff @(posedge clk) begin
		currState <= reset ? 0 : nextState;
	end

	always_comb begin
		pulse = 1'b0;
		clr = reset;
		unique case(currState)
			default: begin 
				pulse = 1'b0;
				clr = 1'b0;
				nextState = eq ? PULSE : COUNT;
			end
			PULSE: begin
				pulse = 1'b1;
				clr = 1'b1;
				nextState = COUNT;
			end
		endcase
	end
endmodule: pulse_counter_fsm
*/


/*

module comparator_test
	#(parameter W=8)
	 (output logic [W-1:0] A, B,
	  input  logic AltB, AeqB, AgtB);

		logic error;

		initial begin
	
			error = 0;
		
			$display("\n------------------");
			$display("Testing Comparator");
			$display("------------------\n");
			$display("/// parameterized [W]idth: %d", W);
			for (A=0; A<(2^W)-1; A++) begin
				for (B=0; B<(2^W)-1; B++) begin 
					if ( (A<B) != AltB ) begin
						$display("*** error: (%d < %d)=%b, correct: (%d < %d)=%b", A, B, AltB, A, B, A<B);
						error = 1;
					end
					if ( (A==B) != AeqB ) begin
						$display("*** error: (%d == %d)=%b, correct: (%d == %d)=%b", A, B, AeqB, A, B, A==B);
						error = 1;
					end
					if ( (A>B) != AgtB ) begin
						$display("*** error: (%d > %d)=%b, correct: (%d > %d)=%b", A, B, AgtB, A, B, A>B);
						error = 1;
					end 	
				end
			end
			if (~error)
				$display("=== no errors");
		end
endmodule: comparator_test


module adder_test
	#(parameter W=8)
	 (output logic [W-1:0] A, B,
	  output logic Cin,
	  input  logic [W-1:0] Sum,
	  input  logic Cout);

	logic [W:0] fullSum;
	logic error;

	initial begin
	
		error = 0;
		
		$display("\n-------------");
		$display("Testing Adder");
		$display("-------------\n");
		$display("/// parameterized [W]idth: %d", W);
		for (Cin=0; Cin<1; Cin++) begin
			for (A=0; A<(2^W)-1; A++) begin
				for (B=0; B<(2^W)-1; B++) begin 
					fullSum = A + B + Cin;
					if (fullSum[W-1:0] != Sum | fullSum[W] != Cout) begin
						$display("*** error: %d+%d+%b=%d Cout=%b, correct: %d+%d+%b=%d Cout=%b", A, B, Cin, Sum, Cout, A, B, Cin, fullSum[W-1:0], fullSum[W]);
						error = 1;
					end
				end
			end
		end
		if (~error)
			$display("=== no errors");
	end
endmodule: adder_test


module mux_test
	#(parameter W=8)
	 (output logic [$clog2(W)-1:0] Sel,
	  output logic [W-1:0] I,
	  input  logic Y);

	logic error;

	initial begin
		error = 0;

		$display("\n-----------");
		$display("Testing Mux");
		$display("-----------\n");
		$display("/// parameterized [W]idth: %d", W);
		for (Sel=0; Sel<(2^$clog2(W))-1; Sel++) begin
			for (I[Sel]=0; I[Sel]<1; I[Sel]++) begin
				if (Y != I[Sel]) begin
					$display("*** error: Sel=%d I[%d]=%b Y=%b, correct: Y=%b", Sel, Sel, I[Sel], Y, I[Sel]);
					error = 1; 
				end
			end
		end	
		if (~error)
			$display("=== no errors");
	end


endmodule: mux_test


module mux2to1_test
	#(parameter W=8)
	 (output logic Sel,
	  output logic [W-1:0] I0,
	  output logic [W-1:0] I1,
	  input  logic [W-1:0] Y);

	logic error;

	initial begin
		error = 0;
		
		$display("\n--------------");
		$display("Testing Mux2to1");
		$display("---------------\n");
		$display("/// parameterized [W]idth: %d", W);
		I0 = 0; I1 = -1;
		Sel = 0;
		if (Y != I0) begin
			$display("*** error: Sel=%b I0=%b != Y=%b", Sel, I0, Y);
			error = 1;
		end	
		Sel = 1;
		if (Y != I1) begin
			$display("*** error: Sel=%b I1=%b != Y=%b", Sel, I1, Y);
			error = 1;
		end
		if (~error)
			$display("=== no errors");
	end

endmodule: mux2to1_test


module decoder_test
	#(parameter W=3)
	 (output logic en,
	  output logic [W-1:0] I,
	  input  logic [2^W-1:0] D);

	logic error;
	logic [2^W-1:0] D_check;

	initial begin
		error = 0;
		
		$display("\n--------------");
		$display("Testing Decoder");
		$display("---------------\n");
		$display("/// parameterized [W]idth: %d", W);		
		for (en=0; en<1; en++) begin
			for (I=0; I<(2^W)-1; I++) begin
				D_check = 0;
				D_check[I] = 1 & en;
				if (D != D_check) begin
					$display("*** error: I=%d D=%b, correct: D=%b", I, D, D_check);
					error = 1;
				end
			end
		end
		if (~error)
			$display("=== no errors");
	end

endmodule: decoder_test


module register_test
	#(parameter W=8)
	 (output logic clk, en, clr,
	  output logic [W-1:0] D,
	  input  logic [W-1:0] Q);


	initial begin
		en = 0;
		clr = 0;
		clk = 0;
		forever #10 clk = ~clk;
	end
	

	initial begin
		# 700;
		$display("\n--------------");
		$display("Testing Register");
		$display("---------------\n");
		$display("/// parameterized [W]idth: %d", W);
		
		$monitor($time,"### en=%b clr=%b D=%d Q=%d", en, clr, D, Q);
		D = 1;	
	
		en = 0; clr = 1;
		@(posedge clk); // clr
		en = 1; 
		@(posedge clk); // clr
		clr = 0;
		@(posedge clk); // Q <- D
		en = 0; D = -1;
		@(posedge clk); // hold Q
		en = 1;
		@(posedge clk); // Q <- D
		@(posedge clk); // hold Q

		$finish;
	end

endmodule: register_test

module counter_test
	();
	logic clk, clr, en;
	logic [31:0] count;

	counter c0(clk, clr, en, count);

	logic [31:0] tCount;

	initial begin
		clk = 0;
		forever #10 clk = ~clk;
	end

	logic error;

	initial begin
		error = 0;

		clr = 1;
		@(posedge clk);
		clr = 0;

		for (en=0; en<1'b1; en++) begin
		for (tCount=32'b0; tCount<32'd100; tCount++) begin
			@(posedge clk);
			if (~en & (count != 0'b0) )
				error = 1'b1;
			if (en & (count != tCount) )
				error = 1'b1;
		end
		end

		if (error)
			$display("problem counting");

		$finish;
	end

endmodule: counter_test



module tb
	#(parameter CMP_W=16, ADD_W=16, MUX_W=16, MUX2_W=16, DEC_W=4, REG_W=16)
	 ();

	logic [CMP_W-1:0] A_cmp, B_cmp;
	logic AltB, AeqB, AgtB;

	logic [ADD_W-1:0] A_add, B_add, Sum;
	logic Cin, Cout;

	logic [MUX_W-1:0] I_mux;
	logic [$clog2(MUX_W)-1:0] Sel_mux;
	logic Y_mux;

	logic [MUX2_W-1:0] I0_mux2, I1_mux2;
	logic Sel_mux2;
	logic [MUX2_W-1:0] Y_mux2;

	logic [DEC_W-1:0] I_dec;
	logic en_dec;
	logic [(2^DEC_W)-1:0] D_dec;

	logic [REG_W-1:0] D_reg, Q_reg;
	logic en, clr, clk;

	comparator #(CMP_W) c(A_cmp, B_cmp, AltB, AgtB, AeqB);
	comparator_test #(CMP_W) ct(A_cmp, B_cmp, AltB, AgtB, AeqB);

	adder #(ADD_W) a(A_add, B_add, Cin, Sum, Cout);
	adder_test #(ADD_W) at(A_add, B_add, Cin, Sum, Cout);

	mux #(MUX_W) m(I_mux, Sel_mux, Y_mux);
	mux_test #(MUX_W) mt(I_mux, Sel_mux, Y_mux);

	mux2to1 #(MUX2_W) m2(I0_mux2, I1_mux2, Sel_mux2, Y_mux2);
	mux2to1_test #(MUX2_W) m2t(I0_mux2, I1_mux2, Sel_mux2, Y_mux2);

	decoder #(DEC_W) d(I_dec, D_dec, en_dec);
	decoder_test #(DEC_W) dt(I_dec, D_dec, en_dec);

	register #(REG_W) r(D_reg, Q_reg, en, clr, clk);
	register_test #(REG_W) rt(D_reg, Q_reg, en, clr, clk);
endmodule: tb


module testbench
	#(parameter COMP_ADDER_W=16, MUX_W=16, MUX2_W=16, DEC_W=4, REG_W=16)
	 ();
	
	logic [COMP_ADDER_W-1:0] A, B, Sum;
	logic AltB, AeqB, AgtB, Cin, Cout;

	logic [COMP_ADDER_W:0] fullSum;

	logic [MUX_W-1:0] I;
	logic [$clog2(MUX_W)-1:0] Sel_mux;
	logic Y_mux;

	logic [MUX2_W-1:0] I0, I1, Y_mux2;
	logic Sel_mux2;

	logic [DEC_W-1:0] I_dec;
	logic [2^DEC_W-1:0] D_dec, D_dec_check;
	logic en_dec;

	logic [REG_W-1:0] D_reg, Q_reg;
	logic en, clr, clk;

	logic error;

	comparator #(COMP_ADDER_W) c(A, B, AltB, AeqB, AgtB); 
	adder #(COMP_ADDER_W) a(A, B, Cin, Sum, Cout);

	mux #(MUX_W) m(I, Sel_mux, Y_mux);
	mux2to1 #(MUX2_W) m2(I0, I1, Sel_mux2, Y_mux2);
	
	decoder #(DEC_W) d(I_dec, en_dec, D_dec);

	register #(REG_W) r(D_reg, en, clr, clk, Q_reg);

	initial begin
		en = 0;
		clr = 0;
		clk = 0;
		forever #10 clk = ~clk;
	end
	
	initial begin
	
		error = 0;
		
		$display("\n----------------------------");
		$display("Testing Comparator and Adder");
		$display("----------------------------\n");
		$display("/// parameterized [W]idth: %d", COMP_ADDER_W);
		for (Cin=0; Cin<1; Cin++) begin
			for (A=0; A<(2^COMP_ADDER_W)-1; A++) begin
				for (B=0; B<(2^COMP_ADDER_W)-1; B++) begin
					if ( (A<B) != AltB ) begin
						$display("*** error: (%d < %d)=%b, correct: (%d < %d)=%b", A, B, AltB, A, B, A<B);
						error = 1;
					end
					if ( (A==B) != AeqB ) begin
						$display("*** error: (%d == %d)=%b, correct: (%d == %d)=%b", A, B, AeqB, A, B, A==B);
						error = 1;
					end
					if ( (A>B) != AgtB ) begin
						$display("*** error: (%d > %d)=%b, correct: (%d > %d)=%b", A, B, AgtB, A, B, A>B);
						error = 1;
					end  
					fullSum = A + B + Cin;
					if (fullSum[COMP_ADDER_W-1:0] != Sum | fullSum[COMP_ADDER_W] != Cout) begin
						$display("*** error: %d+%d+%b=%d Cout=%b, correct: %d+%d+%b=%d Cout=%b", A, B, Cin, Sum, Cout, A, B, Cin, fullSum[COMP_ADDER_W-1:0], fullSum[COMP_ADDER_W]);
						error = 1;
					end
				end
			end
		end
		if (~error)
			$display("=== no errors");
	
		error = 0;

		$display("\n-----------");
		$display("Testing Mux");
		$display("-----------\n");
		$display("/// parameterized [W]idth: %d", MUX_W);
		for (Sel_mux=0; Sel_mux<(2^$clog2(MUX_W))-1; Sel_mux++) begin
			for (I[Sel_mux]=0; I[Sel_mux]<1; I[Sel_mux]++) begin
				if (Y_mux != I[Sel_mux]) begin
					$display("*** error: Sel=%d I[%d]=%b Y=%b, correct: Y=%b", Sel_mux, Sel_mux, I[Sel_mux], Y_mux, I[Sel_mux]);
					error = 1; 
				end
			end
		end	
		if (~error)
			$display("=== no errors");

		error = 0;
		
		$display("\n--------------");
		$display("Testing Mux2to1");
		$display("---------------\n");
		$display("/// parameterized [W]idth: %d", MUX2_W);
		I0 = 0; I1 = -1;
		Sel_mux2 = 0;
		if (Y_mux2 != I0) begin
			$display("*** error: Sel=%b I0=%b != Y=%b", Sel_mux2, I0, Y_mux2);
			error = 1;
		end	
		Sel_mux2 = 1;
		if (Y_mux2 != I1) begin
			$display("*** error: Sel=%b I1=%b != Y=%b", Sel_mux2, I1, Y_mux2);
			error = 1;
		end
		if (~error)
			$display("=== no errors");

		error = 0;
		
		$display("\n--------------");
		$display("Testing Decoder");
		$display("---------------\n");
		$display("/// parameterized [W]idth: %d", DEC_W);		
		for (en_dec=0; en_dec<1; en_dec++) begin
			for (I_dec=0; I_dec<(2^DEC_W)-1; I_dec++) begin
				D_dec_check = 0;
				D_dec_check[I_dec] = 1 & en_dec;
				if (D_dec != D_dec_check) begin
					$display("*** error: I=%d D=%b, correct: D=%b", I_dec, D_dec, D_dec_check);
					error = 1;
				end
			end
		end
		if (~error)
			$display("=== no errors");

		
		$display("\n--------------");
		$display("Testing Register");
		$display("---------------\n");
		$display("/// parameterized [W]idth: %d", REG_W);
		
		$monitor($time,,"### en=%b clr=%b D=%d Q=%d", en, clr, D_reg, Q_reg);
		D_reg = 1;	
	
		en = 0; clr = 1;
		@(posedge clk); // clr
		en = 1; 
		@(posedge clk); // clr
		clr = 0;
		@(posedge clk); // Q <- D
		en = 0; D_reg = -1;
		@(posedge clk); // hold Q
		en = 1;
		@(posedge clk); // Q <- D
		$finish;
	end
endmodule: testbench

*/
