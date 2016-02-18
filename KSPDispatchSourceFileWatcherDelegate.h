//
//  KSPDispatchSourceFileWatcherDelegate.h
//  KSPDispatchSourceFileWatcher
//
//  Created by Konstantin Pavlikhin on 18.02.16.
//  Copyright © 2016 Konstantin Pavlikhin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KSPDispatchSourceFileChangeType.h"

// * * *.

@class KSPDispatchSourceFileWatcher;

// * * *.

@protocol KSPDispatchSourceFileWatcherDelegate <NSObject>

@required;

- (void) dispatchSourceFileWatcher: (nonnull KSPDispatchSourceFileWatcher*) fileWatcher fileDidChange: (KSPDispatchSourceFileChangeType) fileChangeType;

@end
