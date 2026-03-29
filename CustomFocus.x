#import "YTLite.h"
#import <UIKit/UIKit.h>

// --- TELL THE COMPILER WHAT THIS CLASS IS ---
// (YTAppViewController is already defined in YTLite.h, so we only need this one)
@interface YTCompactVideoCell : UIView
@end
// --------------------------------------------

static NSMutableArray *blockedItems = nil;

// --- 1. READ & DECODE THE .YTB FILE ---
%ctor {
    blockedItems = [[NSMutableArray alloc] init];
    NSString *bundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"YTLite.bundle"];
    NSBundle *tweakBundle = [NSBundle bundleWithPath:bundlePath];
    NSString *filePath = [tweakBundle pathForResource:@"blocklist" ofType:@"ytb"];
    
    if (filePath) {
        NSString *base64String = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        if (base64String) {
            NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
            if (decodedData) {
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:decodedData options:0 error:nil];
                if (jsonDict) {
                    NSString *channels = jsonDict[@"blockedChannels"];
                    NSString *titles = jsonDict[@"blockedTitles"];
                    if (channels) [blockedItems addObjectsFromArray:[channels componentsSeparatedByString:@"\n"]];
                    if (titles) [blockedItems addObjectsFromArray:[titles componentsSeparatedByString:@"\n"]];
                }
            }
        }
    }
}

// --- 2. 10-SECOND APP DELAY ---
%hook YTAppViewController
- (void)viewDidLoad {
    %orig;
    
    // Check if the user turned on the Delay toggle in the Focus Settings
    if (!ytlBool(@"enableAppDelay")) return;

    UIView *blockView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    blockView.backgroundColor = [UIColor blackColor];
    blockView.layer.zPosition = 9999;
    
    UILabel *label = [[UILabel alloc] initWithFrame:blockView.bounds];
    label.text = @"Focus. YouTube will open in 10 seconds...";
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:18];
    [blockView addSubview:label];
    [self.view addSubview:blockView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5 animations:^{
            blockView.alpha = 0;
        } completion:^(BOOL finished) {
            [blockView removeFromSuperview];
        }];
    });
}
%end

// --- 3. CHANNEL / TITLE BLOCKER ---
%hook YTCompactVideoCell
- (void)setModel:(id)model {
    %orig;
    
    // Check if the user turned on the Custom Blocker toggle in the Focus Settings
    if (!ytlBool(@"enableCustomFocusBlocker")) return;
    if (!blockedItems || blockedItems.count == 0) return;
    
    @try {
        UILabel *subtitleLabel = [self valueForKey:@"_subtitleLabel"];
        UILabel *titleLabel = [self valueForKey:@"_titleLabel"];
        NSString *subText = subtitleLabel.text.lowercaseString;
        NSString *titleText = titleLabel.text.lowercaseString;
        
        for (NSString *keyword in blockedItems) {
            NSString *cleanKeyword = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].lowercaseString;
            if (cleanKeyword.length == 0) continue; 
            
            if ([subText containsString:cleanKeyword] || [titleText containsString:cleanKeyword]) {
                self.hidden = YES;
                self.frame = CGRectZero;
                break; 
            }
        }
    } @catch (NSException *e) {}
}
%end
