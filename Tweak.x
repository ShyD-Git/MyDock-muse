#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define QA_LOG_PATH @"/var/mobile/Documents/QATestingUtils.log"

static void qaLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [formatter stringFromDate:[NSDate date]];
    NSString *line = [NSString stringWithFormat:@"[%@] %@\n", timeString, msg];
    
    // Ghi file bằng NSFileHandle an toàn
    static dispatch_queue_t logQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logQueue = dispatch_queue_create("com.qa.log", DISPATCH_QUEUE_SERIAL);
    });
    
    dispatch_async(logQueue, ^{
        if (![[NSFileManager defaultManager] fileExistsAtPath:QA_LOG_PATH]) {
            [line writeToFile:QA_LOG_PATH atomically:YES encoding:NSUTF8StringEncoding error:nil];
        } else {
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:QA_LOG_PATH];
            if (fileHandle) {
                [fileHandle seekToEndOfFile];
                [fileHandle writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
                [fileHandle closeFile];
            }
        }
    });
}

// --- 1. Bắt Network (Chỉ Log, không chặn ngầm để tránh crash) ---
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    qaLog(@"🚀 NET REQ: %@", request.URL.absoluteString);
    return %orig;
}
%end

// --- 2. Hook NSUserDefaults (Ép cờ Pro) ---
%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)defaultName {
    if ([defaultName.lowercaseString containsString:@"premium"] || 
        [defaultName.lowercaseString containsString:@"pro"] ||
        [defaultName.lowercaseString containsString:@"sub"] ||
        [defaultName.lowercaseString containsString:@"active"]) {
        qaLog(@"✅ Forced TRUE for UserDefaults: %@", defaultName);
        return YES;
    }
    return %orig;
}
%end

// --- 3. Hook UI An Toàn (Quét subview sau khi View hiện lên) ---
static void scanViewTree(UIView *view) {
    if (!view) return;
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            if ([label.text.lowercaseString containsString:@"dùng thử"] || 
                [label.text.lowercaseString containsString:@"nâng cấp"] ||
                [label.text.lowercaseString containsString:@"mua"]) {
                qaLog(@"👀 Tìm thấy text Paywall: %@", label.text);
            }
        }
        scanViewTree(subview);
    }
}

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    // Quét UI sau khi view đã load xong, không can thiệp vào animation
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        scanViewTree(self.view);
    });
}
%end

// --- 4. Quét Hàm Bool (Sửa lại bộ lọc class) ---
static void scanSwiftMethods(void) {
    unsigned int classCount = 0;
    Class *classes = objc_copyClassList(&classCount);
    if (!classes) return;

    for (unsigned int i = 0; i < classCount; i++) {
        Class cls = classes[i];
        NSString *className = NSStringFromClass(cls);
        
        // Chỉ quét class của app (thường bắt đầu bằng _TtC hoặc tên riêng), bỏ qua Apple
        if ([className hasPrefix:@"_TtC"] || [className.lowercaseString containsString:@"store"] || [className.lowercaseString containsString:@"user"]) {
            unsigned int methodCount = 0;
            Method *methods = class_copyMethodList(cls, &methodCount);
            if (!methods) continue;
            
            for (unsigned int j = 0; j < methodCount; j++) {
                Method method = methods[j];
                SEL selector = method_getName(method);
                NSString *methodName = NSStringFromSelector(selector);
                
                if ([methodName.lowercaseString containsString:@"premium"] || 
                    [methodName.lowercaseString containsString:@"pro"] || 
                    [methodName.lowercaseString containsString:@"active"]) {
                    
                    const char *types = method_getTypeEncoding(method);
                    if (types && (types[0] == 'c' || types[0] == 'B')) {
                        IMP newImp = imp_implementationWithBlock(^BOOL(id _self, ...) {
                            return YES;
                        });
                        method_setImplementation(method, newImp);
                        qaLog(@"✂️ Hooked Method: -[%@ %@]", className, methodName);
                    }
                }
            }
            free(methods);
        }
    }
    free(classes);
}

%ctor {
    // Xóa log cũ trước khi bắt đầu
    [[NSFileManager defaultManager] removeItemAtPath:QA_LOG_PATH error:nil];
    
    qaLog(@"=======================");
    qaLog(@"🚀 QATestingUtils Loaded!");
    qaLog(@"=======================");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        qaLog(@"Bắt đầu quét class...");
        scanSwiftMethods();
        qaLog(@"Quét class xong.");
    });
}
