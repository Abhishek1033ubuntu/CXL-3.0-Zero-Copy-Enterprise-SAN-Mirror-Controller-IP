// ============================================================================
// File:        link_failover_ctrl.sv
// Author:      Abhishek Singh  UIDAI: 9414 9122 9013 (GitHub: @Abhishek1033ubuntu)
// Description: Sub-10ns Hardware Link Monitoring & Dynamic Bus Rerouting Logic
// Target:      PCIe 6.0 / CXL 3.0 AIC (AMD / Xilinx / TSMC 5nm Target)
// ----------------------------------------------------------------------------
// Copyright (c) 2026 Abhishek Singh. All Rights Reserved.
//
// This source code describes Open Hardware and is licensed under the 
// CERN Open Hardware Licence - Strongly Reciprocal (CERN-OHL-S-2.0).
// ============================================================================

`timescale 1ns / 1ps

module link_failover_ctrl (
    input  logic clk,
    input  logic rst_n,

    // Physical Link Health Flags (From PCIe 6.0 / CXL PHY)
    input  logic phy_lane_active_a,
    input  logic phy_lane_active_b,

    // Hardware Output Routing Decision (<10ns Reaction Time)
    output logic active_path_select, // 0 = Path A, 1 = Path B
    output logic link_fault_flag,
    output logic failover_interrupt
);

    // Asynchronous Combinational Logic for Sub-10ns Response
    always_comb begin
        link_fault_flag    = 1'b0;
        failover_interrupt = 1'b0;

        if (phy_lane_active_a) begin
            active_path_select = 1'b0; // Primary CXL Lane A
        end else if (phy_lane_active_b) begin
            active_path_select = 1'b1; // Secondary CXL Lane B (Failover)
            failover_interrupt = 1'b1;
        end else begin
            active_path_select = 1'b0;
            link_fault_flag    = 1'b1; // Total Link Loss
        end
    end

endmodule
