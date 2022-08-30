module gc_xy_inj_top (
    input clk, rst_n,

    // Console signal
    inout JB_cons,

    // Controller signal
    inout JB_ctlr

    // Debug
    /*output DBG_btn_A,
    output DBG_btn_B,
    output DBG_btn_X,
    output DBG_btn_Y,
    output [3:0] DBG_dig,
    output [7:0] DBG_seg,
    output DBG_count_high,
    output [2:0] DBG_state*/
);

reg reset_poll_status;
reg reset_cmd_done_status;

reg console_to_cntlr;
reg cntlr_to_console;

reg inject_sel;
reg rx_start;
reg start_injection;

wire JB_cons_RX;
wire JB_ctlr_RX;
wire JB_inj_TX;
assign JB_ctlr = console_to_cntlr ? JB_cons_RX : 1'bz;
assign JB_cons = cntlr_to_console ? (inject_sel ? JB_inj_TX : JB_ctlr_RX): 1'bz;

assign JB_cons_RX = JB_cons;
assign JB_ctlr_RX = JB_ctlr;

wire console_did_poll;
wire console_cmd_done;

wire x,y;
wire rx_done;
wire rx_start_injection;
wire inj_tx_done;

///////////////////////////
// JOYBUS INSTANTIATION //
/////////////////////////
console_rx iCONS_RX(.clk(clk), .rst_n(rst_n), .JB_RX(JB_cons),
    .reset_poll_status(reset_poll_status), .console_did_poll(console_did_poll),
    .reset_cmd_done_status(reset_cmd_done_status), .console_cmd_done(console_cmd_done));

cntlr_rx iCNTLR_RX(.clk(clk), .rst_n(rst_n), .JB_RX(JB_inj_TX), .rx_start(rx_start),
    .rx_done(rx_done), .x(x), .y(y), .start_injection(rx_start_injection));

injection_tx  iINJ_TX(.clk(clk), .rst_n(rst_n), .inj_tx_start(start_injection),
    .x(x), .y(y), .JB_TX(JB_inj_TX), .inj_tx_done(inj_tx_done));

//////////////////////////
// STATE MACHINE LOGIC //
////////////////////////

typedef enum reg [1:0] {WAIT_FOR_CONS_POLL, READ_CNTLR, INJECT_RESP, FINISH_READ_CNTLR} inj_state_t;
inj_state_t state, nxt_state;

// sequential logic

always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        state <= WAIT_FOR_CONS_POLL;
    else
        state <= nxt_state;

always_comb begin
    console_to_cntlr = 1;
    cntlr_to_console = 0; 
    rx_start = 0;
    reset_cmd_done_status = 0;
    reset_poll_status = 0;
    inject_sel = 0;
    start_injection = 0;

    nxt_state = state;

    case (state)
        WAIT_FOR_CONS_POLL: begin
            console_to_cntlr = 1;
            if (console_cmd_done) begin
                nxt_state = READ_CNTLR;
                reset_cmd_done_status = 1;
                rx_start = 1;
                cntlr_to_console = 1;
                console_to_cntlr = 0;
            end
        end
        READ_CNTLR: begin
            cntlr_to_console = 1;
            console_to_cntlr = 0;
            if (console_did_poll && rx_start_injection) begin
                start_injection = 1;
                inject_sel = 1;
                reset_poll_status = 1;
            end
        end
        INJECT_RESP: begin
            cntlr_to_console = 1;
            console_to_cntlr = 0;
            inject_sel = 1;
            if (inj_tx_done) begin
                inject_sel = 0;
                nxt_state = FINISH_READ_CNTLR;                
            end
        end
        FINISH_READ_CNTLR: begin
            cntlr_to_console = 1;
            console_to_cntlr = 0;
            if (rx_done) begin
                nxt_state = WAIT_FOR_CONS_POLL;
            end
        end
    endcase
end

endmodule
