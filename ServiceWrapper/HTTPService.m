//
//  HTTPService.m
//
//  Created by Ashish Sharma on 30/05/15.
//  Copyright (c) 2015 Konstant Info. All rights reserved.
//

#import "HTTPService.h"

@interface HTTPService ()

/**
 *  Call this to set HTTP headers for request
 *
 *  @param headers HTTP headers
 */
- (void) setHeaders:(NSDictionary*) headers;

/**
 *  Call this to convert params in raw json format
 *
 *  @param params params to post
 */
- (void) addQueryStringWithParams:(NSDictionary*) params;

@end

@implementation HTTPService

#pragma mark - Designated Initializer

- (id)initWithBaseURL:(NSURL*) baseURL andSessionConfig:(NSURLSessionConfiguration*) config
{
    self = [super init];
    
    if (self)
    {
        NSAssert(baseURL, ([NSString stringWithFormat:@"\n<------------------->\n%@\n%sn<------------------->",@"baseURL can't be nil",__PRETTY_FUNCTION__]));
        
        httpBaseURL = [baseURL absoluteString];
        
        if (config)
            httpSessionManager = [[AFHTTPSessionManager alloc]
                                  initWithBaseURL:baseURL sessionConfiguration:config];
        else
            httpSessionManager = [[AFHTTPSessionManager alloc]
                                  initWithBaseURL:baseURL sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        
        httpSessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        httpSessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        
    }
    
    return self;
}

#pragma mark - Super Class Methods

- (id)init
{
    self = [super init];
    
    if (self)
    {
        httpBaseURL = BASE_URL;
        
        httpSessionManager = [[AFHTTPSessionManager alloc]
                              initWithBaseURL:[NSURL URLWithString:httpBaseURL]];
        
        httpSessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        httpSessionManager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingMutableContainers];
    }
    
    return self;
}

- (void)dealloc
{
    httpSessionManager = nil;
}

#pragma mark - Instance Methods (Private)

- (void) setHeaders:(NSDictionary*) headers
{
    if (headers != nil)
    {
        NSArray *allHeaders = [headers allKeys];
        
        for (NSString *key in allHeaders)
        {
            [httpSessionManager.requestSerializer setValue:[headers objectForKey:key] forHTTPHeaderField:key];
        }
    }
}

