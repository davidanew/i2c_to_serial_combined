`timescale 1ns / 1ps

// Sets/resets _filt reg's when reaching integral limits
module i2c_filter
    (
        input clk,
        input sda,
        input scl,
        input reset,
        output reg sda_filt,
        output reg scl_filt
    );
    localparam INTEGRAL_BITS = 4;
    localparam INTEGRAL_MAX = 15;
    reg[INTEGRAL_BITS-1 : 0] sda_integral;
    reg[INTEGRAL_BITS-1 : 0] scl_integral;   
    // Increment, decrement or leave SDA integrator
    always @(posedge clk)
    begin
        if (reset)
        begin
           sda_integral = INTEGRAL_MAX;
           sda_filt <= 1;
        end
        else if ((1 == sda) && ( sda_integral < INTEGRAL_MAX))
        begin
            sda_integral = sda_integral + 1;
            // Set output when max integral met
            if (INTEGRAL_MAX == sda_integral)
            begin
                sda_filt <= 1;
            end
        end
        else if ((0 == sda) && ( sda_integral > 0))
        begin
            sda_integral = sda_integral - 1;
            // clear output when min integral met
            if (0 == sda_integral)
            begin
                sda_filt <= 0;
            end
        end
    end
    // Increment, decrement or leave SCL integrator.
    // TODO: why is this in a seperate always block?
    always @(posedge clk)
    begin
        if (reset)
        begin
           scl_integral = INTEGRAL_MAX; 
           scl_filt <= 1;
        end
        else if ((1 == scl) && ( scl_integral < INTEGRAL_MAX))
        begin
            scl_integral = scl_integral + 1;
            if (INTEGRAL_MAX == scl_integral)
            begin
                scl_filt <= 1;
            end
        end
        else if ((0 == scl) && ( scl_integral > 0))
        begin
            scl_integral = scl_integral - 1;
            if (0 == scl_integral)
            begin
                scl_filt <= 0;
            end
        end
    end
endmodule
