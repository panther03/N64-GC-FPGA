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

reg reset_poll_status;
reg reset_cmd_done_status;

reg console_to_cntlr;
reg cntlr_to_console;

reg inject_sel;

wire JB_cons_RX;
wire JB_ctlr_RX;
assign JB_ctlr = console_to_cntlr ? JB_cons_RX : 1'bz;
assign JB_cons = cntlr_to_console ? (inject_sel ? JB_ctlr_RX): 1'bz;

assign JB_cons_RX = JB_cons;
assign JB_ctrl_RX = JB_ctlr;

wire console_did_poll;
wire console_cmd_done;

///////////////////////////
// JOYBUS INSTANTIATION //
/////////////////////////
console_rx iCONS_RX(.clk(clk), .rst_n(rst_n), .JB_RX(JB_cons),
    .reset_poll_status(reset_poll_status), .console_did_poll(console_did_poll),
    .reset_cmd_done_status(reset_cmd_done_status), .console_cmd_done(console_cmd_done));

//////////////////////////
// STATE MACHINE LOGIC //
////////////////////////

typedef enum reg [1:0] {WAIT_FOR_CONS_POLL, READ_CNTLR, INJECT_RESP, FINISH_READ_CNTLR} ESS_state_t;
ESS_state_t state, nxt_state;

// sequential logic

always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        state <= WAIT_FOR_CONS_POLL;
    else
        state <= nxt_state;

always_comb begin
    console_to_cntlr = 1;
    cntlr_to_console = 0; 

    case (sate)
        WAIT_FOR_CONS_POLL: begin
            console_to_cntlr = 1;
            if console_cmd_done begin
                nxt_state = READ_CNTLR;
                reset_cmd_done_status = 1;
                rx_start = 1
            end
        end
        READ_CNTLR: begin
            if console_did_poll
        end
    endcase
end

endmodule
