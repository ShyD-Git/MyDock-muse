// MyDock v2.9.11-clean - bản SẠCH (không ghi log). Khoảng 2 bên nút
// Dán lên 16pt (từ 12pt); các khoảng còn lại giữ 20pt. Dùng spacer:
// spacing chung 2.0, spacer 12pt kề nút Dán (2+12+2 = 16pt), spacer
// 16pt các khoảng khác (2+16+2 = 20pt).
// MyDock v2.9.10-clean - bản SẠCH (không ghi log) của v2.9.10.
// md_log() là no-op; mọi logic khác giữ nguyên.
// MyDock v2.9.10 - khoảng 2 bên nút Dán lên 12pt (từ 8pt); các khoảng
// còn lại giữ 20pt. Dùng spacer: spacing chung 2.0, spacer 8pt kề nút
// Dán (2+8+2 = 12pt), spacer 16pt các khoảng khác (2+16+2 = 20pt).
// MyDock v2.9.9 - tách 2 bên nút Dán ra chút cho cân đối: khoảng 2 bên
// nút Dán 2pt -> 8pt; các khoảng còn lại giữ 20pt (spacing chung 8.0 +
// spacer 4pt -> 8+4+8 = 20pt).
// MyDock v2.9.8 - thu hẹp khoảng trống 2 bên nút Dán còn 2pt bằng spacer
// (v2.9.6/2.9.7 setCustomSpacing KHÔNG có tác dụng: EqualSpacing ép mọi
// khoảng bằng nhau nên nó bỏ qua custom spacing. Cách mới: spacing chung
// 2.0 + chèn spacer trong suốt 16pt giữa 4 cặp còn lại → khoảng đó
// 2+16+2 = 20pt, còn 2 bên nút Dán chỉ 2pt.)
// MyDock v2.9.7 - thu hẹp khoảng trống 2 bên nút Dán còn 2pt (thay vì 20pt)
// để 6 icon còn lại gần vào; khoảng trống giữa 6 icon kia giữ nguyên 20pt.
// MyDock v2.9.5 - sửa lỗi icon của v2.9.4 (ảnh IMG_6063: nút Dán thành ô
// xám đặc, mất icon). Ép 28pt + clipsToBounds làm icon bị nén/cắt mất.
// Bỏ ép bề rộng, đổi stack sang EqualSpacing để nút Dán giữ cỡ tự nhiên
// 51pt mà không kéo các nút khác rộng theo — hàng nút vừa màn hình.
// MyDock v2.9.4 - bản LAI + sửa icon/kích thước (ảnh IMG_6060: hàng nút
// rộng quá, nút Undo/Dismiss bị cắt khỏi màn hình, nút Dán là ô xám to).
// Lai: ô text thật dùng nút hệ thống (không hỏi); ô trong trang web dùng
// cách dán cũ qua sendAction (sẽ hỏi một lần, nhưng dán được). Kích thước:
// ép nút Dán về 28pt (intrinsic 51pt làm FillEqually kéo cả hàng rộng quá).
// MyDock v2.9.3 - lọc target theo đúng class ô text thật + gán target từ
// lúc tạo nút. ChildView của Gecko cũng tuân thủ UITextInput nên lọc bằng
// protocol vẫn nhận nhầm nó; chỉ UITextField/UITextView mới được nhận.
// MyDock v2.9.2 - sửa chọn target (lỗi v2.9.1-diag tìm ra) + giữ log chẩn đoán.
// Target chỉ nhận ô nhập chữ thật (UITextInput): view thường như ChildView
// của Gecko tuy "tuân thủ" UIPasteConfigurationSupporting theo mặc định
// nhưng canPaste=NO nên nút không dán được. Thêm: thử nền trong suốt ở mức
// view cho nút (xám là vẻ ngoài mặc định, nút vẫn đang bật).
// MyDock v2.9.1-diag - bản CHẨN ĐOÁN, chỉ thêm log lúc bấm nút Dán.
// Log mới: tmp/MyDock291.log — ghi enabled của nút, ô đang focus, target,
// pasteConfiguration (nil hay không), hasStrings, số item trong bảng tạm,
// canPasteItemProviders, độ dài chữ trong ô trước/sau 0.5s. KHÔNG ghi nội
// dung chữ hay nội dung bảng tạm.
// MyDock v2.9 - nút Dán đổi sang nút dán hệ thống (UIPasteControl).
// v2.8: Undo / Copy / Select All / Paste / Dịch / Trích dẫn / Dismiss.
// v2.9: chỉ đổi nút Dán — bỏ nút tự vẽ gọi paste: qua sendAction (iOS
//  coi là app tự đọc bảng tạm nên hiện thông báo "Cho phép dán" mỗi
//  lần), thay bằng UIPasteControl của hệ thống (iOS 16+): bấm là dán
//  thẳng, iOS coi như chính người dùng bấm dán nên KHÔNG hiện thông báo.
//  Thứ tự 7 nút và mọi thứ khác giữ nguyên: FillEqually, spacing 20,
//  bottom -35, icon × 0.8, tag 9999, menu 6 loại dấu ở nút Trích dẫn.
//  Bản này là bản LOG (tmp/MyDock29.log): chỉ ghi loại dấu, độ dài đoạn
//  chọn, ngôn ngữ nhận diện, mã HTTP, thành/bại — KHÔNG ghi nội dung chữ
//  hay bản dịch.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <NaturalLanguage/NaturalLanguage.h>

