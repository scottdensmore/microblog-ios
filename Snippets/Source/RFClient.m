//
//  RFClient.m
//  Snippets
//
//  Created by Manton Reece on 8/21/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFClient.h"

#import "NSString+Extras.h"
#import "SSKeychain.h"
#import "RFAccount.h"

@implementation RFClient

- (instancetype) initWithPath:(NSString *)path
{
	self = [super init];
	if (self) {
		self.path = path;
		self.url = [NSString stringWithFormat:@"%@%@", [RFClient serverHostnameWithScheme], self.path];
	}
	
	return self;
}

- (instancetype) initWithFormat:(NSString *)path, ...
{
	self = [super init];
	if (self) {
		va_list args;
		va_start (args, path);
		self.path = [[NSString alloc] initWithFormat:path arguments:args];
		self.url = [NSString stringWithFormat:@"%@%@", [RFClient serverHostnameWithScheme], self.path];
	}
	
	return self;
}

+ (NSString *) serverHostnameWithScheme
{
	return @"https://micro.blog";
//	return @"http://localhost:3000";
}

+ (NSString *) serverHostname
{
		return @"micro.blog";
//		return @"localhost";
}

+ (NSURLRequest *) authorizedRequestWithURL:(NSString *)url
{
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	
	RFAccount* a = [RFAccount defaultAccount];
	if (a) {
		NSString* token = [a password];
		if (token) {
			NSString* auth = [NSString stringWithFormat:@"Bearer %@", token];
			[request addValue:auth forHTTPHeaderField:@"Authorization"];
		}
	}
	
	return request;
}

- (void) setupRequest:(UUHttpRequest *)request
{
	NSMutableDictionary* headers = [request.headerFields mutableCopy];
	if (headers == nil) {
		headers = [NSMutableDictionary dictionary];
	}
	
	RFAccount* a = [RFAccount defaultAccount];
	if (a) {
		NSString* token = [a password];
		if (token) {
			[headers setObject:[NSString stringWithFormat:@"Bearer %@", token] forKey:@"Authorization"];
		}
		request.headerFields = headers;
	}

	request.shouldHandleCookies = NO;
}

#pragma mark -

- (UUHttpRequest *) getWithQueryArguments:(NSDictionary *)args completion:(void (^)(UUHttpResponse* response))handler
{
	UUHttpRequest* request = [UUHttpRequest getRequest:self.url queryArguments:args];
	[self setupRequest:request];
	
	return [UUHttpSession executeRequest:request completionHandler:handler];
}

#pragma mark -

- (UUHttpRequest *) postWithParams:(NSDictionary *)params completion:(void (^)(UUHttpResponse* response))handler
{
	NSMutableString* body_s = [NSMutableString string];
	
	NSArray* all_keys = [params allKeys];
	for (int i = 0; i < [all_keys count]; i++) {
		NSString* key = [all_keys objectAtIndex:i];
		BOOL added_param = NO;
		
		if ([params[key] isKindOfClass:[NSString class]]) {
			NSString* val = params[key];
			NSString* val_encoded = [val rf_urlEncoded];
			[body_s appendFormat:@"%@=%@", key, val_encoded];
			added_param = YES;
		}
		else if ([params[key] isKindOfClass:[NSNumber class]]) {
			NSNumber* val = params[key];
			[body_s appendFormat:@"%@=%@", key, val];
			added_param = YES;
		}
		else if ([params[key] isKindOfClass:[NSArray class]]) {
			NSArray* array_values = params[key];
			for (int array_i = 0; array_i < [array_values count]; array_i++) {
				NSString* val = [array_values objectAtIndex:array_i];
				NSString* val_encoded = [val rf_urlEncoded];
				[body_s appendFormat:@"%@=%@", key, val_encoded];
				if (array_i != ([array_values count] - 1)) {
					[body_s appendString:@"&"];
				}
				added_param = YES;
			}
		}

		if (added_param && (i != ([all_keys count] - 1))) {
			[body_s appendString:@"&"];
		}
	}
	
	NSData* d = [body_s dataUsingEncoding:NSUTF8StringEncoding];
	UUHttpRequest* request = [UUHttpRequest postRequest:self.url queryArguments:nil body:d contentType:@"application/x-www-form-urlencoded"];
	[self setupRequest:request];

	return [UUHttpSession executeRequest:request completionHandler:handler];
}

- (UUHttpRequest *) postWithObject:(id)object completion:(void (^)(UUHttpResponse* response))handler
{
	return [self postWithObject:object queryArguments:nil completion:handler];
}

