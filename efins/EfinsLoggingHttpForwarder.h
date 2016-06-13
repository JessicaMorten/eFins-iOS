//
//  EfinsLoggingHttpForwarder.h
//  eFins-iOS
//
//  Created by Todd Bryan on 7/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

#ifndef eFins_iOS_EfinsLoggingHttpForwarder_h
#define eFins_iOS_EfinsLoggingHttpForwarder_h

#import <Foundation/Foundation.h>
@protocol Forwarder <NSObject>
@required
- (void)forwardLog:(NSData *)log forDeviceId:(NSString *)devId;
@end


@interface EfinsLoggingHttpForwarder : NSObject <Forwarder>

@property (nonatomic, strong) NSString *aggregatorUrl;

+ (EfinsLoggingHttpForwarder *)forwarderWithAggregatorUrl:(NSString *)url;

@end


#endif