// Khai báo tay thay vì kéo header Substrate, để khớp đúng symbol gốc dùng.
extern void MSHookMessageEx(Class _class, SEL message, IMP hook, IMP *old);

static IMP orig_layoutSubviews = NULL;
static const NSInteger kDockTag = 9999;

// Log chỉ ghi độ dài / mã trạng thái / thành bại — không bao giờ ghi nội dung chữ.
static void md_log(NSString *format, ...) {
    // CLEAN: không ghi log.
    (void)format;
}

static void triggerHapticFeedback(id self, SEL _cmd) {
    (void)self; (void)_cmd;
    UIImpactFeedbackGenerator *gen =
        [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [gen prepare];
    [gen impactOccurred];
}

static void sendEditAction(SEL action) {
    [[UIApplication sharedApplication] sendAction:action to:nil from:nil forEvent:nil];
}

// --- Tìm ô nhập đang focus + controller trên cùng để hiện bảng ---

static UIResponder *md_findFirstResponderInView(UIView *view) {
    if ([view isFirstResponder]) return (UIResponder *)view;
    for (UIView *sub in view.subviews) {
        UIResponder *r = md_findFirstResponderInView(sub);
        if (r) return r;
    }
    return nil;
}

static UIResponder *md_firstResponder(void) {
    for (UIWindow *w in [[UIApplication sharedApplication] windows]) {
        UIResponder *r = md_findFirstResponderInView(w);
        if (r) return r;
    }
    return nil;
}

static UIViewController *md_topViewController(void) {
    UIWindow *main = nil;
    for (UIWindow *w in [[UIApplication sharedApplication] windows]) {
        if (w.rootViewController) { main = w; break; }
    }
    if (!main) return nil;
    UIViewController *vc = main.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

static void md_presentAlert(NSString *title, NSString *message, NSString *copyText) {
    UIViewController *vc = md_topViewController();
    if (!vc) { md_log(@"alert: no top vc"); return; }
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    if (copyText) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Sao chép"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *a) {
            [[UIPasteboard generalPasteboard] setString:copyText];
            md_log(@"translate: copied to pasteboard");
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Đóng"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [vc presentViewController:alert animated:YES completion:nil];
}

static NSString *md_selectedText(void) {
    id responder = md_firstResponder();
    if (![responder conformsToProtocol:@protocol(UITextInput)]) return nil;
    id<UITextInput> input = (id<UITextInput>)responder;
    UITextRange *sel = [input selectedTextRange];
    if (!sel || sel.isEmpty) return nil;
    return [input textInRange:sel];
}

static NSString *md_langLabel(NSString *code) {
    if ([code isEqualToString:@"vi"]) return @"Việt";
    if ([code isEqualToString:@"en"]) return @"Anh";
    return code;
}

// --- Các nút cũ ---

static void didTapSelectAll(id self, SEL _cmd) {
    triggerHapticFeedback(self, _cmd);
    sendEditAction(@selector(selectAll:));
}

static void didTapCopy(id self, SEL _cmd) {
    triggerHapticFeedback(self, _cmd);
    sendEditAction(@selector(copy:));
}

static void didTapUndo(id self, SEL _cmd) {
    triggerHapticFeedback(self, _cmd);
    sendEditAction(@selector(undo:));
}

static void didTapDismiss(id self, SEL _cmd) {
    triggerHapticFeedback(self, _cmd);
    static Class implClass = Nil;
    if (!implClass) implClass = objc_getClass("UIKeyboardImpl");
    // Gọi qua objc_msgSend như bản gốc, vì activeInstance/dismissKeyboard
    // là API private, không có trong header công khai.
    id instance = ((id (*)(id, SEL))objc_msgSend)((id)implClass,
                                                  sel_registerName("activeInstance"));
    ((void (*)(id, SEL))objc_msgSend)(instance, sel_registerName("dismissKeyboard"));
}

// --- Nút Dán hệ thống (UIPasteControl, iOS 16+) ---
// Nút dán tự vẽ của v2.8 gọi paste: qua sendAction nên iOS coi là app
// tự đọc bảng tạm → hiện thông báo "Cho phép dán" mỗi lần. UIPasteControl
// là nút dán của hệ thống: bấm vào là dán thẳng, iOS coi như chính người
// dùng bấm dán nên KHÔNG hiện thông báo. Không cần target cố định — để
// nil thì nó tự dán vào ô đang focus; lúc chạm xuống (TouchDown) Em gán
// lại target là ô đang focus cho chắc.

static UIPasteControl *md_pasteControl = nil;
static __weak id md_pasteTarget = nil;

static void md_updatePasteTarget(id self, SEL _cmd) {
    (void)self; (void)_cmd;
    if (!md_pasteControl) return;
    UIResponder *fr = md_firstResponder();
    id target = nil;
    // v2.9.3: chỉ nhận đúng ô text thật (UITextField/UITextView). ChildView
    // của Gecko cũng tuân thủ UITextInput (để bàn phím gõ được vào trang
    // web) nên lọc bằng protocol vẫn nhận nhầm nó — nó từ chối dán
    // (canPaste=NO) nên nút không làm gì.
    if (fr && ([fr isKindOfClass:[UITextField class]] ||
               [fr isKindOfClass:[UITextView class]]) &&
        [fr conformsToProtocol:@protocol(UIPasteConfigurationSupporting)]) {
        target = fr;
    }
    md_pasteControl.target = target;
    if (target != (id)md_pasteTarget) {
        md_pasteTarget = target;
        md_log(@"paste: target=%@ fr=%@", target ? NSStringFromClass([target class]) : @"nil",
               fr ? NSStringFromClass([fr class]) : @"nil");
    }
}

static UIPasteControl *md_makePasteControl(id target) {
    UIPasteControlConfiguration *cfg = [[UIPasteControlConfiguration alloc] init];
    cfg.displayMode = UIPasteControlDisplayModeIconOnly;
    cfg.baseForegroundColor = [UIColor labelColor];
    cfg.baseBackgroundColor = [UIColor clearColor];
    UIPasteControl *pc = [[UIPasteControl alloc] initWithConfiguration:cfg];
    // v2.9.2: thử nền trong suốt ở mức view (cfg.baseBackgroundColor đã
    // trong suốt nhưng nút vẫn hiện xám — xem lớp nào vẽ nền).
    pc.backgroundColor = [UIColor clearColor];
    // v2.9.4: tint tối như các nút khác (configuration là readonly nên
    // chỉ gán được lúc khởi tạo; màu trong cấu hình có vẻ không được áp dụng
    // — icon vẫn sáng, nền vẫn xám — nên thử tintColor).
    pc.tintColor = [UIColor labelColor];
    // v2.9.5: BỎ ép 28pt + clipsToBounds của v2.9.4 — nó nén/cắt mất icon
    // (ảnh IMG_6063: nút thành ô xám đặc). Nút hệ thống giữ cỡ tự nhiên
    // 51pt thì icon mới hiện; hàng nút vừa màn hình nhờ EqualSpacing dưới.
    // Rung như các nút khác.
    [pc addTarget:target action:@selector(triggerHapticFeedback) forControlEvents:UIControlEventTouchUpInside];
    // Gán target lúc chạm xuống, trước khi nút thực hiện dán lúc nhả tay.
    [pc addTarget:target action:@selector(md_updatePasteTarget) forControlEvents:UIControlEventTouchDown];
    // Chẩn đoán: lúc nhả tay, ghi trạng thái nút / bảng tạm / ô đích / độ dài chữ.
    [pc addTarget:target action:@selector(md_diagPasteTap) forControlEvents:UIControlEventTouchUpInside];
    // v2.9.4 (bản lai): nếu nút hệ thống không có ô đích (đang ở trang web),
    // dán bằng cách cũ (sẽ hỏi "Cho phép dán" một lần, nhưng dán được).
    [pc addTarget:target action:@selector(md_fallbackPasteTap) forControlEvents:UIControlEventTouchUpInside];
    return pc;
}



// Tìm ô nhập chữ (UITextField/UITextView) trong cửa sổ chính — chỉ để ghi
// log bối cảnh, không dùng làm target (dán nhầm chỗ còn tệ hơn không dán).
static UIView *md_findTextFieldInView(UIView *view) {
    if ([view isKindOfClass:[UITextField class]] || [view isKindOfClass:[UITextView class]]) return view;
    for (UIView *sub in view.subviews) {
        UIView *r = md_findTextFieldInView(sub);
        if (r) return r;
    }
    return nil;
}

static NSString *md_windowTextFieldInfo(void) {
    for (UIWindow *w in [[UIApplication sharedApplication] windows]) {
        if (!w.rootViewController) continue;
        UIView *tf = md_findTextFieldInView(w);
        if (tf) {
            return [NSString stringWithFormat:@"%@ firstResponder=%d",
                    NSStringFromClass([tf class]), [tf isFirstResponder]];
        }
    }
    return @"nil";
}

// --- Chẩn đoán nút Dán (v2.9.1-diag): chạy lúc nhả tay, cùng lúc với haptic ---
// Ghi: nút có đang bật không, ô đang focus, target, pasteConfiguration nil
// hay không, bảng tạm có chữ không, số item, ô đích có nhận dán không, và
// độ dài chữ trong ô trước/sau 0.5s (chỉ đếm độ dài, không đọc nội dung).
static void md_diagPasteTap(id self, SEL _cmd) {
    (void)self; (void)_cmd;
    UIPasteControl *pc = md_pasteControl;
    if (!pc) { md_log(@"diag: no paste control"); return; }
    id target = pc.target;
    UIResponder *fr = md_firstResponder();
    BOOL hasStrings = [[UIPasteboard generalPasteboard] hasStrings];
    NSInteger items = [[UIPasteboard generalPasteboard] numberOfItems];
    BOOL canPaste = NO;
    BOOL hasPasteConfig = NO;
    BOOL isText = (fr && ([fr isKindOfClass:[UITextField class]] ||
                          [fr isKindOfClass:[UITextView class]]));
    if (target) {
        id<UIPasteConfigurationSupporting> sup = (id<UIPasteConfigurationSupporting>)target;
        hasPasteConfig = (sup.pasteConfiguration != nil);
        NSArray *providers = [[UIPasteboard generalPasteboard] itemProviders];
        canPaste = [sup canPasteItemProviders:providers];
    }
    NSUInteger beforeLen = 0;
    if (target && [target respondsToSelector:@selector(text)]) {
        NSString *t = [(id)target text];
        beforeLen = t.length;
    }
    md_log(@"diag: tap enabled=%d fr=%@ target=%@ pasteConfig=%d hasStrings=%d items=%ld canPaste=%d textLenBefore=%lu bounds=%@ isText=%d winText=%@",
           pc.enabled,
           fr ? NSStringFromClass([fr class]) : @"nil",
           target ? NSStringFromClass([target class]) : @"nil",
           hasPasteConfig, hasStrings, (long)items, canPaste,
           (unsigned long)beforeLen, NSStringFromCGRect(pc.bounds),
           isText, md_windowTextFieldInfo());
    id targetStrong = target;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NSUInteger afterLen = 0;
        if (targetStrong && [targetStrong respondsToSelector:@selector(text)]) {
            NSString *t = [(id)targetStrong text];
            afterLen = t.length;
        }
        md_log(@"diag: after 0.5s textLenAfter=%lu (before=%lu)",
               (unsigned long)afterLen, (unsigned long)beforeLen);
    });
}


