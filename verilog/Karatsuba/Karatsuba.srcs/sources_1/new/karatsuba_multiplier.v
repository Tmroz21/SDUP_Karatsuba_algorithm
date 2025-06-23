`timescale 1ns / 1ps

module karatsuba_multiplier #(
    parameter WIDTH = 32,
    parameter BASE_THRESHOLD = 8
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output reg [2*WIDTH-1:0] result,
    output reg done
);

    // Definicje stanów
    localparam IDLE     = 3'b000;  // IDLE
    localparam SPLIT    = 3'b001;  // RozdŸia³
    localparam CALC_LOW = 3'b010;  // Obliczanie dolnej czêœci
    localparam CALC_HIGH= 3'b011;  // Obliczanie górnej czêœci
    localparam CALC_MID = 3'b100;  // Obliczanie œrodkowej czêœci
    localparam COMBINE  = 3'b101;  // £¹czenie wyników
    localparam FINISH   = 3'b110;  // Koniec

    reg [2:0] state, next_state;
    reg [3:0] cycle_count;
    reg [3:0] current_width;

    // Rejestry wewnêtrzne
    reg [WIDTH-1:0] a_low, a_high, b_low, b_high;
    reg [WIDTH:0] a_sum, b_sum;  // Dodatkowy bit dla carry
    reg [2*WIDTH-1:0] low_prod, high_prod, mid_prod;
    reg [2*WIDTH-1:0] temp_result;
    reg [WIDTH-1:0] mask;
    reg [4:0] half_width;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cycle_count <= 0;
        end else begin
            state <= next_state;
            if (state != next_state)
                cycle_count <= 0;
            else
                cycle_count <= cycle_count + 1;
        end
    end

    // Logika nastêpnego stanu i operacje
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (start) begin
                    if (WIDTH <= BASE_THRESHOLD) begin
                        next_state = FINISH;
                    end else begin
                        next_state = SPLIT;
                    end
                end
            end
            
            SPLIT: begin
                next_state = CALC_LOW;
            end
            
            CALC_LOW: begin
                if (cycle_count >= 1) begin
                    next_state = CALC_HIGH;
                end
            end
            
            CALC_HIGH: begin
                if (cycle_count >= 1) begin
                    next_state = CALC_MID;
                end
            end
            
            CALC_MID: begin
                if (cycle_count >= 2) begin
                    next_state = COMBINE;
                end
            end
            
            COMBINE: begin
                next_state = FINISH;
            end
            
            FINISH: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

    // Operacje na danych
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 0;
            done <= 0;
            a_low <= 0;
            a_high <= 0;
            b_low <= 0;
            b_high <= 0;
            a_sum <= 0;
            b_sum <= 0;
            low_prod <= 0;
            high_prod <= 0;
            mid_prod <= 0;
            temp_result <= 0;
            half_width <= 0;
            mask <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start && WIDTH <= BASE_THRESHOLD) begin
                        result <= a * b;
                    end
                end
                
                SPLIT: begin
                    half_width <= WIDTH >> 1;
                    mask <= (1 << (WIDTH >> 1)) - 1;
                    a_low <= a & ((1 << (WIDTH >> 1)) - 1);
                    a_high <= a >> (WIDTH >> 1);
                    b_low <= b & ((1 << (WIDTH >> 1)) - 1);
                    b_high <= b >> (WIDTH >> 1);
                    a_sum <= (a & ((1 << (WIDTH >> 1)) - 1)) + (a >> (WIDTH >> 1));
                    b_sum <= (b & ((1 << (WIDTH >> 1)) - 1)) + (b >> (WIDTH >> 1));
                end
                
                CALC_LOW: begin
                    if (cycle_count == 0) begin
                        low_prod <= a_low * b_low;
                    end
                end
                
                CALC_HIGH: begin
                    if (cycle_count == 0) begin
                        high_prod <= a_high * b_high;
                    end
                end
                
                CALC_MID: begin
                    if (cycle_count == 0) begin
                        mid_prod <= a_sum * b_sum;
                    end else if (cycle_count == 1) begin
                        mid_prod <= mid_prod - low_prod - high_prod;
                    end
                end
                
                COMBINE: begin
                    temp_result <= (high_prod << (2 * half_width)) + 
                                  (mid_prod << half_width) + low_prod;
                end
                
                FINISH: begin
                    if (WIDTH <= BASE_THRESHOLD) begin
                        done <= 1;
                    end else begin
                        result <= temp_result;
                        done <= 1;
                    end
                end
            endcase
        end
    end

endmodule
