/////////////////////////////////////////////////////////////////////
////                                                             ////
////  JPEG Run-Length Encoder, remove zero sequences             ////
////                                                             ////
////  - Detect (15,0) (0,0) seqence                              ////
////  - Replace them by (0,0)                                    ////
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
//  $Id: jpeg_rzs.v,v 1.1.1.1 2002-03-26 07:25:12 rherveille Exp $
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

module jpeg_rzs(clk, rst, deni, rleni, sizei, ampi, deno, rleno, sizeo, ampo);

	//
	// inputs & outputs
	//
	input clk;
	input rst;
	input deni;
	input [ 3:0] sizei;
	input [ 3:0] rleni;
	input [11:0] ampi;

	output        deno;
	reg        deno;
	output [ 3:0] sizeo;
	reg [ 3:0] sizeo;
	output [ 3:0] rleno;
	reg [ 3:0] rleno;
	output [11:0] ampo;
	reg [11:0] ampo;

	//
	// variables
	//

	reg [ 3:0] size;
	reg [ 3:0] rlen;
	reg [11:0] amp;
	reg        den;

	wire eob;
	wire zerobl;
	reg  state;

	//
	// module body
	//

	always@(posedge clk)
		if (deni)
			begin
				size  <= #1 sizei;
				rlen  <= #1 rleni;
				amp   <= #1 ampi;
			end

	always@(posedge clk)
		begin
			sizeo <= #1 size;
			rleno <= #1 rlen;
			ampo  <= #1 amp;
		end

	assign zerobl = &rleni &&  ~|sizei && deni;
	assign eob    = ~|{rleni, sizei} && deni;

	always@(posedge clk or negedge rst)
		if (!rst)
			begin
				state <= #1 1'b0;
				den   <= #1 1'b0;
				deno  <= #1 1'b0;
			end
		else
			case (state) // synopsys full_case parallel_case
				1'b0:
					begin
						if (zerobl)
							begin
								state <= #1 1'b1; // go to zero-detection state
								den   <= #1 1'b0; // do not yet set data output enable
								deno  <= #1 den;  // output previous data
							end
						else
							begin
								state <= #1 1'b0; // stay in 'normal' state
								den   <= #1 deni; // set data output enable
								deno  <= #1 den;  // output previous data
							end
					end

				1'b1:
					begin
						deno <= #1 1'b0;

						if (deni)
							if (zerobl)
								begin
									state <= #1 1'b1; // stay in zero-detection state
									den   <= #1 1'b0; // hold current zer-block
									deno  <= #1 1'b1; // output previous zero-block
								end
							else if (eob)
								begin
									state <= #1 1'b0; // go to 'normal' state
									den   <= #1 1'b1; // set output enable for EOB
									deno  <= #1 1'b0; // (was already zero), maybe optimize ??
								end
							else
								begin
									state <= #1 1'b0; // go to normal state
									den   <= #1 1'b1; // set data output enable
									deno  <= #1 1'b1; // oops, zero-block should have been output
								end
					end
			endcase
endmodule
