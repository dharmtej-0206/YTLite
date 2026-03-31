#import <UIKit/UIKit.h>

// --- THE MISSING NAMETAG ---
@interface YTPivotBarItemView : UIView
@end

// --- 1. YOUR FULL BLOCKLIST ---
static NSArray *getBlockedKeywords() {
    return @[
        // Keywords & Titles
        @"phonk", @"funk", @"slowed", @"music", @"sempero", @"teconci",
        
        // Blocked Channels
        @"mrbeast", @"career247", @"studyiq ias", @"neon man", @"purav jha", 
        @"neon man sports", @"lakshay chaudhary", @"abhi and niyu", @"t-series", 
        @"neuzboy", @"ashish chanchlani vines", @"tanmay bhat", @"hindi rush", 
        @"india's got latent clips", @"samay raina", @"carryminati", @"ishowspeed", 
        @"varun mayya", @"aevy tv", @"finance with sharan", @"breakdown", 
        @"ryan george extra plus!", @"ryan george", @"mohak mangal", @"cinedesi", 
        @"rapid info", @"techlinked", @"linus tech tips", @"shortcircuit", @"memapur", 
        @"memapur 2.0", @"sourav joshi vlogs", @"risen ai", @"mr. indian hacker", 
        @"thugesh", @"thugesh unfiltered", @"open letter", @"dhruv rathee", 
        @"𝗀𝖾𝗍 𝗌𝖾𝗍 𝖿𝗅𝗒 𝗌𝖼𝗂𝖾𝗇𝖼𝖾", @"techwiser", @"sillycorns", @"think school", 
        @"mr techpedia", @"nitish rajput", @"gyan therapy", @"aye jude", 
        @"prasadtechintelugu", @"beebom", @"trakin tech", @"the deshbhakt", 
        @"mrwhosetheboss", @"hamza", @"thegoodvibe", @"andromeda - topic", @"mxzi", 
        @"zombr3x", @"sma$hеr", @"flame runner - topic", @"zombr3x - topic", 
        @"jmilton - topic", @"repsaj - topic", @"mgd - topic", @"khaos - topic", 
        @"sma$her - topic", @"mxzi - topic", @"cape - topic", @"torbahed - topic", 
        @"ogryzek - topic", @"trxshbxy - topic", @"ncts - topic", @"fennecxx - topic", 
        @"sayfalse - topic", @"h6itam - topic", @"eternxlkz", @"dj fku - topic", 
        @"dj asul - topic", @"kendrick lamar", @"sabrina carpenter", @"camila cabello", 
        @"shawn mendes", @"one direction", @"wham!", @"sia", @"stephen sanchez", 
        @"publictheband", @"powfu", @"passenger", @"charlie puth", @"onedirectionvevo", 
        @"wiz khalifa music", @"publicvevo", @"alan walker", @"stephensanchezvevo", 
        @"onerepublicvevo", @"green planet lyrics", @"coldplay", @"netflix india", 
        @"dog story", @"zaynvevo", @"neon lyrics", @"glassanimalsvevo", 
        @"aviciiofficialvevo", @"billieeilishvevo", @"thescriptvevo", @"selina lyrics", 
        @"lanadelreyvevo", @"khalidvevo", @"justinbiebervevo", @"bluenight audio", 
        @"pop mage", @"ragnbonemanvevo", @"jonas blue", @"5sos", @"panic! at the disco", 
        @"the score", @"republic records", @"riot games music", @"2wei", @"suka.", 
        @"phant x", @"alpha phonk", @"unstoppable music", @"𝔭𝔥𝔬𝔫𝔨", @"mafia", 
        @"mtheo 785 (1)", @"youssey music", @"mrl", @"ashreveal", @"ro ransom - topic", 
        @"trillyrap", @"7clouds", @"urban paradise", @"pizza music", @"vibe music", 
        @"syrebralvibes", @"dan music", @"solitude songs", @"mikomikei", 
        @"alone candy music", @"7clouds rock", @"latinhype", @"arcade music", 
        @"billion stars", @"tried&refused productions.", @"lynling lyrics", 
        @"pop artist", @"lost panda", @"ignite", @"unique sound", @"music and song 3", 
        @"7clouds chill", @"cakes & eclairs", @"escape lyrics", @"musical muse", 
        @"theweekndvevo", @"high vibes", @"the vibe guide", @"latinnow", @"popular music", 
        @"the weeknd", @"light raider", @"mocha amv", @"tiff.", @"unclonable", 
        @"sabrinacarpentervevo", @"ganda dhanda", @"dj fku", @"rxposo99 - topic", 
        @"rival", @"chainsmokersvevo", @"the chainsmokers - topic", 
        @"axwell λ ingrosso - topic", @"major lazer official", @"gen-z way", @"k-391", 
        @"egzod", @"the chainsmokers", @"kurzgesagt – in a nutshell", @"reallifelore"
    ];
}

// --- 2. THE GLOBAL TEXT TRIPWIRE ---
// This intercepts EVERY single piece of text drawn on the screen
%hook UILabel
- (void)setText:(NSString *)text {
    %orig;
    if (!text || text.length < 2) return;
    
    NSString *lowerText = text.lowercaseString;
    for (NSString *keyword in getBlockedKeywords()) {
        if ([lowerText containsString:keyword]) {
            // A blocked word was found! Climb up the UI tree and destroy the parent container.
            UIView *currentView = self;
            while (currentView != nil) {
                // If we hit a cell container, nuke it
                if ([currentView isKindOfClass:NSClassFromString(@"UICollectionViewCell")]) {
                    currentView.hidden = YES;
                    currentView.alpha = 0;
                    currentView.frame = CGRectZero;
                    break;
                }
                currentView = currentView.superview;
            }
            break;
        }
    }
}
%end

// --- 3. THE TAB BAR NUKE ---
%hook YTPivotBarItemView
- (void)layoutSubviews {
    %orig;
    @try {
        // Scan the accessibility labels of the bottom tabs
        NSString *label = self.accessibilityLabel.lowercaseString ?: @"";
        if ([label containsString:@"home"] || [label containsString:@"shorts"] || [label containsString:@"create"] || [label containsString:@"+"]) {
            self.hidden = YES;
            self.userInteractionEnabled = NO;
            self.frame = CGRectZero;
            [self removeFromSuperview]; // Physically rip it out of the bar
        }
    } @catch (NSException *e) {}
}
%end

// --- 4. PERSISTENCE OVERRIDES ---
%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)defaultName {
    NSArray *forcedKeys = @[@"shortsToRegular", @"endScreenCards", @"noRelatedVids", @"noRelatedWatchNexts"];
    if ([forcedKeys containsObject:defaultName]) return YES;
    return %orig;
}
- (id)objectForKey:(NSString *)defaultName {
    NSArray *forcedKeys = @[@"shortsToRegular", @"endScreenCards", @"noRelatedVids", @"noRelatedWatchNexts"];
    if ([forcedKeys containsObject:defaultName]) return @YES;
    return %orig;
}
// Force boot into Subscriptions (Index 3)
- (NSInteger)integerForKey:(NSString *)defaultName {
    if ([defaultName isEqualToString:@"startupPage"]) return 3; 
    return %orig;
}
%end
