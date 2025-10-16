// ULX3S Enigma UART (25 MHz, 9600 8N1) with power-on reset and pipelined stages.
// Decode online with: Enigma I, Rotors I-II-III (L-M-R), Reflector B, Rings AAA, Start AAA, no plugboard.

module uart_helloworld(
    input        clk_25mhz,
    output [7:0] led,
    output       wifi_gpio0,
    output       ftdi_rxd,   // FPGA TX -> FTDI RX
    input        ftdi_txd    // FTDI TX -> FPGA RX
);
    assign wifi_gpio0 = 1'b1;

    // ----------------------------------------------------------------
    // Status LEDs: led[0] toggles on TX, led[1] blips when RX byte seen
    // ----------------------------------------------------------------
    reg [7:0] led_r = 8'd0;  assign led = led_r;

    // ---------------- UART ----------------
    localparam integer CLK_HZ = 25_000_000;
    localparam integer BAUD   = 9600;

    wire       rx_valid;
    wire [7:0] rx_data;
    uart_rx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) U_RX (
        .clk(clk_25mhz), .rx_i(ftdi_txd), .valid(rx_valid), .data_o(rx_data)
    );

    reg        tx_start = 1'b0;
    wire       tx_busy;
    reg  [7:0] tx_data  = 8'h00;
    uart_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) U_TX (
        .clk(clk_25mhz), .tx_o(ftdi_rxd), .start(tx_start), .data_i(tx_data), .busy(tx_busy)
    );

    // ---------------- Power-on reset (few hundred cycles) ----------------
    reg [9:0] por_cnt = 10'd0;
    wire      rst = ~por_cnt[9];
    always @(posedge clk_25mhz) if (rst) por_cnt <= por_cnt + 10'd1;

    // ---------------- Helpers ----------------
    function [7:0] to_upper(input [7:0] c);
        begin to_upper = (c>="a" && c<="z") ? (c & 8'hDF) : c; end
    endfunction
    function is_letter(input [7:0] c);
        begin is_letter = ((c>="A"&&c<="Z")||(c>="a"&&c<="z")); end
    endfunction
    function [4:0] map_char(input [7:0] c); begin map_char = c - "A"; end endfunction
    function [7:0] unmap_char(input [4:0] x); begin unmap_char = "A" + x[4:0]; end endfunction
    function [4:0] add26(input [4:0] a, input [4:0] b);
        integer t; begin t = a + b; if (t>=26) t=t-26; add26 = t[4:0]; end
    endfunction
    function [4:0] sub26(input [4:0] a, input [4:0] b);
        integer t; begin t = a + 26 - b; if (t>=26) t=t-26; sub26 = t[4:0]; end
    endfunction

    // ---------------- Rotor / Reflector tables (0..25) ----------------
    function [4:0] ROT_I_FWD(input [4:0] i); begin case(i)
        0:ROT_I_FWD=4;  1:ROT_I_FWD=10; 2:ROT_I_FWD=12; 3:ROT_I_FWD=5;  4:ROT_I_FWD=11; 5:ROT_I_FWD=6;
        6:ROT_I_FWD=3;  7:ROT_I_FWD=16; 8:ROT_I_FWD=21; 9:ROT_I_FWD=25;10:ROT_I_FWD=13;11:ROT_I_FWD=19;
        12:ROT_I_FWD=14;13:ROT_I_FWD=22;14:ROT_I_FWD=24;15:ROT_I_FWD=7; 16:ROT_I_FWD=23;17:ROT_I_FWD=20;
        18:ROT_I_FWD=18;19:ROT_I_FWD=15;20:ROT_I_FWD=0; 21:ROT_I_FWD=8; 22:ROT_I_FWD=1; 23:ROT_I_FWD=17;
        24:ROT_I_FWD=2; 25:ROT_I_FWD=9; endcase end endfunction
    function [4:0] ROT_I_INV(input [4:0] i); begin case(i)
        0:ROT_I_INV=20; 1:ROT_I_INV=22; 2:ROT_I_INV=24; 3:ROT_I_INV=6;  4:ROT_I_INV=0;  5:ROT_I_INV=3;
        6:ROT_I_INV=5;  7:ROT_I_INV=15; 8:ROT_I_INV=21; 9:ROT_I_INV=25;10:ROT_I_INV=1; 11:ROT_I_INV=4;
        12:ROT_I_INV=2; 13:ROT_I_INV=10;14:ROT_I_INV=12;15:ROT_I_INV=19;16:ROT_I_INV=7; 17:ROT_I_INV=23;
        18:ROT_I_INV=18;19:ROT_I_INV=11;20:ROT_I_INV=8; 21:ROT_I_INV=13;22:ROT_I_INV=16;23:ROT_I_INV=14;
        24:ROT_I_INV=9; 25:ROT_I_INV=17; endcase end endfunction
    function [4:0] ROT_II_FWD(input [4:0] i); begin case(i)
        0:ROT_II_FWD=0;  1:ROT_II_FWD=9;  2:ROT_II_FWD=3;  3:ROT_II_FWD=10; 4:ROT_II_FWD=18; 5:ROT_II_FWD=8;
        6:ROT_II_FWD=17; 7:ROT_II_FWD=20; 8:ROT_II_FWD=23; 9:ROT_II_FWD=1; 10:ROT_II_FWD=11;11:ROT_II_FWD=7;
        12:ROT_II_FWD=22;13:ROT_II_FWD=19;14:ROT_II_FWD=12;15:ROT_II_FWD=2;16:ROT_II_FWD=16;17:ROT_II_FWD=6;
        18:ROT_II_FWD=25;19:ROT_II_FWD=13;20:ROT_II_FWD=15;21:ROT_II_FWD=24;22:ROT_II_FWD=5; 23:ROT_II_FWD=21;
        24:ROT_II_FWD=14;25:ROT_II_FWD=4; endcase end endfunction
    function [4:0] ROT_II_INV(input [4:0] i); begin case(i)
        0:ROT_II_INV=0;  1:ROT_II_INV=9;  2:ROT_II_INV=15; 3:ROT_II_INV=2;  4:ROT_II_INV=25; 5:ROT_II_INV=22;
        6:ROT_II_INV=17; 7:ROT_II_INV=11; 8:ROT_II_INV=5;  9:ROT_II_INV=1; 10:ROT_II_INV=3; 11:ROT_II_INV=10;
        12:ROT_II_INV=14;13:ROT_II_INV=19;14:ROT_II_INV=24;15:ROT_II_INV=20;16:ROT_II_INV=16;17:ROT_II_INV=6;
        18:ROT_II_INV=4; 19:ROT_II_INV=13;20:ROT_II_INV=7; 21:ROT_II_INV=23;22:ROT_II_INV=12;23:ROT_II_INV=8;
        24:ROT_II_INV=21;25:ROT_II_INV=18; endcase end endfunction
    function [4:0] ROT_III_FWD(input [4:0] i); begin case(i)
        0:ROT_III_FWD=1;  1:ROT_III_FWD=3;  2:ROT_III_FWD=5;  3:ROT_III_FWD=7;  4:ROT_III_FWD=9;  5:ROT_III_FWD=11;
        6:ROT_III_FWD=2;  7:ROT_III_FWD=15; 8:ROT_III_FWD=17; 9:ROT_III_FWD=19;10:ROT_III_FWD=23;11:ROT_III_FWD=21;
        12:ROT_III_FWD=25;13:ROT_III_FWD=13;14:ROT_III_FWD=12;15:ROT_III_FWD=24;16:ROT_III_FWD=4; 17:ROT_III_FWD=8;
        18:ROT_III_FWD=22;19:ROT_III_FWD=6; 20:ROT_III_FWD=0; 21:ROT_III_FWD=10;22:ROT_III_FWD=16;23:ROT_III_FWD=20;
        24:ROT_III_FWD=18;25:ROT_III_FWD=14; endcase end endfunction
    function [4:0] ROT_III_INV(input [4:0] i); begin case(i)
        0:ROT_III_INV=20; 1:ROT_III_INV=0;  2:ROT_III_INV=6;  3:ROT_III_INV=1;  4:ROT_III_INV=16; 5:ROT_III_INV=2;
        6:ROT_III_INV=19; 7:ROT_III_INV=3;  8:ROT_III_INV=17; 9:ROT_III_INV=4;  10:ROT_III_INV=21;11:ROT_III_INV=5;
        12:ROT_III_INV=14;13:ROT_III_INV=13;14:ROT_III_INV=25;15:ROT_III_INV=7; 16:ROT_III_INV=22;17:ROT_III_INV=8;
        18:ROT_III_INV=24;19:ROT_III_INV=9; 20:ROT_III_INV=23;21:ROT_III_INV=11;22:ROT_III_INV=18;23:ROT_III_INV=10;
        24:ROT_III_INV=15;25:ROT_III_INV=12; endcase end endfunction
    function [4:0] REFL_B(input [4:0] i); begin case(i)
        0:REFL_B=24;1:REFL_B=17;2:REFL_B=20;3:REFL_B=7; 4:REFL_B=16;5:REFL_B=18;6:REFL_B=11;7:REFL_B=3;
        8:REFL_B=15;9:REFL_B=23;10:REFL_B=13;11:REFL_B=6;12:REFL_B=14;13:REFL_B=10;14:REFL_B=12;15:REFL_B=8;
        16:REFL_B=4;17:REFL_B=1;18:REFL_B=5;19:REFL_B=25;20:REFL_B=2;21:REFL_B=22;22:REFL_B=21;23:REFL_B=9;
        24:REFL_B=0;25:REFL_B=19; endcase end endfunction

    // ---------------- Positions & pipeline ----------------
    reg [4:0] posL = 5'd0, posM = 5'd0, posR = 5'd0;
    localparam [4:0] NOTCH_I=5'd16, NOTCH_II=5'd4, NOTCH_III=5'd21;

    // FSM: 0=IDLE, 1=STEP, 2 R3F, 3 R2F, 4 R1F, 5 REFL, 6 R1R, 7 R2R, 8 R3R, 9 QUEUE
    reg [3:0] st = 4'd0;

    // staging
    reg [7:0] rx_buf = 8'h00, out_byte = 8'h00;
    reg       have_byte = 1'b0;
    reg [4:0] x = 5'd0, nL = 5'd0, nM = 5'd0, nR = 5'd0;
    reg       stepM = 1'b0, stepL = 1'b0;

    always @(posedge clk_25mhz) begin
        // TX scheduler
        tx_start <= 1'b0;
        if (have_byte && !tx_busy) begin
            tx_data  <= out_byte;
            tx_start <= 1'b1;
            led_r[0] <= ~led_r[0];
            have_byte<= 1'b0;
        end

        if (rst) begin
            st <= 4'd0;
            posL <= 5'd0; posM <= 5'd0; posR <= 5'd0;
            have_byte <= 1'b0;
        end else begin
            // show RX activity
            if (rx_valid) led_r[1] <= ~led_r[1];

            case (st)
                4'd0: begin // IDLE
                    if (rx_valid) begin
                        rx_buf <= rx_data;
                        if (!is_letter(rx_data)) begin
                            if (!have_byte) begin out_byte <= rx_data; have_byte <= 1'b1; end
                        end else begin
                            st <= 4'd1;
                        end
                    end
                end

                4'd1: begin // compute stepping and new positions, map input
                    stepM <= (posR == NOTCH_III) || (posM == NOTCH_II);
                    stepL <= (posM == NOTCH_II);
                    nR    <= add26(posR, 5'd1);
                    nM    <= ( ((posR == NOTCH_III) || (posM == NOTCH_II)) ? add26(posM,5'd1) : posM );
                    nL    <= ( (posM == NOTCH_II) ? add26(posL,5'd1) : posL );
                    x     <= map_char(to_upper(rx_buf));
                    st    <= 4'd2;
                end

                4'd2: begin x <= sub26( ROT_III_FWD( add26(x, nR) ), nR ); st <= 4'd3; end
                4'd3: begin x <= sub26( ROT_II_FWD ( add26(x, nM) ), nM ); st <= 4'd4; end
                4'd4: begin x <= sub26( ROT_I_FWD  ( add26(x, nL) ), nL ); st <= 4'd5; end
                4'd5: begin x <= REFL_B(x);                               st <= 4'd6; end
                4'd6: begin x <= sub26( ROT_I_INV  ( add26(x, nL) ), nL ); st <= 4'd7; end
                4'd7: begin x <= sub26( ROT_II_INV ( add26(x, nM) ), nM ); st <= 4'd8; end
                4'd8: begin x <= sub26( ROT_III_INV( add26(x, nR) ), nR ); st <= 4'd9; end

                4'd9: begin
                    if (!have_byte) begin
                        out_byte  <= unmap_char(x);
                        have_byte <= 1'b1;
                        // commit the new positions
                        posL <= nL; posM <= nM; posR <= nR;
                    end
                    st <= 4'd0;
                end

                default: st <= 4'd0;
            endcase
        end
    end
endmodule

// ---------------- UART TX (8N1) ----------------
module uart_tx #(parameter integer CLK_HZ=25_000_000,
                 parameter integer BAUD  =9_600) (
    input  wire clk,
    output reg  tx_o = 1'b1,   // idle high
    input  wire start,
    input  wire [7:0] data_i,
    output wire busy
);
    localparam integer BIT_TICKS = CLK_HZ / BAUD;   // ~2604
    reg [11:0] tick = 12'd0;
    reg [3:0]  bit_idx = 4'd0;
    reg [9:0]  shreg   = 10'h3FF;
    reg        active  = 1'b0;
    assign busy = active;

    always @(posedge clk) begin
        if (!active) begin
            if (start) begin
                shreg  <= {1'b1, data_i, 1'b0}; // stop, data, start
                bit_idx<= 4'd0; tick<=12'd0; active<=1'b1; tx_o<=1'b0; // start
            end
        end else begin
            tick <= tick + 12'd1;
            if (tick == BIT_TICKS-1) begin
                tick    <= 12'd0;
                bit_idx <= bit_idx + 4'd1;
                shreg   <= {1'b1, shreg[9:1]};
                tx_o    <= shreg[1];
                if (bit_idx == 4'd9) begin active<=1'b0; tx_o<=1'b1; end
            end
        end
    end
endmodule

// Robust UART RX: 9600 8N1 @ 25 MHz, per-bit countdown timer.
// Drop-in replacement for your existing uart_rx.
module uart_rx #(parameter integer CLK_HZ = 25_000_000,
                 parameter integer BAUD   = 9_600)(
    input  wire clk,
    input  wire rx_i,
    output reg  valid  = 1'b0,   // 1-cycle pulse when a byte is ready
    output reg  [7:0] data_o = 8'h00
);
    localparam integer BIT_TICKS      = CLK_HZ / BAUD;       // ~2604
    localparam integer HALF_BIT_TICKS = BIT_TICKS / 2;       // ~1302
    localparam integer CTR_W          = $clog2(BIT_TICKS);   // 12

    // 2-FF synchronizer (idle high)
    reg [1:0] rx_sync = 2'b11;
    always @(posedge clk) rx_sync <= {rx_sync[0], rx_i};
    wire rx = rx_sync[1];

    // State
    reg                    busy    = 1'b0;
    reg [CTR_W-1:0]        tick    = {CTR_W{1'b0}};  // per-bit countdown
    reg [3:0]              bit_idx = 4'd0;           // 0=start, 1..8=data, 9=stop
    reg [7:0]              shreg   = 8'h00;

    always @(posedge clk) begin
        valid <= 1'b0;

        if (!busy) begin
            // Wait for start bit (falling edge to 0)
            if (rx == 1'b0) begin
                busy    <= 1'b1;
                bit_idx <= 4'd0;                 // start bit stage
                tick    <= HALF_BIT_TICKS;       // sample mid-start
            end
        end else begin
            // Countdown within the current bit
            if (tick != 0) begin
                tick <= tick - 1'b1;
            end else begin
                // Time to sample
                if (bit_idx == 4'd0) begin
                    // Sample START bit mid-bit: must still be low
                    if (rx != 1'b0) begin
                        busy <= 1'b0;            // false start
                    end else begin
                        bit_idx <= 4'd1;         // move to data bit 0
                        tick    <= BIT_TICKS-1;
                    end
                end else if (bit_idx >= 4'd1 && bit_idx <= 4'd8) begin
                    // Sample DATA bits (LSB first)
                    shreg   <= {rx, shreg[7:1]};
                    bit_idx <= bit_idx + 1'b1;
                    tick    <= BIT_TICKS-1;
                end else if (bit_idx == 4'd9) begin
                    // STOP bit sample done -> byte ready
                    data_o <= shreg;
                    valid  <= 1'b1;
                    busy   <= 1'b0;
                end else begin
                    // Transition from last data bit to stop bit
                    bit_idx <= 4'd9;
                    tick    <= BIT_TICKS-1;
                end
            end
        end
    end
endmodule