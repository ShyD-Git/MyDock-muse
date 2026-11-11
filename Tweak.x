#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Hàm ghi log ra file cho Filza đọc
static void qaLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSString *logPath = @"/var/mobile/Documents/QATestingUtils.log";
    NSString *timestamp = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    NSString *line = [NSString stringWithFormat:@"[%@] %@\n", timestamp, msg];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
    if (fileHandle == nil) {
        [line writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    } else {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    }
}

// --- 1. Hook Bắt Request Mạng ---
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    qaLog(@"🚀 NET REQ: %@", request.URL.absoluteString);
    
    if ([request.URL.absoluteString containsString:@"verify"] || [request.URL.absoluteString containsString:@"receipt"] || [request.URL.absoluteString containsString:@"purchase"]) {
        qaLog(@"🛑 BLOCKED & MOCKED: %@", request.URL.absoluteString);
        
        NSString *fakeJSON = @"{\"status\":\"success\",\"is_premium\":true,\"expires\":\"2099-12-31\"}";
        NSData *fakeData = [fakeJSON dataUsingEncoding:NSUTF8StringEncoding];
        NSHTTPURLResponse *fakeResp = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{@"Content-Type":@"application/json"}];
        
        if (completionHandler) {
            completionHandler(fakeData, fakeResp, nil);
        }
        return %orig(request, ^(NSData *data, NSURLResponse *response, NSError *error){});
    }
    return %orig;
}
%end

// --- 2. Hook Thư viện RevenueCat ---
%hook RCPurchases
+ (instancetype)sharedPurchases {
    return %orig;
}
- (void)getCustomerInfoWithCompletionBlock:(void (^)(id customerInfo, NSError *error))completion {
    qaLog(@"🐱 RevenueCat Hooked - Mocking Entitlements");
    
    id info = [[objc_getClass("RCCustomerInfo") alloc] init];
    NSDictionary *fakeEntitlements = @{@"pro": @{@"isActive": @YES}, @"premium": @{@"isActive": @YES}};
    
    @try {
        [info setValue:fakeEntitlements forKey:@"entitlements"];
        [info setValue:@{@"pro": @{@"isActive": @YES}} forKey:@"_entitlements"];
    } @catch (NSException *e) {}

    if (completion) completion(info, nil);
}
%end

// --- 3. Quét hàm Bool (Bắt cả Swift) ---
static void scanSwiftMethods(void) {
    unsigned int classCount = 0;
    Class *classes = objc_copyClassList(&classCount);
    if (!classes) return;

    for (unsigned int i = 0; i < classCount; i++) {
        Class cls = classes[i];
        NSString *className = NSStringFromClass(cls);
        
        if ([className hasPrefix:@"_TtC"] || [className.lowercaseString containsString:@"pro"] || [className.lowercaseString containsString:@"store"] || [className.lowercaseString containsString:@"user"]) {
            unsigned int methodCount = 0;
            Method *methods = class_copyMethodList(cls, &methodCount);
            if (!methods) continue;
            
            for (unsigned int j = 0; j < methodCount; j++) {
                Method method = methods[j];
                SEL selector = method_getName(method);
                NSString *methodName = NSStringFromSelector(selector);
                
                if ([methodName.lowercaseString containsString:@"premium"] || 
                    [methodName.lowercaseString containsString:@"pro"] || 
                    [methodName.lowercaseString containsString:@"active"] ||
                    [methodName.lowercaseString containsString:@"sub"]) {
                    
                    const char *types = method_getTypeEncoding(method);
                    if (types && (types[0] == 'c' || types[0] == 'B')) {
                        IMP newImp = imp_implementationWithBlock(^BOOL(id _self, ...) {
                            return YES;
                        });
                        method_setImplementation(method, newImp);
                        qaLog(@"✂️ Swift Hook: -[%@ %@]", className, methodName);
                    }
                }
            }
            free(methods);
        }
    }
    free(classes);
}

%ctor {
    qaLog(@"=======================");
    qaLog(@"🚀 QATestingUtils Loaded!");
    qaLog(@"=======================");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        qaLog(@"Bắt đầu quét class...");
        scanSwiftMethods();
        qaLog(@"Quét xong.");
    });
}
