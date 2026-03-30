#import <UIKit/UIKit.h>

@interface YTVideoCell : UICollectionViewCell
@end
@interface YTCompactVideoCell : UICollectionViewCell
@end
@interface YTSearchVideoCell : UICollectionViewCell
@end
@interface YTPivotBarItemView : UIView
@end

// --- 1. HARDCODED BLOCKLIST ---
static NSArray *getBlockedKeywords() {
    return @[
        @"phonk", @"funk", @"slowed", @"music", @"sempero", @"teconci",
        @"mrbeast", @"career247", @"studyiq ias", @"neon man", @"purav jha", 
        @"neon man sports", @"lakshay chaudhary", @"abhi and niyu", @"t-series", 
        @"neuzboy", @"ashish chanchlani vines", @"tanmay bhat", @"hindi rush", 
        @"india's got latent clips", @"samay raina", @"carryminati", @"ishowspeed", 
        @"varun mayya", @"aevy tv", @"finance with sharan", @"breakdown", 
        @"ryan george", @"mohak mangal", @"cinedesi", @"rapid info", @"techlinked", 
        @"linus tech tips", @"shortcircuit", @"memapur", @"sourav joshi vlogs", 
        @"risen ai", @"mr. indian hacker", @"thugesh", @"open letter", @"dhruv rathee", 
        @"techwiser", @"sillycorns", @"think school", @"mr techpedia", @"nitish rajput", 
        @"gyan therapy", @"aye jude", @"prasadtechintelugu", @"beebom", @"trakin tech", 
        @"the deshbhakt", @"mrwhosetheboss", @"hamza", @"thegoodvibe", @"andromeda", 
        @"mxzi", @"zombr3x", @"sma$her", @"flame runner", @"jmilton", @"repsaj", 
        @"mgd", @"khaos", @"cape", @"torbahed", @"ogryzek", @"trxshbxy", @"ncts", 
        @"fennecxx", @"sayfalse", @"h6itam", @"eternxlkz", @"dj fku", @"dj asul", 
        @"kendrick lamar", @"sabrina carpenter", @"camila cabello", @"shawn mendes", 
        @"one direction", @"wham!", @"sia", @"stephen sanchez", @"publictheband", 
        @"powfu", @"passenger", @"charlie puth", @"onedirectionvevo", @"wiz khalifa", 
        @"publicvevo", @"alan walker", @"stephensanchezvevo", @"onerepublicvevo", 
        @"green planet lyrics", @"coldplay", @"netflix india", @"dog story", @"zaynvevo", 
        @"neon lyrics", @"glassanimalsvevo", @"aviciiofficialvevo", @"billieeilishvevo", 
        @"thescriptvevo", @"selina lyrics", @"lanadelreyvevo", @"khalidvevo", 
        @"justinbiebervevo", @"bluenight audio", @"pop mage", @"ragnbonemanvevo", 
        @"jonas blue", @"5sos", @"panic! at the disco", @"the score", @"republic records", 
        @"riot games music", @"2wei", @"suka.", @"phant x", @"alpha phonk", 
        @"unstoppable music", @"mafia", @"mtheo", @"youssey music", @"mrl", @"ashreveal", 
        @"ro ransom", @"trillyrap", @"7clouds", @"urban paradise", @"pizza music", 
        @"vibe music", @"syrebralvibes", @"dan music", @"solitude songs", @"mikomikei", 
        @"alone candy music", @"latinhype", @"arcade music", @"billion stars", 
        @"tried&refused", @"lynling", @"pop artist", @"lost panda", @"ignite", 
        @"unique sound", @"cakes & eclairs", @"escape lyrics", @"musical muse", 
        @"theweekndvevo", @"high vibes", @"the vibe guide", @"latinnow", @"popular music", 
        @"the weeknd", @"light raider", @"mocha amv", @"tiff.", @"unclonable", 
        @"sabrinacarpentervevo", @"ganda dhanda", @"rxposo99", @"rival", 
        @"chainsmokersvevo", @"the chainsmokers", @"axwell", @"major lazer", @"gen-z way", 
        @"k-391", @"egzod", @"kurzgesagt", @"reallifelore"
    ];
}

// --- 2. THE NUCLEAR TEXT SCANNER ---
// Recursively digs through EVERY single piece of text inside a UI box
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

static BOOL isBlocked(UIView *cell) {
    NSString *fullText = getAllText(cell);
    if (fullText.length < 2) return NO;
    
    for (NSString *keyword in getBlockedKeywords()) {
        if ([fullText containsString:keyword]) return YES;
    }
    return NO;
}

// --- 3. THE GAPLESS BLOCKER ---
%hook YTVideoCell
- (void)layoutSubviews {
    %orig;
    if (isBlocked(self)) {
        self.hidden = YES;
        self.frame = CGRectZero;
    }
}
- (CGSize)sizeThatFits:(CGSize)size {
    if (isBlocked(self)) return CGSizeZero;
    return %orig;
}
%end

%hook YTSearchVideoCell
- (void)layoutSubviews {
    %orig;
    if (isBlocked(self)) {
        self.hidden = YES;
        self.frame = CGRectZero;
    }
}
- (CGSize)sizeThatFits:(CGSize)size {
    if (isBlocked(self)) return CGSizeZero;
    return %orig;
}
%end

// --- 4. NUKE RELATED VIDEOS (INFINITY SCROLL) ---
// By returning CGSizeZero, the related feed is physically incapable of rendering
%hook YTCompactVideoCell
- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
    self.frame = CGRectZero;
}
- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeZero;
}
%end

// --- 5. NUKE THE BOTTOM TABS ---
%hook YTPivotBarItemView
- (void)layoutSubviews {
    %orig;
    NSString *text = getAllText(self);
    // Erase Home, Shorts, and the (+) Upload button
    if ([text containsString:@"home"] || [text containsString:@"shorts"] || [text containsString:@"create"] || [text containsString:@"+"]) {
        self.hidden = YES;
        self.userInteractionEnabled = NO;
        self.frame = CGRectZero;
    }
}
- (CGSize)sizeThatFits:(CGSize)size {
    NSString *text = getAllText(self);
    if ([text containsString:@"home"] || [text containsString:@"shorts"] || [text containsString:@"create"] || [text containsString:@"+"]) {
        return CGSizeZero;
    }
    return %orig;
}
%end

// --- 6. RETAIN PERSISTENCE (SHORTS-TO-REGULAR) ---
%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)defaultName {
    NSArray *forcedKeys = @[@"shortsToRegular", @"endScreenCards"];
    if ([forcedKeys containsObject:defaultName]) return YES;
    return %orig;
}
- (id)objectForKey:(NSString *)defaultName {
    NSArray *forcedKeys = @[@"shortsToRegular", @"endScreenCards"];
    if ([forcedKeys containsObject:defaultName]) return @YES;
    return %orig;
}
%end
