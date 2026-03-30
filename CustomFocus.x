#import <UIKit/UIKit.h>

// --- INTERFACES ---
@interface YTAppViewController : UIViewController
@end

@interface YTCompactVideoCell : UIView
@end

@interface YTSettingsSectionItem : NSObject
+ (instancetype)switchItemWithTitle:(NSString *)title titleDescription:(NSString *)titleDescription accessibilityIdentifier:(NSString *)accessibilityIdentifier switchOn:(BOOL)switchOn switchBlock:(BOOL (^)(id cell, BOOL enabled))switchBlock settingItemId:(int)settingItemId;
+ (instancetype)itemWithTitle:(NSString *)title accessibilityIdentifier:(NSString *)accessibilityIdentifier detailTextBlock:(NSString *(^)(void))detailTextBlock selectBlock:(BOOL (^)(id cell, NSUInteger arg1))selectBlock;
@end

@interface YTAlertView : UIView
+ (instancetype)confirmationDialogWithAction:(void (^)(void))action actionTitle:(NSString *)actionTitle cancelTitle:(NSString *)cancelTitle;
+ (instancetype)infoDialog;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
- (void)show;
@end

@interface YTSettingsPickerViewController : UIViewController
- (instancetype)initWithNavTitle:(NSString *)navTitle pickerSectionTitle:(NSString *)pickerSectionTitle rows:(NSArray *)rows selectedItemIndex:(NSUInteger)selectedItemIndex parentResponder:(id)parentResponder;
@end

@interface YTSettingsViewController : UIViewController
- (void)pushViewController:(UIViewController *)viewController;
- (void)setSectionItems:(NSMutableArray *)sectionItems forCategory:(NSUInteger)category title:(NSString *)title titleDescription:(NSString *)titleDescription headerHidden:(BOOL)headerHidden;
@end

// --- GLOBAL VARIABLES ---
static const NSInteger FocusSectionID = 888;
static NSMutableArray *blockedItems = nil;

// Helper function to read toggles
static BOOL focusBool(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

// Helper functions for the Lock
static BOOL isSettingsLocked() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lockDate = [defaults objectForKey:@"focus_lock_timestamp"];
    NSNumber *durationNum = [defaults objectForKey:@"focus_lock_duration_seconds"]; 
    
    if (lockDate && durationNum && [durationNum doubleValue] > 0) {
        NSTimeInterval timePassed = [[NSDate date] timeIntervalSinceDate:lockDate];
        if (timePassed < [durationNum doubleValue]) {
            return YES;
        } else {
            [defaults removeObjectForKey:@"focus_lock_timestamp"];
            [defaults removeObjectForKey:@"focus_lock_duration_seconds"];
            [defaults synchronize];
            return NO;
        }
    }
    return NO;
}

static int remainingLockMinutes() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lockDate = [defaults objectForKey:@"focus_lock_timestamp"];
    NSNumber *durationNum = [defaults objectForKey:@"focus_lock_duration_seconds"];
    NSTimeInterval timePassed = [[NSDate date] timeIntervalSinceDate:lockDate];
    return (int)(([durationNum doubleValue] - timePassed) / 60);
}


// --- 1. SETTINGS MENU INJECTION ---
%hook YTAppSettingsPresentationData
+ (NSArray *)settingsCategoryOrder {
    NSArray *order = %orig;
    NSMutableArray *mutableOrder = [order mutableCopy];
    NSUInteger insertIndex = [order indexOfObject:@(1)]; // 1 is usually the "General" tab
    if (insertIndex != NSNotFound) {
        [mutableOrder insertObject:@(FocusSectionID) atIndex:insertIndex + 1];
    }
    return mutableOrder;
}
%end

%hook YTSettingsSectionItemManager
- (void)updateSectionForCategory:(NSUInteger)category withEntry:(id)entry {
    if (category == FocusSectionID) {
        NSMutableArray *sectionItems = [NSMutableArray array];
        Class YTSettingsSectionItemClass = %c(YTSettingsSectionItem);
        YTSettingsViewController *settingsViewController = [self valueForKey:@"_settingsViewControllerDelegate"];

        // Toggle 1: Custom Blocks
        YTSettingsSectionItem *blockToggle = [YTSettingsSectionItemClass switchItemWithTitle:@"Enable Custom Blocks (.ytb)" titleDescription:@"Hides specified channels/titles" accessibilityIdentifier:@"FocusSectionItem" switchOn:focusBool(@"enableCustomFocusBlocker") switchBlock:^BOOL(id cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"enableCustomFocusBlocker"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            return YES;
        } settingItemId:0];
        [sectionItems addObject:blockToggle];

        // Toggle 2: App Delay
        YTSettingsSectionItem *delayToggle = [YTSettingsSectionItemClass switchItemWithTitle:@"Enable 10-Second Delay" titleDescription:@"Forces a delay on startup" accessibilityIdentifier:@"FocusSectionItem" switchOn:focusBool(@"enableAppDelay") switchBlock:^BOOL(id cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"enableAppDelay"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            return YES;
        } settingItemId:0];
        [sectionItems addObject:delayToggle];

        // Button: 1 Hour Lock
        YTSettingsSectionItem *lock1 = [YTSettingsSectionItemClass itemWithTitle:@"Lock Settings (1 Hour)" accessibilityIdentifier:@"FocusSectionItem" detailTextBlock:nil selectBlock:^BOOL (id cell, NSUInteger arg1) {
            if (isSettingsLocked()) {
                YTAlertView *alert = [%c(YTAlertView) infoDialog];
                alert.title = @"Locked";
                alert.subtitle = [NSString stringWithFormat:@"Time remaining: %d minutes", remainingLockMinutes()];
                [alert show];
                return NO;
            }
            YTAlertView *alertView = [%c(YTAlertView) confirmationDialogWithAction:^{
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:[NSDate date] forKey:@"focus_lock_timestamp"];
                [defaults setObject:@(3600) forKey:@"focus_lock_duration_seconds"]; 
                [defaults synchronize];
                [[UIApplication sharedApplication] performSelector:@selector(suspend)];
                [NSThread sleepForTimeInterval:1.0];
                exit(0); 
            } actionTitle:@"Lock Now" cancelTitle:@"Cancel"];
            alertView.title = @"Are you sure?";
            alertView.subtitle = @"You cannot change Focus settings for 1 hour.";
            [alertView show];
            return YES;
        }];
        [sectionItems addObject:lock1];

        [settingsViewController setSectionItems:sectionItems forCategory:FocusSectionID title:@"Focus Mode" titleDescription:@"Custom Distraction Blocker" headerHidden:NO];
        return;
    }
    %orig;
}
%end

// --- 2. THE FOCUS LOGIC (BLOCKER & DELAY) ---
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

%hook YTAppViewController
- (void)viewDidLoad {
    %orig;
    if (!focusBool(@"enableAppDelay")) return;

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

%hook YTCompactVideoCell
- (void)setModel:(id)model {
    %orig;
    if (!focusBool(@"enableCustomFocusBlocker")) return;
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
