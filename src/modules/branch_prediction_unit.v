module branch_prediction_unit(
    input clk,
    input rst,
    input TAKEN_BRANCH,
    
    output reg [1:0] branch_prediction,
    output reg [63:0] branch_history
);

    // Branch prediction logic
    always @(posedge clk) begin
        if (rst) begin
            branch_history <= 0;
            branch_prediction <= 2'b00;
        end else begin
            // Update branch history
            branch_history <= {branch_history[62:0], TAKEN_BRANCH};
            
            // Simple 2-bit saturating counter
            if (TAKEN_BRANCH)
                branch_prediction <= (branch_prediction == 2'b11) ? 2'b11 : branch_prediction + 1;
            else
                branch_prediction <= (branch_prediction == 2'b00) ? 2'b00 : branch_prediction - 1;
        end
    end

endmodule 