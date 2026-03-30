#import <UIKit/UIKit.h>

@interface YTCompactVideoCell : UIView
@end

static NSMutableArray *blockedItems = nil;

// --- 1. READ & DECODE THE .YTB BLOCKLIST ---
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

// --- 2. PERMANENTLY HIJACK YTLITE SETTINGS ---
%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)defaultName {
    // These are the exact internal keys YTLite uses for the features you requested
    NSArray *forcedKeys = @[
        @"shortsToRegular",       // Converts Shorts to regular video player
        @"endScreenCards",        // Hides End screen hover cards
        @"noRelatedVids",         // No related videos in the overlay
        @"noRelatedWatchNexts"    // Hides related videos under the main player
    ];
    
    // If YTLite checks any of these keys, force the answer to YES permanently
    if ([forcedKeys containsObject:defaultName]) {
        return YES; 
    }
    
    // For all other normal settings, let the app read them normally
    return %orig(defaultName);
}
%end

// --- 3. CHANNEL & TITLE BLOCKER ---
%hook YTCompactVideoCell
- (void)setModel:(id)model {
    %orig;
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
