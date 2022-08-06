module ESS_top (
    input clk, rst_n,

    // Console signal
    inout JB_cons,

    // Controller signal
    inout JB_ctlr,

    // Debug
    output DBG_btn_A,
    output DBG_btn_B,
    output DBG_btn_X,
    output DBG_btn_Y,
    output [3:0] DBG_dig,
    output [7:0] DBG_seg,
    output DBG_count_high,
    output [2:0] DBG_state
);

wire [63:0] cntlr_data;
wire cntlr_data_rdy;

reg SEND_CONS_RESP_sel;

wire JB_cons_RX = JB_cons;
wire JB_ctlr_RX = JB_ctlr;
assign JB_ctlr = SEND_CONS_RESP_sel ? 1'bz : JB_cons_RX;
assign JB_cons = SEND_CONS_RESP_sel ? 1'b0 : JB_ctlr_RX;

wire console_did_poll;
assign DBG_btn_A = console_did_poll;

///////////////////////////
// JOYBUS INSTANTIATION //
/////////////////////////
console_rx iCONS_RX(.clk(clk), .rst_n(rst_n), .JB_RX(JB_cons),
    .reset_poll_status(1'b0), .console_did_poll(console_did_poll));

//////////////////////////
// STATE MACHINE LOGIC //
////////////////////////

typedef enum reg [1:0] {WAIT_FOR_CONS_POLL, READ_CNTLR, FIX_RESP, SEND_RESP} RX_state_t;
RX_state_t state, nxt_state;

// sequential logic
/*
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        state <= WAIT_FOR_CONS_POLL;
    else
        state <= nxt_state;
*/

always_comb begin
    SEND_CONS_RESP_sel = 1'b0;
end

//always_comb begin
//    case (sate)
//        WAIT_FOR_CONS_POLL: begin
//            if console_did_poll:
//        end
//        READ_CNTLR: begin
//
//        end
//    endcase
//end

endmodule
