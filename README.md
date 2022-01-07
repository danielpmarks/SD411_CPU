# SD-411
The SD-411 CPU is a five stage, fully pipelined core processor for RISC V assembly. The processor consists of an instruction fetch stage, a decode stage, an execute stage, a data memory stage, and finally a write-back stage. The motivation of this architecture design is to increase throughput of RISC V programs by executing multiple instructions simultaneously. On top of the five stage pipeline, this CPU is equipped with a data forwarding unit to handle data hazards, a branch prediction and flushing system to handle control hazards, and an advanced caching scheme to improve the performance of memory operations.


## SD-411 Datapath
Below is the datapath for the pipelined CPU. Each of the five stages is clearly shown by the separating "stage buffers" (i.e. IF/ID, EX/MEM, etc). There are also lines connecting the relevant signals from each stage to the forwarding unit, as well as the forwarding muxes into the ALU. Additionally, the branch predictor is connected to the PC register and takes input from the br_en signal in the execute stage for missed prediction handling. Finally, the data and instruction caches are connected to the relavent parts of the pipeline, with an arbiter between the two and the L2 cache/main memory.

![image](https://user-images.githubusercontent.com/35392192/148576392-4d3fe822-3862-4ca0-83d5-62ba3cb634eb.png)
