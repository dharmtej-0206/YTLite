#import <UIKit/UIKit.h>

@interface YTVideoCell : UICollectionViewCell
@end
@interface YTCompactVideoCell : UICollectionViewCell
@end
@interface YTSearchVideoCell : UICollectionViewCell
@end
@interface YTPivotBarItemView : UIView
@end

// --- 1. YOUR FULL BLOCKLIST ---
static NSArray *getBlockedKeywords() {
    return @[
        @"phonk", @"funk", @"slowed", @"music", @"sempero", @"teconci",
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

// --- 2. RECURSIVE TEXT SCANNER ---
static NSString *getAllText(UIView *view) {
    NSMutableString *text = [NSMutableString string];
    @try {
        if ([view respondsToSelector:@selector(text)]) {
            NSString *t = [view performSelector:@selector(text)];
            if (t && [t isKindOfClass:[NSString class]]) [text appendFormat:@"%@ ", t];
        }
        if ([view respondsToSelector:@selector(accessibilityLabel)]) {
            NSString *a = [view performSelector:@selector(accessibilityLabel)];
            if (a && [a isKindOfClass:[NSString class]]) [text appendFormat:@"%@ ", a];
        }
    } @catch (NSException *e) {}
    
    for (UIView *subview in view.subviews) {
        [text appendString:getAllText(subview)];
    }
    return text.lowercaseString;
}

static BOOL isCellBlocked(UIView *cell) {
    NSString *fullText = getAllText(cell);
    if (fullText.length < 2) return NO;
    for (NSString *keyword in getBlockedKeywords()) {
        if ([fullText containsString:keyword]) return YES;
    }
    return NO;
}

// --- 3. DEFEAT YTLITE: THE VISIBILITY LOCKOUT ---
// By hooking setHidden: and setFrame:, we literally reject YTLite's commands to show the video
%hook YTVideoCell
- (void)setHidden:(BOOL)hidden {
    if (!hidden && isCellBlocked(self)) {
        %orig(YES); // YTLite tried to unhide it. We force it to stay hidden.
    } else {
        %orig(hidden);
    }
}
- (void)setFrame:(CGRect)frame {
    if (isCellBlocked(self)) {
        %orig(CGRectZero); // Force 0 pixels
    } else {
        %orig(frame);
    }
}
- (void)layoutSubviews {
    %orig;
    if (isCellBlocked(self)) {
        self.hidden = YES;
        self.frame = CGRectZero;
    }
}
%end

%hook YTCompactVideoCell
- (void)setHidden:(BOOL)hidden {
    if (!hidden && isCellBlocked(self)) {
        %orig(YES); 
    } else {
        %orig(hidden);
    }
}
- (void)setFrame:(CGRect)frame {
    if (isCellBlocked(self)) {
        %orig(CGRectZero); 
    } else {
        %orig(frame);
    }
}
- (void)layoutSubviews {
    %orig;
    if (isCellBlocked(self)) {
        self.hidden = YES;
        self.frame = CGRectZero;
    }
}
%end

%hook YTSearchVideoCell
- (void)setHidden:(BOOL)hidden {
    if (!hidden && isCellBlocked(self)) {
        %orig(YES); 
    } else {
        %orig(hidden);
    }
}
- (void)setFrame:(CGRect)frame {
    if (isCellBlocked(self)) {
        %orig(CGRectZero); 
    } else {
        %orig(frame);
    }
}
- (void)layoutSubviews {
    %orig;
    if (isCellBlocked(self)) {
        self.hidden = YES;
        self.frame = CGRectZero;
    }
}
%end

// --- 4. THE TAB BAR NUKE (Keep this since it worked!) ---
%hook YTPivotBarItemView
- (void)layoutSubviews {
    %orig;
    @try {
        NSString *label = self.accessibilityLabel.lowercaseString ?: @"";
        if ([label containsString:@"home"] || [label containsString:@"shorts"] || [label containsString:@"create"] || [label containsString:@"+"]) {
            self.hidden = YES;
            self.userInteractionEnabled = NO;
            self.frame = CGRectZero;
            [self removeFromSuperview]; 
        }
    } @catch (NSException *e) {}
}
%end

// --- 5. PERSISTENCE OVERRIDES ---
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
- (NSInteger)integerForKey:(NSString *)defaultName {
    if ([defaultName isEqualToString:@"startupPage"]) return 3; 
    return %orig;
}
%end
