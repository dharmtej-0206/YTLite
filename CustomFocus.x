#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface YTVideoCell : UICollectionViewCell
@end
@interface YTCompactVideoCell : UICollectionViewCell
@end
@interface YTSearchVideoCell : UICollectionViewCell
@end
@interface YTPivotBarItemView : UIView
@end

// --- 1. THE FIRMWARE BLOCKLIST ---
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

// --- 2. THE DATA MODEL HIJACKER ---
// We create a secret tag to remember if a cell is blocked
static const void *kIsBlockedKey = &kIsBlockedKey;

static BOOL isDataBlocked(id dataModel) {
    if (!dataModel) return NO;
    // This intercepts the raw data (JSON/Protobuf) before YouTube even draws the box.
    // It sees EVERYTHING instantly.
    NSString *rawText = [[dataModel description] lowercaseString];
    if (rawText.length < 2) return NO;
    
    for (NSString *keyword in getBlockedKeywords()) {
        if ([rawText containsString:keyword]) return YES;
    }
    return NO;
}

static void markCell(UIView *cell, BOOL isBlocked) {
    objc_setAssociatedObject(cell, kIsBlockedKey, @(isBlocked), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (isBlocked) cell.hidden = YES;
    else cell.hidden = NO;
}

static BOOL isCellBlocked(UIView *cell) {
    NSNumber *val = objc_getAssociatedObject(cell, kIsBlockedKey);
    return [val boolValue];
}

// --- 3. APPLY TO HOME & SEARCH ---
%hook YTVideoCell
- (void)setEntry:(id)arg1 { %orig; markCell(self, isDataBlocked(arg1)); }
- (void)setModel:(id)arg1 { %orig; markCell(self, isDataBlocked(arg1)); }
- (CGSize)sizeThatFits:(CGSize)size {
    if (isCellBlocked(self)) return CGSizeZero;
    return %orig;
}
%end

%hook YTSearchVideoCell
- (void)setEntry:(id)arg1 { %orig; markCell(self, isDataBlocked(arg1)); }
- (void)setModel:(id)arg1 { %orig; markCell(self, isDataBlocked(arg1)); }
- (CGSize)sizeThatFits:(CGSize)size {
    if (isCellBlocked(self)) return CGSizeZero;
    return %orig;
}
%end

// --- 4. ANNIHILATE INFINITE SCROLL & RELATED VIDEOS ---
// We permanently force every related video cell to be blocked and height 0.
%hook YTCompactVideoCell
- (void)setEntry:(id)arg1 { %orig; markCell(self, YES); }
- (void)setModel:(id)arg1 { %orig; markCell(self, YES); }
- (CGSize)sizeThatFits:(CGSize)size { return CGSizeZero; }
%end

// --- 5. BOTTOM TABS & APP STARTUP ---
%hook YTPivotBarItemView
- (CGSize)sizeThatFits:(CGSize)size {
    NSString *aLabel = [self.accessibilityLabel lowercaseString] ?: @"";
    if ([aLabel containsString:@"home"] || [aLabel containsString:@"shorts"] || [aLabel containsString:@"create"]) {
        return CGSizeZero;
    }
    return %orig;
}
- (void)layoutSubviews {
    %orig;
    NSString *aLabel = [self.accessibilityLabel lowercaseString] ?: @"";
    if ([aLabel containsString:@"home"] || [aLabel containsString:@"shorts"] || [aLabel containsString:@"create"]) {
        self.hidden = YES;
    }
}
%end

%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)defaultName {
    NSArray *forcedKeys = @[@"shortsToRegular", @"endScreenCards", @"noRelatedVids", @"noRelatedWatchNexts", @"hideHomeTab", @"hideShortsTab", @"hideUploadTab"];
    if ([forcedKeys containsObject:defaultName]) return YES;
    return %orig;
}
- (id)objectForKey:(NSString *)defaultName {
    NSArray *forcedKeys = @[@"shortsToRegular", @"endScreenCards", @"noRelatedVids", @"noRelatedWatchNexts", @"hideHomeTab", @"hideShortsTab", @"hideUploadTab"];
    if ([forcedKeys containsObject:defaultName]) return @YES;
    return %orig;
}
// Force the app to launch into the Subscriptions tab instead of Home
- (NSInteger)integerForKey:(NSString *)defaultName {
    if ([defaultName isEqualToString:@"startupPage"]) return 3; // 3 = Subscriptions Tab
    return %orig;
}
%end
