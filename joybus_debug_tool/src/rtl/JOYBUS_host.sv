`timescale 1ns/1ns
module JOYBUS_host (
    input clk, rst_n,
    inout JB,
    input btn_send_ORIGIN,
    input btn_send_POLL,
    output [7:0] rpi_btns,
    input btn_A,
    input btn_B,
    input sw_START,
    input sw_UP,
    input sw_DOWN,
    input sw_LEFT,
    input sw_RIGHT
);

// localparam POLL_RATE_MS = 20;
// localparam POLL_CYCLES = POLL_RATE_MS * 1000 * 1000 * 1/40;

////////////////////////////
// STATE MACHINE OUTPUTS //
//////////////////////////
logic count_poll_cycles; 
logic cmd_rdy;
logic [7:0] cmd_data;
logic ld_cntlr_data;

//////////////////////
// POLLING COUNTER //
////////////////////
// logic [$clog2(POLL_CYCLES):0] poll_cycle_count;
// always_ff @(posedge clk)
//     if (count_poll_cycles)
//         poll_cycle_count <= poll_cycle_count + 1;
//     else 
//         poll_cycle_count <= 0;

// wire poll_cycle_count_done = poll_cycle_count == POLL_CYCLES;

///////////////////////
// TX INSTANTIATION //
/////////////////////
logic JB_TX, JB_TX_SEL;
logic tx_done;
JOYBUS_tx iJB_TX(
    .clk(clk),
    .rst_n(rst_n),
    .cmd_data(cmd_data),
    .cmd_rdy(cmd_rdy),
    .JB_TX(JB_TX),
    .JB_TX_SEL(JB_TX_SEL),
    .tx_done(tx_done)
);

///////////////////////
// RX INSTANTIATION //
/////////////////////
// logic JB_RX;
// logic [31:0] jb_rx_cntlr_data;
// JOYBUS_rx iJB_RX(.*, .rx_start(tx_done),
//     .jb_cntlr_data(jb_rx_cntlr_data));

//////////////////////////
// TRISTATE ASSIGNMENT //
////////////////////////
// assign JB_RX = JB_TX_SEL ? 1'b0 : JB;
// pull line to high-Z if we're reading i.e. JB_TX_SEL is low
assign JB = JB_TX_SEL ? JB_TX : 1'bz;

///////////////////////////////////
// FLOP TO HOLD CONTROLLER DATA //
/////////////////////////////////
// logic [31:0] jb_cntlr_data;
// always_ff @(posedge clk, negedge rst_n)
//     if (!rst_n) begin 
//         jb_cntlr_data <= 0;
//     end else if (ld_cntlr_data) begin
//         // When we're finished with a read, hold it until the next poll (20ms by default)
//         jb_cntlr_data <= jb_rx_cntlr_data; 
// 	 end

// assign cntlr_data_rdy = ld_cntlr_data; // if we're loading cntlr data, we want to tell the uart
// assign cntlr_data = jb_cntlr_data;

///////////////////
// BUTTON LOGIC //
/////////////////

reg [7:0] btn_send_ORIGIN_sr;
reg [7:0] btn_send_POLL_sr;
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        btn_send_ORIGIN_sr <= 0;
        btn_send_POLL_sr <= 0;
    end else begin
        btn_send_ORIGIN_sr <= {btn_send_ORIGIN_sr[6:0], ~btn_send_ORIGIN};
        btn_send_POLL_sr <= {btn_send_POLL_sr[6:0], ~btn_send_POLL};
    end
end

wire btn_send_ORIGIN_db = btn_send_ORIGIN_sr == 8'h7F;
wire btn_send_POLL_db = btn_send_POLL_sr == 8'h7F;

////////////////////
// CMD_data flop //
//////////////////

always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        cmd_data <= 0;
    else if (btn_send_ORIGIN_db) 
        cmd_data <= 8'h00;
    else if (btn_send_POLL_db)
        cmd_data <= 8'h01;
end

//////////////////////////
// STATE MACHINE LOGIC //
////////////////////////

typedef enum reg {IDLE, TX} Host_state_t;
Host_state_t state, nxt_state;

// sequential logic
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;

// combinational logic (next state and output ctrl)
always_comb begin
    // count_poll_cycles = 0;
    // ld_cntlr_data = 0;

    cmd_rdy = 0;
    nxt_state = state;

    case (state)
    IDLE: begin
        if (btn_send_ORIGIN_db | btn_send_POLL_db) begin
            nxt_state = TX;
            cmd_rdy = 1;
        end
    end
    TX: begin
        if (tx_done) begin
            nxt_state = IDLE;
        end
    end
    endcase
end


// Seven segment display for debug
// seven_seg_main i7Seg(.disp_num(jb_cntlr_data[15:0]),.clk(clk),.rst_n(rst_n),.dig(DBG_dig),.seg(DBG_seg));

assign rpi_btns = {1'b0, btn_A, btn_B, sw_START, sw_UP, sw_DOWN, sw_LEFT, sw_RIGHT};

endmodule