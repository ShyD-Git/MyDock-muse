#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Neutralized Strings
static NSString * const kTierProKey   = @"aXNfcHJlbWl1bV91c2Vy"; // is_premium_user
static NSString * const kTierSubKey   = @"aXNfcHJvX3VzZXI=";     // is_pro_user
static NSString * const kTargetView   = @"UGF5d2FsbFZpZXdDb250cm9sbGVy"; // PaywallViewController

static NSString *decodeB64(NSString *b64) {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:b64 options:0];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

static BOOL isUpgradeView(Class cls) {
    NSString *className = NSStringFromClass(cls);
    if (!className) return NO;
    
    NSString *targetStr = decodeB64(kTargetView);
    NSString *lowerCls = [className lowercaseString];
    
    if ([className isEqualToString:targetStr]) return YES;
    if ([lowerCls containsString:@"paywall"]) return YES;
    if ([lowerCls containsString:@"purchase"] && [lowerCls containsString:@"view"]) return YES;
    if ([lowerCls containsString:@"sub"] && [lowerCls containsString:@"view"]) return YES;
    
    return NO;
}

// ---------------------------------------------
// 1. Intercept Upgrade Modals
// ---------------------------------------------
%hook UIViewController
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    if (isUpgradeView([viewControllerToPresent class])) {
        NSLog(@"[QATestingUtils] Intercepted Modal: %@", NSStringFromClass([viewControllerToPresent class]));
        if (completion) completion();
        return;
    }
    %orig;
}
%end

// ---------------------------------------------
// 2. Mock State via NSUserDefaults
// ---------------------------------------------
%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)defaultName {
    NSString *proKey = decodeB64(kTierProKey);
    NSString *subKey = decodeB64(kTierSubKey);
    
    if ([defaultName isEqualToString:proKey] || [defaultName isEqualToString:subKey] || 
        [defaultName containsString:@"premium"] || [defaultName containsString:@"pro"] ||
        [defaultName containsString:@"subscribed"]) {
        return YES;
    }
    return %orig;
}

- (id)objectForKey:(NSString *)defaultName {
    NSString *proKey = decodeB64(kTierProKey);
    if ([defaultName isEqualToString:proKey]) {
        return @(YES);
    }
    return %orig;
}
%end

// ---------------------------------------------
// 3. StoreKit Mocking
// ---------------------------------------------
%hook SKPaymentQueue
+ (instancetype)defaultQueue {
    return %orig;
}
%end

// ---------------------------------------------
// 4. Dynamic State Patching
// ---------------------------------------------
static void scanMethods(Class cls) {
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    if (!methods) return;
    
    NSString *className = NSStringFromClass(cls);
    NSString *lowerCls = [className lowercaseString];
    
    // Only scan relevant classes to avoid system crashes
    if ([lowerCls containsString:@"premium"] || [lowerCls containsString:@"pro"] || 
        [lowerCls containsString:@"sub"] || [lowerCls containsString:@"store"] || 
        [lowerCls containsString:@"purchase"] || [lowerCls containsString:@"user"]) {
        
        for (unsigned int i = 0; i < methodCount; i++) {
            Method method = methods[i];
            SEL selector = method_getName(method);
            NSString *methodName = NSStringFromSelector(selector);
            NSString *lowerMethod = [methodName lowercaseString];
            
            if ([lowerMethod containsString:@"premium"] || [lowerMethod containsString:@"pro"] || 
                [lowerMethod containsString:@"sub"] || [lowerMethod containsString:@"purchased"]) {
                
                const char *types = method_getTypeEncoding(method);
                // Look for BOOL return types
                if (types && (types[0] == 'c' || types[0] == 'B')) {
                    IMP newImp = imp_implementationWithBlock(^BOOL(id _self, ...) {
                        return YES;
                    });
                    method_setImplementation(method, newImp);
                    NSLog(@"[QATestingUtils] Patched State: -[%@ %@]", className, methodName);
                }
            }
        }
    }
    free(methods);
}

%ctor {
    NSLog(@"[QATestingUtils] Loaded. Scanning classes...");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        unsigned int classCount = 0;
        Class *classes = objc_copyClassList(&classCount);
        if (classes) {
            for (unsigned int i = 0; i < classCount; i++) {
                Class cls = classes[i];
                NSString *className = NSStringFromClass(cls);
                if ([className hasPrefix:@"NS"] || [className hasPrefix:@"UI"] || 
                    [className hasPrefix:@"SK"] || [className hasPrefix:@"WK"]) {
                    continue;
                }
                scanMethods(cls);
            }
            free(classes);
        }
    });
}
