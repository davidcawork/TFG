# Use cases xdp - p4

In this directory you will find different use cases, to be replicated with each technology ( xdp - p4 )  in order to know its limitations and advantages. All these use cases will be developed for the following environments:


- Ethernet (wired)
- Wireless


| Cases         | xdp | p4 |  p4-wireless | xdp-wireless    |
|---------------|-----|----|---| --- |
| case01 - Drop               | :white_check_mark:    | :white_check_mark:   |  :white_check_mark:  | :white_check_mark: |
| case02 - Pass               | :white_check_mark:    | :white_check_mark:   |  :white_check_mark:  | :white_check_mark: |
| case03 - Echo server        | :white_check_mark:    | :white_check_mark:   |  :white_check_mark:  | :white_check_mark: |
| case04 - Layer 3 forwarding | :white_check_mark:    | :white_check_mark:   |  :white_check_mark:  | :white_check_mark: |
| case05 - Broadcast          | :white_check_mark:    | :white_check_mark:   |  :white_check_mark:  | :white_check_mark: |


<br />
<br />


Additionally, we want to explore the feasibility of using the `mac802154_hwsim` module to replicate use cases and see what limitations and strengths P4 and XDP would have in this low-capacity wireless environment. 


<br />


| Scenario         | Feasibility |
|---------------|-----|
| Kernel module `mac802154_hwsim` to replicate a low capacity wireless medium. | It is not viable since this module follows another architecture, besides not offering Ethernet interfaces connected to the "emulated 802.15.4 card", so the different stages of parsing would have to be re-done in each case of use. |

*   For more information about the analysis of the module `mac802154_hwsim` check this [readme](./ieee802154/README.md).

