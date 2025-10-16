module uart_helloworld(
    input        clk_25mhz,
    input logic [2:0] btn,
    output logic [7:0] led
);
    logic btn_last, btn_sync_0, btn_sync_1;
    initial begin
        btn_last = 0;
        led[7:0] = 0;
    end
    always_ff @(posedge clk_25mhz) begin
        btn_sync_0 <= btn[1];
        btn_sync_1 <= btn_sync_0;
        if(btn_sync_1 && !btn_last)
            led[0] <= ~led[0];
        btn_last <= btn_sync_1;
    end
    always_comb begin
        led[1] = btn[2];
        led[2] = btn[2];
        led[3] = btn[2];
        led[4] = btn[2];
    end
endmodule