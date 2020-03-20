/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>


/* SPDX-License-Identifier: GPL-2.0 
 *
 *
 * Modified archive of the P4lang-project (github.com/p4lang/tutorials/) repository
 * for purely academic purposes.
 *
 *	Author: David Carrascal <davidcawork@gmail.com>
 *	Date:   19 March 2020
 */



/*************************************************************************
***********************  M A C R O S   ***********************************
*************************************************************************/

/*	---	Layer 2 MACROS	     ---	*/
const bit<16> ETHERTYPE_IPV4 = 0x0800;
const bit<16> ETHERTYPE_IPV6 = 0x86dd;

/*	---	Layer 3 MACROS	     ---	*/
const bit<8> IP_PROTOCOL_ICMP = 0x01;
const bit<8> IP_PROTOCOL_ICMPv6 = 0x3a; 

/*
 *   According to RFC 2460, the codes of the protocol immediately above,
 *   layer 4, are the same as those used in IPv4. And I quote:
 *
 *   Next Header          8-bit selector.  Identifies the type of header
 *                       immediately following the IPv6 header.  Uses the
 *                       same values as the IPv4 Protocol field [RFC-1700
 *                       et seq.].
 *
 */

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>   egressSpec_t;
typedef bit<48>  macAddr_t;
typedef bit<32>  ip4Addr_t;
typedef bit<128> ip6Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header ipv6_t {
	bit<4> version;
	bit<8> trafficClass;
	bit<20> flowLabel;
	bit<16> payloadLen;
	bit<8> nextHdr;
	bit<8> hopLimit;
	ip6Addr_t srcAddr;
	ip6Addr_t dstAddr;	
}

header icmp_t {
	bit<8> type;
	bit<8> code;
	bit<16> checksum;
}

header icmp6_t {
	bit<8> type;
	bit<8> code;
	bit<16> checksum;
}

struct metadata {
    /* empty */
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    ipv6_t	 ipv6;
    icmp_t       icmp;
    icmp6_t      icmp6;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_IPV4: parse_ipv4;
 	    ETHERTYPE_IPV6: parse_ipv6;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select( hdr.ipv4.protocol){
		IP_PROTOCOL_ICMP: parse_icmp;
		default: accept;		
	}
    }

    state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition select(){
		IP_PROTOCOL_ICMPv6: parse_icmp6;
		default: accept;
	}
    }

    state parse_icmp {
    	packet.extract(hdr.icmp);
	transition accept;	
    }

    state parse_icmp6 {
    	packet.extract(hdr.icmp6);
	transition accept;	
    }
}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop(standard_metadata);
    }
    
   
    apply {
        drop();
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {
	update_checksum(
	    hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	      hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
