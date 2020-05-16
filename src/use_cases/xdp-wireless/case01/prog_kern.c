/* SPDX-License-Identifier: GPL-2.0 
 *
 *
 * Modified archive of the xdp-project (github.com/xdp-project) repository
 * for purely academic purposes.
 *
 *	Author: David Carrascal <davidcawork@gmail.com>
 *	Date:   29 Jan 2020
 */

#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include "../common/xdp_stats_kern_user.h"
#include "../common/xdp_stats_kern.h"
	
SEC("xdp_case01")
int xdp_pass_func(struct xdp_md *ctx)
{
	int action = XDP_DROP;
	goto out;
out:
        return xdp_stats_record_action(ctx, action);
}

char _license[] SEC("license") = "GPL";
