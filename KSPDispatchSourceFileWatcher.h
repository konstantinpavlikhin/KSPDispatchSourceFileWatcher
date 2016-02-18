//
//  KSPDispatchSourceFileWatcher.h
//  KSPDispatchSourceFileWatcher
//
//  Created by Konstantin Pavlikhin on 18.02.16.
//  Copyright © 2016 Konstantin Pavlikhin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KSPDispatchSourceFileChangeType.h"

// * * *.

@protocol KSPDispatchSourceFileWatcherDelegate;

// * * *.

@interface KSPDispatchSourceFileWatcher : NSObject

+ (nullable instancetype) fileWatcherWithFileURL: (nonnull NSURL*) fileURL fileChangeTypeMask: (KSPDispatchSourceFileChangeType) fileChangeTypeMask;

- (nullable instancetype) initWithFileURL: (nonnull NSURL*) fileURL fileChangeTypeMask: (KSPDispatchSourceFileChangeType) fileChangeTypeMask;

@property(readonly, strong, nonatomic, nonnull) NSURL* fileURL;

@property(readwrite, weak, nonatomic, nullable) id<KSPDispatchSourceFileWatcherDelegate> delegate;

- (void) resume;

- (void) suspend;

- (void) cancel;

@end
