/////////////////////////////////////////////////////////////////////
////                                                             ////
////  JPEG Run-Length Encoder, Entropy encoding                  ////
////                                                             ////
////  - Encode (run-length, size) pair using Hashing-table       ////
////  - Encode amplitude using JPEG table                        ////
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
//  $Id: jpeg_rle2.v,v 1.1.1.1 2002-03-26 07:25:12 rherveille Exp $
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

module jpeg_rle2(clk, rst, rlen, size, amp, den);

	//
	// parameters
	//

	//
	// inputs & outputs
	//
	input        clk;  // system clock
	input        rst;  // asynchronous reset
	input [ 3:0] rlen; // run-length
	input [ 3:0] size; // size
	input [11:0] amp;  // amplitude
	input        den;  // data output enable

	//
	// variables
	//


	//
	// module body
	//

	// functions

	function [11:0] amp_enc;
			input [ 3:0] size;
			input [11:0] amp;
		begin
			if (amp[11]) // negative number
				amp_enc = amp -1; // discard leading ones to get actual number
			else
				amp_enc = amp;
		end
	endfunction


endmodule
