/////////////////////////////////////////////////////////////////////
////                                                             ////
////  JPEG Run-Length Encoder, intermediate results              ////
////                                                             ////
////  - Translate DC and AC coeff. into:                         ////
////  1) zero-run-length                                         ////
////  2) bit-size for amplitude                                  ////
////  3) amplitude                                               ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2001 Richard Herveille                        ////
////                    richard@asics.ws                         ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: jpeg_rle1.v,v 1.1.1.1 2002-03-26 07:25:12 rherveille Exp $
//
//  $Date: 2002-03-26 07:25:12 $
//  $Revision: 1.1.1.1 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $

`timescale 1ns/10ps

module jpeg_rle1(clk, rst, ena, go, din, rlen, size, amp, den);

	//
	// parameters
	//

	//
	// inputs & outputs
	//
	input clk;          // system clock
	input rst;          // asynchronous reset
	input ena;          // clock enable
	input         go;
	input  [11:0] din;  // data input

	output [ 3:0] rlen; // run-length
	reg [ 3:0] rlen;
	output [ 3:0] size; // size
	reg [ 3:0] size;
	output [11:0] amp;  // amplitude
	reg [11:0] amp;
	output        den;  // data output enable
	reg        den;

	//
	// variables
	//

	reg [5:0] sample_cnt;
	reg [3:0] zero_cnt;
	wire      is_zero;

	wire [3:0] sizeof_din;

	reg       state;
	parameter dc = 1'b0;
	parameter ac = 1'b1;

	//
	// module body
	//

	// function declarations
	function [10:0] abs;
		input [11:0] a;
	begin
		if (a[11])
			abs = (~a[10:0]) +11'h1;
		else
			abs = a[10:0];
	end
	endfunction

	function [3:0] sizef;
			input [11:0] a;
			reg   [10:0] tmp;

		begin
			// get absolute value
			tmp = abs(a);

			// determine size
			casex (tmp) // synopsys full_case parallel_case
				11'b1??_????_???? : sizef = 4'hb; // 1024..2047
				11'b01?_????_???? : sizef = 4'ha; //  512..1023
				11'b001_????_???? : sizef = 4'h9;  //  256.. 511
				11'b000_1???_???? : sizef = 4'h8;  //  128.. 255
				11'b000_01??_???? : sizef = 4'h7;  //   64.. 127
				11'b000_001?_???? : sizef = 4'h6;  //   32..  63
				11'b000_0001_???? : sizef = 4'h5;  //   16..  31
				11'b000_0000_1??? : sizef = 4'h4;  //    8..  15
				11'b000_0000_01?? : sizef = 4'h3;  //    4..   7
				11'b000_0000_001? : sizef = 4'h2;  //    2..   3
				default           : sizef = 4'h1;  //    1
			endcase
		end
	endfunction

	// detect zero
	assign is_zero = ~|din;

	// hookup sizef function
	assign sizeof_din = (din);

	// assign dout
	always@(posedge clk)
		if (ena)
			amp <= #1 din;

	// generate sample counter
	always@(posedge clk)
		if (ena)
			if (go)
				sample_cnt <= #1 0;
			else
				sample_cnt <= #1 sample_cnt +1;

	// generate zero counter
	always@(posedge clk)
		if (ena)
			if (is_zero)
				zero_cnt <= #1 zero_cnt +1;
			else
				zero_cnt <= #1 0;

	// statemachine, create intermediate results
	always@(posedge clk or negedge rst)
		if (!rst)
			begin
				state <= #1 dc;
				rlen  <= #1 0;
				size  <= #1 0;
				den   <= #1 1'b0;
			end
		else if (ena)
			case (state) // synopsys full_case parallel_case
				dc:
					if (go)
						begin
							state <= #1 ac;
							rlen  <= #1 0;
							size  <= #1 sizeof_din;
							den   <= #1 1'b1;
						end
					else
						begin
							state <= #1 dc;
							rlen  <= #1 0;
							size  <= #1 sizeof_din;
							den   <= #1 1'b0;
						end

				ac:
					if (&sample_cnt)  // finished current block
						begin
							state <= #1 dc;
							
							if (is_zero) // last sample zero ??
								begin
									rlen <= #1 0;
									size <= #1 0;
									den  <= #1 1'b1;
								end
							else
								begin
									rlen <= #1 zero_cnt;
									size <= #1 sizeof_din;
									den  <= #1 1'b1;
								end
						end
					else
						begin
							state <= #1 ac;

							if (is_zero)
								begin
									if (&zero_cnt)
										begin
											rlen <= #1 zero_cnt;
											size <= #1 0;
											den  <= #1 1'b1;
										end
									else
										begin
											rlen <= #1 zero_cnt;
											size <= #1 0;
											den  <= #1 1'b0;
										end
								end
							else
								begin
									rlen <= #1 zero_cnt;
									size <= #1 sizeof_din;
									den  <= #1 1'b1;
								end
						end
			endcase

endmodule