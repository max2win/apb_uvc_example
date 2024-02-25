/*
*
* Copyright 2023 Massimo Vincenzi
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
*/
`ifndef SV_APB_IF
`define SV_APB_IF

interface apb_if (
	input logic pclk, 
	input logic preset
);

	logic [11:0] paddr;    // lower part of the address
	logic        pwrite;
	logic  [3:0] psel;     // when non-zero, it's the upper part of the address, onehot-encoded
	logic        penable;
	logic [31:0] pwdata;
	logic [31:0] prdata;
	logic        pready;
	logic        pslverr;

	clocking ms @(posedge pclk);
		output paddr;
		output pwrite;
		output psel;
		output penable;
		output pwdata;
		input  prdata;
		input  pready;
		input  pslverr;
	endclocking : ms

	clocking sl @(posedge pclk);
		input  paddr;
		input  pwrite;
		input  psel;
		input  penable;
		input  pwdata;
		output prdata;
		output pready;
		output pslverr;
	endclocking : sl

endinterface

`endif