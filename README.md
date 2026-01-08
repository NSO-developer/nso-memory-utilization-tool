# NSO Memory Utilization Measurement Tool
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/NSO-developer/nso-memory-utilization-tool)  

This is a tool to plot live RSS(Physical Memory Utilization) and Memory Allocated for JavaVM, PythonVMs and NSO Core for NSO. The purpose of this tool is to gain a higher level overview on how memory usage developed during various of incident. Eventually help out Customer to understand what is actually happend in their enviorment, CX on troubleshooting and BU on understanding and fix the problem. 

## Dependency
Gnuplot
```
apt-get install gnuplot
```

## Usage
Start measurment and input measurment time period. The diagram will generated afterwards in the graphs folder per process after the data collection
```
sh plot.sh [--verbose|-v] <Time Duration>
```


## Data Collection Source
* The Memory Allocated is taking the value in "writeable/private" from pmap command.(Suggestion from Magnus Thoang from Architect Support Team). This gives us the actually allocated memory for each process without shared memory. 
* The Physical Memory Used is from "VmRSS" in "/proc/$pid/status"
* "CommitLimit" from "/proc/meminfo" as memory allocation limit. 
* "Committed_AS" from "/proc/meminfo" for global allocated memory across the system. 
* "MemTotal" from "/proc/meminfo" as total amount of physical memory. 
* "MemFree" from "/proc/meminfo" for global physcal memory not used across the system. 


## Diagram Generated
All the diagram generated have a red warning line to indicate where is the CommitLimit except per VM PythonVM measurment. 
* Allocated Memory per Process vs Total Allocated Memory(Commited_AS) vs Physical Memory Usage(RSS)
    * NSO Core(ncs.smp)
    * JavaVM
    * PythonVM
        * per VM (Without CommitLimit Warning Line to increase visiblity)
        * Total for all the VMs
* Comparision between ncs.smp, JavaVM and PythonVM
    * Allocated Memory per Process vs Total Allocated Memory(Commited_AS) 
    * Total Allocated Memory(Commited_AS) vs Physical Memory Usage(RSS)

## Recommended CommitLimit
vm.overcommit_ratio can be calculated with the following formular
```
100(CommitLimit - SWAP) / (total_RAM - total_huge_TLB) = vm.overcommit_ratio
```
After data collection, the code will list the maximum Commited_AS + Buffer and recommend that as CommitLimit

```
Recommended CommitLimit: 15929672.0
Please add some buffer range based on the Recommended CommitLimit
```

In verbose mode one can also see the detail statistics
```
* COLUMN: 
  Mean:          1.59283e+07
  Std Dev:          926.0038
  Sample StdDev:   1069.2571
  Skewness:           0.3991
  Kurtosis:           1.5237
  Avg Dev:          855.0000
  Sum:           6.37133e+07
  Sum Sq.:       1.01485e+15

  Mean Err.:        463.0019
  Std Dev Err.:     327.3918
  Skewness Err.:      1.2247
  Kurtosis Err.:      2.4495

  Minimum:       1.59274e+07 [2]
  Maximum:       1.59297e+07 [0]
  Quartile:      1.59275e+07 
  Median:        1.59281e+07 
  Quartile:      1.59292e+07 
```

## Example Usage
Customer has configured the following settings to only allow 50 percent of total memory to get allocated in the system. 
```
# cat /proc/sys/vm/overcommit_ratio
50
# cat /proc/sys/vm/overcommit_memory
2
```
While NSO require much more than that during the startup. In the diagram below we can clearly see Memory allocated has cross the CommitLimit which triggeres a OOM Crash. 
![alt text](sample_diagram/ncs.smp/mem_ncs.smp.png "Memory Consumption for NSO Core")

The memory consumption diagram from ncs.smp shows the allocated memory has not significant spike during the time allocated memory spiked. This can show the issue is because some other process. For example a cron process lunched something exactly at that time. 

## Problems and Bugs?
Feels free to open issues or comment on the blog post.  
Pull Request are welcome if one wants to contribute. 

## Copyright and License Notice
```
Copyright (c) 2025 Cisco and/or its affiliates.

This software is licensed to you under the terms of the Cisco Sample
Code License, Version 1.1 (the "License"). You may obtain a copy of the
License at

               https://developer.cisco.com/docs/licenses

All use of the material herein must be in accordance with the terms of
the License. All rights not expressly granted by the License are
reserved. Unless required by applicable law or agreed to separately in
writing, software distributed under the License is distributed on an "AS
IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
or implied.
```
