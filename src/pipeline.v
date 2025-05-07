module pipeline(
    input clk1,
    input clk2,
    input rst
);

    // Pipeline registers
    reg [31:0] PC, IF_ID_IR, IF_ID_NPC;
    reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
    reg [2:0] ID_EX_type, EX_MEM_type, MEM_WB_type;
    reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;
    reg EX_MEM_cond;
    reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;
    
    // Register Bank and Memory
    reg [31:0] Reg [0:31];  // Register Bank (32 * 32)
    reg [31:0] Mem [0:1023]; // 1024 x 32 memory
    
    // Control signals
    reg HALTED;
    reg TAKEN_BRANCH;
    reg pipeline_stall;
    
    // Module instantiations
    wire data_hazard, control_hazard, structural_hazard;
    wire [1:0] hazard_type;
    hazard_detection_unit hazard_unit(
        .IF_ID_IR(IF_ID_IR),
        .ID_EX_IR(ID_EX_IR),
        .ID_EX_type(ID_EX_type),
        .EX_MEM_type(EX_MEM_type),
        .TAKEN_BRANCH(TAKEN_BRANCH),
        .data_hazard(data_hazard),
        .control_hazard(control_hazard),
        .structural_hazard(structural_hazard),
        .hazard_type(hazard_type)
    );
    
    wire [1:0] forward_A, forward_B;
    forwarding_unit forward_unit(
        .ID_EX_IR(ID_EX_IR),
        .EX_MEM_IR(EX_MEM_IR),
        .MEM_WB_IR(MEM_WB_IR),
        .EX_MEM_type(EX_MEM_type),
        .MEM_WB_type(MEM_WB_type),
        .forward_A(forward_A),
        .forward_B(forward_B)
    );
    
    wire [1:0] branch_prediction;
    wire [63:0] branch_history;
    branch_prediction_unit branch_unit(
        .clk(clk1),
        .rst(rst),
        .TAKEN_BRANCH(TAKEN_BRANCH),
        .branch_prediction(branch_prediction),
        .branch_history(branch_history)
    );
    
    wire [31:0] cache_data_out;
    wire cache_hit;
    wire [31:0] cache_miss_count;
    cache_interface cache_unit(
        .clk(clk1),
        .rst(rst),
        .addr(EX_MEM_ALUOut),
        .read_write(EX_MEM_type == 3'b011), // STORE
        .write_data(EX_MEM_B),
        .mem_data(Mem[EX_MEM_ALUOut]),
        .cache_data_out(cache_data_out),
        .cache_hit(cache_hit),
        .cache_miss_count(cache_miss_count)
    );
    
    wire [31:0] cycle_count;
    wire [31:0] instruction_count;
    wire [31:0] branch_mispredict_count;
    performance_monitor perf_unit(
        .clk(clk1),
        .rst(rst),
        .pipeline_stall(pipeline_stall),
        .TAKEN_BRANCH(TAKEN_BRANCH),
        .branch_prediction(branch_prediction),
        .cache_hit(cache_hit),
        .cycle_count(cycle_count),
        .instruction_count(instruction_count),
        .branch_mispredict_count(branch_mispredict_count),
        .cache_miss_count(cache_miss_count)
    );
    
    wire [2:0] exception_type;
    wire [31:0] exception_pc;
    wire exception_active;
    wire pipeline_flush;
    exception_handler except_unit(
        .clk(clk1),
        .rst(rst),
        .ID_EX_IR(ID_EX_IR),
        .PC(PC),
        .exception_type(exception_type),
        .exception_pc(exception_pc),
        .exception_active(exception_active),
        .pipeline_flush(pipeline_flush)
    );

    // Pipeline stages implementation
    // ... (rest of the pipeline implementation remains the same)

endmodule 