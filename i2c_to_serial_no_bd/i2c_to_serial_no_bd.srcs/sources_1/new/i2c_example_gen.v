`timescale 1ns / 1ps

module i2c_example_gen
    #(
        // ICE40 has 48MHz clock
        //parameter CLK_FREQ = 48000000,
        // Clock had to be divided by 2
        parameter CLK_FREQ = 24000000,

        // Target I2C freq
        parameter SCL_FREQ = 400000
        // e.g for scl freq 400k and clk 48m there should be 120 clocks per scl
    )
    (
        input clk,
        input reset,
        output scl,
        output sda
    );
    // Number of clock cycles for one SCL clock cycle in the vectors
    localparam CLK_PER_SCL_CYCLE = 3;
    // Number of clock cycles for one vector  
    localparam CLK_CYCLES_PER_VECTOR = (CLK_FREQ / SCL_FREQ) / CLK_PER_SCL_CYCLE;
    
    reg [1:0] i2c_vector; // SCL is MSB
    assign scl = i2c_vector[1];
    assign sda = i2c_vector[0];
       
    reg [31:0] fast_counter; // Number of clock cycles per vector
    //reg [31:0] slow_counter; // Vector number
    // Reduced size so the outputs loops
    reg [15:0] slow_counter; // Vector number
    integer next_slow_counter;

    always @(posedge clk)
    begin
        if(reset)
        begin
            i2c_vector <= 2'b11;
            fast_counter <= 0;
            slow_counter <= 0;            
        end
        else
        begin
            if ((fast_counter + 1) == CLK_CYCLES_PER_VECTOR)
            begin
                next_slow_counter = slow_counter + 1;
                case(next_slow_counter)

//1 is high (not inverted)
//msb first

//https://www.analog.com/en/resources/technical-articles/i2c-primer-what-is-i2c-part-1.html
//https://www.analog.com/en/_/media/analog/en/landing-pages/technical-articles/i2c-primer-what-is-i2c-part-1-/36690.png?la=en&w=900&rev=b09418dbaac742b692bf4067eae2f346

                    //                      scl
                    //                       sda
                    // start
                    8'h01: i2c_vector <= 2'b10; // SDA fall
                    8'h02: i2c_vector <= 2'b00; // SCL fall
                    // 11001001
                    // bit 7 - 1
                    8'h03: i2c_vector <= 2'b01; // set data
                    8'h04: i2c_vector <= 2'b11; // SCL rise
                    8'h05: i2c_vector <= 2'b01; // SCL fall
                    // bit 6 - 1
                    8'h06: i2c_vector <= 2'b01; // set data
                    8'h07: i2c_vector <= 2'b11; // SCL rise
                    8'h08: i2c_vector <= 2'b01; // SCL fall
                    // bit 5 - 0
                    8'h09: i2c_vector <= 2'b00; // set data
                    8'h0a: i2c_vector <= 2'b10; // SCL rise
                    8'h0b: i2c_vector <= 2'b00; // SCL fall
                    // bit 4 - 0
                    8'h0c: i2c_vector <= 2'b00; // set data
                    8'h0d: i2c_vector <= 2'b10; // SCL rise
                    8'h0e: i2c_vector <= 2'b00; // SCL fall
                    // bit 3 - 1
                    8'h0f: i2c_vector <= 2'b01; // set data
                    8'h10: i2c_vector <= 2'b11; // SCL rise
                    8'h11: i2c_vector <= 2'b01; // SCL fall
                    // bit 2 - 0
                    8'h12: i2c_vector <= 2'b00; // set data
                    8'h13: i2c_vector <= 2'b10; // SCL rise
                    8'h14: i2c_vector <= 2'b00; // SCL fall
                    // bit 1 - 0
                    8'h15: i2c_vector <= 2'b00; // set data
                    8'h16: i2c_vector <= 2'b10; // SCL rise
                    8'h17: i2c_vector <= 2'b00; // SCL fall
                    // bit 0 - 1
                    8'h18: i2c_vector <= 2'b01; // set data
                    8'h19: i2c_vector <= 2'b11; // SCL rise
                    8'h1a: i2c_vector <= 2'b01; // SCL fall
                    // ack
                    8'h1b: i2c_vector <= 2'b00; // set data
                    8'h1c: i2c_vector <= 2'b10; // SCL rise
                    8'h1d: i2c_vector <= 2'b00; // SCL fall
                    // 10101010
                    // bit 7 - 1
                    8'h1e: i2c_vector <= 2'b01; // set data
                    8'h1f: i2c_vector <= 2'b11; // SCL rise
                    8'h20: i2c_vector <= 2'b01; // SCL fall
                    // bit 6 - 0
                    8'h21: i2c_vector <= 2'b00; // set data
                    8'h22: i2c_vector <= 2'b10; // SCL rise
                    8'h23: i2c_vector <= 2'b00; // SCL fall
                    // bit 5 - 1
                    8'h24: i2c_vector <= 2'b01; // set data
                    8'h25: i2c_vector <= 2'b11; // SCL rise
                    8'h26: i2c_vector <= 2'b01; // SCL fall
                    // bit 4 - 0
                    8'h27: i2c_vector <= 2'b00; // set data
                    8'h28: i2c_vector <= 2'b10; // SCL rise
                    8'h29: i2c_vector <= 2'b00; // SCL fall
                    // bit 3 - 1
                    8'h2a: i2c_vector <= 2'b01; // set data
                    8'h2b: i2c_vector <= 2'b11; // SCL rise
                    8'h2c: i2c_vector <= 2'b01; // SCL fall
                    // bit 2 - 0
                    8'h2d: i2c_vector <= 2'b00; // set data
                    8'h2e: i2c_vector <= 2'b10; // SCL rise
                    8'h2f: i2c_vector <= 2'b00; // SCL fall
                    // bit 1 - 1
                    8'h30: i2c_vector <= 2'b01; // set data
                    8'h31: i2c_vector <= 2'b11; // SCL rise
                    8'h32: i2c_vector <= 2'b01; // SCL fall
                    // bit 0 - 0
                    8'h33: i2c_vector <= 2'b00; // set data
                    8'h34: i2c_vector <= 2'b10; // SCL rise
                    8'h35: i2c_vector <= 2'b00; // SCL fall
                    // ack
                    8'h36: i2c_vector <= 2'b00; // set data
                    8'h37: i2c_vector <= 2'b10; // SCL rise
                    8'h38: i2c_vector <= 2'b00; // SCL fall
                    // 01010101
                    // bit 7 - 0
                    8'h39: i2c_vector <= 2'b00; // set data
                    8'h3a: i2c_vector <= 2'b10; // SCL rise
                    8'h3b: i2c_vector <= 2'b00; // SCL fall
                    // bit 6 - 1
                    8'h3c: i2c_vector <= 2'b01; // set data
                    8'h3d: i2c_vector <= 2'b11; // SCL rise
                    8'h3e: i2c_vector <= 2'b01; // SCL fall
                    // bit 5 - 0
                    8'h3f: i2c_vector <= 2'b00; // set data
                    8'h40: i2c_vector <= 2'b10; // SCL rise
                    8'h41: i2c_vector <= 2'b00; // SCL fall
                    // bit 4 - 1
                    8'h42: i2c_vector <= 2'b01; // set data
                    8'h43: i2c_vector <= 2'b11; // SCL rise
                    8'h44: i2c_vector <= 2'b01; // SCL fall
                    // bit 3 - 0
                    8'h45: i2c_vector <= 2'b00; // set data
                    8'h46: i2c_vector <= 2'b10; // SCL rise
                    8'h47: i2c_vector <= 2'b00; // SCL fall
                    // bit 2 - 1
                    8'h48: i2c_vector <= 2'b01; // set data
                    8'h49: i2c_vector <= 2'b11; // SCL rise
                    8'h4a: i2c_vector <= 2'b01; // SCL fall
                    // bit 1 - 0
                    8'h4b: i2c_vector <= 2'b00; // set data
                    8'h4c: i2c_vector <= 2'b10; // SCL rise
                    8'h4d: i2c_vector <= 2'b00; // SCL fall
                    // bit 0 - 1
                    8'h4e: i2c_vector <= 2'b01; // set data
                    8'h4f: i2c_vector <= 2'b11; // SCL rise
                    8'h50: i2c_vector <= 2'b01; // SCL fall
                    // nack
                    8'h51: i2c_vector <= 2'b01; // set data
                    8'h52: i2c_vector <= 2'b11; // SCL rise
                    8'h53: i2c_vector <= 2'b01; // SCL fall
                    // stop
                    8'h54: i2c_vector <= 2'b00; // Lows before stop
                    8'h55: i2c_vector <= 2'b10; // SCL rise
                    8'h56: i2c_vector <= 2'b11; // SDL rise
                endcase
                slow_counter <= next_slow_counter;
                fast_counter <= 0;
            end
            else
            begin
                fast_counter <= fast_counter + 1;
            end
        end
    end
endmodule