// --- Bản lai v2.9.4: dán dự phòng cho ô trong trang web ---
// Nút hệ thống chỉ dán được vào ô text thật. Khi đang ở trang web
// (target=nil, nút hệ thống không làm gì), dán bằng cách cũ qua sendAction
// paste: — iOS sẽ hỏi "Cho phép dán" một lần, nhưng chữ sẽ vào được ô chat.
// Chỉ chạy khi bảng tạm có chữ (hasStrings, không gây hỏi) và nút hệ thống
// không có ô đích (để không dán trùng ở ô địa chỉ).
static void md_fallbackPasteTap(id self, SEL _cmd) {
    (void)self; (void)_cmd;
    UIPasteControl *pc = md_pasteControl;
    if (!pc) return;
    if (pc.target != nil) return; // ô text thật: nút hệ thống đã dán rồi.
    if (![[UIPasteboard generalPasteboard] hasStrings]) return;
    UIResponder *fr = md_firstResponder();
    md_log(@"diag: fallback paste fr=%@", fr ? NSStringFromClass([fr class]) : @"nil");
    sendEditAction(@selector(paste:));
}

// --- Nút Dịch: chỉ HIỆN bản dịch, không thay chữ gốc ---

static void didTapTranslate(id self, SEL _cmd) {
    triggerHapticFeedback(self, _cmd);
    NSString *text = md_selectedText();
    if (!text || text.length == 0) {
        md_log(@"translate: no selection");
        md_presentAlert(@"Chưa chọn chữ", @"Bôi đen đoạn chữ cần dịch rồi bấm lại.", nil);
        return;
    }
    if (text.length > 4000) {
        md_log(@"translate: too long len=%lu", (unsigned long)text.length);
        md_presentAlert(@"Đoạn chữ quá dài", @"Bôi đen đoạn ngắn hơn (dưới 4000 ký tự) rồi bấm lại.", nil);
        return;
    }
    // Nhận diện ngôn ngữ trên máy để chọn chiều dịch.
    NLLanguageRecognizer *rec = [[NLLanguageRecognizer alloc] init];
    [rec processString:text];
    NSString *detected = [rec dominantLanguage]; // @"vi" / @"en" / nil
    NSString *target = nil;
    if ([detected isEqualToString:@"vi"]) target = @"en";
    else if ([detected isEqualToString:@"en"]) target = @"vi";
    else target = @"vi";
    md_log(@"translate: len=%lu detected=%@ target=%@", (unsigned long)text.length,
           detected ?: @"?", target);

    NSURLComponents *comp = [[NSURLComponents alloc] init];
    comp.scheme = @"https";
    comp.host = @"translate.googleapis.com";
    comp.path = @"/translate_a/single";
    comp.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"client" value:@"gtx"],
        [NSURLQueryItem queryItemWithName:@"sl" value:@"auto"],
        [NSURLQueryItem queryItemWithName:@"tl" value:target],
        [NSURLQueryItem queryItemWithName:@"dt" value:@"t"],
        [NSURLQueryItem queryItemWithName:@"q" value:text],
    ];
    NSURL *url = comp.URL;
    if (!url) {
        md_log(@"translate: bad url");
        md_presentAlert(@"Không dịch được", @"Thử lại sau.", nil);
        return;
    }
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.timeoutInterval = 15.0;
    // Endpoint này hay chặn UA lạ — giả UA Safari trên iPhone.
    [req setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 16_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.3 Mobile/15E148 Safari/604.1"
        forHTTPHeaderField:@"User-Agent"];
    NSString *targetCopy = [target copy];
    NSString *detectedCopy = detected ? [detected copy] : nil;
    NSURLSessionDataTask *task =
        [[NSURLSession sharedSession] dataTaskWithRequest:req
                                        completionHandler:^(NSData *data, NSURLResponse *resp, NSError *error) {
        NSInteger status = [(NSHTTPURLResponse *)resp statusCode];
        if (error || !data) {
            md_log(@"translate: net fail status=%ld err=%@", (long)status,
                   error.localizedDescription ?: @"?");
            dispatch_async(dispatch_get_main_queue(), ^{
                md_presentAlert(@"Không dịch được", @"Kiểm tra mạng rồi thử lại.", nil);
            });
            return;
        }
        md_log(@"translate: http=%ld bytes=%lu", (long)status, (unsigned long)data.length);
        // Dạng trả về: [[["bản dịch","gốc",...],...],null,"en",...]
        NSString *translated = nil;
        NSString *srcLang = nil;
        NSError *jerr = nil;
        id root = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jerr];
        if ([root isKindOfClass:[NSArray class]] && [(NSArray *)root count] > 0) {
            id segs = [(NSArray *)root objectAtIndex:0];
            if ([segs isKindOfClass:[NSArray class]]) {
                NSMutableString *out = [NSMutableString string];
                for (id seg in (NSArray *)segs) {
                    if ([seg isKindOfClass:[NSArray class]] && [(NSArray *)seg count] > 0 &&
                        [[(NSArray *)seg objectAtIndex:0] isKindOfClass:[NSString class]]) {
                        [out appendString:[(NSArray *)seg objectAtIndex:0]];
                    }
                }
                if (out.length > 0) translated = [out copy];
            }
            if ([(NSArray *)root count] > 2 &&
                [[(NSArray *)root objectAtIndex:2] isKindOfClass:[NSString class]]) {
                srcLang = [(NSArray *)root objectAtIndex:2];
            }
        }
        if (!translated) {
            md_log(@"translate: parse fail");
            dispatch_async(dispatch_get_main_queue(), ^{
                md_presentAlert(@"Không dịch được", @"Google không trả về bản dịch, thử lại sau.", nil);
            });
            return;
        }
        NSString *from = srcLang ?: detectedCopy ?: @"?";
        NSString *title = [NSString stringWithFormat:@"Dịch (%@ → %@)",
                           md_langLabel(from), md_langLabel(targetCopy)];
        md_log(@"translate: ok from=%@ to=%@ outLen=%lu", from, targetCopy,
               (unsigned long)translated.length);
        dispatch_async(dispatch_get_main_queue(), ^{
            md_presentAlert(title, translated, translated);
        });
    }];
    [task resume];
}

