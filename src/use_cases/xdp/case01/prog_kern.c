/* SPDX-License-Identifier: GPL-2.0 
 *
 *
 * Modified archive of the xdp-project (github.com/xdp-project) repository
 * for purely academic purposes.
 *
 *	Author: David Carrascal <davidcawork@gmail.com>
 *	Date:   29 Jan 2011
 */

#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

	
SEC("case01")
int xdp_pass_func(struct xdp_md *ctx)
{
	int action = XDP_PASS;
out:
        return xdp_stats_record_action(ctx, action);
}

char _license[] SEC("license") = "GPL";