- (void) addQueryStringWithParams:(NSDictionary*) params
{
    [httpSessionManager.requestSerializer setQueryStringSerializationWithBlock:^NSString *(NSURLRequest *request, NSDictionary *parameters, NSError *__autoreleasing *error) {
        __block NSMutableString *query = [NSMutableString stringWithString:@""];
        
        NSError *err;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&err];
        NSMutableString *jsonString = [[NSMutableString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        query = jsonString;
        
        return query;
    }];
}

#pragma mark - Instance Methods

-(BOOL)doesServiceHasAppFreezingMetaData:(id)responseObject{
    
    NSDictionary *dictResponse = (NSDictionary *)responseObject;
    if ([dictResponse objectForKey:@"meta"]
        && ([[[dictResponse objectForKey:@"meta"] objectForKey:@"hasUpdate"] boolValue] || [[[dictResponse objectForKey:@"meta"] objectForKey:@"requireLogin"] boolValue])) {
        
        [CommonFunctions showAlertViewForServiceMetaData:[dictResponse objectForKey:@"meta"]];
        
        return YES;
        
    }
    
    return NO;
}

-(void)callServiceWithSuccessBlock:(void(^)(id response, Class modelClass))successHandler withFailureBlock:(void(^)(id response, Class modelClass))failureHandler{
    NSLog(@"over ride this method in relevant child class");
}

- (void) startRequestWithHttpMethod:(kHttpMethodType) httpMethodType
                    withHttpHeaders:(NSMutableDictionary*) headers
                    withServiceName:(NSString*) serviceName
                     withParameters:(NSMutableDictionary*) params
                        withSuccess:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                        withFailure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSAssert(serviceName, ([NSString stringWithFormat:@"\n<------------------->\n%@\n%sn<------------------->",@"serviceName can't be nil",__PRETTY_FUNCTION__]));
    
    NSString *serviceUrl = [httpBaseURL stringByAppendingPathComponent:serviceName];
    
    if (headers == nil || headers.count==0)
    {
        NSDictionary *headers = [[NSDictionary alloc] initWithObjectsAndKeys:@"application/json",@"Accept",@"application/json; charset=utf-8",@"Content-Type",@"1.0",@"version",@"ios",@"os",nil];
        [self setHeaders:headers];
    }
    else
    {
        [headers setObject:@"application/json" forKey:@"Accept"];
        [headers setObject:@"application/json; charset=utf-8" forKey:@"Content-Type"];
        [headers setObject:@"1.0" forKey:@"version"];
        [headers setObject:@"ios" forKey:@"os"];
        [self setHeaders:headers];
    }
    
    if (params != nil)
        [self addQueryStringWithParams:params];
    
    switch (httpMethodType)
    {
        case kHttpMethodTypeGet:
        {
            [httpSessionManager GET:serviceUrl
                         parameters:params
                            success:^(NSURLSessionDataTask *task, id responseObject) {
                                
                                if ([self doesServiceHasAppFreezingMetaData:responseObject]) {
                                    
                                    return ;
                                }
                                
                                if (success != nil)
                                    success(task,responseObject);
                            }
                            failure:^(NSURLSessionDataTask *task, NSError *error) {
                                
                                NSHTTPURLResponse *res =(NSHTTPURLResponse *)task.response;
                                if (res.statusCode == 403) {
                                    [CommonFunctions showAlertViewForServiceMetaData:[NSDictionary dictionaryWithObjectsAndKeys:@"true",@"requireLogin", nil]];
                                    return ;
                                }
                                
                                if (failure != nil)
                                    failure(task,error);
                            }];
        }
            break;
        case kHttpMethodTypePost:
        {
            [httpSessionManager POST:serviceUrl
                          parameters:params
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 
                                 if ([self doesServiceHasAppFreezingMetaData:responseObject]) {
                                     
                                     return ;
                                 }
                                 
                                 if (success != nil)
                                     success(task,responseObject);
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 
                                 NSHTTPURLResponse *res =(NSHTTPURLResponse *)task.response;
                                 if (res.statusCode == 403) {
                                     [CommonFunctions showAlertViewForServiceMetaData:[NSDictionary dictionaryWithObjectsAndKeys:@"true",@"requireLogin", nil]];
                                     return ;
                                 }
                                 
                                 if (failure != nil)
                                     failure(task,error);
                             }];
        }
            break;
        case kHttpMethodTypeDelete:
        {
            [httpSessionManager DELETE:serviceUrl
                            parameters:params
                               success:^(NSURLSessionDataTask *task, id responseObject) {
                                   
                                   if ([self doesServiceHasAppFreezingMetaData:responseObject]) {
                                       
                                       return ;
                                   }
                                   
                                   if (success != nil)
                                       success(task,responseObject);
                               }
                               failure:^(NSURLSessionDataTask *task, NSError *error) {
                                   
                                   NSHTTPURLResponse *res =(NSHTTPURLResponse *)task.response;
                                   if (res.statusCode == 403) {
                                       [CommonFunctions showAlertViewForServiceMetaData:[NSDictionary dictionaryWithObjectsAndKeys:@"true",@"requireLogin", nil]];
                                       return ;
                                   }
                                   
                                   if (failure != nil)
                                       failure(task,error);
                               }];
        }
            break;
        case kHttpMethodTypePut:
        {
            [httpSessionManager PUT:serviceUrl
                         parameters:params
                            success:^(NSURLSessionDataTask *task, id responseObject) {
                                
                                if ([self doesServiceHasAppFreezingMetaData:responseObject]) {
                                    
                                    return ;
                                }
                                
                                if (success != nil)
                                    success(task,responseObject);
                            }
                            failure:^(NSURLSessionDataTask *task, NSError *error) {
                                
                                NSHTTPURLResponse *res =(NSHTTPURLResponse *)task.response;
                                if (res.statusCode == 403) {
                                    [CommonFunctions showAlertViewForServiceMetaData:[NSDictionary dictionaryWithObjectsAndKeys:@"true",@"requireLogin", nil]];
                                    return ;
                                }
                                
                                if (failure != nil)
                                    failure(task,error);
                            }];
        }
            break;
            
        default:
            break;
    }
}

- (void) startMultipartFormDataRequestWithHttpHeaders:(NSMutableDictionary*) headers
                                      withServiceName:(NSString*) serviceName
                                       withParameters:(NSMutableDictionary*) params
                                         withFileData:(NSArray*) files
                                          withSuccess:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                                          withFailure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSAssert(serviceName, ([NSString stringWithFormat:@"\n<------------------->\n%@\n%sn<------------------->",@"serviceName can't be nil",__PRETTY_FUNCTION__]));
    
    NSString *serviceUrl = [httpBaseURL stringByAppendingPathComponent:serviceName];
    
    if (headers == nil)
    {
        NSDictionary *headers = [[NSDictionary alloc] initWithObjectsAndKeys:@"multipart/form-data",@"Content-Type",nil];
        [self setHeaders:headers];
    }
    else
    {
        [headers setObject:@"multipart/form-data" forKey:@"Content-Type"];
        [self setHeaders:headers];
    }
    
    [httpSessionManager POST:serviceUrl
                  parameters:params
   constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
       
       for (NSData *fileData in files)
       {
           [formData appendPartWithFileData:fileData name:@"image" fileName:@"future.jpg" mimeType:@"image/jpeg"];
       }
   }
                     success:^(NSURLSessionDataTask *task, id responseObject) {
                         
                         if ([self doesServiceHasAppFreezingMetaData:responseObject]) {
                             
                             return ;
                         }
                         
                         if (success != nil)
                             success(task,responseObject);
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         
                         NSHTTPURLResponse *res =(NSHTTPURLResponse *)task.response;
                         if (res.statusCode == 403) {
                             [CommonFunctions showAlertViewForServiceMetaData:[NSDictionary dictionaryWithObjectsAndKeys:@"true",@"requireLogin", nil]];
                             return ;
                         }
                         
                         if (failure != nil)
                             failure(task,error);
                     }];
}

@end
