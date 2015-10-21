/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTNetworking.h"

#import "RCTAssert.h"
#import "RCTConvert.h"
#import "RCTDownloadTask.h"
#import "RCTURLRequestHandler.h"
#import "RCTEventDispatcher.h"
#import "RCTHTTPRequestHandler.h"
#import "RCTLog.h"
#import "RCTUtils.h"

typedef RCTURLRequestCancellationBlock (^RCTHTTPQueryResult)(NSError *error, NSDictionary *result);

@interface RCTNetworking ()

- (RCTURLRequestCancellationBlock)processDataForHTTPQuery:(NSDictionary *)data
                                                 callback:(RCTHTTPQueryResult)callback;
@end

/**
 * Helper to convert FormData payloads into multipart/formdata requests.
 */
@interface RCTHTTPFormDataHelper : NSObject

@property (nonatomic, weak) RCTNetworking *networker;

@end

@implementation RCTHTTPFormDataHelper
{
  NSMutableArray *parts;
  NSMutableData *multipartBody;
  RCTHTTPQueryResult _callback;
  NSString *boundary;
}

static NSString *RCTGenerateFormBoundary()
{
  const size_t boundaryLength = 70;
  const char *boundaryChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_./";

  char *bytes = malloc(boundaryLength);
  size_t charCount = strlen(boundaryChars);
  for (int i = 0; i < boundaryLength; i++) {
    bytes[i] = boundaryChars[arc4random_uniform((u_int32_t)charCount)];
  }
  return [[NSString alloc] initWithBytesNoCopy:bytes length:boundaryLength encoding:NSUTF8StringEncoding freeWhenDone:YES];
}

- (RCTURLRequestCancellationBlock)process:(NSArray *)formData
                                 callback:(RCTHTTPQueryResult)callback
{
  if (formData.count == 0) {
    return callback(nil, nil);
  }

  parts = [formData mutableCopy];
  _callback = callback;
  multipartBody = [NSMutableData new];
  boundary = RCTGenerateFormBoundary();

  return [_networker processDataForHTTPQuery:parts[0] callback:^(NSError *error, NSDictionary *result) {
    return [self handleResult:result error:error];
  }];
}

- (RCTURLRequestCancellationBlock)handleResult:(NSDictionary *)result
                                         error:(NSError *)error
{
  if (error) {
    return _callback(error, nil);
  }

  // Start with boundary.
  [multipartBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary]
                             dataUsingEncoding:NSUTF8StringEncoding]];

  // Print headers.
  NSMutableDictionary *headers = [parts[0][@"headers"] mutableCopy];
  NSString *partContentType = result[@"contentType"];
  if (partContentType != nil) {
    headers[@"content-type"] = partContentType;
  }
  [headers enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey, NSString *parameterValue, BOOL *stop) {
    [multipartBody appendData:[[NSString stringWithFormat:@"%@: %@\r\n", parameterKey, parameterValue]
                               dataUsingEncoding:NSUTF8StringEncoding]];
  }];

  // Add the body.
  [multipartBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
  [multipartBody appendData:result[@"body"]];
  [multipartBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];

  [parts removeObjectAtIndex:0];
  if (parts.count) {
    return [_networker processDataForHTTPQuery:parts[0] callback:^(NSError *err, NSDictionary *res) {
      return [self handleResult:res error:err];
    }];
  }

  // We've processed the last item. Finish and return.
  [multipartBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary]
                             dataUsingEncoding:NSUTF8StringEncoding]];
  NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=\"%@\"", boundary];
  return _callback(nil, @{@"body": multipartBody, @"contentType": contentType});
}

@end

/**
 * Bridge module that provides the JS interface to the network stack.
 */
@implementation RCTNetworking
{
  NSMutableDictionary *_tasksByRequestID;
}

@synthesize bridge = _bridge;
@synthesize methodQueue = _methodQueue;

RCT_EXPORT_MODULE()

- (instancetype)init
{
  if ((self = [super init])) {
    _tasksByRequestID = [NSMutableDictionary new];
  }
  return self;
}

