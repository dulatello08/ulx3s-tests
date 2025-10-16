module uart_helloworld(
    input        clk_25mhz,
    input logic [2:0] btn,
    output logic [7:0] led
);
    logic btn1_last, btn1_sync_0, btn1_sync_1;
    logic btn2_last, btn2_sync_0, btn2_sync_1;
    logic [15:0] counter;
    logic tick_ms1, btn1_repeating, btn2_repeating;
    logic [9:0] btn1_timer, btn2_timer, btn1_repeat_timer, btn2_repeat_timer;
    logic [7:0] counter_reg;
    initial begin
        btn1_last = 0;
        btn2_last = 0;
        btn1_timer = 0;
        btn2_timer = 0;
        btn1_repeat_timer = 0;
        btn2_repeat_timer = 0;
        btn1_repeating = 0;
        btn2_repeating = 0;
        counter = 0;
        tick_ms1 = 0;
    end
    assign led = counter_reg;
    always_ff @(posedge clk_25mhz) begin
        if (counter == 16'd24999) begin
            tick_ms1 <= 1;
            counter <= 0;
        end else begin
            counter <= counter + 1;
            tick_ms1 <= 0;
        end
        btn1_sync_0 <= btn[1];
        btn1_sync_1 <= btn1_sync_0;
        btn2_sync_0 <= btn[2];
        btn2_sync_1 <= btn2_sync_0;
        if (btn1_sync_1 && !btn1_last) begin
            counter_reg <= counter_reg + 1;
            btn1_timer <= 10'd0;
        end
        else if (btn2_sync_1 && !btn2_last) begin
            counter_reg <= counter_reg - 1;
            btn2_timer <= 10'd0;
        end
        if (btn1_sync_1 && tick_ms1) btn1_timer <= btn1_timer + 1;
        else if (btn2_sync_1 && tick_ms1) btn2_timer <= btn2_timer + 1;
        if (btn1_timer == 10'd300) btn1_repeating <= 1;
        else if (btn2_timer == 10'd300) btn2_repeating <= 1;
        if (btn1_repeating && tick_ms1) btn1_repeat_timer <= btn1_repeat_timer + 1;
        else if (btn2_repeating && tick_ms1) btn2_repeat_timer <= btn2_repeat_timer + 1;
        if (btn1_repeat_timer == 10'd50) begin
            btn1_repeat_timer <= 0;
            counter_reg <= counter_reg + 1;
        end else if (btn2_repeat_timer == 10'd50) begin
            btn2_repeat_timer <= 0;
            counter_reg <= counter_reg - 1;
        end
        if (!btn1_sync_1 && btn1_last) begin
            btn1_timer <= 0;
            btn1_repeating <= 0;
            btn1_repeat_timer <= 0;
        end else if (!btn2_sync_1 && btn2_last) begin
            btn2_timer <= 0;
            btn2_repeating <= 0;
            btn2_repeat_timer <= 0;
        end
        btn1_last <= btn1_sync_1;
        btn2_last <= btn2_sync_1;
    end
endmodule