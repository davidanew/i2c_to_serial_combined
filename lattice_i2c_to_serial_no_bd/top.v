module top
    (
        //input IOT_37A,
        //input IOT_36B,
        output IOT_39A
    );

    wire int_osc ;
    wire scl;
    wire sda;
    SB_HFOSC u_SB_HFOSC (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));
    // Clock divided by 2 because of timing problems at top frequency.
    defparam u_SB_HFOSC.CLKHF_DIV = "0b01"; // 24MHz
    // TODO: Other code will need to be updated to adapty to this frequency.

    // reset gen
    // Relying on ICE40 behavior of reseting all DFF on power on reset.
    reg [3:0] reset_counter;
    reg reset ;
    always @(posedge int_osc) begin
        if (reset_counter < 10) begin
        reset <= 1;
        reset_counter   <= reset_counter + 1;
        end else begin
        reset <= 0;
        end
    end

    i2c_example_gen i_i2c_example_gen
    (
        .clk(int_osc),
        .reset(reset),
        .scl(scl),
        .sda(sda)
    );

    top_generic i_top_generic
    (
        .clk(int_osc),
        .reset(reset),
        .scl(scl),
        .sda(sda),
        .tx(IOT_39A)
    );

endmodule