// --- Nút Trích dẫn: 6 loại dấu, chọn trong menu ---

static void md_wrapSelection(NSString *open, NSString *close) {
    id responder = md_firstResponder();
    if (![responder conformsToProtocol:@protocol(UITextInput)]) return;
    id<UITextInput> input = (id<UITextInput>)responder;
    UITextRange *sel = [input selectedTextRange];
    if (!sel || sel.isEmpty) return;
    NSString *text = [input textInRange:sel];
    if (!text || text.length == 0) return;
    NSString *wrapped = [NSString stringWithFormat:@"%@%@%@", open, text, close];
    [input replaceRange:sel withText:wrapped];
    md_log(@"quote: wrapped %@ len=%lu", open, (unsigned long)text.length);
}

static void didTapQuote(id self, SEL _cmd) {
    triggerHapticFeedback(self, _cmd);
    id responder = md_firstResponder();
    if (![responder conformsToProtocol:@protocol(UITextInput)]) {
        md_log(@"quote: no input");
        md_presentAlert(@"Chưa chọn chữ", @"Bôi đen đoạn chữ cần thêm dấu rồi bấm lại.", nil);
        return;
    }
    id<UITextInput> input = (id<UITextInput>)responder;
    UITextRange *sel = [input selectedTextRange];
    if (!sel || sel.isEmpty) {
        md_log(@"quote: no selection");
        md_presentAlert(@"Chưa chọn chữ", @"Bôi đen đoạn chữ cần thêm dấu rồi bấm lại.", nil);
        return;
    }
    md_log(@"quote: menu shown");
    UIAlertController *sheet =
        [UIAlertController alertControllerWithTitle:@"Thêm dấu"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"\"...\"  Ngoặc kép"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *a) {
        md_wrapSelection(@"\"", @"\"");
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"*...*  Sao"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *a) {
        md_wrapSelection(@"*", @"*");
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"_..._  Gạch dưới"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *a) {
        md_wrapSelection(@"_", @"_");
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"`...`  Code"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *a) {
        md_wrapSelection(@"`", @"`");
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"-...-  Gạch ngang"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *a) {
        md_wrapSelection(@"-", @"-");
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"```...```  Khối code"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *a) {
        md_wrapSelection(@"```", @"```");
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Hủy"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    UIViewController *vc = md_topViewController();
    if (!vc) { md_log(@"quote: no top vc"); return; }
    [vc presentViewController:sheet animated:YES completion:nil];
}

// --- Tạo nút: có fallback nếu symbol chính không tồn tại trên máy ---

static UIImage *md_symbolImage(NSString *name, NSString *fallback,
                               UIImageSymbolConfiguration *cfg) {
    UIImage *img = [UIImage systemImageNamed:name withConfiguration:cfg];
    if (!img && fallback) {
        md_log(@"symbol fallback: %@ -> %@", name, fallback);
        img = [UIImage systemImageNamed:fallback withConfiguration:cfg];
    }
    return img;
}

static UIButton *dockButton(NSString *symbol, NSString *fallback, SEL action, id target) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    // v2.2: icon nhỏ hơn 20% — mốc là cỡ chữ mặc định của nút, nhân 0.8.
    CGFloat baseSize = button.titleLabel.font.pointSize;
    if (baseSize <= 0) baseSize = 17.0;
    UIImageSymbolConfiguration *cfg =
        [UIImageSymbolConfiguration configurationWithPointSize:baseSize * 0.8
                                                        weight:UIImageSymbolWeightRegular];
    UIImage *image = md_symbolImage(symbol, fallback, cfg);
    [button setImage:image forState:UIControlStateNormal];
    [button setTintColor:[UIColor labelColor]];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

// v2.9.8: spacer trong suốt, chỉ để tạo khoảng cách. Rộng 16pt, cao 20pt.
static UIView *md_spacer(CGFloat w) {
    UIView *v = [[UIView alloc] init];
    v.userInteractionEnabled = NO;
    v.backgroundColor = [UIColor clearColor];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [v.widthAnchor constraintEqualToConstant:w].active = YES;
    [v.heightAnchor constraintEqualToConstant:20.0].active = YES;
    return v;
}

static void hooked_layoutSubviews(id self, SEL _cmd) {
    // Gọi implementation gốc trước, đúng như bản gốc.
    ((void (*)(id, SEL))orig_layoutSubviews)(self, _cmd);

    // Đã gắn rồi thì thôi - chống nhân đôi khi layoutSubviews chạy lại.
    if ([self viewWithTag:kDockTag]) return;

    UIStackView *stack = [[UIStackView alloc] initWithFrame:CGRectZero];
    [stack setTag:kDockTag];
    [stack setAxis:UILayoutConstraintAxisHorizontal];
    // v2.9.5: EqualSpacing thay cho FillEqually. FillEqually ép 7 ô rộng
    // bằng nhau theo ô rộng nhất (nút Dán 51pt) → hàng 477pt, nút đầu/cuối
    // bị cắt. EqualSpacing giữ mỗi nút ở cỡ tự nhiên (nút thường ~20pt,
    // nút Dán 51pt) → hàng ~290pt, vừa màn hình, icon không bị nén.
    [stack setDistribution:UIStackViewDistributionEqualSpacing];
    [stack setAlignment:UIStackViewAlignmentCenter];
    // v2.9.11: spacing chung 2.0. Khoảng 2 bên nút Dán = 2 + spacer 12
    // + 2 = 16pt; 4 khoảng còn lại = 2 + spacer 16 + 2 = 20pt, giữ
    // nguyên. KHÔNG đặt width: stack rộng theo nội dung.
    [stack setSpacing:2.0];

    [stack addArrangedSubview:dockButton(@"arrow.uturn.backward", nil, @selector(didTapUndo), self)];
    [stack addArrangedSubview:md_spacer(16.0)];
    [stack addArrangedSubview:dockButton(@"doc.on.doc", nil, @selector(didTapCopy), self)];
    [stack addArrangedSubview:md_spacer(16.0)];
    [stack addArrangedSubview:dockButton(@"selection.pin.in.out", nil, @selector(didTapSelectAll), self)];
    [stack addArrangedSubview:md_spacer(12.0)];
    md_pasteControl = md_makePasteControl(self);
    // v2.9.3: gán target ngay lúc tạo nút (phòng trường hợp nút đọc target
    // trước lúc bấm); TouchDown vẫn gán lại mỗi lần chạm.
    md_updatePasteTarget(self, _cmd);
    [stack addArrangedSubview:md_pasteControl];
    md_log(@"paste: system control created enabled=%d bounds=%@", md_pasteControl.enabled, NSStringFromCGRect(md_pasteControl.bounds));
    [stack addArrangedSubview:md_spacer(12.0)];
    [stack addArrangedSubview:dockButton(@"character.bubble", @"arrow.left.arrow.right", @selector(didTapTranslate), self)];
    [stack addArrangedSubview:md_spacer(16.0)];
    [stack addArrangedSubview:dockButton(@"quote.opening", @"text.quote", @selector(didTapQuote), self)];
    [stack addArrangedSubview:md_spacer(16.0)];
    [stack addArrangedSubview:dockButton(@"keyboard.chevron.compact.down", nil, @selector(didTapDismiss), self)];

    // v2.9.8: setCustomSpacing đã BỎ (EqualSpacing bỏ qua nó - đã chứng
    // minh bằng log v2.9.7). Khoảng 2 bên nút Dán = spacing chung 2.0;
    // 4 khoảng còn lại = 2 + spacer 16 + 2 = 20pt, giữ nguyên.

    [self addSubview:stack];
    [stack setTranslatesAutoresizingMaskIntoConstraints:NO];

    // Chỉ centerX + bottom -35 (was -23) như bản gốc. Không có widthAnchor.
    NSLayoutConstraint *centerConstraint =
        [[stack centerXAnchor] constraintEqualToAnchor:[self centerXAnchor]];
    NSLayoutConstraint *bottomConstraint =
        [[stack bottomAnchor] constraintEqualToAnchor:[self bottomAnchor] constant:-35.0];
    [centerConstraint setActive:YES];
    [bottomConstraint setActive:YES];
}

__attribute__((constructor))
static void MyDock_init(void) {
    Class dockClass = objc_getClass("UIKeyboardDockView");
    if (!dockClass) return;
    MSHookMessageEx(dockClass, @selector(layoutSubviews),
                    (IMP)hooked_layoutSubviews, &orig_layoutSubviews);
    class_addMethod(dockClass, @selector(triggerHapticFeedback),
                    (IMP)triggerHapticFeedback, "v@:");
    class_addMethod(dockClass, @selector(didTapSelectAll),
                    (IMP)didTapSelectAll, "v@:");
    class_addMethod(dockClass, @selector(didTapCopy),
                    (IMP)didTapCopy, "v@:");
    class_addMethod(dockClass, @selector(md_updatePasteTarget),
                    (IMP)md_updatePasteTarget, "v@:");
    class_addMethod(dockClass, @selector(md_diagPasteTap),
                    (IMP)md_diagPasteTap, "v@:");
    class_addMethod(dockClass, @selector(md_fallbackPasteTap),
                    (IMP)md_fallbackPasteTap, "v@:");
    class_addMethod(dockClass, @selector(didTapUndo),
                    (IMP)didTapUndo, "v@:");
    class_addMethod(dockClass, @selector(didTapDismiss),
                    (IMP)didTapDismiss, "v@:");
    class_addMethod(dockClass, @selector(didTapTranslate),
                    (IMP)didTapTranslate, "v@:");
    class_addMethod(dockClass, @selector(didTapQuote),
                    (IMP)didTapQuote, "v@:");
    md_log(@"init: MyDock v2.9.10 loaded");
}
