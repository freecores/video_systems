/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Discrete Cosine Transform Unit                             ////
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
//  $Id: dctu.v,v 1.1.1.1 2002-03-26 07:25:11 rherveille Exp $
//
//  $Date: 2002-03-26 07:25:11 $
//  $Revision: 1.1.1.1 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $


`include "timescale.v"

module dctu(clk, ena, dgo, x, y, ddin, dout);

	parameter coef_width = 16;
	parameter [2:0] v = 0;
	parameter [2:0] u = 0;

	//
	// inputs & outputs
	//

	input clk;
	input ena;
	input dgo; // double delayed go-signal
	input [2:0] x, y;

	input  [ 7:0] ddin; // delayed data input signal
	output [11:0] dout;

	//
	// variables
	//
	wire [31:0] icoef;
	reg [coef_width-1:0] coef;
	wire [coef_width +10:0] result;

	`include "../../../dct/rtl/verilog/dct_cos_table.v"

	//
	// module body
	//

	// hookup cosine-table
	assign icoef = dct_cos_table(x, y, u, v);

	always@(posedge clk)
		if(ena)
			coef <= #1 icoef[31:31-coef_width +1];

	// hookup dct-mac unit
	dct_mac #(8, coef_width) macu (
		.clk(clk),
		.ena(ena),
		.clr(dgo),
		.din(ddin),
		.coef(coef),
		.result(result)
	);

	assign dout = result[coef_width +10: coef_width -1];
endmodule
