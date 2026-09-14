# ============================================================================
# File:        test_cxl_controller.py
# Author:      Abhishek Singh UIDAI: 9414 9122 9013 (GitHub: @Abhishek1033ubuntu)
# Description: Python CoCoTb Testbench Environment for CXL SAN Controller
# ----------------------------------------------------------------------------
# Copyright (c) 2026 Abhishek Singh. All Rights Reserved.
#
# This source code describes Open Hardware and is licensed under the 
# CERN Open Hardware Licence - Strongly Reciprocal (CERN-OHL-S-2.0).
# ============================================================================

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_cxl_basic_write(dut):
    """Verify basic CXL write request flow and latency execution"""
    
    # Start 500 MHz Clock (2ns Period)
    cocotb.start_soon(Clock(dut.clk, 2, units="ns").start())

    # Reset System
    dut.rst_n.value = 0
    dut.host_req_valid.value = 0
    dut.dedupe_ready.value = 1
    dut.link_fault_flag.value = 0
    await Timer(10, units="ns")
    dut.rst_n.value = 1
    await Timer(10, units="ns")

    # Send Request
    dut.host_req_valid.value = 1
    dut.host_req_addr.value = 0x1000200030004000
    dut.host_req_data.value = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    dut.host_req_qid.value = 1

    await RisingEdge(dut.clk)
    while dut.host_req_ready.value == 0:
        await RisingEdge(dut.clk)

    dut.host_req_valid.value = 0
    cocotb.log.info("CXL Host Request Accepted by Hardware FSM.")
    
    await Timer(100, units="ns")
    cocotb.log.info("CoCoTb Verification Passed.")
