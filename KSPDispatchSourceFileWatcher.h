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

+ (nullable instancetype) fileWatcherWithFileURL: (nonnull NSURL*) fileURL;

+ (nullable instancetype) fileWatcherWithFileURL: (nonnull NSURL*) fileURL fileChangeTypeMask: (KSPDispatchSourceFileChangeType) fileChangeTypeMask;

- (nullable instancetype) init NS_UNAVAILABLE;

- (nullable instancetype) initWithFileURL: (nonnull NSURL*) fileURL;

- (nullable instancetype) initWithFileURL: (nonnull NSURL*) fileURL fileChangeTypeMask: (KSPDispatchSourceFileChangeType) fileChangeTypeMask NS_DESIGNATED_INITIALIZER;

@property(readonly, strong, nonatomic, nonnull) NSURL* fileURL;

@property(readwrite, weak, nonatomic, nullable) id<KSPDispatchSourceFileWatcherDelegate> delegate;

- (void) resume;

- (void) suspend;

- (void) cancel;

@end
