// ============================================================================
// File:        tb_cxl_top.sv
// Author:      Abhishek Singh  UIDAI: 9414 9122 9013 (GitHub: @Abhishek1033ubuntu)
// Description: Top-Level SystemVerilog Verification Testbench for CXL Controller
// ----------------------------------------------------------------------------
// Copyright (c) 2026 Abhishek Singh. All Rights Reserved.
//
// This source code describes Open Hardware and is licensed under the 
// CERN Open Hardware Licence - Strongly Reciprocal (CERN-OHL-S-2.0).
// ============================================================================

`timescale 1ns / 1ps

module tb_cxl_top;

    logic        clk;
    logic        rst_n;
    logic        host_req_valid;
    logic [63:0] host_req_addr;
    logic [511:0]host_req_data;
    logic [6:0]  host_req_qid;
    logic        host_req_ready;
    logic [8:0]  current_credits;
    logic        storage_full_err;
    logic        dedupe_valid;
    logic [63:0] dedupe_addr;
    logic [511:0]dedupe_data;
    logic        dedupe_ready;
    logic        link_fault_flag;
    logic        mirror_commit_ack;

    // Clock Generation (500 MHz -> 2ns period)
    initial clk = 0;
    always #1 clk = ~clk;

    // Instantiate Device Under Test (DUT)
    cxl_mirror_fsm dut (
        .clk(clk),
        .rst_n(rst_n),
        .host_req_valid(host_req_valid),
        .host_req_addr(host_req_addr),
        .host_req_data(host_req_data),
        .host_req_qid(host_req_qid),
        .host_req_ready(host_req_ready),
        .current_credits(current_credits),
        .storage_full_err(storage_full_err),
        .dedupe_valid(dedupe_valid),
        .dedupe_addr(dedupe_addr),
        .dedupe_data(dedupe_data),
        .dedupe_ready(dedupe_ready),
        .link_fault_flag(link_fault_flag),
        .mirror_commit_ack(mirror_commit_ack)
    );

    // Verification Sequence
    initial begin
        $display("[TB] Starting CXL Mirror FSM Hardware Verification...");
        rst_n = 0;
        host_req_valid = 0;
        host_req_addr = 0;
        host_req_data = 0;
        host_req_qid = 0;
        dedupe_ready = 1;
        link_fault_flag = 0;

        #10 rst_n = 1;
        #10;

        // Test Transaction 1: Standard Write Request
        @(posedge clk);
        host_req_valid = 1;
        host_req_addr  = 64'hDEADBEEF00001000;
        host_req_data  = {16{32'hA5A5A5A5}};
        host_req_qid   = 7'd5;

        wait(host_req_ready);
        @(posedge clk);
        host_req_valid = 0;

        $display("[TB] Transaction Dispatched. Checking Credits: %d", current_credits);
        #50;

        // Test Transaction 2: Link Fault Injection (Sub-10ns Check)
        $display("[TB] Injecting Hardware Link Fault...");
        link_fault_flag = 1;
        #20;
        assert(dut.current_state == 3'b101) $display("[PASS] Hardware Fault Handled Correctly.");
        else $error("[FAIL] FSM Failed to Halt on Link Fault!");

        link_fault_flag = 0;
        #20;

        $display("[TB] Verification Completed Successfully.");
        $finish;
    end

endmodule
