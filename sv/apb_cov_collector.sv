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
`ifndef SV_APB_COV_COLLECTOR
`define SV_APB_COV_COLLECTOR

class apb_cov_collector extends uvm_subscriber #(apb_trans_item);
	`uvm_component_utils(apb_cov_collector)

	apb_cfg           cfg;  // handle, do not instantiate
	uvm_analysis_imp#( apb_trans_item, apb_cov_collector) analysis_export;

	apb_trans_item obj;
	int i;
	protected int cumulative_w, cumulative_r;
	protected bit [31:0] databuf[1024];
	protected int        w_hits[1024];
	protected int        r_hits[1024];

	covergroup cg;

		psel_cp : coverpoint obj.addr[11:8] {
			bins psel0 = {0};
			bins psel1 = {1};
			bins psel2 = {2};
			bins psel3 = {3};
			bins decode_error = default;
		}
		addr_cp : coverpoint obj.addr[7:0] {
			bins addr[] = default;
		}
		slverr_cp : coverpoint obj.slverr;
		tout_co : coverpoint obj.trans_tout {
			bins tout[] = {[1:12]};
			bins zero   = {0};
		}
		trtype_cp : coverpoint obj.trtype;

		addr_x_trtype_cr : cross addr_cp, trtype_cp;
	endgroup

	function new(string name = "apb_cov_collector", uvm_component parent = null);
		super.new(name, parent);
		analysis_export  = new("analysis_export",  this);

		// Instantiate covergroups
		cg = new();

	endfunction

	function void write(apb_trans_item t);
		bit[9:0] addr10;
		`uvm_info("COV", $psprintf("collected item #%0d:\n%s", i, t.sprint()), UVM_DEBUG)
		i++;
		assert($cast(obj, t));
		addr10 = obj.addr[9:0];
		if (obj.trtype == APB_WRITE) w_hits[addr10]++; else r_hits[addr10]++;
		if (obj.trtype == APB_WRITE) databuf[addr10] = obj.wdata;
		cg.sample();
	endfunction

	function void check_phase(uvm_phase phase);
		super.check_phase(phase);

		if ($test$plusargs("ALT_COVER")) begin
			for (int addr=0; addr < 256;addr++) begin
				cumulative_w += w_hits[addr];
				cumulative_r += r_hits[addr];
			end
			if (cumulative_w+cumulative_r != cfg.n_iter) `uvm_error("COV", $psprintf("total cumulated  bins don't match: %0d of %0d", cumulative_w+cumulative_r, cfg.n_iter));
		end

	endfunction

	function void report_phase(uvm_phase phase);
		super.report_phase(phase);

		if (i == cfg.n_iter) begin // selfchecking
			`uvm_info("COV", $psprintf("total collected items: %0d of %0d", i, cfg.n_iter), UVM_NONE);
		end
		else begin
			`uvm_error("COV", $psprintf("total collected items don't match: %0d of %0d", i, cfg.n_iter));
		end

		// alternative, tool-independent, coverage statistics
		if ($test$plusargs("ALT_COVER")) begin
			for (int addr=0; addr < 256;addr++) begin
				$display("@%3x : 0x%8x , w_hits: %3d, r_hits: %3d", addr, databuf[addr], w_hits[addr], r_hits[addr]);
			end
			$display("Total requests: %0d, cumulative w_hits: %3d, r_hits: %3d", cumulative_w+cumulative_r, cumulative_w, cumulative_r);
		end

	endfunction

endclass : apb_cov_collector

`endif // SV_APB_COV_COLLECTOR
