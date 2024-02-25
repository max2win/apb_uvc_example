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
`ifndef SV_APB_ENV
`define SV_APB_ENV

class apb_env extends uvm_env;
	`uvm_component_utils(apb_env)
	
    apb_cfg               cfg;
	apb_agent             apb_master;
	apb_agent             apb_slave;
	
	// Declare handles for three new components: a coverage collector
	// a scoreboard and a virtual sequencer. Instance names will be:
	// cov, sb, vseqr. For class names, same as their filenames.
	apb_cov_collector     cov;
	apb_scoreboard        sb;
    apb_virtual_sequencer vseqr;

	int err;            // public variable used to report the local pass/fail state
	
	function new(string name = "apb_env", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		uvm_config_db#(int)::set(this, "apb_master", "agent_kind", `IS_MASTER);	
		uvm_config_db#(int)::set(this, "apb_slave",  "agent_kind", `IS_SLAVE);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "apb_master", "is_active", UVM_ACTIVE);
		uvm_config_db#(uvm_active_passive_enum)::set(this, "apb_slave",  "is_active", UVM_ACTIVE);
		cfg        = apb_cfg  ::type_id::create("cfg", this);
		apb_master = apb_agent::type_id::create("apb_master", this);
		apb_slave  = apb_agent::type_id::create("apb_slave", this);
		
		vseqr = apb_virtual_sequencer::type_id::create("vseqr", this);
		cov   = apb_cov_collector::type_id::create("cov", this);
		sb    = apb_scoreboard::type_id::create("sb", this);
	endfunction

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		
		// 1. Connect the master agent analysis port and the 
		//    slave agent analysis port to their respective
		//    exports in the scoreboard.
		// 2. Subscribe the coverage collector to the
		//    master agent's analysis port.
		// 3. Assign the two sequencer handles inside the
		//    virtual sequencer with the pointers to their
		//    respective agent sequencers.
		// 4. Assign the cfg handles inside the three new
		//    components to point to env.cfg
		// vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
		apb_master.drv.ap.connect(cov.analysis_export);
        apb_master.drv.ap.connect(sb.master_export);
		apb_slave .mon.ap.connect(sb.slave_export);
		vseqr.apb1_seqr = apb_master.seqr;
		vseqr.apb2_seqr = apb_slave.seqr;
		sb.cfg = cfg;
		cov.cfg = cfg;
		vseqr.cfg = cfg;
		// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
		apb_master.cfg = cfg;
		apb_slave.cfg = cfg;

	endfunction
	
	// hierarchical report: each env should query the pass/fail state
	// of all its children scoreboards. Here we use a simple counter, where zero means pass.
	// since the report_phase is traversed bottom-up, the topmost env gets the overall sum.
	virtual function void report_phase(uvm_phase phase);
		super.report_phase(phase);
		err += sb.err;
	endfunction
	
endclass : apb_env

`endif // SV_APB_ENV
