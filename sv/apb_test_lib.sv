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
`ifndef SV_APB_TEST_LIB
`define SV_APB_TEST_LIB

// this is the first and most basic user-defined test. 
// It is recommended to keep this class very simple and thin, containing only the essential.
// All the actual user tests will then be derived from it.

class apb_base_test extends uvm_test;
	// all tests *MUST* be registered or they won't be visible to the run_test task.
	`uvm_component_utils(apb_base_test)

	// place here the top-level container of the UVM framework
	apb_env env;

	function new(string name = "apb_base_test", uvm_component parent = null);
		super.new(name, parent);
		uvm_top.enable_print_topology = 1; // default: print topology
		uvm_top.set_timeout(10ms);         // default simulation timeout
	endfunction

	// UVM components are always instantiated here in the build_phase, not inside new()
	// Make sure that the parent's build_phase is called beforehand.
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = apb_env::type_id::create("env", this);
	endfunction : build_phase

	virtual task run_phase(uvm_phase phase);
		$display("Hello World!");
	endtask

	// hierarchical report: each env should query the pass/fail state
	// of all its children scoreboards. Here we use a simple counter, where zero means pass.
	// since the report_phase is traversed bottom-up, the topmost env gets the overall sum.
	virtual function void report_phase(uvm_phase phase);
		int error_count;
		super.report_phase(phase);

		// foreach env, do:
		error_count += env.err;

		if(error_count) begin
			`uvm_error("TEST_FAIL", $psprintf("err_count: %0d", error_count));
		end 
		else begin
			`uvm_info("TEST_PASS", $psprintf("err_count: %0d", error_count), UVM_NONE);
		end
	endfunction

endclass : apb_base_test

// The smoke test is the first and most basic user-defined test.
// Its sole purpose is to check that the pipes are clean, that all UVCs are built and connected and
// the simulator is happy with your most basic code.
class apb_smoke_test extends apb_base_test;
	`uvm_component_utils(apb_smoke_test)

	function new(string name = "apb_smoke_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	// This redefinition can be omitted if only the super.build_phase is called.
	// However, the build_phase is where user-defined overrides to class types are specified.
	// Most overrides are test-specific, so it's a good idea to have the build_phase
	// redefined here even when it is a mere placeholder like in this case.
	//
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	endfunction : build_phase

	virtual task run_phase(uvm_phase phase);
		apb_virtual_seq vseq;

		// We raise an objection before running something critical (like the test itself)
		// to prevent the run_phase to exit prematurely to the next phase and terminate the test.
		// Once the critical section here is done, the objection can be dropped.
		// There may be multiple threads, each executing its own run_phase, and each of them should raise an 
		// objection. When the last pending objection have been dropped, all components that objected can proceed to the check_phase.

		phase.raise_objection(this);

		$display("Hello World!");
		#1us;

		vseq = apb_smoke_vseq::type_id::create( .name( "smoke_vseq" ), .contxt( get_full_name() ) );
		assert( vseq.randomize() );
		vseq.start( .sequencer( env.vseqr ) );

		phase.drop_objection(this);
	endtask

endclass : apb_smoke_test

class apb_rw_range16_test extends apb_base_test;
	`uvm_component_utils(apb_rw_range16_test)

	function new(string name = "apb_rw_range16_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction

  virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		set_type_override_by_type(apb_smoke_vseq::get_type(), apb_rw_range16_vseq::get_type());
	endfunction : build_phase

endclass : apb_rw_range16_test

`endif // SV_APB_TEST_LIB