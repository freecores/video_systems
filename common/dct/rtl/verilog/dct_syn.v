/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Discrete Cosine Transform Synthesis Test                   ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
////  Synthesis results:                                         ////
////  Device: Altera EP20K400EBC652-1x, 50MHz clk area optimized ////
////  12bit coeff.: 15957lcells(96%), 17440membits(8%), 76MHz    ////                                                          ////
////  11bit coeff.: 15327lcells(92%), 15456membits(7%), 76MHz    ////
////                                                             ////
////                                                             ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2002 Richard Herveille                        ////
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
//  $Id: dct_syn.v,v 1.1.1.1 2002-03-26 07:25:11 rherveille Exp $
//
//  $Date: 2002-03-26 07:25:11 $
//  $Revision: 1.1.1.1 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//

`include "timescale.v"

module dct_syn(clk, ena, rst, dstrb, din, dout, den);

	input clk;
	input ena;
	input rst;

	input dstrb;
	input [7:0] din;
	
	output [11:0] dout;
	output den;

	//
	// DCT unit
	//

	fdct #(9) dut (
		.clk(clk),
		.ena(1'b1),
		.rst(rst),
		.dstrb(dstrb),
		.din(din),
		.dout(dout),
		.douten(den)
	);

endmodule
