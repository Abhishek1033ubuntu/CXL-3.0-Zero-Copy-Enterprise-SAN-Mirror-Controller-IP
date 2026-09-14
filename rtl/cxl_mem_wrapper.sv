// ============================================================================
// File:        cxl_mem_wrapper.sv
// Author:      Abhishek Singh UIDAI: 9414 9122 9013 (GitHub: @Abhishek1033ubuntu)
// Description: CXL.mem Protocol & Bus Interface Wrapper
// Target:      PCIe 6.0 / CXL 3.0 AIC (AMD / Xilinx / TSMC 5nm Target)
// ----------------------------------------------------------------------------
// Copyright (c) 2026 Abhishek Singh. All Rights Reserved.
//
// This source code describes Open Hardware and is licensed under the 
// CERN Open Hardware Licence - Strongly Reciprocal (CERN-OHL-S-2.0).
// ============================================================================

`timescale 1ns / 1ps

module cxl_mem_wrapper #(
    parameter int DATA_WIDTH = 512,
    parameter int ADDR_WIDTH = 64
)(
    input  logic                  clk,
    input  logic                  rst_n,

    // CXL Flit Interface
    input  logic [DATA_WIDTH-1:0] cxl_flit_in,
    input  logic                  cxl_flit_valid,
    output logic                  cxl_flit_ready,

    output logic [ADDR_WIDTH-1:0] extracted_addr,
    output logic [DATA_WIDTH-1:0] extracted_data,
    output logic                  flit_decoded
);

    assign cxl_flit_ready = rst_n;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            extracted_addr <= '0;
            extracted_data <= '0;
            flit_decoded   <= 1'b0;
        end else if (cxl_flit_valid && cxl_flit_ready) begin
            // Extract 64-Byte Cacheline Header & Payload
            extracted_addr <= cxl_flit_in[63:0];
            extracted_data <= cxl_flit_in[DATA_WIDTH-1:64];
            flit_decoded   <= 1'b1;
        end else begin
            flit_decoded   <= 1'b0;
        end
    end

endmodule
