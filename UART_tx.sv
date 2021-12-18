`timescale 1ns/1ns
module UART_tx (
    input clk, rst_n,
    input trmt,
    input [7:0] tx_data,
    output reg tx_done,
    output reg TX
);

// set baud rate as localparams
localparam BAUD_RATE = 19200;
localparam CLK = 50000000;
localparam BAUD_CNT_REF = CLK/BAUD_RATE;

logic [3:0] bit_cnt;
logic unsigned [11:0] baud_cnt;
logic [8:0] tx_shift_reg;

// SM/control signals
logic init, shift, transmitting, set_done;

// bit counter (counts to 10), increments after every bit
always_ff @(posedge clk) 
    case ({init,shift})
        2'b00 : bit_cnt <= bit_cnt;
        2'b01 : bit_cnt <= bit_cnt + 1;
        default : bit_cnt <= 3'h0; // 10 or 11
    endcase

// counts from 0 to 2604
always_ff @(posedge clk) 
    case ({init|shift,transmitting})
        2'b00 : baud_cnt <= baud_cnt;
        2'b01 : baud_cnt <= baud_cnt + 1;
        default : baud_cnt <= 3'h0; // 10 or 11
    endcase

// initialize as tx_data with a zero at the end for start of transmission
// then shift register repeatedly for each TX bit until all bits are transmitted
always_ff @(posedge clk,negedge rst_n)
    if (!rst_n)
        tx_shift_reg <= 9'h1ff; // set
    else
        case ({init,shift})
            2'b00 : tx_shift_reg <= tx_shift_reg;
            2'b01 : tx_shift_reg <= {1'b1,tx_shift_reg[8:1]};
            default : tx_shift_reg <= {tx_data[7:0],1'b0}; // 10 or 11
        endcase

// synchronous SR flop logic for tx_done signal
always_ff @(posedge clk,negedge rst_n)
    if (!rst_n)
        tx_done <= 1'b0;
    else if (init)
        tx_done <= 1'b0;
    else if (set_done)
        tx_done <= 1'b1;
    else
        tx_done <= tx_done; 

// TX is LSB of shifting register
assign TX = tx_shift_reg[0];
// shift goes high when count has reached 2604
assign shift = baud_cnt >= BAUD_CNT_REF;

// STATE MACHINE LOGIC

typedef enum reg {IDLE, TRAN} TX_state_t;
TX_state_t state, nxt_state;

// sequential logic
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;

// combinational logic (next state and output ctrl)
always_comb begin
    nxt_state = IDLE;
    init = 0;
    transmitting = 0;
    set_done = 0;

    case (state) 
        IDLE:
        // wait till external trmt signal goes high,
        // then we can start transmitting
        if (trmt) begin
            nxt_state = TRAN;
            init = 1;
        end
        default: begin
        // stay in TRAN until we have counted to 10 bits,
        // then transmission is over and we go to IDLE
        if (bit_cnt == 4'hA) begin
            nxt_state = IDLE;
            set_done = 1;
        end else begin
            nxt_state = TRAN;
            transmitting = 1;
        end
        end
    endcase
end
    
endmodule