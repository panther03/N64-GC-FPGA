`timescale 1ns/1ns
module injection_tx (
    input clk, rst_n,
    input inj_tx_start,
    input x,
    input y,
    output inj_jb_tx,
    output reg inj_tx_done
);

////////////////////////////
// STATE MACHINE OUTPUTS //
//////////////////////////
logic count_cycles; 
logic tx_high;
logic tx_low;
logic init_tran;
logic set_done;
logic shift_tx;
logic sel_low;

/////////////////////////////////////
// Counter for each duration type //
///////////////////////////////////

localparam DATA_DELAY = 100;

// STOP bit = 2.4uS
// Data = 2uS
// Bit start/ends = 1uS
logic [$clog2(DATA_DELAY):0] tx_cycle_count;
always_ff @(posedge clk) 
    if (count_cycles) 
        tx_cycle_count <= tx_cycle_count + 1;
    else
        tx_cycle_count <= 0; 

wire tx_cycle_count_data = tx_cycle_count == DATA_DELAY - 2; 
wire tx_cycle_count_start_end = tx_cycle_count == (DATA_DELAY >> 1) - 1;
wire tx_cycle_count_stop = tx_cycle_count == 120 - 1;

///////////////////////
// Shift Reg for TX //
/////////////////////

// initialize as tx_data with a zero at the end for start of transmission
// then shift register repeatedly for each TX bit until all bits are transmitted
logic [7:0] jb_tx_shift_reg;
always_ff @(posedge clk,negedge rst_n)
    if (!rst_n)
        jb_tx_shift_reg <= 8'hff; // set
    else if (init_tran)
        jb_tx_shift_reg <= cmd_data;
    else if (shift_tx)        
        jb_tx_shift_reg <= {jb_tx_shift_reg[6:0],1'b1};

/////////////////////////
// Bit counter for TX //
///////////////////////

logic [3:0] bit_cnt;
always_ff @(posedge clk, negedge rst_n) 
    if (!rst_n)
        bit_cnt = 0;
    else if (init_tran)
        bit_cnt = 0;
    else if  (shift_tx)
        bit_cnt <= bit_cnt + 1;

/////////////////////////////
// TX combinational logic //
///////////////////////////

always_comb begin
    if (tx_high)
        JB_TX = 1;
    else if (tx_low)
        JB_TX = 0;
    else 
        JB_TX = jb_tx_shift_reg[7];
end

//////////////////////
// tx_done SR flop //
////////////////////

always @(posedge clk)
    if (set_done)       
        tx_done <= 1;
    else
        tx_done <= 0;

/////////////////////
// JB_TX_SEL flop //
///////////////////

always @(posedge clk)
    if (sel_low)
        JB_TX_SEL <= 0;
    else    
        JB_TX_SEL <= 1;

//////////////////////////
// STATE MACHINE LOGIC //
////////////////////////

typedef enum reg [2:0] {IDLE, CMD, DATA, DATA_CNT, HIGH, STOP, RCV_WAIT} TX_state_t;
TX_state_t state, nxt_state;

// sequential logic
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;

// combinational logic (next state and output ctrl)
always_comb begin
    count_cycles = 0; 
    tx_high = 0;
    tx_low = 0;
    set_done = 0;
    init_tran = 0;
    shift_tx = 0;
    sel_low = 0;

    nxt_state = state;

    case (state)
    IDLE: begin
        if (cmd_rdy)
            nxt_state = CMD;
            count_cycles = 1;
            tx_low = 1;
            init_tran = 1;
            sel_low = 1;
    end
    CMD: begin
        if (tx_cycle_count_start_end) begin
            nxt_state = DATA;
            tx_low = 1;
        end else begin
            count_cycles = 1;
            tx_low = 1;
        end
    end
    DATA: begin
        if (bit_cnt[3]) begin
            nxt_state = STOP;
            //count_cycles = 1;
        end else begin
            nxt_state = DATA_CNT;
        end
    end
    DATA_CNT: begin
        if (tx_cycle_count_data) begin
            nxt_state = HIGH;
        end else begin
            count_cycles = 1;
        end
    end
    HIGH: begin
        if (tx_cycle_count_start_end) begin
            nxt_state = CMD;
            shift_tx = 1;
            tx_high = 1;
        end else begin
            count_cycles = 1;
            tx_high = 1;
        end
    end
    STOP: begin
        if (tx_cycle_count_stop) begin
            nxt_state = RCV_WAIT;
            set_done = 1;
            sel_low = 1;
        end else begin
            count_cycles = 1;
            tx_high = 1;
        end
    end
    RCV_WAIT: begin
        if (rx_done)
            nxt_state = IDLE;
        else
            sel_low = 1;
    end
    endcase
end

endmodule
