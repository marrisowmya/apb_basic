module apb_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic                  PCLK,
    input  logic                  PRESETn,

    // Request interface
    input  logic                  start,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wdata,
    input  logic                  write,

    // Response from APB slave
    input  logic [DATA_WIDTH-1:0] PRDATA,
    input  logic                  PREADY,
    input  logic                  PSLVERR,

    // APB signals
    output logic [ADDR_WIDTH-1:0] PADDR,
    output logic                  PSEL,
    output logic                  PENABLE,
    output logic                  PWRITE,
    output logic [DATA_WIDTH-1:0] PWDATA,

    // Master result
    output logic [DATA_WIDTH-1:0] rdata,
    output logic                  done,
    output logic                  error
);

    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } state_t;

    state_t state, next_state;

    logic [ADDR_WIDTH-1:0] addr_reg;
    logic [DATA_WIDTH-1:0] wdata_reg;
    logic                  write_reg;


    //========================================================
    // State register
    //========================================================

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            state <= IDLE;
        else
            state <= next_state;
    end


    //========================================================
    // Next-state logic
    //========================================================

    always_comb begin

        next_state = state;

        case (state)

            IDLE: begin
                if (start)
                    next_state = SETUP;
            end

            SETUP: begin
                next_state = ACCESS;
            end

            ACCESS: begin
                if (PREADY)
                    next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end

        endcase
    end


    //========================================================
    // Capture transaction information
    //========================================================

    always_ff @(posedge PCLK or negedge PRESETn) begin

        if (!PRESETn) begin
            addr_reg  <= '0;
            wdata_reg <= '0;
            write_reg <= 1'b0;
        end

        else if ((state == IDLE) && start) begin
            addr_reg  <= addr;
            wdata_reg <= wdata;
            write_reg <= write;
        end

    end


    //========================================================
    // APB output signals
    //========================================================

    always_comb begin

        PADDR  = addr_reg;
        PWDATA = wdata_reg;
        PWRITE = write_reg;

        PSEL    = 1'b0;
        PENABLE = 1'b0;

        case (state)

            IDLE: begin
                PSEL    = 1'b0;
                PENABLE = 1'b0;
            end

            SETUP: begin
                PSEL    = 1'b1;
                PENABLE = 1'b0;
            end

            ACCESS: begin
                PSEL    = 1'b1;
                PENABLE = 1'b1;
            end

            default: begin
                PSEL    = 1'b0;
                PENABLE = 1'b0;
            end

        endcase

    end


    //========================================================
    // Capture read data
    //========================================================

    always_ff @(posedge PCLK or negedge PRESETn) begin

        if (!PRESETn) begin
            rdata <= '0;
        end

        else if ((state == ACCESS) &&
                 PREADY &&
                 !write_reg) begin

            rdata <= PRDATA;

        end

    end


    //========================================================
    // Transaction done
    //========================================================

    always_comb begin

        done = 1'b0;

        if ((state == ACCESS) && PREADY)
            done = 1'b1;

    end


    //========================================================
    // Error indication
    //========================================================

    always_comb begin

        error = 1'b0;

        if ((state == ACCESS) && PREADY)
            error = PSLVERR;

    end

endmodule

