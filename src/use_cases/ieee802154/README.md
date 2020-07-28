# Future work: Use case analysis on the standard `ieee802154`

Next, we want to make a brief analysis on the viability of exporting the use cases previously made in wired and wireless media under the low-capacity wireless standard. In this way we want to see the strengths and weaknesses of both XDP and P4 language to program the datapath of low capacity devices, in a scenario oriented to an IoT (Internet of Things) environment, with sensors which are quite limited in battery, range, memory and processing.


## Herramientas 

Where do we start? What userspace tools do we have to work with the `ieee802154` subsystem? It's a good question, I came up with this answer after seeing what dependencies Mininet-Wifi installs to interact with its IoT module. All the tools that have been useful in this analysis are shown in the following summary table: 

| Tool         | Explanation  | Link |  
|---------------|-----|----|
| `iwpan`              | Main tool for the configuration of the `ieee802154` subsystem, its interfaces and its radios. This tool is very similar to the `iw` tool designed to control the Wireless subsystem of the Linux Kernel.  | [Link to the source](https://github.com/linux-wpan/wpan-tools/tree/master/src) |
| ``wpan-hwsim``             | Tool to manage the `mac802154_hwsim` module, allowing to add or remove radios, as well as to add links between different radios through `netlink`.  | [Link to the source](https://github.com/linux-wpan/wpan-tools/tree/master/wpan-hwsim) |
| ``wpan-ping``        | Tool to ping directly with the stack `ieee802154`   | [Link to the source](https://github.com/linux-wpan/wpan-tools/tree/master/wpan-ping) |




## Arquitectura

Here is a diagram of the architecture of the `ieee802154` stack, obtained from the official development repository of the tools and modules associated with the `ieee802154` standard of the linux kernel. This scheme has been very useful to compare its different blocks with the module `mac80211_hwsim` which we use to emulate wireless networks under the `ieee802.11` standard.



```text 

              .-------------------------------------------------------------------------------------------------------.
              |                                               Userspace                                               |
              '-----------------^----------------------------------^----------------------------------^---------------'
                                |                                  | socket                           |
                                |                                  v                                  |
                                |                  .------------------------------.                   |
                                | socket           |             IPv6             |                   |
                                |                  '------------------------------'                   | netlink
                                |                                         ^                           |
             .------------------|-----------------------------------------|---------------------------|-----------------.
             |                  |                             ieee802154  |                           |                 |
             |------------------|-----------------------------------------|---------------------------|-----------------|
             |                  v                                         v                           |                 |
             | .---------------------------------. .-----------------------------.                    |                 |
             | |        802.15.4 Sockets         | |      802.15.4 6LoWPAN       |                    |                 |
             | |---------------------------------| |-----------------------------|    .---------------v-------------.   |
             | |.--------------. .--------------.| |                             |    |          nl802154           |   |
             | ||    DGRAM     | |     RAW      || |  .-----------------------.  |    |-----------------------------|   |
             | || data payload | |  full frame  || |  |    Generic 6LoWPAN    |  |    |                             |   |
             | |'------^-------' '--------------'| |  | .-------------------. |  |    |  .----------. .-----------. |   |
             | |       |                | ^      | |  | |        NHC        | |  |    |  |   mlme   | | cmd, etc. | |   |
             | |       |                | |      | |  | '-------------------' |  |    |  |----------| |-----------| |   |
             | |       v                | |      | |  '-------------^---------'  |    |  | assoc.   | | panid     | |   |
             | | .------------.         | |      | |                |            |    |  | deassoc. | | channel   | |   |
             | | | dataframes |       tx| | rx   | |       .--------v--------.   |    |  | ...      | | ...       | |   |
             | | '------------'         | |      | |       |   dataframes    |   |    |  '----------' '-----------' |   |
             | |     |    ^             | |      | |       '-------^-|-------'   |    |       |             ^       |   |
             | '-----|----|-------------|-|------' '---------------|-|-----------'    |       |             |       |   |
             |       |    |             | |-----------.            | |                |       |             |       |   |
             |    tx |    |rx           '-------|     |            | |                '-------|-------------|-------'   |
             |       |    |---------------------|-----|------.   rx| |tx                      |             |           |
             |       v                          |     |      |     | |                        |             |           |
             | .------------------------------. |     |      |     | |                        |             |           |
             | |        frame creation        | |     |      |     | |                        |             |           |
             | |------------------------------| |     |      |     | |                        |             |           |
             | | generic functions            <-|-----|--------------'                        |             |           |
             | | - wpan_dev callbacks struct? | |     |      |     |                          |             |           |
             | |   instead dev_hard_header    | |     |      |     |   .-------------------.  |             |           |
         ******|   different HardMAC/SoftMAC  | |     |      |     |   |  mlme operations  |  |             |           |
         *   | | - data                       | |     |      |     |   |                   |<-'             |           |
         *   | | --- for mlme ---             | |     |      |     |   '-------------------'                |           |
         *   | | - beacon                     | |     |      |     |                |                       |           |
         *   | | - cmd                        | |     |      |     |                |                       |           |
         *   | | - ack? -> (slotted mode)     | |     |      |     |                |                       |           |
         *   | '--------------|---------------' |.-------------------------.        |                       |           |
         *   |                v                 ||  802.15.4 packet_layer  |        |             ----------'           |
         *   |       .----------------.         |'-------------------------'        |             |                     |
         *   |       | dev_queue_xmit |<--------'            ^                      |             |                     |
         *   |       '----------------'                      |                      |             |                     |
         *   '----------------|------------------------------|----------------------|-------------|---------------------'
         *              .-----|------------------------------|----------------------|-------------|------------.
         *              |     |                              | mac802154            |             |            |
         *              |-----|------------------------------|----------------------v-------------v------------|
         *              |     |                              |               .-------------..-----------.      |
         *******************************************************************>| do mlme ops || cfg802154 |      |
can use frame creation  |     |   .--------------------------|-------------. '-------------'|-----------|      |
                        |     |   | Frame parsing (call netif_receive_skb) |        |       | panid     |--------|
                        |     |   |----------------------------------------|        |       | shortaddr |      | |
                        |     |   | again check if 802.15.4 compliant      |        |       | etc.      |      | |
                        |     |   | different handling coordinator/node    |        |       '-----------'      | |
                        |     |   | set packet type (e.g. PACKET_HOST)     |        |                          | |
                        |     |   '---------------------^------------------'        |                          | |
                        |     |                         |                           | tx workqueue             | |
                        |     |ndo_start_xmit           |   |-----------------------'                          | |  .--------------.
                        |     |      .------------------|---|--------------------------------------.           | |  | e.g. tcpdump |
                        |     |      |                  |   |interface types                       |           | |  '--------------'
                        |     |      |------------------|---|--------------------------------------|           | |          ^
                        |     |      |                  |   |                                      |           | |          |
                        |     |      | .----------------|---v-----------.  .---------------------. |           | |          |
                        |     |      | |             frames             |  |       frames        | | mac sett. | |    .-----------.
                        |     '-------->    for rx, filtered by phy     |  | non-filtered by phy | |<------------|    | af_packet |
                        |            | |--------------------------------|  |---------------------| |           | |    '-----------'
                        |        .---| |                                |  |                     |----.        | |          ^
                        |        |   | | .-------------.  .-----------. |  | .-----------.       | |  |        | |          |
                        |        |   | | | coordinator |  |   node    | |  | |  monitor  |-----------------------|----------'
                        |        |   | | '------^------'  '-----^-----' |  | '-----------'       | |  |        | |
                        |        |   | '--------|---------------|-------'  '-------^-------------' |  |        | |
                        |        |   '----------|---------------|------------------|---------------'  |        | |
                        |        |              | rx/tx         | rx/tx            |rx/tx not possible(no AACK)| |
                        |        |              |               |         |--------|                  |        | |
                        '--------|--------------|---------------|---------|--------|------------------|--------' |
                                 |              v               v         |        |                  |          |
                                 |         ===================================     |                  |          |
                                 |               ^          ^          ^           |                  |          |
                                 |        .------|----------|----------|-----------|------.           |          |
    each interface type has      |        |      |          |  Frames  |           |      |           |     if AACK, ack frames are handled   
    different phy address filters|        |------|----------|----------|-----------|------|           |     by phy layer, not driver.         
    - sets mac settings on ifup  |        | .----v----..----v----..----v----. .---------. |  AACK ----|--->                                   
                                 |        | |  data   ||   cmd   || beacon  | |   ack   |------.      |     AACK disabled if promiscuous mode.
                                 |        | '----^----''----^----''----^----' '----^----' |    |      |     Then driver receives ack frames.  
                                 |        '------|----------|----------|-----------.------'    |      |          |
                                 |               |          |          |           .           |      |          |
                                 |               |          |          |           .           |      | sets promiscuous mode
                                 |        .------v----------v----------v-----------v------.    |      |          |
                                 |        |            802.15.4 SoftMAC Driver            |    |      |          |
                                 |        |-----------------------------------------------|    |      |          |
                                 |        | - supports always AACK handling               |    |      |          |
                                 -------->|   - ACK handling is done by phy (AACK)        |<-----------          |
                                          |   - on AACK, ACK frames doesn't reach driver  |<----------------------
                                          | - filtering (CRC, address, what phy can do..) |    |   phy settings
                                          '-----------------------------------------------'    |
                                                                  ^                            |
                                                                  |                            |
                                                                  v                            |
                                                      .----------------------.                 |
                                                      | 802.15.4 SoftMAC PHY |<----------------'
                                                      '----------------------'


```

After analyzing the architecture we have realized that this module, unlike the module `mac80211_hwsim` does not connect to the physical layer (phy) interfaces of the Ethernet type. Remember that when working with Wifi we wondered why a parsing of packets with 802.11 headers to 802.3 headers and vice versa was done in the Kernel. 


When generalizing to ethernet interfaces, the applications that work at the interface level are highly extrapolated, since they can be ported to different types of devices with different characteristics. It is true that it is lost in performance, since the package is glued up to three times in the Kernel and requires additional processing, but on the other hand it gains a lot of versatility. 


## Feasibility of use cases 

Taking into account that no Ethernet interfaces are used to communicate the physical layer with the upper layers, the use cases would not be immediately extrapolated, since in the parsing stages of all the use cases, an Ethernet header was parsed, both in XDP making memory accesses, and in p4 with the different parsing stages.


Therefore, instead of parsing the packets to Ethernet structures, we should parse them to structures that define the structure of the `ieee802154` header. Furthermore, searching in the [Kernel](https://elixir.bootlin.com/linux/latest/source/include/net/ieee802154_netdev.h) it has been found that this structure is already defined so it would only have to be used in XDP use cases, and in P4 use cases it would be necessary to declare the analogous structure and replace the Ethernet parser by the 802.15.4 headers parser. 

```C
struct ieee802154_hdr {
	struct ieee802154_hdr_fc fc;
	u8 seq;
	struct ieee802154_addr source;
	struct ieee802154_addr dest;
	struct ieee802154_sechdr sec;
};
```

However, it has been tried to add an XDP program to an interface generated by the `mac802154_hwsim` module, as it is understood that BVM2 should not be a problem for you to make use of the supplied interfaces, as it makes use of the [`pcap`](https://github.com/p4lang/behavioral-model/blob/master/src/BMI/bmi_interface.c) library to manage the sending and receiving of the packets. This library has been seen to make use of the `sockets` interface. Ultimately, it can be seen [here](https://github.com/the-tcpdump-group/libpcap/blob/master/pcap.c) at source, so it would not imply any incompatibility with the `ieee802154` subsystem architecture which supports the operability with different families of sockets.


### Load test with XDP

As mentioned above, the future viability of replicating the use cases on the `mac802154_hwsim` module depends on whether they are able to manage the load of XDP programs on their interfaces, since, as indicated with the BMV2, there would be no problem since it would go on the Kernel socket interface, so the architecture of the module itself contemplates it. 


Information was sought on whether the module was compatible with the loading of BPF programs, which is what an XDP program ultimately translates into, but no precise information was found, so it was decided to do a simple load test of ready-made XDP programs. As mentioned above, XDP programs cannot be directly extrapolated to the 802.15.4 subsystem, so we will use [`case01`](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case01) where only one datapath functionality was implemented using XDP return codes.



This way it will not be necessary to parse the `ieee802154` headers, and we will be able to see quickly if those interfaces associated to the radios with the 802.15.4 SoftMAC physical layer support the load of a generic XDP program. This test was first done directly by loading the module and creating the interfaces, but since Mininet-Wifi gives support to manage this module, it was thought that it would give some continuity to the development of the different use cases in this emulation tool.



From this point you can only continue if you have a version of the Kernel `v4.18.x` or higher, it is from this point that the module `mac802154_hwsim` is included. The first thing we'll do is go back to our Mininet-Wifi installation and install the dependencies needed to manage the `mac802154_hwsim` module (Spoiler: This will be the tools mentioned in the previous section :smile: )

```bash

# Go to the mininet-wifi directory
cd mininet-wifi


# We add the dependencies for the management of the module mac802154_hwsim
sudo util/install.sh -6

```
Now with the dependencies already added, let's make use of the example available in Mininet-wifi to test the loading of the XDP program developed in [`case01`](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case01). This example can be found under the `examples` directory with the name `6LoWPan.py`. Note that in this example we add an auxiliary interface that adds the management layer of the `6LoWPan` standard. This is useful for us, since we will load the program on the native interface of `ieee802154` subsystem.
```bash

# We enter the directory of the examples
cd examples

# Execute the example
sudo python 6LoWPan.py
```

Once the example is loaded, we will have the Mininet-Wifi CLI open, and the next thing we will do is compile an XDP use case. As we mentioned before, it will be [`case01`](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case01).

```bash

# We move from one directory to another and compile case01
mininet-wifi> sh cd ~/TFG/src/use_cases/xdp/case01 && sudo make
```

We would already have the XDP use case compiled and ready to be loaded on the interface. But on which interface should we load the XDP program? Well, to answer this question we must first inspect the interfaces of one of the sensors. As the sensors run in their own Network namespace, we will have to open an xterm or indicate the node name previously in the Mininet-Wifi CLI so that this command is executed within the indicated Network Namespace.

```bash
# As you can see the interface that adds the layer 6LoWPan is the sensor1-pan0 interface
# We will focus on the interface that communicates directly with the 802.15.4 subsystem
mininet-wifi> sensor1 ip a s

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: sensor1-pan0@sensor1-wpan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1280 qdisc noqueue state UNKNOWN group default qlen 1000
    link/6lowpan 9e:7b:c7:68:bb:9c:31:56 brd ff:ff:ff:ff:ff:ff:ff:ff
    inet6 2001::1/64 scope global
       valid_lft forever preferred_lft forever
248: sensor1-wpan0: <BROADCAST,NOARP,UP,LOWER_UP> mtu 123 qdisc fq_codel state UNKNOWN group default qlen 300
    link/ieee802.15.4 9e:7b:c7:68:bb:9c:31:56 brd ff:ff:ff:ff:ff:ff:ff:ff

# Additionally, we can use the iwpan tool to see which interfaces (dev)
# are available and on which radio, they are connected.
mininet-wifi> sensor1 iwpan dev
phy#24
        Interface sensor1-wpan0
                ifindex 248
                wpan_dev 0x1800000002
                extended_addr 0x9e7bc768bb9c3156
                short_addr 0xffff
                pan_id 0xbeef
                type node
                max_frame_retries 3
                min_be 3
                max_be 5
                max_csma_backoffs 4
                lbt 0
                ackreq_default 0


```

Therefore, knowing on which interface to operate, in our case we will work on the `sensor1` in the `sensor1-wpan0` interface, only remains to load the program and see if it really supports the functionality of it. Note that only if the bpf file system is not mounted under the path `/sys/fs/bpf/` it will not be possible to collect statistics using BPF maps.

```bash
# Mount special filesystem - BPF
mininet-wifi> sensor1 mount -t bpf bpf /sys/fs/bpf


# Load XDP promar to the interface
mininet-wifi> sensor1 cd /home/n0obie/TFG/src/use_cases/xdp/case01 && sudo ./xdp_loader -S -d sensor1-wpan0 -F --progsec xdp_case01
Success: Loaded BPF-object(prog_kern.o) and used section(xdp_case01)
 - XDP prog attached on device:sensor1-wpan0(ifindex:248)
 - Pinning maps in /sys/fs/bpf/sensor1-wpan0/
mininet-wifi>
```

You can see how the program has been correctly loaded in the interface, in addition, the maps were successfully anchored in the file system so that we can collect statistics regarding XDP return codes. You can check that the functionality of the XDP program is operating as expected by pinging between two sensors, as implementing an 'XDP_DROP' return code will not provide connectivity between them.

```bash

# Watch out! With the XDP program loaded on the interface
mininet-wifi> sensor1 ping sensor2
PING 2001::2(2001::2) 56 data bytes
From 2001::1 icmp_seq=1 Destination unreachable: Address unreachable
From 2001::1 icmp_seq=2 Destination unreachable: Address unreachable
From 2001::1 icmp_seq=3 Destination unreachable: Address unreachable
^CsendInt: writing chr(3)

--- 2001::2 ping statistics ---
4 packets transmitted, 0 received, +3 errors, 100% packet loss, time 3072ms

mininet-wifi>

```


As you can see, the behavior is as expected, but even so, you could think that the connectivity failure between both sensors is due to another reason, so the reader is encouraged to download the XDP program and test again the connectivity between both sensors.

```bash
# We remove the XDP program from the interface 
mininet-wifi> sensor1 cd /home/n0obie/TFG/src/use_cases/xdp/case01 && sudo ./xdp_loader -S -U -d sensor1-wpan0
INFO: xdp_link_detach() removed XDP prog ID:677 on ifindex:248
mininet-wifi>


# Re-test the connectivity between the two sensors
 mininet-wifi> sensor1 ping sensor2
PING 2001::2(2001::2) 56 data bytes
64 bytes from 2001::2: icmp_seq=1 ttl=64 time=0.053 ms
64 bytes from 2001::2: icmp_seq=2 ttl=64 time=0.044 ms
64 bytes from 2001::2: icmp_seq=3 ttl=64 time=0.044 ms
64 bytes from 2001::2: icmp_seq=4 ttl=64 time=0.106 ms
^CsendInt: writing chr(3)

--- 2001::2 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3049ms
rtt min/avg/max/mdev = 0.044/0.061/0.106/0.027 ms
mininet-wifi>

```


## Conclusions

Taking into account all the aspects discussed in this feasibility analysis, it is concluded that the use cases cannot be directly extrapolated, since the interfaces are not of the Ethernet type. This would imply redoing the layer two parsing module, which is admissible and feasible. 


Therefore, it is proposed in the future to carry out this development, as well as to study and analyze different variables that come into play in a low-capacity wireless environment. Such as battery, memory, transmission and reception numbers, among others. In this way, it is intended to see which technology, if p4 or XDP, will allow us to program IoT devices with greater efficiency in 802.15.4 networks.




## Sources and links

*   [Source `ieee802154` in the Linux Kernel](https://elixir.bootlin.com/linux/latest/source/drivers/net/ieee802154)
*   [Doc   `ieee802154` in the Linux Kernel](https://www.kernel.org/doc/Documentation/networking/ieee802154.txt)
*   [Linux WPAN network development - github.org](https://github.com/linux-wpan)
*   [Linux WPAN network development - webpage](https://linux-wpan.org/)
*   [User space Tools for the stack `ieee802154`](https://github.com/linux-wpan/wpan-tools)




