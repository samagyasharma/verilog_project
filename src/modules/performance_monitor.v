module performance_monitor(
    input clk,
    input rst,
    input pipeline_stall,
    input TAKEN_BRANCH,
    input [1:0] branch_prediction,
    input cache_hit,
    
    output reg [31:0] cycle_count,
    output reg [31:0] instruction_count,
    output reg [31:0] branch_mispredict_count,
    output reg [31:0] cache_miss_count
);

    // Performance monitoring logic
    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 0;
            instruction_count <= 0;
            branch_mispredict_count <= 0;
            cache_miss_count <= 0;
        end else begin
            // Update cycle count
            cycle_count <= cycle_count + 1;
            
            // Update instruction count if not stalled
            if (!pipeline_stall)
                instruction_count <= instruction_count + 1;
            
            // Update branch misprediction count
            if (TAKEN_BRANCH && branch_prediction[1] == 0)
                branch_mispredict_count <= branch_mispredict_count + 1;
            
            // Update cache miss count
            if (!cache_hit)
                cache_miss_count <= cache_miss_count + 1;
        end
    end

endmodule 