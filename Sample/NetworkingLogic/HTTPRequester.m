//
//  HTTPRequester.m
//
//  Created by BENJAMIN BRYANT BUDIMAN on 05/09/18.
//  Copyright © 2018 Boku, Inc. All rights reserved.
//

#import "HTTPRequester.h"
#import "SocketAddress.h"
#import "sslfuncs.h"
#import <Foundation/Foundation.h>
#import <ifaddrs.h>
#import <net/if.h>
#import <netdb.h>
#include <arpa/inet.h>

@implementation HTTPRequester

//+ (NSString *)performGetRequest:(NSURL *)url withCookies:(NSString *)cookies {
+ (NSString *)performGetRequest:(NSURL *)url {
 
    // Stores any errors that occur during execution
    OSStatus status;
    
    // All local (cellular interface) IP addresses of this device.
    NSMutableArray<SocketAddress *> *localAddresses = [NSMutableArray array];
    // All remote IP addresses that we're trying to connect to.
    NSMutableArray<SocketAddress *> *remoteAddresses = [NSMutableArray array];
    
    // The local (cellular interface) IP address of this device.
    SocketAddress *localAddress;
    // The remote IP address that we're trying to connect to.
    SocketAddress *remoteAddress;
    
    NSPredicate *ipv4Predicate = [NSPredicate predicateWithBlock:^BOOL(SocketAddress *evaluatedObject, NSDictionary<NSString *, id> *bindings) {
        return evaluatedObject.sockaddr->sa_family == AF_INET;
    }];
    NSPredicate *ipv6Predicate = [NSPredicate predicateWithBlock:^BOOL(SocketAddress *evaluatedObject, NSDictionary<NSString *, id> *bindings) {
        return evaluatedObject.sockaddr->sa_family == AF_INET6;
    }];
    
    struct ifaddrs *ifaddrPointer;
    struct ifaddrs *ifaddrs;
    
    status = getifaddrs(&ifaddrPointer);
    if (status) {
        return nil;
    }
    
    ifaddrs = ifaddrPointer;
    while (ifaddrs) {
        // If the interface is up
        if (ifaddrs->ifa_flags & IFF_UP) {
            // If the interface is the pdp_ip0 (cellular) interface
            if (strcmp(ifaddrs->ifa_name, "pdp_ip0") == 0) {
                switch (ifaddrs->ifa_addr->sa_family) {
                    case AF_INET:  // IPv4
                    case AF_INET6: // IPv6
                        [localAddresses addObject:[[SocketAddress alloc] initWithSockaddr:ifaddrs->ifa_addr]];
                        break;
                }
            }
        }
        ifaddrs = ifaddrs->ifa_next;
    }
    
    struct addrinfo *addrinfoPointer;
    struct addrinfo *addrinfo;
    
    // Generate "hints" for the DNS lookup (namely, search for both IPv4 and
    // IPv6 addresses)
    struct addrinfo hints;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    
    char* service = [[url scheme] UTF8String];
    
    if(url.port) {
        NSString *portString = [NSString stringWithFormat: @"%@", [url port]];
        service = [portString UTF8String];
    }
    
    status = getaddrinfo([[url host] UTF8String], service, &hints, &addrinfoPointer);
    if (status) {
        freeifaddrs(ifaddrPointer);
        NSString *toReturn = @"ERROR: CANNOT FIND REMOTE ADDRESS";
        return toReturn;
    }
    
    addrinfo = addrinfoPointer;
    
    while (addrinfo) {
        switch (addrinfo->ai_addr->sa_family) {
            case AF_INET:  // IPv4
            case AF_INET6: // IPv6
                [remoteAddresses addObject:[[SocketAddress alloc] initWithSockaddr:addrinfo->ai_addr]];
                break;
        }
        addrinfo = addrinfo->ai_next;
    }
    
    if ((localAddress = [[localAddresses filteredArrayUsingPredicate:ipv6Predicate] lastObject]) && (remoteAddress = [[remoteAddresses filteredArrayUsingPredicate:ipv6Predicate] lastObject])) {
        // Select the IPv6 route, if possible
    }
    else if ((localAddress = [[localAddresses filteredArrayUsingPredicate:ipv4Predicate] lastObject]) && (remoteAddress = [[remoteAddresses filteredArrayUsingPredicate:ipv4Predicate] lastObject])) {
        // Select the IPv4 route, if possible (and no IPv6 route is available)
    }
    else {                                                                                                                                                                                             // No route found, abort
        freeaddrinfo(addrinfoPointer);
        NSString *toReturn = @"ERROR: NO ROUTES FOUND";
        return toReturn;
    }
    
    // Create a new socket
    int sock = socket(localAddress.sockaddr->sa_family, SOCK_STREAM, 0);
    if(sock == -1) {
        NSString *toReturn = @"ERROR: CANNOT CREATE SOCKET";
        return toReturn;
    }
    
    // Bind the socket to the local address
    bind(sock, localAddress.sockaddr, localAddress.size);
    
    // Connect to the remote address using the socket
    status = connect(sock, remoteAddress.sockaddr, remoteAddress.size);
    if (status) {
        freeaddrinfo(addrinfoPointer);
        NSString *toReturn =  @"ERROR: CANNOT CONNECT SOCKET TO REMOTE ADDRESS";
        return toReturn;
    }
    
    NSString *requestString = [NSString stringWithFormat:@"GET %@%@ HTTP/1.1\r\nHost: %@%@\r\n", [url path], [url query] ? [@"?" stringByAppendingString:[url query]] : @"", [url host], [url port] ? [@":" stringByAppendingFormat:@"%@", [url port]] : @""];
    
    requestString = [requestString stringByAppendingString:@"Connection: close\r\n\r\n"];
   
    const char* request = [requestString UTF8String];

    char buffer[4096];
    
    if ([[url scheme] isEqualToString:@"http"]) {
        write(sock, request, strlen(request));
        
        int received = 0;
        int total = sizeof(buffer)-1;
        do {
            int bytes = (int)read(sock, buffer+received, total-received);
            if (bytes < 0) {
                NSString *toReturn = @"ERROR: PROBLEM READING RESPONSE";
                return toReturn;
            } else if(bytes==0) {
                break;
            }
            
            received += bytes;
        } while (received < total);
    } else {
        // Setup SSL
        SSLContextRef context = SSLCreateContext(kCFAllocatorDefault, kSSLClientSide, kSSLStreamType);
        
        status = SSLSetIOFuncs(context, ssl_read, ssl_write);
        if (status) {
            SSLClose(context);
            CFRelease(context);
            NSString *toReturn = @"ERROR: SSL1";
            return toReturn;
        }
        
        status = SSLSetConnection(context, (SSLConnectionRef)&sock);
        if (status) {
            SSLClose(context);
            CFRelease(context);
            NSString *toReturn = @"ERROR: SSL2";
            return toReturn;
        }
        
        status = SSLSetPeerDomainName(context, [[url host] UTF8String], strlen([[url host] UTF8String]));
        if (status) {
            SSLClose(context);
            CFRelease(context);
            NSString *toReturn = @"ERROR: SSL3";
            return toReturn;
        }
        
        // Repeat this until it doesn't error out
        do {
            status = SSLHandshake(context);
        } while (status == errSSLWouldBlock);
        if (status) {
            SSLClose(context);
            CFRelease(context);
            NSString *toReturn = @"ERROR: SSL4";
            return toReturn;
        }
        
        size_t processed = 0;
        status = SSLWrite(context, request, strlen(request), &processed);
        if (status) {
            SSLClose(context);
            CFRelease(context);
            NSString *toReturn = @"ERROR: SSL5";
            return toReturn;
        }
        
        do {
            status = SSLRead(context, buffer, sizeof(buffer) - 1, &processed);
            buffer[processed] = 0;
            
            // If the buffer was filled, then continue reading
            if (processed == sizeof(buffer) - 1) {
                status = errSSLWouldBlock;
            }
        } while (status == errSSLWouldBlock);
        
        if (status && status != errSSLClosedGraceful) {
            SSLClose(context);
            CFRelease(context);
            NSString *toReturn = @"ERROR: SSL6";
            return toReturn;
        }
    }
    
    NSString *response = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
  
    if ([response rangeOfString:@"HTTP/"].location == NSNotFound) {
        NSString *toReturn = @"ERROR: Done";
        return toReturn;
    }
    
    NSUInteger prefixLocation = [response rangeOfString:@"HTTP/"].location + 9;
    
    NSRange toReturnRange = NSMakeRange(prefixLocation, 1);
    
    NSString* urlResponseCode = [response substringWithRange:toReturnRange];
    
    if ([urlResponseCode isEqualToString:@"3"]) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Location: (.*)\r\n" options:NSRegularExpressionCaseInsensitive error:NULL];
        
        NSArray *myArray = [regex matchesInString:response options:0 range:NSMakeRange(0, [response length])] ;
        
        NSString* redirectLink = @"";
        
        for (NSTextCheckingResult *match in myArray) {
            NSRange matchRange = [match rangeAtIndex:1];
            redirectLink = [response substringWithRange:matchRange];
        }
        
        response = @"REDIRECT:";
        response = [response stringByAppendingString:redirectLink];
    }

    return response;
}

@end
