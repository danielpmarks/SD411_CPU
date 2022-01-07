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

### Pipelined Caches
The pipelined caches improve performance by improving the fmax of our system. Since it was using the separate Bram module, we were able to implement a very big L1 cache with 4 ways and 32 sets per way without hurting the frequency too much, which significantly decreased the miss rates of both the instruction-cache and the data-cache. We only have 1-2% of misses in data-cache and 0.05% misses in instruction-cache when running competition tests. We faced challenges with this approach when updating the caches to spread over two stages of the pipeline. This changed the forwarding path for the memory stage, and required us to utilize bubble states to stall part of the CPU pipeline for load operations followed by instructions that generated a destination register dependency. Additionally, we had to implement a mechanism to handle cache stalls since the two cycle cache can only detect a hit on the next cycle from the request.

![image](https://user-images.githubusercontent.com/35392192/148580136-4dc16fb5-1912-4652-9667-1a8959d00400.png)

We found that the pipelined cache with BRAM modules greatly increased our maximum frequency, while increasing the size to four ways per set improved the hit rate for some programs. At the same time, the infrequency of bubble states indicates that implementing a pipelined cache does not lead to significantly more data hazards.

![image](https://user-images.githubusercontent.com/35392192/148580380-64ab9c34-e8be-4fc7-ac75-4898835aaa16.png)

### L2 Cache
The L2 cache provides more cache space to the CPU which significantly reduces the miss rate if L2 cache is fully used. However, if L1 is big enough, L2 will drag down the performance as L2 increases the time to fetch data from the main memory. In our design, adding L2 cache doesn’t provide significant speed up. Our theory is that since our L1 cache is big (as it is 4 ways), the extra cache space that L2 provides is excessive. L2 cache can be implemented by changing the ports of L1 cache; since L2 sends read data from main memory and receives writeback data from L1, the read/write data will all be 256 bits long. And since L2 only gets a written request when L1 needs to write back a whole block, we also don’t need the membyte_enble as we just need to write everything into a block. So for L2, we just replace 32 bits read/write data ports of L1 cache with physical write/read data and set the membyte_enble to 0xffffffff.

### Victim Cache
A victim cache is a technique that we used to reduce conflict misses. Whenever a higher level cache misses, the data being evicted is stored in the victim cache. Since these lines were evicted because of a higher level cache’s capacity limitation, there is a good chance of them being referenced again. It is much faster to retrieve it from the victim cache than from the main memory because it only takes one cycle for misses in higher-level cache and hits in the victim cache. 

Our victim cache is 16 way set associative and one set per way with a Pseudo LRU replacement policy. We didn’t implement it using pipelined although we should for the sake of reducing power and logic consumption. Pipelined cache is another level of complexity added to the already difficult victim cache design. 

There were three locations that we deemed reasonable to place the victim cache, that is, between L1 data-cache and arbiter (Since we tested that there were much more conflict misses from L1 data-cache as opposed to L1 instruction-cache), between arbiter and L2, or between L2 and main memory. For the ease of connecting, we end up with placing the victim cache between L2 and main memory, it is probably not the best place to put it since we have a very big L1 cache written with pipelined cache so we don’t have too many duplicated misses, therefore, victim cache performance is not the best. 

We tested the victim cache separately without pipelined cache and L2 cache and connected it between the given data-cache and arbiter. Using a counter, we record a total of 1413 misses in L1 data-cache and a total of 1011 hits in the victim cache. Out of the 1011 hits in victim cache, 419 of them were L1 write misses. It is a big performance boost since it shrinks the 30+ cycle penalties of read/write misses to 1 cycle penalties.

## Overall Performance and Power Usage
![image](https://user-images.githubusercontent.com/35392192/148581671-6e9e7203-b3f8-4ec2-97f0-379b69b362cf.png)


## Conclusion
We successfully implemented a five-stage pipelined CPU with tournament branch predictor and with that we build a complex cache structure including pipelined L1 instruction cache and L1 data cache, arbiter, L2 cache, and victim cache. It is very hard to test each component out separately and it is even harder to test the combination of different components but we finished it in the end. The concept of balancing frequency and logic cost are crucial in this assignment and we sadly didn’t reach our goal in that category. However, our project consists of an overall working CPU and cache system. We are proud of what we’ve accomplished.
