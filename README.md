# SD-411
The SD-411 CPU is a five stage, fully pipelined core processor for RISC V assembly. The processor consists of an instruction fetch stage, a decode stage, an execute stage, a data memory stage, and finally a write-back stage. The motivation of this architecture design is to increase throughput of RISC V programs by executing multiple instructions simultaneously. On top of the five stage pipeline, this CPU is equipped with a data forwarding unit to handle data hazards, a branch prediction and flushing system to handle control hazards, and an advanced caching scheme to improve the performance of memory operations.


## SD-411 Datapath
Below is the datapath for the pipelined CPU. Each of the five stages is clearly shown by the separating "stage buffers" (i.e. IF/ID, EX/MEM, etc). There are also lines connecting the relevant signals from each stage to the forwarding unit, as well as the forwarding muxes into the ALU. Additionally, the branch predictor is connected to the PC register and takes input from the br_en signal in the execute stage for missed prediction handling. Finally, the data and instruction caches are connected to the relavent parts of the pipeline, with an arbiter between the two and the L2 cache/main memory.

![image](https://user-images.githubusercontent.com/35392192/148576392-4d3fe822-3862-4ca0-83d5-62ba3cb634eb.png)

## Advanced Features
This project included multiple "advanced features" to improve the performance of the pipelined CPU. These features either improved throughput or latency of instructions through a variety of techniques.

### Tournament Branch Predictor
The tournament branch predictor consists of both a local branch history table and a global branch history table. The local table takes the 6 least significant bits from the PC as input and hashes a branch prediction and a target PC which the PC loads as its next value. The global branch prediction takes 5 bits from the PC concatenated with 4 bits which store the outcome of the previous 4 branches as the hashing mechanism for the table. To choose the correct prediction between these two tables using a two bit predictor. This predictor functions similarly to a conventional two bit predictor, instead of using the states strongly-global, weakly-global, weakly-local, and strongly-local. As the predictor generates more missed predictions, it shifts to the states which use the other table. Overall, our branch predictor was able to correctly predict the correct branch PC 77% correctly on average in the three competition codes.

![image](https://user-images.githubusercontent.com/35392192/148578283-b650b248-c1d8-44ab-b6c8-3381fb8d6ebb.png)

Below is the performance metrics for three programs running on three different implementations of the tournament predictor. From this data, it is clear that more bits from the PC as well as more previous prediction bits improves performance substantially, but can come at a cost of the maximum frequency of the system.

![image](https://user-images.githubusercontent.com/35392192/148577307-f17712b7-1c2d-45bd-9b62-f6402787fd3a.png)

