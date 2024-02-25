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
`ifndef SV_APB_SCOREBOARD
`define SV_APB_SCOREBOARD

`uvm_analysis_imp_decl( _master )
`uvm_analysis_imp_decl( _slave )

class apb_scoreboard extends uvm_scoreboard;

	apb_cfg               cfg;  // handle, do not instantiate

	uvm_analysis_imp_master #( apb_trans_item, apb_scoreboard) master_export;
	uvm_analysis_imp_slave  #( apb_trans_item, apb_scoreboard) slave_export;

	//TODO: add more analysis ports if needed
	//TODO: add more user fields

	`uvm_component_utils_begin(apb_scoreboard)
	//TODO: add field macros for user fields
	`uvm_component_utils_end

	int err;                 // public variable used to report the local pass/fail state
	apb_trans_item obj;
	apb_trans_item ref_q[$]; // queue of reference transaction items
	apb_trans_item mon_q[$]; // queue of monitored transaction items
	protected int i, j;
	event ref_e, mon_e;

	protected bit [31:0] databuf[1024]; // used by the reference model

	// Function: new
	//
	function new(string name, uvm_component parent = null);
		super.new(name, parent);
		master_export = new("master_export", this);
		slave_export  = new("slave_export",  this);
	endfunction

	function void write_buf(ref apb_trans_item t);
		bit [9:0] addr10;
		addr10 = t.addr[9:0];
		if (!t.slverr) databuf[addr10] = t.wdata;
	endfunction

	function void read_buf(ref apb_trans_item t);
		bit [9:0] addr10;
		addr10 = t.addr[9:0];
		if (!t.slverr) t.rdata = databuf[addr10]; // the referenced item now contains the expected read value
	endfunction

	// Function: write_master
	//
	virtual function void write_master(input apb_trans_item pkt);
		apb_trans_item expected_item;
		`uvm_info("SB", $psprintf("master item #%0d:\n%s", i++, pkt.sprint()), UVM_NONE)
		expected_item = new pkt;
		assert(expected_item);
		ref_q.push_back(expected_item);
		`uvm_info("SB", $psprintf("ref_q.size: %0d", ref_q.size()), UVM_DEBUG)

		begin : REFERENCE_MODEL
			case (expected_item.trtype)
				APB_WRITE, APB_WRITE_WAIT : write_buf(expected_item);
				APB_READ, APB_READ_WAIT   : read_buf(expected_item);
			endcase
		end : REFERENCE_MODEL

		->ref_e;
	endfunction

	// Function: write_slave
	//
	virtual function void write_slave(input apb_trans_item pkt);
		`uvm_info("SB", $psprintf("slave item #%0d:\n%s", j++, pkt.sprint()), UVM_NONE)
		assert($cast(obj, pkt));
		mon_q.push_back(obj);
		`uvm_info("SB", $psprintf("mon_q.size: %0d", mon_q.size()), UVM_DEBUG)
		->mon_e;
	endfunction

	virtual function void compare(apb_trans_item a, b);
		`uvm_info("SB", $psprintf("comparing items..."), UVM_NONE)
		if (a.trtype == b.trtype)
			`uvm_info("SB", $psprintf("trtype: %s", b.trtype.name), UVM_NONE)
			else
			`uvm_error("SB", $psprintf("trtypes don't match, ref: %s, mon:%s", a.trtype.name, b.trtype.name));

		if (a.trtype == APB_READ) begin
			if (a.rdata == b.rdata) 
				`uvm_info("SB", $psprintf("rdata: 0x%8x", b.rdata), UVM_NONE)
				else 
				`uvm_error("SB", $psprintf("rdata don't match, ref: 0x%8x, mon: 0x%8x", a.rdata, b.rdata));
		end
		if (a.trtype == APB_WRITE) begin
			if (a.wdata == b.wdata) 
				`uvm_info("SB", $psprintf("wdata: 0x%8x", b.wdata), UVM_NONE)
				else 
				`uvm_error("SB", $psprintf("wdata don't match, ref: 0x%8x, mon: 0x%8x", a.wdata, b.wdata));
		end
		`uvm_info("SB", $psprintf("done."), UVM_NONE)
		endfunction

	//TODO: implement write functions for all analysis ports

	// Function: report_phase
	//
	virtual function void report_phase(uvm_phase phase);
		super.report_phase(phase);
		`uvm_info("SB", $psprintf("N_ITER: %0d, master items: %0d, slave items %0d", cfg.n_iter, i, j), UVM_NONE)

		// always check the status of FIFOs after the run_phase
		if (ref_q.size > 0 || mon_q.size > 0) begin
			`uvm_warning("SB", $psprintf("FIFOs are not empty!"))
			err++;
		end
		else begin
			`uvm_info("SB", $psprintf("FIFO check: OK"), UVM_DEBUG) // observe selfcheck is working
			end

		// more checks
		if (i == 0 || j == 0) err++; // selfchecking
		if (i != cfg.n_iter) err++;  // selfchecking
		if (i != j) err++;

	endfunction

	// Task: run_phase
	//
	task run_phase(uvm_phase phase);
		int i;
		forever begin
			fork // wait until the two events fire, in any order
				begin @(ref_e); `uvm_info("SB", $psprintf("ref_e, ref_q.size: %0d", ref_q.size()), UVM_NONE); end
				begin @(mon_e); `uvm_info("SB", $psprintf("mon_e, mon_q.size; %0d", mon_q.size()), UVM_NONE); end
			join
			if (ref_q.size > 0 && mon_q.size > 0) begin
				compare(ref_q.pop_front(), mon_q.pop_front()); // compare in FIFO order
			end
			else begin
				`uvm_warning( "SB", $sformatf("Compare FIFOs are misaligned at iteration %0d", i) )
				end
			i++;
		end	
	endtask

endclass

`endif // SV_APB_SCOREBOARD
