module forwarding_unit(
    input [31:0] ID_EX_IR,
    input [31:0] EX_MEM_IR,
    input [31:0] MEM_WB_IR,
    input [2:0] EX_MEM_type,
    input [2:0] MEM_WB_type,
    
    output reg [1:0] forward_A,
    output reg [1:0] forward_B
);

    // Forward A logic
    always @(*) begin
        if ((EX_MEM_type == 3'b000 || EX_MEM_type == 3'b001) &&
            (EX_MEM_IR[15:11] == ID_EX_IR[25:21]))
            forward_A = 2'b01;
        else if ((MEM_WB_type == 3'b000 || MEM_WB_type == 3'b001) &&
                 (MEM_WB_IR[15:11] == ID_EX_IR[25:21]))
            forward_A = 2'b10;
        else
            forward_A = 2'b00;
    end

    // Forward B logic
    always @(*) begin
        if ((EX_MEM_type == 3'b000 || EX_MEM_type == 3'b001) &&
            (EX_MEM_IR[15:11] == ID_EX_IR[20:16]))
            forward_B = 2'b01;
        else if ((MEM_WB_type == 3'b000 || MEM_WB_type == 3'b001) &&
                 (MEM_WB_IR[15:11] == ID_EX_IR[20:16]))
            forward_B = 2'b10;
        else
            forward_B = 2'b00;
    end

endmodule 