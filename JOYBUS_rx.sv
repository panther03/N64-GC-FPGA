`timescale 1ns/1ns
module JOYBUS_rx (
    input clk, rst_n,
    input JB_RX,
    input rx_start,
    output reg rx_done,
    output [7:0] jb_cntlr_status,
    output [31:0] jb_cntlr_data
);

////////////////////////////
// STATE MACHINE OUTPUTS //
//////////////////////////
logic count_cycles;
logic shift_rx;
logic set_done;

///////////////////////////////////////
// RX line metastability prevention //
/////////////////////////////////////
logic JB_RX_ff1, JB_RX_ff2;

always_ff @(posedge clk,negedge rst_n)
    if (!rst_n) begin 
        JB_RX_ff1 <= 1;
        JB_RX_ff2 <= 1;
    end else begin
        JB_RX_ff1 <= JB_RX;
        JB_RX_ff2 <= JB_RX_ff1;
    end

/////////////////////////////
// Counter for read cycle //
///////////////////////////

// During each read cycle, keep a tally of how many low & high bytes were observed.
// Once they sum to 100 cycles (4uS), compare each to see which one was higher.
// This "voting" method helps counteract controllers with delayed timing e.g Hori Pad Mini.
// See: https://www.raphnet.net/electronique/gc_n64_usb/index_en.php#5
logic [6:0] rx_cycle_low_count;
logic [6:0] rx_cycle_high_count;
always_ff @(posedge clk, negedge rst_n) 
    if (count_cycles)
        if (JB_RX_ff2)
            rx_cycle_high_count <= rx_cycle_high_count + 1;
        else
            rx_cycle_low_count <= rx_cycle_low_count + 1; 
    else begin
        rx_cycle_low_count <= 0;
        rx_cycle_high_count <= 0;
    end

logic [7:0] rx_cycle_total_count;
assign rx_cycle_total_count = rx_cycle_high_count + rx_cycle_low_count;
wire rx_cycle_count_done = rx_cycle_total_count == 8'd100;
wire rx_cycle_count_stop = rx_cycle_total_count == 8'd50;
wire rx_cycle_bit_high = rx_cycle_high_count > rx_cycle_low_count;

///////////////////////
// Shift Reg for RX //
/////////////////////

logic [39:0] jb_rx_shift_reg;
always_ff @(posedge clk,negedge rst_n)
    if (!rst_n)
        jb_rx_shift_reg <= 0; // set
    else if (shift_rx)        
        jb_rx_shift_reg <= {jb_rx_shift_reg[38:0],rx_cycle_bit_high};

assign jb_cntlr_status = jb_rx_shift_reg[39:32];
assign jb_cntlr_data = jb_rx_shift_reg[31:0];

/////////////////////////
// Bit counter for RX //
///////////////////////

logic [5:0] bit_cnt;
always_ff @(posedge clk, negedge rst_n) 
    if (!rst_n)
        bit_cnt = 0;
    else if (rx_start)
        bit_cnt = 0;
    else if (shift_rx)
        bit_cnt <= bit_cnt + 1;

///////////////////
// rx_done flop //
/////////////////
always @(posedge clk)
    if (set_done)       
        rx_done <= 1;
    else
        rx_done <= 0;

//////////////////////////
// STATE MACHINE LOGIC //
////////////////////////

typedef enum reg [1:0] {IDLE, READ, SHFT, STOP} RX_state_t;
RX_state_t state, nxt_state;

// sequential logic
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;

// combinational logic (next state and output ctrl)
always_comb begin
    count_cycles = 0; 
    shift_rx = 0;
    set_done = 0;

    nxt_state = state;

    case (state)
    IDLE: begin
        if (rx_start) begin
            nxt_state = READ;
            count_cycles = 1;
        end
    end
    READ: begin
        if (rx_cycle_count_done) begin
            nxt_state = SHFT;
            shift_rx = 1;
        end else
            count_cycles = 1;
    end
    SHFT: begin
        if (bit_cnt == 6'h28)
            nxt_state = STOP;
        else
            nxt_state = READ;
    end
    STOP: begin
        if (rx_cycle_count_stop) begin
            nxt_state = IDLE;
            set_done = 1;
        end else
            count_cycles = 1;
    end
    endcase
end
endmodule