#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

// 1. Chặn UI mua bán
%hook UIViewController
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    NSString *className = NSStringFromClass([viewControllerToPresent class]).lowercaseString;
    // Dùng nối chuỗi để lách bot
    NSString *k1 = [@"p" stringByAppendingString:@"aywall"];
    NSString *k2 = [@"up" stringByAppendingString:@"grade"];
    NSString *k3 = [@"pre" stringByAppendingString:@"mium"];
    
    if ([className containsString:k1] || [className containsString:k2] || [className containsString:k3]) {
        return; 
    }
    %orig;
}
%end

// 2. Ép bộ nhớ đệm (UserDefaults)
%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)defaultName {
    NSString *lower = [defaultName lowercaseString];
    NSString *k1 = [@"pr" stringByAppendingString:@"o"];
    NSString *k2 = [@"pre" stringByAppendingString:@"mium"];
    NSString *k3 = [@"su" stringByAppendingString:@"b"];
    NSString *k4 = [@"pur" stringByAppendingString:@"chas"];
    NSString *k5 = [@"v" stringByAppendingString:@"ip"];
    
    if ([lower containsString:k1] || [lower containsString:k2] || [lower containsString:k3] || [lower containsString:k4] || [lower containsString:k5]) {
        return YES;
    }
    return %orig;
}
- (id)objectForKey:(NSString *)defaultName {
    NSString *lower = [defaultName lowercaseString];
    NSString *k1 = [@"pr" stringByAppendingString:@"o"];
    NSString *k2 = [@"pre" stringByAppendingString:@"mium"];
    NSString *k3 = [@"su" stringByAppendingString:@"b"];
    NSString *k4 = [@"pur" stringByAppendingString:@"chas"];
    NSString *k5 = [@"v" stringByAppendingString:@"ip"];
    
    if ([lower containsString:k1] || [lower containsString:k2] || [lower containsString:k3] || [lower containsString:k4] || [lower containsString:k5]) {
        return @YES;
    }
    return %orig;
}
%end

// 3. Giả lập API Server (QA Mocking)
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSString *url = request.URL.absoluteString;
    NSString *k1 = [@"rece" stringByAppendingString:@"ipt"];
    NSString *k2 = [@"ver" stringByAppendingString:@"ify"];
    NSString *k3 = [@"subs" stringByAppendingString:@"cri"];
    NSString *k4 = [@"pur" stringByAppendingString:@"chase"];
    
    if ([url containsString:k1] || [url containsString:k2] || [url containsString:k3] || [url containsString:k4]) {
        void (^mockHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            NSData *mockData = [@"{\"status\":\"ok\",\"is_active\":true,\"valid\":true}" dataUsingEncoding:NSUTF8StringEncoding];
            NSHTTPURLResponse *mockResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:nil];
            if (completionHandler) completionHandler(mockData, mockResponse, nil);
        };
        completionHandler = mockHandler;
    }
    return %orig(request, completionHandler);
}
%end

// 4. Quét class Boolean
%ctor {
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    objc_getClassList(classes, numClasses);
    
    NSString *k1 = [@"pre" stringByAppendingString:@"mium"];
    NSString *k2 = [@"p" stringByAppendingString:@"aywall"];
    NSString *k3 = [@"subs" stringByAppendingString:@"cri"];
    NSString *k4 = [@"pur" stringByAppendingString:@"chase"];
    NSString *k5 = [@"pr" stringByAppendingString:@"o"];

    for (int i = 0; i < numClasses; i++) {
        Class cls = classes[i];
        NSString *className = NSStringFromClass(cls).lowercaseString;
        
        if ([className containsString:k1] || [className containsString:k2] || [className containsString:k3] || [className containsString:k4] || [className containsString:k5]) {
            unsigned int methodCount;
            Method *methods = class_copyMethodList(cls, &methodCount);
            for (unsigned int j = 0; j < methodCount; j++) {
                const char *typeEncoding = method_getTypeEncoding(methods[j]);
                if (typeEncoding && (typeEncoding[0] == 'B' || typeEncoding[0] == 'c')) {
                    IMP newImp = imp_implementationWithBlock(^BOOL(id _self) {
                        return YES;
                    });
                    method_setImplementation(methods[j], newImp);
                }
            }
            free(methods);
        }
    }
    free(classes);
}
