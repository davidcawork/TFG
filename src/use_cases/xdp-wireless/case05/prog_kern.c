/* SPDX-License-Identifier: GPL-2.0 
 *
 *
 * Modified archive of the xdp-project (github.com/xdp-project) repository
 * for purely academic purposes.
 *
 *	Author: David Carrascal <davidcawork@gmail.com>
 *	Date:   15 May 2020
 */


#include <linux/bpf.h>
#include <linux/in.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>
#include <linux/pkt_cls.h>
//#include "bpf_helpers.h"
#include "../common/parsing_helpers.h"

/* Defines xdp_stats_map */
#include "../common/xdp_stats_kern_user.h"
#include "../common/xdp_stats_kern.h"

#define BROADCAST_U64 39125021762781183

#ifndef memcpy
#define memcpy(dest, src, n) __builtin_memcpy((dest), (src), (n))
#endif

#define bpf_debug(fmt, ...)						\
		({							\
			char ____fmt[] = fmt;				\
			bpf_trace_printk(____fmt, sizeof(____fmt),	\
				     ##__VA_ARGS__);			\
		})




/* To u64 in host order */
static inline __u64 ether_addr_to_u64(const __u8 *addr)
{
	__u64 u = 0;
	int i;

	for (i = ETH_ALEN; i >= 0; i--)
		u = u << 8 | addr[i];
	return u;
}


static __always_inline int isBroadcast(const __u8 *mac) {
 
	/*	ff's string in __u64 format */
	__u64 broadcast  = BROADCAST_U64;  
  
  	return ( ether_addr_to_u64(mac) == broadcast ) ? (1) : (0);	
}


SEC("xdp_case05")
int xdp_pass_func(struct xdp_md *ctx)
{
        void *data_end = (void *)(long)ctx->data_end;
        void *data = (void *)(long)ctx->data;
        struct hdr_cursor nh;
        struct ethhdr *eth;
        int action = XDP_PASS;
	int eth_type;
        unsigned ifindex = 143; /*  Wireless interface */

        /* These keep track of the next header type and iterator pointer */
        nh.pos = data;

        /* Parse Ethernet and IP/IPv6 headers */
        eth_type = parse_ethhdr(&nh, data_end, &eth);
        if (eth_type == -1)
                goto out;
	
	bpf_debug("src: %llu, dst: %llu, proto: %u\n",
           ether_addr_to_u64(eth->h_source),
           ether_addr_to_u64(eth->h_dest),
           bpf_ntohs(eth->h_proto));


	/* If the packet is broadcast, just send it to the wireless interfaces with FF's  */
	if ( isBroadcast(eth->h_dest) ){
        	action = bpf_redirect(ifindex,0);
	}


out:
        return xdp_stats_record_action(ctx, action);

}

char _license[] SEC("license") = "GPL";
