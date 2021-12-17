`timescale 1ns/1ns
module JOYBUS_host (
    input clk, rst_n,
    output JB,
    output btn_A,
    output btn_B,
    output btn_Z
);

////////////////////////////
// STATE MACHINE OUTPUTS //
//////////////////////////
logic cmd_rdy;
logic [7:0] cmd_data;

///////////////////////
// TX INSTANTIATION //
/////////////////////
logic JB_TX, JB_TX_SEL;
logic tx_done; 
logic rx_done;
JOYBUS_tx iJB_TX(.*);

///////////////////////
// RX INSTANTIATION //
/////////////////////
logic JB_RX;
JOYBUS_tx iJB_RX(.*, .rx_start(tx_done));

//////////////////////////
// TRISTATE ASSIGNMENT //
////////////////////////

assign JB_RX = JB;
assign JB = JB_TX_SEL ? JB_TX : 1'bz; // pull line to high-Z if we're reading i.e. JB_TX_SEL is low




endmodule