module hazard_detection_unit(
    input [31:0] IF_ID_IR,
    input [31:0] ID_EX_IR,
    input [2:0] ID_EX_type,
    input [2:0] EX_MEM_type,
    input TAKEN_BRANCH,
    
    output reg data_hazard,
    output reg control_hazard,
    output reg structural_hazard,
    output reg [1:0] hazard_type
);

    // Data Hazard Detection
    always @(*) begin
        // RAW Hazard
        data_hazard = ((ID_EX_IR[25:21] == IF_ID_IR[20:16]) || 
                      (ID_EX_IR[25:21] == IF_ID_IR[15:11])) &&
                      (ID_EX_type == 3'b010); // LOAD type
        
        // Control Hazard Detection
        control_hazard = TAKEN_BRANCH;
        
        // Structural Hazard Detection
        structural_hazard = (ID_EX_type == 3'b101) && (EX_MEM_type == 3'b101); // MUL operation
        
        // Combined hazard type
        hazard_type = {data_hazard, control_hazard};
    end

endmodule 