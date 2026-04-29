// ============================================================
//  Module  : accumulator
//  Project : K-Means Hardware Accelerator
//  Step    : 4 of 7
// ------------------------------------------------------------
//  Purpose : Accumulates R, G, B pixel values per cluster and
//            computes new centroid means after a full pixel pass.
//
//  Python equivalent (your reference model):
//      for i in range(K):
//          if np.any(clusters == i):
//              centroids[i] = np.mean(pixels[clusters == i], axis=0)
//
//  Two operating phases (controlled by FSM signals):
//
//  ACCUMULATE (accum_en=1, update_en=0):
//      Called once per pixel during COMPUTE state.
//      cluster_id tells which cluster this pixel belongs to.
//      Adds pixel R,G,B to that cluster's sum bank.
//      Increments that cluster's pixel count.
//
//  UPDATE (accum_en=0, update_en=1):
//      Called after all pixels processed (end of COMPUTE state).
//      Divides each cluster's sum by its count.
//      Outputs new centroid R,G,B for each cluster.
//      FSM uses these to write back to centroid_regs.
//
//  CLEAR (clear_en=1):
//      Resets all sums and counts to zero.
//      Called at start of each iteration before pixel scan.
//
//  Bit-width analysis:
//      pixel channel : 8 bits  (0-255)
//      sum per cluster: up to 1024 pixels × 255 = 261120 → 18 bits
//      count         : up to 1024 pixels           → 11 bits
//      new centroid  : sum / count → 8 bits (fits back in register)
//
//  Ports:
//      clk, rst          - system clock and reset
//      accum_en          - high during COMPUTE: add this pixel
//      clear_en          - high at iteration start: zero all banks
//      update_rdy        - high when new centroids are valid
//      pixel_r/g/b [7:0] - current pixel from pixel_mem
//      cluster_id  [1:0] - winning cluster from min_finder
//      new_c0..c3_r/g/b  - computed new centroids (to centroid_regs)
// ============================================================

`timescale 1ns / 1ps

module accumulator (
    // ── Clock and reset ──
    input  wire        clk,
    input  wire        rst,

    // ── Control signals from FSM ──
    input  wire        accum_en,    // 1 = accumulate current pixel
    input  wire        clear_en,    // 1 = zero all banks (new iteration)
    input  wire        update_en,   // 1 = compute new centroids now

    // ── Pixel data from pixel_mem ──
    input  wire [7:0]  pixel_r,
    input  wire [7:0]  pixel_g,
    input  wire [7:0]  pixel_b,

    // ── Cluster assignment from min_finder ──
    input  wire [1:0]  cluster_id,

    // ── New centroid outputs → to centroid_regs ──
    output reg  [7:0]  new_c0_r, new_c0_g, new_c0_b,
    output reg  [7:0]  new_c1_r, new_c1_g, new_c1_b,
    output reg  [7:0]  new_c2_r, new_c2_g, new_c2_b,
    output reg  [7:0]  new_c3_r, new_c3_g, new_c3_b,

    // ── Valid flag: new centroids are ready to write back ──
    output reg         update_rdy
);

    // ----------------------------------------------------------
    //  Internal accumulation banks
    //  sum needs 18 bits: 1024 pixels × 255 max = 261120 < 2^18
    //  count needs 11 bits: max 1024 pixels < 2^11
    // ----------------------------------------------------------
    reg [17:0] sum_r [0:3];   // running R sum per cluster
    reg [17:0] sum_g [0:3];   // running G sum per cluster
    reg [17:0] sum_b [0:3];   // running B sum per cluster
    reg [10:0] count  [0:3];  // pixel count per cluster

    // ----------------------------------------------------------
    //  Accumulation phase
    //  On each clock where accum_en=1:
    //    Add pixel RGB to the bank indexed by cluster_id
    //    Increment that cluster's count
    //
    //  Python: sum_r[cid] += pixel[0]
    //          count[cid] += 1
    // ----------------------------------------------------------
    always @(posedge clk) begin
        if (rst || clear_en) begin
            // Zero all banks at reset or start of new iteration
            sum_r[0] <= 0; sum_g[0] <= 0; sum_b[0] <= 0; count[0] <= 0;
            sum_r[1] <= 0; sum_g[1] <= 0; sum_b[1] <= 0; count[1] <= 0;
            sum_r[2] <= 0; sum_g[2] <= 0; sum_b[2] <= 0; count[2] <= 0;
            sum_r[3] <= 0; sum_g[3] <= 0; sum_b[3] <= 0; count[3] <= 0;
            update_rdy <= 0;
        end
        else if (accum_en) begin
            // Add current pixel to its cluster's bank
            // cluster_id selects which bank (0,1,2,3)
            sum_r[cluster_id] <= sum_r[cluster_id] + {10'b0, pixel_r};
            sum_g[cluster_id] <= sum_g[cluster_id] + {10'b0, pixel_g};
            sum_b[cluster_id] <= sum_b[cluster_id] + {10'b0, pixel_b};
            count[cluster_id] <= count[cluster_id] + 1;
            update_rdy <= 0;
        end
        else if (update_en) begin
            // ── Compute new centroids: mean = sum / count ──
            // Guard against empty cluster (count=0) → keep 0
            // Python: centroids[i] = np.mean(pixels[clusters==i], axis=0)

            // Centroid 0
            if (count[0] > 0) begin
                new_c0_r <= sum_r[0] / count[0];
                new_c0_g <= sum_g[0] / count[0];
                new_c0_b <= sum_b[0] / count[0];
            end else begin
                new_c0_r <= 0; new_c0_g <= 0; new_c0_b <= 0;
            end

            // Centroid 1
            if (count[1] > 0) begin
                new_c1_r <= sum_r[1] / count[1];
                new_c1_g <= sum_g[1] / count[1];
                new_c1_b <= sum_b[1] / count[1];
            end else begin
                new_c1_r <= 0; new_c1_g <= 0; new_c1_b <= 0;
            end

            // Centroid 2
            if (count[2] > 0) begin
                new_c2_r <= sum_r[2] / count[2];
                new_c2_g <= sum_g[2] / count[2];
                new_c2_b <= sum_b[2] / count[2];
            end else begin
                new_c2_r <= 0; new_c2_g <= 0; new_c2_b <= 0;
            end

            // Centroid 3
            if (count[3] > 0) begin
                new_c3_r <= sum_r[3] / count[3];
                new_c3_g <= sum_g[3] / count[3];
                new_c3_b <= sum_b[3] / count[3];
            end else begin
                new_c3_r <= 0; new_c3_g <= 0; new_c3_b <= 0;
            end

            update_rdy <= 1;   // signal FSM that new centroids are ready
        end
        else begin
            update_rdy <= 0;
        end
    end

endmodule