- (RCTURLRequestCancellationBlock)buildRequest:(NSDictionary *)query
                                 completionBlock:(void (^)(NSURLRequest *request))block
{
  NSURL *URL = [RCTConvert NSURL:query[@"url"]]; // this is marked as nullable in JS, but should not be null
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
  request.HTTPMethod = [RCTConvert NSString:RCTNilIfNull(query[@"method"])].uppercaseString ?: @"GET";
  request.allHTTPHeaderFields = [RCTConvert NSDictionary:query[@"headers"]];

  NSDictionary *data = [RCTConvert NSDictionary:RCTNilIfNull(query[@"data"])];
  return [self processDataForHTTPQuery:data callback:^(NSError *error, NSDictionary *result) {
    if (error) {
      RCTLogError(@"Error processing request body: %@", error);
      // Ideally we'd circle back to JS here and notify an error/abort on the request.
      return (RCTURLRequestCancellationBlock)nil;
    }
    request.HTTPBody = result[@"body"];
    NSString *contentType = result[@"contentType"];
    if (contentType) {
      [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    }

    // Gzip the request body
    if ([request.allHTTPHeaderFields[@"Content-Encoding"] isEqualToString:@"gzip"]) {
      request.HTTPBody = RCTGzipData(request.HTTPBody, -1 /* default */);
      [request setValue:(@(request.HTTPBody.length)).description forHTTPHeaderField:@"Content-Length"];
    }

    block(request);
    return (RCTURLRequestCancellationBlock)nil;
  }];
}

- (id<RCTURLRequestHandler>)handlerForRequest:(NSURLRequest *)request
{
  NSMutableArray *handlers = [NSMutableArray array];
  for (id<RCTBridgeModule> module in _bridge.modules.allValues) {
    if ([module conformsToProtocol:@protocol(RCTURLRequestHandler)]) {
      if ([(id<RCTURLRequestHandler>)module canHandleRequest:request]) {
        [handlers addObject:module];
      }
    }
  }
  [handlers sortUsingComparator:^NSComparisonResult(id<RCTURLRequestHandler> a, id<RCTURLRequestHandler> b) {
    float priorityA = [a respondsToSelector:@selector(handlerPriority)] ? [a handlerPriority] : 0;
    float priorityB = [b respondsToSelector:@selector(handlerPriority)] ? [b handlerPriority] : 0;
    if (priorityA < priorityB) {
      return NSOrderedAscending;
    } else if (priorityA > priorityB) {
      return NSOrderedDescending;
    } else {
      RCTLogError(@"The RCTURLRequestHandlers %@ and %@ both reported that"
                  " they can handle the request %@, and have equal priority"
                  " (%g). This could result in non-deterministic behavior.",
                  a, b, request, priorityA);

      return NSOrderedSame;
    }
  }];
  id<RCTURLRequestHandler> handler = handlers.lastObject;
  if (!handler) {
    RCTLogError(@"No suitable request handler found for %@", request.URL);
  }
  return handler;
}

/**
 * Process the 'data' part of an HTTP query.
 *
 * 'data' can be a JSON value of the following forms:
 *
 * - {"string": "..."}: a simple JS string that will be UTF-8 encoded and sent as the body
 *
 * - {"uri": "some-uri://..."}: reference to a system resource, e.g. an image in the asset library
 *
 * - {"formData": [...]}: list of data payloads that will be combined into a multipart/form-data request
 *
 * If successful, the callback be called with a result dictionary containing the following (optional) keys:
 *
 * - @"body" (NSData): the body of the request
 *
 * - @"contentType" (NSString): the content type header of the request
 *
 */
- (RCTURLRequestCancellationBlock)processDataForHTTPQuery:(nullable NSDictionary *)query callback:
(RCTURLRequestCancellationBlock (^)(NSError *error, NSDictionary *result))callback
{
  if (!query) {
    return callback(nil, nil);
  }
  NSData *body = [RCTConvert NSData:query[@"string"]];
  if (body) {
    return callback(nil, @{@"body": body});
  }
  NSURLRequest *request = [RCTConvert NSURLRequest:query[@"uri"]];
  if (request) {

    __block RCTURLRequestCancellationBlock cancellationBlock = nil;
    RCTDownloadTask *task = [self downloadTaskWithRequest:request completionBlock:^(NSURLResponse *response, NSData *data, NSError *error) {
      cancellationBlock = callback(error, data ? @{@"body": data, @"contentType": RCTNullIfNil(response.MIMEType)} : nil);
    }];

    __weak RCTDownloadTask *weakTask = task;
    return ^{
      [weakTask cancel];
      if (cancellationBlock) {
        cancellationBlock();
      }
    };
  }
  NSDictionaryArray *formData = [RCTConvert NSDictionaryArray:query[@"formData"]];
  if (formData) {
    RCTHTTPFormDataHelper *formDataHelper = [RCTHTTPFormDataHelper new];
    formDataHelper.networker = self;
    return [formDataHelper process:formData callback:callback];
  }
  // Nothing in the data payload, at least nothing we could understand anyway.
  // Ignore and treat it as if it were null.
  return callback(nil, nil);
}

- (void)sendData:(NSData *)data forTask:(RCTDownloadTask *)task
{
  if (data.length == 0) {
    return;
  }

  // Get text encoding
  NSURLResponse *response = task.response;
  NSStringEncoding encoding = NSUTF8StringEncoding;
  if (response.textEncodingName) {
    CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)response.textEncodingName);
    encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
  }

  // Attempt to decode text
  NSString *responseText = [[NSString alloc] initWithData:data encoding:encoding];
  if (!responseText && data.length) {

    // We don't have an encoding, or the encoding is incorrect, so now we
    // try to guess (unfortunately, this feature is available of iOS 8+ only)
    if ([NSString respondsToSelector:@selector(stringEncodingForData:
                                               encodingOptions:
                                               convertedString:
                                               usedLossyConversion:)]) {
      [NSString stringEncodingForData:data
                      encodingOptions:nil
                      convertedString:&responseText
                  usedLossyConversion:NULL];
    }

    // If we still can't decode it, bail out
    if (!responseText) {
      RCTLogWarn(@"Received data was not a string, or was not a recognised encoding.");
      return;
    }
  }

  NSArray *responseJSON = @[task.requestID, responseText ?: @""];
  [_bridge.eventDispatcher sendDeviceEventWithName:@"didReceiveNetworkData"
                                              body:responseJSON];
}

