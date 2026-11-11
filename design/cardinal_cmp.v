////////////////////////////////////////////////////////////////////////////
// Cardinal 16-node chip multiprocessor - top-level module (EE577B Phase 3)
//
// DO NOT CHANGE THE MODULE NAME OR THE PORT LIST BELOW.
// The grading testbench instantiates cardinal_cmp by these exact port
// names: the memory interface of every node (N = 0..15), plus clk and
// reset. If the module name, a port name, a direction or a width differs,
// the elaboration step (ncelab) stops with an error.
//
// Integrate sixteen Cardinal processors, sixteen Cardinal NICs and your
// 4x4 Cardinal mesh of Project 1 (module gold_mesh_4x4 with the Project 1
// ports: replace the port-only template design/gold_mesh_4x4.v with your
// mesh and all of its submodules). Node N is the processor and
// the NIC connected to the mesh port nodeN_* at coordinate
// (x = N % 4, y = N / 4). The instruction and data memories are simulation
// models in the testbench; each node's memory ports come out of this
// module. The NIC signals (nodeN_addr_nic, nodeN_din_nic, nodeN_dout_nic,
// nodeN_nicEn, nodeN_nicWrEn) are internal wires between the processor and
// the NIC of each node; the testbench does not connect them.
//
// NIC <-> mesh connections for node N (the mesh ports are [63:0], the NIC
// ports [0:63]; connecting them is fine, bit 63 of the mesh is bit 0 of
// the NIC):
//   nic.net_so -> mesh.nodeN_pesi      nic.net_do -> mesh.nodeN_pedi
//   nic.net_ro <- mesh.nodeN_peri      nic.net_si <- mesh.nodeN_peso
//   nic.net_di <- mesh.nodeN_pedo      nic.net_ri -> mesh.nodeN_pero
//   nic.net_polarity <- mesh.nodeN_polarity
////////////////////////////////////////////////////////////////////////////
module cardinal_cmp (
    input         clk,
    input         reset,
    input  [0:31] node0_inst_in,
    input  [0:63] node0_d_in,
    output [0:31] node0_pc_out,
    output [0:63] node0_d_out,
    output [0:31] node0_addr_out,
    output        node0_memWrEn,
    output        node0_memEn,
    input  [0:31] node1_inst_in,
    input  [0:63] node1_d_in,
    output [0:31] node1_pc_out,
    output [0:63] node1_d_out,
    output [0:31] node1_addr_out,
    output        node1_memWrEn,
    output        node1_memEn,
    input  [0:31] node2_inst_in,
    input  [0:63] node2_d_in,
    output [0:31] node2_pc_out,
    output [0:63] node2_d_out,
    output [0:31] node2_addr_out,
    output        node2_memWrEn,
    output        node2_memEn,
    input  [0:31] node3_inst_in,
    input  [0:63] node3_d_in,
    output [0:31] node3_pc_out,
    output [0:63] node3_d_out,
    output [0:31] node3_addr_out,
    output        node3_memWrEn,
    output        node3_memEn,
    input  [0:31] node4_inst_in,
    input  [0:63] node4_d_in,
    output [0:31] node4_pc_out,
    output [0:63] node4_d_out,
    output [0:31] node4_addr_out,
    output        node4_memWrEn,
    output        node4_memEn,
    input  [0:31] node5_inst_in,
    input  [0:63] node5_d_in,
    output [0:31] node5_pc_out,
    output [0:63] node5_d_out,
    output [0:31] node5_addr_out,
    output        node5_memWrEn,
    output        node5_memEn,
    input  [0:31] node6_inst_in,
    input  [0:63] node6_d_in,
    output [0:31] node6_pc_out,
    output [0:63] node6_d_out,
    output [0:31] node6_addr_out,
    output        node6_memWrEn,
    output        node6_memEn,
    input  [0:31] node7_inst_in,
    input  [0:63] node7_d_in,
    output [0:31] node7_pc_out,
    output [0:63] node7_d_out,
    output [0:31] node7_addr_out,
    output        node7_memWrEn,
    output        node7_memEn,
    input  [0:31] node8_inst_in,
    input  [0:63] node8_d_in,
    output [0:31] node8_pc_out,
    output [0:63] node8_d_out,
    output [0:31] node8_addr_out,
    output        node8_memWrEn,
    output        node8_memEn,
    input  [0:31] node9_inst_in,
    input  [0:63] node9_d_in,
    output [0:31] node9_pc_out,
    output [0:63] node9_d_out,
    output [0:31] node9_addr_out,
    output        node9_memWrEn,
    output        node9_memEn,
    input  [0:31] node10_inst_in,
    input  [0:63] node10_d_in,
    output [0:31] node10_pc_out,
    output [0:63] node10_d_out,
    output [0:31] node10_addr_out,
    output        node10_memWrEn,
    output        node10_memEn,
    input  [0:31] node11_inst_in,
    input  [0:63] node11_d_in,
    output [0:31] node11_pc_out,
    output [0:63] node11_d_out,
    output [0:31] node11_addr_out,
    output        node11_memWrEn,
    output        node11_memEn,
    input  [0:31] node12_inst_in,
    input  [0:63] node12_d_in,
    output [0:31] node12_pc_out,
    output [0:63] node12_d_out,
    output [0:31] node12_addr_out,
    output        node12_memWrEn,
    output        node12_memEn,
    input  [0:31] node13_inst_in,
    input  [0:63] node13_d_in,
    output [0:31] node13_pc_out,
    output [0:63] node13_d_out,
    output [0:31] node13_addr_out,
    output        node13_memWrEn,
    output        node13_memEn,
    input  [0:31] node14_inst_in,
    input  [0:63] node14_d_in,
    output [0:31] node14_pc_out,
    output [0:63] node14_d_out,
    output [0:31] node14_addr_out,
    output        node14_memWrEn,
    output        node14_memEn,
    input  [0:31] node15_inst_in,
    input  [0:63] node15_d_in,
    output [0:31] node15_pc_out,
    output [0:63] node15_d_out,
    output [0:31] node15_addr_out,
    output        node15_memWrEn,
    output        node15_memEn
);

    // Processor <-> NIC and NIC <-> mesh wires (one set per node)
    // Node 0 (x = 0, y = 0)
    wire [0:1]  node0_addr_nic;
    wire [0:63] node0_din_nic, node0_dout_nic;
    wire        node0_nicEn, node0_nicWrEn;
    wire        node0_net_si, node0_net_ri, node0_net_so, node0_net_ro, node0_polarity;
    wire [0:63] node0_net_di, node0_net_do;
    // Node 1 (x = 1, y = 0)
    wire [0:1]  node1_addr_nic;
    wire [0:63] node1_din_nic, node1_dout_nic;
    wire        node1_nicEn, node1_nicWrEn;
    wire        node1_net_si, node1_net_ri, node1_net_so, node1_net_ro, node1_polarity;
    wire [0:63] node1_net_di, node1_net_do;
    // Node 2 (x = 2, y = 0)
    wire [0:1]  node2_addr_nic;
    wire [0:63] node2_din_nic, node2_dout_nic;
    wire        node2_nicEn, node2_nicWrEn;
    wire        node2_net_si, node2_net_ri, node2_net_so, node2_net_ro, node2_polarity;
    wire [0:63] node2_net_di, node2_net_do;
    // Node 3 (x = 3, y = 0)
    wire [0:1]  node3_addr_nic;
    wire [0:63] node3_din_nic, node3_dout_nic;
    wire        node3_nicEn, node3_nicWrEn;
    wire        node3_net_si, node3_net_ri, node3_net_so, node3_net_ro, node3_polarity;
    wire [0:63] node3_net_di, node3_net_do;
    // Node 4 (x = 0, y = 1)
    wire [0:1]  node4_addr_nic;
    wire [0:63] node4_din_nic, node4_dout_nic;
    wire        node4_nicEn, node4_nicWrEn;
    wire        node4_net_si, node4_net_ri, node4_net_so, node4_net_ro, node4_polarity;
    wire [0:63] node4_net_di, node4_net_do;
    // Node 5 (x = 1, y = 1)
    wire [0:1]  node5_addr_nic;
    wire [0:63] node5_din_nic, node5_dout_nic;
    wire        node5_nicEn, node5_nicWrEn;
    wire        node5_net_si, node5_net_ri, node5_net_so, node5_net_ro, node5_polarity;
    wire [0:63] node5_net_di, node5_net_do;
    // Node 6 (x = 2, y = 1)
    wire [0:1]  node6_addr_nic;
    wire [0:63] node6_din_nic, node6_dout_nic;
    wire        node6_nicEn, node6_nicWrEn;
    wire        node6_net_si, node6_net_ri, node6_net_so, node6_net_ro, node6_polarity;
    wire [0:63] node6_net_di, node6_net_do;
    // Node 7 (x = 3, y = 1)
    wire [0:1]  node7_addr_nic;
    wire [0:63] node7_din_nic, node7_dout_nic;
    wire        node7_nicEn, node7_nicWrEn;
    wire        node7_net_si, node7_net_ri, node7_net_so, node7_net_ro, node7_polarity;
    wire [0:63] node7_net_di, node7_net_do;
    // Node 8 (x = 0, y = 2)
    wire [0:1]  node8_addr_nic;
    wire [0:63] node8_din_nic, node8_dout_nic;
    wire        node8_nicEn, node8_nicWrEn;
    wire        node8_net_si, node8_net_ri, node8_net_so, node8_net_ro, node8_polarity;
    wire [0:63] node8_net_di, node8_net_do;
    // Node 9 (x = 1, y = 2)
    wire [0:1]  node9_addr_nic;
    wire [0:63] node9_din_nic, node9_dout_nic;
    wire        node9_nicEn, node9_nicWrEn;
    wire        node9_net_si, node9_net_ri, node9_net_so, node9_net_ro, node9_polarity;
    wire [0:63] node9_net_di, node9_net_do;
    // Node 10 (x = 2, y = 2)
    wire [0:1]  node10_addr_nic;
    wire [0:63] node10_din_nic, node10_dout_nic;
    wire        node10_nicEn, node10_nicWrEn;
    wire        node10_net_si, node10_net_ri, node10_net_so, node10_net_ro, node10_polarity;
    wire [0:63] node10_net_di, node10_net_do;
    // Node 11 (x = 3, y = 2)
    wire [0:1]  node11_addr_nic;
    wire [0:63] node11_din_nic, node11_dout_nic;
    wire        node11_nicEn, node11_nicWrEn;
    wire        node11_net_si, node11_net_ri, node11_net_so, node11_net_ro, node11_polarity;
    wire [0:63] node11_net_di, node11_net_do;
    // Node 12 (x = 0, y = 3)
    wire [0:1]  node12_addr_nic;
    wire [0:63] node12_din_nic, node12_dout_nic;
    wire        node12_nicEn, node12_nicWrEn;
    wire        node12_net_si, node12_net_ri, node12_net_so, node12_net_ro, node12_polarity;
    wire [0:63] node12_net_di, node12_net_do;
    // Node 13 (x = 1, y = 3)
    wire [0:1]  node13_addr_nic;
    wire [0:63] node13_din_nic, node13_dout_nic;
    wire        node13_nicEn, node13_nicWrEn;
    wire        node13_net_si, node13_net_ri, node13_net_so, node13_net_ro, node13_polarity;
    wire [0:63] node13_net_di, node13_net_do;
    // Node 14 (x = 2, y = 3)
    wire [0:1]  node14_addr_nic;
    wire [0:63] node14_din_nic, node14_dout_nic;
    wire        node14_nicEn, node14_nicWrEn;
    wire        node14_net_si, node14_net_ri, node14_net_so, node14_net_ro, node14_polarity;
    wire [0:63] node14_net_di, node14_net_do;
    // Node 15 (x = 3, y = 3)
    wire [0:1]  node15_addr_nic;
    wire [0:63] node15_din_nic, node15_dout_nic;
    wire        node15_nicEn, node15_nicWrEn;
    wire        node15_net_si, node15_net_ri, node15_net_so, node15_net_ro, node15_polarity;
    wire [0:63] node15_net_di, node15_net_do;

    // Each processor accesses its local NIC through the mapped register bus.
    // Each NIC then connects to the PE port of its matching mesh router.

    // Node 0: (0, 0)
    cardinal_cpu cpu0 (
        .clk(clk), .reset(reset),
        .inst_in(node0_inst_in), .d_in(node0_d_in),
        .pc_out(node0_pc_out), .addr_out(node0_addr_out),
        .memEn(node0_memEn), .memWrEn(node0_memWrEn), .d_out(node0_d_out),
        .addr_nic(node0_addr_nic), .din_nic(node0_din_nic),
        .dout_nic(node0_dout_nic), .nicEn(node0_nicEn),
        .nicWrEn(node0_nicWrEn)
    );
    cardinal_nic nic0 (
        .clk(clk), .reset(reset),
        .addr(node0_addr_nic), .d_in(node0_din_nic), .d_out(node0_dout_nic),
        .nicEn(node0_nicEn), .nicWrEn(node0_nicWrEn),
        .net_si(node0_net_si), .net_ri(node0_net_ri), .net_di(node0_net_di),
        .net_so(node0_net_so), .net_ro(node0_net_ro), .net_do(node0_net_do),
        .net_polarity(node0_polarity)
    );

    // Node 1: (1, 0)
    cardinal_cpu cpu1 (
        .clk(clk), .reset(reset),
        .inst_in(node1_inst_in), .d_in(node1_d_in),
        .pc_out(node1_pc_out), .addr_out(node1_addr_out),
        .memEn(node1_memEn), .memWrEn(node1_memWrEn), .d_out(node1_d_out),
        .addr_nic(node1_addr_nic), .din_nic(node1_din_nic),
        .dout_nic(node1_dout_nic), .nicEn(node1_nicEn),
        .nicWrEn(node1_nicWrEn)
    );
    cardinal_nic nic1 (
        .clk(clk), .reset(reset),
        .addr(node1_addr_nic), .d_in(node1_din_nic), .d_out(node1_dout_nic),
        .nicEn(node1_nicEn), .nicWrEn(node1_nicWrEn),
        .net_si(node1_net_si), .net_ri(node1_net_ri), .net_di(node1_net_di),
        .net_so(node1_net_so), .net_ro(node1_net_ro), .net_do(node1_net_do),
        .net_polarity(node1_polarity)
    );

    // Node 2: (2, 0)
    cardinal_cpu cpu2 (
        .clk(clk), .reset(reset),
        .inst_in(node2_inst_in), .d_in(node2_d_in),
        .pc_out(node2_pc_out), .addr_out(node2_addr_out),
        .memEn(node2_memEn), .memWrEn(node2_memWrEn), .d_out(node2_d_out),
        .addr_nic(node2_addr_nic), .din_nic(node2_din_nic),
        .dout_nic(node2_dout_nic), .nicEn(node2_nicEn),
        .nicWrEn(node2_nicWrEn)
    );
    cardinal_nic nic2 (
        .clk(clk), .reset(reset),
        .addr(node2_addr_nic), .d_in(node2_din_nic), .d_out(node2_dout_nic),
        .nicEn(node2_nicEn), .nicWrEn(node2_nicWrEn),
        .net_si(node2_net_si), .net_ri(node2_net_ri), .net_di(node2_net_di),
        .net_so(node2_net_so), .net_ro(node2_net_ro), .net_do(node2_net_do),
        .net_polarity(node2_polarity)
    );

    // Node 3: (3, 0)
    cardinal_cpu cpu3 (
        .clk(clk), .reset(reset),
        .inst_in(node3_inst_in), .d_in(node3_d_in),
        .pc_out(node3_pc_out), .addr_out(node3_addr_out),
        .memEn(node3_memEn), .memWrEn(node3_memWrEn), .d_out(node3_d_out),
        .addr_nic(node3_addr_nic), .din_nic(node3_din_nic),
        .dout_nic(node3_dout_nic), .nicEn(node3_nicEn),
        .nicWrEn(node3_nicWrEn)
    );
    cardinal_nic nic3 (
        .clk(clk), .reset(reset),
        .addr(node3_addr_nic), .d_in(node3_din_nic), .d_out(node3_dout_nic),
        .nicEn(node3_nicEn), .nicWrEn(node3_nicWrEn),
        .net_si(node3_net_si), .net_ri(node3_net_ri), .net_di(node3_net_di),
        .net_so(node3_net_so), .net_ro(node3_net_ro), .net_do(node3_net_do),
        .net_polarity(node3_polarity)
    );

    // Node 4: (0, 1)
    cardinal_cpu cpu4 (
        .clk(clk), .reset(reset),
        .inst_in(node4_inst_in), .d_in(node4_d_in),
        .pc_out(node4_pc_out), .addr_out(node4_addr_out),
        .memEn(node4_memEn), .memWrEn(node4_memWrEn), .d_out(node4_d_out),
        .addr_nic(node4_addr_nic), .din_nic(node4_din_nic),
        .dout_nic(node4_dout_nic), .nicEn(node4_nicEn),
        .nicWrEn(node4_nicWrEn)
    );
    cardinal_nic nic4 (
        .clk(clk), .reset(reset),
        .addr(node4_addr_nic), .d_in(node4_din_nic), .d_out(node4_dout_nic),
        .nicEn(node4_nicEn), .nicWrEn(node4_nicWrEn),
        .net_si(node4_net_si), .net_ri(node4_net_ri), .net_di(node4_net_di),
        .net_so(node4_net_so), .net_ro(node4_net_ro), .net_do(node4_net_do),
        .net_polarity(node4_polarity)
    );

    // Node 5: (1, 1)
    cardinal_cpu cpu5 (
        .clk(clk), .reset(reset),
        .inst_in(node5_inst_in), .d_in(node5_d_in),
        .pc_out(node5_pc_out), .addr_out(node5_addr_out),
        .memEn(node5_memEn), .memWrEn(node5_memWrEn), .d_out(node5_d_out),
        .addr_nic(node5_addr_nic), .din_nic(node5_din_nic),
        .dout_nic(node5_dout_nic), .nicEn(node5_nicEn),
        .nicWrEn(node5_nicWrEn)
    );
    cardinal_nic nic5 (
        .clk(clk), .reset(reset),
        .addr(node5_addr_nic), .d_in(node5_din_nic), .d_out(node5_dout_nic),
        .nicEn(node5_nicEn), .nicWrEn(node5_nicWrEn),
        .net_si(node5_net_si), .net_ri(node5_net_ri), .net_di(node5_net_di),
        .net_so(node5_net_so), .net_ro(node5_net_ro), .net_do(node5_net_do),
        .net_polarity(node5_polarity)
    );

    // Node 6: (2, 1)
    cardinal_cpu cpu6 (
        .clk(clk), .reset(reset),
        .inst_in(node6_inst_in), .d_in(node6_d_in),
        .pc_out(node6_pc_out), .addr_out(node6_addr_out),
        .memEn(node6_memEn), .memWrEn(node6_memWrEn), .d_out(node6_d_out),
        .addr_nic(node6_addr_nic), .din_nic(node6_din_nic),
        .dout_nic(node6_dout_nic), .nicEn(node6_nicEn),
        .nicWrEn(node6_nicWrEn)
    );
    cardinal_nic nic6 (
        .clk(clk), .reset(reset),
        .addr(node6_addr_nic), .d_in(node6_din_nic), .d_out(node6_dout_nic),
        .nicEn(node6_nicEn), .nicWrEn(node6_nicWrEn),
        .net_si(node6_net_si), .net_ri(node6_net_ri), .net_di(node6_net_di),
        .net_so(node6_net_so), .net_ro(node6_net_ro), .net_do(node6_net_do),
        .net_polarity(node6_polarity)
    );

    // Node 7: (3, 1)
    cardinal_cpu cpu7 (
        .clk(clk), .reset(reset),
        .inst_in(node7_inst_in), .d_in(node7_d_in),
        .pc_out(node7_pc_out), .addr_out(node7_addr_out),
        .memEn(node7_memEn), .memWrEn(node7_memWrEn), .d_out(node7_d_out),
        .addr_nic(node7_addr_nic), .din_nic(node7_din_nic),
        .dout_nic(node7_dout_nic), .nicEn(node7_nicEn),
        .nicWrEn(node7_nicWrEn)
    );
    cardinal_nic nic7 (
        .clk(clk), .reset(reset),
        .addr(node7_addr_nic), .d_in(node7_din_nic), .d_out(node7_dout_nic),
        .nicEn(node7_nicEn), .nicWrEn(node7_nicWrEn),
        .net_si(node7_net_si), .net_ri(node7_net_ri), .net_di(node7_net_di),
        .net_so(node7_net_so), .net_ro(node7_net_ro), .net_do(node7_net_do),
        .net_polarity(node7_polarity)
    );

    // Node 8: (0, 2)
    cardinal_cpu cpu8 (
        .clk(clk), .reset(reset),
        .inst_in(node8_inst_in), .d_in(node8_d_in),
        .pc_out(node8_pc_out), .addr_out(node8_addr_out),
        .memEn(node8_memEn), .memWrEn(node8_memWrEn), .d_out(node8_d_out),
        .addr_nic(node8_addr_nic), .din_nic(node8_din_nic),
        .dout_nic(node8_dout_nic), .nicEn(node8_nicEn),
        .nicWrEn(node8_nicWrEn)
    );
    cardinal_nic nic8 (
        .clk(clk), .reset(reset),
        .addr(node8_addr_nic), .d_in(node8_din_nic), .d_out(node8_dout_nic),
        .nicEn(node8_nicEn), .nicWrEn(node8_nicWrEn),
        .net_si(node8_net_si), .net_ri(node8_net_ri), .net_di(node8_net_di),
        .net_so(node8_net_so), .net_ro(node8_net_ro), .net_do(node8_net_do),
        .net_polarity(node8_polarity)
    );

    // Node 9: (1, 2)
    cardinal_cpu cpu9 (
        .clk(clk), .reset(reset),
        .inst_in(node9_inst_in), .d_in(node9_d_in),
        .pc_out(node9_pc_out), .addr_out(node9_addr_out),
        .memEn(node9_memEn), .memWrEn(node9_memWrEn), .d_out(node9_d_out),
        .addr_nic(node9_addr_nic), .din_nic(node9_din_nic),
        .dout_nic(node9_dout_nic), .nicEn(node9_nicEn),
        .nicWrEn(node9_nicWrEn)
    );
    cardinal_nic nic9 (
        .clk(clk), .reset(reset),
        .addr(node9_addr_nic), .d_in(node9_din_nic), .d_out(node9_dout_nic),
        .nicEn(node9_nicEn), .nicWrEn(node9_nicWrEn),
        .net_si(node9_net_si), .net_ri(node9_net_ri), .net_di(node9_net_di),
        .net_so(node9_net_so), .net_ro(node9_net_ro), .net_do(node9_net_do),
        .net_polarity(node9_polarity)
    );

    // Node 10: (2, 2)
    cardinal_cpu cpu10 (
        .clk(clk), .reset(reset),
        .inst_in(node10_inst_in), .d_in(node10_d_in),
        .pc_out(node10_pc_out), .addr_out(node10_addr_out),
        .memEn(node10_memEn), .memWrEn(node10_memWrEn), .d_out(node10_d_out),
        .addr_nic(node10_addr_nic), .din_nic(node10_din_nic),
        .dout_nic(node10_dout_nic), .nicEn(node10_nicEn),
        .nicWrEn(node10_nicWrEn)
    );
    cardinal_nic nic10 (
        .clk(clk), .reset(reset),
        .addr(node10_addr_nic), .d_in(node10_din_nic), .d_out(node10_dout_nic),
        .nicEn(node10_nicEn), .nicWrEn(node10_nicWrEn),
        .net_si(node10_net_si), .net_ri(node10_net_ri), .net_di(node10_net_di),
        .net_so(node10_net_so), .net_ro(node10_net_ro), .net_do(node10_net_do),
        .net_polarity(node10_polarity)
    );

    // Node 11: (3, 2)
    cardinal_cpu cpu11 (
        .clk(clk), .reset(reset),
        .inst_in(node11_inst_in), .d_in(node11_d_in),
        .pc_out(node11_pc_out), .addr_out(node11_addr_out),
        .memEn(node11_memEn), .memWrEn(node11_memWrEn), .d_out(node11_d_out),
        .addr_nic(node11_addr_nic), .din_nic(node11_din_nic),
        .dout_nic(node11_dout_nic), .nicEn(node11_nicEn),
        .nicWrEn(node11_nicWrEn)
    );
    cardinal_nic nic11 (
        .clk(clk), .reset(reset),
        .addr(node11_addr_nic), .d_in(node11_din_nic), .d_out(node11_dout_nic),
        .nicEn(node11_nicEn), .nicWrEn(node11_nicWrEn),
        .net_si(node11_net_si), .net_ri(node11_net_ri), .net_di(node11_net_di),
        .net_so(node11_net_so), .net_ro(node11_net_ro), .net_do(node11_net_do),
        .net_polarity(node11_polarity)
    );

    // Node 12: (0, 3)
    cardinal_cpu cpu12 (
        .clk(clk), .reset(reset),
        .inst_in(node12_inst_in), .d_in(node12_d_in),
        .pc_out(node12_pc_out), .addr_out(node12_addr_out),
        .memEn(node12_memEn), .memWrEn(node12_memWrEn), .d_out(node12_d_out),
        .addr_nic(node12_addr_nic), .din_nic(node12_din_nic),
        .dout_nic(node12_dout_nic), .nicEn(node12_nicEn),
        .nicWrEn(node12_nicWrEn)
    );
    cardinal_nic nic12 (
        .clk(clk), .reset(reset),
        .addr(node12_addr_nic), .d_in(node12_din_nic), .d_out(node12_dout_nic),
        .nicEn(node12_nicEn), .nicWrEn(node12_nicWrEn),
        .net_si(node12_net_si), .net_ri(node12_net_ri), .net_di(node12_net_di),
        .net_so(node12_net_so), .net_ro(node12_net_ro), .net_do(node12_net_do),
        .net_polarity(node12_polarity)
    );

    // Node 13: (1, 3)
    cardinal_cpu cpu13 (
        .clk(clk), .reset(reset),
        .inst_in(node13_inst_in), .d_in(node13_d_in),
        .pc_out(node13_pc_out), .addr_out(node13_addr_out),
        .memEn(node13_memEn), .memWrEn(node13_memWrEn), .d_out(node13_d_out),
        .addr_nic(node13_addr_nic), .din_nic(node13_din_nic),
        .dout_nic(node13_dout_nic), .nicEn(node13_nicEn),
        .nicWrEn(node13_nicWrEn)
    );
    cardinal_nic nic13 (
        .clk(clk), .reset(reset),
        .addr(node13_addr_nic), .d_in(node13_din_nic), .d_out(node13_dout_nic),
        .nicEn(node13_nicEn), .nicWrEn(node13_nicWrEn),
        .net_si(node13_net_si), .net_ri(node13_net_ri), .net_di(node13_net_di),
        .net_so(node13_net_so), .net_ro(node13_net_ro), .net_do(node13_net_do),
        .net_polarity(node13_polarity)
    );

    // Node 14: (2, 3)
    cardinal_cpu cpu14 (
        .clk(clk), .reset(reset),
        .inst_in(node14_inst_in), .d_in(node14_d_in),
        .pc_out(node14_pc_out), .addr_out(node14_addr_out),
        .memEn(node14_memEn), .memWrEn(node14_memWrEn), .d_out(node14_d_out),
        .addr_nic(node14_addr_nic), .din_nic(node14_din_nic),
        .dout_nic(node14_dout_nic), .nicEn(node14_nicEn),
        .nicWrEn(node14_nicWrEn)
    );
    cardinal_nic nic14 (
        .clk(clk), .reset(reset),
        .addr(node14_addr_nic), .d_in(node14_din_nic), .d_out(node14_dout_nic),
        .nicEn(node14_nicEn), .nicWrEn(node14_nicWrEn),
        .net_si(node14_net_si), .net_ri(node14_net_ri), .net_di(node14_net_di),
        .net_so(node14_net_so), .net_ro(node14_net_ro), .net_do(node14_net_do),
        .net_polarity(node14_polarity)
    );

    // Node 15: (3, 3)
    cardinal_cpu cpu15 (
        .clk(clk), .reset(reset),
        .inst_in(node15_inst_in), .d_in(node15_d_in),
        .pc_out(node15_pc_out), .addr_out(node15_addr_out),
        .memEn(node15_memEn), .memWrEn(node15_memWrEn), .d_out(node15_d_out),
        .addr_nic(node15_addr_nic), .din_nic(node15_din_nic),
        .dout_nic(node15_dout_nic), .nicEn(node15_nicEn),
        .nicWrEn(node15_nicWrEn)
    );
    cardinal_nic nic15 (
        .clk(clk), .reset(reset),
        .addr(node15_addr_nic), .d_in(node15_din_nic), .d_out(node15_dout_nic),
        .nicEn(node15_nicEn), .nicWrEn(node15_nicWrEn),
        .net_si(node15_net_si), .net_ri(node15_net_ri), .net_di(node15_net_di),
        .net_so(node15_net_so), .net_ro(node15_net_ro), .net_do(node15_net_do),
        .net_polarity(node15_polarity)
    );

    // ---------------------------------------------------------------------
    // Project 1 mesh: NIC N connects to router N's PE port.
    // ---------------------------------------------------------------------
    gold_mesh_4x4 #(.PACKET_SIZE(64)) mesh (
        .clk(clk), .reset(reset),

        .node0_pesi(node0_net_so), .node0_peri(node0_net_ro), .node0_pedi(node0_net_do),
        .node0_peso(node0_net_si), .node0_pero(node0_net_ri), .node0_pedo(node0_net_di),
        .node0_polarity(node0_polarity),

        .node1_pesi(node1_net_so), .node1_peri(node1_net_ro), .node1_pedi(node1_net_do),
        .node1_peso(node1_net_si), .node1_pero(node1_net_ri), .node1_pedo(node1_net_di),
        .node1_polarity(node1_polarity),

        .node2_pesi(node2_net_so), .node2_peri(node2_net_ro), .node2_pedi(node2_net_do),
        .node2_peso(node2_net_si), .node2_pero(node2_net_ri), .node2_pedo(node2_net_di),
        .node2_polarity(node2_polarity),

        .node3_pesi(node3_net_so), .node3_peri(node3_net_ro), .node3_pedi(node3_net_do),
        .node3_peso(node3_net_si), .node3_pero(node3_net_ri), .node3_pedo(node3_net_di),
        .node3_polarity(node3_polarity),

        .node4_pesi(node4_net_so), .node4_peri(node4_net_ro), .node4_pedi(node4_net_do),
        .node4_peso(node4_net_si), .node4_pero(node4_net_ri), .node4_pedo(node4_net_di),
        .node4_polarity(node4_polarity),

        .node5_pesi(node5_net_so), .node5_peri(node5_net_ro), .node5_pedi(node5_net_do),
        .node5_peso(node5_net_si), .node5_pero(node5_net_ri), .node5_pedo(node5_net_di),
        .node5_polarity(node5_polarity),

        .node6_pesi(node6_net_so), .node6_peri(node6_net_ro), .node6_pedi(node6_net_do),
        .node6_peso(node6_net_si), .node6_pero(node6_net_ri), .node6_pedo(node6_net_di),
        .node6_polarity(node6_polarity),

        .node7_pesi(node7_net_so), .node7_peri(node7_net_ro), .node7_pedi(node7_net_do),
        .node7_peso(node7_net_si), .node7_pero(node7_net_ri), .node7_pedo(node7_net_di),
        .node7_polarity(node7_polarity),

        .node8_pesi(node8_net_so), .node8_peri(node8_net_ro), .node8_pedi(node8_net_do),
        .node8_peso(node8_net_si), .node8_pero(node8_net_ri), .node8_pedo(node8_net_di),
        .node8_polarity(node8_polarity),

        .node9_pesi(node9_net_so), .node9_peri(node9_net_ro), .node9_pedi(node9_net_do),
        .node9_peso(node9_net_si), .node9_pero(node9_net_ri), .node9_pedo(node9_net_di),
        .node9_polarity(node9_polarity),

        .node10_pesi(node10_net_so), .node10_peri(node10_net_ro), .node10_pedi(node10_net_do),
        .node10_peso(node10_net_si), .node10_pero(node10_net_ri), .node10_pedo(node10_net_di),
        .node10_polarity(node10_polarity),

        .node11_pesi(node11_net_so), .node11_peri(node11_net_ro), .node11_pedi(node11_net_do),
        .node11_peso(node11_net_si), .node11_pero(node11_net_ri), .node11_pedo(node11_net_di),
        .node11_polarity(node11_polarity),

        .node12_pesi(node12_net_so), .node12_peri(node12_net_ro), .node12_pedi(node12_net_do),
        .node12_peso(node12_net_si), .node12_pero(node12_net_ri), .node12_pedo(node12_net_di),
        .node12_polarity(node12_polarity),

        .node13_pesi(node13_net_so), .node13_peri(node13_net_ro), .node13_pedi(node13_net_do),
        .node13_peso(node13_net_si), .node13_pero(node13_net_ri), .node13_pedo(node13_net_di),
        .node13_polarity(node13_polarity),

        .node14_pesi(node14_net_so), .node14_peri(node14_net_ro), .node14_pedi(node14_net_do),
        .node14_peso(node14_net_si), .node14_pero(node14_net_ri), .node14_pedo(node14_net_di),
        .node14_polarity(node14_polarity),

        .node15_pesi(node15_net_so), .node15_peri(node15_net_ro), .node15_pedi(node15_net_do),
        .node15_peso(node15_net_si), .node15_pero(node15_net_ri), .node15_pedo(node15_net_di),
        .node15_polarity(node15_polarity)
    );

endmodule

