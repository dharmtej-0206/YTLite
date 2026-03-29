#import <UIKit/UIKit.h>

// --- SETTINGS LOCKOUT LOGIC ---

// Helper function to check if the settings are currently locked
BOOL isSettingsLocked() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lockDate = [defaults objectForKey:@"ytl_lock_timestamp"];
    NSNumber *durationNum = [defaults objectForKey:@"ytl_lock_duration_seconds"]; 
    
    // If a lock exists, check the time
    if (lockDate && durationNum && [durationNum doubleValue] > 0) {
        NSTimeInterval timePassed = [[NSDate date] timeIntervalSinceDate:lockDate];
        if (timePassed < [durationNum doubleValue]) {
            return YES; // Still locked!
        } else {
            // Timer expired. Remove the lock so you can access settings again.
            [defaults removeObjectForKey:@"ytl_lock_timestamp"];
            [defaults removeObjectForKey:@"ytl_lock_duration_seconds"];
            [defaults synchronize];
            return NO;
        }
    }
    return NO;
}

// Helper to calculate remaining minutes
int remainingLockMinutes() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lockDate = [defaults objectForKey:@"ytl_lock_timestamp"];
    NSNumber *durationNum = [defaults objectForKey:@"ytl_lock_duration_seconds"];
    NSTimeInterval timePassed = [[NSDate date] timeIntervalSinceDate:lockDate];
    return (int)(([durationNum doubleValue] - timePassed) / 60);
}

// Hook the Navigation Controller to intercept opening the Settings Menu
%hook UINavigationController
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSString *vcClassName = NSStringFromClass([viewController class]);
    
    // Check if the screen being opened is the YouTube Settings or YTLite Settings
    if ([vcClassName containsString:@"SettingsViewController"] || [vcClassName containsString:@"YTLite"]) {
        
        if (isSettingsLocked()) {
            int minsLeft = remainingLockMinutes();
            NSString *alertMessage = [NSString stringWithFormat:@"Focus mode is active. Settings are locked to prevent tampering.\n\nTime remaining: %d minutes.", minsLeft];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Access Denied" 
                                                                           message:alertMessage 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Understood" style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
            return; // ABORT pushing the settings screen. You are locked out.
        }
    }
    
    // If not locked, allow the screen to open normally
    %orig;
}
%end
