/*  SPDX-License-Identifier: GPL-2.0 
 *
 *	Author: David Carrascal <davidcawork@gmail.com>
 *	Date:   21 Feb 2020
 *
 *
 */

#include <linux/bpf.h>
#include <linux/pkt_cls.h>
#include <linux/if_arp.h>
#include <linux/in.h>
#include <stddef.h>
#include "bpf_helpers.h"

#define MAX_NETDEV 64

SEC("action")
int case05_broadcast(struct __sk_buff *skb)
{
	
	void *data = (void *)(long)skb->data;
	void *data_end = (void *)(long)skb->data_end;
	
	
	if (data + sizeof(struct arphdr) > data_end)
		return TC_ACT_UNSPEC;
	
	#pragma unroll
	for (int i = 0; i < 256 ; i++) {
		if(!( i == skb->ifindex))
			bpf_clone_redirect(skb, i, 0);
	}

	return TC_ACT_SHOT;
}


SEC("classifier")
int case05_cls(struct __sk_buff *skb)
{
        return TC_ACT_UNSPEC;
}


char __license[] SEC("license") = "GPL";
