//
//  CNWAppDelegate.m
//  WWDCReader
//
//  Created by Chiharu Nameki on 2014/12/03.
//  Copyright (c) 2014 Chiharu Nameki. All rights reserved.
//

#import "CNWAppDelegate.h"

@implementation CNWAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Documents/Inbox 直下にファイルがあったら移動
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *inboxPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Inbox/"];
    NSArray *contentURLs = [fm contentsOfDirectoryAtURL:[NSURL fileURLWithPath:inboxPath]
                             includingPropertiesForKeys:@[NSURLIsRegularFileKey]
                                                options:NSDirectoryEnumerationSkipsHiddenFiles
                                                  error:&error];
    if (error) return;
    
    for (NSURL *contentURL in contentURLs) {
        NSNumber *isRegularFile = nil;
        if ([contentURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:nil] &&
            [isRegularFile boolValue] == YES) {
            [self moveDocumentFromURL:contentURL];
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    if ([self moveDocumentFromURL:url]) {
        [(UINavigationController *)self.window.rootViewController popToRootViewControllerAnimated:NO];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)moveDocumentFromURL:(NSURL *)url {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 同名のものがあったらファイル名に2,3,...と番号をつける
    NSURL *dstURL = [CNWDocumentsDirectoryURL() URLByAppendingPathComponent:url.lastPathComponent];
    NSString *filename = [url.lastPathComponent stringByDeletingPathExtension];
    NSString *extension = url.pathExtension;
    int i = 2;
    while ([fm fileExistsAtPath:dstURL.path]) {
        @autoreleasepool {
            dstURL = [CNWDocumentsDirectoryURL() URLByAppendingPathComponent:
                      [NSString stringWithFormat:@"%@ %d.%@", filename, i++, extension]];
        }
    }
    
    return [fm moveItemAtURL:url toURL:dstURL error:nil];
}
@end

NSURL *CNWDocumentsDirectoryURL() {
    return [[[NSFileManager defaultManager]
             URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask]
            firstObject];
}