- (void)sendRequest:(NSURLRequest *)request
 incrementalUpdates:(BOOL)incrementalUpdates
     responseSender:(RCTResponseSenderBlock)responseSender
{
  __block RCTDownloadTask *task;

  RCTURLRequestProgressBlock uploadProgressBlock = ^(int64_t progress, int64_t total) {
    dispatch_async(_methodQueue, ^{
      NSArray *responseJSON = @[task.requestID, @((double)progress), @((double)total)];
      [_bridge.eventDispatcher sendDeviceEventWithName:@"didSendNetworkData" body:responseJSON];
    });
  };

  void (^responseBlock)(NSURLResponse *) = ^(NSURLResponse *response) {
    dispatch_async(_methodQueue, ^{
      NSHTTPURLResponse *httpResponse = nil;
      if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        // Might be a local file request
        httpResponse = (NSHTTPURLResponse *)response;
      }
      NSArray *responseJSON = @[task.requestID,
                                @(httpResponse.statusCode ?: 200),
                                httpResponse.allHeaderFields ?: @{},
                                ];

      [_bridge.eventDispatcher sendDeviceEventWithName:@"didReceiveNetworkResponse"
                                                  body:responseJSON];
    });
  };

  void (^incrementalDataBlock)(NSData *) = incrementalUpdates ? ^(NSData *data) {
    dispatch_async(_methodQueue, ^{
      [self sendData:data forTask:task];
    });
  } : nil;

  RCTURLRequestCompletionBlock completionBlock =
  ^(NSURLResponse *response, NSData *data, NSError *error) {
    dispatch_async(_methodQueue, ^{
      if (!incrementalUpdates) {
        [self sendData:data forTask:task];
      }
      NSArray *responseJSON = @[task.requestID,
                                RCTNullIfNil(error.localizedDescription),
                                ];

      [_bridge.eventDispatcher sendDeviceEventWithName:@"didCompleteNetworkResponse"
                                                  body:responseJSON];

      [_tasksByRequestID removeObjectForKey:task.requestID];
    });
  };

  task = [self downloadTaskWithRequest:request completionBlock:completionBlock];
  task.incrementalDataBlock = incrementalDataBlock;
  task.responseBlock = responseBlock;
  task.uploadProgressBlock = uploadProgressBlock;

  if (task.requestID) {
    _tasksByRequestID[task.requestID] = task;
    responseSender(@[task.requestID]);
  }
}

#pragma mark - Public API

- (RCTDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                             completionBlock:(RCTURLRequestCompletionBlock)completionBlock
{
  id<RCTURLRequestHandler> handler = [self handlerForRequest:request];
  if (!handler) {
    return nil;
  }

  return [[RCTDownloadTask alloc] initWithRequest:request
                                          handler:handler
                                  completionBlock:completionBlock];
}

#pragma mark - JS API

RCT_EXPORT_METHOD(sendRequest:(NSDictionary *)query
                  responseSender:(RCTResponseSenderBlock)responseSender)
{
  // TODO: buildRequest returns a cancellation block, but there's currently
  // no way to invoke it, if, for example the request is cancelled while
  // loading a large file to build the request body
  [self buildRequest:query completionBlock:^(NSURLRequest *request) {

    BOOL incrementalUpdates = [RCTConvert BOOL:query[@"incrementalUpdates"]];
    [self sendRequest:request
   incrementalUpdates:incrementalUpdates
       responseSender:responseSender];
  }];
}

RCT_EXPORT_METHOD(cancelRequest:(nonnull NSNumber *)requestID)
{
  [_tasksByRequestID[requestID] cancel];
  [_tasksByRequestID removeObjectForKey:requestID];
}

@end

@implementation RCTBridge (RCTNetworking)

- (RCTNetworking *)networking
{
  return self.modules[RCTBridgeModuleNameForClass([RCTNetworking class])];
}

@end
