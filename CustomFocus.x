#import <UIKit/UIKit.h>

@interface YTVideoCell : UICollectionViewCell
@end
@interface YTCompactVideoCell : UICollectionViewCell
@end
@interface YTSearchVideoCell : UICollectionViewCell
@end

// --- 1. HARDCODED BLOCKLIST ---
static NSArray *getBlockedKeywords() {
    return @[
        // Keywords
        @"phonk", @"funk", @"slowed", @"music", @"sempero", @"teconci",
        
        // Channels (Cleaned up from your JSON)
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

// --- 2. THE UNIVERSAL TEXT SCANNER ---
static void executeBlock(UIView *cell) {
    @try {
        NSString *title = @"";
        NSString *subtitle = @"";
        
        // Grab the raw text exactly when YouTube injects it into the labels
        UILabel *tLabel = [cell valueForKey:@"_titleLabel"];
        if (tLabel && [tLabel respondsToSelector:@selector(text)]) {
            title = tLabel.text.lowercaseString ?: @"";
        }
        
        UILabel *sLabel = [cell valueForKey:@"_subtitleLabel"];
        if (sLabel && [sLabel respondsToSelector:@selector(text)]) {
            subtitle = sLabel.text.lowercaseString ?: @"";
        }
        
        NSString *fullText = [NSString stringWithFormat:@"%@ %@", title, subtitle];
        if (fullText.length < 2) return;
        
        NSArray *blocked = getBlockedKeywords();
        for (NSString *keyword in blocked) {
            if ([fullText containsString:keyword]) {
                cell.hidden = YES;
                cell.alpha = 0;
                CGRect frame = cell.frame;
                frame.size.height = 0;
                cell.frame = frame; // Crush the box
                break;
            }
        }
    } @catch (NSException *e) {}
}

// --- 3. APPLY BLOCKER AT DATA INJECTION ---
// Hooking both methods ensures we catch every version of YouTube's codebase
%hook YTVideoCell
- (void)setModel:(id)arg1 { %orig; executeBlock(self); }
- (void)setEntry:(id)arg1 { %orig; executeBlock(self); }
%end

%hook YTCompactVideoCell
- (void)setModel:(id)arg1 { %orig; executeBlock(self); }
- (void)setEntry:(id)arg1 { %orig; executeBlock(self); }
%end

%hook YTSearchVideoCell
- (void)setModel:(id)arg1 { %orig; executeBlock(self); }
- (void)setEntry:(id)arg1 { %orig; executeBlock(self); }
%end

// --- 4. THE ULTIMATE SETTINGS INTERCEPTOR ---
%hook NSUserDefaults
// Catch Question 1 (Bools)
- (BOOL)boolForKey:(NSString *)defaultName {
    NSArray *forcedKeys = @[
        @"shortsToRegular", @"endScreenCards", @"noRelatedVids", @"noRelatedWatchNexts", 
        @"hideHomeTab", @"hideShortsTab", @"hideUploadTab"
    ];
    if ([forcedKeys containsObject:defaultName]) return YES;
    return %orig;
}

// Catch Question 2 (Objects)
- (id)objectForKey:(NSString *)defaultName {
    NSArray *forcedKeys = @[
        @"shortsToRegular", @"endScreenCards", @"noRelatedVids", @"noRelatedWatchNexts", 
        @"hideHomeTab", @"hideShortsTab", @"hideUploadTab"
    ];
    if ([forcedKeys containsObject:defaultName]) return @YES;
    return %orig;
}
%end
