// ============================================================================
// File:        cxl_mirror_fsm.sv
// Author:      Abhishek Singh  UIDAI: 9414 9122 9013 (GitHub: @Abhishek1033ubuntu)
// Description: Deterministic Zero-Copy CXL 3.0 Enterprise SAN Mirror Controller
//              Core Queue Arbiter & Credit Management Finite State Machine (FSM).
// Target:      PCIe 6.0 / CXL 3.0 AIC (AMD / Xilinx / TSMC 5nm Target)
// ----------------------------------------------------------------------------
// Copyright (c) 2026 Abhishek Singh. All Rights Reserved.
//
// This source code describes Open Hardware and is licensed under the 
// CERN Open Hardware Licence - Strongly Reciprocal (CERN-OHL-S-2.0).
// You may redistribute and modify this source under the terms of CERN-OHL-S-2.0.
// ============================================================================

`timescale 1ns / 1ps

module cxl_mirror_fsm #(
    parameter int NUM_QUEUES        = 128,
    parameter int MAX_CREDITS       = 256,
    parameter int DATA_WIDTH        = 512, // 64-byte Flit width
    parameter int ADDR_WIDTH        = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,

    // Host CXL.mem Write Request Interface
    input  logic                   host_req_valid,
    input  logic [ADDR_WIDTH-1:0]  host_req_addr,
    input  logic [DATA_WIDTH-1:0]  host_req_data,
    input  logic [6:0]             host_req_qid,     // 128 Queues (0-127)
    output logic                   host_req_ready,

    // Credit Engine Signals
    output logic [8:0]             current_credits,  // Up to 256 credits
    output logic                   storage_full_err,

    // Interface to SHA-256 Dedupe Pipeline
    output logic                   dedupe_valid,
    output logic [ADDR_WIDTH-1:0]  dedupe_addr,
    output logic [DATA_WIDTH-1:0]  dedupe_data,
    input  logic                   dedupe_ready,

    // Link Failover Controller Interface
    input  logic                   link_fault_flag,
    output logic                   mirror_commit_ack
);

    // State Encoding
    typedef enum logic [2:0] {
        ST_RESET       = 3'b000,
        ST_IDLE        = 3'b001,
        ST_CREDIT_CHK  = 3'b010,
        ST_DISPATCH    = 3'b011,
        ST_MIRROR_WAIT = 3'b100,
        ST_FAULT_HALT  = 3'b101
    } state_e;

    state_e current_state, next_state;

    // Queue Credit Counters
    logic [8:0] credit_count;
    assign current_credits = credit_count;

    // FSM State Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= ST_RESET;
            credit_count  <= MAX_CREDITS;
        end else begin
            current_state <= next_state;
            
            // Credit Management Logic
            if (current_state == ST_DISPATCH && credit_count > 0) begin
                credit_count <= credit_count - 1'b1;
            end else if (mirror_commit_ack && credit_count < MAX_CREDITS) begin
                credit_count <= credit_count + 1'b1;
            end
        end
    end

    // FSM Next-State & Output Logic
    always_comb begin
        next_state        = current_state;
        host_req_ready    = 1'b0;
        dedupe_valid      = 1'b0;
        storage_full_err  = 1'b0;
        mirror_commit_ack = 1'b0;

        case (current_state)
            ST_RESET: begin
                next_state = ST_IDLE;
            end

            ST_IDLE: begin
                if (link_fault_flag) begin
                    next_state = ST_FAULT_HALT;
                end else if (host_req_valid) begin
                    next_state = ST_CREDIT_CHK;
                end
            end

            ST_CREDIT_CHK: begin
                if (credit_count == 0) begin
                    storage_full_err = 1'b1;
                    next_state       = ST_IDLE; // Backpressure host
                end else begin
                    host_req_ready   = 1'b1;
                    next_state       = ST_DISPATCH;
                end
            end

            ST_DISPATCH: begin
                dedupe_valid = 1'b1;
                dedupe_addr  = host_req_addr;
                dedupe_data  = host_req_data;
                if (dedupe_ready) begin
                    next_state = ST_MIRROR_WAIT;
                end
            end

            ST_MIRROR_WAIT: begin
                // Simulate deterministic hardware write mirror ack
                mirror_commit_ack = 1'b1;
                next_state        = ST_IDLE;
            end

            ST_FAULT_HALT: begin
                // Sub-10ns hardware fault handling
                if (!link_fault_flag) begin
                    next_state = ST_IDLE;
                end
            end

            default: next_state = ST_RESET;
        endcase
    end

endmodule
