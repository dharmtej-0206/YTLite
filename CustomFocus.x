#import <Foundation/Foundation.h>

// --- PERMANENTLY HIJACK YTLITE SETTINGS ---
// This forces specific YouTube Plus options to remain ON permanently.

%hook NSUserDefaults

// Intercept boolean checks (ON/OFF switches)
- (BOOL)boolForKey:(NSString *)defaultName {
    NSArray *forcedKeys = @[
        @"shortsToRegular",       // Converts Shorts to regular player
        @"endScreenCards",        // Hides End screen hover cards
        @"noRelatedVids",         // No related videos in the overlay
        @"noRelatedWatchNexts"    // Hides related videos under the main player
    ];
    
    if ([forcedKeys containsObject:defaultName]) {
        return YES; 
    }
    return %orig(defaultName);
}

// Intercept object checks (In case YTLite asks for the data object directly)
- (id)objectForKey:(NSString *)defaultName {
    NSArray *forcedKeys = @[
        @"shortsToRegular",       
        @"endScreenCards",        
        @"noRelatedVids",         
        @"noRelatedWatchNexts"    
    ];
    
    if ([forcedKeys containsObject:defaultName]) {
        return @YES; 
    }
    return %orig(defaultName);
}

%end
