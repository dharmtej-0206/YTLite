#import <UIKit/UIKit.h>

@interface YTVideoCell : UICollectionViewCell
@end
@interface YTCompactVideoCell : UICollectionViewCell
@end
@interface YTSearchVideoCell : UICollectionViewCell
@end

// --- 1. HARDCODED BLOCKLIST (THE FIRMWARE) ---
static NSArray *getBlockedKeywords() {
    return @[
        // Keywords & Titles
        @"phonk", @"funk", @"slowed", @"music", @"sempero", @"teconci",
        
        // Blocked Channels (All lowercase for the accessibility scanner)
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

// --- 2. THE UNIVERSAL VIDEO DESTROYER ---
static void hideIfBlocked(UICollectionViewCell *cell) {
    NSString *cellText = cell.accessibilityLabel.lowercaseString;
    if (!cellText) return;
    
    NSArray *blocked = getBlockedKeywords();
    for (NSString *keyword in blocked) {
        if ([cellText containsString:keyword]) {
            cell.hidden = YES;
            CGRect newFrame = cell.frame;
            newFrame.size.height = 0;
            cell.frame = newFrame;
            break;
        }
    }
}

// --- 3. PERMANENTLY HIJACK YTLITE SETTINGS ---
%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)defaultName {
    NSArray *forcedKeys = @[
        @"shortsToRegular",       // Converts Shorts to regular player
        @"endScreenCards",        // Hides End screen hover cards
        @"noRelatedVids",         // No related videos in the overlay
        @"noRelatedWatchNexts",   // Hides related videos under the main player
        @"hideHomeTab",           // NUKES THE HOME FEED
        @"hideShortsTab"          // NUKES THE SHORTS TAB
    ];
    
    if ([forcedKeys containsObject:defaultName]) {
        return YES; 
    }
    return %orig(defaultName);
}
%end

// --- 4. APPLY BLOCKER TO ALL YOUTUBE SCREENS ---
%hook YTVideoCell
- (void)layoutSubviews { 
    %orig; 
    hideIfBlocked(self); 
}
%end

%hook YTCompactVideoCell
- (void)layoutSubviews { 
    %orig; 
    hideIfBlocked(self); 
}
%end

%hook YTSearchVideoCell
- (void)layoutSubviews { 
    %orig; 
    hideIfBlocked(self); 
}
%end
