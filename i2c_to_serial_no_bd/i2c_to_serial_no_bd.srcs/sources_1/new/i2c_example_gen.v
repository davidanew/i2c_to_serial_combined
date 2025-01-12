`timescale 1ns / 1ps



//@clk rise
//scl
//  sda
//1 1
//1 0 start
//0 0
//0 d


//1 is high (not inverted)
//msb first


// reset could but default into register

//https://www.analog.com/en/resources/technical-articles/i2c-primer-what-is-i2c-part-1.html
//https://www.analog.com/en/_/media/analog/en/landing-pages/technical-articles/i2c-primer-what-is-i2c-part-1-/36690.png?la=en&w=900&rev=b09418dbaac742b692bf4067eae2f346


/*

If you're just using the array to pull out one value at a time, how about using a case statement? Granted, it's a long-winded way of doing it, but you could always write a script to write the RTL for you.

reg [7:0] value;
reg [7:0] i;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        i <= 8'd0;
    else
        i <= i + 1;
end

always @(*) begin
    case(i) 
        8'h00: value = 8'd0;
        8'h01: value = 8'd34;
        ...
    endcase
endcase

*/

//with the above the counter could also so the wait between

module i2c_example_gen
    (
        input clk,
        input reset,
        output scl,
        output sda
    );
    
    reg [1:0] i2c_vector; // SCL is LSB
    assign scl = i2c_vector[0];
    assign sda = i2c_vector[1];
       
    reg [31:0] fast_counter;
    reg [31:0] slow_counter;
    integer next_slow_counter;

    always @(posedge clk)
    begin
        if(reset)
        begin
            i2c_vector <= 2'b10;
        end
        else
        begin
            if (fast_counter == NUM_TICKS_PER_SLOW_COUNTER)
            begin
                next_slow_counter = slow_counter + 1;
                case(next_slow_counter)
                    8'h01: i2c_vector <= 2'b10;
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

/*

module shift_reg 
    #(
        parameter LEN = 8
    )
    (
        input clk, //Clock input
        input reset,  // Active high reset input
        input [LEN-1:0] load_val, 	// Load value
        input load_en, // Load enable
        output out_val
    );
     
    reg [LEN-1:0] ff;
    assign out_val = ff[LEN - 1];

    integer i = 0 ;

    always @ (posedge clk) 
    begin
        if (reset)
	    begin
	       ff <= 0;
	    end 
	    else
	    begin
	    	if (load_en)
	    	begin
	      	    ff <= load_val;
	      	end
	      	else
	      	begin
                for (i = 0; i < LEN; i = i + 1)
                begin
                    ff[i+1] <= ff[i];
                end
                ff[0] <= ff[LEN - 1];
            end
        end
    end
endmodule

*/


