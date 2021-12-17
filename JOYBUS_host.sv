`timescale 1ns/1ns
module JOYBUS_host (
    input clk, rst_n,
    input [7:0] cmd_data,
    input cmd_rdy,
    input JB_RX,
    output reg JB_TX,
    output reg tx_done // TEMPORARY
);

////////////////////////////
// STATE MACHINE OUTPUTS //
//////////////////////////
logic count_cycles = 0; 
logic tx_high = 0;
logic tx_low = 0;
logic ld_cmd_data = 0;
logic shift_tx = 0;

/////////////////////////////////////
// Counter for each duration type //
///////////////////////////////////

// STOP bit = 2.4uS
// Data = 2uS
// Bit start/ends = 1uS
logic [6:0] tx_cycle_count;
always_ff @(posedge clk) 
    if (count_cycles) 
        tx_cycle_count <= tx_cycle_count + 1;
    else
        tx_cycle_count <= 0; 

wire tx_cycle_count_data = tx_cycle_count == 7'd48;
wire tx_cycle_count_start_end = tx_cycle_count == 7'd24;
wire tx_cycle_count_stop = tx_cycle_count == 7'd60;

///////////////////////
// Shift Reg for TX //
/////////////////////

// initialize as tx_data with a zero at the end for start of transmission
// then shift register repeatedly for each TX bit until all bits are transmitted
logic [7:0] jb_tx_shift_reg;
always_ff @(posedge clk,negedge rst_n)
    if (!rst_n)
        jb_tx_shift_reg <= 8'hff; // set
    else
        case ({ld_cmd_data, shift_tx})
            2'b00 : jb_tx_shift_reg <= jb_tx_shift_reg;
            2'b01 : jb_tx_shift_reg <= {jb_tx_shift_reg[6:0],1'b1};
            default : jb_tx_shift_reg <= cmd_data; // 10 or 11
        endcase

/////////////////////////
// Bit counter for TX //
///////////////////////

logic [3:0] bit_cnt;
always_ff @(posedge clk) 
    case ({ld_cmd_data, shift_tx})
        2'b00 : bit_cnt <= bit_cnt;
        2'b01 : bit_cnt <= bit_cnt + 1;
        default : bit_cnt <= 4'h0; // 10 or 11
    endcase

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

// STATE MACHINE LOGIC

typedef enum reg [2:0] {IDLE, CMD, DATA, DATA_CNT, HIGH, STOP} TX_state_t;
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
    tx_done = 0;
    ld_cmd_data = 0;
    shift_tx = 0;

    nxt_state = state;

    case (state)
    IDLE: begin
        if (cmd_rdy)
            nxt_state = CMD;
            count_cycles = 1;
            tx_low = 1;
            ld_cmd_data = 1;
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
            count_cycles = 1;
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
            nxt_state = IDLE;
            tx_done = 1;
        end else begin
            count_cycles = 1;
            tx_high = 1;
        end
    end
    endcase
end

endmodule