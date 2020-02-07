/* SPDX-License-Identifier: GPL-2.0 
 *
 *
 * Modified archive of the xdp-project (github.com/xdp-project) repository
 * for purely academic purposes.
 *
 *	Author: David Carrascal <davidcawork@gmail.com>
 *	Date:   07 Feb 2020
 */


#include <linux/bpf.h>
#include <linux/in.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>
#include "../common/parsing_helpers.h"

/* Defines xdp_stats_map */
#include "../common/xdp_stats_kern_user.h"
#include "../common/xdp_stats_kern.h"

#ifndef memcpy
#define memcpy(dest, src, n) __builtin_memcpy((dest), (src), (n))
#endif

SEC("xdp_case05")
int xdp_redirect_func(struct xdp_md *ctx)
{
	void *data_end = (void *)(long)ctx->data_end;
	void *data = (void *)(long)ctx->data;
	struct hdr_cursor nh;
	struct ethhdr *eth;
	int eth_type;
	int action = XDP_PASS;
	unsigned char dst[ETH_ALEN + 1] = {0x52,0xe1,0xb9,0x94,0xde,0x61, '\0'} ;
	unsigned ifindex = 6; 	

	/* These keep track of the next header type and iterator pointer */
	nh.pos = data;

	/* Parse Ethernet and IP/IPv6 headers */
	eth_type = parse_ethhdr(&nh, data_end, &eth);
	if (eth_type == -1)
		goto out;


	memcpy(eth->h_dest,dst,ETH_ALEN);
	action = bpf_redirect(ifindex,0);

out:
	return xdp_stats_record_action(ctx, action);
}


SEC("xdp_pass")
int xdp_pass_func(struct xdp_md *ctx)
{
	return XDP_PASS;
}

char _license[] SEC("license") = "GPL";
