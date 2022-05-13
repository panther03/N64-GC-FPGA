`timescale 1ns/1ns
module JOYBUS_host (
    input clk, rst_n,
    output JB,
    output btn_A,
    output btn_B,
    output btn_Z,
    output reg [3:0] dbg
);

localparam POLL_RATE_MS = 20;
localparam POLL_CYCLES = POLL_RATE_MS * 1000 * 1000 * 1/40;

////////////////////////////
// STATE MACHINE OUTPUTS //
//////////////////////////
logic count_poll_cycles; 
logic cmd_rdy;
logic [7:0] cmd_data;
logic ld_cntlr_data;
logic rst_cntlr_data;

//////////////////////
// POLLING COUNTER //
////////////////////
logic [$clog2(POLL_CYCLES):0] poll_cycle_count;
always_ff @(posedge clk)
    if (count_poll_cycles)
        poll_cycle_count <= poll_cycle_count + 1;
    else 
        poll_cycle_count <= 0;

wire poll_cycle_count_done = poll_cycle_count == POLL_CYCLES;

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
logic [7:0] jb_rx_cntlr_status;
logic [31:0] jb_rx_cntlr_data;
JOYBUS_rx iJB_RX(.*, .rx_start(tx_done),
    .jb_cntlr_status(jb_rx_cntlr_status),
    .jb_cntlr_data(jb_rx_cntlr_data));

//////////////////////////
// TRISTATE ASSIGNMENT //
////////////////////////
assign JB_RX = JB;
// pull line to high-Z if we're reading i.e. JB_TX_SEL is low
assign JB = JB_TX_SEL ? JB_TX : 1'bz; 

///////////////////////////////////
// FLOP TO HOLD CONTROLLER DATA //
/////////////////////////////////
logic [31:0] jb_cntlr_data;
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        jb_cntlr_data <= 0;
    else if (rst_cntlr_data)
        jb_cntlr_data <= 0;
    else if (ld_cntlr_data)
        jb_cntlr_data <= jb_rx_cntlr_data; 

/////////////////////////
// BUTTON ASSIGNMENTS //
///////////////////////
assign btn_A = jb_cntlr_data[31];
assign btn_B = jb_cntlr_data[30];
assign btn_Z = jb_cntlr_data[29];

//////////////////////////
// STATE MACHINE LOGIC //
////////////////////////

typedef enum reg {IDLE, TRX} Host_state_t;
Host_state_t state, nxt_state;

// sequential logic
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;

// combinational logic (next state and output ctrl)
always_comb begin
    count_poll_cycles = 0;
    cmd_rdy = 0;
    cmd_data = 0;
    ld_cntlr_data = 0;
    rst_cntlr_data = 0;
    dbg = 4'b0000;

    nxt_state = state;

    case (state)
    IDLE: begin
        dbg = 4'b0000;
        if (poll_cycle_count_done) begin
            nxt_state = TRX;
            cmd_data = 8'h01;
            cmd_rdy = 1;
        end
        else
            count_poll_cycles = 1;
    end
    TRX: begin
        if (rx_done) begin
            nxt_state = IDLE;
            dbg = 4'b11111;
            if (jb_rx_cntlr_status == 8'h05)
                ld_cntlr_data = 1;
            else
                rst_cntlr_data = 1;
        end else begin
            dbg = 4'b0011;
        end
    end
    endcase
end
endmodule
