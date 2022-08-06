import cocotb
from cocotb.triggers import Timer
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from cocotb.utils import get_sim_time
import random

async def jb_bit(bit, JB):
    JB.value = 0
    await Timer(1, units="us")
    JB.value = 1 if bit else 0
    await Timer(2, units="us")
    JB.value = 1
    await Timer(1, units="us")

async def jb_stop(JB):
    JB.value = 0
    await Timer(4, units="us")
    JB.value = 1

async def send_rand_resp(JB_RX):
    # 32 bits of random data
    resp = int.from_bytes(random.randbytes(4), byteorder='big')
    resp_temp = resp
    for _ in range(32):
        # shift left one bit
        resp_temp <<= 1
        # send out MSB of response
        await jb_bit(resp_temp & (1 << 31), JB_RX)
    await jb_stop(JB_RX)
    return resp


@cocotb.test()
async def main_test(dut):
    cnt = 0

    dut.rst_n.value = 1
    dut.clk.value = 0

    cocotb.start_soon(Clock(dut.clk, 20, units="ns").start())

    await RisingEdge(dut.clk)
    dut.rst_n.value = 0

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1

    await RisingEdge(dut.iJB_HOST.tx_done)
    dut._log.info(f"TRANSFERRING CONTROL.. time ={get_sim_time(units = 'ns')}")
    resp = await send_rand_resp(dut.JB)
    await RisingEdge(dut.iJB_HOST.rx_done)
    dut._log.info(hex(resp))
    dut._log.info(dut.btn_A.value)