- (UUHttpRequest *) postWithObject:(id)object queryArguments:(NSDictionary *)args completion:(void (^)(UUHttpResponse* response))handler
{
	NSData* d;
	if (object) {
		d = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
	}
	else {
		d = [NSData data];
	}

	UUHttpRequest* request = [UUHttpRequest postRequest:self.url queryArguments:args body:d contentType:@"application/json"];
	[self setupRequest:request];

	return [UUHttpSession executeRequest:request completionHandler:handler];
}

#pragma mark -

- (UUHttpRequest *) putWithObject:(id)object completion:(void (^)(UUHttpResponse* response))handler
{
	NSData* d;
	if (object) {
		d = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
	}
	else {
		d = [NSData data];
	}

	UUHttpRequest* request = [UUHttpRequest putRequest:self.url queryArguments:nil body:d contentType:@"application/json"];
	[self setupRequest:request];

	return [UUHttpSession executeRequest:request completionHandler:handler];
}

- (UUHttpRequest *) uploadFileData:(NSData *)imageData named:(NSString *)imageName filename:(NSString *)filename contentType:(NSString *)contentType httpMethod:(NSString *)method queryArguments:(NSDictionary *)args completion:(void (^)(UUHttpResponse* response))handler
{
	NSString* boundary = [[NSProcessInfo processInfo] globallyUniqueString];
	NSMutableData* d = [NSMutableData data];

	for (NSString* k in [args allKeys]) {
		NSString* val = [args objectForKey:k];
		[d appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[d appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", k] dataUsingEncoding:NSUTF8StringEncoding]];
		[d appendData:[[NSString stringWithFormat:@"%@\r\n", val] dataUsingEncoding:NSUTF8StringEncoding]];
	}

	if (imageData) {
		[d appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[d appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", imageName, filename] dataUsingEncoding:NSUTF8StringEncoding]];
		[d appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", contentType] dataUsingEncoding:NSUTF8StringEncoding]];
		[d appendData:imageData];
		[d appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	}

	[d appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	UUHttpRequest* request;
	
	if ([[method uppercaseString] isEqualToString:@"PUT"]) {
		request = [UUHttpRequest putRequest:self.url queryArguments:nil body:d contentType:@"application/json"];
	}
	else {
		request = [UUHttpRequest postRequest:self.url queryArguments:nil body:d contentType:@"application/json"];
	}
	[self setupRequest:request];
	
	NSString* content_type = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	NSMutableDictionary* headers = [request.headerFields mutableCopy];
	[headers setObject:content_type forKey:@"Content-Type"];
	request.headerFields = headers;

	return [UUHttpSession executeRequest:request completionHandler:handler];
}

- (UUHttpRequest *) uploadImageData:(NSData *)imageData named:(NSString *)imageName filename:(NSString *)filename httpMethod:(NSString *)method queryArguments:(NSDictionary *)args completion:(void (^)(UUHttpResponse* response))handler
{
	NSString* content_type;
	
	if ([[filename pathExtension] isEqualToString:@"png"]) {
		content_type = @"image/png";
	}
	else {
		content_type = @"image/jpeg";
	}
	
	return [self uploadFileData:imageData named:imageName filename:filename contentType:content_type httpMethod:method queryArguments:args completion:handler];
}

- (UUHttpRequest *) uploadVideoData:(NSData *)videoData named:(NSString *)imageName httpMethod:(NSString *)method queryArguments:(NSDictionary *)args completion:(void (^)(UUHttpResponse* response))handler
{
	return [self uploadFileData:videoData named:imageName filename:@"video.mov" contentType:@"video/mov" httpMethod:method queryArguments:args completion:handler];
}

#pragma mark -

- (UUHttpRequest *) deleteWithObject:(id)object completion:(void (^)(UUHttpResponse* response))handler
{
	return [self deleteWithObject:object queryArguments:nil completion:handler];
}

- (UUHttpRequest *) deleteWithObject:(id)object queryArguments:(NSDictionary *)args completion:(void (^)(UUHttpResponse* response))handler
{
	NSData* d;
	if (object) {
		d = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
	}
	else {
		d = [NSData data];
	}

	UUHttpRequest* request = [UUHttpRequest deleteRequest:self.url queryArguments:args body:d contentType:@"application/json"];
	[self setupRequest:request];

	return [UUHttpSession executeRequest:request completionHandler:handler];
}

@end
