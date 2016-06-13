#import "EfinsLoggingHttpForwarder.h"
#import "zlib.h"
#import "TeleportUtils.h"

@interface EfinsLoggingHttpForwarder()
@end

@implementation EfinsLoggingHttpForwarder

+ (EfinsLoggingHttpForwarder *)forwarderWithAggregatorUrl:(NSString *)url {
    EfinsLoggingHttpForwarder *forwarder = [[EfinsLoggingHttpForwarder alloc] init];
    forwarder.aggregatorUrl = url;
    return forwarder;
}

- (void)forwardLog:(NSData *)log forDeviceId:(NSString *)devId {
    if (self.aggregatorUrl == nil || self.aggregatorUrl.length == 0)
        return;
    
    if ([log length] < 1)
        return;
    
    //Compression is turned off for now
    [self uploadData:log forField:@"file" URL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?devid=%@", self.aggregatorUrl, devId]] completion:^(BOOL success, NSString *errorMessage) {
        [TeleportUtils teleportDebug:[NSString stringWithFormat:@"success = %d; errorMessage = %@", success, errorMessage]];
    }];
}

- (void)uploadData:(NSData *)data
          forField:(NSString *)fieldName
               URL:(NSURL*)url
        completion:(void (^)(BOOL success, NSString *errorMessage))completion
{
    // configure the request
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setTimeoutInterval:30];
    [request setHTTPMethod:@"POST"];
    
    // set content type
    NSString *bearer = [[NSString alloc] initWithFormat:@"Bearer %@", [[NSUserDefaults standardUserDefaults] stringForKey:@"SessionToken"]];
    NSString *contentLength = [[NSString alloc] initWithFormat:@"%lu", data.length];
    [request setValue:@"text/plain" forHTTPHeaderField: @"Content-Type"];
    //[request setValue:@"deflate" forHTTPHeaderField: @"Content-Encoding"];
    [request setValue:contentLength forHTTPHeaderField: @"Content-Length"];


    [request setValue:bearer forHTTPHeaderField:@"Authorization"];
    
    // setting the body of the post to the request
    
    
    [request setHTTPBody:data];
    
    [TeleportUtils teleportDebug:[NSString stringWithFormat:@"Posting %lu bytes to: %@", (unsigned long)[data length], [url absoluteString]]];
    
    NSURLResponse *reponse;
    NSError *error;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&reponse error:&error];
    
    if (error)
    {
        if (completion)
            completion(FALSE, [NSString stringWithFormat:@"%s: sendSynchronousRequest error: %@", __FUNCTION__, error]);
        return;
    } else {
        if (completion)
            completion(TRUE, @"Ok");
        return;
    }
    
}

NSData* compressData(NSData* uncompressedData) {
    if ([uncompressedData length] == 0) return uncompressedData;
    
    z_stream strm;
    
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef *)[uncompressedData bytes];
    strm.avail_in = (unsigned int)[uncompressedData length];
    
    // Compresssion Levels:
    //   Z_NO_COMPRESSION
    //   Z_BEST_SPEED
    //   Z_BEST_COMPRESSION
    //   Z_DEFAULT_COMPRESSION
    
    if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
    
    NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
    
    do {
        
        if (strm.total_out >= [compressed length])
            [compressed increaseLengthBy: 16384];
        
        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = (unsigned int)([compressed length] - strm.total_out);
        
        deflate(&strm, Z_FINISH);
        
    } while (strm.avail_out == 0);
    
    deflateEnd(&strm);
    
    [compressed setLength: strm.total_out];
    return [NSData dataWithData:compressed];
}

@end
