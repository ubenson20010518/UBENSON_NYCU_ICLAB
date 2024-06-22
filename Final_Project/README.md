Final Project 需要設計一個單核 CPU，相較於 Midterm Project，難度下降了一些，大概降了一顆星。這時候只剩下這個 project 了，寫起來比較輕鬆。幸運的是，我在準備研究所考試時讀過計組，因此對於 5 stage CPU 的架構並不陌生。不過，題目中有一個獨創的計算 4x4 行列式的指令，讓我覺得有些莫名其妙。基本的指令如 add、beq、lw、sw 等等，都只需要 3 到 5 個周期就可以完成，而這個 4x4 行列式的指令，在只用 3 個乘法器的情況下需要 26 個周期才能完成，這讓 pipeline 的實現非常困難。此外，還需要解決 hazard 的問題，挺麻煩的，所以我最後決定用 multicycle 的方法來完成。

這個 Final Project 要求我們從前端（設計、模擬）到後段（驗證、APR）的流程都跑過一遍，可以說是為這門課做了一個完美的總結。最後看到 A 出來的結果，我內心吶喊：“IT'S FINALLY OVER！”

![CHIP_APR_result](https://github.com/ubenson20010518/UBENSON_NYCU_ICLAB/assets/169625082/89530809-40ae-40ec-b387-5df1f0044421)
