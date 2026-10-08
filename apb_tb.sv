`timescale 1ns/1ps

module apb_tb;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;

    //========================================================
    // Clock and reset
    //========================================================

    logic PCLK;
    logic PRESETn;

    initial begin
        PCLK = 1'b0;
        forever #5 PCLK = ~PCLK;
    end


    //========================================================
    // Master request signals
    //========================================================

    logic                  start;
    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] wdata;
    logic                  write;


    //========================================================
    // APB signals
    //========================================================

    logic [ADDR_WIDTH-1:0] PADDR;
    logic                  PSEL;
    logic                  PENABLE;
    logic                  PWRITE;
    logic [DATA_WIDTH-1:0] PWDATA;

    logic [DATA_WIDTH-1:0] PRDATA;
    logic                  PREADY;
    logic                  PSLVERR;


    //========================================================
    // Master result
    //========================================================

    logic [DATA_WIDTH-1:0] rdata;
    logic                  done;
    logic                  error;


    //========================================================
    // Instantiate APB Master
    //========================================================

    apb_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) master_inst (

        .PCLK    (PCLK),
        .PRESETn (PRESETn),

        .start   (start),
        .addr    (addr),
        .wdata   (wdata),
        .write   (write),

        .PRDATA  (PRDATA),
        .PREADY  (PREADY),
        .PSLVERR (PSLVERR),

        .PADDR   (PADDR),
        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PWRITE  (PWRITE),
        .PWDATA  (PWDATA),

        .rdata   (rdata),
        .done    (done),
        .error   (error)
    );


    //========================================================
    // Instantiate APB Slave
    //========================================================

    apb_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) slave_inst (

        .PCLK    (PCLK),
        .PRESETn (PRESETn),

        .PADDR   (PADDR),
        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PWRITE  (PWRITE),
        .PWDATA  (PWDATA),

        .PRDATA  (PRDATA),
        .PREADY  (PREADY),
        .PSLVERR (PSLVERR)
    );


    //========================================================
    // Reset
    //========================================================

    initial begin

        PRESETn = 1'b0;

        start = 1'b0;
        addr  = '0;
        wdata = '0;
        write = 1'b0;

        #20;

        PRESETn = 1'b1;

    end


    //========================================================
    // APB WRITE TASK
    //========================================================

    task automatic apb_write(
        input logic [ADDR_WIDTH-1:0] address,
        input logic [DATA_WIDTH-1:0] data
    );

        begin

            @(posedge PCLK);

            addr  <= address;
            wdata <= data;
            write <= 1'b1;
            start <= 1'b1;

            @(posedge PCLK);

            start <= 1'b0;

            wait(done);

            @(posedge PCLK);

            if (error)
                $display("WRITE ERROR: Address = %h", address);

            else
                $display("WRITE SUCCESS: Address = %h Data = %h",
                         address, data);

        end

    endtask


    //========================================================
    // APB READ TASK
    //========================================================

    task automatic apb_read(
        input  logic [ADDR_WIDTH-1:0] address,
        output logic [DATA_WIDTH-1:0] data
    );

        begin

            @(posedge PCLK);

            addr  <= address;
            wdata <= '0;
            write <= 1'b0;
            start <= 1'b1;

            @(posedge PCLK);

            start <= 1'b0;

            wait(done);

            data = rdata;

            @(posedge PCLK);

            if (error)
                $display("READ ERROR: Address = %h", address);

            else
                $display("READ SUCCESS: Address = %h Data = %h",
                         address, data);

        end

    endtask


    //========================================================
    // Main test
    //========================================================

    logic [DATA_WIDTH-1:0] read_data;


    initial begin

        wait(PRESETn == 1'b1);

        // Small delay after reset
        @(posedge PCLK);


        //====================================================
        // TEST 1: WRITE DATA REGISTER
        //====================================================

        $display("\n----------------------------------");
        $display("TEST 1: WRITE DATA REGISTER");
        $display("----------------------------------");

        apb_write(
            32'h0000_0008,
            32'h0000_ABCD
        );


        //====================================================
        // TEST 2: READ DATA REGISTER
        //====================================================

        $display("\n----------------------------------");
        $display("TEST 2: READ DATA REGISTER");
        $display("----------------------------------");

        apb_read(
            32'h0000_0008,
            read_data
        );

        if (read_data == 32'h0000_ABCD)

            $display("PASS: Read data matches written data");

        else

            $display("FAIL: Expected ABCD, Got %h",
                     read_data);


        //====================================================
        // TEST 3: WRITE CTRL
        //====================================================

        $display("\n----------------------------------");
        $display("TEST 3: WRITE CTRL REGISTER");
        $display("----------------------------------");

        apb_write(
            32'h0000_0000,
            32'h1234_5678
        );


        //====================================================
        // TEST 4: READ CTRL
        //====================================================

        $display("\n----------------------------------");
        $display("TEST 4: READ CTRL REGISTER");
        $display("----------------------------------");

        apb_read(
            32'h0000_0000,
            read_data
        );

        if (read_data == 32'h1234_5678)

            $display("PASS: CTRL read successful");

        else

            $display("FAIL: CTRL data mismatch");


        //====================================================
        // TEST 5: READ STATUS
        //====================================================

        $display("\n----------------------------------");
        $display("TEST 5: READ STATUS REGISTER");
        $display("----------------------------------");

        apb_read(
            32'h0000_0004,
            read_data
        );


        //====================================================
        // TEST 6: INVALID ADDRESS
        //====================================================

        $display("\n----------------------------------");
        $display("TEST 6: INVALID ADDRESS");
        $display("----------------------------------");

        apb_read(
            32'h0000_0010,
            read_data
        );

        if (error)

            $display("PASS: Invalid address generated PSLVERR");

        else

            $display("FAIL: Invalid address did not generate error");


        //====================================================
        // Finish
        //====================================================

        $display("\n==================================");
        $display("       APB SIMULATION COMPLETE");
        $display("==================================\n");

        #20;

        $finish;

    end

endmodule
