// ============================================================
//  Module  : fsm_control
//  Project : K-Means Hardware Accelerator
//  Step    : 6a of 7
// ------------------------------------------------------------
//  Purpose : Controls the entire K-Means iteration sequence.
//            Generates all control signals for every module.
//
//  Python equivalent (your reference model):
//      for _ in range(MAX_ITER):          ← iter_count
//          for addr, p in enumerate(pixels): ← pixel_addr
//              cid = hardware_kmeans_rgb(p, centroids)
//          for i in range(K):
//              centroids[i] = np.mean(...)
//
//  5 States:
//  ┌─────────┬──────────────────────────────────────────────┐
//  │  IDLE   │ Wait for start=1                             │
//  ├─────────┼──────────────────────────────────────────────┤
//  │  LOAD   │ Assert rst to centroid_regs (load defaults)  │
//  │         │ Assert clear_en to accumulator               │
//  │         │ 1 clock only                                 │
//  ├─────────┼──────────────────────────────────────────────┤
//  │ COMPUTE │ Stream all 1024 pixels through pipeline      │
//  │         │ rd_en=1, accum_en=1 (with 1-cycle delay)     │
//  │         │ pixel_addr increments each cycle             │
//  │         │ When addr=1023 → go to UPDATE                │
//  ├─────────┼──────────────────────────────────────────────┤
//  │ UPDATE  │ Assert update_en → accumulator divides       │
//  │         │ Wait update_rdy → write new centroids        │
//  │         │ Write all 4 centroids to centroid_regs       │
//  │         │ Then clear accumulator for next iteration    │
//  ├─────────┼──────────────────────────────────────────────┤
//  │  DONE   │ Assert done=1                                │
//  │         │ If iter < MAX_ITER → loop back to COMPUTE    │
//  │         │ Else → stay DONE                             │
//  └─────────┴──────────────────────────────────────────────┘
//
//  Ports:
//      clk, rst        - system clock and reset
//      start           - begin clustering (from testbench)
//      update_rdy      - accumulator has new centroids ready
//      pixel_addr[9:0] - current pixel index (0-1023)
//      rd_en           - pixel_mem read enable
//      accum_en        - accumulator: add this pixel
//      clear_en        - accumulator: zero all banks
//      update_en       - accumulator: compute new centroids
//      wr_en           - centroid_regs: write enable
//      wr_sel[1:0]     - centroid_regs: which centroid to write
//      done            - clustering complete
//      state_out[2:0]  - current FSM state (for debug/testbench)
// ============================================================

`timescale 1ns / 1ps

module fsm_control (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,        // begin from testbench
    input  wire        update_rdy,   // accumulator done dividing

    // ── Pixel memory control ──
    output reg  [9:0]  pixel_addr,   // address to pixel_mem
    output reg         rd_en,        // pixel_mem read enable

    // ── Accumulator control ──
    output reg         accum_en,     // add pixel to bank
    output reg         clear_en,     // zero all banks
    output reg         update_en,    // compute new centroids

    // ── Centroid register file control ──
    output reg         wr_en,        // write new centroid
    output reg  [1:0]  wr_sel,       // which centroid (0-3)

    // ── Status ──
    output reg         done,         // clustering complete
    output reg  [2:0]  state_out     // current state for debug
);

    // ----------------------------------------------------------
    //  State encoding
    // ----------------------------------------------------------
    localparam IDLE    = 3'd0;
    localparam LOAD    = 3'd1;
    localparam COMPUTE = 3'd2;
    localparam UPDATE  = 3'd3;
    localparam DONE    = 3'd4;

    // ----------------------------------------------------------
    //  Parameters
    // ----------------------------------------------------------
    localparam MAX_PIXELS = 10'd1023;  // 0-1023 = 1024 pixels
    localparam MAX_ITER   = 4'd10;     // 10 K-Means iterations
                                        // (matches Python's range(20)
                                        //  but 10 is enough for 32×32)

    // ----------------------------------------------------------
    //  Internal registers
    // ----------------------------------------------------------
    reg [2:0]  state;
    reg [3:0]  iter_count;    // iteration counter (0-9)
    reg [1:0]  wr_phase;      // which centroid we are writing back
                               // during UPDATE (0,1,2,3)
    reg        accum_delay;   // 1-cycle pipeline delay for accum_en
                               // (pixel_mem has 1-cycle read latency)

    // ----------------------------------------------------------
    //  FSM - state register
    // ----------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            pixel_addr <= 0;
            iter_count <= 0;
            wr_phase   <= 0;
            accum_delay<= 0;
        end
        else begin
            case (state)

                // ── IDLE ──────────────────────────────────────
                IDLE: begin
                    if (start) begin
                        state      <= LOAD;
                        iter_count <= 0;
                    end
                end

                // ── LOAD ──────────────────────────────────────
                // One clock: clear accumulator, centroids hold
                // their reset defaults (set in centroid_regs rst)
                LOAD: begin
                    state      <= COMPUTE;
                    pixel_addr <= 0;
                    accum_delay<= 0;
                end

                // ── COMPUTE ───────────────────────────────────
                // Stream pixels 0→1023 through pipeline.
                // pixel_mem has 1 cycle latency so accum_en is
                // delayed by 1 cycle via accum_delay flag.
                COMPUTE: begin
                    if (pixel_addr < MAX_PIXELS) begin
                        pixel_addr  <= pixel_addr + 1;
                        accum_delay <= 1;
                    end else begin
                        // All pixels processed → go to UPDATE
                        pixel_addr  <= 0;
                        accum_delay <= 0;
                        state       <= UPDATE;
                        wr_phase    <= 0;
                    end
                end

                // ── UPDATE ────────────────────────────────────
                // Step 1: wait for update_rdy from accumulator
                // Step 2: write all 4 new centroids one per cycle
                // Step 3: clear accumulator, go back or done
                UPDATE: begin
                    if (update_rdy) begin
                        if (wr_phase < 2'd3) begin
                            wr_phase <= wr_phase + 1;
                        end else begin
                            // All 4 centroids written back
                            wr_phase   <= 0;
                            iter_count <= iter_count + 1;
                            if (iter_count >= MAX_ITER - 1) begin
                                state <= DONE;
                            end else begin
                                state <= COMPUTE;
                            end
                        end
                    end
                end

                // ── DONE ──────────────────────────────────────
                DONE: begin
                    // Stay here until reset
                    state <= DONE;
                end

            endcase
        end
    end

    // ----------------------------------------------------------
    //  Output logic - combinational decode of state
    // ----------------------------------------------------------
    always @(*) begin
        // defaults - all signals low unless explicitly set
        rd_en      = 0;
        accum_en   = 0;
        clear_en   = 0;
        update_en  = 0;
        wr_en      = 0;
        wr_sel     = 0;
        done       = 0;
        state_out  = state;

        case (state)

            IDLE: begin
                // nothing asserted - waiting for start
            end

            LOAD: begin
                clear_en = 1;   // zero accumulator banks
            end

            COMPUTE: begin
                rd_en    = 1;               // read pixel from memory
                accum_en = accum_delay;     // delayed 1 cycle for mem latency
            end

            UPDATE: begin
                // First cycle in UPDATE: trigger accumulator divide
                update_en = ~update_rdy;    // hold until rdy goes high
                // Once update_rdy=1: write centroids sequentially
                if (update_rdy) begin
                    wr_en  = 1;
                    wr_sel = wr_phase;
                end
            end

            DONE: begin
                done = 1;
            end

        endcase
    end

endmodule